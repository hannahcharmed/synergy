import SwiftUI

// MARK: - Feed View (Discover tab)

struct FeedView: View {
    @EnvironmentObject var vm: FeedViewModel
    @State private var showSynastrySheet = false
    @State private var showDiscoverySettings = false

    var body: some View {
        // iOS 15: NavigationView + .navigationViewStyle(.stack)
        // iOS 16+: replace with NavigationStack (see SynergyApp.swift note)
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()

                VStack(spacing: 0) {
                    feedNavBar

                    if vm.isLoading {
                        loadingState
                    } else if vm.isEmpty {
                        emptyState
                    } else {
                        cardDeck
                        actionButtons
                            .padding(.bottom, 100)
                    }
                }
            }
            .sheet(item: $vm.selectedItem) { item in
                SynastryDetailSheet(item: item)
            }
            .sheet(isPresented: $showDiscoverySettings) {
                DiscoverySettingsSheet()
            }
            .overlay {
                if vm.showMatchAlert, let match = vm.latestMatch {
                    MatchAlertOverlay(
                        item: match,
                        onDismiss: { vm.showMatchAlert = false },
                        onSendIcebreaker: { icebreakerText in
                            vm.showMatchAlert = false
                            vm.pendingIcebreakerText = icebreakerText
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4), value: vm.showMatchAlert)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Nav Bar

    private var feedNavBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SYNERGY")
                    .font(SynergyFont.headline(20))
                    .foregroundColor(.cosmicNeutral)
                    .kerning(4)
                Text("discover")
                    .systemLabel()
                    .foregroundColor(.cosmicCyan.opacity(0.8))
            }

            Spacer()

            HStack(spacing: Spacing.md) {
                CosmicIconButton("slider.horizontal.3") {
                    showDiscoverySettings = true
                }

                CosmicIconButton("arrow.counterclockwise") {
                    vm.refreshFeed()
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Card Deck

    private var cardDeck: some View {
        ZStack {
            ForEach(Array(vm.visibleItems.enumerated().reversed()), id: \.element.id) { index, item in
                let isTop = index == 0
                MatchCardView(
                    item: item,
                    isTop: isTop,
                    onLike: { vm.like(item) },
                    onPass: { vm.pass(item) },
                    onTap: isTop ? { vm.selectedItem = item } : nil
                )
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Spacing.xl)
                .scaleEffect(cardScale(for: index))
                .offset(y: cardOffset(for: index))
                .zIndex(Double(vm.visibleItems.count - index))
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.vertical, Spacing.md)
    }

    private func cardScale(for index: Int) -> CGFloat {
        1.0 - CGFloat(index) * 0.03
    }

    private func cardOffset(for index: Int) -> CGFloat {
        CGFloat(index) * 12
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            // Undo hint label (shown when undo is available)
            if vm.lastSwipedItem != nil {
                Text("Tap \u{21BA} to undo your last pass")
                    .font(SynergyFont.body(11))
                    .foregroundColor(.cosmicMuted)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack(spacing: Spacing.xl) {
                // Pass
                CosmicIconButton("xmark", variant: .outlined, size: 60) {
                    if let item = vm.visibleItems.first { vm.pass(item) }
                }

                // Undo last pass (only visible when available)
                if vm.lastSwipedItem != nil {
                    CosmicIconButton("arrow.uturn.backward", variant: .gradient, size: 44) {
                        vm.undoLastSwipe()
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Super Like (star)
                CosmicIconButton("star.fill", variant: .gradient, size: 52) {
                    if let item = vm.visibleItems.first { vm.superLike(item) }
                }

                // Like
                CosmicIconButton("heart.fill", variant: .outlined, size: 60) {
                    if let item = vm.visibleItems.first { vm.like(item) }
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: vm.lastSwipedItem?.id)
        .padding(.vertical, Spacing.lg)
    }

    // MARK: - Loading / Empty

    private var loadingState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            ProgressView().tint(.cosmicCyan).scaleEffect(1.5)
            Text("Calculating cosmic alignments...")
                .font(SynergyFont.body(14))
                .foregroundColor(.cosmicMuted)
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Text("✦")
                .font(.system(size: 48))
                .foregroundColor(.cosmicCyan.opacity(0.5))
            Text("You've seen everyone nearby")
                .font(SynergyFont.headline(20))
                .foregroundColor(.cosmicNeutral)
            Text("More cosmic matches are on the way. The stars are aligning.")
                .font(SynergyFont.body(14))
                .foregroundColor(.cosmicMuted)
                .multilineTextAlignment(.center)
            CosmicButton("Refresh feed", variant: .outlined) { vm.refreshFeed() }
                .padding(.horizontal, Spacing.xxxl)
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Match Alert Overlay

struct MatchAlertOverlay: View {
    let item: FeedItem
    let onDismiss: () -> Void
    var onSendIcebreaker: ((String) -> Void)? = nil

    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: Spacing.xl) {
                // Glow orb
                ZStack {
                    Circle()
                        .fill(LinearGradient.cosmicGradient)
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)
                    Text("✦")
                        .font(.system(size: 48))
                        .foregroundColor(.cosmicNeutral)
                }

                VStack(spacing: Spacing.sm) {
                    Text("It's a cosmic match!")
                        .font(SynergyFont.headline(28))
                        .foregroundColor(.cosmicNeutral)
                    Text("You and \(item.user.displayName) liked each other")
                        .font(SynergyFont.body(15))
                        .foregroundColor(.cosmicMuted)
                    MatchScorePill(score: item.cosmicScore)
                }

                VStack(spacing: Spacing.sm) {
                    CosmicButton("Send icebreaker", variant: .gradient) {
                        onSendIcebreaker?(item.aiIcebreaker)
                    }
                    Button("Keep exploring") { onDismiss() }
                        .font(SynergyFont.body(14))
                        .foregroundColor(.cosmicMuted)
                }
                .padding(.horizontal, Spacing.xl)
            }
            .padding(Spacing.xl)
            .background(Color.cosmicCard)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl)
                    .strokeBorder(LinearGradient.cosmicGradient, lineWidth: 1.5)
            )
            .padding(.horizontal, Spacing.xl)
            .scaleEffect(scale)
            .opacity(opacity)
            .cosmicPurpleGlow(radius: 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0; opacity = 1.0
            }
        }
    }
}

// MARK: - Synastry Detail Sheet

struct SynastryDetailSheet: View {
    let item: FeedItem
    @Environment(\.dismiss) var dismiss

    var body: some View {
        // iOS 15: NavigationView + .navigationViewStyle(.stack)
        // iOS 16+: replace with NavigationStack (see SynergyApp.swift note)
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    scoreHeader
                    radarSection
                    layersSection
                    aspectsSection
                    icebreakerSection
                }
                .padding(Spacing.xl)
            }
            .background(Color.cosmicDark)
            .navigationTitle("\(item.user.displayName) · Synastry")
            .navigationBarTitleDisplayMode(.inline)
            // iOS 16+: restore .toolbarBackground / .toolbarColorScheme
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(SynergyFont.body(14))
                        .foregroundColor(.cosmicCyan)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var scoreHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("COSMIC_MATCH_SCORE™")
                    .systemLabel()
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(item.cosmicScore)")
                        .font(SynergyFont.scoreDisplay)
                        .foregroundColor(.cosmicNeutral)
                    Text("/ 100")
                        .font(SynergyFont.body(16))
                        .foregroundColor(.cosmicMuted)
                }
                HStack(spacing: Spacing.sm) {
                    ForEach(item.highlights.prefix(2), id: \.self) { h in
                        PlanetAspectTag(text: h, highlighted: true)
                    }
                }
            }
            Spacer()
            MatchScoreBadge(score: item.cosmicScore, size: .large)
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }

    private var radarSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("COMPATIBILITY_RADAR")
                .systemLabel()
            HStack {
                Spacer()
                RadarChartView.fromSynastry(score: item.cosmicScore)
                Spacer()
            }
            .padding(.vertical, Spacing.sm)
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }

    private var layersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("SCORE_BREAKDOWN")
                .systemLabel()

            let layers: [(String, Int, Int)] = [
                ("Synastry Core", Int(Double(item.cosmicScore) * 0.40), 40),
                ("Elemental Balance", Int(Double(item.cosmicScore) * 0.25), 25),
                ("Intent Alignment", Int(Double(item.cosmicScore) * 0.20), 20),
                ("Transit Modifiers", Int(Double(item.cosmicScore) * 0.15), 15),
            ]

            ForEach(layers, id: \.0) { name, score, weight in
                layerRow(name: name, score: score, weight: weight)
            }
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }

    private func layerRow(name: String, score: Int, weight: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(SynergyFont.body(14, weight: .medium))
                    .foregroundColor(.cosmicNeutral)
                Spacer()
                Text("\(score) pts · \(weight)%")
                    .systemLabel()
                    .foregroundColor(.cosmicCyan)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.cosmicBorder)
                    Capsule()
                        .fill(LinearGradient.scoreGlow)
                        .frame(width: g.size.width * CGFloat(score) / 100)
                }
                .frame(height: 4)
            }
            .frame(height: 4)
        }
    }

    private var aspectsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("KEY_ASPECTS")
                .systemLabel()

            let aspects: [(String, String, Bool)] = [
                ("Venus △ Venus",   "Trine — deep romantic harmony", true),
                ("☽ Moon ☌ Moon",  "Conjunction — emotional resonance", true),
                ("☉ Sun ⚹ ☽ Moon", "Sextile — natural understanding", true),
                ("♂ Mars □ ♄ Saturn", "Square — productive tension", false),
            ]

            ForEach(aspects, id: \.0) { name, desc, positive in
                HStack(spacing: Spacing.md) {
                    Circle()
                        .fill(positive ? Color.cosmicSuccess : Color.cosmicError)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(SynergyFont.body(14, weight: .medium))
                            .foregroundColor(.cosmicNeutral)
                        Text(desc)
                            .font(SynergyFont.body(12))
                            .foregroundColor(.cosmicMuted)
                    }
                    Spacer()
                }
            }
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }

    private var icebreakerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("AI_ICEBREAKER")
                .systemLabel()
            Text("\u{201C}\(item.aiIcebreaker)\u{201D}")
                .font(SynergyFont.body(15))
                .foregroundColor(.cosmicNeutral)
                .lineSpacing(5)
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }
}

