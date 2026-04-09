import SwiftUI

// MARK: - Screen 07: First Match Reveal
// Confetti + haptic on reveal. Immediate payoff — the hook.
// Logs match_first_seen analytics event.

struct FirstMatchRevealView: View {
    @EnvironmentObject var vm: OnboardingViewModel
    let onComplete: () -> Void

    @State private var cardScale: CGFloat = 0.7
    @State private var cardOpacity: Double = 0
    @State private var confettiActive = false
    @State private var scoreOpacity: Double = 0
    @State private var detailsOpacity: Double = 0

    private var match: FeedItem? { vm.firstMatch }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            header
                .padding(.horizontal, Spacing.xl)

            Spacer()

            // Match card
            if let match = match {
                firstMatchCard(match: match)
                    .padding(.horizontal, Spacing.xl)
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
            } else {
                ProgressView().tint(.cosmicCyan)
            }

            Spacer()

            // CTA
            CosmicButton("Send icebreaker →", variant: .gradient) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onComplete()
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxxl)
            .opacity(detailsOpacity)
        }
        .overlay(alignment: .top) {
            if confettiActive {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear { runReveal() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            Text("SEQUENCE // 07")
                .systemLabel()
                .foregroundColor(.cosmicCyan.opacity(0.8))

            Text("Your top match ✦")
                .font(SynergyFont.headline(30))
                .foregroundColor(.cosmicNeutral)
        }
    }

    // MARK: - Match Card

    private func firstMatchCard(match: FeedItem) -> some View {
        VStack(spacing: 0) {
            // Photo area (placeholder gradient)
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [Color.cosmicPurple.opacity(0.3), Color.cosmicCyan.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 220)
                .overlay(
                    Text(match.user.displayName.prefix(1))
                        .font(SynergyFont.headline(72))
                        .foregroundColor(.cosmicNeutral.opacity(0.2))
                )

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, Color.cosmicCard],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }

            // Card content
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Name + score row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: Spacing.sm) {
                            Text("\(match.user.displayName), \(match.user.age)")
                                .font(SynergyFont.headline(22))
                                .foregroundColor(.cosmicNeutral)

                            if match.user.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.cosmicCyan)
                            }
                        }

                        HStack(spacing: Spacing.sm) {
                            Text(match.user.birthChart.sunSign.rawValue)
                                .font(SynergyFont.body(13))
                                .foregroundColor(.cosmicMuted)

                            if let dist = match.user.distanceMiles {
                                Text("· \(String(format: "%.1f", dist)) mi")
                                    .font(SynergyFont.body(13))
                                    .foregroundColor(.cosmicMuted)
                            }
                        }
                    }

                    Spacer()

                    MatchScoreBadge(score: match.cosmicScore, size: .medium)
                        .opacity(scoreOpacity)
                }

                // Aspect highlights
                HStack(spacing: Spacing.sm) {
                    ForEach(match.highlights.prefix(2), id: \.self) { h in
                        PlanetAspectTag(text: h, highlighted: true)
                    }
                    if let boost = match.transitBoost {
                        PlanetAspectTag(text: "+\(boost.points)pts today", highlighted: false)
                    }
                }
                .opacity(detailsOpacity)

                // AI Icebreaker
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("AI_ICEBREAKER")
                        .systemLabel()
                    Text(""\(match.aiIcebreaker)"")
                        .font(SynergyFont.body(14))
                        .foregroundColor(.cosmicNeutral.opacity(0.8))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.md)
                .background(Color.cosmicDarkAlt)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .strokeBorder(Color.cosmicBorder, lineWidth: 1)
                )
                .opacity(detailsOpacity)
            }
            .padding(Spacing.lg)
        }
        .cosmicCard()
        .cardShadow()
        .cosmicPurpleGlow(radius: 20)
    }

    // MARK: - Reveal Animation

    private func runReveal() {
        // Haptic on appear
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.2)) {
            cardScale = 1.0
            cardOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            scoreOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.9)) {
            detailsOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            confettiActive = true
        }

        // Log analytics
        print("[Analytics] match_first_seen")
    }
}

// MARK: - Confetti View (lightweight SwiftUI)

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        Canvas { context, size in
            for p in particles {
                let rect = CGRect(x: p.x, y: p.y, width: p.size, height: p.size * 0.5)
                var ctx = context
                ctx.opacity = p.opacity
                ctx.rotate(by: .degrees(p.rotation))
                ctx.fill(
                    RoundedRectangle(cornerRadius: 2).path(in: rect),
                    with: .color(p.color)
                )
            }
        }
        .onAppear { spawnParticles() }
    }

    private func spawnParticles() {
        let colors: [Color] = [.cosmicCyan, .cosmicPurple, Color(hex: "#FFB800"),
                               Color(hex: "#FF6B9D"), .cosmicNeutral]
        particles = (0..<60).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...400),
                y: -20,
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement()!,
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                velocityY: Double.random(in: 200...500),
                velocityX: Double.random(in: -60...60)
            )
        }

        withAnimation(.linear(duration: 2)) {
            for i in particles.indices {
                particles[i].y += particles[i].velocityY
                particles[i].x += particles[i].velocityX
                particles[i].rotation += 180
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
    var rotation: Double
    var velocityY: Double
    var velocityX: Double
}
