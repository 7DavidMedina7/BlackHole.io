import AVFoundation

/// Prerendered, seamless noise keeps audio work off the simulation's render loop.
final class SandboxAudio: NSObject {
    private var ambience: AVAudioPlayer?
    private var wash: AVAudioPlayer?
    private var orbitTone: AVAudioPlayer?
    private var dustTone: AVAudioPlayer?
    private var enabled = true
    private var active = false
    private var interrupted = false
    private var level: Float = 0.3
    private var lastTone: TimeInterval = 0

    override init() {
        super.init()
        ambience = player("CosmicNoise", looping: true)
        wash = player("GravityWash", looping: true)
        wash?.enableRate = true
        orbitTone = player("OrbitTone")
        dustTone = player("DustTone")
        NotificationCenter.default.addObserver(self, selector: #selector(interruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func player(_ name: String, looping: Bool = false) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return nil }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.numberOfLoops = looping ? -1 : 0
        player.volume = 0
        player.prepareToPlay()
        return player
    }

    func configure(enabled: Bool, volume: Double, active: Bool) {
        self.enabled = enabled
        self.level = Float(min(1, max(0, volume)))
        self.active = active
        refresh()
    }

    private func refresh() {
        guard active, enabled, level > 0, !interrupted else {
            ambience?.pause()
            endInteraction()
            orbitTone?.stop(); dustTone?.stop()
            return
        }
        do {
            // Ambient audio respects the silent switch and coexists with music.
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            if ambience?.isPlaying != true {
                ambience?.volume = 0
                ambience?.play()
            }
            ambience?.setVolume(level * 0.42, fadeDuration: 0.5)
        } catch {
            ambience?.pause()
            endInteraction()
        }
    }

    func interact(x: Double, y: Double, stardust: Bool, began: Bool) {
        guard active, enabled, level > 0, !interrupted else { return }
        wash?.pan = Float(min(1, max(-1, x * 2 - 1)))
        wash?.rate = Float(0.7 + min(1, max(0, y)) * 0.6)
        if wash?.isPlaying != true {
            wash?.volume = 0
            wash?.play()
        }
        wash?.setVolume(level * 0.4, fadeDuration: 0.12)
        let now = ProcessInfo.processInfo.systemUptime
        if began || (stardust && now - lastTone > 0.28) {
            guard now - lastTone > 0.12 else { return }
            lastTone = now
            let tone = stardust ? dustTone : orbitTone
            tone?.currentTime = 0
            tone?.pan = wash?.pan ?? 0
            tone?.volume = level * 0.45
            tone?.play()
        }
    }

    func endInteraction() {
        wash?.setVolume(0, fadeDuration: 0.25)
    }

    @objc private func interruption(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        if type == .began {
            interrupted = true
            refresh()
        } else {
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            interrupted = !AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume)
            refresh()
        }
    }
}
