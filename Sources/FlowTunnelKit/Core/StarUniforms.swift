/// Uniform parameter struct passed to Metal shaders.
///
/// This struct mirrors the `StarUniforms` struct in `StarTunnel.metal`.
/// Field order and types must **exactly match** for proper memory layout.
///
/// ## Memory Layout Requirements
/// Metal expects this struct to be tightly packed with no padding. The order of fields
/// here must match the shader definition exactly, or rendering will be corrupted.
///
/// - Important: Do not reorder fields or change types without updating the Metal shader.
public struct StarUniforms: Sendable {
    /// Elapsed time in seconds (drives animation).
    var time: Float

    /// Animation speed multiplier (controls star velocity).
    var speed: Float

    /// Radial stretch factor (elongates stars along rays from center).
    var stretch: Float

    /// Glow width (controls star softness).
    var blur: Float

    /// Star field density (controls layer count and star frequency).
    var density: Float

    /// Base star size (controls point brightness falloff).
    var size: Float

    /// Screen dimensions in pixels.
    var resolution: SIMD2<Float>

    /// Event horizon radius in normalized UV space (0 = disabled).
    var blackHoleRadius: Float

    /// Lensing strength multiplier (0-3, controls deflection intensity).
    var blackHoleWarp: Float

    /// 1.0 if EDR/HDR output is available, 0.0 for SDR displays.
    var enableEDR: Float

    /// Creates uniforms from configuration with runtime state.
    ///
    /// - Parameters:
    ///   - config: User configuration for visual parameters
    ///   - time: Current animation time in seconds
    ///   - resolution: Screen dimensions in pixels
    ///   - enableEDR: Whether EDR/HDR is available on this display
    init(config: StarTunnelConfiguration, time: Float, resolution: SIMD2<Float>, enableEDR: Bool) {
        self.time = time
        self.speed = config.speed
        self.stretch = config.stretch
        self.blur = config.blur
        self.density = config.density
        self.size = config.size
        self.resolution = resolution
        self.blackHoleRadius = config.blackHoleRadius
        self.blackHoleWarp = config.blackHoleWarp
        self.enableEDR = enableEDR ? 1.0 : 0.0
    }
}
