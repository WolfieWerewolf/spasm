module spasm.dom;

import spasm.types;
import spasm.dom;
import spasm.ct;
import std.traits : hasMember, isAggregateType;
import std.traits : TemplateArgsOf, staticMap, isPointer, PointerTarget, getUDAs;
import spasm.css;
import spasm.node;
import spasm.event;
import std.meta : staticIndexOf;
import spasm.array;
import spasm.rt.array;

private extern(C) {
  Handle createElement(NodeType type);
  void addClass(Handle node, string className);
  void setProperty(Handle node, string prop, string value);
  void removeChild(Handle childPtr);
  void unmount(Handle childPtr);
  void appendChild(Handle parentPtr, Handle childPtr);
  void insertBefore(Handle parentPtr, Handle childPtr, Handle sibling);
  void setAttribute(Handle nodePtr, string attr, string value);
  void setPropertyBool(Handle nodePtr, string attr, bool value);
  void setPropertyInt(Handle nodePtr, string attr, int value);
  void innerText(Handle nodePtr, string text);
  void removeClass(Handle node, string className);
  void changeClass(Handle node, string className, bool on);
}

extern(C) {
  string getProperty(Handle node, string prop);
  int getPropertyInt(Handle node, string prop);
  bool getPropertyBool(Handle node, string prop);
  void focus(Handle node);
  void setSelectionRange(Handle node, uint start, uint end);
  void addCss(string css);
}

import spasm.bindings.dom : Document;
import spasm.bindings.html : Window;
__gshared undefined = Any(JsHandle(0));
__gshared document = Document(JsHandle(1));
__gshared window = Window(JsHandle(2));

void unmount(T)(auto ref T t) if (hasMember!(T, "node")) {
  unmount(t.node.node);
  static if (hasMember!(T, "node"))
    t.node.mounted = false;
  t.propagateOnUnmount();
 }

auto removeChild(T)(auto ref T t) if (hasMember!(T,"node")) {
  removeChild(t.node.node);
  static if (hasMember!(T, "node"))
    t.node.mounted = false;
  t.propagateOnUnmount();
}

auto focus(T)(auto ref T t) if (hasMember!(T,"node")) {
  t.node.node.focus();
 }

auto renderBefore(T, Ts...)(JsHandle parent, auto ref T t, JsHandle sibling, auto ref Ts ts) {
  if (parent == invalidHandle)
    return;
  renderIntoNode(parent, t, ts);
  static if (hasMember!(T, "node")) {
    parent.insertBefore(t.node.node, sibling);
    t.node.mounted = true;
  }
  t.propagateOnMount();
}

auto render(T, Ts...)(JsHandle parent, auto ref T t, auto ref Ts ts) {
  if (parent == invalidHandle)
    return;
  renderIntoNode(parent, t, ts);
  static if (hasMember!(T, "node")) {
    if (!t.node.mounted) {
      parent.appendChild(t.node.node);
      t.node.mounted = true;
    }
  }
  t.propagateOnMount();
}

import std.traits : isFunction;
auto propagateOnMount(T)(auto ref T t) {
  static foreach (c; getChildren!T)
    __traits(getMember, t, c).propagateOnMount();
  // static if (hasMember!(T, "node"))
    // t.node.mounted = true;
  static if (hasMember!(T, "onMount") && isFunction!(T.onMount))
    t.onMount();
}

auto propagateOnUnmount(T)(auto ref T t)
{
  static foreach (c; getChildren!T)
    __traits(getMember, t, c).propagateOnMount();
  // static if (hasMember!(T, "node"))
    // t.node.mounted = false;
  static if (hasMember!(T, "onUnmount") && isFunction!(T.onUnmount))
    t.onUnmount();
}

auto remount(string field, Parent)(auto ref Parent parent) {
  import std.traits : hasUDA;
  import std.meta : AliasSeq;
  alias fields = AliasSeq!(__traits(allMembers, Parent));//FieldNameTuple!Parent;
  alias idx = staticIndexOf!(field,fields);
  static if (fields.length > idx+1) {
    static foreach(child; fields[idx+1..$]) {
      static if (hasUDA!(__traits(getMember, Parent, child), spasm.types.child)) {
        if (__traits(getMember, parent, child).node.mounted)
          return renderBefore(parent.node.node, __traits(getMember, parent, field), __traits(getMember, parent, child).node.node, parent);
      }
    }
  }
  return render(parent.node.node, __traits(getMember, parent, field), parent);
}

