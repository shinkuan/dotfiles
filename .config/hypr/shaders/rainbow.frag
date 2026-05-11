uniform float time;

void windowShader(inout vec4 color) {
    vec3 sineColor = 0.5 + 0.5 * cos(time + vec3(0, 2, 4));
    color.rgb = mix(color.rgb, sineColor, 0.3); 
}