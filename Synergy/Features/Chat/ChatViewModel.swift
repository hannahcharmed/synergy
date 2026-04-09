import SwiftUI
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var activeConversation: Conversation? = nil
    @Published var messageText: String = ""
    @Published var isTyping: Bool = false  // Other user is typing

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
    }

    func markRead(_ conv: Conversation) {
        guard let idx = conversations.firstIndex(where: { $0.id == conv.id }) else { return }
        conversations[idx] = Conversation(
            id: conv.id,
            match: conv.match,
            messages: conv.messages,
            lastMessage: conv.lastMessage,
            unreadCount: 0,
            updatedAt: conv.updatedAt
        )
    }

    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty,
              var conv = activeConversation else { return }

        let msg = Message(
            id: UUID(),
            conversationId: conv.id,
            senderId: MockData.currentUserId,
            content: messageText.trimmingCharacters(in: .whitespaces),
            createdAt: Date(),
            readAt: nil,
            isFromCurrentUser: true
        )

        // Optimistic UI update
        let updated = Conversation(
            id: conv.id,
            match: conv.match,
            messages: conv.messages + [msg],
            lastMessage: msg,
            unreadCount: 0,
            updatedAt: Date()
        )
        activeConversation = updated

        if let idx = conversations.firstIndex(where: { $0.id == conv.id }) {
            conversations[idx] = updated
        }

        messageText = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Simulate reply (typing indicator → response)
        simulateTypingReply(in: conv)
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
            let reply = Message(
                id: UUID(),
                conversationId: conv.id,
                senderId: conv.otherUser.id,
                content: replies.randomElement()!,
                createdAt: Date(),
                readAt: nil,
                isFromCurrentUser: false
            )
            if var active = self.activeConversation, active.id == conv.id {
                self.activeConversation = Conversation(
                    id: active.id,
                    match: active.match,
                    messages: active.messages + [reply],
                    lastMessage: reply,
                    unreadCount: 0,
                    updatedAt: Date()
                )
            }
        }
    }
}
