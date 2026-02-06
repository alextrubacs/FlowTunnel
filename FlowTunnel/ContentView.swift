import SwiftUI

struct ContentView: View {
    @State private var speed: Float = 1.0
    @State private var stretch: Float = 0.5
    @State private var blur: Float = 0.3
    @State private var density: Float = 0.5
    @State private var showControls = true

    var body: some View {
        ZStack {
            StarTunnelView(speed: speed, stretch: stretch, blur: blur, density: density)
                .ignoresSafeArea()

            VStack {
                Spacer()

                if showControls {
                    controlsPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showControls)

            // Toggle button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showControls.toggle()
                    } label: {
                        Image(systemName: showControls ? "chevron.down.circle.fill" : "slider.horizontal.3")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(12)
                    }
                }
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
            parameterSlider(label: "Density", value: $density, range: 0.1...1)
        }
        .padding(20)
        .background(.ultraThinMaterial.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func parameterSlider(label: String, value: Binding<Float>, range: ClosedRange<Float>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
            }
            Slider(value: value, in: range)
                .tint(.white.opacity(0.6))
        }
    }
}

#Preview {
    ContentView()
}
