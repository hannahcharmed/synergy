import Foundation

// MARK: - Daily Horoscope

struct Horoscope: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let date: Date
    let content: String
    let headline: String
    let cosmicWeather: CosmicWeather
    let luckyAspects: [String]
    let alignedMatchIds: [UUID]     // Which matches are most aligned today
    let generatedAt: Date
    let modelVersion: String

    var dateFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMMM d"
        return f.string(from: date)
    }
}

// MARK: - Cosmic Weather

struct CosmicWeather: Codable {
    let mood: CosmicMood
    let dominantTransit: String
    let intensityLevel: Int         // 1–5
    let keyTheme: String

    enum CosmicMood: String, Codable {
        case expansive   = "Expansive"
        case reflective  = "Reflective"
        case passionate  = "Passionate"
        case grounded    = "Grounded"
        case electric    = "Electric"
        case dreamy      = "Dreamy"

        var icon: String {
            switch self {
            case .expansive:  return "sun.max.fill"
            case .reflective: return "moon.stars.fill"
            case .passionate: return "flame.fill"
            case .grounded:   return "mountain.2.fill"
            case .electric:   return "bolt.fill"
            case .dreamy:     return "cloud.fill"
            }
        }

        var color: String {
            switch self {
            case .expansive:  return "#FFB800"
            case .reflective: return "#7D5FFF"
            case .passionate: return "#FF4D6A"
            case .grounded:   return "#7AB648"
            case .electric:   return "#00F0FF"
            case .dreamy:     return "#A78BFA"
            }
        }
    }
}

// MARK: - Ritual Event

struct RitualEvent: Codable, Identifiable {
    let id: UUID
    let type: RitualType
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date
    let ritualPrompt: String
    let isActive: Bool

    enum RitualType: String, Codable {
        case newMoon      = "new_moon"
        case fullMoon     = "full_moon"
        case venusSeason  = "venus_season"
        case retrograde   = "retrograde"
        case eclipse      = "eclipse"

        var icon: String {
            switch self {
            case .newMoon:     return "moon.fill"
            case .fullMoon:    return "moon.circle.fill"
            case .venusSeason: return "heart.circle.fill"
            case .retrograde:  return "arrow.counterclockwise.circle.fill"
            case .eclipse:     return "sun.haze.fill"
            }
        }

        var color: String {
            switch self {
            case .newMoon:     return "#7D5FFF"
            case .fullMoon:    return "#F0C040"
            case .venusSeason: return "#FF6B9D"
            case .retrograde:  return "#FF4D6A"
            case .eclipse:     return "#FF8C00"
            }
        }
    }

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
}

// MARK: - Transit

struct Transit: Codable, Identifiable {
    let id: UUID
    let planet: Planet
    let fromSign: ZodiacSign
    let toSign: ZodiacSign
    let type: TransitType
    let startDate: Date
    let exactDate: Date
    let endDate: Date
    let description: String
    let scoreImpact: Int        // Positive or negative, ±15 max

    enum TransitType: String, Codable {
        case entering     = "Entering"
        case conjunction  = "Conjunction"
        case trine        = "Trine"
        case opposition   = "Opposition"
        case direct       = "Direct"
        case retrograde   = "Retrograde"
    }
}
