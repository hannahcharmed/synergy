import SwiftUI

// MARK: - Conversations List

struct ConversationsView: View {
    @EnvironmentObject var vm: ChatViewModel
    @State private var convToUnmatch: Conversation? = nil
    @State private var selectedUnmatchReason: UnmatchReason? = nil
    @State private var selectedProfile: User? = nil

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
        .sheet(item: $selectedProfile) { user in
            MatchProfileSheet(user: user)
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
                        ConversationRow(conversation: conv, onAvatarTap: {
                            selectedProfile = conv.otherUser
                        })
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
    var onAvatarTap: (() -> Void)? = nil

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
            Button { onAvatarTap?() } label: { avatarView }
                .buttonStyle(.plain)

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

// MARK: - Match Profile Sheet

struct MatchProfileSheet: View {
    let user: User
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        avatarHeader
                        bigThreeCard
                        if let bio = user.profile.bio, !bio.isEmpty { bioCard(bio) }
                        if !user.profile.vibeWords.isEmpty { vibeCard }
                        if !user.profile.intentionTags.isEmpty { intentionCard }
                        promptsSection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(user.displayName)
                        .font(SynergyFont.headlineMedium(16))
                        .foregroundColor(.cosmicNeutral)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.cosmicCyan)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var avatarHeader: some View {
        VStack(spacing: Spacing.md) {
            // Photo gallery
            photoGallery

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.displayName)
                        .font(SynergyFont.headline(22))
                        .foregroundColor(.cosmicNeutral)
                    Text("• \(user.age)")
                        .font(SynergyFont.body(18))
                        .foregroundColor(.cosmicMuted)
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.cosmicCyan)
                            .font(.system(size: 15))
                    }
                }
                Text(user.locationDisplay)
                    .font(SynergyFont.body(13))
                    .foregroundColor(.cosmicMuted)
                if let occ = user.profile.occupation {
                    Text(occ)
                        .font(SynergyFont.body(13))
                        .foregroundColor(.cosmicMuted)
                }
            }
        }
    }

    private var photoGallery: some View {
        TabView {
            ForEach(0..<max(1, user.profile.photos.count), id: \.self) { i in
                ZStack {
                    // Element-based gradient placeholder (replace with real images in production)
                    LinearGradient(
                        colors: galleryGradient(index: i),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg))

                    Text(user.displayName.prefix(1))
                        .font(SynergyFont.headline(72))
                        .foregroundColor(.white.opacity(0.18))
                }
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            }
        }
        .tabViewStyle(.page(indexDisplayMode: user.profile.photos.count > 1 ? .always : .never))
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private func galleryGradient(index: Int) -> [Color] {
        let baseColors: [[Color]] = [
            [Color(hex: "#2D1B2E"), Color(hex: "#1A1528")],   // purple deep
            [Color(hex: "#1A2838"), Color(hex: "#162040")],   // midnight blue
            [Color(hex: "#2A1A2E"), Color(hex: "#3D1B3D")],   // violet
            [Color(hex: "#1E2838"), Color(hex: "#1A3040")],   // steel
            [Color(hex: "#281A1E"), Color(hex: "#3D1B28")],   // crimson
        ]
        return baseColors[index % baseColors.count]
    }

    private var bigThreeCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("BIRTH CHART")
                .systemLabel()
                .foregroundColor(.cosmicCyan)
            HStack(spacing: Spacing.sm) {
                signPill(label: "☉ SUN", sign: user.birthChart.sunSign.rawValue)
                signPill(label: "☽ MOON", sign: user.birthChart.moonSign.rawValue)
                signPill(label: "↑ RISING", sign: user.birthChart.risingSign.rawValue)
            }
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }

    private func signPill(label: String, sign: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.cosmicMuted)
                .kerning(0.5)
            Text(sign)
                .font(SynergyFont.headlineMedium(13))
                .foregroundColor(.cosmicNeutral)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Color.cosmicDarkAlt)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    private func bioCard(_ bio: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("ABOUT")
                .systemLabel()
                .foregroundColor(.cosmicCyan)
            Text(bio)
                .font(SynergyFont.body(14))
                .foregroundColor(.cosmicNeutral)
                .lineSpacing(4)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cosmicCard()
    }

    private var vibeCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("VIBE")
                .systemLabel()
                .foregroundColor(.cosmicCyan)
            HStack(spacing: Spacing.sm) {
                ForEach(user.profile.vibeWords, id: \.self) { word in
                    Text(word)
                        .font(SynergyFont.body(13))
                        .foregroundColor(.cosmicNeutral)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 7)
                        .background(Color.cosmicPurple.opacity(0.15))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.cosmicPurple, lineWidth: 1).opacity(0.4))
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cosmicCard()
    }

    private var intentionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("LOOKING FOR")
                .systemLabel()
                .foregroundColor(.cosmicCyan)
            HStack(spacing: Spacing.sm) {
                ForEach(user.profile.intentionTags, id: \.self) { tag in
                    Text(tag.rawValue)
                        .font(SynergyFont.body(13))
                        .foregroundColor(.cosmicNeutral)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 7)
                        .background(Color.cosmicCyan.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cosmicCard()
    }

    @ViewBuilder
    private var promptsSection: some View {
        if !user.profile.prompts.isEmpty {
            VStack(spacing: Spacing.md) {
                ForEach(user.profile.prompts) { prompt in
                    promptCard(prompt)
                }
            }
        } else if let legacy = user.profile.promptAnswer, !legacy.isEmpty {
            promptCard(ProfilePrompt(
                question: PromptQuestion.wrongAboutSign.rawValue,
                answer: legacy
            ))
        }
    }

    private func promptCard(_ prompt: ProfilePrompt) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("✦  \(prompt.question.uppercased())")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.cosmicCyan)
                .kerning(0.5)
            Text(prompt.answer)
                .font(SynergyFont.body(15))
                .foregroundColor(.cosmicNeutral)
                .lineSpacing(4)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cosmicCard()
    }
}
