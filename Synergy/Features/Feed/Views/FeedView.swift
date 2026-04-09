import SwiftUI

// MARK: - Feed View (Discover tab)

struct FeedView: View {
    @EnvironmentObject var vm: FeedViewModel
    @State private var showSynastrySheet = false

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
            .overlay {
                if vm.showMatchAlert, let match = vm.latestMatch {
                    MatchAlertOverlay(item: match) {
                        vm.showMatchAlert = false
                    }
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
                    // Filter sheet
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
        HStack(spacing: Spacing.xl) {
            // Pass
            CosmicIconButton("xmark", variant: .outlined, size: 60) {
                if let item = vm.visibleItems.first { vm.pass(item) }
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
                    CosmicButton("Send icebreaker", variant: .gradient) { onDismiss() }
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
