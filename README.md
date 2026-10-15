# BlackHole.io

A little space to unwind.

BlackHole.io is an interactive gravity sandbox for iPhone and iPad. Move black holes, paint stardust, and watch glowing particles settle into shifting currents, accompanied by soft ambient sound. There are no scores or objectives—just space to experiment.

## Explore the sandbox

| Mode | How to play |
| --- | --- |
| **Orbit** | Touch and drag anywhere in the simulation to move the black hole and reshape the particle orbits. |
| **Binary** | Touch near either black hole and drag to move it. Particles respond to the combined gravitational field. |
| **Stardust** | Drag through the simulation to paint particles around a central black hole. |

- **Gravitational pull:** adjust the attraction from 0.2× to 3.0×.
- **Time flow:** slow down or speed up the simulation from 0.1× to 1.5×.
- **Pause / Resume:** take a moment or keep the particles moving.
- **Begin again:** rebuild the current scene while keeping your control settings.
- **Hide controls:** tuck away the playground panel for a quieter view.

Each scene contains 600 particles with colored trails. Particles absorbed by a black hole or traveling far outside the scene are replaced, keeping the playground populated.

## Sound

Open the **speaker button** to enable or mute sound and adjust its volume. Sound preferences are saved between launches.

- A soft, filtered white-noise loop provides the ambient background.
- Touching the simulation in Orbit or Binary plays a low tone.
- Painting stardust adds brighter, gently spaced tones.
- Dragging creates a soft wash that pans horizontally with your finger and changes playback rate with its vertical position. It fades when you let go.

Audio pauses with the simulation and when the app becomes inactive. It respects Silent Mode and can play alongside your music. If you cannot hear anything, check the speaker settings, device volume, and Silent Mode.

## Run locally

You need a Mac with Xcode and an iOS 18.5 or later simulator or device. The project uses Apple's built-in frameworks and has no third-party dependencies.

1. Clone the repository:

   ```sh
   git clone https://github.com/7DavidMedina7/BlackHole.io.git
   cd BlackHole.io
   open BlackHole.io.xcodeproj
   ```

2. Select the **BlackHole.io** scheme and an iPhone or iPad run destination.
3. For a physical device, select your development team under **Signing & Capabilities**.
4. Press **⌘R** to build and run.

## Project structure

| File or folder | Purpose |
| --- | --- |
| `BlackHole.io/ContentView.swift` | SwiftUI interface, simulation controls, sound settings, and SpriteKit view integration. |
| `BlackHole.io/GravityScene.swift` | Particle motion, gravitational fields, rendering, and touch interactions. |
| `BlackHole.io/SandboxAudio.swift` | Ambient and interaction playback, stereo panning, and audio interruption handling. |
| `BlackHole.io/Sounds/` | Bundled noise loops and synthesized tones. |
| `BlackHole.ioTests/` | Simulation stability test using Swift Testing. |
| `BlackHole.ioUITests/` | Xcode UI test scaffolding. |

## Testing

Use **Product → Test** (**⌘U**) in Xcode. The simulation stability test advances each preset for 1,800 updates at maximum pull and time flow, checking that positions remain finite and the scene's node count stays constant after simulation and reset.

For a hands-on check, try all three modes, move both holes in Binary, paint stardust, and exercise pause, reset, mute, volume, and background/foreground transitions. Audition sound on a physical device as well as the simulator.

## About the physics

This is a playful visualization using a softened Newtonian gravitational field. The black holes act as movable attractors, with particles disappearing inside their cores. It does not model general relativity, physical black-hole mergers, or scientifically accurate event horizons. The sound is an artistic accompaniment.
