import SpriteKit

// An intentionally playful, softened Newtonian field, rather than a relativity model.
enum GravityPreset: String, CaseIterable, Identifiable {
    case orbit = "Orbit", binary = "Binary", stardust = "Stardust"
    var id: String { rawValue }
    var hint: String {
        switch self {
        case .orbit: "Drag the black hole. Watch its orbit unravel."
        case .binary: "Drag either black hole to reshape the currents."
        case .stardust: "Paint stardust with your finger. Let gravity take over."
        }
    }
}

final class GravityScene: SKScene {
    let audio = SandboxAudio()
    var pull = 1.0
    var timeFlow = 0.7
    private var preset = GravityPreset.orbit
    private var lastTime: TimeInterval = 0
    private var holes: [SKNode] = []
    private var particles: [Particle] = []
    private var trails: [SKShapeNode] = []
    private var selectedHole = 0
    private let colors: [UIColor] = [UIColor(red: 0.42, green: 0.88, blue: 1, alpha: 1), UIColor(red: 0.65, green: 0.5, blue: 1, alpha: 1), UIColor(red: 1, green: 0.74, blue: 0.48, alpha: 1)]
    private struct Particle {
        var position: CGPoint
        var velocity: CGVector
        var history: [CGPoint]
        var node: SKShapeNode
        var color: Int
    }

    override init() {
        super.init(size: CGSize(width: 400, height: 850))
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.012, green: 0.018, blue: 0.04, alpha: 1)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func didMove(to view: SKView) { reset(preset) }
    override func didChangeSize(_ oldSize: CGSize) { if view != nil { reset(preset) } }

    func reset(_ selection: GravityPreset) {
        audio.endInteraction()
        preset = selection
        removeAllChildren()
        holes.removeAll(); particles.removeAll(); trails.removeAll()
        lastTime = 0
        for _ in 0..<100 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.3...1))
            star.fillColor = .white; star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.1...0.4)
            star.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 0...size.height))
            addChild(star)
        }
        for color in colors {
            let trail = SKShapeNode()
            trail.strokeColor = color.withAlphaComponent(0.24)
            trail.lineWidth = 0.8; trail.blendMode = .add; trail.zPosition = 1
            addChild(trail); trails.append(trail)
        }
        let center = CGPoint(x: size.width / 2, y: size.height * 0.60)
        let positions = selection == .binary
            ? [CGPoint(x: center.x - size.width * 0.18, y: center.y + 38), CGPoint(x: center.x + size.width * 0.18, y: center.y - 38)]
            : [center]
        for position in positions { makeHole(at: position) }
        for _ in 0..<600 { particles.append(makeParticle()) }
    }

    private func makeHole(at point: CGPoint) {
        let hole = SKNode(); hole.position = point; hole.zPosition = 3
        let glow = SKShapeNode(circleOfRadius: 26)
        glow.strokeColor = colors[1].withAlphaComponent(0.5)
        glow.lineWidth = 7; glow.glowWidth = 20; glow.blendMode = .add
        hole.addChild(glow)
        let ring = SKShapeNode(ellipseOf: CGSize(width: 82, height: 25))
        ring.strokeColor = colors[0].withAlphaComponent(0.65)
        ring.lineWidth = 1.5; ring.glowWidth = 5; ring.zRotation = -0.35
        hole.addChild(ring)
        let core = SKShapeNode(circleOfRadius: 21)
        core.fillColor = .black; core.strokeColor = colors[0].withAlphaComponent(0.5)
        core.lineWidth = 1; hole.addChild(core)
        addChild(hole); holes.append(hole)
    }

    private func makeParticle(at location: CGPoint? = nil) -> Particle {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.60)
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let radius = CGFloat.random(in: 65...max(90, min(size.width * 0.8, size.height * 0.43)))
        let point = location ?? CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        let orbitalSpeed = sqrt(21000 * CGFloat(pull) * CGFloat(holes.count) / radius)
        let color = Int.random(in: 0..<colors.count)
        let node = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.65...1.6))
        node.fillColor = colors[color]; node.strokeColor = .clear
        node.alpha = CGFloat.random(in: 0.45...0.95); node.blendMode = .add; node.zPosition = 2
        node.position = point; addChild(node)
        return Particle(position: point, velocity: CGVector(dx: -sin(angle) * orbitalSpeed, dy: cos(angle) * orbitalSpeed), history: [], node: node, color: color)
    }

    override func update(_ currentTime: TimeInterval) {
        defer { lastTime = currentTime }
        guard lastTime > 0 else { return }
        // Cap elapsed time after interruptions, then substep to keep close passes stable.
        let dt = CGFloat(min(currentTime - lastTime, 1.0 / 30.0) * timeFlow)
        let paths = colors.map { _ in CGMutablePath() }
        for i in particles.indices {
            var p = particles[i]
            var consumed = false
            for _ in 0..<3 {
                for hole in holes {
                    let dx = hole.position.x - p.position.x, dy = hole.position.y - p.position.y
                    let squared = dx * dx + dy * dy
                    if squared < 21 * 21 { consumed = true; break }
                    let softened = squared + 28 * 28
                    let force = 21000 * CGFloat(pull) / (softened * sqrt(softened))
                    p.velocity.dx += dx * force * dt / 3
                    p.velocity.dy += dy * force * dt / 3
                }
                if consumed { break }
                p.position.x += p.velocity.dx * dt / 3
                p.position.y += p.velocity.dy * dt / 3
            }
            if consumed || !p.position.x.isFinite || !p.position.y.isFinite || abs(p.position.x - size.width / 2) > size.width * 2 || abs(p.position.y - size.height / 2) > size.height * 2 {
                p.node.removeFromParent(); particles[i] = makeParticle(); continue
            }
            p.history.append(p.position)
            if p.history.count > 16 { p.history.removeFirst() }
            if let first = p.history.first {
                paths[p.color].move(to: first)
                for point in p.history.dropFirst() { paths[p.color].addLine(to: point) }
            }
            p.node.position = p.position
            particles[i] = p
        }
        for i in trails.indices { trails[i].path = paths[i] }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        selectedHole = holes.indices.min { a, b in
            hypot(holes[a].position.x - point.x, holes[a].position.y - point.y) < hypot(holes[b].position.x - point.x, holes[b].position.y - point.y)
        } ?? 0
        interact(at: point, began: true)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        interact(at: point)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        audio.endInteraction()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        audio.endInteraction()
    }
    private func interact(at point: CGPoint, began: Bool = false) {
        guard !isPaused else { return }
        audio.interact(x: Double(point.x / max(1, size.width)), y: Double(point.y / max(1, size.height)), stardust: preset == .stardust, began: began)
        if preset == .stardust {
            // Reuse slots so painting can never grow the node count without bound.
            for _ in 0..<8 {
                let i = Int.random(in: particles.indices)
                particles[i].node.removeFromParent()
                particles[i] = makeParticle(at: CGPoint(x: point.x + .random(in: -10...10), y: point.y + .random(in: -10...10)))
            }
        } else if holes.indices.contains(selectedHole) {
            holes[selectedHole].position = point
        }
    }
}
