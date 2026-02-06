import SwiftUI

/// A SwiftUI view that renders a real-time star tunnel effect with gravitational lensing.
///
/// `StarTunnelView` displays a procedurally-generated star field that appears to fly
/// toward the viewer, creating a warp-speed tunnel effect. The view supports gravitational
/// lensing around a central black hole and runs entirely on the GPU via Metal shaders.
///
/// ## Example
/// ```swift
/// struct ContentView: View {
///     @State private var config = StarTunnelConfiguration()
///     @State private var fps: Double = 0.0
///
///     var body: some View {
///         StarTunnelView(configuration: $config, fps: $fps)
///             .ignoresSafeArea()
///     }
/// }
/// ```
///
/// ## Performance
/// The rendering runs at 60+ FPS on modern devices with all processing done on the GPU.
/// Adjusting `density` has the most impact on performance, as it controls the number
/// of depth layers rendered per frame.
///
/// ## Platform Support
/// - iOS 26.0+
/// - macOS 13.0+
/// - visionOS 1.0+
public struct StarTunnelView: View {
    /// The rendering configuration (use Binding for live updates).
    @Binding public var configuration: StarTunnelConfiguration

    /// Current frames per second (updated automatically).
    @Binding public var fps: Double

    /// Creates a star tunnel view with configuration binding.
    ///
    /// - Parameters:
    ///   - configuration: Binding to the rendering configuration
    ///   - fps: Binding to receive FPS updates (defaults to constant 0.0)
    public init(
        configuration: Binding<StarTunnelConfiguration>,
        fps: Binding<Double> = .constant(0.0)
    ) {
        self._configuration = configuration
        self._fps = fps
    }

    public var body: some View {
        StarTunnelViewBridge(configuration: configuration, fps: $fps)
    }
}
