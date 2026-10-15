import Testing
import SpriteKit
@testable import BlackHole_io

struct BlackHole_ioTests {
    @Test @MainActor func simulationStaysFiniteAndBounded() {
        let scene = GravityScene()
        scene.pull = 3
        scene.timeFlow = 1.5
        for preset in GravityPreset.allCases {
            scene.reset(preset)
            let count = scene.children.count
            for frame in 1...1800 { scene.update(Double(frame) / 60) }
            #expect(scene.children.count == count)
            #expect(scene.children.allSatisfy { $0.position.x.isFinite && $0.position.y.isFinite })
            scene.reset(preset)
            #expect(scene.children.count == count)
        }
    }
}
