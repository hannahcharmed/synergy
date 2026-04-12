import SwiftUI

// MARK: - Conversations List

struct ConversationsView: View {
    @EnvironmentObject var vm: ChatViewModel
    @State private var convToUnmatch: Conversation? = nil
    @State private var selectedUnmatchReason: UnmatchReason? = nil

    var body: some View {
        NavigationView {
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
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(item: $convToUnmatch) { conv in
            unmatchSheet(for: conv)
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
                    NavigationLink(destination:
                        ChatView(conversation: conv)
                            .environmentObject(vm)
                    ) {
                        ConversationRow(conversation: conv)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded { vm.openConversation(conv) })
                    .contextMenu {
                        Button(role: .destructive) {
                            convToUnmatch = conv
                        } label: {
                            Label("Unmatch", systemImage: "heart.slash")
                        }
                        Button(role: .destructive) {
                            vm.blockUser(conv.otherUser.id, in: conv)
                        } label: {
                            Label("Block", systemImage: "hand.raised")
                        }
                    }

                    Divider()
                        .overlay(Color.cosmicBorder.opacity(0.5))
                        .padding(.leading, 80)
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Unmatch Sheet

    private func unmatchSheet(for conv: Conversation) -> some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    Text("Why are you unmatching \(conv.otherUser.displayName)?")
                        .font(SynergyFont.headlineMedium(18))
                        .foregroundColor(.cosmicNeutral)
                        .padding(.top, Spacing.md)

                    VStack(spacing: Spacing.sm) {
                        ForEach(UnmatchReason.allCases) { reason in
                            Button { selectedUnmatchReason = reason } label: {
                                HStack {
                                    Text(reason.rawValue)
                                        .font(SynergyFont.body(15))
                                        .foregroundColor(.cosmicNeutral)
                                    Spacer()
                                    if selectedUnmatchReason == reason {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.cosmicCyan)
                                    }
                                }
                                .padding(Spacing.lg)
                                .cosmicCard()
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.card)
                                        .strokeBorder(
                                            selectedUnmatchReason == reason
                                                ? Color.cosmicCyan.opacity(0.5) : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()

                    CosmicButton("Confirm unmatch", variant: .outlined) {
                        vm.unmatch(conv, reason: selectedUnmatchReason)
                        convToUnmatch = nil
                        selectedUnmatchReason = nil
                    }

                    Text("They won't be notified of the specific reason.")
                        .font(SynergyFont.body(12))
                        .foregroundColor(.cosmicMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(Spacing.xl)
            }
            .navigationTitle("Unmatch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        convToUnmatch = nil
                        selectedUnmatchReason = nil
                    }
                    .foregroundColor(.cosmicCyan)
                }
            }
        }
        .navigationViewStyle(.stack)
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
            avatarView

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUser.displayName)
                        .font(SynergyFont.headlineMedium(16))
                        .foregroundColor(.cosmicNeutral)

                    // Streak badge
                    if conversation.streakDays >= 3 {
                        HStack(spacing: 2) {
                            Text("✦")
                                .font(.system(size: 9))
                            Text("\(conversation.streakDays)d")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.cosmicCyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cosmicCyan.opacity(0.12))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    // Expiry countdown (if < 24h)
                    if let hours = conversation.hoursUntilExpiry, hours < 24 {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text("\(hours)h")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        }
                        .foregroundColor(.cosmicError)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cosmicError.opacity(0.1))
                        .clipShape(Capsule())
                    } else {
                        Text(timeString)
                            .systemLabel()
                            .foregroundColor(.cosmicMuted)
                    }
                }

                HStack(spacing: 6) {
                    MatchScorePill(score: conversation.match.cosmicScore, showLabel: false)

                    Text(conversation.previewText)
                        .font(SynergyFont.body(13))
                        .foregroundColor(conversation.unreadCount > 0 ? .cosmicNeutral : .cosmicMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

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
