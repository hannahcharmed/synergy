import SwiftUI

// MARK: - Match Card
// The primary swipeable card with cosmic score, aspects, and icebreaker.

struct MatchCardView: View {
    let item: FeedItem
    let isTop: Bool
    var onLike: (() -> Void)? = nil
    var onPass: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var dragAngle: Double = 0
    @State private var likeOpacity: Double = 0
    @State private var passOpacity: Double = 0
    @State private var synastryHintOpacity: Double = 0

    private let swipeThreshold: CGFloat = 100
    private let swipeUpThreshold: CGFloat = -80

    var body: some View {
        ZStack(alignment: .bottom) {
            // Photo / gradient background
            photoLayer

            // Like / Pass overlays
            swipeOverlays

            // Bottom info panel
            infoPanel
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .cardShadow()
        .cosmicPurpleGlow(radius: isTop ? 16 : 0)
        .offset(dragOffset)
        .rotationEffect(.degrees(dragAngle))
        .gesture(isTop ? dragGesture : nil)
        .onTapGesture { onTap?() }
        .animation(.interactiveSpring(), value: dragOffset)
        .accessibilityLabel("\(item.user.displayName), \(item.user.age), \(item.cosmicScore)% cosmic match")
    }

    // MARK: - Photo Layer

    private var photoLayer: some View {
        ZStack {
            // Placeholder gradient (replace with SDWebImageSwiftUI in production)
            LinearGradient(
                colors: photoGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Initials placeholder
            Text(item.user.displayName.prefix(1))
                .font(SynergyFont.headline(96))
                .foregroundColor(.white.opacity(0.12))

            // Bottom fade
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, Color.cosmicDark.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 260)
            }
        }
    }

    private var photoGradient: [Color] {
        switch item.user.birthChart.sunSign.element {
        case .fire:  return [Color(hex: "#2D1B1B"), Color(hex: "#3D2612")]
        case .earth: return [Color(hex: "#1A2D1A"), Color(hex: "#1E2D1A")]
        case .air:   return [Color(hex: "#1A1E2D"), Color(hex: "#162030")]
        case .water: return [Color(hex: "#16181F"), Color(hex: "#1A1328")]
        }
    }

    // MARK: - Swipe Overlays

