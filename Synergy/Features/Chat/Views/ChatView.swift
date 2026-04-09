import SwiftUI

// MARK: - Chat Message Thread
// ASTRO_OS aesthetic: "TRANSMISSION_SECURE" label, cosmic chat bubbles.

struct ChatView: View {
    let conversation: Conversation
    @EnvironmentObject var vm: ChatViewModel
    @FocusState private var inputFocused: Bool
    @State private var scrollProxy: ScrollViewProxy? = nil

    private var messages: [Message] {
        vm.activeConversation?.messages ?? conversation.messages
    }

    var body: some View {
        ZStack {
            Color.cosmicDark.ignoresSafeArea()

            VStack(spacing: 0) {
                // Status bar (ASTRO_OS)
                statusBar

                // Messages
                messageList

                // Input bar
                inputBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { navBarContent }
        .toolbarBackground(Color.cosmicDarkAlt, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .ignoresSafeArea(edges: .bottom)
        .onAppear { vm.openConversation(conversation) }
    }

    // MARK: - Status Bar (ASTRO_OS system aesthetic)

    private var statusBar: some View {
        HStack(spacing: Spacing.md) {
            // System header
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.cosmicSuccess)
                Text("TRANSMISSION_SECURE")
                    .systemLabel()
                    .foregroundColor(.cosmicSuccess.opacity(0.8))
            }

            Spacer()

            // Match score
            MatchScorePill(score: conversation.match.cosmicScore)

            // Synastry button
            Button {
                // Show synastry sheet
            } label: {
                Text("SYNASTRY")
                    .systemLabel()
                    .foregroundColor(.cosmicCyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cosmicCyan.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.cosmicCyan.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.sm)
        .background(Color.cosmicDarkAlt)
        .overlay(alignment: .bottom) {
            Divider().overlay(Color.cosmicBorder)
        }
    }

    // MARK: - Nav Bar

    @ToolbarContentBuilder
    private var navBarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: Spacing.sm) {
                // Mini avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient.cosmicGradient)
                        .frame(width: 32, height: 32)
                    Text(conversation.otherUser.displayName.prefix(1))
                        .font(SynergyFont.headlineMedium(14))
                        .foregroundColor(.cosmicDark)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(conversation.otherUser.displayName)
                        .font(SynergyFont.headlineMedium(15))
                        .foregroundColor(.cosmicNeutral)
                    Text(conversation.otherUser.birthChart.sunSign.rawValue + " \(conversation.otherUser.birthChart.sunSign.symbol)")
                        .systemLabel()
                        .foregroundColor(.cosmicMuted)
                }
            }
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Date header
                    Text("TODAY")
                        .systemLabel()
                        .foregroundColor(.cosmicMuted)
                        .padding(.vertical, Spacing.lg)

                    ForEach(messages) { message in
                        MessageBubble(message: message, otherUser: conversation.otherUser)
                            .id(message.id)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, 3)
                    }

                    // Typing indicator
                    if vm.isTyping {
                        TypingIndicator(user: conversation.otherUser)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, 3)
                            .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottomLeading)))
                    }

                    // Spacer for input bar
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
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: vm.isTyping) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.cosmicBorder)

            HStack(spacing: Spacing.md) {
                // Mic / attachment
                Button {
                    // Voice / attachment
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.cosmicMuted)
                        .frame(width: 36, height: 36)
                }

                // Text field
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
                }
                .padding(.horizontal, Spacing.md)
                .frame(height: 44)
                .background(Color.cosmicDarkAlt)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.cosmicBorder, lineWidth: 1))

                // Send
                Button {
                    vm.sendMessage()
                } label: {
                    ZStack {
                        Circle()
                            .fill(vm.messageText.isEmpty
                                  ? Color.cosmicCard
                                  : LinearGradient.cosmicGradient)
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
            .padding(.bottom, 24) // safe area
            .background(Color.cosmicDark)
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message
    let otherUser: User

    private var timeString: String {
        let f = DateFormatter(); f.timeStyle = .short
        return f.string(from: message.createdAt)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            if message.isFromCurrentUser { Spacer(minLength: 60) }

            if !message.isFromCurrentUser {
                // Mini avatar for other user
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
                // Bubble
                Text(message.content)
                    .font(SynergyFont.body(15))
                    .foregroundColor(.cosmicNeutral)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, 10)
                    .background(
                        message.isFromCurrentUser
                            ? LinearGradient.cosmicGradient.opacity(0.85)
                            : Color(hex: "#1E2229") as? LinearGradient ?? LinearGradient(colors: [Color(hex: "#1E2229")], startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(ChatBubbleShape(isFromCurrentUser: message.isFromCurrentUser))

                // Timestamp + read receipt
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
    }
}

// MARK: - Incoming bubble background fix

extension MessageBubble {
    // Override background for incoming bubbles (can't use conditional gradient)
    private var incomingBg: Color { Color(hex: "#1E2229") }
}

// MARK: - Custom Bubble Shape

struct ChatBubbleShape: Shape {
    let isFromCurrentUser: Bool
    let cornerRadius: CGFloat = 18
    let tailRadius: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = cornerRadius
        let t = tailRadius

        if isFromCurrentUser {
            // Round all corners, small tail bottom-right
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
            // Tail bottom-left
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
