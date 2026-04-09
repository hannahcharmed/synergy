import SwiftUI

// MARK: - Profile Tab

struct ProfileView: View {
    @EnvironmentObject var vm: ProfileViewModel
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()

                if let user = vm.user {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Spacing.xl) {
                            profileNavBar(user: user)
                            tierBadge(user: user)
                            chartSummaryCard(user: user)
                            bioCard(user: user)
                            settingsSection
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, Spacing.xl)
                    }
                }
            }
            .sheet(isPresented: $vm.showPaywall) {
                PaywallView()
                    .environmentObject(vm)
            }
        }
    }

    // MARK: - Nav Bar

    private func profileNavBar(user: User) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Profile")
                    .font(SynergyFont.headline(24))
                    .foregroundColor(.cosmicNeutral)
                Text(user.birthChart.shortSummary)
                    .systemLabel()
                    .foregroundColor(.cosmicMuted)
            }
            Spacer()
            CosmicIconButton("gearshape.fill") {
                vm.showSettings = true
            }
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Tier Badge

    private func tierBadge(user: User) -> some View {
        HStack {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient.cosmicGradient)
                    .frame(width: 80, height: 80)
                    .cosmicPurpleGlow(radius: 16)
                Text(user.displayName.prefix(1))
                    .font(SynergyFont.headline(34))
                    .foregroundColor(.cosmicDark)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(user.displayName)
                    .font(SynergyFont.headline(20))
                    .foregroundColor(.cosmicNeutral)
                Text(user.locationDisplay)
                    .font(SynergyFont.body(13))
                    .foregroundColor(.cosmicMuted)

                // Tier pill
                HStack(spacing: 4) {
                    Image(systemName: user.subscriptionTier.icon)
                        .font(.system(size: 11))
                    Text(user.subscriptionTier.displayName)
                        .font(SynergyFont.body(12, weight: .semibold))
                }
                .foregroundColor(tierColor(user.subscriptionTier))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(tierColor(user.subscriptionTier).opacity(0.15))
                .clipShape(Capsule())
            }
            .padding(.leading, Spacing.md)

            Spacer()
        }
    }

    private func tierColor(_ tier: SubscriptionTier) -> Color {
        switch tier {
        case .stardust: return .cosmicMuted
        case .cosmic:   return .cosmicCyan
        case .oracle:   return .cosmicPurple
        }
    }

    // MARK: - Upgrade CTA (if free tier)

    // MARK: - Birth Chart Summary

    private func chartSummaryCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("NATAL_CHART")
                    .systemLabel()
                Spacer()
                Text("PLACIDUS")
                    .systemLabel()
                    .foregroundColor(.cosmicMuted.opacity(0.5))
            }

            // Big three
            HStack(spacing: 0) {
                ForEach([
                    ("☉", "Sun", user.birthChart.sunSign.rawValue),
                    ("☽", "Moon", user.birthChart.moonSign.rawValue),
                    ("AC", "Rising", user.birthChart.risingSign.rawValue),
                ], id: \.1) { symbol, label, value in
                    VStack(spacing: 4) {
                        Text(symbol)
                            .font(.system(size: 20))
                            .foregroundColor(.cosmicCyan)
                        Text(value)
                            .font(SynergyFont.headlineMedium(14))
                            .foregroundColor(.cosmicNeutral)
                        Text(label.uppercased())
                            .systemLabel()
                    }
                    .frame(maxWidth: .infinity)

                    if label != "Rising" {
                        Divider()
                            .overlay(Color.cosmicBorder)
                            .frame(height: 40)
                    }
                }
            }
            .padding(.vertical, Spacing.sm)

            Divider().overlay(Color.cosmicBorder)

            // Planetary positions list
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                ForEach(user.birthChart.positions.prefix(8)) { pos in
                    HStack(spacing: 6) {
                        Text(pos.planet.symbol)
                            .font(.system(size: 13))
                            .foregroundColor(.cosmicCyan.opacity(0.8))
                            .frame(width: 20)
                        Text(pos.sign.rawValue)
                            .font(SynergyFont.body(12))
                            .foregroundColor(.cosmicNeutral)
                        Spacer()
                        Text(pos.isRetrograde ? "℞" : "")
                            .font(.system(size: 10))
                            .foregroundColor(.cosmicError)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }

    // MARK: - Bio Card

    private func bioCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("PROFILE_DATA")
                .systemLabel()

            if let bio = user.profile.bio {
                Text(bio)
                    .font(SynergyFont.body(14))
                    .foregroundColor(.cosmicNeutral.opacity(0.8))
                    .lineSpacing(4)
            }

            if !user.profile.vibeWords.isEmpty {
                HStack(spacing: Spacing.sm) {
                    ForEach(user.profile.vibeWords, id: \.self) { word in
                        PlanetAspectTag(text: word, highlighted: true)
                    }
                }
            }

            // Intentions
            if !user.profile.intentionTags.isEmpty {
                HStack(spacing: Spacing.sm) {
                    ForEach(user.profile.intentionTags) { tag in
                        HStack(spacing: 4) {
                            Image(systemName: tag.icon).font(.system(size: 11))
                            Text(tag.rawValue).font(SynergyFont.body(12))
                        }
                        .foregroundColor(.cosmicMuted)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(spacing: Spacing.sm) {
            // Upgrade button (free tier)
            if vm.user?.subscriptionTier == .stardust {
                Button { vm.showPaywall = true } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(LinearGradient.cosmicGradient)
                        Text("Upgrade to Cosmic")
                            .font(SynergyFont.body(15, weight: .semibold))
                            .foregroundStyle(LinearGradient.cosmicGradient)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.cosmicMuted)
                    }
                    .padding(Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(Color.cosmicCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .strokeBorder(LinearGradient.cosmicGradient, lineWidth: 1.5)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            ForEach(settingsRows, id: \.title) { row in
                settingsRow(row)
            }
        }
    }

    private struct SettingsRow {
        let icon: String; let title: String; let destructive: Bool
    }

    private var settingsRows: [SettingsRow] {
        [
            .init(icon: "bell.fill",           title: "Notifications",      destructive: false),
            .init(icon: "slider.horizontal.3", title: "Discovery settings", destructive: false),
            .init(icon: "lock.shield.fill",    title: "Privacy",            destructive: false),
            .init(icon: "questionmark.circle", title: "Help & Support",     destructive: false),
            .init(icon: "rectangle.portrait.and.arrow.right", title: "Sign out", destructive: true),
        ]
    }

    private func settingsRow(_ row: SettingsRow) -> some View {
        Button {
            if row.title == "Sign out" { coordinator.signOut() }
        } label: {
            HStack {
                Image(systemName: row.icon)
                    .font(.system(size: 15))
                    .foregroundColor(row.destructive ? .cosmicError : .cosmicMuted)
                    .frame(width: 24)
                Text(row.title)
                    .font(SynergyFont.body(15))
                    .foregroundColor(row.destructive ? .cosmicError : .cosmicNeutral)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.cosmicMuted)
            }
            .padding(Spacing.lg)
            .cosmicCard()
        }
        .buttonStyle(.plain)
    }
}
