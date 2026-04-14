import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User? = nil
    @Published var showPaywall = false
    @Published var showSettings = false

    init() { loadProfile() }

    private func loadProfile() {
        // Mock current user
        let chart = MockDataService.shared.currentUserChart(
            name: "You",
            birthDate: Calendar.current.date(byAdding: .year, value: -27, to: Date())!,
            birthTime: nil,
            city: "London, UK"
        )
        let profile = UserProfile(
            photos: ["you_1", "you_2"],
            bio: "Scorpio sun, Pisces rising. Depth over breadth.",
            intentionTags: [.aSoulmate, .growth],
            vibeWords: ["Intense", "Loyal", "Witchy"],
            prompts: [
                ProfilePrompt(question: PromptQuestion.wrongAboutSign.rawValue,
                              answer: "We're not as scary as we seem, just selective."),
                ProfilePrompt(question: PromptQuestion.perfectDay.rawValue,
                              answer: "Full moon, candles, a book, and zero plans."),
            ]
        )
        user = User(
            id: MockData.currentUserId,
            displayName: "You",
            age: 27,
            subscriptionTier: .stardust,
            birthChart: chart,
            profile: profile,
            locationDisplay: "London, UK",
            distanceMiles: nil,
            lastActive: Date(),
            isVerified: false
        )
    }

    func saveProfile(bio: String, vibeWords: [String], prompts: [ProfilePrompt]) {
        guard var u = user else { return }
        let cleanBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        let newProfile = UserProfile(
            photos: u.profile.photos,
            bio: cleanBio.isEmpty ? nil : cleanBio,
            intentionTags: u.profile.intentionTags,
            vibeWords: vibeWords.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
            prompts: prompts,
            promptAnswer: u.profile.promptAnswer,
            height: u.profile.height,
            occupation: u.profile.occupation
        )
        user = User(
            id: u.id, displayName: u.displayName, age: u.age,
            subscriptionTier: u.subscriptionTier, birthChart: u.birthChart,
            profile: newProfile, locationDisplay: u.locationDisplay,
            distanceMiles: u.distanceMiles, lastActive: u.lastActive,
            isVerified: u.isVerified
        )
    }

    func upgradeTo(_ tier: SubscriptionTier) {
        guard let user = user else { return }
        // In production: trigger StoreKit 2 purchase flow
        self.user = User(
            id: user.id, displayName: user.displayName, age: user.age,
            subscriptionTier: tier, birthChart: user.birthChart,
            profile: user.profile, locationDisplay: user.locationDisplay,
            distanceMiles: user.distanceMiles, lastActive: user.lastActive,
            isVerified: user.isVerified
        )
        showPaywall = false
    }
}
