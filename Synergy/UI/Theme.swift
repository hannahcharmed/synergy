import SwiftUI

// MARK: - Brand Colors

extension Color {

    // Adaptive helper — creates a color that responds to dark/light mode
    static func adaptive(dark darkHex: String, light lightHex: String) -> Color {
        Color(UIColor { trait in
            UIColor(Color(hex: trait.userInterfaceStyle == .dark ? darkHex : lightHex))
        })
    }

    // Core palette
    static let cosmicDark    = adaptive(dark: "#202124", light: "#F5F0FF")
    // Adaptive accents: neon on dark, deeper/accessible on light
    static let cosmicCyan    = adaptive(dark: "#00F0FF", light: "#0077A8")
    static let cosmicPurple  = adaptive(dark: "#7D5FFF", light: "#5433C8")
    static let cosmicNeutral = adaptive(dark: "#F8F9FA", light: "#1A1525")

    // Extended
    static let cosmicDarkAlt = adaptive(dark: "#16181A", light: "#EDE5FA")
    static let cosmicCard    = adaptive(dark: "#1E2023", light: "#FFFFFF")
    static let cosmicBorder  = adaptive(dark: "#2C2F33", light: "#C9BEE8")
    static let cosmicMuted   = adaptive(dark: "#6B7280", light: "#4E3F70")
    static let cosmicError   = Color(hex: "#FF4D6A")
    static let cosmicSuccess = adaptive(dark: "#00D68F", light: "#007A52")

    // Semantic element colours
    static let cosmicFire  = Color(hex: "#FF6B35")
    static let cosmicEarth = Color(hex: "#7AB648")
    static let cosmicAir   = Color(hex: "#00C2FF")
    static let cosmicWater = Color(hex: "#7D5FFF")

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
        colors: [Color.cosmicPurple.opacity(0.8), Color.cosmicCyan.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let darkFade = LinearGradient(
        colors: [.cosmicDark, .cosmicDarkAlt],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardShimmer = LinearGradient(
        colors: [.cosmicCard, Color.adaptive(dark: "#252830", light: "#F0EBF8"), .cosmicCard],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let scoreGlow = LinearGradient(
        colors: [.cosmicCyan, .cosmicPurple],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Adaptive: deep cosmic dark → purple-tinted dark (dark) / soft lavender (light)
    static let onboardingBg = LinearGradient(
        colors: [
            Color.cosmicDarkAlt,
            Color.cosmicDark,
            Color.adaptive(dark: "#1A1328", light: "#DDD5F0"),
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Spacing

enum Spacing {
    static let xs:   CGFloat = 4
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 16
    static let lg:   CGFloat = 24
    static let xl:   CGFloat = 32
    static let xxl:  CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius

enum Radius {
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let lg:   CGFloat = 16
    static let xl:   CGFloat = 24
    static let card: CGFloat = 20
    static let pill: CGFloat = 100
}

// MARK: - Glow / Shadow

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
                    .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(opacity)))
                    .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.04)],
                                startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1))
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
                    .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.cosmicBorder, lineWidth: 1))
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
