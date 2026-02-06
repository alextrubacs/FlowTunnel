import Testing
@testable import FlowTunnelKit

/// Tests for StarTunnelConfiguration initialization and default values.
@Suite("Configuration Tests")
struct ConfigurationTests {
    @Test("Default configuration has expected values")
    func testDefaultConfiguration() {
        let config = StarTunnelConfiguration()

        #expect(config.speed == 1.0)
        #expect(config.stretch == 0.0)
        #expect(config.blur == 0.15)
        #expect(config.density == 1.8)
        #expect(config.size == 0.15)
        #expect(config.blackHoleRadius == 0.15)
        #expect(config.blackHoleWarp == 1.0)
    }

    @Test("Custom configuration accepts all parameters")
    func testCustomConfiguration() {
        let config = StarTunnelConfiguration(
            speed: 2.5,
            stretch: 1.5,
            blur: 0.8,
            density: 1.2,
            size: 0.3,
            blackHoleRadius: 0.25,
            blackHoleWarp: 2.0
        )

        #expect(config.speed == 2.5)
        #expect(config.stretch == 1.5)
        #expect(config.blur == 0.8)
        #expect(config.density == 1.2)
        #expect(config.size == 0.3)
        #expect(config.blackHoleRadius == 0.25)
        #expect(config.blackHoleWarp == 2.0)
    }

    @Test("Configuration is mutable")
    func testConfigurationMutability() {
        var config = StarTunnelConfiguration()
        config.speed = 3.0
        config.blackHoleRadius = 0.5

        #expect(config.speed == 3.0)
        #expect(config.blackHoleRadius == 0.5)
    }

    @Test("Configuration conforms to Sendable")
    func testConfigurationSendable() {
        let config = StarTunnelConfiguration()

        Task {
            let _ = config  // Should compile without warnings
        }
    }
}
