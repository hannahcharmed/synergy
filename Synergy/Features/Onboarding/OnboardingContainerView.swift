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
                ForEach(1..<8) { i in
                    Capsule()
                        .fill(stepColor(for: i))
                        .frame(width: stepWidth(for: i), height: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.currentStep)
                }
            }
            .frame(maxWidth: .infinity)

            // Skip (only on optional steps)
            if showSkip {
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

    // MARK: - Skip (discovery is skippable)

    var showSkip: Bool {
        vm.currentStep == .notifications || vm.currentStep == .discovery
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
        case .discovery:    OnboardingDiscoveryView()
        case .notifications: NotificationOptInView()
        case .firstMatch:   FirstMatchRevealView {
            coordinator.completeOnboarding()
        }
        }
    }
}

// MARK: - Onboarding Discovery View (Step 06)

struct OnboardingDiscoveryView: View {
    @EnvironmentObject var vm: OnboardingViewModel
    @State private var maxDistance: Double = 25
    @State private var minAge: Double = 22
    @State private var maxAge: Double = 35
    @State private var selectedGenders: Set<String> = ["Everyone"]

    private let genderOptions = ["Women", "Men", "Non-binary", "Everyone"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header

                // Who to show
                settingGroup(title: "SHOW_ME") {
                    VStack(spacing: 0) {
                        ForEach(genderOptions, id: \.self) { option in
                            Button {
                                if option == "Everyone" {
                                    selectedGenders = ["Everyone"]
                                } else {
                                    selectedGenders.remove("Everyone")
                                    if selectedGenders.contains(option) {
                                        selectedGenders.remove(option)
                                    } else {
                                        selectedGenders.insert(option)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(option)
                                        .font(SynergyFont.body(15))
                                        .foregroundColor(.cosmicNeutral)
                                    Spacer()
                                    Image(systemName: selectedGenders.contains(option)
                                          ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedGenders.contains(option)
                                                         ? .cosmicCyan : .cosmicBorder)
                                }
                                .padding(.vertical, Spacing.sm)
                            }
                            .buttonStyle(.plain)
                            if option != genderOptions.last {
                                Divider().overlay(Color.cosmicBorder)
                            }
                        }
                    }
                }

                // Distance
                settingGroup(title: "MAX_DISTANCE") {
                    VStack(spacing: Spacing.sm) {
                        HStack {
                            Text("Within \(Int(maxDistance)) miles")
                                .font(SynergyFont.body(15))
                                .foregroundColor(.cosmicNeutral)
                            Spacer()
                        }
                        Slider(value: $maxDistance, in: 5...100, step: 5)
                            .tint(.cosmicCyan)
                    }
                }

                // Age range
                settingGroup(title: "AGE_RANGE") {
                    VStack(spacing: Spacing.sm) {
                        HStack {
                            Text("\(Int(minAge)) to \(Int(maxAge)) years")
                                .font(SynergyFont.body(15))
                                .foregroundColor(.cosmicNeutral)
                            Spacer()
                        }
                        HStack(spacing: Spacing.md) {
                            Text("Min").systemLabel().frame(width: 28)
                            Slider(value: $minAge, in: 18...maxAge - 1, step: 1).tint(.cosmicPurple)
                        }
                        HStack(spacing: Spacing.md) {
                            Text("Max").systemLabel().frame(width: 28)
                            Slider(value: $maxAge, in: minAge + 1...65, step: 1).tint(.cosmicPurple)
                        }
                    }
                }

                CosmicButton("Looks good", variant: .gradient) {
                    vm.advance()
                }
                .padding(.bottom, Spacing.xxxl)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.lg)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("05 / 07")
                .systemLabel()
                .foregroundColor(.cosmicCyan.opacity(0.8))
            Text("Who you'd like to meet")
                .font(SynergyFont.headline(30))
                .foregroundColor(.cosmicNeutral)
            Text("You can always change this later")
                .font(SynergyFont.body(15))
                .foregroundColor(.cosmicMuted)
        }
    }

    private func settingGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title).systemLabel()
            content()
                .padding(Spacing.lg)
                .cosmicCard()
        }
    }
}
