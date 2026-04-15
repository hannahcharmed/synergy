import SwiftUI

// MARK: - Profile Tab

struct ProfileView: View {
    @EnvironmentObject var vm: ProfileViewModel
    @EnvironmentObject var coordinator: AppCoordinator

    // Tracks which settings sheet is active
    @State private var activeSettings: SettingsDestination? = nil
    @State private var showShareCard = false
    @State private var shareImage: UIImage? = nil
    @State private var showEditProfile = false

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
                            completionCard(user: user)
                            chartSummaryCard(user: user)
                            bioCard(user: user)
                            promptsCard(user: user)
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
            .sheet(isPresented: $showShareCard) {
                if let img = shareImage {
                    ShareSheetView(items: [img])
                }
            }
            .sheet(isPresented: $showEditProfile) {
                if let user = vm.user {
                    EditProfileSheet(user: user)
                        .environmentObject(vm)
                }
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
            HStack(spacing: Spacing.sm) {
                CosmicIconButton("square.and.arrow.up") {
                    shareImage = ShareableProfileCardView(user: user)
                        .snapshot(size: CGSize(width: 320, height: 568))
                    showShareCard = true
                }
                CosmicIconButton("pencil") {
                    showEditProfile = true
                }
                CosmicIconButton("gearshape.fill") {
                    vm.showSettings = true
                }
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

    // MARK: - Profile Completion Meter

    private func completionScore(for user: User) -> Int {
        var score = 0
        if user.profile.bio != nil && !(user.profile.bio?.isEmpty ?? true) { score += 20 }
        score += min(20, user.profile.photos.count * 10)   // 10 pts per photo, max 20
        score += min(15, user.profile.vibeWords.count * 5) // 5 pts per vibe word, max 15
        score += min(30, user.profile.prompts.count * 10)  // 10 pts per prompt, max 30
        if user.profile.height != nil       { score += 8 }
        if user.profile.occupation != nil   { score += 7 }
        return min(100, score)
    }

    private func completionCard(user: User) -> some View {
        let pct = completionScore(for: user)
        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("PROFILE_STRENGTH")
                    .systemLabel()
                Spacer()
                Text("\(pct)%")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(pct >= 80 ? AnyShapeStyle(LinearGradient.cosmicGradient)
                                               : AnyShapeStyle(Color.cosmicMuted))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.cosmicBorder)
                    Capsule()
                        .fill(LinearGradient.cosmicGradient)
                        .frame(width: geo.size.width * CGFloat(pct) / 100)
                }
                .frame(height: 6)
            }
            .frame(height: 6)

