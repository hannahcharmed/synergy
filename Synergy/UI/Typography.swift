import SwiftUI

// MARK: - Font Registration
// Add SpaceGrotesk-*.ttf and Inter-*.ttf to Resources/ and Info.plist under UIAppFonts

enum SynergyFont {
    // Headline — Space Grotesk
    static func headline(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom("SpaceGrotesk-Bold", size: size, relativeTo: .title)
    }

    static func headlineMedium(_ size: CGFloat) -> Font {
        .custom("SpaceGrotesk-Medium", size: size, relativeTo: .headline)
    }

    static func headlineSemiBold(_ size: CGFloat) -> Font {
        .custom("SpaceGrotesk-SemiBold", size: size, relativeTo: .headline)
    }

    // Body — Inter
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .medium:   return .custom("Inter-Medium", size: size, relativeTo: .body)
        case .semibold: return .custom("Inter-SemiBold", size: size, relativeTo: .body)
        case .bold:     return .custom("Inter-Bold", size: size, relativeTo: .body)
        default:        return .custom("Inter-Regular", size: size, relativeTo: .body)
        }
    }

    // System label — monospaced feel for data fields
    static var systemLabel: Font {
        .system(size: 10, weight: .medium, design: .monospaced)
    }

    // Score display
    static var scoreDisplay: Font {
        .custom("SpaceGrotesk-Bold", size: 56, relativeTo: .largeTitle)
    }
}

// MARK: - Text Styles (convenience)

extension Text {
    func displayStyle() -> Text {
        self.font(SynergyFont.headline(40))
            .foregroundColor(.cosmicNeutral)
    }

    func headlineStyle() -> Text {
        self.font(SynergyFont.headline(24))
            .foregroundColor(.cosmicNeutral)
    }

    func subheadlineStyle() -> Text {
        self.font(SynergyFont.headlineMedium(16))
            .foregroundColor(.cosmicNeutral)
    }

    func bodyStyle() -> Text {
        self.font(SynergyFont.body(15))
            .foregroundColor(.cosmicNeutral.opacity(0.8))
    }

    func captionStyle() -> Text {
        self.font(SynergyFont.body(12))
            .foregroundColor(.cosmicMuted)
    }

    func systemLabelStyle() -> Text {
        self.font(SynergyFont.systemLabel)
            .foregroundColor(.cosmicMuted)
            .kerning(1.5)
    }

    func cyanAccent() -> Text {
        self.foregroundColor(.cosmicCyan)
    }

    func purpleAccent() -> Text {
        self.foregroundColor(.cosmicPurple)
    }
}
