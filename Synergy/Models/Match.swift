import Foundation

// MARK: - Match

struct Match: Codable, Identifiable {
    let id: UUID
    let userA: User
    let userB: User
    let cosmicScore: Int
    let synastry: SynastryResult
    let status: MatchStatus
    let createdAt: Date
    let mutualAt: Date?     // When both liked each other
    let aiIcebreaker: String?

    var otherUser: User { userB }

    var scoreHighlights: [String] {
        synastry.highlights.prefix(3).map { $0 }
    }
}

enum MatchStatus: String, Codable {
    case liked     = "liked"      // Current user liked them
    case matched   = "matched"    // Mutual
    case unmatched = "unmatched"
    case passed    = "passed"
}

// MARK: - Feed Item (card in the swipe deck)

struct FeedItem: Identifiable {
    let id: UUID
    let user: User
    let cosmicScore: Int
    let highlights: [String]
    let aiIcebreaker: String
    let transitBoost: SynastryResult.TransitBoost?

    var hasMutualLike: Bool = false     // Hidden from user per spec
    var recencyBoost: Bool = false
}

// MARK: - Like / Pass Action

enum SwipeAction {
    case like, pass, superLike
}

// MARK: - Conversation

struct Conversation: Codable, Identifiable {
    let id: UUID
    let match: Match
    var messages: [Message]
    var lastMessage: Message?
    var unreadCount: Int
    let updatedAt: Date
    let streakDays: Int          // Consecutive days of messaging
    let expiresAt: Date?         // Nil = no expiry; set when match goes cold

    var otherUser: User { match.otherUser }
    var previewText: String {
        lastMessage?.displayText ?? match.aiIcebreaker ?? "You matched!"
    }

    var hoursUntilExpiry: Int? {
        guard let exp = expiresAt else { return nil }
        let h = Int(exp.timeIntervalSinceNow / 3600)
        return h > 0 ? h : nil
    }

    init(id: UUID, match: Match, messages: [Message], lastMessage: Message?,
         unreadCount: Int, updatedAt: Date, streakDays: Int = 0, expiresAt: Date? = nil) {
        self.id = id; self.match = match; self.messages = messages
        self.lastMessage = lastMessage; self.unreadCount = unreadCount
        self.updatedAt = updatedAt; self.streakDays = streakDays
        self.expiresAt = expiresAt
    }
}

// MARK: - Message

struct Message: Codable, Identifiable {
    let id: UUID
    let conversationId: UUID
    let senderId: UUID
    let content: String     // Decrypted on device — Signal Protocol in prod
    let createdAt: Date
    var readAt: Date?
    let isFromCurrentUser: Bool
    var reactions: [String: Int]    // emoji → count
    var isVoiceNote: Bool
    var voiceDuration: Double?      // seconds (mock)

    init(id: UUID = UUID(), conversationId: UUID, senderId: UUID,
         content: String, createdAt: Date = Date(), readAt: Date? = nil,
         isFromCurrentUser: Bool, reactions: [String: Int] = [:],
         isVoiceNote: Bool = false, voiceDuration: Double? = nil) {
        self.id = id; self.conversationId = conversationId
        self.senderId = senderId; self.content = content
        self.createdAt = createdAt; self.readAt = readAt
        self.isFromCurrentUser = isFromCurrentUser; self.reactions = reactions
        self.isVoiceNote = isVoiceNote; self.voiceDuration = voiceDuration
    }

    var displayText: String { isVoiceNote ? "🎙 Voice note" : content }
    var isRead: Bool { readAt != nil }
}

// MARK: - Unmatch Reason

enum UnmatchReason: String, CaseIterable, Identifiable {
    case notAligned  = "Our energies aren't aligned"
    case cosmicPause = "Taking a cosmic pause"
    case noSpark     = "The spark wasn't there"
    case tooIntense  = "The intensity was off"
    case other       = "Another reason"
    var id: String { rawValue }
}

// MARK: - Report Reason

enum ReportReason: String, CaseIterable, Identifiable {
    case spam          = "Spam or bot"
    case harassment    = "Harassment"
    case fakeProfile   = "Fake profile"
    case inappropriate = "Inappropriate content"
    case other         = "Other"
    var id: String { rawValue }
}
