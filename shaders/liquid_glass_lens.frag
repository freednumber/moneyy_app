// File: shaders/liquid_glass_lens.frag
// (Preso da lucasxu0/liquid_glass)
#include <flutter/runtime_effect.glsl>

precision mediump float;

out vec4 fragColor;

uniform vec2 uResolution;
uniform float uTime;
uniform float uDistortion;
uniform float uRefraction;
uniform float uReflectance;
uniform float uBlur;
uniform float uNoise;

uniform sampler2D uBackgroundTexture;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.y * u.x;
}

vec4 lensDistortion(vec2 uv, float distortion, float refraction, float reflectance, float blur, float noiseAmount) {
    vec2 ndc = uv * 2.0 - 1.0;
    float r2 = dot(ndc, ndc);
    vec2 distortedUV = uv;

    // Distorsione a barile (Barrel distortion)
    if (distortion > 0.0) {
        float distortionFactor = 1.0 + distortion * r2;
        distortedUV = 0.5 + ndc * distortionFactor * 0.5;
    }

    // Aberrazione cromatica (simulata)
    vec2 refractionVec = normalize(ndc) * (r2 * refraction);
    
    // Campionamento del background con distorsione e rifrazione
    vec4 background = texture(uBackgroundTexture, distortedUV - refractionVec * 0.01);
    vec4 backgroundR = texture(uBackgroundTexture, distortedUV - refractionVec * 0.02);
    vec4 backgroundG = texture(uBackgroundTexture, distortedUV - refractionVec * 0.005);
    vec4 backgroundB = texture(uBackgroundTexture, distortedUV + refractionVec * 0.01);

    vec4 color = vec4(backgroundR.r, backgroundG.g, backgroundB.b, background.a);

    // Sfocatura basata sulla distanza dal centro
    float blurAmount = r2 * blur;
    if (blurAmount > 0.0) {
        vec4 blurredColor = vec4(0.0);
        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                vec2 offset = vec2(float(x), float(y)) * blurAmount / uResolution.xy;
                blurredColor += texture(uBackgroundTexture, distortedUV + offset);
            }
        }
        color = mix(color, blurredColor / 9.0, blurAmount);
    }

    // Riflettanza (simula un bordo più luminoso)
    float edgeFactor = 1.0 - smoothstep(0.9, 1.0, r2);
    float reflectanceAmount = (1.0 - edgeFactor) * reflectance;
    color = mix(color, vec4(1.0), reflectanceAmount * color.a);

    // Rumore
    float noiseValue = noise(uv * 100.0 + uTime * 0.1) * 2.0 - 1.0;
    color.rgb += noiseValue * noiseAmount;

    // Maschera per i bordi (per tagliare l'effetto se esce)
    color.a *= edgeFactor;
    
    return color;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution.xy;
    fragColor = lensDistortion(uv, uDistortion, uRefraction, uReflectance, uBlur, uNoise);
}
