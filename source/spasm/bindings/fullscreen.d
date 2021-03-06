module spasm.bindings.fullscreen;

import spasm.types;
import spasm.bindings.html;

enum FullscreenNavigationUI {
  auto_,
  show,
  hide
}
struct FullscreenOptions {
  JsHandle handle;
  alias handle this;
  static auto create() {
    return FullscreenOptions(JsHandle(spasm_add__object()));
  }
  void navigationUI(FullscreenNavigationUI navigationUI) {
    FullscreenOptions_navigationUI_Set(this.handle, navigationUI);
  }
  auto navigationUI() {
    return FullscreenOptions_navigationUI_Get(this.handle);
  }
}


extern (C) void FullscreenOptions_navigationUI_Set(Handle, FullscreenNavigationUI);
extern (C) FullscreenNavigationUI FullscreenOptions_navigationUI_Get(Handle);