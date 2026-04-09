import SwiftUI
import Combine

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var feedItems: [FeedItem] = []
    @Published var isLoading = false
    @Published var currentIndex = 0
    @Published var lastAction: SwipeAction? = nil
    @Published var showMatchAlert = false
    @Published var latestMatch: FeedItem? = nil
    @Published var selectedItem: FeedItem? = nil  // Detail sheet

    private var swipedIds: Set<UUID> = []

    init() { loadFeed() }

    // MARK: - Feed Loading

    func loadFeed() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.feedItems = MockDataService.shared.fetchFeed(limit: 20)
            self.isLoading = false
        }
    }

    func refreshFeed() {
        feedItems = []
        swipedIds = []
        currentIndex = 0
        loadFeed()
    }

    // MARK: - Swipe Actions

    func like(_ item: FeedItem) {
        guard !swipedIds.contains(item.id) else { return }
        swipedIds.insert(item.id)
        lastAction = .like
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Simulate mutual match (30% chance per spec hasMutualLike logic)
        if Bool.random() && Bool.random() {
            latestMatch = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showMatchAlert = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        advanceDeck()
        logEvent("feed_like", item: item)
    }

    func pass(_ item: FeedItem) {
        guard !swipedIds.contains(item.id) else { return }
        swipedIds.insert(item.id)
        lastAction = .pass
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        advanceDeck()
        logEvent("feed_pass", item: item)
    }

    func superLike(_ item: FeedItem) {
        guard !swipedIds.contains(item.id) else { return }
        swipedIds.insert(item.id)
        lastAction = .superLike
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        advanceDeck()
        logEvent("feed_superlike", item: item)
    }

    private func advanceDeck() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentIndex += 1
        }
        // Prefetch more when near end
        if currentIndex >= feedItems.count - 3 {
            appendMoreItems()
        }
    }

    private func appendMoreItems() {
        let more = MockDataService.shared.fetchFeed(limit: 10)
        feedItems.append(contentsOf: more)
    }

    // MARK: - Remaining deck

    var visibleItems: [FeedItem] {
        Array(feedItems.dropFirst(currentIndex).prefix(3))
    }

    var isEmpty: Bool {
        currentIndex >= feedItems.count
    }

    // MARK: - Analytics stub

    private func logEvent(_ name: String, item: FeedItem) {
        print("[Analytics] \(name) — \(item.user.displayName) score:\(item.cosmicScore)")
    }
}
