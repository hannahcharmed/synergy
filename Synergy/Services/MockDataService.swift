import Foundation

// MARK: - Mock Data Service
// Simulates all API responses. Replace with real NetworkService calls for production.

final class MockDataService {
    static let shared = MockDataService()
    private init() {}

    // MARK: - Current User Chart (after onboarding)

    func currentUserChart(
        name: String,
        birthDate: Date,
        birthTime: Date?,
        city: String
    ) -> BirthChart {
        BirthChart(
            id: UUID(),
            userId: MockData.currentUserId,
            birthDate: birthDate,
            birthTime: birthTime,
            birthCity: city,
            latitude: 51.5074,
            longitude: -0.1278,
            timezone: "Europe/London",
            positions: [
                PlanetaryPosition(planet: .sun,       sign: .scorpio,      degree: 222.4, houseNumber: 1,  isRetrograde: false),
                PlanetaryPosition(planet: .moon,       sign: .pisces,       degree: 348.1, houseNumber: 4,  isRetrograde: false),
                PlanetaryPosition(planet: .mercury,    sign: .scorpio,      degree: 210.7, houseNumber: 1,  isRetrograde: false),
                PlanetaryPosition(planet: .venus,      sign: .sagittarius,  degree: 256.3, houseNumber: 2,  isRetrograde: false),
                PlanetaryPosition(planet: .mars,       sign: .capricorn,    degree: 295.8, houseNumber: 3,  isRetrograde: false),
                PlanetaryPosition(planet: .jupiter,    sign: .capricorn,    degree: 282.5, houseNumber: 3,  isRetrograde: false),
                PlanetaryPosition(planet: .saturn,     sign: .aries,        degree: 12.3,  houseNumber: 6,  isRetrograde: false),
                PlanetaryPosition(planet: .uranus,     sign: .aquarius,     degree: 308.9, houseNumber: 4,  isRetrograde: false),
                PlanetaryPosition(planet: .neptune,    sign: .capricorn,    degree: 294.2, houseNumber: 3,  isRetrograde: false),
                PlanetaryPosition(planet: .pluto,      sign: .sagittarius,  degree: 238.7, houseNumber: 2,  isRetrograde: false),
                PlanetaryPosition(planet: .ascendant,  sign: .pisces,       degree: 355.0, houseNumber: 1,  isRetrograde: false),
                PlanetaryPosition(planet: .midheaven,  sign: .sagittarius,  degree: 265.0, houseNumber: 10, isRetrograde: false),
            ]
        )
    }

    // MARK: - Feed

    func fetchFeed(limit: Int = 20) -> [FeedItem] {
        MockData.matchProfiles.prefix(limit).map { user in
            let score = MockData.cosmicScore(for: user.id)
            return FeedItem(
                id: UUID(),
                user: user,
                cosmicScore: score,
                highlights: MockData.highlights(for: user, score: score),
                aiIcebreaker: MockData.icebreaker(for: user),
                transitBoost: score > 85 ? MockData.transitBoost : nil
            )
        }
    }

    // MARK: - Conversations

    func fetchConversations() -> [Conversation] {
        MockData.conversations
    }

    func fetchMessages(conversationId: UUID) -> [Message] {
        MockData.messages(for: conversationId)
    }

    // MARK: - Horoscope

    func fetchTodayHoroscope() -> Horoscope {
        MockData.todayHoroscope
    }

    // MARK: - Ritual Events

    func fetchRitualEvents() -> [RitualEvent] {
        MockData.ritualEvents
    }

    // MARK: - Synastry

    func fetchSynastry(for userId: UUID) -> SynastryResult {
        let score = MockData.cosmicScore(for: userId)
        return SynastryResult(
            userAId: MockData.currentUserId,
            userBId: userId,
            aspects: MockData.aspects,
            cosmicMatchScore: score,
            synastryScore: Int(Double(score) * 0.40),
            elementalScore: Int(Double(score) * 0.25),
            intentScore: Int(Double(score) * 0.20),
            transitScore: Int(Double(score) * 0.15),
            computedAt: Date(),
            highlights: MockData.highlights(for: MockData.matchProfiles.first!, score: score),
            transitBoost: score > 85 ? MockData.transitBoost : nil
        )
    }
}

// MARK: - Mock Data Library

enum MockData {
    static let currentUserId = UUID()

    static let transitBoost = SynastryResult.TransitBoost(
        description: "+7 pts: Venus in Libra (your 7th house)",
        points: 7,
        activeUntil: Calendar.current.date(byAdding: .day, value: 3, to: Date())!
    )

