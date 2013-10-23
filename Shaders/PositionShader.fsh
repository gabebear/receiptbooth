varying highp vec2 textureCoordinate;

uniform sampler2D videoFrame;
precision mediump float;
void main() {
    float luminance;
    
    // compute luminance weighted toward visible color spectrum
    luminance = dot(vec4(0.30, 0.59, 0.11, 0.0), texture2D(videoFrame, textureCoordinate));
    
    // set to black or white depending on value
    gl_FragColor = (luminance > 0.45)  ?  vec4(1.0) : vec4(0.0);
}

