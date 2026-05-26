#define MAX_COLORS 16

uniform float count;
uniform vec3  bkg[MAX_COLORS];
uniform float similarity[MAX_COLORS];
uniform float amount[MAX_COLORS];
uniform float targetOpacity[MAX_COLORS];

bool isColorSimilar(vec3 color, vec3 target, float sim) {
    return all(greaterThanEqual(color, target - sim)) &&
           all(lessThanEqual(color, target + sim));
}

void windowShader(inout vec4 color) {
    int n = int(count);
    if (n > MAX_COLORS) n = MAX_COLORS;

    float factor = 1.0; // 1.0 = unchanged
    for (int i = 0; i < MAX_COLORS; i++) {
        if (i >= n) break;
        if (!isColorSimilar(color.rgb, bkg[i], similarity[i])) continue;

        vec3 err = abs(color.rgb - bkg[i]);
        float avg = (err.r + err.g + err.b) / 3.0;
        float f = targetOpacity[i] + (1.0 - targetOpacity[i]) * avg * amount[i] / similarity[i];
        factor = min(factor, f);
    }

    color *= factor;
}
