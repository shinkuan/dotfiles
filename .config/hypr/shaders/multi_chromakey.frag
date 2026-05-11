#define MAX_COLORS 16

uniform float count; 

uniform vec3 bkg[MAX_COLORS];
uniform float similarity[MAX_COLORS];
uniform float amount[MAX_COLORS];
uniform float targetOpacity[MAX_COLORS];

bool isColorSimilar(vec3 color, vec3 target, float sim) {
    return color.r >= target.r - sim && color.r <= target.r + sim &&
           color.g >= target.g - sim && color.g <= target.g + sim &&
           color.b >= target.b - sim && color.b <= target.b + sim;
}

void windowShader(inout vec4 color) {
    int loopCount = int(count);
    
    if (loopCount > MAX_COLORS) loopCount = MAX_COLORS;

    for (int i = 0; i < MAX_COLORS; i++) {
        if (i >= loopCount) break;

        vec3 currentBkg = bkg[i];
        float currentSim = similarity[i];
        
        if (isColorSimilar(color.rgb, currentBkg, currentSim)) {
            float currentAmt = amount[i];
            float currentOp = targetOpacity[i];

            vec3 error = abs(color.rgb - currentBkg);
            float avg_error = (error.r + error.g + error.b) / 3.0;

            float factor = currentOp + (1.0 - currentOp) * avg_error * currentAmt / currentSim;
            
            color *= factor;
            break; 
        }
    }
}