import Testing
import Metal
@testable import FlowTunnelKit

/// Tests for MetalStarTunnelRenderer initialization and configuration updates.
@Suite("Renderer Tests")
struct RendererTests {
    @Test("Renderer initializes successfully with valid device")
    func testRendererInitialization() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            Issue.record("Metal not available on this device")
            return
        }

        let config = StarTunnelConfiguration()
        let renderer = try MetalStarTunnelRenderer(
            device: device,
            pixelFormat: .rgba16Float,
            configuration: config,
            enableEDR: false
        )

        #expect(renderer.currentFPS >= 0.0)
    }

    @Test("Renderer accepts configuration updates")
    func testConfigurationUpdate() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            Issue.record("Metal not available on this device")
            return
        }

        let initialConfig = StarTunnelConfiguration(speed: 1.0)
        let renderer = try MetalStarTunnelRenderer(
            device: device,
            pixelFormat: .rgba16Float,
            configuration: initialConfig,
            enableEDR: false
        )

        let newConfig = StarTunnelConfiguration(speed: 3.0)
        renderer.updateConfiguration(newConfig)

        // If we get here without crashing, the update succeeded
        #expect(Bool(true))
    }

    @Test("Renderer accepts EDR state changes")
    func testEDRStateChange() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            Issue.record("Metal not available on this device")
            return
        }

        let renderer = try MetalStarTunnelRenderer(
            device: device,
            pixelFormat: .rgba16Float,
            configuration: StarTunnelConfiguration(),
            enableEDR: false
        )

        renderer.setEDREnabled(true)
        renderer.setEDREnabled(false)

        // If we get here without crashing, the updates succeeded
        #expect(Bool(true))
    }
}
