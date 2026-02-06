#if canImport(AppKit)
import SwiftUI
import MetalKit

/// macOS-specific implementation of the star tunnel view bridge.
///
/// This extension provides the AppKit-specific implementation of `StarTunnelViewBridge`,
/// handling the creation and updating of MTKView on macOS.
extension StarTunnelViewBridge {
    public func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()

        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not available on this device")
        }

        mtkView.device = device
        mtkView.colorPixelFormat = .rgba16Float
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        mtkView.preferredFramesPerSecond = 120
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false

        // Enable EDR on macOS if available
        var edrEnabled = false
        if let metalLayer = mtkView.layer as? CAMetalLayer {
            metalLayer.wantsExtendedDynamicRangeContent = true
            metalLayer.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
            edrEnabled = metalLayer.wantsExtendedDynamicRangeContent
        }

        // Initialize renderer
        do {
            let renderer = try MetalStarTunnelRenderer(
                device: device,
                pixelFormat: mtkView.colorPixelFormat,
                configuration: configuration,
                enableEDR: edrEnabled
            )
            mtkView.delegate = renderer
            context.coordinator.renderer = renderer
            context.coordinator.startFPSUpdates()
        } catch {
            print("Failed to initialize Metal renderer: \(error)")
        }

        return mtkView
    }

    public func updateNSView(_ mtkView: MTKView, context: Context) {
        context.coordinator.renderer?.updateConfiguration(configuration)
    }
}
#endif
