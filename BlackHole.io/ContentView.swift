//
//  ContentView.swift
//  BlackHole.io
//
//  Created by David Alonzo Medina on 8/17/25.
//

import SwiftUI

struct ContentView: View {
    @State private var time = 0.0
    @GestureState private var fingerLocation: CGPoint? = nil
    @State private var pulse = false
    @State private var showGlow = false

    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let screenCenter = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                Color.black.ignoresSafeArea()

                // Particle canvas
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)

                    for i in 0..<1500 {
                        let angle = Double(i) * 0.2 + time * 0.4
                        let radius = CGFloat(100 + i / 2)

                        let point = CGPoint(
                            x: center.x + cos(angle) * radius,
                            y: center.y + sin(angle) * radius
                        )

                        let dot = Path(ellipseIn: CGRect(x: point.x, y: point.y, width: 2, height: 2))
                        context.fill(dot, with: .color(.white.opacity(0.8)))
                    }
                }
                .drawingGroup()

                // Glow ring
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                .white.opacity(0.3),
                                .blue.opacity(0.4),
                                .purple.opacity(0.3),
                                .white.opacity(0.3)
                            ]),
                            center: .center
                        ),
                        lineWidth: 30
                    )
                    .blur(radius: 15)
                    .frame(width: 130, height: 130)
                    .scaleEffect(pulse ? 1.03 : 0.97)
                    .opacity(0.6)
                    .blendMode(.screen)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            pulse.toggle()
                        }
                    }

                // Reactive center glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                showGlow ? Color.red.opacity(0.6) : .clear,
                                .clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .animation(.easeOut(duration: 0.5), value: showGlow)

                // Black hole core
                Circle()
                    .fill(Color.black)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )

                // Touch interaction (only center glow)
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .updating($fingerLocation) { value, state, _ in
                                state = value.location
                                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                                let distance = hypot(center.x - value.location.x, center.y - value.location.y)
                                if distance < 40 {
                                    if !showGlow {
                                        triggerGlow()
                                    }
                                }
                            }
                    )
            }
            .onReceive(timer) { _ in
                time += 1
            }
        }
    }

    func triggerGlow() {
        showGlow = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showGlow = false
        }
    }
}
