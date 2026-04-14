import SwiftUI

// MARK: - Paywall / Subscription Tiers
// Stardust (free) · Cosmic £14.99 · Oracle £34.99

struct PaywallView: View {
    @EnvironmentObject var vm: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedTier: SubscriptionTier = .cosmic
    @State private var showingPurchase = false

    var body: some View {
        // iOS 15: NavigationView; iOS 16+: replace with NavigationStack
        NavigationView {
            ZStack {
                LinearGradient.onboardingBg.ignoresSafeArea()
                StarParticleView(count: 40).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        header
                        tierCards
                        selectedFeatures
                        ctaButton
                        legalFooter
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.xl)
                    .padding(.bottom, Spacing.xxxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.cosmicMuted)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                OrbitalRingView(diameter: 80)
                Text("✦")
                    .font(.system(size: 32))
                    .foregroundColor(.cosmicCyan)
                    .cosmicGlow(color: .cosmicCyan, radius: 16)
            }
            .frame(width: 100, height: 100)

            Text("Unlock the cosmos")
                .font(SynergyFont.headline(28))
                .foregroundColor(.cosmicNeutral)
                .multilineTextAlignment(.center)

            Text("Get full synastry, unlimited matches,\nand daily cosmic intelligence")
                .font(SynergyFont.body(14))
                .foregroundColor(.cosmicMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }

    // MARK: - Tier Cards

    private var tierCards: some View {
        HStack(spacing: Spacing.md) {
            ForEach([SubscriptionTier.cosmic, .oracle], id: \.self) { tier in
                TierCard(
                    tier: tier,
                    isSelected: selectedTier == tier,
                    isMostPopular: tier == .cosmic
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTier = tier
                    }
                }
            }
        }
    }

    // MARK: - Feature List

    private var selectedFeatures: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("INCLUDED")
                .systemLabel()

            ForEach(selectedTier.features, id: \.self) { feature in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.cosmicCyan)
                    Text(feature)
                        .font(SynergyFont.body(14))
                        .foregroundColor(.cosmicNeutral)
                    Spacer()
                }
            }
        }
        .padding(Spacing.lg)
        .cosmicCard()
        .animation(.easeInOut(duration: 0.2), value: selectedTier)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        VStack(spacing: Spacing.md) {
            CosmicButton(
                "Start \(selectedTier.displayName) · \(selectedTier.monthlyPrice)",
                variant: .gradient
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                vm.upgradeTo(selectedTier)
            }
            .cosmicGlow(color: .cosmicPurple, radius: 20)

            Text("Cancel anytime · Billed monthly")
                .font(SynergyFont.body(12))
                .foregroundColor(.cosmicMuted)
        }
    }

    // MARK: - Legal

    private var legalFooter: some View {
        VStack(spacing: 6) {
            HStack(spacing: Spacing.lg) {
                Button("Restore purchases") {}
                    .font(SynergyFont.body(12))
                    .foregroundColor(.cosmicMuted)
                Button("Terms") {}
                    .font(SynergyFont.body(12))
                    .foregroundColor(.cosmicMuted)
                Button("Privacy") {}
                    .font(SynergyFont.body(12))
                    .foregroundColor(.cosmicMuted)
            }
        }
    }
}

// MARK: - Tier Card

struct TierCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let isMostPopular: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.md) {
                // Popular badge
                if isMostPopular {
                    Text("MOST POPULAR")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.cosmicDark)
                        .kerning(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(LinearGradient.cosmicGradient)
                        .clipShape(Capsule())
                } else {
                    Text("PREMIUM")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.cosmicPurple)
                        .kerning(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.cosmicPurple.opacity(0.15))
                        .clipShape(Capsule())
                }

                // Icon
                Image(systemName: tier.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(
                        isSelected ? LinearGradient.cosmicGradient : LinearGradient(colors: [.cosmicMuted], startPoint: .top, endPoint: .bottom)
                    )

                // Name
                Text(tier.rawValue)
                    .font(SynergyFont.headline(18))
                    .foregroundColor(.cosmicNeutral)

                // Price
                Text(tier.monthlyPrice)
                    .font(SynergyFont.headlineMedium(14))
                    .foregroundColor(isSelected ? .cosmicCyan : .cosmicMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(Color.cosmicCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .strokeBorder(
                                isSelected
                                    ? LinearGradient.cosmicGradient
                                    : LinearGradient(colors: [Color.cosmicBorder], startPoint: .top, endPoint: .bottom),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .cosmicGlow(color: .cosmicCyan, radius: isSelected ? 12 : 0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}
