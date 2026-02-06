import SwiftUI
import MetalKit

/// Cross-platform bridge for rendering the star tunnel effect.
///
/// This struct provides a unified SwiftUI view that works on iOS, macOS, and visionOS
/// by implementing the appropriate platform representable protocol.
public struct StarTunnelViewBridge: PlatformViewRepresentable {
    var configuration: StarTunnelConfiguration
    @Binding var fps: Double

    init(configuration: StarTunnelConfiguration, fps: Binding<Double>) {
        self.configuration = configuration
        self._fps = fps
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(fps: $fps)
    }

    /// Coordinator manages the renderer and FPS updates.
    public class Coordinator: @unchecked Sendable {
        var renderer: MetalStarTunnelRenderer?
        var fps: Binding<Double>

        init(fps: Binding<Double>) {
            self.fps = fps
        }

        func startFPSUpdates() {
            // Poll FPS from the main actor on a timer
            Task { @MainActor in
                while !Task.isCancelled {
                    if let renderer = self.renderer {
                        self.fps.wrappedValue = renderer.currentFPS
                    }
                    try? await Task.sleep(for: .milliseconds(100))
                }
            }
        }
    }
}
