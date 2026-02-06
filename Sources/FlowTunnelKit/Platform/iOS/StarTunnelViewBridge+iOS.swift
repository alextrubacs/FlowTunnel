#if canImport(UIKit)
import SwiftUI
import MetalKit

/// iOS-specific implementation of the star tunnel view bridge.
///
/// This extension provides the UIKit-specific implementation of `StarTunnelViewBridge`,
/// handling the creation and updating of MTKView on iOS.
extension StarTunnelViewBridge {
    public func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()

        guard let device = MTLCreateSystemDefaultDevice() else {
            print("⚠️ Metal is not available (running in Simulator?). Showing black screen.")
            return mtkView
        }

        mtkView.device = device

        // Use rgba16Float on real devices, fallback to bgra8Unorm on simulator
        #if targetEnvironment(simulator)
        mtkView.colorPixelFormat = .bgra8Unorm
        #else
        mtkView.colorPixelFormat = .rgba16Float
        #endif

        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        mtkView.preferredFramesPerSecond = 120
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false

        // Enable EDR/HDR — allows shader output > 1.0 to display brighter than SDR white
        var edrEnabled = false
        if let metalLayer = mtkView.layer as? CAMetalLayer {
            metalLayer.wantsExtendedDynamicRangeContent = true
            metalLayer.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
            // Check if EDR is actually supported (requires iOS 16+ and compatible display)
            if #available(iOS 16.0, *) {
                edrEnabled = metalLayer.wantsExtendedDynamicRangeContent
            }
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

    public func updateUIView(_ mtkView: MTKView, context: Context) {
        context.coordinator.renderer?.updateConfiguration(configuration)
    }
}
#endif