// MARK: - Radar Chart (appended here so Xcode project can find it)

private struct RadarChartView: View {
    struct Axis {
        let label: String
        let value: Double   // 0.0 – 1.0
        let color: Color
    }

    let axes: [Axis]
    var animated: Bool = true

    @State private var progress: Double = 0

    private let sides: Int = 5
    private let gridLevels: Int = 4

    var body: some View {
        ZStack {
            // Grid rings
            ForEach(1...gridLevels, id: \.self) { level in
                RadarPolygonShape(sides: sides, scale: Double(level) / Double(gridLevels))
                    .stroke(Color.cosmicBorder, lineWidth: 1)
                    .opacity(0.4)
            }

            // Axis lines
            ForEach(0..<sides, id: \.self) { i in
                Path { p in
                    p.move(to: radarCenter)
                    p.addLine(to: radarPoint(index: i, scale: 1.0))
                }
                .stroke(Color.cosmicBorder, lineWidth: 1)
                .opacity(0.3)
            }

            // Filled area
            radarFilledPolygon
                .fill(LinearGradient.cosmicGradient)
                .opacity(0.25)
            radarFilledPolygon
                .stroke(LinearGradient.cosmicGradient, lineWidth: 2)

            // Axis labels
            ForEach(0..<min(sides, axes.count), id: \.self) { i in
                radarAxisLabel(index: i)
            }

            // Value dots
            ForEach(0..<min(sides, axes.count), id: \.self) { i in
                Circle()
                    .fill(axes[i].color)
                    .frame(width: 8, height: 8)
                    .position(radarPoint(index: i, scale: axes[i].value * progress))
                    .cosmicGlow(color: axes[i].color, radius: 6)
            }
        }
        .frame(width: 220, height: 220)
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 0.8).delay(0.1)) { progress = 1 }
            } else {
                progress = 1
            }
        }
    }

    private let radarSize: CGFloat = 220
    private var radarCenter: CGPoint { CGPoint(x: radarSize / 2, y: radarSize / 2) }
    private var radarRadius: CGFloat { radarSize / 2 - 28 }

    private func radarPoint(index: Int, scale: Double) -> CGPoint {
        let angle = (2 * .pi / Double(sides)) * Double(index) - .pi / 2
        return CGPoint(
            x: radarCenter.x + CGFloat(cos(angle) * Double(radarRadius) * scale),
            y: radarCenter.y + CGFloat(sin(angle) * Double(radarRadius) * scale)
        )
    }

    private var radarFilledPolygon: Path {
        Path { path in
            guard !axes.isEmpty else { return }
            let first = radarPoint(index: 0, scale: axes[0].value * progress)
            path.move(to: first)
            for i in 1..<min(sides, axes.count) {
                path.addLine(to: radarPoint(index: i, scale: axes[i].value * progress))
            }
            path.closeSubpath()
        }
    }

    @ViewBuilder
    private func radarAxisLabel(index: Int) -> some View {
        let pt = radarPoint(index: index, scale: 1.28)
        Text(axes[index].label)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundColor(.cosmicMuted)
            .multilineTextAlignment(.center)
            .frame(width: 52)
            .position(pt)
    }

    static func fromSynastry(score: Int) -> RadarChartView {
        let s = Double(score) / 100
        return RadarChartView(axes: [
            Axis(label: "SYNASTRY\nCORE",   value: s * 1.00, color: .cosmicPurple),
            Axis(label: "ELEMENTAL",         value: s * 0.90, color: .cosmicCyan),
            Axis(label: "INTENT\nALIGN",     value: s * 0.85, color: .cosmicSuccess),
            Axis(label: "TRANSIT\nBOOST",    value: s * 0.70, color: Color(hex: "#FFD700")),
            Axis(label: "VENUS\n+ MOON",     value: s * 0.95, color: Color(hex: "#FF6B9D")),
        ])
    }
}

private struct RadarPolygonShape: Shape {
    let sides: Int
    let scale: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2 * CGFloat(scale)
        var path = Path()
        for i in 0..<sides {
            let angle = (2 * .pi / Double(sides)) * Double(i) - .pi / 2
            let pt = CGPoint(x: center.x + r * CGFloat(cos(angle)),
                             y: center.y + r * CGFloat(sin(angle)))
            i == 0 ? path.move(to: pt) : path.addLine(to: pt)
        }
        path.closeSubpath()
        return path
    }
}
