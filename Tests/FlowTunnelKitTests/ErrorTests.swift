import Testing
import Foundation
@testable import FlowTunnelKit

/// Tests for StarTunnelError cases and descriptions.
@Suite("Error Tests")
struct ErrorTests {
    @Test("Error descriptions are meaningful")
    func testErrorDescriptions() {
        let errors: [StarTunnelError] = [
            .metalNotAvailable,
            .commandQueueCreationFailed,
            .vertexBufferCreationFailed,
            .shaderLibraryNotFound,
            .shaderFunctionNotFound("testFunction"),
            .pipelineCreationFailed(NSError(domain: "test", code: 1))
        ]

        for error in errors {
            let description = error.errorDescription
            #expect(description != nil)
            #expect(!description!.isEmpty)
        }
    }

    @Test("Shader function not found error includes function name")
    func testShaderFunctionNotFoundError() {
        let error = StarTunnelError.shaderFunctionNotFound("myCustomFunction")
        let description = error.errorDescription

        #expect(description?.contains("myCustomFunction") == true)
    }

    @Test("Pipeline creation error includes underlying error")
    func testPipelineCreationError() {
        let underlyingError = NSError(domain: "TestDomain", code: 123)
        let error = StarTunnelError.pipelineCreationFailed(underlyingError)
        let description = error.errorDescription

        #expect(description != nil)
        #expect(!description!.isEmpty)
    }
}
