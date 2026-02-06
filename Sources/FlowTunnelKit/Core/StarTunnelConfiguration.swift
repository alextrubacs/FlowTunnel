/// Configuration for the star tunnel rendering effect.
///
/// This struct defines all user-controllable parameters for the star tunnel visualization.
/// Each parameter controls a specific aspect of the rendering, from animation speed to
/// gravitational lensing effects.
///
/// ## Example
/// ```swift
/// var config = StarTunnelConfiguration()
/// config.speed = 1.5
/// config.blackHoleRadius = 0.2
/// ```
public struct StarTunnelConfiguration: Sendable {
    /// Animation speed multiplier (0-3).
    ///
    /// Controls how fast stars move through the tunnel. Higher values create
    /// faster motion, while lower values slow down the effect.
    public var speed: Float

    /// Radial stretch factor (0-3).
    ///
    /// Elongates stars along rays from the screen center, creating motion blur
    /// and warp-speed streak effects. 0 = no stretch, higher values = longer streaks.
    public var stretch: Float

    /// Star glow softness (0-1).
    ///
    /// Controls the width of the Gaussian glow around each star. Lower values
    /// create sharper, more point-like stars. Higher values create softer, more diffuse glows.
    public var blur: Float

    /// Star field density (0.1-2).
    ///
    /// Controls both the number of depth layers (10-40) and the star frequency threshold.
    /// Higher density = more stars, more layers, more GPU cost.
    public var density: Float

    /// Base star size (0.1-3).
    ///
    /// Scales the base radius for star brightness calculations. Larger values
    /// create bigger, brighter stars.
    public var size: Float

    /// Event horizon radius (0-0.5).
    ///
    /// Radius of the central black hole in normalized UV space. 0 disables the
    /// black hole entirely. Values above 0 create a black disk at the center.
    public var blackHoleRadius: Float

    /// Gravitational lensing strength (0-3).
    ///
    /// Multiplier for the Schwarzschild-inspired light deflection around the black hole.
    /// Higher values bend light more dramatically, creating Einstein ring effects.
    public var blackHoleWarp: Float

    /// Creates a default configuration with balanced parameters.
    public init(
        speed: Float = 1.0,
        stretch: Float = 0.0,
        blur: Float = 0.15,
        density: Float = 1.8,
        size: Float = 0.15,
        blackHoleRadius: Float = 0.15,
        blackHoleWarp: Float = 1.0
    ) {
        self.speed = speed
        self.stretch = stretch
        self.blur = blur
        self.density = density
        self.size = size
        self.blackHoleRadius = blackHoleRadius
        self.blackHoleWarp = blackHoleWarp
    }
}
