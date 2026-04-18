import SwiftUI

// MARK: - Feed View (Discover tab)

struct FeedView: View {
    @EnvironmentObject var vm: FeedViewModel
    @State private var showSynastrySheet = false
    @State private var showDiscoverySettings = false
    @State private var selectedProfileItem: FeedItem? = nil

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
                            .padding(.bottom, 24)
                    }
                }
            }
            .sheet(item: $vm.selectedItem) { item in
                SynastryDetailSheet(item: item)
            }
            .sheet(item: $selectedProfileItem) { item in
                FeedMatchProfileSheet(item: item, onViewSynastry: { vm.selectedItem = item })
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
                    onTap: isTop ? { selectedProfileItem = item } : nil,
                    onSynastry: isTop ? { vm.selectedItem = item } : nil
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
        1.0 - CGFloat(index) * 0.04
    }

    private func cardOffset(for index: Int) -> CGFloat {
        CGFloat(index) * 22
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack {
            deckButton(icon: "xmark", label: "PASS", color: .cosmicError, size: 62) {
                if let item = vm.visibleItems.first { vm.pass(item) }
            }
            Spacer()
            if vm.lastSwipedItem != nil {
                deckButton(icon: "arrow.uturn.backward", label: "UNDO", color: .cosmicMuted, size: 46) {
                    vm.undoLastSwipe()
                }
                .transition(.scale.combined(with: .opacity))
                Spacer()
            }
            deckButton(icon: "star.fill", label: "STAR", color: .cosmicPurple, size: 54) {
                if let item = vm.visibleItems.first { vm.superLike(item) }
            }
            Spacer()
            deckButton(icon: "heart.fill", label: "LIKE", color: .cosmicCyan, size: 62) {
                if let item = vm.visibleItems.first { vm.like(item) }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: vm.lastSwipedItem?.id)
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.xl)
    }

    private func deckButton(icon: String, label: String, color: Color, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: size, height: size)
                    .background(Color.cosmicCard)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(color.opacity(0.35), lineWidth: 1.5))
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(color.opacity(0.7))
                    .kerning(1)
            }
        }
        .buttonStyle(.plain)
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
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 42))
                .foregroundColor(.cosmicCyan.opacity(0.4))
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
    @State private var confettiActive = false
    @State private var scoreBadgeVisible = false
    @State private var avatarScale: CGFloat = 0.6
    @State private var avatarOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: Spacing.xl) {
                // Avatars with score badge
                ZStack {
                    // Two avatar circles overlapping
                    HStack(spacing: -20) {
                        avatarCircle("Y", gradient: LinearGradient.cosmicGradient)
                        avatarCircle(String(item.user.displayName.prefix(1)),
                                     gradient: LinearGradient(colors: [.cosmicPurple, .cosmicCyan],
                                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                    .scaleEffect(avatarScale)
                    .opacity(avatarOpacity)

                    // Score badge floating above
                    MatchScoreBadge(score: item.cosmicScore, size: .medium)
                        .offset(y: -52)
                        .opacity(scoreBadgeVisible ? 1 : 0)
                        .scaleEffect(scoreBadgeVisible ? 1 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.35), value: scoreBadgeVisible)
                }
                .frame(height: 110)

                VStack(spacing: Spacing.sm) {
                    Text("It's a cosmic match!")
                        .font(SynergyFont.headline(26))
                        .foregroundColor(.cosmicNeutral)
                        .multilineTextAlignment(.center)
                    Text("You and \(item.user.displayName) liked each other")
                        .font(SynergyFont.body(15))
                        .foregroundColor(.cosmicMuted)
                        .multilineTextAlignment(.center)

                    if !item.highlights.isEmpty {
                        HStack(spacing: Spacing.sm) {
                            ForEach(item.highlights.prefix(2), id: \.self) { h in
                                PlanetAspectTag(text: h, highlighted: true)
                            }
                        }
                        .padding(.top, 2)
                    }
                }

                VStack(spacing: Spacing.sm) {
                    CosmicButton("Send icebreaker →", variant: .gradient) {
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
            .cosmicPurpleGlow(radius: 30)

            // Confetti on top
            if confettiActive {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0; opacity = 1.0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1)) {
                avatarScale = 1.0; avatarOpacity = 1.0
            }
            scoreBadgeVisible = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                confettiActive = true
            }
        }
    }

    private func avatarCircle(_ initial: String, gradient: LinearGradient) -> some View {
        ZStack {
            Circle()
                .fill(gradient)
                .frame(width: 72, height: 72)
                .overlay(Circle().strokeBorder(Color.cosmicDark, lineWidth: 3))
                .cosmicPurpleGlow(radius: 12)
            Text(initial)
                .font(SynergyFont.headline(28))
                .foregroundColor(.cosmicDark)
        }
    }
}

