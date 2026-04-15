import SwiftUI
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var activeConversation: Conversation? = nil
    @Published var messageText: String = ""
    @Published var isTyping: Bool = false

    // Icebreaker suggestions
    @Published var icebreakerSuggestions: [String] = []
    @Published var showIcebreakerSuggestions = false

    // Block/Report
    @Published var blockedUserIds: Set<UUID> = []

    var totalUnread: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    init() { loadConversations() }

    func loadConversations() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.conversations = MockDataService.shared.fetchConversations()
            self.isLoading = false
        }
    }

    func openConversation(_ conv: Conversation) {
        activeConversation = conv
        markRead(conv)
        loadIcebreakerSuggestions(for: conv)
        // Auto-show after 5s if the user hasn't typed anything
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self, self.messageText.isEmpty else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.showIcebreakerSuggestions = true
            }
        }
    }

    func markRead(_ conv: Conversation) {
        guard let idx = conversations.firstIndex(where: { $0.id == conv.id }) else { return }
        conversations[idx] = Conversation(
            id: conv.id, match: conv.match, messages: conv.messages,
            lastMessage: conv.lastMessage, unreadCount: 0, updatedAt: conv.updatedAt,
            streakDays: conv.streakDays, expiresAt: conv.expiresAt
        )
    }

    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty,
              let conv = activeConversation else { return }

        let msg = Message(
            conversationId: conv.id,
            senderId: MockData.currentUserId,
            content: messageText.trimmingCharacters(in: .whitespaces),
            isFromCurrentUser: true
        )

        applyMessage(msg, to: conv)
        messageText = ""
        showIcebreakerSuggestions = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        simulateTypingReply(in: conv)
    }

    func sendVoiceNote(duration: Double) {
        guard let conv = activeConversation else { return }
        let msg = Message(
            conversationId: conv.id,
            senderId: MockData.currentUserId,
            content: "",
            isFromCurrentUser: true,
            isVoiceNote: true,
            voiceDuration: duration
        )
        applyMessage(msg, to: conv)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        simulateTypingReply(in: conv)
    }

    func addReaction(_ emoji: String, to message: Message) {
        guard let convIdx = conversations.firstIndex(where: { $0.id == message.conversationId }),
              let msgIdx = conversations[convIdx].messages.firstIndex(where: { $0.id == message.id })
        else { return }

        var msg = conversations[convIdx].messages[msgIdx]
        let current = msg.reactions[emoji] ?? 0
        if current > 0 {
            msg.reactions.removeValue(forKey: emoji)
        } else {
            msg.reactions[emoji] = current + 1
        }
        conversations[convIdx].messages[msgIdx] = msg

        // Sync to activeConversation
        if var active = activeConversation, active.id == conversations[convIdx].id {
            active.messages[msgIdx] = msg
            activeConversation = active
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func unmatch(_ conv: Conversation, reason: UnmatchReason?) {
        conversations.removeAll { $0.id == conv.id }
        if activeConversation?.id == conv.id { activeConversation = nil }
    }

    func blockUser(_ userId: UUID, in conv: Conversation) {
        blockedUserIds.insert(userId)
        unmatch(conv, reason: nil)
    }

    // MARK: - Icebreaker suggestions

    private func loadIcebreakerSuggestions(for conv: Conversation) {
        let user = conv.otherUser
        icebreakerSuggestions = [
            "What does your \(user.birthChart.moonSign.rawValue) moon say about your ideal Sunday?",
            "Your \(user.birthChart.risingSign.rawValue) rising is giving me serious intrigue.",
            "Venus in \(user.birthChart.venusSign.rawValue). Do you fall fast or slow?",
        ]
    }

    func focusedWithEmptyText() {
        guard messageText.isEmpty else { showIcebreakerSuggestions = false; return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let strongSelf = self, strongSelf.messageText.isEmpty else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                strongSelf.showIcebreakerSuggestions = true
            }
        }
    }

    func dismissIcebreakers() {
        withAnimation { showIcebreakerSuggestions = false }
    }

    // MARK: - Private helpers

    private func applyMessage(_ msg: Message, to conv: Conversation) {
        let updated = Conversation(
            id: conv.id, match: conv.match,
            messages: conv.messages + [msg],
            lastMessage: msg, unreadCount: 0,
            updatedAt: Date(), streakDays: conv.streakDays + 1,
            expiresAt: conv.expiresAt
        )
        activeConversation = updated
        if let idx = conversations.firstIndex(where: { $0.id == conv.id }) {
            conversations[idx] = updated
        }
    }

    private func simulateTypingReply(in conv: Conversation) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isTyping = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            self.isTyping = false
            let replies = [
                "The oscillation is palpable. My compatibility metrics are spiking.",
                "I've been monitoring the natal alignment against the current transit.",
                "Ready to synchronise data sets 🌙",
                "That's such a Scorpio thing to say and I mean that as the highest compliment.",
                "My Venus is literally doing a trine right now."
            ]
            let replyText = replies.randomElement()!
            NotificationService.shared.scheduleMessageNotification(
                senderName: conv.otherUser.displayName,
                preview: replyText
            )
            let reply = Message(
                conversationId: conv.id,
                senderId: conv.otherUser.id,
                content: replyText,
                isFromCurrentUser: false
            )
            if var active = self.activeConversation, active.id == conv.id {
                active.messages.append(reply)
                active = Conversation(
                    id: active.id, match: active.match, messages: active.messages,
                    lastMessage: reply, unreadCount: 0, updatedAt: Date(),
                    streakDays: active.streakDays, expiresAt: active.expiresAt
                )
                self.activeConversation = active
            }
        }
    }
}
