import spasm.bindings;
import spasm.dom;
import spasm.types;

void get_shaders(void delegate(string) callback){
    auto promise = window.fetch(RequestInfo("https://reqres.in/api/users/2"));
    promise.then(r => r.json).then((data){
        callback(data.as!(Json).data.avatar.as!string);
    });
}

/** Export to JS Side */
extern (C) export void _start(){
    get_shaders((data) => console.log(data));
}