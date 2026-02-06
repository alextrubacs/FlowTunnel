import Foundation

/// Errors that can occur during star tunnel initialization or rendering.
public enum StarTunnelError: LocalizedError, Sendable {
    /// Metal is not available on this device.
    case metalNotAvailable

    /// Failed to create a Metal command queue.
    case commandQueueCreationFailed

    /// Failed to allocate GPU memory for the fullscreen quad.
    case vertexBufferCreationFailed

    /// Failed to load the Metal shader library.
    case shaderLibraryNotFound

    /// Failed to find required shader functions in the library.
    case shaderFunctionNotFound(String)

    /// Failed to compile the render pipeline.
    case pipelineCreationFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .metalNotAvailable:
            return "Metal is not available on this device."
        case .commandQueueCreationFailed:
            return "Failed to create Metal command queue."
        case .vertexBufferCreationFailed:
            return "Failed to allocate GPU memory for rendering."
        case .shaderLibraryNotFound:
            return "Failed to load Metal shader library from bundle."
        case .shaderFunctionNotFound(let name):
            return "Shader function '\(name)' not found in library."
        case .pipelineCreationFailed(let error):
            return "Failed to compile render pipeline: \(error.localizedDescription)"
        }
    }
}
