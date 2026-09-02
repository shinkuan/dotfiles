#version 440

// Screen frame with panels blended into it: an inverted rounded rect
// (the frame) smooth-unioned with up to four rounded rects, all in item
// pixels. Panels with zero size are skipped.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    vec4 frame;        // band thickness: left, top, right, bottom
    float rounding;    // inner corner radius of the frame
    float smoothing;   // blend distance between frame and panels
    vec4 color;
    vec4 shadowColor;  // rgb + strength
    vec4 p0;           // x, y, width, height
    vec4 p1;
    vec4 p2;
    vec4 p3;
    vec4 radii;
};

float box(vec2 p, vec2 c, vec2 hs, float r) {
    r = min(r, min(hs.x, hs.y));
    vec2 q = abs(p - c) - hs + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float rect(vec2 p, vec4 rc, float r) {
    if (rc.z <= 0.0 || rc.w <= 0.0)
        return 1e5;
    return box(p, rc.xy + rc.zw * 0.5, rc.zw * 0.5, r);
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

void main() {
    vec2 p = qt_TexCoord0 * size;
    vec2 lo = frame.xy;
    vec2 hi = size - frame.zw;
    float d = -box(p, (lo + hi) * 0.5, (hi - lo) * 0.5, rounding);
    float k = max(smoothing, 0.001);
    d = smin(d, rect(p, p0, radii.x), k);
    d = smin(d, rect(p, p1, radii.y), k);
    d = smin(d, rect(p, p2, radii.z), k);
    d = smin(d, rect(p, p3, radii.w), k);
    float fill = 1.0 - smoothstep(-0.7, 0.7, d);
    float shade = (1.0 - smoothstep(0.0, 22.0, d)) * shadowColor.a * (1.0 - fill);
    vec3 rgb = color.rgb * color.a * fill + shadowColor.rgb * shade;
    fragColor = vec4(rgb, color.a * fill + shade) * qt_Opacity;
}
