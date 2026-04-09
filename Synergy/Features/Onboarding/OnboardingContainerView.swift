import SwiftUI

// MARK: - Onboarding Container
// Manages the 7-step onboarding flow with progress indicator and step transitions.

struct OnboardingContainerView: View {
    @StateObject private var vm = OnboardingViewModel()
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        ZStack {
            // Persistent star background
            StarParticleView(count: 60)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: back + progress
                if vm.currentStep != .welcome {
                    topBar
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Step content
                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .environmentObject(vm)
        .onChange(of: vm.currentStep) { step in
            vm.logFunnelEvent(step)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: Spacing.md) {
            // Back button
            if vm.currentStep != .birthChart {
                Button { vm.back() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.cosmicNeutral)
                        .frame(width: 36, height: 36)
                        .background(Color.cosmicCard)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color.cosmicBorder, lineWidth: 1))
                }
            } else {
                Spacer().frame(width: 36)
            }

            // Step progress dots
            HStack(spacing: 6) {
                ForEach(1..<7) { i in
                    Capsule()
                        .fill(stepColor(for: i))
                        .frame(width: stepWidth(for: i), height: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.currentStep)
                }
            }
            .frame(maxWidth: .infinity)

            // Skip (only on optional steps)
            if vm.currentStep == .notifications {
                Button { vm.advance() } label: {
                    Text("Skip")
                        .font(SynergyFont.body(14))
                        .foregroundColor(.cosmicMuted)
                }
            } else {
                Spacer().frame(width: 36)
            }
        }
    }

    private func stepColor(for i: Int) -> Color {
        i <= vm.currentStep.rawValue ? .cosmicCyan : Color.cosmicBorder
    }

    private func stepWidth(for i: Int) -> CGFloat {
        i == vm.currentStep.rawValue ? 24 : 8
    }

    // MARK: - Step Content Router

    @ViewBuilder
    private var stepContent: some View {
        switch vm.currentStep {
        case .welcome:      WelcomeView()
        case .birthChart:   BirthChartCaptureView()
        case .chartReveal:  ChartRevealView()
        case .intention:    IntentionView()
        case .profile:      ProfileSetupView()
        case .notifications: NotificationOptInView()
        case .firstMatch:   FirstMatchRevealView {
            coordinator.completeOnboarding()
        }
        }
    }
}
