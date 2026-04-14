import SwiftUI

// MARK: - Chat Message Thread
// ASTRO_OS aesthetic: cosmic chat bubbles, reactions, voice notes, icebreaker suggestions.

struct ChatView: View {
    let conversation: Conversation
    @EnvironmentObject var vm: ChatViewModel
    @FocusState private var inputFocused: Bool
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var showSynastry = false
    @State private var showUnmatchSheet = false
    @State private var showReportSheet = false
    @State private var selectedUnmatchReason: UnmatchReason? = nil
    @State private var selectedReportReason: ReportReason? = nil
    @State private var isRecordingVoice = false
    @State private var showingMatchProfile = false

    private var messages: [Message] {
        vm.activeConversation?.messages ?? conversation.messages
    }

    private var synastryItem: FeedItem {
        FeedItem(
            id: conversation.match.id,
            user: conversation.otherUser,
            cosmicScore: conversation.match.cosmicScore,
            highlights: conversation.match.scoreHighlights,
            aiIcebreaker: conversation.match.aiIcebreaker ?? "Ask them about their moon sign.",
            transitBoost: nil
        )
    }

    var body: some View {
        ZStack {
            Color.cosmicDark.ignoresSafeArea()

            VStack(spacing: 0) {
                statusBar
                messageList
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if isRecordingVoice {
                    VoiceNoteRecorderView(isRecording: $isRecordingVoice) { duration in
                        vm.sendVoiceNote(duration: duration)
                    }
                } else {
                    icebreakerBar
                    inputBar
                }
            }
            .background(Color.cosmicDark)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { navBarContent }
        .onAppear { vm.openConversation(conversation) }
        .sheet(isPresented: $showSynastry) { SynastryDetailSheet(item: synastryItem) }
        .sheet(isPresented: $showUnmatchSheet) { unmatchSheet }
        .sheet(isPresented: $showReportSheet) { reportSheet }
        .sheet(isPresented: $showingMatchProfile) {
            MatchProfileSheet(user: conversation.otherUser)
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.cosmicSuccess)
                Text("TRANSMISSION_SECURE")
                    .systemLabel()
                    .foregroundColor(.cosmicSuccess.opacity(0.8))
            }
            Spacer()
            MatchScorePill(score: conversation.match.cosmicScore)
            Button { showSynastry = true } label: {
                Text("SYNASTRY")
                    .systemLabel()
                    .foregroundColor(.cosmicCyan)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.cosmicCyan.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.cosmicCyan, lineWidth: 1).opacity(0.3))
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.sm)
        .background(Color.cosmicDarkAlt)
        .overlay(alignment: .bottom) { Divider().overlay(Color.cosmicBorder) }
    }

    // MARK: - Nav Bar

    @ToolbarContentBuilder
    private var navBarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Button { showingMatchProfile = true } label: {
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle().fill(LinearGradient.cosmicGradient).frame(width: 32, height: 32)
                        Text(conversation.otherUser.displayName.prefix(1))
                            .font(SynergyFont.headlineMedium(14))
                            .foregroundColor(.cosmicDark)
                        if conversation.otherUser.isOnline {
                            Circle()
                                .fill(Color.cosmicSuccess)
                                .frame(width: 9, height: 9)
                                .overlay(Circle().strokeBorder(Color.cosmicDarkAlt, lineWidth: 1.5))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        }
                    }
                    .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(conversation.otherUser.displayName)
                            .font(SynergyFont.headlineMedium(15))
                            .foregroundColor(.cosmicNeutral)
                        Text(conversation.otherUser.isOnline ? "Online now" :
                             conversation.otherUser.birthChart.sunSign.rawValue
                             + " \(conversation.otherUser.birthChart.sunSign.symbol)")
                            .systemLabel()
                            .foregroundColor(conversation.otherUser.isOnline ? .cosmicSuccess : .cosmicMuted)
                    }
                }
            }
            .buttonStyle(.plain)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button(role: .destructive) { showUnmatchSheet = true } label: {
                    Label("Unmatch", systemImage: "heart.slash")
                }
                Button(role: .destructive) { showReportSheet = true } label: {
                    Label("Report", systemImage: "flag")
                }
                Button(role: .destructive) {
                    vm.blockUser(conversation.otherUser.id, in: conversation)
                } label: {
                    Label("Block", systemImage: "hand.raised")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.cosmicMuted)
            }
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    Text("TODAY")
                        .systemLabel()
                        .foregroundColor(.cosmicMuted)
                        .padding(.vertical, Spacing.lg)

                    ForEach(messages) { message in
                        MessageBubble(
                            message: message,
                            otherUser: conversation.otherUser,
                            onReact: { emoji in vm.addReaction(emoji, to: message) }
                        )
                        .id(message.id)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, 3)
                    }

                    if vm.isTyping {
                        TypingIndicator(user: conversation.otherUser)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, 3)
                            .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottomLeading)))
                    }

                    Color.clear.frame(height: 100).id("bottom")
                }
                .padding(.bottom, Spacing.sm)
            }
            .onAppear {
                scrollProxy = proxy
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: messages.count) { _ in
                withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: vm.isTyping) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    // MARK: - Icebreaker Bar

    @ViewBuilder
    private var icebreakerBar: some View {
        if vm.showIcebreakerSuggestions && !vm.icebreakerSuggestions.isEmpty {
            VStack(spacing: 0) {
                Divider().overlay(Color.cosmicBorder)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        Text("✦")
                            .font(.system(size: 11))
                            .foregroundColor(.cosmicCyan.opacity(0.7))
                            .padding(.leading, Spacing.xl)
                        ForEach(vm.icebreakerSuggestions, id: \.self) { suggestion in
                            Button {
                                vm.messageText = suggestion
                                vm.dismissIcebreakers()
                            } label: {
                                Text(suggestion)
                                    .font(SynergyFont.body(12))
                                    .foregroundColor(.cosmicNeutral)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, 8)
                                    .background(Color.cosmicCyan.opacity(0.08))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().strokeBorder(Color.cosmicCyan, lineWidth: 1).opacity(0.25))
                            }
                        }
                        Button { vm.dismissIcebreakers() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                                .foregroundColor(.cosmicMuted)
                                .padding(.trailing, Spacing.xl)
                        }
                    }
                    .padding(.vertical, Spacing.sm)
                }
                .background(Color.cosmicDarkAlt)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.cosmicBorder)
            HStack(spacing: Spacing.md) {
                Button {
                    isRecordingVoice = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.cosmicMuted)
                        .frame(width: 36, height: 36)
                }

                HStack {
                    TextField("", text: $vm.messageText,
                              prompt: Text("SYNAPSE_INPUT")
                                  .font(.system(size: 12, weight: .medium, design: .monospaced))
                                  .foregroundColor(.cosmicMuted.opacity(0.5))
                    )
                    .font(SynergyFont.body(15))
                    .foregroundColor(.cosmicNeutral)
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit { vm.sendMessage() }
                    .onChange(of: inputFocused) { focused in
                        if focused { vm.focusedWithEmptyText() }
                    }
                    .onChange(of: vm.messageText) { text in
                        if !text.isEmpty { vm.dismissIcebreakers() }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .frame(height: 44)
                .background(Color.cosmicDarkAlt)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.cosmicBorder, lineWidth: 1))

                Button { vm.sendMessage() } label: {
                    ZStack {
                        Circle()
                            .fill(vm.messageText.isEmpty
                                  ? AnyShapeStyle(Color.cosmicCard)
                                  : AnyShapeStyle(LinearGradient.cosmicGradient))
                            .frame(width: 40, height: 40)
                        Text("EXECUTE")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(vm.messageText.isEmpty ? .cosmicMuted : .cosmicNeutral)
                            .kerning(1)
                    }
                }
                .disabled(vm.messageText.isEmpty)
                .animation(.easeInOut(duration: 0.2), value: vm.messageText.isEmpty)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
            .background(Color.cosmicDark)
        }
    }

    // MARK: - Unmatch Sheet

    private var unmatchSheet: some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    Text("Why are you unmatching?")
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
                        showUnmatchSheet = false
                        vm.unmatch(conversation, reason: selectedUnmatchReason)
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
                    Button("Cancel") { showUnmatchSheet = false }.foregroundColor(.cosmicCyan)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Report Sheet

    private var reportSheet: some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    Text("What's the issue?")
                        .font(SynergyFont.headlineMedium(18))
                        .foregroundColor(.cosmicNeutral)
                        .padding(.top, Spacing.md)

                    VStack(spacing: Spacing.sm) {
                        ForEach(ReportReason.allCases) { reason in
                            Button { selectedReportReason = reason } label: {
                                HStack {
                                    Text(reason.rawValue)
                                        .font(SynergyFont.body(15))
                                        .foregroundColor(.cosmicNeutral)
                                    Spacer()
                                    if selectedReportReason == reason {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.cosmicError)
                                    }
                                }
                                .padding(Spacing.lg)
                                .cosmicCard()
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.card)
                                        .strokeBorder(
                                            selectedReportReason == reason
                                                ? Color.cosmicError.opacity(0.5) : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()

                    CosmicButton("Submit report", variant: .outlined) {
                        showReportSheet = false
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }

                    Text("We review all reports within 24 hours.")
                        .font(SynergyFont.body(12))
                        .foregroundColor(.cosmicMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(Spacing.xl)
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showReportSheet = false }.foregroundColor(.cosmicCyan)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message
    let otherUser: User
    var onReact: ((String) -> Void)? = nil

    @State private var showReactionPicker = false

    private var timeString: String {
        let f = DateFormatter(); f.timeStyle = .short
        return f.string(from: message.createdAt)
    }

    private let cosmicEmojis = ["✦", "☽", "♥", "⚡", "✨"]

    var body: some View {
        VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 2) {
            HStack(alignment: .bottom, spacing: Spacing.sm) {
                if message.isFromCurrentUser { Spacer(minLength: 60) }

                if !message.isFromCurrentUser {
                    Circle()
                        .fill(LinearGradient.cosmicGradient)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(otherUser.displayName.prefix(1))
                                .font(SynergyFont.body(11, weight: .semibold))
                                .foregroundColor(.cosmicDark)
                        )
                }

                VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                    bubbleContent
                        .onLongPressGesture {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.3)) { showReactionPicker.toggle() }
                        }

                    HStack(spacing: 4) {
                        Text(timeString)
                            .systemLabel()
                            .foregroundColor(.cosmicMuted.opacity(0.6))
                        if message.isFromCurrentUser {
                            Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.system(size: 9))
                                .foregroundColor(message.isRead ? .cosmicCyan : .cosmicMuted)
                        }
                    }
                }

                if !message.isFromCurrentUser { Spacer(minLength: 60) }
            }

            // Existing reactions row
            if !message.reactions.isEmpty {
                reactionRow
                    .padding(.leading, message.isFromCurrentUser ? 0 : 40)
            }

            // Reaction picker
            if showReactionPicker {
                reactionPicker
                    .transition(.scale(scale: 0.7,
                        anchor: message.isFromCurrentUser ? .bottomTrailing : .bottomLeading)
                        .combined(with: .opacity))
                    .padding(.leading, message.isFromCurrentUser ? 0 : 40)
            }
        }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        if message.isVoiceNote {
            VoiceNotePlayerView(
                duration: message.voiceDuration ?? 5,
                isFromCurrentUser: message.isFromCurrentUser
            )
            .frame(maxWidth: 220)
        } else {
            Text(message.content)
                .font(SynergyFont.body(15))
                .foregroundColor(.cosmicNeutral)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 10)
                .background {
                    if message.isFromCurrentUser {
                        LinearGradient.cosmicGradient.opacity(0.85)
                    } else {
                        Color.adaptive(dark: "#1E2229", light: "#E6DEFF")
                    }
                }
                .clipShape(ChatBubbleShape(isFromCurrentUser: message.isFromCurrentUser))
        }
    }

    private var reactionRow: some View {
        HStack(spacing: 4) {
            ForEach(message.reactions.sorted(by: { $0.key < $1.key }), id: \.key) { emoji, count in
                Button { onReact?(emoji) } label: {
                    HStack(spacing: 3) {
                        Text(emoji).font(.system(size: 13))
                        if count > 1 {
                            Text("\(count)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.cosmicMuted)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cosmicDarkAlt)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.cosmicBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 2)
    }

    private var reactionPicker: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(cosmicEmojis, id: \.self) { emoji in
                Button {
                    onReact?(emoji)
                    withAnimation { showReactionPicker = false }
                } label: {
                    Text(emoji)
                        .font(.system(size: 20))
                        .frame(width: 36, height: 36)
                        .background(Color.cosmicCard)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color.cosmicBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.sm)
        .background(Color.cosmicDarkAlt)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.cosmicBorder, lineWidth: 1))
        .cardShadow()
    }
}

// MARK: - Custom Bubble Shape

struct ChatBubbleShape: Shape {
    let isFromCurrentUser: Bool
    let cornerRadius: CGFloat = 18
    let tailRadius: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = cornerRadius; let t = tailRadius
        if isFromCurrentUser {
            path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - t * 2))
            path.addArc(center: CGPoint(x: rect.maxX + t, y: rect.maxY - t), radius: t, startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + t * 2, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX - t, y: rect.maxY - t), radius: t, startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    let user: User
    @State private var phase: Double = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            Circle()
                .fill(LinearGradient.cosmicGradient)
                .frame(width: 28, height: 28)
                .overlay(
                    Text(user.displayName.prefix(1))
                        .font(SynergyFont.body(11, weight: .semibold))
                        .foregroundColor(.cosmicDark)
                )

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.cosmicMuted)
                        .frame(width: 7, height: 7)
                        .scaleEffect(1 + 0.4 * sin(phase + Double(i) * 0.8))
                        .opacity(0.6 + 0.4 * sin(phase + Double(i) * 0.8))
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 12)
            .background(Color(hex: "#1E2229"))
            .clipShape(Capsule())
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = .pi * 2
                }
            }

            Spacer(minLength: 60)
        }
    }
}

