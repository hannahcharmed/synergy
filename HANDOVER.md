# Synergy — Project Handover / Save File

**Branch:** `claude/install-ui-ux-skill-BP3E1`
**Last updated:** 2026-04-18
**App:** Synergy iOS (SwiftUI, iOS 15+) — cosmic astrology dating app

---

## Project Overview

Synergy is a dating app built in SwiftUI targeting iOS 15+. The aesthetic crosses Hinge/Tinder's card-swipe UX with Co-Star's minimal, high-contrast dark-mode astrology UI. Core features: birth chart capture, synastry compatibility scoring, a card deck feed, Today tab, and chat.

Key design tokens live in `Synergy/UI/` — colors (`CosmicColors.swift`), fonts (`SynergyFont.swift`), spacing/radius (`DesignSystem.swift`), and shared components (`Components/`).

---

## Architecture

```
Synergy/
├── App/               SynergyApp.swift, AppCoordinator.swift
├── Models/            User, BirthChart, FeedItem, etc.
├── Services/          MockDataService.swift (single source of mock data + analytics stubs)
├── Features/
│   ├── Onboarding/    OnboardingContainerView + 7 step views
│   ├── Feed/          FeedView, MatchCardView, FeedViewModel
│   ├── Today/         TodayView, TodayViewModel
│   ├── Chat/          ConversationsView, ChatView
│   ├── Profile/       ProfileView, ProfileViewModel
│   └── Settings/      SettingsView
└── UI/
    ├── Components/    CosmicButton, MatchScorePill, PlanetAspectTag, etc.
    ├── Modifiers/     .cosmicCard(), .cosmicGlow(), .cardShadow(), etc.
    └── Theme/         CosmicColors, SynergyFont, DesignSystem
```

**Navigation:** `AppCoordinator` (ObservableObject) manages root state: `.onboarding` → `.main`. Main uses a `TabView` with Feed, Today, Chat, Profile tabs.

**State:** Each feature has a `ViewModel` (`@StateObject` at root, `@EnvironmentObject` in children). No third-party dependencies — pure SwiftUI + Combine.

---

## Completed Work (this session group)

### Group 1 — Foundation Polish
- `MatchScorePill`: Redesigned (number + "MATCH" monospaced label, no sparkles emoji)
- `MatchCardView`: 28pt name, inline score pill, no aspect chips, clean Hinge-style prompt row with thin separator
- `ProfileView`: Hinge-style prompts (no card backgrounds, dividers, 16pt answers); fixed ambiguous `remove(at:)` compiler errors

### Group 2 — Consistency Pass
- Removed all `.foregroundColor(.cosmicCyan.opacity(0.8))` overrides on step counter systemLabels across all 7 onboarding screens
- `TodayView`: purged emoji from cosmic weather and planet descriptions
- `MockDataService`: purged emoji from display strings
- `BirthChart.swift`: Fixed `ZodiacSign.element` — was returning `.fire` for all signs

### Group 3 — Onboarding Visual Polish (Co-Star style)
- `OnboardingContainerView`: Replaced `StarParticleView(count: 60)` with `Color.black.ignoresSafeArea()` — pure black canvas
- `WelcomeView`: Replaced orbital ring decorations + ✦ with a single pulsing `moon.stars.fill` mark (two concentric circle strokes that pulse via `glowPulse` state)
- `FirstMatchRevealView`: Removed ✦ from headline, switched `MatchScoreBadge` → `MatchScorePill`, fixed distance format `%.1f` → `%.0f`
- `ChartRevealView`: Stripped decorative SF symbol icons from PLANET_INSIGHTS and chart breakdown headers; improved `PlanetDot` (30px filled bg + stroke ring, glow on sun/moon only)

### Zodiac Emoji Fix
- **Root cause:** iOS renders bare Unicode codepoints ♈–♓ as emoji
- **Fix:** Appended `\u{FE0E}` (VS15 text variation selector) to all 12 glyphs in `ZodiacSign.symbol` in `BirthChart.swift` and in `zodiacGlyphs` array in `SynastryCompositeWheelView`

### Feed UX — Profile vs Synastry Split
- `MatchCardView`: Added `onSynastry: (() -> Void)?` callback. Card tap → `onTap` (profile); swipe-up → `onSynastry` (synastry sheet)
- `FeedView`: Added `@State private var selectedProfileItem: FeedItem?`; `.sheet(item:)` presents `FeedMatchProfileSheet`
- `FeedMatchProfileSheet` (in `FeedView.swift`): Full Hinge-style profile sheet with photo area (element-tinted gradient bg), all prompts, chart big three, and PASS / SYNASTRY / LIKE action bar. Note: named `FeedMatchProfileSheet` to avoid conflict with existing `MatchProfileSheet(user:)` in `ConversationsView.swift`
- `SynastryDetailSheet`: Moved `aspectGridSection` before `layersSection` (aspects now appear under radar chart, not below score breakdown)

### Today Tab
- `TodayView`: Moved `weeklyReportCard` above `cosmicWeatherBanner`/`horoscopeCard`, below `alignedMatchesSection`

### Onboarding — Discovery Step (05/07)
- Added `minCosmicScore` slider to `OnboardingDiscoveryView` with color-coded pill (`discScoreColor`) and contextual description (`discScoreDescription`)