template isLiteral(alias t) {
  enum isLiteral = __traits(compiles, { enum p = t; });
}

template createParameterTuple(Params...) {
  auto createParameterTuple(Parent)(auto ref Parent p) {
    import std.traits : TemplateArgsOf, staticMap;
    import spasm.spa : Param;
    template extractName(Arg) {
      enum extractName = Arg.Name;
    }
    static auto extractField(alias sym)(auto ref Parent p) {
      enum name = sym.stringof;
      enum literal = isLiteral!(sym);
      static if (isLiteral!(sym)) {
        __gshared static auto val = sym;
        return &val;
      } else
        return &__traits(getMember, p, name);
    }
    static auto extractFields(Args...)(auto ref Parent p) if (Args.length > 0) {
      alias sym = TemplateArgsOf!(Args[0])[1];
      static if (Args.length > 1)
        return tuple(extractField!(sym)(p), extractFields!(Args[1..$])(p).expand);
      else
        return tuple(extractField!(sym)(p));
    }
    alias ParamsTuple = staticMap!(TemplateArgsOf, Params);
    alias Names = staticMap!(extractName, ParamsTuple);
    auto Fields = extractFields!(ParamsTuple)(p);
    return tuple!(Names)(Fields.expand);
  }
}

auto setPointers(T, Ts...)(auto ref T t, auto ref Ts ts) {
  import std.meta : AliasSeq;
  import std.traits : hasUDA;
  static foreach(i; __traits(allMembers, T)) {{
      alias sym = AliasSeq!(__traits(getMember, t, i))[0];
      static if (is(typeof(sym) == Prop*, Prop)) {
        setPointerFromParent!(i)(t, ts);
      }
      static if (!is(sym) && isAggregateType!T) {
        static if (is(typeof(sym) : DynamicArray!(Item), Item)) {
          // items in appenders need to be set via render functions
        } else {
          static if (!isCallable!(typeof(sym)) && !isPointer!(typeof(sym))) {
            import spasm.spa;
            alias Params = getUDAs!(sym, Parameters);
            static if (Params.length > 0) {
              auto params = createParameterTuple!(Params)(t);
            }
            else
              alias params = AliasSeq!();
            static if (hasUDA!(sym, child))
              setPointers(__traits(getMember, t, i), AliasSeq!(params, t, ts));
            else static if (params.length > 0)
              setPointers(__traits(getMember, t, i), AliasSeq!(params));
          }
        }
      }
    }}
}

auto isChildVisible(string child, Parent)(auto ref Parent parent) {
  import std.traits : getSymbolsByUDA, getUDAs;
  alias visiblePreds = getSymbolsByUDA!(Parent, visible);
  static foreach(sym; visiblePreds) {{
      alias vs = getUDAs!(sym, visible);
      // TODO: static assert sym is callable
      static foreach(v; vs) {{
        static if (is(v == visible!name, string name) && child == name) {
          static if (is(typeof(sym) == bool)) {
            if (!__traits(getMember, parent, __traits(identifier,sym)))
              return false;
          } else {
            auto result = callMember!(__traits(identifier, sym))(parent);
            if (result == false)
              return false;
          }
        }
        }}
    }}
  return true;
}

auto callMember(string fun, T)(auto ref T t) {
  import spasm.ct : ParameterIdentifierTuple;
  import std.meta : staticMap, AliasSeq;
  alias params = ParameterIdentifierTuple!(__traits(getMember, t, fun));
  static if (params.length == 0) {
    return __traits(getMember, t, fun)();
  } else static if (params.length == 1) {
    return __traits(getMember, t, fun)(__traits(getMember, t, params[0]));
  } else static if (params.length == 2) {
    return __traits(getMember, t, fun)(__traits(getMember, t, params[0]),__traits(getMember, t, params[1]));
  }
  else {
    pragma(msg, params.length);
    static assert(false, "Not implemented");
  }
}

auto renderIntoNode(T, Ts...)(JsHandle parent, auto ref T t, auto ref Ts ts) if (isPointer!T) {
  return renderIntoNode(parent, *t, ts);
}

