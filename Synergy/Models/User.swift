import Foundation

// MARK: - User

struct User: Codable, Identifiable {
    let id: UUID
    let displayName: String
    let age: Int
    let subscriptionTier: SubscriptionTier
    let birthChart: BirthChart
    let profile: UserProfile
    let locationDisplay: String     // "London, UK" (never exact coords)
    let distanceMiles: Double?
    let lastActive: Date
    let isVerified: Bool

    var isOnline: Bool {
        Date().timeIntervalSince(lastActive) < 300 // 5 minutes
    }
}

// MARK: - Profile Prompt

struct ProfilePrompt: Codable, Identifiable {
    let id: UUID
    let question: String
    let answer: String

    init(id: UUID = UUID(), question: String, answer: String) {
        self.id = id
        self.question = question
        self.answer = answer
    }
}

// Common Hinge-style prompt questions
enum PromptQuestion: String, CaseIterable {
    case wrongAboutSign   = "What people always get wrong about my sign"
    case perfectDay       = "My perfect Sunday looks like"
    case loveLanguage     = "My love language is"
    case dealbreaker      = "My biggest dealbreaker"
    case moonSign         = "My moon sign explains why I"
    case firstDate        = "On a first date I always"
    case venusSign        = "My Venus sign in real life"
    case greenFlag        = "My biggest green flag"
    case rizz             = "You should know about me"
}

// MARK: - User Profile

struct UserProfile: Codable {
    var photos: [String]            // S3 keys / local asset names
    var bio: String?
    var intentionTags: [RelationshipIntention]
    var vibeWords: [String]         // 3-word vibe tags
    var prompts: [ProfilePrompt]    // Hinge-style Q&A prompts (up to 3)
    var promptAnswer: String?       // Legacy single prompt answer
    var height: String?
    var occupation: String?

    // Convenience: photos count for gallery display
    var photoCount: Int { photos.count }

    init(photos: [String], bio: String? = nil,
         intentionTags: [RelationshipIntention],
         vibeWords: [String], prompts: [ProfilePrompt] = [],
         promptAnswer: String? = nil,
         height: String? = nil, occupation: String? = nil) {
        self.photos = photos
        self.bio = bio
        self.intentionTags = intentionTags
        self.vibeWords = vibeWords
        self.prompts = prompts
        self.promptAnswer = promptAnswer
        self.height = height
        self.occupation = occupation
    }
}

// MARK: - Subscription Tiers

enum SubscriptionTier: String, Codable {
    case stardust = "Stardust"   // Free
    case cosmic   = "Cosmic"     // £14.99/mo
    case oracle   = "Oracle"     // £34.99/mo

    var displayName: String { rawValue }

    var monthlyPrice: String {
        switch self {
        case .stardust: return "Free"
        case .cosmic:   return "£14.99/mo"
        case .oracle:   return "£34.99/mo"
        }
    }

    var icon: String {
        switch self {
        case .stardust: return "star"
        case .cosmic:   return "sparkles"
        case .oracle:   return "eye"
        }
    }

    var canAccessFullSynastry: Bool { self != .stardust }
    var canSeeWhoLiked: Bool { self != .stardust }
    var hasUnlimitedSwipes: Bool { self != .stardust }
    var hasLiveAstrologer: Bool { self == .oracle }
    var dailySwipeLimit: Int? { self == .stardust ? 5 : nil }

    var features: [String] {
        switch self {
        case .stardust:
            return ["Sun sign matching", "5 daily swipes", "Daily horoscope", "Basic birth chart", "Cosmic icebreakers"]
        case .cosmic:
            return ["Full synastry matching", "Unlimited swipes", "Transit-boosted scores",
                    "Who liked you", "AI chart narration", "Ritual challenges", "Partner compatibility PDF"]
        case .oracle:
            return ["Everything in Cosmic", "Live astrologer chat", "Annual forecast",
                    "Compatibility vault", "Priority matching", "Exclusive events"]
        }
    }
}

// MARK: - Current User (logged-in session)

class CurrentUser: ObservableObject {
    @Published var user: User?
    @Published var isOnboarded: Bool = false
    @Published var onboardingStep: OnboardingStep = .welcome

    // Draft state during onboarding
    @Published var draftName: String = ""
    @Published var draftBirthDate: Date? = nil
    @Published var draftBirthTime: Date? = nil
    @Published var draftBirthCity: String = ""
    @Published var draftIntentions: Set<RelationshipIntention> = []
    @Published var draftPhotos: [String] = []
    @Published var draftBio: String = ""
    @Published var draftVibeWords: [String] = []

    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case birthChart = 1
        case chartReveal = 2
        case intention = 3
        case profile = 4
        case discovery = 5
        case notifications = 6
        case firstMatch = 7
    }
}
