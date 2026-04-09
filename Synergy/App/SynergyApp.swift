import SwiftUI

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  iOS 15 COMPATIBILITY NOTE — revert when Xcode is updated              │
// │                                                                         │
// │  This file contains UIAppearance workarounds required because the       │
// │  current build targets iOS 15.5 (Xcode 13 SDK).                        │
// │                                                                         │
// │  When Xcode is updated to Xcode 14+ and deployment target is            │
// │  raised to iOS 16.0:                                                    │
// │                                                                         │
// │  1. Delete the entire init() block below                                │
// │  2. In ChatView, FeedView (SynastryDetailSheet), TodayView              │
// │     (RitualDetailSheet) — restore:                                      │
// │       .toolbarBackground(Color.cosmicDarkAlt, for: .navigationBar)     │
// │       .toolbarColorScheme(.dark, for: .navigationBar)                   │
// │  3. Replace all NavigationView + .navigationViewStyle(.stack) with      │
// │     NavigationStack                                                     │
// │  4. In ConversationsView restore:                                       │
// │       .navigationDestination(item: $vm.activeConversation) { conv in   │
// │           ChatView(conversation: conv).environmentObject(vm)            │
// │       }                                                                 │
// │  5. In ProfileSetupView restore PhotosPicker / PhotosPickerItem and     │
// │     .scrollContentBackground(.hidden) on TextEditor                     │
// │  6. Remove UITextView.appearance().backgroundColor = .clear from init() │
// └─────────────────────────────────────────────────────────────────────────┘

@main
struct SynergyApp: App {
    @StateObject private var currentUser = CurrentUser()
    @StateObject private var appCoordinator = AppCoordinator()

    init() {
        // Global nav bar appearance — dark cosmic style
        // (iOS 16 equivalent: .toolbarBackground + .toolbarColorScheme per-view)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.cosmicDarkAlt)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Color.cosmicNeutral)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.cosmicNeutral)]
        UINavigationBar.appearance().standardAppearance  = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance   = appearance
        UINavigationBar.appearance().tintColor = UIColor(Color.cosmicCyan)

        // Transparent TextEditor background
        // (iOS 16 equivalent: .scrollContentBackground(.hidden) per TextEditor)
        UITextView.appearance().backgroundColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(currentUser)
                .environmentObject(appCoordinator)
                .preferredColorScheme(.dark)
                .tint(.cosmicCyan)
        }
    }
}
