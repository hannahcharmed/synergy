import SwiftUI
import Combine

// MARK: - App Coordinator
// Top-level navigation state machine. Controls onboarding → main app flow.

final class AppCoordinator: ObservableObject {
    @Published var state: AppState = .loading

    enum AppState {
        case loading
        case onboarding
        case main
    }

    init() {
        // In production, check Keychain for valid session token
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // Check if user has completed onboarding
            let hasOnboarded = UserDefaults.standard.bool(forKey: "synergy_onboarded")
            self.state = hasOnboarded ? .main : .onboarding
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "synergy_onboarded")
        withAnimation(.easeInOut(duration: 0.5)) {
            state = .main
        }
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: "synergy_onboarded")
        withAnimation(.easeInOut(duration: 0.4)) {
            state = .onboarding
        }
    }
}

// MARK: - App Root View

struct AppRootView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        Group {
            switch coordinator.state {
            case .loading:
                SplashView()
            case .onboarding:
                OnboardingContainerView()
                    .transition(.opacity)
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: coordinator.state)
    }
}

// MARK: - Splash / Launch Screen

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient.onboardingBg
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                // Wordmark
                Text("SYNERGY")
                    .font(SynergyFont.headline(38))
                    .foregroundColor(.cosmicNeutral)
                    .kerning(8)

                Text("✦")
                    .font(.system(size: 20))
                    .foregroundColor(.cosmicCyan)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}
