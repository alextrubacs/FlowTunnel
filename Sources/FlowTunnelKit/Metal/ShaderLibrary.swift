import Metal
import Foundation

/// Manages loading and compilation of Metal shaders from the package bundle.
///
/// This class provides a centralized way to load shader code from the package's
/// resources, compile it, and retrieve shader functions. It handles errors gracefully
/// and provides clear error messages when shader loading fails.
public final class ShaderLibrary: @unchecked Sendable {
    private let device: MTLDevice
    private let library: MTLLibrary

    /// Initialize shader library by loading and compiling Metal shader code.
    ///
    /// - Parameter device: The Metal device to use for compilation
    /// - Throws: `StarTunnelError` if shader loading or compilation fails
    public init(device: MTLDevice) throws {
        self.device = device

        // Use embedded shader source (avoids SPM resource bundle issues)
        let shaderSource = EmbeddedShaderSource.starTunnelShader

        // Compile shader source into Metal library
        do {
            self.library = try device.makeLibrary(source: shaderSource, options: nil)
        } catch {
            throw StarTunnelError.pipelineCreationFailed(error)
        }
    }

    /// Retrieve a compiled shader function by name.
    ///
    /// - Parameter name: The function name as declared in the Metal shader
    /// - Returns: The compiled Metal function
    /// - Throws: `StarTunnelError.shaderFunctionNotFound` if the function doesn't exist
    public func makeFunction(name: String) throws -> MTLFunction {
        guard let function = library.makeFunction(name: name) else {
            throw StarTunnelError.shaderFunctionNotFound(name)
        }
        return function
    }
}