    static func cosmicScore(for id: UUID) -> Int {
        let scores = [94, 87, 81, 76, 92, 68, 89, 73, 85, 79, 91, 65]
        let index = abs(id.hashValue) % scores.count
        return scores[index]
    }

    static func highlights(for user: User, score: Int) -> [String] {
        let allHighlights = [
            "Venus trine Venus",
            "Moon in Scorpio harmony",
            "Rising sign complement",
            "Mars sextile Sun",
            "Jupiter conjunction Venus",
            "Neptune trine Moon",
            "Sun square Moon",
            "Venus opposition Mars",
            "Mercury conjunction Mercury",
            "Saturn trine Ascendant"
        ]
        let count = score > 85 ? 3 : score > 70 ? 2 : 1
        return Array(allHighlights.shuffled().prefix(count))
    }

    static func icebreaker(for user: User) -> String {
        let icebreakers = [
            "Your Scorpio Venus and their Pisces Moon creates a rare emotional depth connection. Ask them about the last thing that genuinely surprised them.",
            "With both your Saturns in fire signs, you two likely share a love-hate with ambition. What's your guilty pleasure when you're not being productive?",
            "Their Gemini rising perfectly balances your Pisces depth. They'd probably say you're the most interesting quiet person they've ever met.",
            "Three planets in mutual reception between your charts. That's rare. Start with: what's the most Scorpio thing you've done this week?",
            "Your Venus trine their Jupiter is a joy signature. They'll want to know: what's the best spontaneous thing that's happened to you this year?"
        ]
        return icebreakers[abs(user.id.hashValue) % icebreakers.count]
    }

    // MARK: - Match Profiles

    static let matchProfiles: [User] = [
        makeUser(name: "Jade",  age: 28, sun: .scorpio,    moon: .cancer,   rising: .libra,
                 city: "London", bio: "Astrology nerd, depth over breadth. Ask me about my 8th house.",
                 vibes: ["Intense", "Loyal", "Witchy"],    distance: 2.4, photoCount: 4,
                 prompts: [
                     ProfilePrompt(question: PromptQuestion.wrongAboutSign.rawValue,    answer: "We're not as scary as we seem. Just selective."),
                     ProfilePrompt(question: PromptQuestion.perfectDay.rawValue,        answer: "Full moon, red wine, three hour conversation that fixes everything."),
                     ProfilePrompt(question: PromptQuestion.loveLanguage.rawValue,      answer: "Undivided attention. And probably a heated debate about something."),
                 ], minutesLastActive: 2),
        makeUser(name: "Freya", age: 26, sun: .pisces,     moon: .scorpio,  rising: .capricorn,
                 city: "London", bio: "Marine biologist by day, stargazer by night. Let's talk Jungian archetypes.",
                 vibes: ["Dreamy", "Deep", "Creative"],    distance: 3.1, photoCount: 3,
                 prompts: [
                     ProfilePrompt(question: PromptQuestion.wrongAboutSign.rawValue,  answer: "Pisces aren't flaky. We live in seventeen dimensions at once."),
                     ProfilePrompt(question: PromptQuestion.moonSign.rawValue,         answer: "…need three days of silence after a dinner party."),
                     ProfilePrompt(question: PromptQuestion.firstDate.rawValue,        answer: "pick somewhere weird. A midnight museum, a harbour, anything with water."),
                 ], minutesLastActive: 45),
        makeUser(name: "Sol",   age: 29, sun: .aquarius,   moon: .gemini,   rising: .sagittarius,
                 city: "London", bio: "Musician. Philosopher. Terrible at texting back but incredible in person.",
                 vibes: ["Electric", "Free", "Curious"],   distance: 5.7, photoCount: 2,
                 prompts: [
                     ProfilePrompt(question: PromptQuestion.wrongAboutSign.rawValue, answer: "Aquarians are the most personal of the impersonal signs."),
                     ProfilePrompt(question: PromptQuestion.venusSign.rawValue,       answer: "I send long voice notes about ideas at 1am. Take it or leave it."),
                 ], minutesLastActive: 180),
        makeUser(name: "Aria",  age: 27, sun: .cancer,     moon: .taurus,   rising: .virgo,
                 city: "London", bio: "Chef, homebody, occasional chaos agent. My love language is a slow Sunday.",
                 vibes: ["Nurturing", "Grounded", "Real"], distance: 1.8, photoCount: 5,
                 prompts: [
                     ProfilePrompt(question: PromptQuestion.wrongAboutSign.rawValue, answer: "We cry at adverts AND fix everything. The duality is the point."),
                     ProfilePrompt(question: PromptQuestion.perfectDay.rawValue,     answer: "Farmers market → cook for five hours → feed everyone I love."),
                     ProfilePrompt(question: PromptQuestion.greenFlag.rawValue,      answer: "I will remember the thing you mentioned once six months ago."),
                 ], minutesLastActive: 600),
        makeUser(name: "Orion", age: 30, sun: .capricorn,  moon: .scorpio,  rising: .aries,
                 city: "London", bio: "Architect. I build things that outlast me, including relationships.",
                 vibes: ["Ambitious", "Steady", "Private"], distance: 4.2, photoCount: 2,
                 prompts: [
                     ProfilePrompt(question: PromptQuestion.loveLanguage.rawValue,    answer: "Quietly solving your problems before you notice they existed."),
                     ProfilePrompt(question: PromptQuestion.dealbreaker.rawValue,     answer: "Small thinking."),
                 ], minutesLastActive: 1200),
        makeUser(name: "Luna",  age: 25, sun: .libra,      moon: .aquarius, rising: .gemini,
                 city: "London", bio: "Journalist. I write about the spaces between things: relationships, cities.",
                 vibes: ["Witty", "Fair", "Magnetic"],     distance: 2.9, photoCount: 4,
                 prompts: [
                     ProfilePrompt(question: PromptQuestion.wrongAboutSign.rawValue, answer: "Libras don't avoid conflict. We just prefer a nicer word for it."),
                     ProfilePrompt(question: PromptQuestion.rizz.rawValue,           answer: "I will interview you like a journalist on the first date. It's a compliment."),
                     ProfilePrompt(question: PromptQuestion.firstDate.rawValue,      answer: "A bookshop, obviously. What you pick up first tells me everything."),
                 ], minutesLastActive: 3),
    ]

