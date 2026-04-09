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

    var otherUser: User { match.otherUser }
    var previewText: String {
        lastMessage?.displayText ?? match.aiIcebreaker ?? "You matched!"
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

    var displayText: String { content }
    var isRead: Bool { readAt != nil }
}
