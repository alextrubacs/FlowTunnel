/// Star Tunnel Fragment Shader
/// Renders a volumetric star tunnel with gravitational lensing around a central black hole.
/// Stars fly from the vanishing point (center) toward the viewer, creating a warp-speed effect.

#include <metal_stdlib>
using namespace metal;

/// Uniform parameters passed from Swift for shader customization
struct StarUniforms {
    float time;              ///< Elapsed time in seconds (drives animation)
    float speed;             ///< Animation speed multiplier (controls star velocity)
    float stretch;           ///< Radial stretch factor (elongates stars along rays from center)
    float blur;              ///< Glow width (controls star softness)
    float density;           ///< Star field density (controls layer count and star frequency)
    float size;              ///< Base star size (controls point brightness falloff)
    float2 resolution;       ///< Screen dimensions in pixels
    float blackHoleRadius;   ///< Event horizon radius in normalized UV space (0 = disabled)
    float blackHoleWarp;     ///< Lensing strength multiplier (0-3, controls deflection intensity)
    float enableEDR;         ///< 1.0 if EDR/HDR output is available, 0.0 for SDR displays
};

/// Output structure for vertex shader
struct VertexOut {
    float4 position [[position]];  ///< Final screen position
    float2 uv;                     ///< Normalized texture coordinates (0-1)
};

/// Vertex Shader - Simple fullscreen quad pass-through
/// Takes pre-computed quad vertices and outputs them with normalized UV coordinates.
/// @param vertexID The vertex index (0-5 for fullscreen triangle pair)
/// @param vertices Pre-computed quad vertices in clip space (-1 to 1)
vertex VertexOut starTunnelVertex(uint vertexID [[vertex_id]],
                                  constant float2 *vertices [[buffer(0)]]) {
    VertexOut out;
    float2 pos = vertices[vertexID];                    // Get quad vertex position
    out.position = float4(pos, 0.0, 1.0);              // Output to clip space
    out.uv = pos * 0.5 + 0.5;                          // Convert to UV range [0,1]
    return out;
}

/// Pseudo-random hash function for star placement
/// Generates consistent pseudo-random values from 2D coordinates using trigonometric hashing.
/// @param p Grid coordinate (integer cell ID)
/// @return Random float in range [0, 1]
float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));            // Multiply and take fractional part
    p += dot(p, p + 45.32);                            // Self-referential mixing step
    return fract(p.x * p.y);                           // Final mix and normalize
}

