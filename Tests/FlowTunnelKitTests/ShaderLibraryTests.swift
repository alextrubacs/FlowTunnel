import Testing
import Metal
@testable import FlowTunnelKit

/// Tests for ShaderLibrary loading and function retrieval.
@Suite("Shader Library Tests")
struct ShaderLibraryTests {
    @Test("Shader library loads successfully")
    func testShaderLibraryLoading() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            Issue.record("Metal not available on this device")
            return
        }

        let _ = try ShaderLibrary(device: device)
        // If we get here without throwing, the library loaded successfully
    }

    @Test("Vertex shader function exists")
    func testVertexShaderFunction() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            Issue.record("Metal not available on this device")
            return
        }

        let library = try ShaderLibrary(device: device)
        let function = try library.makeFunction(name: "starTunnelVertex")

        #expect(function.functionType == .vertex)
    }

    @Test("Fragment shader function exists")
    func testFragmentShaderFunction() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            Issue.record("Metal not available on this device")
            return
        }

        let library = try ShaderLibrary(device: device)
        let function = try library.makeFunction(name: "starTunnelFragment")

        #expect(function.functionType == .fragment)
    }

    @Test("Nonexistent shader function throws error")
    func testNonexistentShaderFunction() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            Issue.record("Metal not available on this device")
            return
        }

        let library = try ShaderLibrary(device: device)

        #expect(throws: StarTunnelError.self) {
            _ = try library.makeFunction(name: "nonexistentFunction")
        }
    }
}