// MARK: - Synastry Detail Sheet

struct SynastryDetailSheet: View {
    let item: FeedItem
    @Environment(\.dismiss) var dismiss

    var body: some View {
        // No NavigationView wrapper — avoids unwanted horizontal slide animation
        // when the sheet is presented. Custom top bar replaces the nav bar.
        ZStack(alignment: .top) {
            Color.cosmicDark.ignoresSafeArea()
            VStack(spacing: 0) {
                // Custom top bar
                HStack {
                    Text("\(item.user.displayName) · Synastry")
                        .font(SynergyFont.headlineMedium(15))
                        .foregroundColor(.cosmicNeutral)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(SynergyFont.body(14, weight: .semibold))
                        .foregroundColor(.cosmicCyan)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(Color.cosmicDark)
                .overlay(alignment: .bottom) {
                    Divider().overlay(Color.cosmicBorder)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        scoreHeader
                        compositeWheelSection
                        radarSection
                        aspectGridSection
                        layersSection
                        relationshipDomainsSection
                        icebreakerSection
                    }
                    .padding(Spacing.xl)
                    .padding(.bottom, Spacing.xxxl)
                }
            }
        }
    }

    private var scoreHeader: some View {
        VStack(spacing: 0) {
            elementAffinityStrip
            HStack {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("COSMIC MATCH")
                        .systemLabel()
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(item.cosmicScore)")
                            .font(SynergyFont.scoreDisplay)
                            .foregroundColor(.cosmicNeutral)
                        Text("/ 100")
                            .font(SynergyFont.body(16))
                            .foregroundColor(.cosmicMuted)
                    }
                }
                Spacer()
                MatchScoreBadge(score: item.cosmicScore, size: .large)
            }
            .padding(Spacing.lg)
        }
        .cosmicCard()
    }

    private var elementAffinityStrip: some View {
        let matchElement = item.user.birthChart.sunSign.element
        return HStack(spacing: 0) {
            Rectangle().fill(Color.cosmicWater).frame(maxWidth: .infinity)
            Rectangle().fill(elementThemeColor(matchElement)).frame(maxWidth: .infinity)
        }
        .frame(height: 3)
    }

    private func elementThemeColor(_ element: Element) -> Color {
        switch element {
        case .fire:  return .cosmicFire
        case .earth: return .cosmicEarth
        case .air:   return .cosmicAir
        case .water: return .cosmicWater
        }
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

    // MARK: - Relationship Domains

    private var relationshipDomainsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("RELATIONSHIP_DYNAMICS")
                .systemLabel()

            ForEach(relationshipDomains, id: \.title) { domain in
                domainCard(domain)
            }
        }
    }

    private struct RelationshipDomain {
        let title: String
        let icon: String
        let color: Color
        let score: Int
        let summary: String
        let detail: String
    }

    private var relationshipDomains: [RelationshipDomain] {
        let s = item.cosmicScore
        return [
            RelationshipDomain(
                title: "Communication",
                icon: "bubble.left.and.bubble.right.fill",
                color: .cosmicCyan,
                score: min(100, Int(Double(s) * 1.05)),
                summary: communicationSummary,
                detail: "Mercury alignment shapes how you exchange ideas, process conflict, and understand each other's language."
            ),
            RelationshipDomain(
                title: "Intimacy",
                icon: "heart.fill",
                color: Color(hex: "#FF6B9D"),
                score: min(100, Int(Double(s) * 0.98)),
                summary: intimacySummary,
                detail: "Venus and Moon connections determine emotional depth, physical chemistry, and how safe you each feel being vulnerable."
            ),
            RelationshipDomain(
                title: "Growth",
                icon: "arrow.up.forward.circle.fill",
                color: .cosmicSuccess,
                score: min(100, Int(Double(s) * 0.92)),
                summary: growthSummary,
                detail: "Jupiter and Saturn aspects reveal whether this connection expands your world or challenges you to build something lasting."
            ),
            RelationshipDomain(
                title: "Conflict Style",
                icon: "bolt.circle.fill",
                color: Color(hex: "#FFB800"),
                score: min(100, Int(Double(s) * 0.87)),
                summary: conflictSummary,
                detail: "Mars placements show how you each assert needs and navigate disagreement — compatibility here means arguments that actually resolve."
            ),
        ]
    }

    private func domainCard(_ domain: RelationshipDomain) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: domain.icon)
                    .font(.system(size: 14))
                    .foregroundColor(domain.color)
                    .frame(width: 28, height: 28)
                    .background(domain.color.opacity(0.12))
                    .clipShape(Circle())

                Text(domain.title)
                    .font(SynergyFont.body(15, weight: .semibold))
                    .foregroundColor(.cosmicNeutral)

                Spacer()

                Text("\(domain.score)%")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(domain.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(domain.color.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Score bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.cosmicBorder)
                    Capsule()
                        .fill(domain.color.opacity(0.8))
                        .frame(width: geo.size.width * CGFloat(domain.score) / 100)
                }
                .frame(height: 3)
            }
            .frame(height: 3)

            Text(domain.summary)
                .font(SynergyFont.body(13, weight: .medium))
                .foregroundColor(.cosmicNeutral.opacity(0.85))

            Text(domain.detail)
                .font(SynergyFont.body(12))
                .foregroundColor(.cosmicMuted)
                .lineSpacing(3)
        }
        .padding(Spacing.lg)
        .cosmicCard()
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(domain.color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Domain summary text

    private var communicationSummary: String {
        switch item.cosmicScore {
        case 85...: return "Natural frequency match — you'll finish each other's thoughts."
        case 70..<85: return "Strong flow with occasional disconnects that deepen understanding."
        case 55..<70: return "Different styles, but complementary when you slow down to listen."
        default: return "Requires patience — your mental wiring differs, which can spark growth."
        }
    }

    private var intimacySummary: String {
        let user = item.user
        switch user.birthChart.venusSign.element {
        case .water: return "Deep emotional attunement — vulnerability comes naturally here."
        case .fire:  return "Passionate and immediate — the chemistry is hard to miss."
        case .earth: return "Slow-building, sensory, and enduring — it only deepens over time."
        case .air:   return "Intellectual first, physical second — connection lives in the mind."
        }
    }

    private var growthSummary: String {
        switch item.cosmicScore {
        case 80...: return "This connection expands both of you — you'll leave each other changed."
        case 65..<80: return "Meaningful growth potential, especially around shared beliefs."
        default: return "Growth through friction — this connection will test and strengthen you."
        }
    }

    private var conflictSummary: String {
        switch item.cosmicScore {
        case 80...: return "Arguments are rare and resolve quickly — you fight fair."
        case 65..<80: return "Occasional friction that mostly leads to better understanding."
        default: return "Hot-and-cold dynamic — managing Mars energy will be key."
        }
    }

    // MARK: - Current user positions (Scorpio Sun / Pisces Moon, mirrors MockDataService)

    private var currentUserPositions: [PlanetaryPosition] {
        [
            PlanetaryPosition(planet: .sun,     sign: .scorpio,     degree: 222.4, houseNumber: 1,  isRetrograde: false),
            PlanetaryPosition(planet: .moon,    sign: .pisces,      degree: 348.1, houseNumber: 4,  isRetrograde: false),
            PlanetaryPosition(planet: .mercury, sign: .scorpio,     degree: 210.7, houseNumber: 1,  isRetrograde: false),
            PlanetaryPosition(planet: .venus,   sign: .sagittarius, degree: 256.3, houseNumber: 2,  isRetrograde: false),
            PlanetaryPosition(planet: .mars,    sign: .capricorn,   degree: 295.8, houseNumber: 3,  isRetrograde: false),
        ]
    }

    // MARK: - Composite Wheel Section

    private var compositeWheelSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("COMPOSITE_WHEEL")
                .systemLabel()

            HStack(spacing: Spacing.lg) {
                legendPill(color: .cosmicCyan, label: "You")
                legendPill(color: Color(hex: "#FF6B9D"), label: item.user.displayName)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    legendPill(color: .cosmicSuccess, label: "Harmonious")
                    legendPill(color: .cosmicError,   label: "Challenging")
                }
            }

            HStack {
                Spacer()
                SynastryCompositeWheelView(
                    userPositions: currentUserPositions,
                    matchPositions: item.user.birthChart.positions
                )
                Spacer()
            }
            .padding(.vertical, Spacing.sm)
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }

    private func legendPill(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(SynergyFont.body(11))
                .foregroundColor(.cosmicMuted)
        }
    }

    // MARK: - Aspect Grid Section

    private var aspectGridSection: some View {
        let gridPlanets: [Planet] = [.sun, .moon, .venus, .mars]
        let userPos  = currentUserPositions
        let matchPos = item.user.birthChart.positions

        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text("ASPECT_GRID")
                .systemLabel()

            HStack(spacing: 3) {
                Text("You ↓")
                    .font(SynergyFont.body(11, weight: .medium))
                    .foregroundColor(.cosmicCyan)
                Text("·")
                    .font(SynergyFont.body(11))
                    .foregroundColor(.cosmicMuted)
                Text("\(item.user.displayName) →")
                    .font(SynergyFont.body(11, weight: .medium))
                    .foregroundColor(Color(hex: "#FF6B9D"))
            }

            // Header row
            HStack(spacing: 0) {
                Color.clear.frame(width: 34, height: 30)
                ForEach(gridPlanets, id: \.self) { p in
                    Text(p.symbol)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#FF6B9D").opacity(0.85))
                        .frame(maxWidth: .infinity)
                }
            }

            Divider().overlay(Color.cosmicBorder.opacity(0.6))

            ForEach(Array(gridPlanets.enumerated()), id: \.element) { rowIdx, uPlanet in
                let uDeg = userPos.first(where: { $0.planet == uPlanet })?.degree ?? 0
                HStack(spacing: 0) {
                    Text(uPlanet.symbol)
                        .font(.system(size: 14))
                        .foregroundColor(Color.cosmicCyan.opacity(0.85))
                        .frame(width: 34)

                    ForEach(gridPlanets, id: \.self) { mPlanet in
                        let mDeg = matchPos.first(where: { $0.planet == mPlanet })?.degree ?? 0
                        aspectGridCell(aspect: synastryAspect(degA: uDeg, degB: mDeg))
                            .frame(maxWidth: .infinity)
                    }
                }
                if rowIdx < gridPlanets.count - 1 {
                    Divider().overlay(Color.cosmicBorder.opacity(0.25))
                }
            }
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }

    private func aspectGridCell(aspect: AspectType?) -> some View {
        VStack(spacing: 1) {
            if let asp = aspect {
                Text(asp.symbol)
                    .font(.system(size: 16))
                    .foregroundColor(asp.isHarmonious ? .cosmicSuccess : .cosmicError)
                Text(String(asp.rawValue.prefix(3)).uppercased())
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .foregroundColor((asp.isHarmonious ? Color.cosmicSuccess : Color.cosmicError).opacity(0.65))
            } else {
                Text("—")
                    .font(.system(size: 14))
                    .foregroundColor(.cosmicBorder)
                    .padding(.bottom, 10)
            }
        }
        .frame(height: 44)
        .background(aspectCellBackground(aspect: aspect))
    }

    @ViewBuilder
    private func aspectCellBackground(aspect: AspectType?) -> some View {
        if let asp = aspect {
            RoundedRectangle(cornerRadius: 4)
                .fill((asp.isHarmonious ? Color.cosmicSuccess : Color.cosmicError).opacity(0.07))
        }
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

// MARK: - Feed Match Profile Sheet (FeedItem-based; distinct from chat MatchProfileSheet which takes User)

struct FeedMatchProfileSheet: View {
    let item: FeedItem
    var onViewSynastry: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            photoSection
                            infoSection
                                .padding(Spacing.xl)
                        }
                        .padding(.bottom, 120)
                    }
                    actionBar
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Photo area

    private var photoSection: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: elementGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 340)
            .overlay(
                Text(item.user.displayName.prefix(1))
                    .font(SynergyFont.headline(110))
                    .foregroundColor(.white.opacity(0.1))
            )

            LinearGradient(
                colors: [.clear, Color.cosmicDark],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 340)

            // Dismiss + synastry quick buttons
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Button { dismiss(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onViewSynastry?() } } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.right.circle.fill").font(.system(size: 12))
                            Text("Synastry").font(.system(size: 12, weight: .semibold, design: .monospaced))
                        }
                        .foregroundColor(.cosmicCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.md)
                Spacer()
            }
            .frame(height: 340)
        }
    }

    private var elementGradient: [Color] {
        switch item.user.birthChart.sunSign.element {
        case .fire:  return [Color(hex: "#2D1B1B"), Color(hex: "#3D2612")]
        case .earth: return [Color(hex: "#1A2D1A"), Color(hex: "#1E2D1A")]
        case .air:   return [Color(hex: "#1A1E2D"), Color(hex: "#162030")]
        case .water: return [Color(hex: "#16181F"), Color(hex: "#1A1328")]
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Name + score + basics
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(item.user.displayName), \(item.user.age)")
                        .font(SynergyFont.headline(28))
                        .foregroundColor(.cosmicNeutral)
                    if item.user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.cosmicCyan)
                    }
                    Spacer()
                    MatchScorePill(score: item.cosmicScore)
                }
                HStack(spacing: 6) {
                    Text("\(item.user.birthChart.sunSign.symbol) \(item.user.birthChart.sunSign.rawValue)")
                    Text("·")
                    Text("\(item.user.birthChart.risingSign.rawValue) rising")
                    if let dist = item.user.distanceMiles {
                        Text("· \(String(format: "%.0f", dist)) mi")
                    }
                }
                .font(SynergyFont.body(13))
                .foregroundColor(.cosmicMuted)
            }

            // Vibe words
            if !item.user.profile.vibeWords.isEmpty {
                HStack(spacing: 6) {
                    ForEach(item.user.profile.vibeWords, id: \.self) { word in
                        Text(word)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Color.white.opacity(0.07)).clipShape(Capsule())
                    }
                }
            }

            // Transit boost
            if let boost = item.transitBoost {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.right.circle.fill").font(.system(size: 10))
                    Text(boost.description).font(SynergyFont.body(11))
                }
                .foregroundColor(Color(hex: "#00F0FF"))
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(Color(hex: "#00F0FF").opacity(0.10)).clipShape(Capsule())
            }

            // All prompts (Hinge-style)
            if !item.user.profile.prompts.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(item.user.profile.prompts.indices, id: \.self) { idx in
                        if idx > 0 { Divider().overlay(Color.cosmicBorder.opacity(0.4)) }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.user.profile.prompts[idx].question.uppercased())
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundColor(.cosmicMuted)
                                .kerning(0.5)
                            Text("\u{201C}\(item.user.profile.prompts[idx].answer)\u{201D}")
                                .font(SynergyFont.body(15))
                                .foregroundColor(.cosmicNeutral)
                                .lineSpacing(4)
                        }
                        .padding(.vertical, Spacing.md)
                    }
                }
                .padding(Spacing.lg)
                .cosmicCard()
            }

            // Chart big three
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("NATAL_CHART").systemLabel()
                HStack(spacing: 0) {
                    chartItem("☉", label: "Sun",    value: item.user.birthChart.sunSign.rawValue)
                    Divider().overlay(Color.cosmicBorder).frame(height: 40)
                    chartItem("☽", label: "Moon",   value: item.user.birthChart.moonSign.rawValue)
                    Divider().overlay(Color.cosmicBorder).frame(height: 40)
                    chartItem("AC", label: "Rising", value: item.user.birthChart.risingSign.rawValue)
                }
                .padding(.vertical, Spacing.sm)
            }
            .padding(Spacing.lg)
            .cosmicCard()
        }
    }

    private func chartItem(_ symbol: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(symbol).font(.system(size: 18)).foregroundColor(.cosmicCyan)
            Text(value).font(SynergyFont.headlineMedium(13)).foregroundColor(.cosmicNeutral)
            Text(label.uppercased()).systemLabel()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action bar

    private var actionBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.cosmicBorder)
            HStack(spacing: Spacing.xl) {
                Button { dismiss(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { /* pass handled via deck */ } } label: {
                    VStack(spacing: 5) {
                        Image(systemName: "xmark")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.cosmicError)
                            .frame(width: 58, height: 58)
                            .background(Color.cosmicCard)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color.cosmicError.opacity(0.35), lineWidth: 1.5))
                        Text("PASS").font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.cosmicError.opacity(0.7)).kerning(1)
                    }
                }.buttonStyle(.plain)

                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onViewSynastry?() }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(LinearGradient.cosmicGradient)
                            .frame(width: 52, height: 52)
                            .background(Color.cosmicCard)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color.cosmicPurple.opacity(0.4), lineWidth: 1.5))
                        Text("SYNASTRY").font(.system(size: 9, weight: .bold, design: .monospaced))
                            .kerning(1)
                            .foregroundStyle(LinearGradient.cosmicGradient)
                    }
                }.buttonStyle(.plain)

                Button { dismiss() } label: {
                    VStack(spacing: 5) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.cosmicCyan)
                            .frame(width: 58, height: 58)
                            .background(Color.cosmicCard)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color.cosmicCyan.opacity(0.35), lineWidth: 1.5))
                        Text("LIKE").font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.cosmicCyan.opacity(0.7)).kerning(1)
                    }
                }.buttonStyle(.plain)
            }
            .padding(.vertical, Spacing.lg)
            .padding(.horizontal, Spacing.xxxl)
            .background(Color.cosmicDark)
        }
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