---

## Known Issues / Remaining Work

### High priority
- [ ] **One animation per screen** — `ChartRevealView.runAnimation()` still has 6+ staggered `withAnimation` calls. Co-Star style = one entrance animation per screen. Simplify to a single fade/slide-in.
- [ ] **`MatchProfileSheet` in Chat context** — `ConversationsView.swift` and `ChatView.swift` use `MatchProfileSheet(user:)` which has a simpler UI (no score pill, no synastry shortcut). Could be merged with `FeedMatchProfileSheet` once real data is wired.

### Medium priority
- [ ] **Real photo support** — All photo areas use placeholder gradients with initials. `ProfileView` has `photoSlots` with camera/library picker UI but it's UI-only (no persistence).
- [ ] **Birth chart wheel readability** — `ChartRevealView`'s `chartWheel` orbital rings are visually dense. The `PlanetDot` was improved but the center zodiac sign glyph in the wheel is still small.
- [ ] **Analytics stubs** — All `print("[Analytics]…")` calls are stubs. Replace with real analytics SDK when integrating backend.

### Low priority
- [ ] `ChartRevealView.swift:300` — `.foregroundColor(.cosmicCyan.opacity(0.8))` on zodiac sign symbol in `placementRow` is intentional (sign color, not a systemLabel override) but could be a `Color` constant.
- [ ] `OnboardingDiscoveryView` header says "05 / 07" but is actually step 6 in the enum (`.discovery` = rawValue 6). Double-check numbering against final step order.

---

## Critical File Map

| File | Purpose |
|------|---------|
| `Synergy/Models/BirthChart.swift` | ZodiacSign, Planet, BirthChart models; VS15 glyph fix here |
| `Synergy/Services/MockDataService.swift` | All mock users, feed items, transits, weekly reports |
| `Synergy/Features/Feed/Views/FeedView.swift` | Feed, SynastryDetailSheet, FeedMatchProfileSheet, RadarChartView, SynastryCompositeWheelView, aspect computation |
| `Synergy/Features/Feed/Views/MatchCardView.swift` | Swipe card — onTap/onSynastry callbacks |
| `Synergy/Features/Onboarding/OnboardingContainerView.swift` | 7-step container + OnboardingDiscoveryView (05/07) |
| `Synergy/Features/Onboarding/Views/WelcomeView.swift` | Step 01 |
| `Synergy/Features/Onboarding/Views/ChartRevealView.swift` | Step 02 — chart display, PlanetDot component |
| `Synergy/Features/Today/Views/TodayView.swift` | Today tab — aligned matches, weekly report, horoscope |
| `Synergy/UI/Components/MatchScoreBadge.swift` | MatchScorePill (inline) + MatchScoreBadge (large) |
| `Synergy/UI/Theme/CosmicColors.swift` | All Color extensions |

---

## Naming Conflicts to Know

- **`MatchProfileSheet`** — two versions exist:
  - `ConversationsView.swift`: `MatchProfileSheet(user: User)` — used in Chat context
  - `FeedView.swift`: `FeedMatchProfileSheet(item: FeedItem, onViewSynastry:)` — used in Feed context
- **`ConfettiView`** — defined in `FirstMatchRevealView.swift`; also referenced by `MatchAlertOverlay` in `FeedView.swift` via the same file (they're both in the module)

---

## Design System Quick Reference

```swift
// Spacing
Spacing.xs / sm / md / lg / xl / xxl / xxxl

// Radius
Radius.sm / card / xl

// Fonts
SynergyFont.headline(size)        // Serif display
SynergyFont.headlineMedium(size)  // Medium weight
SynergyFont.body(size)            // Body

// Colors (all via Color extension)
.cosmicDark / .cosmicDarkAlt / .cosmicCard
.cosmicNeutral / .cosmicMuted / .cosmicBorder
.cosmicCyan / .cosmicPurple
.cosmicFire / .cosmicEarth / .cosmicAir / .cosmicWater
.cosmicSuccess / .cosmicError

// Gradients
LinearGradient.cosmicGradient   // cyan → purple
LinearGradient.scoreGlow

// Modifiers
.cosmicCard()           // dark card bg + border + corner radius
.cardShadow()           // drop shadow
.cosmicGlow(color:radius:)
.cosmicPurpleGlow(radius:)
.systemLabel()          // 9pt monospaced uppercase, cosmicMuted
```

---

## Gotchas

1. **`.foregroundStyle(gradient).kerning(n)`** breaks compilation — `foregroundStyle` with a gradient `ShapeStyle` returns `some View`, not `Text`. Always put `.kerning()` before `.foregroundStyle()` on Text.
2. **`remove(at:)` on protocol arrays** — Swift can't resolve which `remove(at:)` overload to use on arrays of protocol types. Use `removeAll { $0.id == targetId }` instead.
3. **iOS 15 navigation** — use `NavigationView` + `.navigationViewStyle(.stack)`, not `NavigationStack`.
4. **`ForEach` with indices** — use `ForEach(array.indices, id: \.self)` not `ForEach(Array(array.enumerated()), id: \.element.id)` when you need the index.
5. **Zodiac emoji** — Always append `\u{FE0E}` (VS15 text selector) to zodiac glyphs ♈–♓ in strings displayed as SwiftUI Text.
