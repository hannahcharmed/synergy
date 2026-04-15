import SwiftUI

// MARK: - Cosmic Match Score Badge

struct MatchScoreBadge: View {
    let score: Int
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large
        var diameter: CGFloat {
            switch self { case .small: return 52; case .medium: return 72; case .large: return 100 }
        }
        var fontSize: CGFloat {
            switch self { case .small: return 16; case .medium: return 22; case .large: return 32 }
        }
        var labelSize: CGFloat {
            switch self { case .small: return 7; case .medium: return 8; case .large: return 10 }
        }
        var strokeWidth: CGFloat {
            switch self { case .small: return 2; case .medium: return 2.5; case .large: return 3 }
        }
    }

    private var scoreColor: Color {
        switch score {
        case 90...100: return .cosmicCyan
        case 75...89:  return .cosmicPurple
        case 60...74:  return Color(hex: "#A78BFA")
        default:       return .cosmicMuted
        }
    }

    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(scoreColor.opacity(0.2), lineWidth: size.strokeWidth * 3)
                .frame(width: size.diameter + 8, height: size.diameter + 8)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    LinearGradient.scoreGlow,
                    style: StrokeStyle(lineWidth: size.strokeWidth, lineCap: .round)
                )
                .frame(width: size.diameter, height: size.diameter)
                .rotationEffect(.degrees(-90))

            // Background circle
            Circle()
                .fill(Color.cosmicDark)
                .frame(width: size.diameter - size.strokeWidth * 2, height: size.diameter - size.strokeWidth * 2)

            // Score content
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(SynergyFont.headline(size.fontSize))
                    .foregroundColor(.cosmicNeutral)

                Text("match")
                    .font(.system(size: size.labelSize, weight: .medium, design: .monospaced))
                    .foregroundColor(.cosmicMuted)
                    .kerning(1)
            }
        }
        .cosmicGlow(color: scoreColor, radius: score > 85 ? 16 : 8)
        .onAppear {
            let style: UIImpactFeedbackGenerator.FeedbackStyle = score >= 90 ? .heavy : score >= 75 ? .medium : .light
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }
}

// MARK: - Score Pill (inline)

struct MatchScorePill: View {
    let score: Int
    var showLabel: Bool = true

    private var color: Color {
        score >= 85 ? .cosmicCyan : score >= 70 ? .cosmicPurple : .cosmicMuted
    }

    var body: some View {
        HStack(spacing: 4) {
            if showLabel {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .semibold))
            }
            Text("\(score)%")
                .font(SynergyFont.headlineMedium(13))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1))
        .cosmicGlow(color: color, radius: score >= 85 ? 6 : 0)
    }
}

// MARK: - Planet Aspect Tag

struct PlanetAspectTag: View {
    let text: String
    var highlighted: Bool = false

    var body: some View {
        Text(text)
            .font(SynergyFont.body(12, weight: .medium))
            .foregroundColor(highlighted ? .cosmicCyan : .cosmicNeutral.opacity(0.8))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 5)
            .background(
                highlighted
                    ? Color.cosmicCyan.opacity(0.12)
                    : Color.cosmicBorder.opacity(0.5)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(
                    highlighted ? Color.cosmicCyan.opacity(0.5) : Color.cosmicBorder,
                    lineWidth: 1
                )
            )
    }
}

// MARK: - Element Badge

struct ElementBadge: View {
    let element: String

    private var color: Color {
        switch element.lowercased() {
        case "fire":  return .cosmicFire
        case "earth": return .cosmicEarth
        case "air":   return .cosmicAir
        case "water": return .cosmicWater
        default:      return .cosmicMuted
        }
    }

    private var icon: String {
        switch element.lowercased() {
        case "fire":  return "flame.fill"
        case "earth": return "leaf.fill"
        case "air":   return "wind"
        case "water": return "drop.fill"
        default:      return "circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(element)
                .font(SynergyFont.body(11, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}
