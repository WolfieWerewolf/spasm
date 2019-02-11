import spasm.bindings;
import spasm.dom;
import spasm.types;

struct Rect {
    float x;
    float y;
    float size;
    float min_size;
    float max_size;
    float r;
    float g;
    float b;
    float grow_speed;
    bool growin;
}

void get_shaders(void delegate(string) callback){
    auto promise = window.fetch(RequestInfo("/shaders/cube.glsl"));
    promise.then(r => r.text).then((data){
        callback(data.as!(string));
    });
}

void init_webgl(string data){

    auto canvas = document.getElementById("glCanvas");
    console.log(canvas);
    //console.log("init_webgl");

    //console.log(data);

    //console.log("init_webgl--- calling getElementById-----");
    //auto canvas = document.createElement("canvas").as!HTMLElement;
    //canvas.id = "glCanvas";
    //console.log(canvas);

    //auto canvas = document.getElementById("glCanvas");
    //console.log(canvas);

    }

/** Export to JS Side */
extern (C) export void _start(){
    get_shaders((data) => init_webgl(data));
}