import SwiftUI
import Combine

// MARK: - Onboarding ViewModel
// Manages all 7 onboarding steps and draft state.

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: CurrentUser.OnboardingStep = .welcome
    @Published var isLoading = false
    @Published var showChartReveal = false

    // Step 2 — Birth Chart
    @Published var fullName: String = ""
    @Published var birthDate: Date? = nil
    @Published var birthTime: Date? = nil
    @Published var birthCity: String = ""
    @Published var birthCitySuggestions: [String] = []

    // Step 3 — Chart Reveal
    @Published var computedChart: BirthChart? = nil
    @Published var chartRevealProgress: Double = 0

    // Step 4 — Intention
    @Published var selectedIntentions: Set<RelationshipIntention> = []

    // Step 5 — Profile
    @Published var photos: [UIImage] = []
    @Published var bio: String = ""
    @Published var vibeWords: [String] = []
    @Published var vibeInput: String = ""
    @Published var prompts: [ProfilePrompt] = []

    // Step 6 — Discovery (preferences)

    // Step 7 — Notifications
    @Published var notificationsGranted = false

    // Step 8 — First Match
    @Published var firstMatch: FeedItem? = nil

    // Validation
    var canAdvanceFromBirthChart: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        birthDate != nil &&
        !birthCity.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var canAdvanceFromIntention: Bool {
        !selectedIntentions.isEmpty
    }

    var canAdvanceFromProfile: Bool {
        !photos.isEmpty
    }

    // MARK: - Navigation

    func advance() {
        let steps = CurrentUser.OnboardingStep.allCases
        guard let idx = steps.firstIndex(of: currentStep),
              idx + 1 < steps.count else { return }

        // Side effects per step
        switch currentStep {
        case .birthChart:
            computeChart()
        case .notifications:
            loadFirstMatch()
        default:
            break
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            currentStep = steps[idx + 1]
        }
    }

    func back() {
        let steps = CurrentUser.OnboardingStep.allCases
        guard let idx = steps.firstIndex(of: currentStep), idx > 0 else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            currentStep = steps[idx - 1]
        }
    }

    // MARK: - Birth Chart Computation

    private func computeChart() {
        guard let date = birthDate else { return }
        isLoading = true
        // Simulate async Swiss Ephemeris call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            self.computedChart = MockDataService.shared.currentUserChart(
                name: self.fullName,
                birthDate: date,
                birthTime: self.birthTime,
                city: self.birthCity
            )
            self.isLoading = false
            // Animate planet reveal
            self.animateChartReveal()
        }
    }

    private func animateChartReveal() {
        chartRevealProgress = 0
        withAnimation(.easeInOut(duration: 2.4)) {
            chartRevealProgress = 1.0
        }
    }

    // MARK: - City Autocomplete (mock — replace with Google Places)

    func searchCity(_ query: String) {
        guard query.count > 1 else { birthCitySuggestions = []; return }
        let mockCities = [
            "London, UK", "Los Angeles, CA", "New York, NY", "Manchester, UK",
            "Dublin, Ireland", "Paris, France", "Sydney, Australia", "Toronto, Canada",
            "Berlin, Germany", "Amsterdam, Netherlands", "Barcelona, Spain"
        ]
        birthCitySuggestions = mockCities.filter {
            $0.lowercased().hasPrefix(query.lowercased())
        }
    }

    func selectCity(_ city: String) {
        birthCity = city
        birthCitySuggestions = []
    }

    // MARK: - Intentions (max 2)

    func toggleIntention(_ intention: RelationshipIntention) {
        if selectedIntentions.contains(intention) {
            selectedIntentions.remove(intention)
        } else if selectedIntentions.count < 2 {
            selectedIntentions.insert(intention)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    // MARK: - Vibe Words (max 3)

    func addVibeWord() {
        let word = vibeInput.trimmingCharacters(in: .whitespaces)
        guard !word.isEmpty, vibeWords.count < 3 else { return }
        vibeWords.append(word)
        vibeInput = ""
    }

    func removeVibeWord(at index: Int) {
        vibeWords.remove(at: index)
    }

    // MARK: - Notifications

    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsGranted = granted
                if granted { self.scheduleDaily7amNotification() }
                self.advance()
            }
        }
    }

    private func scheduleDaily7amNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Your cosmic reading is ready ✦"
        content.body = "See which matches are aligned with you today."
        content.sound = .default

        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "synergy.daily", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - First Match

    private func loadFirstMatch() {
        let feed = MockDataService.shared.fetchFeed(limit: 1)
        firstMatch = feed.first
    }

    // MARK: - Funnel Analytics (stub — wire to Mixpanel in prod)

    func logFunnelEvent(_ step: CurrentUser.OnboardingStep) {
        // Mixpanel.mainInstance().track(event: "onboarding_step_\(step.rawValue)")
        print("[Analytics] onboarding_step_\(step.rawValue)")
    }
}
