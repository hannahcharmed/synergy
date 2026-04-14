import SwiftUI

// MARK: - Main Tab View
// 4 tabs: Feed · Today · Chat · Profile

struct MainTabView: View {
    @State private var selectedTab: Tab = .feed
    @StateObject private var feedVM   = FeedViewModel()
    @StateObject private var todayVM  = TodayViewModel()
    @StateObject private var chatVM   = ChatViewModel()
    @StateObject private var profileVM = ProfileViewModel()

    enum Tab: Int, CaseIterable {
        case feed = 0, today, chat, profile

        var title: String {
            switch self {
            case .feed:    return "Discover"
            case .today:   return "Today"
            case .chat:    return "Messages"
            case .profile: return "Profile"
            }
        }

        var icon: String {
            switch self {
            case .feed:    return "sparkles.rectangle.stack"
            case .today:   return "moon.stars.fill"
            case .chat:    return "bubble.left.and.bubble.right.fill"
            case .profile: return "person.circle.fill"
            }
        }

        var selectedIcon: String {
            switch self {
            case .feed:    return "sparkles.rectangle.stack.fill"
            case .today:   return "moon.stars.fill"
            case .chat:    return "bubble.left.and.bubble.right.fill"
            case .profile: return "person.circle.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .environmentObject(feedVM)
                .tag(Tab.feed)

            TodayView()
                .environmentObject(todayVM)
                .tag(Tab.today)

            ConversationsView()
                .environmentObject(chatVM)
                .tag(Tab.chat)

            ProfileView()
                .environmentObject(profileVM)
                .tag(Tab.profile)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        // Tab bar as a proper safeAreaInset so every page's bottom safe area
        // includes the tab bar height — this is what lets ChatView's inputBar
        // sit above the tab bar (not behind it).
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CosmicTabBar(selectedTab: $selectedTab, chatUnreadCount: chatVM.totalUnread)
        }
        .background(Color.cosmicDark)
        // Icebreaker handoff: switch to chat tab and pre-fill message
        .onChange(of: feedVM.pendingIcebreakerText) { text in
            guard let text = text else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = .chat
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                chatVM.messageText = text
                feedVM.pendingIcebreakerText = nil
            }
        }
    }
}

// MARK: - Custom Tab Bar

struct CosmicTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    var chatUnreadCount: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(
            ZStack {
                // Extend background under the home indicator
                Color.cosmicDarkAlt
                    .ignoresSafeArea(edges: .bottom)
                // Top border glow
                VStack {
                    LinearGradient(
                        colors: [Color.cosmicCyan.opacity(0.3), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                    Spacer()
                }
            }
        )
    }

    @ViewBuilder
    private func tabButton(_ tab: MainTabView.Tab) -> some View {
        let isSelected = selectedTab == tab

        Button {
            if selectedTab != tab {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Active pill background
                    if isSelected {
                        Capsule()
                            .fill(LinearGradient.cosmicGradient)
                            .opacity(0.2)
                            .frame(width: 48, height: 28)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .cosmicCyan : .cosmicMuted)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .frame(height: 28)

                Text(tab.title)
                    .font(SynergyFont.body(10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .cosmicCyan : .cosmicMuted)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                // Unread badge for Chat tab
                if tab == .chat && chatUnreadCount > 0 {
                    Text("\(min(chatUnreadCount, 9))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.cosmicDark)
                        .frame(width: 16, height: 16)
                        .background(Color.cosmicCyan)
                        .clipShape(Circle())
                        .offset(x: 8, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }
}
