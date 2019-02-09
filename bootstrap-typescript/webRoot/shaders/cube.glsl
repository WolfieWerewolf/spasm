//VERTEX
#version 300 es
in vec2 in_position;
uniform vec2 un_resolution;
void main() {
    vec2 clipSpace = (2.0 * in_position/un_resolution - 1.0) * vec2(1, -1);
    gl_Position = vec4(clipSpace, 0, 1);
}

//FRAGMENT
#version 300 es
precision mediump float;
uniform vec4 un_color;
out vec4 outColor;
void main() {
    outColor = un_color;
}