auto renderIntoNode(T, Ts...)(JsHandle parent, auto ref T t, auto ref Ts ts) if (!isPointer!T) {
  import std.traits : hasUDA, getUDAs;
  import std.meta : AliasSeq;
  import std.meta : staticMap;
  import std.traits : isCallable, getSymbolsByUDA, isPointer;
  import std.conv : text;
  enum hasNode = hasMember!(T, "node");
  static if (hasNode)
    bool shouldRender = t.node.node == invalidHandle;
  else
    bool shouldRender = true;
  if (shouldRender) {
    auto node = createNode(parent, t);
    alias StyleSet = getStyleSet!T;
    static foreach(i; __traits(allMembers, T)) {{
        alias name = domName!i;
        alias sym = AliasSeq!(__traits(getMember, t, i))[0];
        static if (!is(sym)) {
          alias styles = getStyles!(sym);
          static if (is(typeof(sym) == Prop*, Prop)) {
            if (__traits(getMember, t, i) is null) {
              // TODO: do we need to call createParameterTuple here as well as in setPointers?? 
              setPointerFromParent!(i)(t, ts);
            }
          }
          static if (hasUDA!(sym, child)) {
            import spasm.spa;
            alias Params = getUDAs!(sym, Parameters);
            static if (Params.length > 0)
              auto params = createParameterTuple!(Params)(t);
            else
              alias params = AliasSeq!();
            if (isChildVisible!(i)(t)) {
              static if (is(typeof(sym) : DynamicArray!(Item*), Item)) {
                foreach(ref item; __traits(getMember, t, i)) {
                  // TODO: we only need to pass t to a child render function when there is a child that has an alias to one of its member
                  node.render(*item, AliasSeq!(params, t, ts));
                  static if (is(typeof(t) == Array!Item))
                    t.assignEventListeners(*item);
                }
              } else {
                // TODO: we only need to pass t to a child render function when there is a child that has an alias to one of its member
                static if (isCallable!(typeof(sym))) {
                  static assert(false, "we don't support @child functions");
                  // node.render(callMember!(i)(t), AliasSeq!(t, ts));
                } else {
                  node.render(__traits(getMember, t, i), AliasSeq!(params, t, ts));
                }
              }
            }
          } else static if (hasUDA!(sym, prop)) {
            static if (isCallable!(sym)) {
              auto result = callMember!(i)(t);
              node.setPropertyTyped!name(result);
            } else {
              node.setPropertyTyped!name(__traits(getMember, t, i));
            }
          } else static if (hasUDA!(sym, callback)) {
            node.addEventListenerTyped!i(t);
          } else static if (hasUDA!(sym, attr)) {
            static if (isCallable!(sym)) {
              auto result = callMember!(sym)(t);
              node.setAttributeTyped!name(result);
            } else {
              node.setAttributeTyped!name(__traits(getMember, t, i));
            }
          } else static if (hasUDA!(sym, connect)) {
            alias connects = getUDAs!(sym, connect);
            static foreach(c; connects) {
              auto del = &__traits(getMember, t, i);
              static if (is(c: connect!(a,b), alias a, alias b)) {
                mixin("t."~a~"."~replace!(b,'.','_')~".add(del);");
              } else static if (is(c : connect!field, alias field)) {
                mixin("t."~field~".add(del);");
              }
            }
          }
          alias extendedStyles = getStyleSets!(sym);
          static foreach(style; extendedStyles) {
            static assert(hasMember!(typeof(sym), "node"), "styleset on field is currently only possible when said field has a Node mixin");
            __traits(getMember, t, i).node.setAttribute(GenerateExtendedStyleSetName!style,"");
          }
          static if (i == "node") {
            node.applyStyles!(T, styles);
          } else static if (styles.length > 0) {
            static if (isCallable!(sym)) {
              auto result = callMember!(i)(t);
              if (result == true) {
                node.applyStyles!(T, styles);
              }
            } else static if (is(typeof(sym) == bool)) {
              if (__traits(getMember, t, i) == true)
                node.applyStyles!(T, styles);
            } else static if (hasUDA!(sym, child)) {
              __traits(getMember, t, i).node.applyStyles!(T, styles);
            }
          }
        }
      }}
    static if (hasMember!(T, "node")) {
      t.node.node = node;
    }
  }
 }


template among(alias field, T...) {
  static if (T.length == 0)
    enum among = false;
  else static if (T.length == 1)
    enum among = field.stringof == T[0];
  else
    enum among = among!(field,T[0..$/2]) || among!(field,T[$/2..$]);
}

template getAnnotatedParameters(alias symbol) {
  import spasm.spa;
  alias Params = getUDAs!(symbol, Parameters);
  alias getAnnotatedParameters = staticMap!(TemplateArgsOf, Params);
}

