import Testing
@testable import FlowTunnelKit

/// Tests for StarUniforms creation and memory layout.
@Suite("Uniform Tests")
struct UniformTests {
    @Test("Uniforms created from configuration")
    func testUniformsFromConfiguration() {
        let config = StarTunnelConfiguration(
            speed: 2.0,
            stretch: 1.0,
            blur: 0.5,
            density: 1.5,
            size: 0.2,
            blackHoleRadius: 0.3,
            blackHoleWarp: 1.5
        )

        let uniforms = StarUniforms(
            config: config,
            time: 10.0,
            resolution: SIMD2<Float>(1920, 1080),
            enableEDR: true
        )

        #expect(uniforms.time == 10.0)
        #expect(uniforms.speed == 2.0)
        #expect(uniforms.stretch == 1.0)
        #expect(uniforms.blur == 0.5)
        #expect(uniforms.density == 1.5)
        #expect(uniforms.size == 0.2)
        #expect(uniforms.resolution.x == 1920)
        #expect(uniforms.resolution.y == 1080)
        #expect(uniforms.blackHoleRadius == 0.3)
        #expect(uniforms.blackHoleWarp == 1.5)
        #expect(uniforms.enableEDR == 1.0)
    }

    @Test("EDR flag converts boolean to float correctly")
    func testEDRFlagConversion() {
        let config = StarTunnelConfiguration()

        let uniformsEnabled = StarUniforms(
            config: config,
            time: 0,
            resolution: SIMD2<Float>(1920, 1080),
            enableEDR: true
        )
        #expect(uniformsEnabled.enableEDR == 1.0)

        let uniformsDisabled = StarUniforms(
            config: config,
            time: 0,
            resolution: SIMD2<Float>(1920, 1080),
            enableEDR: false
        )
        #expect(uniformsDisabled.enableEDR == 0.0)
    }

    @Test("Uniforms struct has expected memory size")
    func testUniformsMemorySize() {
        // StarUniforms should be 11 floats = 44 bytes
        // (time, speed, stretch, blur, density, size, resolution.x, resolution.y, blackHoleRadius, blackHoleWarp, enableEDR)
        let expectedSize = MemoryLayout<Float>.size * 11
        let actualSize = MemoryLayout<StarUniforms>.size

        #expect(actualSize == expectedSize)
    }
}
