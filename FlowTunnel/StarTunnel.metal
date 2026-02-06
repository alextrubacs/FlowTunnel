#include <metal_stdlib>
using namespace metal;

struct StarUniforms {
    float time;
    float speed;
    float stretch;
    float blur;
    float density;
    float2 resolution;
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

    float t = uniforms.time * uniforms.speed;

    // Number of depth layers based on density
    int numLayers = int(mix(10.0, 40.0, uniforms.density));

    float3 col = float3(0.0);

    for (int i = 0; i < numLayers; i++) {
        // Depth for this layer, cycling forward with time
        float depth = fract(float(i) / float(numLayers) + t * 0.15);

        // Scale factor — smaller depth = further away
        float scale = mix(20.0, 0.5, depth);

        // Fade: dim when far, bright when close, fade out right at camera
        float fade = depth * smoothstep(0.0, 0.1, depth) * smoothstep(1.0, 0.8, depth);

        // Grid coordinates at this depth
        float2 gridUV = uv * scale;
        float2 cellID = floor(gridUV);
        float2 cellUV = fract(gridUV) - 0.5;

        // Random value per cell to decide star presence and position
        float rnd = hash21(cellID + float(i) * 134.51);

        // Only ~30-50% of cells have a star (adjusted by density)
        float threshold = mix(0.7, 0.5, uniforms.density);
        if (rnd > threshold) {
            // Star position within cell (random offset)
            float2 starPos = float2(hash21(cellID * 1.1 + float(i) * 73.0),
                                     hash21(cellID * 2.3 + float(i) * 91.0)) - 0.5;
            starPos *= 0.8; // Keep stars away from cell edges

            float2 delta = cellUV - starPos;

            // Apply radial stretch from screen center
            if (uniforms.stretch > 0.0) {
                // Direction from center in screen space
                float2 worldPos = (cellID + cellUV + 0.5) / scale;
                float2 radialDir = normalize(worldPos + 1e-6);
                // Stretch along radial direction
                float radialComponent = dot(delta, radialDir);
                float tangentComponent = length(delta - radialComponent * radialDir);
                float stretchFactor = 1.0 + uniforms.stretch * depth * 3.0;
                float dist = sqrt(tangentComponent * tangentComponent +
                                   (radialComponent / stretchFactor) * (radialComponent / stretchFactor));
                float starSize = mix(0.01, 0.05, uniforms.blur);
                float brightness = starSize / (dist + 0.001);
                brightness = smoothstep(0.0, 1.0, brightness);
                brightness *= fade;

                // Slight color variation
                float3 starColor = mix(float3(0.8, 0.85, 1.0),
                                        float3(0.6, 0.7, 1.0),
                                        hash21(cellID + 42.0));
                col += starColor * brightness;
            } else {
                float dist = length(delta);
                float starSize = mix(0.01, 0.05, uniforms.blur);
                float brightness = starSize / (dist + 0.001);
                brightness = smoothstep(0.0, 1.0, brightness);
                brightness *= fade;

                float3 starColor = mix(float3(0.8, 0.85, 1.0),
                                        float3(0.6, 0.7, 1.0),
                                        hash21(cellID + 42.0));
                col += starColor * brightness;
            }
        }
    }

    // Tone map to prevent blowout
    col = 1.0 - exp(-col * 1.5);

    return float4(col, 1.0);
}
