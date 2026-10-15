import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var universe = GravityScene()
    @State private var preset = GravityPreset.orbit
    @State private var gravity = 1.0
    @State private var speed = 0.7
    @State private var paused = false
    @State private var controlsVisible = true
    @State private var soundControlsVisible = false
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("soundVolume") private var soundVolume = 0.3
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            UniverseView(scene: universe, paused: paused || scenePhase != .active)
                .ignoresSafeArea()
                .accessibilityLabel("Gravity sandbox. Drag to move a black hole. In Stardust, drag to paint particles.")
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("BLACKHOLE").font(.system(size: 12, weight: .medium, design: .monospaced)).tracking(5)
                        Text("A little space to unwind.").font(.system(size: 22, weight: .light, design: .serif))
                    }
                    Spacer()
                    Button { soundControlsVisible.toggle() } label: {
                        Image(systemName: soundEnabled && soundVolume > 0 ? "speaker.wave.2" : "speaker.slash")
                            .frame(width: 44, height: 44).background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Sound settings")
                    .popover(isPresented: $soundControlsVisible) {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("Cosmic sound", isOn: $soundEnabled)
                            Text("Soft noise, gentle tones, and a wash of sound as you move through space.")
                                .font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: "speaker.fill")
                                Slider(value: $soundVolume, in: 0...1)
                                    .accessibilityLabel("Sound volume")
                                Image(systemName: "speaker.wave.3.fill")
                            }
                            Text("Respects Silent Mode and plays alongside your music.")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(20).frame(width: 290)
                        .presentationCompactAdaptation(.popover)
                        .preferredColorScheme(.dark)
                    }
                    Button { withAnimation { controlsVisible.toggle() } } label: {
                        Image(systemName: controlsVisible ? "arrow.down.right.and.arrow.up.left" : "slider.horizontal.3")
                            .frame(width: 44, height: 44).background(.ultraThinMaterial, in: Circle())
                    }.accessibilityLabel(controlsVisible ? "Hide controls" : "Show controls")
                }
                Spacer()
                if controlsVisible {
                    VStack(spacing: 18) {
                        HStack {
                            Label("GRAVITY PLAYGROUND", systemImage: "sparkle")
                                .font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(2)
                            Spacer()
                            Text("∞").foregroundStyle(.cyan)
                        }.foregroundStyle(.white.opacity(0.55))
                        Picker("Scene", selection: $preset) {
                            ForEach(GravityPreset.allCases) { item in Text(item.rawValue).tag(item) }
                        }.pickerStyle(.segmented)
                        Text(preset.hint).font(.system(size: 12)).foregroundStyle(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        control("Gravitational pull", value: $gravity, range: 0.2...3, suffix: "×")
                        control("Time flow", value: $speed, range: 0.1...1.5, suffix: "×")
                        HStack(spacing: 12) {
                            Button { paused.toggle(); universe.isPaused = paused } label: {
                                Label(paused ? "Resume" : "Pause", systemImage: paused ? "play.fill" : "pause.fill")
                                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                            }.background(.white.opacity(0.09), in: Capsule())
                            Button { universe.reset(preset) } label: {
                                Label("Begin again", systemImage: "arrow.counterclockwise")
                                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                            }.background(.white.opacity(0.09), in: Capsule())
                        }.font(.system(size: 12, weight: .medium))
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.08)))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }.padding(24).frame(maxWidth: 600)
        }
        .preferredColorScheme(.dark)
        .tint(.cyan)
        .onChange(of: preset) { _, value in universe.reset(value) }
        .onChange(of: gravity) { _, value in universe.pull = value }
        .onChange(of: speed) { _, value in universe.timeFlow = value }
        .onAppear { syncAudio() }
        .onDisappear { universe.audio.configure(enabled: soundEnabled, volume: soundVolume, active: false) }
        .onChange(of: soundEnabled) { _, _ in syncAudio() }
        .onChange(of: soundVolume) { _, _ in syncAudio() }
        .onChange(of: paused) { _, _ in syncAudio() }
        .onChange(of: scenePhase) { _, phase in
            universe.isPaused = paused || phase != .active
            syncAudio()
        }
    }

    private func syncAudio() {
        universe.audio.configure(enabled: soundEnabled, volume: soundVolume, active: !paused && scenePhase == .active)
    }

    private func control(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title).foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(String(format: "%.1f", value.wrappedValue) + suffix).monospacedDigit()
            }.font(.system(size: 12))
            Slider(value: value, in: range).accessibilityLabel(title)
        }
    }
}

private struct UniverseView: UIViewRepresentable {
    let scene: GravityScene
    let paused: Bool

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        scene.isPaused = paused
    }
}
