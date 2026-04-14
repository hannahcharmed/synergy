import SwiftUI
import Combine

// MARK: - Transit Alert

struct TransitAlert: Identifiable {
    let id = UUID()
    let planet: String
    let description: String
    let affectedSign: String
    let boostPercent: Int           // +N% on cosmic scores
    let expiresAt: Date
    var isExpired: Bool { Date() > expiresAt }
}

// MARK: - Upcoming Transit Card

struct UpcomingTransit: Identifiable {
    let id = UUID()
    let planet: String
    let planetSymbol: String
    let action: String       // e.g. "enters", "trines your natal", "goes retrograde"
    let target: String       // e.g. "your 7th House", "Venus", ""
    let daysUntil: Int       // 0 = today
    let impactDescription: String
    let colorHex: String
    var isToday: Bool { daysUntil == 0 }
    var isImminent: Bool { daysUntil <= 2 }
}

// MARK: - Weekly Synastry Report Entry

struct WeeklyReportEntry: Identifiable {
    let id = UUID()
    let matchName: String
    let cosmicScore: Int
    let weeklyInsight: String
    let bestDay: String
    let transitNote: String
}

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var horoscope: Horoscope? = nil
    @Published var ritualEvents: [RitualEvent] = []
    @Published var alignedMatches: [FeedItem] = []
    @Published var isLoading = false
    @Published var selectedRitual: RitualEvent? = nil

    // Transit alert banner (dismissible)
    @Published var activeTransitAlert: TransitAlert? = nil
    @Published var showTransitAlert = true

    // Mercury retrograde
    @Published var isMercuryRetrograde = false

    // Weekly synastry report (shown on Mon/mock always)
    @Published var weeklyReport: [WeeklyReportEntry] = []
    @Published var showWeeklyReport = false

    // Upcoming transit predictions
    @Published var upcomingTransits: [UpcomingTransit] = []

    // Cosmic streak (days opened in a row — persisted via UserDefaults)
    @Published var streakDays: Int = 0

    init() {
        loadStreak()
        loadToday()
    }

    func loadToday() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.horoscope = MockDataService.shared.fetchTodayHoroscope()
            self.ritualEvents = MockDataService.shared.fetchRitualEvents()
            self.alignedMatches = MockDataService.shared.fetchFeed(limit: 3)
            self.isMercuryRetrograde = self.checkMercuryRetrograde()
            self.activeTransitAlert = self.buildTransitAlert()
            self.weeklyReport = self.buildWeeklyReport()
            self.upcomingTransits = self.buildUpcomingTransits()
            self.isLoading = false
        }
    }

    func refresh() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        horoscope = MockDataService.shared.fetchTodayHoroscope()
        ritualEvents = MockDataService.shared.fetchRitualEvents()
        alignedMatches = MockDataService.shared.fetchFeed(limit: 3)
        activeTransitAlert = buildTransitAlert()
        isLoading = false
    }

    func dismissTransitAlert() {
        withAnimation { showTransitAlert = false }
    }

    var activeRituals: [RitualEvent] { ritualEvents.filter { $0.isActive } }
    var upcomingRituals: [RitualEvent] { ritualEvents.filter { !$0.isActive } }

    // MARK: - Streak

    private func loadStreak() {
        let key = "lastOpenedDate"
        let today = Calendar.current.startOfDay(for: Date())
        if let stored = UserDefaults.standard.object(forKey: key) as? Date {
            let lastDay = Calendar.current.startOfDay(for: stored)
            let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 0 {
                streakDays = UserDefaults.standard.integer(forKey: "streakDays")
            } else if diff == 1 {
                streakDays = UserDefaults.standard.integer(forKey: "streakDays") + 1
                UserDefaults.standard.set(streakDays, forKey: "streakDays")
            } else {
                streakDays = 1
                UserDefaults.standard.set(1, forKey: "streakDays")
            }
        } else {
            streakDays = 1
            UserDefaults.standard.set(1, forKey: "streakDays")
        }
        UserDefaults.standard.set(Date(), forKey: key)
    }

    // MARK: - Mercury Retrograde (mock: check active rituals for retrograde type)

    private func checkMercuryRetrograde() -> Bool {
        ritualEvents.contains { $0.type == .retrograde && $0.isActive }
    }

    // MARK: - Transit Alert (mock)

    private func buildTransitAlert() -> TransitAlert? {
        guard let h = horoscope else { return nil }
        return TransitAlert(
            planet: "Venus",
            description: h.cosmicWeather.dominantTransit,
            affectedSign: "Scorpio",
            boostPercent: 15,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date()
        )
    }

    // MARK: - Upcoming Transits (mock predictions)

    private func buildUpcomingTransits() -> [UpcomingTransit] {
        [
            UpcomingTransit(
                planet: "Venus", planetSymbol: "♀",
                action: "enters", target: "your 7th House",
                daysUntil: 0,
                impactDescription: "Romantic magnetism peaks. Open invitations, direct confessions. This window lasts 18 days.",
                colorHex: "#FF6B9D"
            ),
            UpcomingTransit(
                planet: "Jupiter", planetSymbol: "♃",
                action: "trines your natal", target: "Venus",
                daysUntil: 3,
                impactDescription: "Expansion in love. New connections made now carry long-term potential.",
                colorHex: "#FFD700"
            ),
            UpcomingTransit(
                planet: "Full Moon", planetSymbol: "○",
                action: "in your", target: "5th House",
                daysUntil: 5,
                impactDescription: "Creative expression and playfulness amplified. Ideal for first dates and bold moves.",
                colorHex: "#C0C0C0"
            ),
            UpcomingTransit(
                planet: "Mercury", planetSymbol: "☿",
                action: "goes retrograde in", target: "Gemini",
                daysUntil: 11,
                impactDescription: "Review conversations, not new ones. Back up important messages now.",
                colorHex: "#6B7280"
            ),
            UpcomingTransit(
                planet: "Mars", planetSymbol: "♂",
                action: "sextiles your natal", target: "Sun",
                daysUntil: 14,
                impactDescription: "Energy and confidence align. Your magnetism is at its highest all month.",
                colorHex: "#FF4444"
            ),
        ]
    }

    // MARK: - Weekly Report (mock)

    private func buildWeeklyReport() -> [WeeklyReportEntry] {
        let matches = MockDataService.shared.fetchFeed(limit: 3)
        let days = ["Monday", "Wednesday", "Friday"]
        let insights = [
            "Venus trines their natal Moon this week. Emotional depth is available.",
            "Mercury aligns with their rising. Conversations will flow effortlessly.",
            "Mars sextiles their Venus. Shared momentum and creative spark."
        ]
        let transits = [
            "Jupiter entering your 7th house amplifies this connection.",
            "Full Moon in your 5th house. Ideal for playful exchanges.",
            "Venus retrograde ends. Unresolved feelings may surface positively."
        ]
        return matches.enumerated().map { i, item in
            WeeklyReportEntry(
                matchName: item.user.displayName,
                cosmicScore: item.cosmicScore,
                weeklyInsight: insights[i % insights.count],
                bestDay: days[i % days.count],
                transitNote: transits[i % transits.count]
            )
        }
    }
}
