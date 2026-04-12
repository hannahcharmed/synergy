import SwiftUI

// MARK: - Profile Tab

struct ProfileView: View {
    @EnvironmentObject var vm: ProfileViewModel
    @EnvironmentObject var coordinator: AppCoordinator

    // Tracks which settings sheet is active
    @State private var activeSettings: SettingsDestination? = nil

    enum SettingsDestination: String, Identifiable {
        case notifications, discovery, privacy, help
        var id: String { rawValue }
    }

    var body: some View {
        NavigationView {
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
                PaywallView().environmentObject(vm)
            }
            .sheet(isPresented: $vm.showSettings) {
                SettingsMenuSheet()
                    .environmentObject(vm)
                    .environmentObject(coordinator)
            }
            .sheet(item: $activeSettings) { dest in
                settingsSheet(for: dest)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
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

    // MARK: - Birth Chart Summary

    private func chartSummaryCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("NATAL_CHART").systemLabel()
                Spacer()
                Text("PLACIDUS").systemLabel().foregroundColor(.cosmicMuted.opacity(0.5))
            }

            HStack(spacing: 0) {
                ForEach([
                    ("☉", "Sun",    user.birthChart.sunSign.rawValue),
                    ("☽", "Moon",   user.birthChart.moonSign.rawValue),
                    ("AC", "Rising", user.birthChart.risingSign.rawValue),
                ], id: \.1) { symbol, label, value in
                    VStack(spacing: 4) {
                        Text(symbol).font(.system(size: 20)).foregroundColor(.cosmicCyan)
                        Text(value).font(SynergyFont.headlineMedium(14)).foregroundColor(.cosmicNeutral)
                        Text(label.uppercased()).systemLabel()
                    }
                    .frame(maxWidth: .infinity)
                    if label != "Rising" {
                        Divider().overlay(Color.cosmicBorder).frame(height: 40)
                    }
                }
            }
            .padding(.vertical, Spacing.sm)

            Divider().overlay(Color.cosmicBorder)

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
            Text("PROFILE_DATA").systemLabel()

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
                            .overlay(RoundedRectangle(cornerRadius: Radius.md)
                                .strokeBorder(LinearGradient.cosmicGradient, lineWidth: 1.5))
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
            switch row.title {
            case "Notifications":
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            case "Discovery settings": activeSettings = .discovery
            case "Privacy":            activeSettings = .privacy
            case "Help & Support":     activeSettings = .help
            case "Sign out":           coordinator.signOut()
            default: break
            }
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
                if !row.destructive {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.cosmicMuted)
                }
            }
            .padding(Spacing.lg)
            .cosmicCard()
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func settingsSheet(for dest: SettingsDestination) -> some View {
        switch dest {
        case .discovery: DiscoverySettingsSheet()
        case .privacy:   PlaceholderSettingsSheet(title: "Privacy", icon: "lock.shield.fill", message: "Manage who can see your profile and how your data is used. Full privacy controls coming soon.")
        case .help:      PlaceholderSettingsSheet(title: "Help & Support", icon: "questionmark.circle", message: "For support, email us at hello@synergy.app\n\nWe typically respond within 24 hours.")
        case .notifications: EmptyView()
        }
    }
}

// MARK: - Settings Menu Sheet (gear button)