/// Main Fragment Shader - Renders the star tunnel with lensing
/// For each pixel, samples multiple depth layers of procedurally-generated stars,
/// applies gravitational lensing distortion, and composites the result.
/// @param in Vertex output containing screen position and UV coordinates
/// @param uniforms Runtime parameters from Swift
fragment float4 starTunnelFragment(VertexOut in [[stage_in]],
                                    constant StarUniforms &uniforms [[buffer(0)]]) {
    // ===== UV Setup =====
    float2 fragCoord = in.uv * uniforms.resolution;
    // Convert from pixel coordinates to centered UV space (-1 to 1)
    // Aspect ratio corrected: normalized by screen height for square proportions
    float2 uv = (fragCoord - 0.5 * uniforms.resolution) / uniforms.resolution.y;

    // Save original (pre-lensing) UV for event horizon rendering
    float2 uv_original = uv;
    float bhR = uniforms.blackHoleRadius;

    // ===== Gravitational Lensing (Einstein Ring Effect) =====
    if (bhR > 0.0) {
        float r = length(uv);                          // Distance from center
        // Schwarzschild-inspired deflection: R²/r² formula
        // Creates physical light-bending around the black hole
        float deflection = uniforms.blackHoleWarp * (bhR * bhR) / (r * r + 0.001);
        uv = uv * (1.0 + deflection);                  // Push UV outward (light appears bent)
    }

    // ===== Time and Layer Setup =====
    float t = uniforms.time * uniforms.speed;          // Scaled time for animation

    // Determine how many depth layers to render based on density
    int numLayers = int(mix(10.0, 40.0, uniforms.density)); // 10-40 layers
    // Threshold for star presence (higher density = more stars, lower threshold)
    float threshold = mix(0.7, 0.5, uniforms.density);

    // Star appearance parameters
    float baseRadius = uniforms.size * 0.06;           // Base star size
    float glowWidth = mix(0.3, 2.0, uniforms.blur);    // Glow falloff width

    float3 col = float3(0.0);                          // Accumulate star colors

    // ===== Layer Loop - Volumetric Rendering =====
    for (int i = 0; i < numLayers; i++) {
        // Compute depth cycling forward with time (creates fly-through effect)
        float depth = fract(float(i) / float(numLayers) + t * 0.15);

        // Scale: near layers (depth ≈ 1) are fine-grained, far layers (depth ≈ 0) are coarse
        float scale = mix(20.0, 0.5, depth);

        // Fade: dim at far (depth ≈ 0) and near (depth ≈ 1), bright in middle
        float fade = depth * smoothstep(0.0, 0.1, depth) * smoothstep(1.0, 0.8, depth);

        // Grid coordinates at this depth
        float2 gridUV = uv * scale;
        float2 cellID = floor(gridUV);                 // Which grid cell we're in

        // Determine if this cell contains a star
        float rnd = hash21(cellID + float(i) * 134.51);

        // Only render stars for ~50-70% of cells (controlled by density)
        if (rnd >= threshold) {
            // Random position within the cell (keeps stars away from edges)
            float2 starPos = float2(hash21(cellID * 1.1 + float(i) * 73.0),
                                     hash21(cellID * 2.3 + float(i) * 91.0)) - 0.5;
            starPos *= 0.8;                            // Scale offset to 80% of cell size

            // Vector from current fragment to this star
            float2 delta = gridUV - (cellID + 0.5 + starPos);

            float dist;
            // ===== Distance Calculation (with optional stretch) =====
            if (uniforms.stretch > 0.0) {
                // Radial stretch: elongate stars along rays from screen center
                float2 worldPos = (cellID + 0.5 + starPos) / scale;
                float radLen = length(worldPos);
                // Direction vector from center to this star
                float2 radialDir = radLen > 1e-5 ? worldPos / radLen : float2(0.0, 1.0);
                // Decompose delta into radial and tangential components
                float radialComponent = dot(delta, radialDir);
                float2 tangent = delta - radialComponent * radialDir;
                float tangentLen = length(tangent);
                // Compress distance along radial direction (creates streaks)
                float stretchFactor = 1.0 + uniforms.stretch * depth * 3.0;
                dist = sqrt(tangentLen * tangentLen +
                            (radialComponent / stretchFactor) * (radialComponent / stretchFactor));
            } else {
                // Simple Euclidean distance
                dist = length(delta);
            }

            // ===== Star Brightness - Gaussian Glow =====
            // Exponential falloff creates smooth glow around each star point
            float brightness = exp(-dist * dist / (baseRadius * baseRadius * glowWidth));
            brightness *= fade;                        // Modulate by depth fade

            // ===== Star Color - Pure white with slight variation =====
            float3 starColor = mix(float3(1.0, 1.0, 1.0),   // Pure white
                                    float3(0.95, 0.95, 1.0), // Bright blue-white
                                    hash21(cellID + 42.0));  // Per-cell variation
            col += starColor * brightness * 1.5;       // Accumulate with brightness boost
        }
    }

    // ===== Tone Mapping with Optional EDR Headroom =====
    // Exponential compression to SDR range
    col = 1.0 - exp(-col * 1.0);
    // EDR boost: only apply on HDR-capable displays to avoid clamping on SDR
    if (uniforms.enableEDR > 0.5) {
        // Bright pixels get amplified beyond SDR white for HDR displays
        col *= 1.0 + col * 1.5;
    }

    // ===== Black Hole Event Horizon =====
    if (bhR > 0.0) {
        float r_orig = length(uv_original);            // Distance in original (non-lensed) space
        float edgeSoftness = 0.003;                    // Anti-alias edge width
        // Smooth step creates anti-aliased black disk boundary
        float horizonMask = smoothstep(bhR - edgeSoftness, bhR + edgeSoftness, r_orig);
        col *= horizonMask;                            // Multiply by mask (0 inside, 1 outside)
    }

    return float4(col, 1.0);                           // Output final color with full opacity
}
