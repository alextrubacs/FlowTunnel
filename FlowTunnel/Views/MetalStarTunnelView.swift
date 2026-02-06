import SwiftUI
import MetalKit

/// Uniform parameter struct mirroring the Metal shader struct
/// IMPORTANT: Field order and types must exactly match StarUniforms in StarTunnel.metal
struct StarUniforms {
    var time: Float = 0
    var speed: Float = 1.5
    var stretch: Float = 0.07
    var blur: Float = 0.3
    var density: Float = 0.5
    var size: Float = 0.15
    var resolution: SIMD2<Float> = .zero
    var blackHoleRadius: Float = 0.15
    var blackHoleWarp: Float = 1.0
    var enableEDR: Float = 0.0
}

/// Metal Renderer - GPU rendering engine for the star tunnel effect
///
/// How it works:
/// 1. **One-time setup** (init):
///    - Gets a GPU device from the system
///    - Loads the Metal shader code and compiles it
///    - Creates a command queue (a pipeline for sending GPU commands)
///    - Builds a fullscreen quad (2 triangles) to render on
///
/// 2. **Each frame** (draw):
///    - Gets the current screen drawable from MTKView
///    - Packages up all parameter values (speed, blur, etc.) into a buffer
///    - Sends render commands to the GPU:
///      * Use the compiled shaders
///      * Set up the vertex buffer (the quad)
///      * Pass the parameters to the fragment shader
///      * Draw the fullscreen quad
///    - Presents the rendered image to the screen
///
/// The renderer acts as the bridge between SwiftUI (which sends parameter values)
/// and the GPU (which does the actual star tunnel rendering in the shader).
class MetalStarTunnelRenderer: NSObject, MTKViewDelegate {
    // GPU infrastructure
    private let device: MTLDevice                // The GPU
    private let commandQueue: MTLCommandQueue    // Queue for GPU commands
    private let pipelineState: MTLRenderPipelineState  // Compiled shader program
    private let vertexBuffer: MTLBuffer          // Fullscreen quad vertices
    private var startTime: CFAbsoluteTime        // When rendering started

    // FPS tracking
    private var frameCount: Int = 0
    private var lastFPSUpdate: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    var currentFPS: Double = 0.0

    // Animatable parameters synced from SwiftUI
    var speed: Float = 1.0
    var stretch: Float = 0.5
    var blur: Float = 0.3
    var density: Float = 0.5
    var size: Float = 1.0
    var blackHoleRadius: Float = 0.15
    var blackHoleWarp: Float = 1.0
    var isEDREnabled: Bool = false

    /// Initialize Metal device, compile shaders, and create render pipeline
    /// - Gets or creates a GPU device
    /// - Loads Metal shaders from the default library (compiled shader code)
    /// - Creates a render pipeline (vertex shader → rasterizer → fragment shader)
    /// - Allocates a fullscreen quad to render onto
    init?(mtkView: MTKView) {
        // Get GPU device or fail gracefully
        guard let device = mtkView.device ?? MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }

        self.device = device
        self.commandQueue = commandQueue
        self.startTime = CFAbsoluteTimeGetCurrent()
        mtkView.device = device

        // Create fullscreen quad vertices (2 triangles covering entire screen)
        let vertices: [SIMD2<Float>] = [
            SIMD2(-1, -1), SIMD2( 1, -1), SIMD2(-1,  1),  // Triangle 1
            SIMD2(-1,  1), SIMD2( 1, -1), SIMD2( 1,  1)   // Triangle 2
        ]
        // Allocate GPU memory for vertices
        guard let vb = device.makeBuffer(bytes: vertices,
                                         length: MemoryLayout<SIMD2<Float>>.stride * vertices.count,
                                         options: .storageModeShared) else {
            return nil
        }
        self.vertexBuffer = vb

        // Load and compile Metal shaders from StarTunnel.metal
        guard let library = device.makeDefaultLibrary(),
              let vertexFunc = library.makeFunction(name: "starTunnelVertex"),
              let fragFunc = library.makeFunction(name: "starTunnelFragment") else {
            return nil
        }

