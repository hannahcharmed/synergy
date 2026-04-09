import SwiftUI

// MARK: - Button Styles matching brand guide

enum CosmicButtonVariant {
    case primary    // Dark filled
    case secondary  // Cyan filled
    case inverted   // Light filled
    case outlined   // Outline only
    case ghost      // Text only
    case gradient   // Purple → Cyan gradient
}

struct CosmicButton: View {
    let title: String
    let variant: CosmicButtonVariant
    let icon: String?
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        variant: CosmicButtonVariant = .gradient,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            buttonContent
        }
        .buttonStyle(CosmicButtonStyle(variant: variant))
        .disabled(isLoading)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private var buttonContent: some View {
        HStack(spacing: Spacing.sm) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: labelColor))
                    .scaleEffect(0.8)
            } else {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(SynergyFont.headlineMedium(16))
                    .kerning(0.3)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
    }

    private var labelColor: Color {
        switch variant {
        case .primary:   return .cosmicNeutral
        case .secondary: return .cosmicDark
        case .inverted:  return .cosmicDark
        case .outlined:  return .cosmicCyan
        case .ghost:     return .cosmicCyan
        case .gradient:  return .cosmicNeutral
        }
    }
}

struct CosmicButtonStyle: ButtonStyle {
    let variant: CosmicButtonVariant

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            Color.cosmicDark
        case .secondary:
            Color.cosmicCyan
        case .inverted:
            Color.cosmicNeutral
        case .outlined:
            Color.clear
        case .ghost:
            Color.clear
        case .gradient:
            LinearGradient.cosmicGradient
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:   return .cosmicNeutral
        case .secondary: return .cosmicDark
        case .inverted:  return .cosmicDark
        case .outlined:  return .cosmicCyan
        case .ghost:     return .cosmicCyan
        case .gradient:  return .cosmicNeutral
        }
    }

    private var borderColor: Color {
        switch variant {
        case .outlined: return .cosmicCyan.opacity(0.7)
        default: return .clear
        }
    }

    private var borderWidth: CGFloat {
        switch variant {
        case .outlined: return 1.5
        default: return 0
        }
    }
}

// MARK: - Icon Button

struct CosmicIconButton: View {
    let icon: String
    let variant: CosmicButtonVariant
    let size: CGFloat
    let action: () -> Void

    init(_ icon: String, variant: CosmicButtonVariant = .outlined, size: CGFloat = 52, action: @escaping () -> Void) {
        self.icon = icon
        self.variant = variant
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: size, height: size)
                .background(background)
                .clipShape(Circle())
                .overlay(
                    Circle().strokeBorder(borderColor, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon)
    }

    private var iconColor: Color {
        switch variant {
        case .primary:  return .cosmicNeutral
        case .outlined: return .cosmicCyan
        case .gradient: return .cosmicNeutral
        default:        return .cosmicNeutral
        }
    }

    @ViewBuilder
    private var background: some View {
        switch variant {
        case .primary:  Color.cosmicCard
        case .outlined: Color.cosmicCard
        case .gradient: LinearGradient.cosmicGradient
        default:        Color.cosmicCard
        }
    }

    private var borderColor: Color {
        switch variant {
        case .outlined: return .cosmicCyan.opacity(0.5)
        default:        return .cosmicBorder
        }
    }
}
