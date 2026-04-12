import SwiftUI

// MARK: - Today Tab — Horoscope + Ritual Engine

struct TodayView: View {
    @EnvironmentObject var vm: TodayViewModel
    @State private var selectedRitual: RitualEvent? = nil
    @State private var showWeeklyReport = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()

                if vm.isLoading {
                    loadingView
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            todayNavBar

                            // Transit alert banner
                            if let alert = vm.activeTransitAlert, vm.showTransitAlert {
                                transitAlertBanner(alert)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // Mercury retrograde warning
                            if vm.isMercuryRetrograde {
                                mercuryRetrogradeBanner
                            }

                            if let h = vm.horoscope {
                                cosmicWeatherBanner(h)
                                horoscopeCard(h)
                            }

                            // Cosmic streak
                            if vm.streakDays >= 2 {
                                streakCard
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

                            // Weekly synastry report button
                            if !vm.weeklyReport.isEmpty {
                                weeklyReportCard
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, Spacing.xl)
                    }
                    .refreshable { await vm.refresh() }
                }
            }
            .sheet(item: $selectedRitual) { ritual in
                RitualDetailSheet(ritual: ritual)
            }
            .sheet(isPresented: $showWeeklyReport) {
                WeeklyReportSheet(entries: vm.weeklyReport)
            }
            .navigationBarHidden(true)
            .animation(.easeInOut(duration: 0.3), value: vm.showTransitAlert)
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

            // Streak indicator (compact, top-right)
            if vm.streakDays >= 2 {
                HStack(spacing: 4) {
                    Text("✦")
                        .font(.system(size: 11))
                    Text("\(vm.streakDays)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(LinearGradient.cosmicGradient)
                .padding(.trailing, Spacing.sm)
            }

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 22))
                .foregroundStyle(LinearGradient.cosmicGradient)
                .cosmicPurpleGlow(radius: 8)
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Transit Alert Banner

    private func transitAlertBanner(_ alert: TransitAlert) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 14))
                .foregroundStyle(LinearGradient.cosmicGradient)
                .frame(width: 32, height: 32)
                .background(Color.cosmicPurple.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("TRANSIT_ACTIVE · +\(alert.boostPercent)% BOOST")
                    .systemLabel()
                    .foregroundColor(.cosmicCyan)
                Text(alert.description)
                    .font(SynergyFont.body(13, weight: .medium))
                    .foregroundColor(.cosmicNeutral)
                    .lineLimit(2)
            }

            Spacer()

            Button { vm.dismissTransitAlert() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
                    .foregroundColor(.cosmicMuted)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.cosmicCard)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .strokeBorder(LinearGradient.cosmicGradient.opacity(0.5), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Mercury Retrograde Banner

    private var mercuryRetrogradeBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundColor(.cosmicError)
            VStack(alignment: .leading, spacing: 1) {
                Text("MERCURY_RETROGRADE")
                    .systemLabel()
                    .foregroundColor(.cosmicError)
                Text("Back up plans, re-read messages before sending, avoid signing contracts.")
                    .font(SynergyFont.body(12))
                    .foregroundColor(.cosmicNeutral.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding(Spacing.md)
        .background(Color.cosmicError.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(Color.cosmicError.opacity(0.3), lineWidth: 1)
        )
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

            Text(h.content)
                .font(SynergyFont.body(15))
                .foregroundColor(.cosmicNeutral.opacity(0.8))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(Color.cosmicBorder)

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

    // MARK: - Cosmic Streak Card

    private var streakCard: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(LinearGradient.cosmicGradient.opacity(0.2))
                    .frame(width: 44, height: 44)
                Text("✦")
                    .font(.system(size: 20))
                    .foregroundStyle(LinearGradient.cosmicGradient)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("COSMIC_STREAK")
                    .systemLabel()
                Text("\(vm.streakDays) days in a row — the stars notice your consistency.")
                    .font(SynergyFont.body(13))
                    .foregroundColor(.cosmicNeutral.opacity(0.8))
            }
            Spacer()
            Text("\(vm.streakDays)")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(LinearGradient.cosmicGradient)
        }
        .padding(Spacing.md)
        .cosmicCard()
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(LinearGradient.cosmicGradient.opacity(0.3), lineWidth: 1)
        )
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

    // MARK: - Weekly Report Card

    private var weeklyReportCard: some View {
        Button { showWeeklyReport = true } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(.cosmicPurple)
                    .frame(width: 40, height: 40)
                    .background(Color.cosmicPurple.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("WEEKLY_SYNASTRY_REPORT")
                        .systemLabel()
                    Text("Your cosmic connections this week")
                        .font(SynergyFont.body(13))
                        .foregroundColor(.cosmicNeutral.opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.cosmicMuted)
            }
            .padding(Spacing.md)
            .cosmicCard()
        }
        .buttonStyle(.plain)
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

// MARK: - Weekly Report Sheet

struct WeeklyReportSheet: View {
    let entries: [WeeklyReportEntry]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("Your matches and the stars are aligning this week. Here's what the transits say.")
                            .font(SynergyFont.body(14))
                            .foregroundColor(.cosmicMuted)
                            .lineSpacing(4)
                            .padding(.top, Spacing.sm)

                        ForEach(entries) { entry in
                            weeklyEntryCard(entry)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(Spacing.xl)
                }
            }
            .navigationTitle("Weekly Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.cosmicCyan)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func weeklyEntryCard(_ entry: WeeklyReportEntry) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.matchName)
                        .font(SynergyFont.headlineMedium(16))
                        .foregroundColor(.cosmicNeutral)
                    Text("BEST DAY: \(entry.bestDay.uppercased())")
                        .systemLabel()
                        .foregroundColor(.cosmicCyan)
                }
                Spacer()
                MatchScorePill(score: entry.cosmicScore)
            }

            Text(entry.weeklyInsight)
                .font(SynergyFont.body(14))
                .foregroundColor(.cosmicNeutral.opacity(0.8))
                .lineSpacing(4)

            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.cosmicPurple)
                Text(entry.transitNote)
                    .font(SynergyFont.body(12))
                    .foregroundColor(.cosmicMuted)
                    .lineLimit(2)
            }
        }
        .padding(Spacing.lg)
        .cosmicCard()
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(LinearGradient.cosmicGradient.opacity(0.2), lineWidth: 1)
        )
    }
}
