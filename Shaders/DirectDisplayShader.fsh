uniform sampler2D videoFrame;

varying highp vec2 tc0;
varying highp vec2 tc1;
varying highp vec2 tc2;
varying highp vec2 tc3;
varying highp vec2 tc4;
varying highp vec2 tc5;
varying highp vec2 tc6;
varying highp vec2 tc7;

precision mediump float;

void main() {
    float lum = dot(vec4(abs(dot(texture2D(videoFrame, tc1), vec4(.25)) -
                             dot(texture2D(videoFrame, tc6), vec4(.25))),
                         abs(dot(texture2D(videoFrame, tc4), vec4(.25)) -
                             dot(texture2D(videoFrame, tc3), vec4(.25))),
                         abs(dot(texture2D(videoFrame, tc0), vec4(.25)) -
                             dot(texture2D(videoFrame, tc7), vec4(.25))),
                         abs(dot(texture2D(videoFrame, tc2), vec4(.25)) -
                             dot(texture2D(videoFrame, tc5), vec4(.25)))),
                    vec4(.25));
    gl_FragColor = lum < 0.055 ? vec4(1.0) : vec4(0.0);
}

