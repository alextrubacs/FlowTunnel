import SwiftUI
import UIKit
import FlowTunnelKit

struct ContentView: View {
    @State private var config = StarTunnelConfiguration()
    @State private var showControls = false
    @State private var fps: Double = 0.0

    // Warp state
    @State private var isWarpPressed = false
    @State private var warpProgress: Float = 0.0
    @State private var warpTask: Task<Void, Never>? = nil
    @State private var lastWarpUpdateTime: CFAbsoluteTime = 0

    // Snapshot of user slider values before warp
    @State private var preWarpConfig = StarTunnelConfiguration()

    // Haptic generators
    @State private var impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @State private var selectionGenerator = UISelectionFeedbackGenerator()
    @State private var lastHapticTime: CFAbsoluteTime = 0

    // Warp target values
    private let warpTargetSpeed: Float = 3.0
    private let warpTargetStretch: Float = 2.5
    private let warpTargetBlur: Float = 0.8
    private let warpTargetSize: Float = 0.25
    private let warpTargetBlackHoleWarp: Float = 2.0

    // Timing
    private let rampUpDuration: Float = 3.0
    private let rampDownDuration: Float = 2.5

    var body: some View {
        ZStack {
            StarTunnelView(configuration: $config, fps: $fps)
                .ignoresSafeArea()

            VStack {
                Spacer()
                if showControls {
                    controlsPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                warpButton
                    .padding(.bottom, 30)
            }
            .animation(.easeInOut(duration: 0.3), value: showControls)

            VStack {
                HStack {
                    Text(String(format: "%.0f FPS", fps))
                        .font(.caption.monospaced())
                        .foregroundStyle(.white)
                        .bold()
                        .padding(8)
                        .glassEffect(.clear, in: .capsule)

                    Spacer()
                    Button {
                        withAnimation(.spring) {
                            showControls.toggle()
                        }
                    } label: {
                        Text(showControls ? "close" : "controls")
                    }
                    .buttonStyle(.glass)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .persistentSystemOverlays(.hidden)
        .onDisappear { warpTask?.cancel() }
    }

    // MARK: - Warp Button

    private var warpButton: some View {
        Button(action: {}) {
            Text(isWarpPressed || warpProgress > 0 ? "WARPING" : "WARP SPEED")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.clear)
        }
        .buttonStyle(.plain)
        .glassEffect(.clear, in: .capsule)
        .scaleEffect(isWarpPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isWarpPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isWarpPressed {
                        onWarpPressed()
                    }
                }
                .onEnded { _ in
                    onWarpReleased()
                }
        )
        .accessibilityLabel("Warp Speed")
        .accessibilityHint("Press and hold to activate warp speed mode")
        .accessibilityValue(isWarpPressed || warpProgress > 0 ? "Warping" : "Ready")
    }

    // MARK: - Controls Panel

    private var controlsPanel: some View {
        VStack(spacing: 16) {
            parameterSlider(label: "Speed", value: $config.speed, range: 0...3)
            parameterSlider(label: "Stretch", value: $config.stretch, range: 0...3)
            parameterSlider(label: "Blur", value: $config.blur, range: 0...1)
            parameterSlider(label: "Density", value: $config.density, range: 0.1...2)
            parameterSlider(label: "Size", value: $config.size, range: 0.1...3)
            parameterSlider(label: "Black Hole", value: $config.blackHoleRadius, range: 0...0.5)
            parameterSlider(label: "BH Warp", value: $config.blackHoleWarp, range: 0...3)
        }
        .padding(20)
        .glassEffect(.clear, in: .rect(cornerRadius: 38))
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func parameterSlider(label: String, value: Binding<Float>, range: ClosedRange<Float>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.white)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white)
                    .bold()
            }
            Slider(value: value, in: range)
                .tint(.cyan)
        }
    }

    // MARK: - Warp Logic

    private func onWarpPressed() {
        isWarpPressed = true

        // Snapshot current slider values
        preWarpConfig = config

        // Prepare and fire initial haptic
        impactGenerator.prepare()
        heavyImpactGenerator.prepare()
        selectionGenerator.prepare()
        heavyImpactGenerator.impactOccurred(intensity: 1.0)
        lastHapticTime = CFAbsoluteTimeGetCurrent()

        startWarpLoop()
    }

    private func onWarpReleased() {
        isWarpPressed = false
        // The loop continues running and will animate progress back down
    }

    private func startWarpLoop() {
        warpTask?.cancel()
        lastWarpUpdateTime = CFAbsoluteTimeGetCurrent()
        warpTask = Task { @MainActor in
            let tickInterval: UInt64 = 16_000_000 // ~60Hz (16ms)

            while !Task.isCancelled {
                updateWarpProgress()

                // Exit loop when fully wound down
                if !isWarpPressed && warpProgress <= 0.0 {
                    break
                }

                try? await Task.sleep(nanoseconds: tickInterval)
            }
        }
    }

    private func updateWarpProgress() {
        let now = CFAbsoluteTimeGetCurrent()
        let dt = Float(now - lastWarpUpdateTime)
        lastWarpUpdateTime = now

        if isWarpPressed {
            warpProgress = min(1.0, warpProgress + dt / rampUpDuration)
        } else {
            warpProgress = max(0.0, warpProgress - dt / rampDownDuration)
        }

        let eased = isWarpPressed
            ? easedRampUp(warpProgress)
            : easedRampDown(warpProgress)

        // Interpolate shader parameters
        config.speed = lerp(preWarpConfig.speed, warpTargetSpeed, eased)
        config.stretch = lerp(preWarpConfig.stretch, warpTargetStretch, eased)
        config.blur = lerp(preWarpConfig.blur, warpTargetBlur, eased)
        config.size = lerp(preWarpConfig.size, warpTargetSize, eased)
        config.blackHoleWarp = lerp(preWarpConfig.blackHoleWarp, warpTargetBlackHoleWarp, eased)

        updateHaptics(easedProgress: eased)
    }

    /// Ramp up: smoothstep for gradual acceleration feel
    private func easedRampUp(_ t: Float) -> Float {
        let c = min(max(t, 0), 1)
        return c * c * (3 - 2 * c)
    }

    /// Ramp down: quadratic ease-in so deceleration starts immediately (no plateau)
    private func easedRampDown(_ t: Float) -> Float {
        let c = min(max(t, 0), 1)
        return c * c
    }

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * t
    }

    private func updateHaptics(easedProgress: Float) {
        let now = CFAbsoluteTimeGetCurrent()

        if isWarpPressed && warpProgress < 1.0 {
            // Accelerating: haptic interval decreases from 150ms to 50ms, intensity increases
            let interval = Double(lerp(0.15, 0.05, easedProgress))
            let intensity = CGFloat(lerp(0.3, 1.0, easedProgress))
            if now - lastHapticTime >= interval {
                impactGenerator.impactOccurred(intensity: intensity)
                lastHapticTime = now
            }
        } else if isWarpPressed && warpProgress >= 1.0 {
            // Cruising: subtle selection feedback every 300ms
            if now - lastHapticTime >= 0.3 {
                selectionGenerator.selectionChanged()
                lastHapticTime = now
            }
        } else if !isWarpPressed && warpProgress > 0.0 {
            // Decelerating: haptic interval increases from 50ms to 200ms, intensity decreases
            let interval = Double(lerp(0.2, 0.05, easedProgress))
            let intensity = CGFloat(lerp(0.2, 0.8, easedProgress))
            if now - lastHapticTime >= interval {
                impactGenerator.impactOccurred(intensity: intensity)
                lastHapticTime = now
            }
        }
    }
}

#Preview {
    ContentView()
}
