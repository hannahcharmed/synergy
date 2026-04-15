import SwiftUI

// MARK: - Today Tab — Horoscope + Ritual Engine

struct TodayView: View {
    @EnvironmentObject var vm: TodayViewModel
    @State private var selectedRitual: RitualEvent? = nil
    @State private var showWeeklyReport = false
    @State private var selectedAlignedMatch: FeedItem? = nil

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
                            mainContent
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
            .sheet(item: $selectedAlignedMatch) { match in
                AlignedMatchProfileSheet(item: match)
            }
            .navigationBarHidden(true)
            .animation(.easeInOut(duration: 0.3), value: vm.showTransitAlert)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Main Content (extracted to avoid type-checker timeout)

    @ViewBuilder
    private var mainContent: some View {
        // Transit alert banner
        if let alert = vm.activeTransitAlert, vm.showTransitAlert {
            transitAlertBanner(alert)
                .transition(.move(edge: .top).combined(with: .opacity))
        }

        // Mercury retrograde warning
        if vm.isMercuryRetrograde {
            mercuryRetrogradeBanner
        }

        // Aligned matches first — highest-signal content
        if !vm.alignedMatches.isEmpty {
            alignedMatchesSection
        }

        if let h = vm.horoscope {
            cosmicWeatherBanner(h)
            horoscopeCard(h)
        }

        // Cosmic streak
        if vm.streakDays >= 2 {
            streakCard
        }

        // Weekly synastry report button
        if !vm.weeklyReport.isEmpty {
            weeklyReportCard
        }

        if !vm.activeRituals.isEmpty {
            ritualSection(title: "ACTIVE_RITUALS", events: vm.activeRituals)
        }
        if !vm.upcomingRituals.isEmpty {
            ritualSection(title: "UPCOMING", events: vm.upcomingRituals)
        }

        // Upcoming transit forecast cards
        if !vm.upcomingTransits.isEmpty {
            upcomingTransitsSection
        }
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
                        .strokeBorder(Color.cosmicCyan, lineWidth: 1.5)
                        .opacity(0.4)
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
                .strokeBorder(Color.cosmicError, lineWidth: 1)
                .opacity(0.3)
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
                    let barColor: Color = i <= h.cosmicWeather.intensityLevel
                        ? Color(hex: h.cosmicWeather.mood.color) : Color.cosmicBorder
                    Capsule()
                        .fill(barColor)
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
                    .fill(LinearGradient.cosmicGradient)
                    .opacity(0.2)
                    .frame(width: 44, height: 44)
                Text("✦")
                    .font(.system(size: 20))
                    .foregroundStyle(LinearGradient.cosmicGradient)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("COSMIC_STREAK")
                    .systemLabel()
                Text("\(vm.streakDays) days in a row. The stars notice your consistency.")
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
                .strokeBorder(Color.cosmicPurple, lineWidth: 1)
                .opacity(0.4)
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
                        Button { selectedAlignedMatch = item } label: {
                            AlignedMatchChip(item: item)
                        }
                        .buttonStyle(.plain)
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

    // MARK: - Upcoming Transits Section

    private var upcomingTransitsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("UPCOMING_TRANSITS")
                    .systemLabel()
                Spacer()
                Text("FORECAST · 14 DAYS")
                    .systemLabel()
                    .foregroundColor(.cosmicMuted.opacity(0.6))
            }