template updateChildren(string field) {
  template isParamField(Param) {
    enum isParamField = TemplateArgsOf!(Param)[1].stringof == field;
  }
  static auto updateChildren(Parent)(auto ref Parent parent) {
    // we are updating field in parent
    // all children that have a pointer with the exact same name
    // should get an update
    // all children that have a params annotation that refers to the field
    // should get an update
    import std.traits : getSymbolsByUDA;
    import std.meta : ApplyLeft, staticMap;
    alias getSymbol = ApplyLeft!(getMember, parent);
    alias childrenNames = getChildren!Parent;
    alias children = staticMap!(getSymbol,childrenNames);
    static foreach(c; children) {{
      alias ChildType = typeof(c);
      alias Params = getAnnotatedParameters!c;
      alias matchingParam = Filter!(isParamField, Params);
      static if (matchingParam.length > 0) {
        static foreach(p; matchingParam) {
          __traits(getMember, parent, c.stringof).update!(__traits(getMember, __traits(getMember, parent, c.stringof), p.Name));
        }
      } else static if (hasMember!(ChildType, field) && isPointer!ChildType) {
        __traits(getMember, parent, c.stringof).update!(__traits(getMember, __traits(getMember, parent, c.stringof), field));
      } else
        .updateChildren!(field)(__traits(getMember, parent, c.stringof));
      }}
  }
}

auto update(T)(ref T node) if (hasMember!(T, "node")){
  struct Inner {
    auto opDispatch(string name, T)(auto ref T t) const {
      mixin("node.update!(node." ~ name ~ ")(t);");
    }
  }
  return Inner();
}

void update(Range, Sink)(Range source, ref Sink sink) {
  import std.range : ElementType;
  import std.algorithm : copy;
  alias E = ElementType!Range;
  auto output = Updater!(Sink)(&sink);
  foreach(i; source)
    output.put(i);
}

auto setVisible(string field, Parent)(auto ref Parent parent, bool visible) {
  bool current = __traits(getMember, parent, field).node.mounted;
  if (current != visible) {
    if (visible) {
      remount!(field)(parent);
    } else {
      unmount(__traits(getMember, parent, field));
    }
  }
}

template update(alias field) {
  import std.traits : isPointer;
  static auto updateDom(Parent, T)(auto ref Parent parent, auto ref T t) {
    import spasm.ct : ParameterIdentifierTuple;
    import std.traits : hasUDA, isCallable, getUDAs;
    import std.meta : AliasSeq;
    import std.meta : staticMap;
    alias name = domName!(field.stringof);
    static if (hasUDA!(field, prop)) {
      parent.node.setPropertyTyped!name(t);
    } else static if (hasUDA!(field, attr)) {
      parent.node.setAttributeTyped!name(t);
    }
    static if (is(T == bool)) {
      alias styles = getStyles!(field);
      static foreach(style; styles) {
        __gshared static string className = GetCssClassName!(Parent, style);
        parent.node.changeClass(className,t);
      }
      static if (hasUDA!(field, visible)) {
        alias udas = getUDAs!(field, visible);
        static foreach (uda; udas) {
          static if (is(uda : visible!elem, alias elem)) {
            setVisible!(elem)(parent, __traits(getMember, parent, __traits(identifier, field)));
          }
        }
      }
    }
    static foreach(i; __traits(allMembers, Parent)) {{
        alias sym = AliasSeq!(__traits(getMember, parent, i))[0];
        static if (isCallable!(sym)) {
          alias params = ParameterIdentifierTuple!sym;
          static if (among!(field, params)) {
            static if (hasUDA!(sym, prop)) {
              alias cleanName = domName!i;
              auto result = callMember!(i)(parent);
              parent.node.node.setPropertyTyped!cleanName(result);
            }
            else static if (hasUDA!(sym, style)) {
              alias styles = getStyles!(sym);
              auto result = callMember!(i)(parent);
              static foreach (style; styles)
              {
                __gshared static string className = GetCssClassName!(Parent, style);
                parent.node.node.changeClass(className,result);
              }
            } else {
              import std.traits : ReturnType;
              alias RType = ReturnType!(__traits(getMember, parent, i));
              static if (is(RType : void))
                callMember!(i)(parent);
              else {
                auto result = callMember!(i)(parent);
                static if (hasUDA!(sym, visible)) {
                  alias udas = getUDAs!(sym, visible);
                  static foreach(uda; udas) {
                    static if (is(uda : visible!elem, alias elem)) {
                      setVisible!(elem)(parent, result);
                    }
                  }
                }
              }
            }
          }
        }
      }}
    updateChildren!(field.stringof)(parent);
  }
  static auto update(Parent)(auto ref Parent parent) {
    static if (isPointer!Parent)
      updateDom(*parent, __traits(getMember, parent, field.stringof));
    else
      updateDom(parent, __traits(getMember, parent, field.stringof));
  }
  static auto update(Parent, T)(auto ref Parent parent, T t) {
    mixin("parent."~field.stringof~" = t;");
    static if (isPointer!Parent)
      updateDom(*parent, t);
    else
      updateDom(parent, t);
  }
}

