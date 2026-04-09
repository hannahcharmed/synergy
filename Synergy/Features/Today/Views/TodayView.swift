import SwiftUI

// MARK: - Today Tab — Horoscope + Ritual Engine

struct TodayView: View {
    @EnvironmentObject var vm: TodayViewModel
    @State private var selectedRitual: RitualEvent? = nil

    var body: some View {
        // iOS 15: NavigationView + .navigationViewStyle(.stack)
        // iOS 16+: replace with NavigationStack (see SynergyApp.swift note)
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()

                if vm.isLoading {
                    loadingView
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            todayNavBar

                            if let h = vm.horoscope {
                                cosmicWeatherBanner(h)
                                horoscopeCard(h)
                            }

                            if !vm.activeRituals.isEmpty {
                                ritualSection(title: "ACTIVE_RITUALS", events: vm.activeRituals)
                            }
                            if !vm.alignedMatches.isEmpty {
                                alignedMatchesSection
                            }
                            if !vm.upcomingRituals.isEmpty {
                                ritualSection(title: "UPCOMING", events: vm.upcomingRituals)
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, Spacing.xl)
                    }
                }
            }
            .sheet(item: $selectedRitual) { ritual in
                RitualDetailSheet(ritual: ritual)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Nav Bar

    private var todayNavBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today")
                    .font(SynergyFont.headline(24))
                    .foregroundColor(.cosmicNeutral)

                if let h = vm.horoscope {
                    Text(h.dateFormatted.uppercased())
                        .systemLabel()
                        .foregroundColor(.cosmicMuted)
                }
            }

            Spacer()

            // Moon phase icon
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 22))
                .foregroundStyle(LinearGradient.cosmicGradient)
                .cosmicPurpleGlow(radius: 8)
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Cosmic Weather Banner

    private func cosmicWeatherBanner(_ h: Horoscope) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: h.cosmicWeather.mood.icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: h.cosmicWeather.mood.color))
                .frame(width: 40, height: 40)
                .background(Color(hex: h.cosmicWeather.mood.color).opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("COSMIC_WEATHER")
                    .systemLabel()
                Text(h.cosmicWeather.dominantTransit)
                    .font(SynergyFont.body(14, weight: .medium))
                    .foregroundColor(.cosmicNeutral)
            }

            Spacer()

            // Intensity meter
            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { i in
                    Capsule()
                        .fill(i <= h.cosmicWeather.intensityLevel
                              ? Color(hex: h.cosmicWeather.mood.color)
                              : Color.cosmicBorder)
                        .frame(width: 6, height: 14 + CGFloat(i) * 3)
                }
            }
        }
        .padding(Spacing.md)
        .cosmicCard()
    }

    // MARK: - Horoscope Card

    private func horoscopeCard(_ h: Horoscope) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DAILY_READING")
                        .systemLabel()
                    Text(h.headline)
                        .font(SynergyFont.headlineMedium(17))
                        .foregroundColor(.cosmicNeutral)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(.cosmicCyan)
                    .cosmicGlow(color: .cosmicCyan, radius: 8)
            }

            // Body text
            Text(h.content)
                .font(SynergyFont.body(15))
                .foregroundColor(.cosmicNeutral.opacity(0.8))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(Color.cosmicBorder)

            // Lucky aspects
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("LUCKY_ASPECTS")
                    .systemLabel()
                ForEach(h.luckyAspects, id: \.self) { aspect in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.cosmicCyan)
                        Text(aspect)
                            .font(SynergyFont.body(13))
                            .foregroundColor(.cosmicNeutral.opacity(0.7))
                    }
                }
            }

            // Model attribution
            HStack {
                Spacer()
                Text("generated by \(h.modelVersion)")
                    .systemLabel()
                    .foregroundColor(.cosmicMuted.opacity(0.5))
            }
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }

    // MARK: - Ritual Section

    private func ritualSection(title: String, events: [RitualEvent]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .systemLabel()

            ForEach(events) { ritual in
                RitualCard(ritual: ritual)
                    .onTapGesture { selectedRitual = ritual }
            }
        }
    }

    // MARK: - Aligned Matches

    private var alignedMatchesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("ALIGNED_TODAY")
                    .systemLabel()
                Spacer()
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.cosmicCyan)
                Text("transit active")
                    .systemLabel()
                    .foregroundColor(.cosmicCyan)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(vm.alignedMatches) { item in
                        AlignedMatchChip(item: item)
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView().tint(.cosmicCyan).scaleEffect(1.3)
            Text("Reading the stars...")
                .font(SynergyFont.body(14))
                .foregroundColor(.cosmicMuted)
        }
    }
}