            if pct < 100 {
                completionTips(for: user)
            } else {
                Text("Your profile is fully optimised. More matches incoming.")
                    .font(SynergyFont.body(12))
                    .foregroundColor(.cosmicSuccess)
                    .lineSpacing(2)
            }
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }

    @ViewBuilder
    private func completionTips(for user: User) -> some View {
        let tips = buildCompletionTips(for: user)
        if !tips.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("TO_IMPROVE")
                    .systemLabel()
                    .foregroundColor(.cosmicMuted)
                ForEach(tips.prefix(2), id: \.self) { tip in
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.cosmicPurple)
                        Text(tip)
                            .font(SynergyFont.body(12))
                            .foregroundColor(.cosmicNeutral.opacity(0.7))
                    }
                }
            }
        }
    }

    private func buildCompletionTips(for user: User) -> [String] {
        var tips: [String] = []
        if user.profile.bio == nil || (user.profile.bio?.isEmpty ?? true) {
            tips.append("Add a bio to show your personality")
        }
        if user.profile.photos.count < 2 {
            tips.append("Add \(2 - user.profile.photos.count) more photo(s)")
        }
        if user.profile.vibeWords.count < 3 {
            tips.append("Add \(3 - user.profile.vibeWords.count) vibe word(s)")
        }
        if user.profile.prompts.count < 3 {
            tips.append("Answer \(3 - user.profile.prompts.count) more prompt(s)")
        }
        if user.profile.height == nil {
            tips.append("Add your height")
        }
        if user.profile.occupation == nil {
            tips.append("Add your occupation")
        }
        return tips
    }

    // MARK: - Birth Chart Summary

    private func chartSummaryCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("NATAL_CHART").systemLabel()
                Spacer()
                Text("PLACIDUS").systemLabel().foregroundColor(.cosmicMuted.opacity(0.5))
            }

            bigThreeRow(user: user)

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

    private func bigThreeRow(user: User) -> some View {
        HStack(spacing: 0) {
            signItem(symbol: "☉",  label: "Sun",    value: user.birthChart.sunSign.rawValue)
            Divider().overlay(Color.cosmicBorder).frame(height: 40)
            signItem(symbol: "☽",  label: "Moon",   value: user.birthChart.moonSign.rawValue)
            Divider().overlay(Color.cosmicBorder).frame(height: 40)
            signItem(symbol: "AC", label: "Rising",  value: user.birthChart.risingSign.rawValue)
        }
        .padding(.vertical, Spacing.sm)
    }

    private func signItem(symbol: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(symbol).font(.system(size: 20)).foregroundColor(.cosmicCyan)
            Text(value).font(SynergyFont.headlineMedium(14)).foregroundColor(.cosmicNeutral)
            Text(label.uppercased()).systemLabel()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bio Card

    private func bioCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("PROFILE_DATA").systemLabel()
            bioText(user: user)
            vibeTagsRow(user: user)
            intentionTagsRow(user: user)
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }

    @ViewBuilder
    private func bioText(user: User) -> some View {
        if let bio = user.profile.bio {
            Text(bio)
                .font(SynergyFont.body(14))
                .foregroundColor(.cosmicNeutral.opacity(0.8))
                .lineSpacing(4)
        }
    }

    @ViewBuilder
    private func vibeTagsRow(user: User) -> some View {
        if !user.profile.vibeWords.isEmpty {
            HStack(spacing: Spacing.sm) {
                ForEach(user.profile.vibeWords, id: \.self) { word in
                    PlanetAspectTag(text: word, highlighted: true)
                }
            }
        }
    }

    @ViewBuilder
    private func intentionTagsRow(user: User) -> some View {
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

    // MARK: - Prompts Card

    private func promptsCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("PROFILE_PROMPTS").systemLabel()
            promptsContent(user: user)
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }

    @ViewBuilder
    private func promptsContent(user: User) -> some View {
        if user.profile.prompts.isEmpty {
            Text("Add up to 3 prompts to let people see your personality")
                .font(SynergyFont.body(13))
                .foregroundColor(.cosmicMuted)
                .lineSpacing(3)
        } else {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(user.profile.prompts) { prompt in
                    singlePrompt(prompt)
                }
            }
        }
    }

    private func singlePrompt(_ prompt: ProfilePrompt) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(prompt.question.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.cosmicCyan)
                .kerning(0.5)
            Text(prompt.answer)
                .font(SynergyFont.body(14))
                .foregroundColor(.cosmicNeutral)
                .lineSpacing(3)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cosmicDarkAlt)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(spacing: Spacing.sm) {
            if vm.user?.subscriptionTier == .stardust {
                upgradeButton
            }
            ForEach(settingsRows, id: \.title) { row in
                settingsRow(row)
            }
        }
    }

    private var upgradeButton: some View {
        Button { vm.showPaywall = true } label: {
            HStack {
                Image(systemName: "sparkles").foregroundStyle(LinearGradient.cosmicGradient)
                Text("Upgrade to Cosmic")
                    .font(SynergyFont.body(15, weight: .semibold))
                    .foregroundStyle(LinearGradient.cosmicGradient)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.cosmicMuted)
            }
            .padding(Spacing.lg)
            .cosmicCard()
            .overlay(RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(LinearGradient.cosmicGradient, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private struct SettingsRow {
        let icon: String; let title: String; let destructive: Bool
    }

    private var settingsRows: [SettingsRow] {
        [
            .init(icon: "pencil",              title: "Edit Profile",       destructive: false),
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
            case "Edit Profile":       showEditProfile = true
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
                settingsContent
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

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            if let user = vm.user { accountHeader(user) }
            Divider().overlay(Color.cosmicBorder)
            appearancePicker
            Divider().overlay(Color.cosmicBorder)
            versionRow
            Spacer()
            CosmicButton("Sign out", variant: .outlined) { dismiss(); coordinator.signOut() }
        }
        .padding(Spacing.xl)
    }

    private func accountHeader(_ user: User) -> some View {
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

    private var appearancePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("APPEARANCE").systemLabel().padding(.horizontal, Spacing.lg)
            Picker("", selection: $colorSchemePreference) {
                Text("Dark").tag("dark")
                Text("Light").tag("light")
                Text("System").tag("system")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.lg)

            // Live preview card
            appearancePreviewCard
                .padding(.horizontal, Spacing.lg)
        }
    }

    private var appearancePreviewCard: some View {
        let isDark = colorSchemePreference == "dark" ||
            (colorSchemePreference == "system" &&
             UITraitCollection.current.userInterfaceStyle == .dark)
        let bgColor     = isDark ? Color(hex: "#13141A") : Color(hex: "#F4EDFF")
        let cardBg      = isDark ? Color(hex: "#1A1C24") : Color.white
        let textColor   = isDark ? Color.white           : Color(hex: "#1A1525")
        let mutedColor  = isDark ? Color(hex: "#6B7280") : Color(hex: "#5B4D7A")
        let borderColor = isDark ? Color(hex: "#2C2F33") : Color(hex: "#D4C8F0")
        let cyanColor   = isDark ? Color(hex: "#00F0FF") : Color(hex: "#0088B3")

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PREVIEW")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(cyanColor)
                    .kerning(1.5)
                Spacer()
                // Mini mode indicator
                Image(systemName: isDark ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 10))
                    .foregroundColor(cyanColor)
            }

            // Simulated match card row
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.cosmicGradient)
                        .frame(width: 40, height: 40)
                    Text("L")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isDark ? Color(hex: "#13141A") : Color.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Luna, 26")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(textColor)
                    Text("♏ Scorpio · Pisces rising")
                        .font(.system(size: 11))
                        .foregroundColor(mutedColor)
                }

                Spacer()

                Text("87%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(cyanColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(cyanColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(10)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(borderColor, lineWidth: 1)
            )

            // Simulated message bubble row
            HStack {
                Spacer()
                Text("Venus in Scorpio. I feel you. \u{1F31D}")
                    .font(.system(size: 12))
                    .foregroundColor(isDark ? Color.white : Color(hex: "#1A1525"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isDark ? Color(hex: "#7D5FFF").opacity(0.55) : Color(hex: "#7D5FFF"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .frame(maxWidth: 200)
            }
        }
        .padding(12)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.25), value: colorSchemePreference)
    }

    private var versionRow: some View {
        HStack {
            Text("VERSION").systemLabel()
            Spacer()
            Text("1.0.0 (mock)").font(SynergyFont.body(13)).foregroundColor(.cosmicMuted)
        }
        .padding(.horizontal, Spacing.lg)
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
    @State private var selectedGenders: Set<String> = ["Women", "Men", "Non-binary"]
    @AppStorage("minCosmicScore") private var minCosmicScore: Double = 60

    private let genderOptions = ["Women", "Men", "Non-binary", "Everyone"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {

                        // Gender preference
                        settingGroup(title: "SHOW_ME") {
                            VStack(spacing: 0) {
                                ForEach(genderOptions, id: \.self) { option in
                                    Button {
                                        if option == "Everyone" {
                                            if selectedGenders.contains("Everyone") {
                                                selectedGenders = []
                                            } else {
                                                selectedGenders = ["Everyone"]
                                            }
                                        } else {
                                            selectedGenders.remove("Everyone")
                                            if selectedGenders.contains(option) {
                                                selectedGenders.remove(option)
                                            } else {
                                                selectedGenders.insert(option)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(option)
                                                .font(SynergyFont.body(15))
                                                .foregroundColor(.cosmicNeutral)
                                            Spacer()
                                            if selectedGenders.contains(option) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.cosmicCyan)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(.cosmicBorder)
                                            }
                                        }
                                        .padding(.vertical, Spacing.sm)
                                    }
                                    .buttonStyle(.plain)
                                    if option != genderOptions.last {
                                        Divider().overlay(Color.cosmicBorder)
                                    }
                                }
                            }
                        }

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

                        // Cosmic score threshold
                        settingGroup(title: "COSMIC_COMPATIBILITY") {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 11))
                                            .foregroundColor(.cosmicCyan)
                                        Text("Minimum match score")
                                            .font(SynergyFont.body(15))
                                            .foregroundColor(.cosmicNeutral)
                                    }
                                    Spacer()
                                    Text("\(Int(minCosmicScore))%+")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(scoreColor(Int(minCosmicScore)))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(scoreColor(Int(minCosmicScore)).opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                Slider(value: $minCosmicScore, in: 0...95, step: 5)
                                    .tint(.cosmicCyan)
                                Text(scoreDescription(Int(minCosmicScore)))
                                    .font(SynergyFont.body(12))
                                    .foregroundColor(.cosmicMuted)
                                    .lineSpacing(2)
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

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: return .cosmicCyan
        case 60..<80: return .cosmicPurple
        default: return .cosmicMuted
        }
    }

    private func scoreDescription(_ score: Int) -> String {
        switch score {
        case 0..<30:  return "Show everyone — no cosmic filter applied."
        case 30..<60: return "Light filter — most profiles will appear."
        case 60..<80: return "Balanced — only meaningful astrological alignment."
        case 80..<90: return "High bar — strong synastry matches only."
        default:      return "Strict — only rare, highly aligned connections."
        }
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

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @EnvironmentObject var vm: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    let user: User

    @State private var bio: String
    @State private var vibeWord1: String
    @State private var vibeWord2: String
    @State private var vibeWord3: String
    @State private var prompts: [ProfilePrompt]
    @State private var photoSlots: [String]
    @State private var birthTime: Date

    init(user: User) {
        self.user = user
        _bio = State(initialValue: user.profile.bio ?? "")
        let words = user.profile.vibeWords + ["", "", ""]
        _vibeWord1 = State(initialValue: words[0])
        _vibeWord2 = State(initialValue: words[1])
        _vibeWord3 = State(initialValue: words[2])
        _prompts = State(initialValue: user.profile.prompts)
        _photoSlots = State(initialValue: Array(user.profile.photos.prefix(6)))
        let defaultTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        _birthTime = State(initialValue: user.birthChart.birthTime ?? defaultTime)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        photosSection
                        bioSection
                        vibeSection
                        promptsSection
                        birthTimeSection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.lg)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.cosmicMuted)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveAndDismiss() }
                        .font(SynergyFont.body(15, weight: .semibold))
                        .foregroundColor(.cosmicCyan)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Photos Section

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Label("PHOTOS (up to 6)", systemImage: "photo.stack")
                    .systemLabel()
                    .foregroundColor(.cosmicCyan)
                Spacer()
                Text("\(photoSlots.count) / 6")
                    .systemLabel()
                    .foregroundColor(.cosmicMuted)
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 3),
                spacing: Spacing.sm
            ) {
                ForEach(photoSlots.indices, id: \.self) { idx in
                    photoSlotView(index: idx)
                }
                if photoSlots.count < 6 {
                    addPhotoButtonView
                }
            }

            Text("Tap × to remove a photo. Real upload coming in v1.1.")
                .font(SynergyFont.body(11))
                .foregroundColor(.cosmicMuted)
        }
    }

    private func photoSlotView(index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(
                        LinearGradient(
                            colors: [
                                photoSlotColor(index).opacity(0.55),
                                photoSlotColor(index).opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                VStack(spacing: 6) {
                    Text(user.displayName.prefix(1))
                        .font(SynergyFont.headline(26))
                        .foregroundColor(.white.opacity(0.35))
                    Text("Photo \(index + 1)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .aspectRatio(0.75, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))

            // Remove badge
            Button {
                withAnimation(.spring(response: 0.3)) {
                    photoSlots.remove(at: index)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.cosmicError)
                        .frame(width: 20, height: 20)
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(4)
        }
    }

    private var addPhotoButtonView: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                photoSlots.append("\(user.displayName.lowercased())_\(photoSlots.count + 1)")
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(Color.cosmicDarkAlt)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .strokeBorder(Color.cosmicBorder, lineWidth: 1.5)
                    )
                VStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.cosmicCyan.opacity(0.65))
                    Text("Add")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.cosmicMuted)
                }
            }
            .aspectRatio(0.75, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }

    private func photoSlotColor(_ index: Int) -> Color {
        let palette: [Color] = [.cosmicPurple, .cosmicCyan, Color(hex: "#FF6B9D"),
                                Color(hex: "#FFB800"), Color(hex: "#34D399"), Color(hex: "#7D5FFF")]
        return palette[index % palette.count]
    }

    // MARK: - Birth Time Section

    private var birthTimeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("BIRTH_TIME", systemImage: "clock.fill")
                .systemLabel()
                .foregroundColor(.cosmicCyan)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Correct birth time")
                        .font(SynergyFont.body(14))
                        .foregroundColor(.cosmicNeutral)
                    Text("Improving accuracy recalculates your chart")
                        .font(SynergyFont.body(11))
                        .foregroundColor(.cosmicMuted)
                }
                Spacer()
                DatePicker("", selection: $birthTime, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                    .tint(.cosmicCyan)
                    .environment(\.colorScheme, .dark)
            }
            .padding(Spacing.lg)
            .background(Color.cosmicDarkAlt)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(Color.cosmicBorder, lineWidth: 1))

            if user.birthChart.birthTime == nil {
                HStack(spacing: 5) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                    Text("No birth time was recorded during onboarding — adding one improves chart accuracy.")
                        .font(SynergyFont.body(11))
                        .lineSpacing(2)
                }
                .foregroundColor(.cosmicMuted)
            }
        }
    }

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("BIO", systemImage: "text.alignleft")
                .systemLabel()
                .foregroundColor(.cosmicCyan)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(Color.cosmicDarkAlt)
                    .overlay(RoundedRectangle(cornerRadius: Radius.md)
                        .strokeBorder(Color.cosmicBorder, lineWidth: 1))
                TextEditor(text: $bio)
                    .font(SynergyFont.body(15))
                    .foregroundColor(.cosmicNeutral)
                    .padding(Spacing.sm)
                    .background(Color.clear)
                    .onAppear { UITextView.appearance().backgroundColor = .clear }
            }
            .frame(minHeight: 120, maxHeight: 160)
        }
    }

    private var vibeSuggestions: [String] {
        switch user.birthChart.sunSign {
        case .aries:       return ["Bold", "Passionate", "Direct", "Fearless", "Fiery"]
        case .taurus:      return ["Grounded", "Sensual", "Steady", "Loyal", "Patient"]
        case .gemini:      return ["Witty", "Curious", "Playful", "Electric", "Adaptable"]
        case .cancer:      return ["Nurturing", "Intuitive", "Empathic", "Deep", "Homey"]
        case .leo:         return ["Radiant", "Generous", "Dramatic", "Warm", "Creative"]
        case .virgo:       return ["Analytical", "Precise", "Caring", "Grounded", "Thoughtful"]
        case .libra:       return ["Charming", "Fair", "Aesthetic", "Witty", "Diplomatic"]
        case .scorpio:     return ["Intense", "Mysterious", "Loyal", "Magnetic", "Deep"]
        case .sagittarius: return ["Free", "Adventurous", "Philosophical", "Honest", "Optimistic"]
        case .capricorn:   return ["Ambitious", "Steady", "Disciplined", "Dry", "Private"]
        case .aquarius:    return ["Electric", "Visionary", "Quirky", "Detached", "Original"]
        case .pisces:      return ["Dreamy", "Empathic", "Creative", "Fluid", "Romantic"]
        }
    }

    private var currentVibeWords: [String] {
        [vibeWord1, vibeWord2, vibeWord3].filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func fillNextVibeSlot(_ word: String) {
        if vibeWord1.trimmingCharacters(in: .whitespaces).isEmpty { vibeWord1 = word; return }
        if vibeWord2.trimmingCharacters(in: .whitespaces).isEmpty { vibeWord2 = word; return }
        if vibeWord3.trimmingCharacters(in: .whitespaces).isEmpty { vibeWord3 = word; return }
    }

    private var vibeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("VIBE WORDS (up to 3)", systemImage: "tag")
                .systemLabel()
                .foregroundColor(.cosmicCyan)

            // Zodiac-based suggestion chips
            if currentVibeWords.count < 3 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(user.birthChart.sunSign.rawValue) suggestions")
                        .font(SynergyFont.body(11))
                        .foregroundColor(.cosmicMuted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            ForEach(vibeSuggestions.filter { !currentVibeWords.contains($0) }, id: \.self) { chip in
                                Button { fillNextVibeSlot(chip) } label: {
                                    Text(chip)
                                        .font(SynergyFont.body(12))
                                        .foregroundColor(.cosmicCyan)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.cosmicCyan.opacity(0.08))
                                        .clipShape(Capsule())
                                        .overlay(Capsule().strokeBorder(Color.cosmicCyan.opacity(0.3), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            VStack(spacing: Spacing.sm) {
                vibeField("e.g. Intense", binding: $vibeWord1)
                vibeField("e.g. Loyal", binding: $vibeWord2)
                vibeField("e.g. Witchy", binding: $vibeWord3)
            }
        }
    }

    private func vibeField(_ placeholder: String, binding: Binding<String>) -> some View {
        TextField(placeholder, text: binding)
            .font(SynergyFont.body(15))
            .foregroundColor(.cosmicNeutral)
            .padding(Spacing.md)
            .background(Color.cosmicDarkAlt)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(Color.cosmicBorder, lineWidth: 1))
    }

    private var promptsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("PROMPTS (up to 3)", systemImage: "quote.bubble")
                    .systemLabel()
                    .foregroundColor(.cosmicCyan)
                Spacer()
                if prompts.count < 3 {
                    Button {
                        let questions = PromptQuestion.allCases
                        let usedQuestions = Set(prompts.map { $0.question })
                        if let next = questions.first(where: { !usedQuestions.contains($0.rawValue) }) {
                            prompts.append(ProfilePrompt(question: next.rawValue, answer: ""))
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.cosmicCyan)
                            .font(.system(size: 20))
                    }
                }
            }
            promptsList
        }
    }

    @ViewBuilder
    private var promptsList: some View {
        if prompts.isEmpty {
            Text("Tap + to add a prompt")
                .font(SynergyFont.body(13))
                .foregroundColor(.cosmicMuted)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.cosmicDarkAlt)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        } else {
            VStack(spacing: Spacing.md) {
                ForEach(prompts.indices, id: \.self) { idx in
                    promptCard(index: idx)
                }
            }
        }
    }

    private func promptSuggestions(for question: String) -> [String] {
        switch question {
        case PromptQuestion.wrongAboutSign.rawValue:
            return ["We're actually the most loyal", "Not as [adjective] as they say", "We feel everything deeply"]
        case PromptQuestion.perfectDay.rawValue:
            return ["Coffee, long walk, no plans", "Slow morning, good book, good company", "Anywhere with good food and better conversation"]
        case PromptQuestion.loveLanguage.rawValue:
            return ["Quality time, no phones", "Acts of service, quietly", "Words — I need to hear it"]
        case PromptQuestion.dealbreaker.rawValue:
            return ["Unkindness", "Lack of curiosity", "Inconsistency"]
        case PromptQuestion.moonSign.rawValue:
            return ["…need a lot of alone time", "…overthink everything at 2am", "…feel everything before I process it"]
        case PromptQuestion.firstDate.rawValue:
            return ["Somewhere with good acoustics", "A walk — you can't fake chemistry walking", "Somewhere low-key, high-conversation"]
        case PromptQuestion.venusSign.rawValue:
            return ["I love deeply or not at all", "Slow to open, impossible to forget", "I show love through small, specific things"]
        case PromptQuestion.greenFlag.rawValue:
            return ["You remember the small things", "You're kind to strangers", "You have opinions and defend them gently"]
        case PromptQuestion.rizz.rawValue:
            return ["I will remember everything you tell me", "I'm a better listener than talker", "I'm exactly who I am on day one and day one thousand"]
        default:
            return []
        }
    }

    private func promptCard(index: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(prompts[index].question.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.cosmicCyan)
                    .kerning(0.5)
                    .lineLimit(1)
                Spacer()
                Button {
                    prompts.remove(at: index)
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.cosmicMuted)
                        .font(.system(size: 16))
                }
            }
            TextField("Your answer...", text: Binding(
                get: { prompts[index].answer },
                set: { newVal in
                    prompts[index] = ProfilePrompt(
                        id: prompts[index].id,
                        question: prompts[index].question,
                        answer: newVal
                    )
                }
            ))
            .font(SynergyFont.body(14))
            .foregroundColor(.cosmicNeutral)

            // Suggestion chips for this prompt
            let suggestions = promptSuggestions(for: prompts[index].question)
            if !suggestions.isEmpty && prompts[index].answer.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                prompts[index] = ProfilePrompt(
                                    id: prompts[index].id,
                                    question: prompts[index].question,
                                    answer: suggestion
                                )
                            } label: {
                                Text(suggestion)
                                    .font(SynergyFont.body(11))
                                    .foregroundColor(.cosmicMuted)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.cosmicCard)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().strokeBorder(Color.cosmicBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.cosmicDarkAlt)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Radius.md)
            .strokeBorder(Color.cosmicBorder, lineWidth: 1))
    }

    private func saveAndDismiss() {
        let words = [vibeWord1, vibeWord2, vibeWord3]
        vm.saveProfile(bio: bio, vibeWords: words, prompts: prompts, photos: photoSlots)
        dismiss()
    }
}

