import SwiftUI

// MARK: - Screen 01: Welcome Ritual
// "Begin my chart ✦" framing vs "sign up"
// Target: 85%+ continue to Step 2

struct WelcomeView: View {
    @EnvironmentObject var vm: OnboardingViewModel
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var ctaOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.7
    @State private var glowPulse: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background handled by container (StarParticleView)

                VStack(spacing: 0) {
                    Spacer()

                    // Logo + wordmark
                    logoSection

                    Spacer()

                    // Central tagline
                    taglineSection
                        .padding(.horizontal, Spacing.xl)

                    Spacer()

                    // CTA
                    ctaSection
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, geo.safeAreaInsets.bottom + Spacing.xxl)
                }
            }
        }
        .onAppear { runEntrance() }
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: Spacing.xl) {
            // Single pulsing mark — Co-Star minimal style
            ZStack {
                Circle()
                    .stroke(Color.cosmicCyan.opacity(glowPulse ? 0.15 : 0.05), lineWidth: 1)
                    .frame(width: 120, height: 120)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: glowPulse)

                Circle()
                    .stroke(Color.cosmicCyan.opacity(glowPulse ? 0.08 : 0.03), lineWidth: 1)
                    .frame(width: 80, height: 80)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.3), value: glowPulse)

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(LinearGradient.cosmicGradient)
            }
            .frame(width: 140, height: 140)
            .scaleEffect(logoScale)
            .animation(.spring(response: 1.2, dampingFraction: 0.7), value: logoScale)

            // Wordmark
            Text("SYNERGY")
                .font(SynergyFont.headline(32))
                .foregroundColor(.cosmicNeutral)
                .kerning(8)
                .opacity(titleOpacity)
        }
    }

    // MARK: - Tagline

    private var taglineSection: some View {
        VStack(spacing: Spacing.md) {
            Text("Your cosmic journey\nbegins here")
                .font(SynergyFont.headline(28))
                .foregroundColor(.cosmicNeutral)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("We use your full birth chart to find\nyour true matches")
                .font(SynergyFont.body(16))
                .foregroundColor(.cosmicNeutral.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .opacity(subtitleOpacity)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: Spacing.md) {
            CosmicButton("Begin my chart", variant: .gradient) {
                vm.advance()
            }
            .opacity(ctaOpacity)

            Button("Sign in instead") {
                // Navigate to sign in (future)
            }
            .font(SynergyFont.body(14))
            .foregroundColor(.cosmicMuted)
            .opacity(ctaOpacity)

            // Legal micro-copy
            Text("By continuing you agree to our Terms & Privacy Policy")
                .font(SynergyFont.body(11))
                .foregroundColor(.cosmicMuted.opacity(0.5))
                .multilineTextAlignment(.center)
                .opacity(ctaOpacity)
        }
    }

    // MARK: - Entrance Animation

    private func runEntrance() {
        glowPulse = true

        withAnimation(.spring(response: 1.0, dampingFraction: 0.6).delay(0.1)) {
            logoScale = 1.0
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            titleOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            subtitleOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.9)) {
            ctaOpacity = 1.0
        }
    }
}
