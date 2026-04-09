import Foundation

// MARK: - Zodiac Signs

enum ZodiacSign: String, Codable, CaseIterable {
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
    case aquarius = "Aquarius"
    case pisces = "Pisces"

    var symbol: String {
        switch self {
        case .aries:       return "♈"
        case .taurus:      return "♉"
        case .gemini:      return "♊"
        case .cancer:      return "♋"
        case .leo:         return "♌"
        case .virgo:       return "♍"
        case .libra:       return "♎"
        case .scorpio:     return "♏"
        case .sagittarius: return "♐"
        case .capricorn:   return "♑"
        case .aquarius:    return "♒"
        case .pisces:      return "♓"
        }
    }

    var element: Element {
        switch self {
        case .aries, .leo, .sagittarius:           return .fire
        case .taurus, .virgo, .capricorn:          return .earth
        case .gemini, .libra, .aquarius:           return .air
        case .cancer, .scorpio, .pisces:           return .water
        }
    }

    var modality: Modality {
        switch self {
        case .aries, .cancer, .libra, .capricorn:       return .cardinal
        case .taurus, .leo, .scorpio, .aquarius:        return .fixed
        case .gemini, .virgo, .sagittarius, .pisces:    return .mutable
        }
    }

    var rulingPlanet: Planet {
        switch self {
        case .aries:       return .mars
        case .taurus:      return .venus
        case .gemini:      return .mercury
        case .cancer:      return .moon
        case .leo:         return .sun
        case .virgo:       return .mercury
        case .libra:       return .venus
        case .scorpio:     return .pluto
        case .sagittarius: return .jupiter
        case .capricorn:   return .saturn
        case .aquarius:    return .uranus
        case .pisces:      return .neptune
        }
    }
}

// MARK: - Element

enum Element: String, Codable, CaseIterable {
    case fire = "Fire"
    case earth = "Earth"
    case air = "Air"
    case water = "Water"

    var emoji: String {
        switch self {
        case .fire:  return "🔥"
        case .earth: return "🌿"
        case .air:   return "💨"
        case .water: return "💧"
        }
    }

    var compatibleElements: [Element] {
        switch self {
        case .fire:  return [.fire, .air]
        case .earth: return [.earth, .water]
        case .air:   return [.air, .fire]
        case .water: return [.water, .earth]
        }
    }
}

// MARK: - Modality

enum Modality: String, Codable {
    case cardinal = "Cardinal"
    case fixed = "Fixed"
    case mutable = "Mutable"
}

// MARK: - Planets

enum Planet: String, Codable, CaseIterable {
    case sun        = "Sun"
    case moon       = "Moon"
    case mercury    = "Mercury"
    case venus      = "Venus"
    case mars       = "Mars"
    case jupiter    = "Jupiter"
    case saturn     = "Saturn"
    case uranus     = "Uranus"
    case neptune    = "Neptune"
    case pluto      = "Pluto"
    case ascendant  = "Ascendant"
    case midheaven  = "Midheaven"
    case chiron     = "Chiron"
    case northNode  = "North Node"

    var symbol: String {
        switch self {
        case .sun:       return "☉"
        case .moon:      return "☽"
        case .mercury:   return "☿"
        case .venus:     return "♀"
        case .mars:      return "♂"
        case .jupiter:   return "♃"
        case .saturn:    return "♄"
        case .uranus:    return "♅"
        case .neptune:   return "♆"
        case .pluto:     return "♇"
        case .ascendant: return "AC"
        case .midheaven: return "MC"
        case .chiron:    return "⚷"
        case .northNode: return "☊"
        }
    }

    var significance: Double {
        switch self {
        case .venus:     return 1.0
        case .moon:      return 0.95
        case .ascendant: return 0.85
        case .mars:      return 0.9
        case .sun:       return 0.8
        case .mercury:   return 0.7
        case .jupiter:   return 0.65
        case .saturn:    return 0.6
        case .midheaven: return 0.55
        case .northNode: return 0.5
        case .chiron:    return 0.45
        case .uranus:    return 0.4
        case .neptune:   return 0.35
        case .pluto:     return 0.3
        }
    }
}

// MARK: - Planetary Position

struct PlanetaryPosition: Codable, Identifiable {
    var id: String { planet.rawValue }
    let planet: Planet
    let sign: ZodiacSign
    let degree: Double      // 0–360 ecliptic longitude
    let houseNumber: Int    // 1–12
    let isRetrograde: Bool

