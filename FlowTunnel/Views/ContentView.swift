import SwiftUI

struct ContentView: View {
    @State private var speed: Float = 1.0
    @State private var stretch: Float = 0.0
    @State private var blur: Float = 0.15
    @State private var density: Float = 1.8
    @State private var size: Float = 0.15
    @State private var blackHoleRadius: Float = 0.15
    @State private var blackHoleWarp: Float = 1.0
    @State private var showControls = false
    @State private var fps: Double = 0.0

    var body: some View {
        ZStack {
            StarTunnelView(speed: speed, stretch: stretch, blur: blur, density: density,
                          size: size, blackHoleRadius: blackHoleRadius, blackHoleWarp: blackHoleWarp, fps: $fps)
                .ignoresSafeArea()

            VStack {
                Spacer()
                if showControls {
                    controlsPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showControls)

            VStack {
                HStack {
                    // FPS counter
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
    }

    private var controlsPanel: some View {
        VStack(spacing: 16) {
            parameterSlider(label: "Speed", value: $speed, range: 0...3)
            parameterSlider(label: "Stretch", value: $stretch, range: 0...3)
            parameterSlider(label: "Blur", value: $blur, range: 0...1)
            parameterSlider(label: "Density", value: $density, range: 0.1...2)
            parameterSlider(label: "Size", value: $size, range: 0.1...3)
            parameterSlider(label: "Black Hole", value: $blackHoleRadius, range: 0...0.5)
            parameterSlider(label: "BH Warp", value: $blackHoleWarp, range: 0...3)
        }
        .padding(20)
        .glassEffect(.clear, in: .rect(cornerRadius: 38))
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    /// Parameter slider with label and current value display
    /// - Parameters:
    ///   - label: Display name for the parameter
    ///   - value: Binding to the parameter Float value
    ///   - range: Valid range for the slider
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
}

#Preview {
    ContentView()
}
