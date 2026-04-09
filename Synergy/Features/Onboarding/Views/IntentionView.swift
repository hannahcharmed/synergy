import SwiftUI

// MARK: - Screen 04: Relationship Intention
// "Calling in" framing — not "looking for"
// Max 2 selections. Multi-select with haptic.

struct IntentionView: View {
    @EnvironmentObject var vm: OnboardingViewModel
    @State private var appeared = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.lg)

            // Grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: Spacing.md) {
                    ForEach(Array(RelationshipIntention.allCases.enumerated()), id: \.element.id) { idx, intention in
                        IntentionCard(
                            intention: intention,
                            isSelected: vm.selectedIntentions.contains(intention),
                            isDisabled: vm.selectedIntentions.count >= 2 && !vm.selectedIntentions.contains(intention)
                        ) {
                            vm.toggleIntention(intention)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                                .delay(Double(idx) * 0.06),
                            value: appeared
                        )
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }

            // CTA pinned bottom
            bottomBar
        }
        .onAppear { appeared = true }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("SEQUENCE // 04")
                .systemLabel()
                .foregroundColor(.cosmicCyan.opacity(0.8))

            Text("What are you\ncalling in?")
                .font(SynergyFont.headline(30))
                .foregroundColor(.cosmicNeutral)
                .lineSpacing(2)

            Text("Not 'what are you looking for' — but what energy\ndo you want to invite into your life?")
                .font(SynergyFont.body(14))
                .foregroundColor(.cosmicMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if vm.selectedIntentions.count > 0 {
                Text("Select up to \(2 - vm.selectedIntentions.count) more")
                    .font(SynergyFont.body(12))
                    .foregroundColor(.cosmicCyan)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.selectedIntentions.count)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: Spacing.sm) {
            CosmicButton(
                "This feels right →",
                variant: vm.canAdvanceFromIntention ? .gradient : .outlined
            ) {
                vm.advance()
            }
            .disabled(!vm.canAdvanceFromIntention)
            .opacity(vm.canAdvanceFromIntention ? 1.0 : 0.4)
            .animation(.easeInOut(duration: 0.2), value: vm.canAdvanceFromIntention)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.xxxl)
    }
}

// MARK: - Intention Card

struct IntentionCard: View {
    let intention: RelationshipIntention
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(isSelected
                              ? AnyShapeStyle(LinearGradient.cosmicGradient)
                              : AnyShapeStyle(Color.cosmicCard))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle().strokeBorder(
                                isSelected ? Color.clear : Color.cosmicBorder,
                                lineWidth: 1
                            )
                        )

                    Image(systemName: intention.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? .cosmicDark : .cosmicMuted)
                }

                Text(intention.rawValue)
                    .font(SynergyFont.body(13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .cosmicNeutral : .cosmicMuted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .padding(.horizontal, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(isSelected
                          ? Color.cosmicCyan.opacity(0.08)
                          : Color.cosmicCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(
                        isSelected ? Color.cosmicCyan.opacity(0.6) : Color.cosmicBorder,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .opacity(isDisabled ? 0.35 : 1.0)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .cosmicGlow(color: .cosmicCyan, radius: isSelected ? 8 : 0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityLabel(intention.rawValue)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