    var formattedDegree: String {
        let d = Int(degree) % 30
        let m = Int((degree.truncatingRemainder(dividingBy: 1)) * 60)
        return "\(d)°\(String(format: "%02d", m))'"
    }

    var displayString: String {
        "\(planet.symbol) \(sign.rawValue) \(formattedDegree)\(isRetrograde ? " ℞" : "")"
    }
}

// MARK: - Aspect

enum AspectType: String, Codable {
    case conjunction  = "Conjunction"   // 0°
    case opposition   = "Opposition"    // 180°
    case trine        = "Trine"         // 120°
    case square       = "Square"        // 90°
    case sextile      = "Sextile"       // 60°
    case quincunx     = "Quincunx"      // 150°

    var angle: Double {
        switch self {
        case .conjunction: return 0
        case .opposition:  return 180
        case .trine:       return 120
        case .square:      return 90
        case .sextile:     return 60
        case .quincunx:    return 150
        }
    }

    var orb: Double {
        switch self {
        case .conjunction, .opposition: return 8
        case .trine, .square:           return 6
        case .sextile:                  return 4
        case .quincunx:                 return 2
        }
    }

    var isHarmonious: Bool {
        switch self {
        case .trine, .sextile, .conjunction: return true
        case .opposition, .square, .quincunx: return false
        }
    }

    var symbol: String {
        switch self {
        case .conjunction: return "☌"
        case .opposition:  return "☍"
        case .trine:       return "△"
        case .square:      return "□"
        case .sextile:     return "⚹"
        case .quincunx:    return "⚻"
        }
    }
}

struct Aspect: Codable, Identifiable {
    let id: UUID
    let planetA: Planet
    let planetB: Planet
    let type: AspectType
    let orb: Double         // Actual deviation from exact angle
    let weight: Double      // Combined planet significance

    var isExact: Bool { orb < 1.0 }

    var description: String {
        "\(planetA.symbol) \(type.rawValue) \(planetB.symbol)"
    }
}

// MARK: - Birth Chart

struct BirthChart: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let birthDate: Date
    let birthTime: Date?
    let birthCity: String
    let latitude: Double
    let longitude: Double
    let timezone: String

    // Planetary positions (raw degrees — never derived scores)
    let positions: [PlanetaryPosition]

    // Convenience accessors
    var sunSign: ZodiacSign { positions.first(where: { $0.planet == .sun })?.sign ?? .aries }
    var moonSign: ZodiacSign { positions.first(where: { $0.planet == .moon })?.sign ?? .cancer }
    var risingSign: ZodiacSign { positions.first(where: { $0.planet == .ascendant })?.sign ?? .aries }
    var venusSign: ZodiacSign { positions.first(where: { $0.planet == .venus })?.sign ?? .taurus }
    var marsSign: ZodiacSign { positions.first(where: { $0.planet == .mars })?.sign ?? .aries }

    var dominantElement: Element {
        var counts: [Element: Int] = [:]
        for position in positions {
            counts[position.sign.element, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? .air
    }

    var shortSummary: String {
        "\(sunSign.rawValue) \(sunSign.symbol) · \(risingSign.rawValue) rising"
    }
}

// MARK: - Synastry Result

struct SynastryResult: Codable {
    let userAId: UUID
    let userBId: UUID
    let aspects: [Aspect]
    let cosmicMatchScore: Int           // 0–100
    let synastryScore: Int              // Layer 1: 40%
    let elementalScore: Int             // Layer 2: 25%
    let intentScore: Int                // Layer 3: 20%
    let transitScore: Int               // Layer 4: 15%
    let computedAt: Date
    let highlights: [String]            // Human-readable aspect highlights
    let transitBoost: TransitBoost?

    struct TransitBoost: Codable {
        let description: String
        let points: Int
        let activeUntil: Date
    }
}

// MARK: - Relationship Intention

enum RelationshipIntention: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case aSoulmate      = "A soulmate"
    case deepFriendship = "Deep friendship"
    case adventure      = "Adventure"
    case slowLove       = "Slow love"
    case intellectual   = "Intellectual match"
    case growth         = "Growth partner"
    case somethingCosmic = "Something cosmic"
    case notSureYet     = "Not sure yet"

    var icon: String {
        switch self {
        case .aSoulmate:       return "heart.fill"
        case .deepFriendship:  return "person.2.fill"
        case .adventure:       return "airplane"
        case .slowLove:        return "leaf.fill"
        case .intellectual:    return "brain"
        case .growth:          return "arrow.up.circle.fill"
        case .somethingCosmic: return "sparkles"
        case .notSureYet:      return "questionmark.circle.fill"
        }
    }
}