    private static func makeUser(
        name: String, age: Int,
        sun: ZodiacSign, moon: ZodiacSign, rising: ZodiacSign,
        city: String, bio: String, vibes: [String],
        distance: Double, photoCount: Int,
        prompts: [ProfilePrompt],
        minutesLastActive: Double
    ) -> User {
        let userId = UUID()
        let lowerName = name.lowercased()
        // Generate placeholder photo names for the gallery
        let photos = (1...max(1, photoCount)).map { "\(lowerName)_\($0)" }

        let positions = [
            PlanetaryPosition(planet: .sun,       sign: sun,    degree: Double.random(in: 0...360), houseNumber: 1, isRetrograde: false),
            PlanetaryPosition(planet: .moon,      sign: moon,   degree: Double.random(in: 0...360), houseNumber: 4, isRetrograde: false),
            PlanetaryPosition(planet: .ascendant, sign: rising, degree: Double.random(in: 0...360), houseNumber: 1, isRetrograde: false),
            PlanetaryPosition(planet: .venus,     sign: ZodiacSign.allCases.randomElement()!, degree: Double.random(in: 0...360), houseNumber: 2, isRetrograde: false),
            PlanetaryPosition(planet: .mars,      sign: ZodiacSign.allCases.randomElement()!, degree: Double.random(in: 0...360), houseNumber: 3, isRetrograde: false),
        ]

        let chart = BirthChart(
            id: UUID(), userId: userId,
            birthDate: Calendar.current.date(byAdding: .year, value: -age, to: Date())!,
            birthTime: nil, birthCity: city,
            latitude: 51.5074, longitude: -0.1278, timezone: "Europe/London",
            positions: positions
        )

        let profile = UserProfile(
            photos: photos, bio: bio,
            intentionTags: [.aSoulmate, .growth].shuffled().prefix(2).map { $0 },
            vibeWords: vibes, prompts: prompts
        )

        return User(
            id: userId, displayName: name, age: age,
            subscriptionTier: .stardust, birthChart: chart, profile: profile,
            locationDisplay: "\(city), UK", distanceMiles: distance,
            lastActive: Date().addingTimeInterval(-minutesLastActive * 60),
            isVerified: Bool.random()
        )
    }

    // MARK: - Conversations