template symbolFromAliasThis(Parent, string name) {
  import std.meta : anySatisfy;
  alias aliasThises = AliasSeq!(__traits(getAliasThis, Parent));
  static if (aliasThises.length == 0)
    enum symbolFromAliasThis = false;
  else {
    alias hasSymbol = ApplyRight!(hasMember, name);
    enum symbolFromAliasThis = anySatisfy!(hasSymbol, aliasThises);
  }
}

void setPointerFromParent(string name, T, Ts...)(ref T t, auto ref Ts ts) {
  import std.traits : PointerTarget;
  import std.meta : AliasSeq;
  alias FieldType = PointerTarget!(typeof(getMember!(T, name)));
  template matchesField(Parent) {
    static if (!hasMember!(Parent,name))
      enum matchesField = false;
    else {
      alias ItemTypeParent = AliasSeq!(__traits(parent, getMember!(Parent, name)))[0];
      static if (is(T == ItemTypeParent))
        enum matchesField = false;
      else {
        alias ItemType = typeof(getMember!(Parent, name));
        enum matchesField = (is(ItemType == FieldType) || is (ItemType == FieldType*));
      }
    }
  }
  enum index = indexOfPred!(matchesField, AliasSeq!Ts);
  static if (index >= ts.length) {
    return;
  }
  else static if (is(typeof(__traits(getMember, ts[index], name)) == FieldType*)) {
    __traits(getMember, t, name) = __traits(getMember, ts[index], name);
  } else {
    __traits(getMember, t, name) = &__traits(getMember, ts[index], name);
  }
}

auto setAttributeTyped(string name, T)(JsHandle node, auto ref T t) {
  import std.traits : isPointer;
  static if (isPointer!T)
    node.setAttributeTyped!name(*t);
  else static if (is(T == bool))
    node.setAttributeBool(name, t);
  else {
    node.setAttribute(name, t);
  }
}

auto setPropertyTyped(string name, T)(JsHandle node, auto ref T t) {
  import std.traits : isPointer, isNumeric;
  static if (isPointer!T) {
    node.setPropertyTyped!name(*t);
  }
  else static if (is(T == bool))
    node.setPropertyBool(name, t);
  else static if (isNumeric!(T))
    node.setPropertyInt(name, t);
  else
  {
    static if (__traits(compiles, __traits(getMember, api, name)))
      __traits(getMember, api, name)(node, t);
    else
      node.setProperty(name, t);
  }
}

auto applyStyles(T, styles...)(JsHandle node) {
  static foreach(style; styles) {
    node.addClass(GetCssClassName!(T, style));
  }
}

JsHandle createNode(T)(JsHandle parent, ref T t) {
  enum hasNode = hasMember!(T, "node");
  static if (hasNode && is(typeof(t.node) : NamedJsHandle!tag, alias tag)) {
    mixin("NodeType n = NodeType." ~ tag ~ ";");
    return JsHandle(createElement(n));
  } else
    return parent;
}

template indexOfPred(alias Pred, TList...) {
  enum indexOfPred = indexOf!(Pred, TList).index;
}

template indexOf(alias Pred, args...) {
  import std.meta : AliasSeq;
  static if (args.length > 0) {
    static if (Pred!(args[0])) {
      enum index = 0;
    } else {
      enum next = indexOf!(Pred, AliasSeq!(args[1..$])).index;
      enum index = (next == -1) ? -1 : 1 + next;
    }
  } else {
    enum index = -1;
  }
}

template domName(string name) {
  import std.algorithm : stripRight;
  import std.conv : text;
  static if (name[$-1] == '_')
    enum domName = name[0..$-1];
  else
    enum domName = name;
}

template join(Seq...) {
  static if (is(typeof(Seq) == string))
    enum join = Seq;
  else {
    static if (Seq.length == 1) {
      enum join = Seq[0];
    }
    else {
      enum join = Seq[0] ~ "," ~ join!(Seq[1 .. $]);
    }
  }
}
