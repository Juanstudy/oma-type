#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float ditherIntensity;
    float colorLevels;
    float ditherEnabled;
    float vignetteEnabled;
    float itemWidth;
    float itemHeight;
    float cornerRadius;
    float cellSize;
    float adaptiveDim;
};

layout(binding = 1) uniform sampler2D source;

// Bayer 8x8 matrix normalized to 0.0 .. 1.0
const float bayer8[64] = float[64](
     0.0/64.0, 32.0/64.0,  8.0/64.0, 40.0/64.0,  2.0/64.0, 34.0/64.0, 10.0/64.0, 42.0/64.0,
    48.0/64.0, 16.0/64.0, 56.0/64.0, 24.0/64.0, 50.0/64.0, 18.0/64.0, 58.0/64.0, 26.0/64.0,
    12.0/64.0, 44.0/64.0,  4.0/64.0, 36.0/64.0, 14.0/64.0, 46.0/64.0,  6.0/64.0, 38.0/64.0,
    60.0/64.0, 28.0/64.0, 52.0/64.0, 20.0/64.0, 62.0/64.0, 30.0/64.0, 54.0/64.0, 22.0/64.0,
     3.0/64.0, 35.0/64.0, 11.0/64.0, 43.0/64.0,  1.0/64.0, 33.0/64.0,  9.0/64.0, 41.0/64.0,
    51.0/64.0, 19.0/64.0, 59.0/64.0, 27.0/64.0, 49.0/64.0, 17.0/64.0, 57.0/64.0, 25.0/64.0,
    15.0/64.0, 47.0/64.0,  7.0/64.0, 39.0/64.0, 13.0/64.0, 45.0/64.0,  5.0/64.0, 37.0/64.0,
    63.0/64.0, 31.0/64.0, 55.0/64.0, 23.0/64.0, 61.0/64.0, 29.0/64.0, 53.0/64.0, 21.0/64.0
);

void main() {
    // Exact rounded corner clipping (SDF) to match BorderSurface corner radius
    float cornerAlpha = 1.0;
    if (cornerRadius > 0.5 && itemWidth > 1.0 && itemHeight > 1.0) {
        vec2 halfSize = vec2(itemWidth, itemHeight) * 0.5;
        vec2 p = abs((qt_TexCoord0 - vec2(0.5)) * vec2(itemWidth, itemHeight));
        vec2 q = p - (halfSize - vec2(cornerRadius));
        float dist = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - cornerRadius;
        if (dist > 0.5) {
            discard;
        }
        cornerAlpha = clamp(0.5 - dist, 0.0, 1.0);
    }

    vec4 c = texture(source, qt_TexCoord0);

    // Linear vertical dither dissolve (when vignette is enabled)
    float v = 1.0;
    if (vignetteEnabled > 0.5) {
        float y = qt_TexCoord0.y;
        float yTopSolid = 0.08;
        float yTopFade  = 0.22;
        float yBotFade  = 0.78;
        float yBotSolid = 0.92;

        if (y <= yTopSolid) {
            v = 1.0;
        } else if (y < yTopFade) {
            float t = (yTopFade - y) / (yTopFade - yTopSolid);
            v = t * t * (3.0 - 2.0 * t);
        } else if (y <= yBotFade) {
            v = 0.0;
        } else if (y < yBotSolid) {
            float t = (y - yBotFade) / (yBotSolid - yBotFade);
            v = t * t * (3.0 - 2.0 * t);
        } else {
            v = 1.0;
        }
    }

    if (ditherEnabled < 0.5) {
        // Blur / direct image only: smooth premultiplied alpha fade
        float lum = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
        c.rgb *= (1.0 - adaptiveDim * smoothstep(0.35, 0.85, lum));
        float finalAlpha = c.a * v * cornerAlpha;
        fragColor = vec4(c.rgb * finalAlpha, finalAlpha) * qt_Opacity;
        return;
    }

    // Bayer 8x8 ordered dithering + quantization (pattern replicated in cellSize blocks)
    float cs = max(cellSize, 1.0);
    int x = int(mod(floor(gl_FragCoord.x / cs), 8.0));
    int y = int(mod(floor(gl_FragCoord.y / cs), 8.0));
    float bayerVal = bayer8[y * 8 + x];
    float threshold = bayerVal - 0.5;

    float levels = max(colorLevels, 2.0);
    // Ordered dithering spreads across the quantization step
    vec3 dithered = c.rgb + threshold * (ditherIntensity * (1.0 / levels) * 1.5);
    
    // Color levels quantization (discrete bands)
    dithered = floor(dithered * levels + 0.5) / levels;

    // Luminance-adaptive scrim: darken only bright pixels (clouds) so light text
    // stays readable; dark sky keeps its dither pattern and vibrancy untouched.
    float lum = dot(clamp(dithered, 0.0, 1.0), vec3(0.2126, 0.7152, 0.0722));
    dithered *= (1.0 - adaptiveDim * smoothstep(0.35, 0.85, lum));

    float dissolve = (v >= 0.99) ? 1.0 : clamp((v - bayerVal) / 0.18 + 0.5, 0.0, 1.0) * smoothstep(0.0, 0.05, v);
    float finalAlpha = c.a * dissolve * cornerAlpha;

    // Premultiplied alpha for Qt Quick Scene Graph
    fragColor = vec4(clamp(dithered, 0.0, 1.0) * finalAlpha, finalAlpha) * qt_Opacity;
}
