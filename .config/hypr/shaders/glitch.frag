// Hyprland 內建變數
uniform vec2 fullSize; 
uniform vec2 topLeft;
uniform sampler2D tex; 

// 我們自己加入的時間變數 (需要你的 PR)
uniform float time;

#define DURATION 10.
#define AMT .1
#define SS(a, b, x) (smoothstep(a, b, x) * smoothstep(b, a, x))

// 修正 uvec 定義以相容部分 GLSL 版本
#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UIF (1. / float(0xffffffffU))

vec3 hash33(vec3 p)
{
    uvec3 q = uvec3(ivec3(p)) * UI3;
    q = (q.x ^ q.y ^ q.z) * UI3;
    return -1. + 2. * vec3(q) * UIF;
}

float gnoise(vec3 x)
{
    vec3 p = floor(x);
    vec3 w = fract(x);
    vec3 u = w * w * w * (w * (w * 6. - 15.) + 10.);
    vec3 ga = hash33(p + vec3(0., 0., 0.));
    vec3 gb = hash33(p + vec3(1., 0., 0.));
    vec3 gc = hash33(p + vec3(0., 1., 0.));
    vec3 gd = hash33(p + vec3(1., 1., 0.));
    vec3 ge = hash33(p + vec3(0., 0., 1.));
    vec3 gf = hash33(p + vec3(1., 0., 1.));
    vec3 gg = hash33(p + vec3(0., 1., 1.));
    vec3 gh = hash33(p + vec3(1., 1., 1.));
    float va = dot(ga, w - vec3(0., 0., 0.));
    float vb = dot(gb, w - vec3(1., 0., 0.));
    float vc = dot(gc, w - vec3(0., 1., 0.));
    float vd = dot(gd, w - vec3(1., 1., 0.));
    float ve = dot(ge, w - vec3(0., 0., 1.));
    float vf = dot(gf, w - vec3(1., 0., 1.));
    float vg = dot(gg, w - vec3(0., 1., 1.));
    float vh = dot(gh, w - vec3(1., 1., 1.));
    float gNoise = va + u.x * (vb - va) + 
            u.y * (vc - va) + 
            u.z * (ve - va) + 
            u.x * u.y * (va - vb - vc + vd) + 
            u.y * u.z * (va - vc - ve + vg) + 
            u.z * u.x * (va - vb - ve + vf) + 
            u.x * u.y * u.z * (-va + vb + vc - vd + ve - vf - vg + vh);
    return 2. * gNoise;
}

// 主函式改為 windowShader
void windowShader(inout vec4 color) {
    // 1. 計算 UV (將螢幕絕對座標轉換為視窗相對座標 0~1)
    vec2 uv = (gl_FragCoord.xy - topLeft) / fullSize;
    
    // 修正 y 軸方向 (如果發現畫面上下顛倒，請移除或修改這一行)
    // 一般 OpenGL 紋理座標是左下角為 0,0，但有時視窗內容是反的
    // uv.y = 1.0 - uv.y; 

    float t = time;
    
    // 模擬 iFrame
    float iFrame = time * 60.0;
    
    // 原始解析度參數
    vec2 iResolution = fullSize;

    float glitchAmount = SS(DURATION * .001, DURATION * AMT, mod(t, DURATION));  
    float displayNoise = 0.;
    vec3 col = vec3(0.);
    vec2 eps = vec2(5. / iResolution.x, 0.);
    vec2 st = vec2(0.);

    // Analog distortion logic
    float y = uv.y * iResolution.y;
    float distortion = gnoise(vec3(0., y * .01, t * 500.)) * (glitchAmount * 4. + .1);
    distortion *= gnoise(vec3(0., y * .02, t * 250.)) * (glitchAmount * 2. + .025);

    ++displayNoise;
    distortion += smoothstep(.999, 1., sin((uv.y + t * 1.6) * 2.)) * .02;
    distortion -= smoothstep(.999, 1., sin((uv.y + t) * 2.)) * .02;
    st = uv + vec2(distortion, 0.);
    
    // Chromatic aberration & Texture Sampling
    // 這裡我們直接採樣 tex，忽略原本輸入的 color
    // 注意：在 GLES 中通常使用 texture() 或 texture2D()
    col.r += texture(tex, st + eps + distortion).r;
    col.g += texture(tex, st).g;
    col.b += texture(tex, st - eps - distortion).b;
    
    // White noise + scanlines
    displayNoise = 0.2 * clamp(displayNoise, 0., 1.);
    
    // 用 gl_FragCoord 替換 fragCoord
    col += (.15 + .65 * glitchAmount) * (hash33(vec3(gl_FragCoord.xy, mod(iFrame, 1000.))).r) * displayNoise;
    col -= (.25 + .75 * glitchAmount) * (sin(4. * t + uv.y * iResolution.y * 1.75)) * displayNoise;
    
    // 輸出最終顏色
    color = vec4(col, 1.0);
}