            ForEach(vm.upcomingTransits) { transit in
                upcomingTransitCard(transit)
            }
        }
    }

    private func upcomingTransitCard(_ transit: UpcomingTransit) -> some View {
        let accentColor = Color(hex: transit.colorHex)
        let glowRadius: CGFloat   = transit.isImminent ? 8 : 0
        let planetFontSize: CGFloat = transit.isToday ? 20 : 17
        let badgeLabel: String    = transit.isToday ? "TODAY" : "IN \(transit.daysUntil)D"
        let badgeTextColor: Color = transit.isToday ? accentColor : .cosmicMuted
        let badgeBgColor: Color   = transit.isToday ? accentColor.opacity(0.18) : Color.cosmicBorder
        let borderColor: Color    = transit.isImminent ? accentColor : Color.cosmicBorder
        let borderWidth: CGFloat  = transit.isImminent ? 1.5 : 1
        let borderOpacity: Double = transit.isImminent ? 0.5 : 1

        return HStack(alignment: .top, spacing: Spacing.md) {
            // Planet symbol circle
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(transit.planetSymbol)
                    .font(.system(size: planetFontSize))
                    .foregroundColor(accentColor)
            }
            .cosmicGlow(color: accentColor, radius: glowRadius)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(transit.planet) \(transit.action) \(transit.target)")
                        .font(SynergyFont.body(14, weight: .medium))
                        .foregroundColor(.cosmicNeutral)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    // Day badge
                    Text(badgeLabel)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(badgeTextColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(badgeBgColor)
                        .clipShape(Capsule())
                }
                Text(transit.impactDescription)
                    .font(SynergyFont.body(12))
                    .foregroundColor(.cosmicNeutral.opacity(0.65))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .background(Color.cosmicCard)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(borderColor, lineWidth: borderWidth)
                .opacity(borderOpacity)
        )
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
                    ritual.isActive ? accentColor : Color.cosmicBorder,
                    lineWidth: ritual.isActive ? 1.5 : 1
                )
                .opacity(ritual.isActive ? 0.3 : 1.0)
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
                            .strokeBorder(accentColor, lineWidth: 1)
                            .opacity(0.3)
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
                .strokeBorder(Color.cosmicBorder, lineWidth: 1)
        )
    }
}

// MARK: - Aligned Match Profile Sheet

struct AlignedMatchProfileSheet: View {
    let item: FeedItem
    @Environment(\.dismiss) var dismiss

    // These would navigate to the full Feed/Profile tabs in production
    @State private var showSynastry = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Spacing.xl) {
                            // Avatar + name
                            heroSection

                            // Cosmic score + highlights
                            scoreSection

                            // First prompt if available
                            if let prompt = item.user.profile.prompts.first {
                                promptCard(prompt)
                            }

                            // Vibe words
                            if !item.user.profile.vibeWords.isEmpty {
                                vibeSection
                            }
                        }
                        .padding(Spacing.xl)
                        .padding(.bottom, 120)
                    }

                    // Sticky action buttons
                    actionButtons
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.cosmicMuted)
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showSynastry) {
            SynastryDetailSheet(item: item)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(LinearGradient.cosmicGradient)
                    .frame(width: 90, height: 90)
                Text(item.user.displayName.prefix(1))
                    .font(SynergyFont.headline(36))
                    .foregroundColor(.cosmicDark)
            }
            .cosmicGlow(color: .cosmicCyan, radius: 16)

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(item.user.displayName), \(item.user.age)")
                        .font(SynergyFont.headline(22))
                        .foregroundColor(.cosmicNeutral)
                    if item.user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.cosmicCyan)
                    }
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
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.md)
    }

    // MARK: - Score

    private var scoreSection: some View {
        VStack(spacing: Spacing.md) {
            MatchScoreBadge(score: item.cosmicScore, size: .large)

            if !item.highlights.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(item.highlights, id: \.self) { h in
                            PlanetAspectTag(text: h, highlighted: true)
                        }
                    }
                }
            }

            if let boost = item.transitBoost {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                    Text(boost.description)
                        .font(SynergyFont.body(12))
                }
                .foregroundColor(.cosmicCyan)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.cosmicCyan.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Prompt card

    private func promptCard(_ prompt: ProfilePrompt) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(prompt.question.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.cosmicCyan.opacity(0.7))
                .kerning(0.5)
            Text("\u{201C}\(prompt.answer)\u{201D}")
                .font(SynergyFont.body(15))
                .foregroundColor(.cosmicNeutral.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cosmicCard()
    }

    // MARK: - Vibe words

    private var vibeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("VIBE")
                .systemLabel()
            HStack(spacing: Spacing.sm) {
                ForEach(item.user.profile.vibeWords, id: \.self) { word in
                    Text(word)
                        .font(SynergyFont.body(13))
                        .foregroundColor(.cosmicCyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.cosmicCyan.opacity(0.08))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.cosmicCyan.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            Divider().overlay(Color.cosmicBorder)
            VStack(spacing: Spacing.sm) {
                CosmicButton("View synastry", variant: .gradient) {
                    showSynastry = true
                }
                CosmicButton("View full profile", variant: .outlined) {
                    // In production: navigate to full MatchCard / Feed detail
                    dismiss()
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.lg)
        }
        .background(Color.cosmicDark)
    }
}