struct SettingsMenuSheet: View {
    @EnvironmentObject var vm: ProfileViewModel
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.dismiss) var dismiss
    @AppStorage("colorScheme") private var colorSchemePreference: String = "dark"

    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if let user = vm.user {
                        // Account info
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.cosmicGradient)
                                    .frame(width: 56, height: 56)
                                Text(user.displayName.prefix(1))
                                    .font(SynergyFont.headline(24))
                                    .foregroundColor(.cosmicDark)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName)
                                    .font(SynergyFont.headline(18))
                                    .foregroundColor(.cosmicNeutral)
                                Text(user.subscriptionTier.displayName + " member")
                                    .font(SynergyFont.body(13))
                                    .foregroundColor(.cosmicMuted)
                            }
                        }
                        .padding(.bottom, Spacing.sm)
                    }

                    Divider().overlay(Color.cosmicBorder)

                    // Appearance
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("APPEARANCE")
                            .systemLabel()
                            .padding(.horizontal, Spacing.lg)

                        Picker("", selection: $colorSchemePreference) {
                            Text("Dark").tag("dark")
                            Text("Light").tag("light")
                            Text("System").tag("system")
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, Spacing.lg)
                    }

                    Divider().overlay(Color.cosmicBorder)

                    // App version
                    HStack {
                        Text("VERSION")
                            .systemLabel()
                        Spacer()
                        Text("1.0.0 (mock)")
                            .font(SynergyFont.body(13))
                            .foregroundColor(.cosmicMuted)
                    }
                    .padding(.horizontal, Spacing.lg)

                    Spacer()

                    // Sign out
                    CosmicButton("Sign out", variant: .outlined) {
                        dismiss()
                        coordinator.signOut()
                    }
                }
                .padding(Spacing.xl)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.cosmicCyan)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Discovery Settings Sheet

struct DiscoverySettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var maxDistance: Double = 25
    @State private var minAge: Double = 22
    @State private var maxAge: Double = 35
    @State private var showVerifiedOnly = false
    @State private var showActiveOnly  = true

    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {

                        // Distance
                        settingGroup(title: "MAX_DISTANCE") {
                            VStack(spacing: Spacing.sm) {
                                HStack {
                                    Text("Within \(Int(maxDistance)) miles")
                                        .font(SynergyFont.body(15))
                                        .foregroundColor(.cosmicNeutral)
                                    Spacer()
                                }
                                Slider(value: $maxDistance, in: 5...100, step: 5)
                                    .tint(.cosmicCyan)
                            }
                        }

                        // Age range
                        settingGroup(title: "AGE_RANGE") {
                            VStack(spacing: Spacing.sm) {
                                HStack {
                                    Text("\(Int(minAge)) – \(Int(maxAge)) years")
                                        .font(SynergyFont.body(15))
                                        .foregroundColor(.cosmicNeutral)
                                    Spacer()
                                }
                                HStack(spacing: Spacing.md) {
                                    Text("Min")
                                        .systemLabel()
                                        .frame(width: 28)
                                    Slider(value: $minAge, in: 18...maxAge - 1, step: 1)
                                        .tint(.cosmicPurple)
                                }
                                HStack(spacing: Spacing.md) {
                                    Text("Max")
                                        .systemLabel()
                                        .frame(width: 28)
                                    Slider(value: $maxAge, in: minAge + 1...65, step: 1)
                                        .tint(.cosmicPurple)
                                }
                            }
                        }

                        // Toggles
                        settingGroup(title: "FILTERS") {
                            VStack(spacing: 0) {
                                toggleRow(label: "Verified profiles only", isOn: $showVerifiedOnly)
                                Divider().overlay(Color.cosmicBorder)
                                toggleRow(label: "Active in last 7 days", isOn: $showActiveOnly)
                            }
                        }

                        CosmicButton("Save preferences", variant: .gradient) { dismiss() }
                    }
                    .padding(Spacing.xl)
                }
            }
            .navigationTitle("Discovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.cosmicCyan)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func settingGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title).systemLabel()
            content()
                .padding(Spacing.lg)
                .cosmicCard()
        }
    }

    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(SynergyFont.body(15))
                .foregroundColor(.cosmicNeutral)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(.cosmicCyan)
                .labelsHidden()
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Placeholder Sheet (Privacy / Help)

struct PlaceholderSettingsSheet: View {
    let title: String
    let icon: String
    let message: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()
                VStack(spacing: Spacing.xl) {
                    Spacer()
                    Image(systemName: icon)
                        .font(.system(size: 48))
                        .foregroundColor(.cosmicMuted.opacity(0.5))
                    Text(message)
                        .font(SynergyFont.body(15))
                        .foregroundColor(.cosmicMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, Spacing.xl)
                    Spacer()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.cosmicCyan)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
