import SwiftUI

// MARK: - Brand Colors

extension Color {
    // Core palette — from brand guide
    static let cosmicDark      = Color(hex: "#202124")   // Primary background
    static let cosmicCyan      = Color(hex: "#00F0FF")   // Secondary / accent
    static let cosmicPurple    = Color(hex: "#7D5FFF")   // Tertiary / cosmic
    static let cosmicNeutral   = Color(hex: "#F8F9FA")   // Light text / surfaces

    // Extended
    static let cosmicDarkAlt   = Color(hex: "#16181A")   // Deeper background
    static let cosmicCard      = Color(hex: "#1E2023")   // Card surface
    static let cosmicBorder    = Color(hex: "#2C2F33")   // Subtle borders
    static let cosmicMuted     = Color(hex: "#6B7280")   // Muted text
    static let cosmicError     = Color(hex: "#FF4D6A")   // Error / destructive
    static let cosmicSuccess   = Color(hex: "#00D68F")   // Success / matched

    // Semantic
    static let cosmicFire      = Color(hex: "#FF6B35")   // Fire signs
    static let cosmicEarth     = Color(hex: "#7AB648")   // Earth signs
    static let cosmicAir       = Color(hex: "#00C2FF")   // Air signs
    static let cosmicWater     = Color(hex: "#7D5FFF")   // Water signs

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Gradients

extension LinearGradient {
    static let cosmicGradient = LinearGradient(
        colors: [.cosmicPurple, .cosmicCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cosmicVertical = LinearGradient(
        colors: [.cosmicPurple.opacity(0.8), .cosmicCyan.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let darkFade = LinearGradient(
        colors: [.cosmicDark, .cosmicDarkAlt],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardShimmer = LinearGradient(
        colors: [.cosmicCard, Color(hex: "#252830"), .cosmicCard],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let scoreGlow = LinearGradient(
        colors: [.cosmicCyan, .cosmicPurple],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let onboardingBg = LinearGradient(
        colors: [Color(hex: "#0D0E10"), Color(hex: "#16181F"), Color(hex: "#1A1328")],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Spacing

enum Spacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius

enum Radius {
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 24
    static let card: CGFloat = 20
    static let pill: CGFloat = 100
}

// MARK: - Shadow

extension View {
    func cosmicGlow(color: Color = .cosmicCyan, radius: CGFloat = 12) -> some View {
        self.shadow(color: color.opacity(0.4), radius: radius, x: 0, y: 0)
    }

    func cosmicPurpleGlow(radius: CGFloat = 12) -> some View {
        self.shadow(color: Color.cosmicPurple.opacity(0.4), radius: radius, x: 0, y: 0)
    }

    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Glass Effect

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = Radius.card
    var opacity: Double = 0.06

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(opacity))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.15), Color.white.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

struct CosmicCard: ViewModifier {
    var cornerRadius: CGFloat = Radius.card

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cosmicCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Color.cosmicBorder, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = Radius.card) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }

    func cosmicCard(cornerRadius: CGFloat = Radius.card) -> some View {
        modifier(CosmicCard(cornerRadius: cornerRadius))
    }
}

// MARK: - System Label Style (ASTRO_OS tonal)

struct SystemLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(SynergyFont.systemLabel)
            .foregroundColor(.cosmicMuted)
            .textCase(.uppercase)
    }
}

extension View {
    func systemLabel() -> some View {
        modifier(SystemLabelStyle())
    }
}