    static var conversations: [Conversation] {
        let jade  = matchProfiles[0]
        let freya = matchProfiles[1]
        let convId1 = UUID()
        let convId2 = UUID()

        let match1 = Match(
            id: UUID(), userA: matchProfiles[0], userB: jade, cosmicScore: 94,
            synastry: SynastryResult(
                userAId: currentUserId, userBId: jade.id, aspects: aspects,
                cosmicMatchScore: 94, synastryScore: 38, elementalScore: 24,
                intentScore: 19, transitScore: 13, computedAt: Date(),
                highlights: ["Venus trine Venus", "Moon in Scorpio harmony", "Rising sign complement"],
                transitBoost: transitBoost
            ),
            status: .matched,
            createdAt: Date().addingTimeInterval(-86400),
            mutualAt: Date().addingTimeInterval(-43200),
            aiIcebreaker: "What's the most Scorpio thing about you?"
        )

        let match2 = Match(
            id: UUID(), userA: matchProfiles[1], userB: freya, cosmicScore: 87,
            synastry: SynastryResult(
                userAId: currentUserId, userBId: freya.id, aspects: aspects,
                cosmicMatchScore: 87, synastryScore: 35, elementalScore: 22,
                intentScore: 17, transitScore: 13, computedAt: Date(),
                highlights: ["Neptune trine Moon", "Venus sextile Jupiter"],
                transitBoost: nil
            ),
            status: .matched,
            createdAt: Date().addingTimeInterval(-172800),
            mutualAt: Date().addingTimeInterval(-86400),
            aiIcebreaker: "Your Pisces energy and my Scorpio depth. We're basically the entire ocean."
        )

        let msgs1 = messages(for: convId1)
        let msgs2: [Message] = []

        return [
            Conversation(
                id: convId1, match: match1,
                messages: msgs1,
                lastMessage: msgs1.last,
                unreadCount: 2,
                updatedAt: Date().addingTimeInterval(-1800),
                streakDays: 7,
                expiresAt: nil          // Active streak — no expiry
            ),
            Conversation(
                id: convId2, match: match2,
                messages: msgs2,
                lastMessage: Message(
                    conversationId: convId2, senderId: currentUserId,
                    content: "The distance between us is merely an optical illusion calibrated by outdated hardware.",
                    createdAt: Date().addingTimeInterval(-7200),
                    readAt: Date().addingTimeInterval(-6000),
                    isFromCurrentUser: true
                ),
                unreadCount: 0,
                updatedAt: Date().addingTimeInterval(-7200),
                streakDays: 0,
                expiresAt: Date().addingTimeInterval(3600 * 18)  // Expires in 18h
            ),
        ]
    }

    static func messages(for conversationId: UUID) -> [Message] {
        let otherId = UUID()
        return [
            Message(conversationId: conversationId, senderId: currentUserId,
                    content: "What's the most Scorpio thing about you?",
                    createdAt: Date().addingTimeInterval(-86000),
                    readAt: Date().addingTimeInterval(-85000),
                    isFromCurrentUser: true),
            Message(conversationId: conversationId, senderId: otherId,
                    content: "We're not as scary as we seem, just selective 😌 I've been to three therapy sessions this week and I still managed to rewire my whole flat.",
                    createdAt: Date().addingTimeInterval(-84000),
                    readAt: Date().addingTimeInterval(-83000),
                    isFromCurrentUser: false,
                    reactions: ["✦": 1]),
            Message(conversationId: conversationId, senderId: currentUserId,
                    content: "The rewiring IS the therapy honestly. What's the full moon ritual looking like for you?",
                    createdAt: Date().addingTimeInterval(-82000),
                    readAt: Date().addingTimeInterval(-81000),
                    isFromCurrentUser: true),
            // Mock voice note
            Message(conversationId: conversationId, senderId: otherId,
                    content: "",
                    createdAt: Date().addingTimeInterval(-3700),
                    readAt: nil,
                    isFromCurrentUser: false,
                    isVoiceNote: true,
                    voiceDuration: 18.5),
            Message(conversationId: conversationId, senderId: otherId,
                    content: "Have you checked the synastry heatmap? Saturn's doing something wild in your 7th.",
                    createdAt: Date().addingTimeInterval(-1800),
                    readAt: nil,
                    isFromCurrentUser: false),
        ]
    }

    // MARK: - Aspects