        // Create render pipeline: specify which shaders to use
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunc           // Positions vertices on screen
        descriptor.fragmentFunction = fragFunc           // Colors each pixel
        descriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat  // Output format

        do {
            // Compile the pipeline into GPU code
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
            return nil
        }

        super.init()
    }

    /// Called when screen size changes (e.g., device rotation)
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    /// Called every frame to render one image
    /// - Packs current parameters into a buffer
    /// - Sends GPU render commands
    /// - Presents the result to screen
    func draw(in view: MTKView) {
        // Get GPU rendering surfaces from MTKView
        guard let drawable = view.currentDrawable,              // Where to draw
              let descriptor = view.currentRenderPassDescriptor, // How to clear
              let commandBuffer = commandQueue.makeCommandBuffer(),  // GPU command container
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {  // GPU command writer
            return
        }

        // Calculate elapsed time for animation
        let elapsed = Float(CFAbsoluteTimeGetCurrent() - startTime)

        // Update FPS counter
        frameCount += 1
        let currentTime = CFAbsoluteTimeGetCurrent()
        let timeSinceLastUpdate = currentTime - lastFPSUpdate
        if timeSinceLastUpdate >= 0.5 {  // Update FPS every 0.5 seconds
            currentFPS = Double(frameCount) / timeSinceLastUpdate
            frameCount = 0
            lastFPSUpdate = currentTime
        }

        // Package all shader parameters into a single buffer
        var uniforms = StarUniforms(
            time: elapsed,                  // How far through animation we are
            speed: speed,                   // How fast stars move
            stretch: stretch,               // How elongated stars are
            blur: blur,                     // How soft/glowy stars are
            density: density,               // How many stars
            size: size,                     // How big stars are
            resolution: SIMD2<Float>(Float(view.drawableSize.width),
                                     Float(view.drawableSize.height)),  // Screen size
            blackHoleRadius: blackHoleRadius,  // Size of black hole
            blackHoleWarp: blackHoleWarp,      // Strength of light bending
            enableEDR: isEDREnabled ? 1.0 : 0.0  // Enable EDR boost on capable displays
        )

        // Tell GPU which compiled shader program to use
        encoder.setRenderPipelineState(pipelineState)

        // Tell GPU where the quad vertices are
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        // Send parameter values to the fragment shader (runs per pixel)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<StarUniforms>.size, index: 0)

        // Render: draw the fullscreen quad (6 vertices = 2 triangles)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

        // Finish encoding render commands
        encoder.endEncoding()

        // Submit commands to GPU and display the result
        commandBuffer.present(drawable)  // "Show this on screen"
        commandBuffer.commit()            // "Execute these GPU commands"
    }
}

struct StarTunnelView: UIViewRepresentable {
    var speed: Float
    var stretch: Float
    var blur: Float
    var density: Float
    var size: Float
    var blackHoleRadius: Float
    var blackHoleWarp: Float
    @Binding var fps: Double

    func makeCoordinator() -> Coordinator {
        Coordinator(fps: $fps)
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .rgba16Float
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
                edrEnabled = metalLayer.wantsExtendedDynamicRangeContent && 
                             UIScreen.main.currentEDRHeadroom > 1.0
            }
        }

        if let renderer = MetalStarTunnelRenderer(mtkView: mtkView) {
            renderer.speed = speed
            renderer.stretch = stretch
            renderer.blur = blur
            renderer.density = density
            renderer.size = size
            renderer.blackHoleRadius = blackHoleRadius
            renderer.blackHoleWarp = blackHoleWarp
            renderer.isEDREnabled = edrEnabled
            mtkView.delegate = renderer
            context.coordinator.renderer = renderer
            context.coordinator.startFPSUpdates()
        }

        return mtkView
    }

    func updateUIView(_ mtkView: MTKView, context: Context) {
        context.coordinator.renderer?.speed = speed
        context.coordinator.renderer?.stretch = stretch
        context.coordinator.renderer?.blur = blur
        context.coordinator.renderer?.density = density
        context.coordinator.renderer?.size = size
        context.coordinator.renderer?.blackHoleRadius = blackHoleRadius
        context.coordinator.renderer?.blackHoleWarp = blackHoleWarp
    }

    class Coordinator: @unchecked Sendable {
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
