import Metal
import MetalKit

/// Metal Renderer - GPU rendering engine for the star tunnel effect.
///
/// ## How it works
///
/// ### One-time setup (init):
/// 1. Gets a GPU device from the system
/// 2. Loads the Metal shader code and compiles it via `ShaderLibrary`
/// 3. Creates a command queue (a pipeline for sending GPU commands)
/// 4. Builds a fullscreen quad (2 triangles) to render on
///
/// ### Each frame (draw):
/// 1. Gets the current screen drawable from MTKView
/// 2. Packages up all parameter values (speed, blur, etc.) into a buffer
/// 3. Sends render commands to the GPU:
///    - Use the compiled shaders
///    - Set up the vertex buffer (the quad)
///    - Pass the parameters to the fragment shader
///    - Draw the fullscreen quad
/// 4. Presents the rendered image to the screen
///
/// The renderer acts as the bridge between SwiftUI (which sends configuration values)
/// and the GPU (which does the actual star tunnel rendering in the shader).
public final class MetalStarTunnelRenderer: NSObject, MTKViewDelegate, @unchecked Sendable {
    // GPU infrastructure
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer
    private let startTime: CFAbsoluteTime

    // FPS tracking
    private var frameCount: Int = 0
    private var lastFPSUpdate: CFAbsoluteTime
    private var _currentFPS: Double = 0.0

    /// Current frames per second (updated every 0.5 seconds).
    public var currentFPS: Double {
        _currentFPS
    }

    // Current configuration and EDR state
    private var config: StarTunnelConfiguration
    private var isEDREnabled: Bool

    /// Initialize Metal device, compile shaders, and create render pipeline.
    ///
    /// - Parameters:
    ///   - device: The Metal device to use for rendering
    ///   - pixelFormat: The pixel format for the render target
    ///   - configuration: Initial rendering configuration
    ///   - enableEDR: Whether to enable EDR/HDR output if available
    /// - Throws: `StarTunnelError` if initialization fails
    public init(
        device: MTLDevice,
        pixelFormat: MTLPixelFormat,
        configuration: StarTunnelConfiguration = StarTunnelConfiguration(),
        enableEDR: Bool = false
    ) throws {
        // Create command queue
        guard let commandQueue = device.makeCommandQueue() else {
            throw StarTunnelError.commandQueueCreationFailed
        }

        self.device = device
        self.commandQueue = commandQueue
        self.config = configuration
        self.isEDREnabled = enableEDR
        self.startTime = CFAbsoluteTimeGetCurrent()
        self.lastFPSUpdate = CFAbsoluteTimeGetCurrent()

        // Create fullscreen quad vertices (2 triangles covering entire screen)
        let vertices: [SIMD2<Float>] = [
            SIMD2(-1, -1), SIMD2( 1, -1), SIMD2(-1,  1),  // Triangle 1
            SIMD2(-1,  1), SIMD2( 1, -1), SIMD2( 1,  1)   // Triangle 2
        ]

        // Allocate GPU memory for vertices
        guard let vb = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<SIMD2<Float>>.stride * vertices.count,
            options: .storageModeShared
        ) else {
            throw StarTunnelError.vertexBufferCreationFailed
        }
        self.vertexBuffer = vb

        // Load and compile Metal shaders
        let shaderLibrary = try ShaderLibrary(device: device)
        let vertexFunc = try shaderLibrary.makeFunction(name: "starTunnelVertex")
        let fragFunc = try shaderLibrary.makeFunction(name: "starTunnelFragment")

        // Create render pipeline descriptor
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunc
        descriptor.fragmentFunction = fragFunc
        descriptor.colorAttachments[0].pixelFormat = pixelFormat

        // Compile the pipeline into GPU code
        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            throw StarTunnelError.pipelineCreationFailed(error)
        }

        super.init()
    }

    /// Update the rendering configuration.
    ///
    /// This can be called from any thread. The new configuration will be used
    /// starting with the next frame.
    ///
    /// - Parameter configuration: New rendering parameters
    public func updateConfiguration(_ configuration: StarTunnelConfiguration) {
        self.config = configuration
    }

    /// Update EDR enablement state.
    ///
    /// - Parameter enabled: Whether EDR/HDR should be enabled
    public func setEDREnabled(_ enabled: Bool) {
        self.isEDREnabled = enabled
    }

    // MARK: - MTKViewDelegate

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Size changes are handled automatically via uniforms.resolution
    }

    public func draw(in view: MTKView) {
        // Get GPU rendering surfaces from MTKView
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        // Calculate elapsed time for animation
        let elapsed = Float(CFAbsoluteTimeGetCurrent() - startTime)

        // Update FPS counter
        frameCount += 1
        let currentTime = CFAbsoluteTimeGetCurrent()
        let timeSinceLastUpdate = currentTime - lastFPSUpdate
        if timeSinceLastUpdate >= 0.5 {  // Update FPS every 0.5 seconds
            _currentFPS = Double(frameCount) / timeSinceLastUpdate
            frameCount = 0
            lastFPSUpdate = currentTime
        }

        // Package all shader parameters into a single uniform struct
        var uniforms = StarUniforms(
            config: config,
            time: elapsed,
            resolution: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            enableEDR: isEDREnabled
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
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
