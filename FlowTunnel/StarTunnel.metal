#include <metal_stdlib>
using namespace metal;

struct StarUniforms {
    float time;
    float speed;
    float stretch;
    float blur;
    float density;
    float size;
    float2 resolution;
    float blackHoleRadius;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut starTunnelVertex(uint vertexID [[vertex_id]],
                                  constant float2 *vertices [[buffer(0)]]) {
    VertexOut out;
    float2 pos = vertices[vertexID];
    out.position = float4(pos, 0.0, 1.0);
    out.uv = pos * 0.5 + 0.5;
    return out;
}

// Hash function for pseudo-random star placement
float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

fragment float4 starTunnelFragment(VertexOut in [[stage_in]],
                                    constant StarUniforms &uniforms [[buffer(0)]]) {
    float2 fragCoord = in.uv * uniforms.resolution;
    float2 uv = (fragCoord - 0.5 * uniforms.resolution) / uniforms.resolution.y;

    // Save pre-distortion UV for event horizon + glow compositing
    float2 uv_original = uv;
    float bhR = uniforms.blackHoleRadius;
    if (bhR > 0.0) {
        float r = length(uv);
        // Schwarzschild-inspired lensing: displacement ~ R²/r²
        float deflection = (bhR * bhR) / (r * r + 0.001);
        uv = uv * (1.0 + deflection);
    }

    float t = uniforms.time * uniforms.speed;

    int numLayers = int(mix(10.0, 40.0, uniforms.density));
    float threshold = mix(0.7, 0.5, uniforms.density);

    // Star radius from size uniform, blur widens the glow
    float baseRadius = uniforms.size * 0.06;
    float glowWidth = mix(0.3, 2.0, uniforms.blur);

    float3 col = float3(0.0);

    for (int i = 0; i < numLayers; i++) {
        float depth = fract(float(i) / float(numLayers) + t * 0.15);
        float scale = mix(20.0, 0.5, depth);
        float fade = depth * smoothstep(0.0, 0.1, depth) * smoothstep(1.0, 0.8, depth);

        float2 gridUV = uv * scale;
        float2 cellID = floor(gridUV);
        
        float rnd = hash21(cellID + float(i) * 134.51);

        if (rnd >= threshold) {
            // Star position within cell
            float2 starPos = float2(hash21(cellID * 1.1 + float(i) * 73.0),
                                     hash21(cellID * 2.3 + float(i) * 91.0)) - 0.5;
            starPos *= 0.8;

            // Delta from this fragment to the star center (in grid space)
            float2 delta = gridUV - (cellID + 0.5 + starPos);

            float dist;
            if (uniforms.stretch > 0.0) {
                // Radial stretch from screen center
                float2 worldPos = (cellID + 0.5 + starPos) / scale;
                float radLen = length(worldPos);
                float2 radialDir = radLen > 1e-5 ? worldPos / radLen : float2(0.0, 1.0);
                float radialComponent = dot(delta, radialDir);
                float2 tangent = delta - radialComponent * radialDir;
                float tangentLen = length(tangent);
                float stretchFactor = 1.0 + uniforms.stretch * depth * 3.0;
                dist = sqrt(tangentLen * tangentLen +
                            (radialComponent / stretchFactor) * (radialComponent / stretchFactor));
            } else {
                dist = length(delta);
            }

            // Smooth falloff: Gaussian-ish glow centered on baseRadius
            float brightness = exp(-dist * dist / (baseRadius * baseRadius * glowWidth));
            brightness *= fade;

            float3 starColor = mix(float3(0.8, 0.85, 1.0),
                                    float3(0.6, 0.7, 1.0),
                                    hash21(cellID + 42.0));
            col += starColor * brightness;
        }
    }

    // Tone map
    col = 1.0 - exp(-col * 1.5);

    // Black hole: event horizon (black disk)
    if (bhR > 0.0) {
        float r_orig = length(uv_original);
        float edgeSoftness = 0.003;
        float horizonMask = smoothstep(bhR - edgeSoftness, bhR + edgeSoftness, r_orig);
        col *= horizonMask;
    }

    return float4(col, 1.0);
}