// MARK: - Ritual Card

struct RitualCard: View {
    let ritual: RitualEvent

    private var accentColor: Color { Color(hex: ritual.type.color) }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Image(systemName: ritual.type.icon)
                .font(.system(size: 20))
                .foregroundColor(accentColor)
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(ritual.title)
                        .font(SynergyFont.body(15, weight: .medium))
                        .foregroundColor(.cosmicNeutral)

                    if ritual.isActive {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text(ritual.description)
                    .font(SynergyFont.body(12))
                    .foregroundColor(.cosmicMuted)
                    .lineLimit(2)

                if !ritual.isActive {
                    Text("in \(ritual.daysRemaining) days")
                        .systemLabel()
                        .foregroundColor(accentColor.opacity(0.8))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.cosmicMuted)
        }
        .padding(Spacing.md)
        .cosmicCard()
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(
                    ritual.isActive ? accentColor.opacity(0.3) : Color.cosmicBorder,
                    lineWidth: ritual.isActive ? 1.5 : 1
                )
        )
    }
}

// MARK: - Aligned Match Chip

struct AlignedMatchChip: View {
    let item: FeedItem

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(LinearGradient.cosmicGradient)
                    .frame(width: 52, height: 52)
                Text(item.user.displayName.prefix(1))
                    .font(SynergyFont.headline(22))
                    .foregroundColor(.cosmicDark)
            }
            .cosmicGlow(color: .cosmicCyan, radius: 8)

            Text(item.user.displayName)
                .font(SynergyFont.body(12, weight: .medium))
                .foregroundColor(.cosmicNeutral)

            MatchScorePill(score: item.cosmicScore, showLabel: false)
        }
        .frame(width: 80)
    }
}

// MARK: - Ritual Detail Sheet

struct RitualDetailSheet: View {
    let ritual: RitualEvent
    @Environment(\.dismiss) var dismiss

    private var accentColor: Color { Color(hex: ritual.type.color) }

    var body: some View {
        // iOS 15: NavigationView; iOS 16+: replace with NavigationStack
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    HStack {
                        Image(systemName: ritual.type.icon)
                            .font(.system(size: 32))
                            .foregroundColor(accentColor)
                            .frame(width: 72, height: 72)
                            .background(accentColor.opacity(0.15))
                            .clipShape(Circle())
                            .cosmicGlow(color: accentColor, radius: 16)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("RITUAL_DESCRIPTION")
                            .systemLabel()
                        Text(ritual.description)
                            .font(SynergyFont.body(15))
                            .foregroundColor(.cosmicNeutral.opacity(0.8))
                            .lineSpacing(5)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("RITUAL_PROMPT")
                            .systemLabel()
                            .foregroundColor(accentColor.opacity(0.8))
                        Text("\u{201C}\(ritual.ritualPrompt)\u{201D}")
                            .font(SynergyFont.headlineMedium(17))
                            .foregroundColor(.cosmicNeutral)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Spacing.lg)
                    .background(accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .strokeBorder(accentColor.opacity(0.3), lineWidth: 1)
                    )

                    CosmicButton("Set my intention", variant: .gradient) {
                        dismiss()
                    }
                }
                .padding(Spacing.xl)
            }
            .background(Color.cosmicDark)
            .navigationTitle(ritual.title)
            .navigationBarTitleDisplayMode(.large)
            // iOS 16+: restore .toolbarBackground / .toolbarColorScheme
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.cosmicCyan)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