// MARK: - Voice Note Player

struct VoiceNotePlayerView: View {
    let duration: Double
    let isFromCurrentUser: Bool

    @State private var isPlaying = false
    @State private var playProgress: Double = 0
    @State private var timer: Timer? = nil

    private var accentColor: Color { isFromCurrentUser ? .cosmicNeutral : .cosmicCyan }
    private var bgColor: Color {
        isFromCurrentUser ? Color.white.opacity(0.15) : Color.adaptive(dark: "#1E2229", light: "#E6DEFF")
    }
    private var timeLabel: String {
        let remaining = duration * (1 - playProgress)
        return String(format: "%d:%02d", Int(remaining) / 60, Int(remaining) % 60)
    }
    private var barHeights: [CGFloat] {
        (0..<20).map { i in CGFloat(abs(sin(Double(i) * 1.4 + duration)) * 0.7 + 0.15) }
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Button { togglePlayback() } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14))
                    .foregroundColor(accentColor)
                    .frame(width: 30, height: 30)
                    .background(accentColor.opacity(0.2))
                    .clipShape(Circle())
            }
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(0..<barHeights.count, id: \.self) { i in
                        let played = Double(i) / Double(barHeights.count) <= playProgress
                        Capsule()
                            .fill(accentColor)
                            .opacity(played ? 1.0 : 0.3)
                            .frame(width: 3, height: geo.size.height * barHeights[i])
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 28)
            Text(timeLabel)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(accentColor.opacity(0.8))
                .frame(width: 32)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 10)
        .background(bgColor)
        .clipShape(Capsule())
        .onDisappear { stopPlayback() }
    }

    private func togglePlayback() { isPlaying ? stopPlayback() : startPlayback() }

    private func startPlayback() {
        isPlaying = true
        if playProgress >= 1 { playProgress = 0 }
        let step = 0.05 / duration
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                if self.playProgress < 1 {
                    withAnimation(.linear(duration: 0.05)) { self.playProgress += step }
                } else { self.stopPlayback() }
            }
        }
    }

    private func stopPlayback() {
        isPlaying = false
        timer?.invalidate(); timer = nil
    }
}

