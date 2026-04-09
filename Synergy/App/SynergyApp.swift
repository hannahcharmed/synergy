import SwiftUI

@main
struct SynergyApp: App {
    @StateObject private var currentUser = CurrentUser()
    @StateObject private var appCoordinator = AppCoordinator()

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