// MARK: - Shareable Cosmic Profile Card (appended here so Xcode project can find it)

private struct ShareableProfileCardView: View {
    let user: User

    var body: some View {
        ZStack {
            cardBackground
            starField
            cardContent
        }
        .frame(width: 320, height: 568)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [Color(hex: "#0D0A1A"), Color(hex: "#1A1328"), Color(hex: "#0A0D1A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardContent: some View {
        VStack(spacing: Spacing.xl) {
            Text("SYNERGY")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .kerning(6)
                .foregroundStyle(LinearGradient.cosmicGradient)
            Spacer()
            avatarView
            nameView
            bigThreeBar
            vibeWordsRow
            Spacer()
            footerView
        }
        .padding(Spacing.xl)
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(LinearGradient.cosmicGradient)
                .frame(width: 100, height: 100)
                .blur(radius: 1)
                .cosmicPurpleGlow(radius: 24)
            Text(user.displayName.prefix(1))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private var nameView: some View {
        VStack(spacing: 6) {
            Text(user.displayName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("\(user.age) · \(user.locationDisplay)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private var bigThreeBar: some View {
        HStack(spacing: Spacing.lg) {
            bigThreeItem(symbol: "☉", label: "Sun",   value: user.birthChart.sunSign.rawValue)
            bigThreeItem(symbol: "☽", label: "Moon",  value: user.birthChart.moonSign.rawValue)
            bigThreeItem(symbol: "AC", label: "Rising", value: user.birthChart.risingSign.rawValue)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.lg)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .strokeBorder(Color.cosmicPurple, lineWidth: 1)
                .opacity(0.4)
        )
    }

    @ViewBuilder
    private var vibeWordsRow: some View {
        if !user.profile.vibeWords.isEmpty {
            HStack(spacing: Spacing.sm) {
                ForEach(user.profile.vibeWords.prefix(3), id: \.self) { word in
                    Text(word)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.white, lineWidth: 1).opacity(0.15))
                }
            }
        }
    }

    private var footerView: some View {
        VStack(spacing: 6) {
            Text("Find your cosmic match")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            Text("synergy.app")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(LinearGradient.cosmicGradient)
        }
    }

    private func bigThreeItem(symbol: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(symbol)
                .font(.system(size: 18))
                .foregroundStyle(LinearGradient.cosmicGradient)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    private var starField: some View {
        GeometryReader { geo in
            ForEach(0..<40, id: \.self) { i in
                starDot(i: i, canvasSize: geo.size)
            }
        }
    }

    private func starDot(i: Int, canvasSize: CGSize) -> some View {
        let x = CGFloat((i * 137 + 23) % Int(canvasSize.width))
        let y = CGFloat((i * 97 + 41) % Int(canvasSize.height))
        let dotSize = CGFloat((i % 3) + 1)
        let alpha = Double((i % 5) + 1) * 0.07
        return Circle()
            .fill(Color.white)
            .opacity(alpha)
            .frame(width: dotSize, height: dotSize)
            .position(x: x, y: y)
    }
}

// MARK: - Share Sheet (iOS 15 compatible)

private struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Snapshot helper (iOS 15)

private extension View {
    func snapshot(size: CGSize) -> UIImage {
        let controller = UIHostingController(rootView: self.ignoresSafeArea())
        // Always render in dark mode so cosmic card colours look correct
        controller.overrideUserInterfaceStyle = .dark
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = UIColor(Color(hex: "#0D0A1A"))

        // Force layout before rendering
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // layer.render is more reliable than drawHierarchy for off-screen views
            controller.view.layer.render(in: ctx.cgContext)
        }
    }
}
