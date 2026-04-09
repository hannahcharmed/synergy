import SwiftUI

// MARK: - Conversations List

struct ConversationsView: View {
    @EnvironmentObject var vm: ChatViewModel
    @State private var showChatView = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()

                VStack(spacing: 0) {
                    chatNavBar

                    if vm.isLoading {
                        Spacer()
                        ProgressView().tint(.cosmicCyan)
                        Spacer()
                    } else if vm.conversations.isEmpty {
                        emptyState
                    } else {
                        conversationList
                    }
                }
            }
            .navigationDestination(item: $vm.activeConversation) { conv in
                ChatView(conversation: conv)
                    .environmentObject(vm)
            }
        }
    }

    // MARK: - Nav Bar

    private var chatNavBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Messages")
                    .font(SynergyFont.headline(24))
                    .foregroundColor(.cosmicNeutral)

                if vm.totalUnread > 0 {
                    Text("\(vm.totalUnread) unread")
                        .systemLabel()
                        .foregroundColor(.cosmicCyan)
                }
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - List

    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(vm.conversations) { conv in
                    ConversationRow(conversation: conv)
                        .onTapGesture { vm.openConversation(conv) }

                    Divider()
                        .overlay(Color.cosmicBorder.opacity(0.5))
                        .padding(.leading, 80)
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.cosmicMuted.opacity(0.4))
            Text("No messages yet")
                .font(SynergyFont.headline(20))
                .foregroundColor(.cosmicNeutral)
            Text("Like someone in Discover to start a conversation")
                .font(SynergyFont.body(14))
                .foregroundColor(.cosmicMuted)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: Conversation

    private var timeString: String {
        let date = conversation.updatedAt
        let diff = Date().timeIntervalSince(date)
        if diff < 3600 { return "\(Int(diff / 60))m" }
        if diff < 86400 { return "\(Int(diff / 3600))h" }
        let f = DateFormatter(); f.dateFormat = "EEE"
        return f.string(from: date)
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Avatar
            avatarView

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUser.displayName)
                        .font(SynergyFont.headlineMedium(16))
                        .foregroundColor(.cosmicNeutral)

                    Spacer()

                    Text(timeString)
                        .systemLabel()
                        .foregroundColor(.cosmicMuted)
                }

                HStack(spacing: 6) {
                    // Cosmic score pill
                    MatchScorePill(score: conversation.match.cosmicScore, showLabel: false)

                    Text(conversation.previewText)
                        .font(SynergyFont.body(13))
                        .foregroundColor(conversation.unreadCount > 0 ? .cosmicNeutral : .cosmicMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            // Unread badge
            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cosmicDark)
                    .frame(width: 20, height: 20)
                    .background(Color.cosmicCyan)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(
            conversation.unreadCount > 0
                ? Color.cosmicCyan.opacity(0.04)
                : Color.clear
        )
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.cosmicPurple.opacity(0.4), Color.cosmicCyan.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)

            Text(conversation.otherUser.displayName.prefix(1))
                .font(SynergyFont.headline(20))
                .foregroundColor(.cosmicNeutral)

            // Online indicator
            if conversation.otherUser.isOnline {
                Circle()
                    .fill(Color.cosmicSuccess)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().strokeBorder(Color.cosmicDark, lineWidth: 2))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .frame(width: 52, height: 52)
    }
}