// MARK: - Voice Note Recorder

struct VoiceNoteRecorderView: View {
    @Binding var isRecording: Bool
    var onSend: (Double) -> Void

    @State private var phase: Double = 0
    @State private var elapsed: Double = 0
    @State private var timer: Timer? = nil

    private var timeLabel: String {
        String(format: "%d:%02d", Int(elapsed) / 60, Int(elapsed) % 60)
    }

    var body: some View {
        HStack(spacing: Spacing.lg) {
            Button { stop(); isRecording = false } label: {
                Image(systemName: "xmark").font(.system(size: 16)).foregroundColor(.cosmicError)
            }
            HStack(spacing: 3) {
                ForEach(0..<12, id: \.self) { i in
                    Capsule()
                        .fill(Color.cosmicError)
                        .frame(width: 3, height: 6 + 16 * CGFloat(abs(sin(phase + Double(i) * 0.6))))
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) { phase = .pi * 2 }
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    Task { @MainActor in self.elapsed += 0.1 }
                }
            }
            Text(timeLabel)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.cosmicNeutral)
                .monospacedDigit()
            Spacer()
            Button {
                let dur = max(1, elapsed); stop(); isRecording = false; onSend(dur)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(LinearGradient.cosmicGradient)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(Color.cosmicDarkAlt)
    }

    private func stop() { timer?.invalidate(); timer = nil }
}