    private var swipeOverlays: some View {
        ZStack {
            // LIKE
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(Color.cosmicSuccess, lineWidth: 3)
                .overlay(
                    VStack {
                        HStack {
                            likeLabel
                                .padding(Spacing.lg)
                            Spacer()
                        }
                        Spacer()
                    }
                )
                .opacity(likeOpacity)

            // PASS
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(Color.cosmicError, lineWidth: 3)
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            passLabel
                                .padding(Spacing.lg)
                        }
                        Spacer()
                    }
                )
                .opacity(passOpacity)

            // SYNASTRY (swipe up)
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(LinearGradient.cosmicGradient, lineWidth: 3)
                .overlay(
                    VStack {
                        Spacer()
                        synastryLabel
                            .padding(.bottom, Spacing.xl)
                    }
                )
                .opacity(synastryHintOpacity)
        }
    }

    private var synastryLabel: some View {
        VStack(spacing: 6) {
            Image(systemName: "chevron.up")
                .font(.system(size: 14, weight: .bold))
            Text("SYNASTRY")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .kerning(2)
        }
        .foregroundStyle(LinearGradient.cosmicGradient)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .overlay(
            Capsule()
                .strokeBorder(LinearGradient.cosmicGradient, lineWidth: 1.5)
        )
    }

    private var likeLabel: some View {
        Text("LIKE")
            .font(SynergyFont.headline(22))
            .foregroundColor(.cosmicSuccess)
            .kerning(3)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .strokeBorder(Color.cosmicSuccess, lineWidth: 2)
            )
            .rotationEffect(.degrees(-15))
    }

    private var passLabel: some View {
        Text("PASS")
            .font(SynergyFont.headline(22))
            .foregroundColor(.cosmicError)
            .kerning(3)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .strokeBorder(Color.cosmicError, lineWidth: 2)
            )
            .rotationEffect(.degrees(15))
    }

    // MARK: - Info Panel

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Name + score
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: Spacing.sm) {
                        Text("\(item.user.displayName), \(item.user.age)")
                            .font(SynergyFont.headline(24))
                            .foregroundColor(.cosmicNeutral)

                        if item.user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.cosmicCyan)
                        }
                    }

                    HStack(spacing: 6) {
                        Text("\(item.user.birthChart.sunSign.symbol) \(item.user.birthChart.sunSign.rawValue)")
                            .font(SynergyFont.body(13))
                            .foregroundColor(.cosmicMuted)

                        Text("·")
                            .foregroundColor(.cosmicBorder)

                        Text("\(item.user.birthChart.risingSign.rawValue) rising")
                            .font(SynergyFont.body(13))
                            .foregroundColor(.cosmicMuted)

                        if let dist = item.user.distanceMiles {
                            Text("· \(String(format: "%.1f", dist)) mi")
                                .font(SynergyFont.body(13))
                                .foregroundColor(.cosmicMuted)
                        }
                    }
                }

                Spacer()

                MatchScoreBadge(score: item.cosmicScore, size: .medium)
            }

            // Transit boost (if active)
            if let boost = item.transitBoost {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.cosmicCyan)
                    Text(boost.description)
                        .font(SynergyFont.body(12))
                        .foregroundColor(.cosmicCyan)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.cosmicCyan.opacity(0.1))
                .clipShape(Capsule())
            }

            // Aspect highlights
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(item.highlights, id: \.self) { h in
                        PlanetAspectTag(text: h, highlighted: true)
                    }
                }
            }

            // Vibe tags
            if !item.user.profile.vibeWords.isEmpty {
                HStack(spacing: Spacing.sm) {
                    ForEach(item.user.profile.vibeWords, id: \.self) { word in
                        Text(word)
                            .font(SynergyFont.body(12))
                            .foregroundColor(.cosmicMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cosmicBorder.opacity(0.5))
                            .clipShape(Capsule())
                    }
                }
            }

            // Swipe-up hint (only on top card)
            if isTop {
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9, weight: .semibold))
                        Text("synastry")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.cosmicMuted.opacity(0.6))
                    Spacer()
                }
            }
        }
        .padding(Spacing.lg)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let isSwipingUp = value.translation.height < 0
                    && abs(value.translation.height) > abs(value.translation.width)
                if isSwipingUp {
                    // Only show synastry hint — no horizontal offset
                    let progress = min(1, -value.translation.height / 120)
                    synastryHintOpacity = Double(progress)
                } else {
                    synastryHintOpacity = 0
                    dragOffset = value.translation
                    dragAngle = Double(value.translation.width / 20)
                    likeOpacity = Double(max(0, value.translation.width / swipeThreshold))
                    passOpacity = Double(max(0, -value.translation.width / swipeThreshold))
                }
            }
            .onEnded { value in
                let w = value.translation.width
                let h = value.translation.height
                let isSwipeUp = h < swipeUpThreshold && abs(w) < 60
                if isSwipeUp {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        synastryHintOpacity = 0
                        dragOffset = .zero
                    }
                    onTap?()   // opens synastry sheet
                } else if w > swipeThreshold {
                    synastryHintOpacity = 0
                    swipeOff(direction: .like)
                } else if w < -swipeThreshold {
                    synastryHintOpacity = 0
                    swipeOff(direction: .pass)
                } else {
                    // Snap back
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dragOffset = .zero
                        dragAngle = 0
                        likeOpacity = 0
                        passOpacity = 0
                        synastryHintOpacity = 0
                    }
                }
            }
    }

    private func swipeOff(direction: SwipeAction) {
        let xOffset: CGFloat = direction == .like ? 600 : -600
        withAnimation(.easeIn(duration: 0.3)) {
            dragOffset = CGSize(width: xOffset, height: -50)
            dragAngle = direction == .like ? 20 : -20
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if direction == .like { onLike?() } else { onPass?() }
            dragOffset = .zero
            dragAngle = 0
            likeOpacity = 0
            passOpacity = 0
        }
    }
}