// MARK: - Synastry Composite Wheel

private struct SynastryCompositeWheelView: View {
    let userPositions: [PlanetaryPosition]
    let matchPositions: [PlanetaryPosition]

    private let size: CGFloat    = 240
    private let outerR: CGFloat  = 108   // outer zodiac ring edge
    private let innerR: CGFloat  = 86    // inner zodiac ring edge
    private let matchDotR: CGFloat = 73  // match planet orbit
    private let userDotR: CGFloat  = 55  // current-user planet orbit

    private let zodiacGlyphs = ["♈\u{FE0E}","♉\u{FE0E}","♊\u{FE0E}","♋\u{FE0E}","♌\u{FE0E}","♍\u{FE0E}","♎\u{FE0E}","♏\u{FE0E}","♐\u{FE0E}","♑\u{FE0E}","♒\u{FE0E}","♓\u{FE0E}"]
    private let personalPlanets: [Planet] = [.sun, .moon, .venus, .mars, .mercury, .ascendant]

    private var half: CGFloat { size / 2 }

    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(Color.cosmicDarkAlt)
                .frame(width: size, height: size)

            // Ring geometry (Canvas — no layout overhead)
            wheelRingCanvas

            // Zodiac glyphs
            ForEach(0..<12, id: \.self) { i in
                let a = segMidAngle(i)
                let r = (outerR + innerR) / 2
                Text(zodiacGlyphs[i])
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.cosmicNeutral.opacity(0.75))
                    .position(x: half + r * cos(a), y: half + r * sin(a))
            }

            // Aspect lines
            aspectLinesCanvas

            // Orbit separator
            Circle()
                .stroke(Color.cosmicBorder.opacity(0.2), lineWidth: 1)
                .frame(width: (userDotR + matchDotR), height: (userDotR + matchDotR))

            // Match planets (outer orbit — pink)
            ForEach(matchPositions.filter { personalPlanets.contains($0.planet) }) { pos in
                planetDot(pos: pos, color: Color(hex: "#FF6B9D"), radius: matchDotR)
            }

            // User planets (inner orbit — cyan)
            ForEach(userPositions.filter { personalPlanets.contains($0.planet) }) { pos in
                planetDot(pos: pos, color: .cosmicCyan, radius: userDotR)
            }

            // Centre glyph
            Circle()
                .fill(Color.cosmicDark)
                .frame(width: 30, height: 30)
            Text("✦")
                .font(.system(size: 11))
                .foregroundStyle(LinearGradient.cosmicGradient)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color.cosmicBorder.opacity(0.35), lineWidth: 1))
    }

    // Angle helpers (0° ecliptic → top of wheel, clockwise)
    private func degToAngle(_ deg: Double) -> CGFloat {
        CGFloat((deg / 360.0 - 0.25) * 2.0 * .pi)
    }
    private func segStartAngle(_ i: Int) -> CGFloat {
        CGFloat((Double(i) / 12.0 - 0.25) * 2.0 * .pi)
    }
    private func segMidAngle(_ i: Int) -> CGFloat {
        CGFloat((Double(i) / 12.0 + 1.0 / 24.0 - 0.25) * 2.0 * .pi)
    }

    // Zodiac ring + segment lines via Canvas
    private var wheelRingCanvas: some View {
        let outerR = self.outerR, innerR = self.innerR, half = self.half
        return Canvas { ctx, sz in
            let cx = sz.width / 2, cy = sz.height / 2

            // Outer ring stroke
            ctx.stroke(
                Path(ellipseIn: CGRect(x: cx - outerR, y: cy - outerR, width: outerR * 2, height: outerR * 2)),
                with: .color(Color.cosmicBorder.opacity(0.3)), lineWidth: 1
            )
            // Inner ring stroke
            ctx.stroke(
                Path(ellipseIn: CGRect(x: cx - innerR, y: cy - innerR, width: innerR * 2, height: innerR * 2)),
                with: .color(Color.cosmicBorder.opacity(0.25)), lineWidth: 1
            )
            // 12 segment dividers
            for i in 0..<12 {
                let a = Double((Double(i) / 12.0 - 0.25) * 2.0 * .pi)
                var p = Path()
                p.move(to: CGPoint(x: cx + innerR * CGFloat(cos(a)), y: cy + innerR * CGFloat(sin(a))))
                p.addLine(to: CGPoint(x: cx + outerR * CGFloat(cos(a)), y: cy + outerR * CGFloat(sin(a))))
                ctx.stroke(p, with: .color(Color.cosmicBorder.opacity(0.3)), lineWidth: 0.5)
            }
            // Degree tick marks (every 30° on outer edge)
            for i in 0..<12 {
                let a = Double((Double(i) / 12.0 - 0.25) * 2.0 * .pi)
                var tick = Path()
                tick.move(to: CGPoint(x: cx + outerR * CGFloat(cos(a)), y: cy + outerR * CGFloat(sin(a))))
                tick.addLine(to: CGPoint(x: cx + (outerR + 4) * CGFloat(cos(a)), y: cy + (outerR + 4) * CGFloat(sin(a))))
                ctx.stroke(tick, with: .color(Color.cosmicBorder.opacity(0.4)), lineWidth: 1)
            }
            _ = half // suppress capture warning
        }
        .frame(width: size, height: size)
    }

    // Aspect lines between both charts
    private var aspectLinesCanvas: some View {
        let uFiltered = userPositions.filter  { personalPlanets.contains($0.planet) }
        let mFiltered = matchPositions.filter { personalPlanets.contains($0.planet) }
        let cx = half, cy = half
        let uR = userDotR, mR = matchDotR
        return Canvas { ctx, _ in
            for u in uFiltered {
                for m in mFiltered {
                    guard let asp = synastryAspect(degA: u.degree, degB: m.degree) else { continue }
                    let ua = CGFloat((u.degree / 360.0 - 0.25) * 2.0 * .pi)
                    let ma = CGFloat((m.degree / 360.0 - 0.25) * 2.0 * .pi)
                    let uPt = CGPoint(x: cx + uR * cos(ua), y: cy + uR * sin(ua))
                    let mPt = CGPoint(x: cx + mR * cos(ma), y: cy + mR * sin(ma))
                    var path = Path(); path.move(to: uPt); path.addLine(to: mPt)
                    let c: Color = asp.isHarmonious ? .cosmicSuccess : .cosmicError
                    ctx.stroke(path, with: .color(c.opacity(0.28)), lineWidth: 1)
                }
            }
        }
        .frame(width: size, height: size)
    }

    private func planetDot(pos: PlanetaryPosition, color: Color, radius: CGFloat) -> some View {
        let a = degToAngle(pos.degree)
        let x = half + radius * cos(a)
        let y = half + radius * sin(a)
        return ZStack {
            Circle()
                .fill(color)
                .frame(width: 17, height: 17)
                .shadow(color: color.opacity(0.6), radius: 3)
            Text(pos.planet.symbol)
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(.cosmicDark)
        }
        .position(x: x, y: y)
    }
}

// MARK: - Aspect computation (file-private helper)

private func synastryAspect(degA: Double, degB: Double) -> AspectType? {
    var diff = abs(degA - degB).truncatingRemainder(dividingBy: 360)
    if diff > 180 { diff = 360 - diff }
    for type: AspectType in [.conjunction, .opposition, .trine, .square, .sextile, .quincunx] {
        if abs(diff - type.angle) <= type.orb { return type }
    }
    return nil
}
