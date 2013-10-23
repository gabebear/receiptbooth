varying highp vec2 textureCoordinate;

uniform sampler2D videoFrame;
precision mediump float;
void main() {
    float luminance;
    
    // compute luminance weighted toward visible color spectrum
    luminance = dot(vec4(0.30, 0.59, 0.11, 0.0), texture2D(videoFrame, textureCoordinate));
    
    // add noise computed from texture coordinate
    luminance += (0.35*fract(sin(dot(textureCoordinate.xy ,vec2(12.9898,78.233))) * 43758.5453));
    
    // set to black or white depending on value
    gl_FragColor = (luminance > 0.65)  ?  vec4(1.0) : vec4(0.0);
}
