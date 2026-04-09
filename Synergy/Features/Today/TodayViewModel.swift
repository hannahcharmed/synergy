import SwiftUI
import Combine

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var horoscope: Horoscope? = nil
    @Published var ritualEvents: [RitualEvent] = []
    @Published var alignedMatches: [FeedItem] = []
    @Published var isLoading = false
    @Published var selectedRitual: RitualEvent? = nil

    init() { loadToday() }

    func loadToday() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.horoscope = MockDataService.shared.fetchTodayHoroscope()
            self.ritualEvents = MockDataService.shared.fetchRitualEvents()
            self.alignedMatches = MockDataService.shared.fetchFeed(limit: 3)
            self.isLoading = false
        }
    }

    var activeRituals: [RitualEvent] {
        ritualEvents.filter { $0.isActive }
    }

    var upcomingRituals: [RitualEvent] {
        ritualEvents.filter { !$0.isActive }
    }
}
