import SwiftUI
import MetalKit

struct StarUniforms {
    var time: Float = 0
    var speed: Float = 1.0
    var stretch: Float = 0.5
    var blur: Float = 0.3
    var density: Float = 0.5
    var size: Float = 1.0
    var resolution: SIMD2<Float> = .zero
}

class MetalStarTunnelRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer
    private var startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    var speed: Float = 1.0
    var stretch: Float = 0.5
    var blur: Float = 0.3
    var density: Float = 0.5
    var size: Float = 1.0

    init?(mtkView: MTKView) {
        guard let device = mtkView.device ?? MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }

        self.device = device
        self.commandQueue = commandQueue
        mtkView.device = device

        // Fullscreen quad vertices (2 triangles)
        let vertices: [SIMD2<Float>] = [
            SIMD2(-1, -1), SIMD2( 1, -1), SIMD2(-1,  1),
            SIMD2(-1,  1), SIMD2( 1, -1), SIMD2( 1,  1)
        ]
        guard let vb = device.makeBuffer(bytes: vertices,
                                         length: MemoryLayout<SIMD2<Float>>.stride * vertices.count,
                                         options: .storageModeShared) else {
            return nil
        }
        self.vertexBuffer = vb

        // Build render pipeline
        guard let library = device.makeDefaultLibrary(),
              let vertexFunc = library.makeFunction(name: "starTunnelVertex"),
              let fragFunc = library.makeFunction(name: "starTunnelFragment") else {
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunc
        descriptor.fragmentFunction = fragFunc
        descriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
            return nil
        }

        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        let elapsed = Float(CFAbsoluteTimeGetCurrent() - startTime)
        var uniforms = StarUniforms(
            time: elapsed,
            speed: speed,
            stretch: stretch,
            blur: blur,
            density: density,
            size: size,
            resolution: SIMD2<Float>(Float(view.drawableSize.width),
                                     Float(view.drawableSize.height))
        )

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<StarUniforms>.size, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

struct StarTunnelView: UIViewRepresentable {
    var speed: Float
    var stretch: Float
    var blur: Float
    var density: Float
    var size: Float

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false

        if let renderer = MetalStarTunnelRenderer(mtkView: mtkView) {
            renderer.speed = speed
            renderer.stretch = stretch
            renderer.blur = blur
            renderer.density = density
            renderer.size = size
            mtkView.delegate = renderer
            context.coordinator.renderer = renderer
        }

        return mtkView
    }

    func updateUIView(_ mtkView: MTKView, context: Context) {
        context.coordinator.renderer?.speed = speed
        context.coordinator.renderer?.stretch = stretch
        context.coordinator.renderer?.blur = blur
        context.coordinator.renderer?.density = density
        context.coordinator.renderer?.size = size
    }

    class Coordinator {
        var renderer: MetalStarTunnelRenderer?
    }
}
