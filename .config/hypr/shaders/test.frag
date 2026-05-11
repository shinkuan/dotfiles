#ifdef IS_EXT
    // EXT Hack
    uniform samplerExternalOES tex;
#endif

uniform float time;

#define DURATION 10.0
#define AMT 0.1
#define SS(a, b, x) (smoothstep(a, b, x) * smoothstep(b, a, x))

vec3 hash33(vec3 p) {
    p = vec3( dot(p, vec3(127.1, 311.7, 74.7)),
              dot(p, vec3(269.5, 183.3, 246.1)),
              dot(p, vec3(113.5, 271.9, 124.6)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float gnoise(vec3 x) {
    vec3 p = floor(x);
    vec3 w = fract(x);
    vec3 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
    
    vec3 ga = hash33(p + vec3(0.0, 0.0, 0.0));
    vec3 gb = hash33(p + vec3(1.0, 0.0, 0.0));
    vec3 gc = hash33(p + vec3(0.0, 1.0, 0.0));
    vec3 gd = hash33(p + vec3(1.0, 1.0, 0.0));
    vec3 ge = hash33(p + vec3(0.0, 0.0, 1.0));
    vec3 gf = hash33(p + vec3(1.0, 0.0, 1.0));
    vec3 gg = hash33(p + vec3(0.0, 1.0, 1.0));
    vec3 gh = hash33(p + vec3(1.0, 1.0, 1.0));
    
    float va = dot(ga, w - vec3(0.0, 0.0, 0.0));
    float vb = dot(gb, w - vec3(1.0, 0.0, 0.0));
    float vc = dot(gc, w - vec3(0.0, 1.0, 0.0));
    float vd = dot(gd, w - vec3(1.0, 1.0, 0.0));
    float ve = dot(ge, w - vec3(0.0, 0.0, 1.0));
    float vf = dot(gf, w - vec3(1.0, 0.0, 1.0));
    float vg = dot(gg, w - vec3(0.0, 1.0, 1.0));
    float vh = dot(gh, w - vec3(1.0, 1.0, 1.0));
    
    float gNoise = va + u.x * (vb - va) + 
            u.y * (vc - va) + 
            u.z * (ve - va) + 
            u.x * u.y * (va - vb - vc + vd) + 
            u.y * u.z * (va - vc - ve + vg) + 
            u.z * u.x * (va - vb - ve + vf) + 
            u.x * u.y * u.z * (-va + vb + vc - vd + ve - vf - vg + vh);
    return 2.0 * gNoise;
}

void windowShader(inout vec4 color) {
    vec2 uv = (gl_FragCoord.xy - topLeft) / fullSize;
    
    float t = time;
    float iFrame = time * 60.0;
    vec2 iResolution = fullSize;

    float glitchAmount = SS(DURATION * 0.001, DURATION * AMT, mod(t, DURATION));  
    float displayNoise = 0.0;
    vec3 col = vec3(0.0);
    vec2 eps = vec2(5.0 / iResolution.x, 0.0);
    vec2 st = vec2(0.0);

    float y = uv.y * iResolution.y;
    float distortion = gnoise(vec3(0.0, y * 0.01, t * 500.0)) * (glitchAmount * 4.0 + 0.1);
    distortion *= gnoise(vec3(0.0, y * 0.02, t * 250.0)) * (glitchAmount * 2.0 + 0.025);

    displayNoise += 1.0;
    distortion += smoothstep(0.999, 1.0, sin((uv.y + t * 1.6) * 2.0)) * 0.02;
    distortion -= smoothstep(0.999, 1.0, sin((uv.y + t) * 2.0)) * 0.02;
    st = uv + vec2(distortion, 0.0);
    
    col.r += texture(tex, st + eps + distortion).r;
    col.g += texture(tex, st).g;
    col.b += texture(tex, st - eps - distortion).b;
    
    displayNoise = 0.2 * clamp(displayNoise, 0.0, 1.0);
    
    col += (0.15 + 0.65 * glitchAmount) * (hash33(vec3(gl_FragCoord.xy, mod(iFrame, 1000.0))).r) * displayNoise;
    col -= (0.25 + 0.75 * glitchAmount) * (sin(4.0 * t + uv.y * iResolution.y * 1.75)) * displayNoise;
    
    color = vec4(col, texture(tex, st).a);
}