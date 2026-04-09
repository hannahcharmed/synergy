import SwiftUI

// MARK: - Star Particle System (SwiftUI implementation of SpriteKit spec)

struct StarParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
    var twinklePhase: Double
}

struct StarParticleView: View {
    let count: Int
    @State private var particles: [StarParticle] = []
    @State private var phase: Double = 0
    @State private var isAnimating = false

    init(count: Int = 80) {
        self.count = count
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deep space background
                Color.cosmicDarkAlt

                // Nebula glow blobs
                nebulaLayer(size: geo.size)

                // Stars
                Canvas { context, size in
                    for particle in particles {
                        let twinkle = sin(phase * particle.speed + particle.twinklePhase)
                        let currentOpacity = particle.opacity * (0.5 + 0.5 * twinkle)
                        let currentSize = particle.size * (0.85 + 0.15 * twinkle)

                        let rect = CGRect(
                            x: particle.x * size.width - currentSize / 2,
                            y: particle.y * size.height - currentSize / 2,
                            width: currentSize,
                            height: currentSize
                        )

                        var star = context
                        star.opacity = currentOpacity

                        // Large stars get a glow
                        if particle.size > 2.5 {
                            let glowRect = rect.insetBy(dx: -currentSize, dy: -currentSize)
                            star.fill(
                                Ellipse().path(in: glowRect),
                                with: .color(.cosmicCyan.opacity(0.15))
                            )
                        }

                        star.fill(
                            Ellipse().path(in: rect),
                            with: .color(starColor(for: particle))
                        )
                    }
                }
                .onAppear {
                    generateParticles()
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                        phase = .pi * 2
                    }
                }

                // Shooting star effect (rare)
                ShootingStarView()
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func nebulaLayer(size: CGSize) -> some View {
        ZStack {
            // Purple nebula top-right
            Ellipse()
                .fill(Color.cosmicPurple.opacity(0.07))
                .frame(width: size.width * 0.7, height: size.height * 0.4)
                .blur(radius: 60)
                .offset(x: size.width * 0.25, y: -size.height * 0.1)

            // Cyan nebula bottom-left
            Ellipse()
                .fill(Color.cosmicCyan.opacity(0.05))
                .frame(width: size.width * 0.5, height: size.height * 0.3)
                .blur(radius: 50)
                .offset(x: -size.width * 0.15, y: size.height * 0.2)
        }
    }

    private func starColor(for particle: StarParticle) -> Color {
        if particle.size > 2.8 {
            return .cosmicCyan.opacity(0.9)
        } else if particle.size > 2.0 {
            return Color.white.opacity(0.9)
        } else {
            return Color.white.opacity(0.6)
        }
    }

    private func generateParticles() {
        particles = (0..<count).map { _ in
            StarParticle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 0.8...3.5),
                opacity: Double.random(in: 0.4...1.0),
                speed: Double.random(in: 0.3...1.2),
                twinklePhase: Double.random(in: 0...(.pi * 2))
            )
        }
    }
}

// MARK: - Shooting Star

struct ShootingStarView: View {
    @State private var isVisible = false
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            if isVisible {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .cosmicCyan.opacity(0.8), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 80, height: 1.5)
                    .rotationEffect(.degrees(-35))
                    .offset(offset)
                    .opacity(opacity)
            }
        }
        .onAppear {
            scheduleShootingStar()
        }
    }

    private func scheduleShootingStar() {
        let delay = Double.random(in: 4...10)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            isVisible = true
            offset = CGSize(width: -200, height: -100)
            withAnimation(.easeIn(duration: 0.8)) {
                offset = CGSize(width: 200, height: 200)
                opacity = 1
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                isVisible = false
                scheduleShootingStar()
            }
        }
    }
}

// MARK: - Orbital Ring (chart decoration)

struct OrbitalRingView: View {
    let diameter: CGFloat
    var dashed: Bool = false
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        Color.cosmicCyan.opacity(0.3),
                        Color.cosmicPurple.opacity(0.15),
                        Color.cosmicCyan.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(
                    lineWidth: 1,
                    dash: dashed ? [4, 8] : []
                )
            )
            .frame(width: diameter, height: diameter)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: dashed ? 30 : 20).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Constellation background pattern

struct ConstellationPatternView: View {
    var body: some View {
        Canvas { context, size in
            let points: [CGPoint] = [
                CGPoint(x: size.width * 0.15, y: size.height * 0.2),
                CGPoint(x: size.width * 0.35, y: size.height * 0.12),
                CGPoint(x: size.width * 0.55, y: size.height * 0.25),
                CGPoint(x: size.width * 0.45, y: size.height * 0.4),
                CGPoint(x: size.width * 0.65, y: size.height * 0.35),
                CGPoint(x: size.width * 0.8, y: size.height * 0.18),
                CGPoint(x: size.width * 0.25, y: size.height * 0.6),
                CGPoint(x: size.width * 0.7, y: size.height * 0.65),
                CGPoint(x: size.width * 0.85, y: size.height * 0.55),
            ]

            // Draw connecting lines
            let connections: [(Int, Int)] = [(0,1),(1,2),(2,4),(4,5),(2,3),(3,6),(4,7),(7,8)]
            for (a, b) in connections {
                var path = Path()
                path.move(to: points[a])
                path.addLine(to: points[b])
                context.stroke(path, with: .color(.cosmicCyan.opacity(0.08)), lineWidth: 1)
            }

            // Draw star nodes
            for point in points {
                let rect = CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4)
                context.fill(Ellipse().path(in: rect), with: .color(.cosmicCyan.opacity(0.25)))
            }
        }
    }
}
