attribute vec4 position;
attribute vec4 inputTextureCoordinate;

varying vec2 tc0;
varying vec2 tc1;
varying vec2 tc2;
varying vec2 tc3;
varying vec2 tc4;
varying vec2 tc5;
varying vec2 tc6;
varying vec2 tc7;

void main() {
    const float dxtex = 1.0 / 480.0;
    const float dytex = 1.0 / 640.0;
    
	gl_Position = position;
    
    tc0 = inputTextureCoordinate.xy + vec2(-dxtex, -dytex);
    tc1 = inputTextureCoordinate.xy + vec2(-dxtex, 0.0);
    tc2 = inputTextureCoordinate.xy + vec2(-dxtex, dytex);
    tc3 = inputTextureCoordinate.xy + vec2(0.0, -dytex);
    tc4 = inputTextureCoordinate.xy + vec2(-0.0, dytex);
    tc5 = inputTextureCoordinate.xy + vec2(dxtex, -dytex);
    tc6 = inputTextureCoordinate.xy + vec2(dxtex, 0.0);
    tc7 = inputTextureCoordinate.xy + vec2(dxtex, dytex);
}