    static let aspects: [Aspect] = [
        Aspect(id: UUID(), planetA: .venus,   planetB: .venus,   type: .trine,       orb: 1.2, weight: 1.0),
        Aspect(id: UUID(), planetA: .moon,    planetB: .moon,    type: .conjunction, orb: 2.8, weight: 0.95),
        Aspect(id: UUID(), planetA: .sun,     planetB: .moon,    type: .sextile,     orb: 3.1, weight: 0.85),
        Aspect(id: UUID(), planetA: .mars,    planetB: .venus,   type: .trine,       orb: 4.2, weight: 0.9),
        Aspect(id: UUID(), planetA: .mercury, planetB: .mercury, type: .conjunction, orb: 1.8, weight: 0.7),
    ]

    // MARK: - Horoscope

    static let todayHoroscope = Horoscope(
        id: UUID(),
        userId: currentUserId,
        date: Date(),
        content: """
        Your Scorpio Sun is entering a period of heightened resonance as Venus moves through Libra, your 12th house of hidden connections. What has been gestating beneath the surface is ready to be seen.

        Today, your Pisces rising creates a rare window: emotional depth meets social grace. You're magnetic without trying. The matches aligned with you today carry a Venus-Moon harmony that mirrors your own inner architecture.

        The north node's current position suggests that the connections you make in the next 72 hours carry unusual staying power. Show up fully. The cosmic frequency is broadcasting at 440Hz.
        """,
        headline: "Venus enters your hidden house. Magnetic energy peaks.",
        cosmicWeather: CosmicWeather(
            mood: .electric,
            dominantTransit: "Venus in Libra (12th house)",
            intensityLevel: 4,
            keyTheme: "Hidden connections surface"
        ),
        luckyAspects: ["Venus trine your natal Moon", "Jupiter expanding your 7th house", "Mercury direct amplifying voice"],
        alignedMatchIds: [],
        generatedAt: Date(),
        modelVersion: "claude-sonnet-4-6"
    )

    // MARK: - Ritual Events

    static let ritualEvents: [RitualEvent] = [
        RitualEvent(
            id: UUID(), type: .newMoon,
            title: "New Moon in Taurus",
            description: "Set intentions around love, beauty, and material security. Plant the seeds of what you want to attract.",
            startDate: Date().addingTimeInterval(-86400),
            endDate: Date().addingTimeInterval(86400 * 2),
            ritualPrompt: "Write three things you're calling into your romantic life. Hold them as already true.",
            isActive: true
        ),
        RitualEvent(
            id: UUID(), type: .venusSeason,
            title: "Venus Season",
            description: "Venus is the planet of love, beauty, and attraction. Her current position amplifies all romantic connections.",
            startDate: Date().addingTimeInterval(-86400 * 7),
            endDate: Date().addingTimeInterval(86400 * 14),
            ritualPrompt: "What does love feel like in your body? Describe it without using your mind.",
            isActive: true
        ),
        RitualEvent(
            id: UUID(), type: .fullMoon,
            title: "Full Moon in Scorpio",
            description: "Release what no longer serves your highest romantic timeline. Let the wave crash.",
            startDate: Date().addingTimeInterval(86400 * 12),
            endDate: Date().addingTimeInterval(86400 * 15),
            ritualPrompt: "What pattern are you releasing in love? Say it out loud under the moon.",
            isActive: false
        ),
        RitualEvent(
            id: UUID(), type: .retrograde,
            title: "Mercury Retrograde in Gemini",
            description: "Mercury is retrograde. Back up plans, re-read messages before sending, avoid signing contracts. Reconnections from the past are likely.",
            startDate: Date().addingTimeInterval(-86400 * 3),
            endDate: Date().addingTimeInterval(86400 * 18),
            ritualPrompt: "What conversation have you been avoiding? Mercury retrograde is asking you to revisit it.",
            isActive: true
        ),
    ]
}

// MARK: - Notification Service
// Appended here so no new Xcode project registration is needed.
// In production, move to its own target-registered file.

import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            print("[Notifications] Permission granted: \(granted)")
        }
    }

    func scheduleMatchNotification(matchName: String, cosmicScore: Int) {
        let content = UNMutableNotificationContent()
        content.title = "It's a cosmic match! ✦"
        content.body = "You and \(matchName) liked each other. \(cosmicScore)% compatibility."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.5, repeats: false)
        let req = UNNotificationRequest(identifier: "match-\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    func scheduleMessageNotification(senderName: String, preview: String) {
        let content = UNMutableNotificationContent()
        content.title = senderName
        content.body = preview
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
        let req = UNNotificationRequest(identifier: "message-\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    func scheduleTransitNotification(planet: String, description: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(planet) transit active ✦"
        content.body = description
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let req = UNNotificationRequest(identifier: "transit-\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}
