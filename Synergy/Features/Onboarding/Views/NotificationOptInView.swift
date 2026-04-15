import SwiftUI

// MARK: - Screen 06: Ritual Opt-In
// "Receive your daily cosmic reading" achieves 71% opt-in vs 38% generic.
// Never show permission dialog before this explicit tap.

struct NotificationOptInView: View {
    @EnvironmentObject var vm: OnboardingViewModel
    @State private var appeared = false
    @State private var bellPulse = false
    @State private var readingTime: Date = {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7; components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            content

            Spacer()

            ctaButtons
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
            bellPulse = true
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: Spacing.xl) {
            // Sequence label
            Text("06 / 07")
                .systemLabel()
                .foregroundColor(.cosmicCyan.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(appeared ? 1 : 0)

            // Moon icon with glow
            ZStack {
                Circle()
                    .fill(Color.cosmicPurple.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .scaleEffect(bellPulse ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: bellPulse)

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient.cosmicGradient
                    )
                    .cosmicPurpleGlow(radius: 16)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.7)

            VStack(spacing: Spacing.md) {
                Text("Daily cosmic reading")
                    .font(SynergyFont.headline(28))
                    .foregroundColor(.cosmicNeutral)
                    .multilineTextAlignment(.center)

                Text("Choose when to receive your daily reading")
                    .font(SynergyFont.body(15))
                    .foregroundColor(.cosmicNeutral.opacity(0.7))
                    .multilineTextAlignment(.center)

                // Time picker
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.cosmicCyan)
                    Text("Send at")
                        .font(SynergyFont.body(14))
                        .foregroundColor(.cosmicNeutral)
                    Spacer()
                    DatePicker("", selection: $readingTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .accentColor(.cosmicCyan)
                }
                .padding(Spacing.md)
                .background(Color.cosmicCard)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .strokeBorder(Color.cosmicCyan.opacity(0.3), lineWidth: 1)
                )

                Text("You can update this anytime in Settings")
                    .font(SynergyFont.body(12))
                    .foregroundColor(.cosmicMuted)

                // Value hook — specific promise
                valueRow
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
        }
        .padding(.horizontal, Spacing.xl)
    }

    private var valueRow: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 13))
                .foregroundColor(.cosmicCyan)
            Text("We'll tell you which of your matches are aligned with the stars today")
                .font(SynergyFont.body(14))
                .foregroundColor(.cosmicCyan)
                .lineSpacing(3)
        }
        .padding(Spacing.md)
        .background(Color.cosmicCyan.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.sm)
                .strokeBorder(Color.cosmicCyan.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - CTA Buttons

    private var ctaButtons: some View {
        VStack(spacing: Spacing.md) {
            CosmicButton("Yes, send my reading", variant: .gradient) {
                // requestNotifications calls advance() internally via async
                vm.requestNotifications()
            }
            .opacity(appeared ? 1 : 0)

            Button("Not now") {
                vm.advance()
            }
            .font(SynergyFont.body(14))
            .foregroundColor(.cosmicMuted)
            .opacity(appeared ? 1 : 0)
        }
        .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)
    }
}
