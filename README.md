# Synergy — Astrological Dating App (iOS)

Synergy matches people based on full birth chart astrological synastry. Instead of swiping on photos, users get a **Cosmic Match Score™** derived from planetary positions, elemental balance, shared intentions, and active transits.

## Tech Stack

- **Swift 5.9 / SwiftUI** (iOS 16+)
- **MVVM + Coordinator** pattern
- **Combine** for reactive state
- Mock API layer (StoreKit 2 + real ephemeris in production)

---

## Xcode Setup

### 1. Create the Xcode project

1. Open Xcode → **File > New > Project**
2. Choose **iOS → App** template
3. Set the following:
   - **Product Name**: `Synergy`
   - **Bundle Identifier**: `app.synergy.ios`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Minimum Deployments**: iOS 16.0
4. Uncheck "Include Tests" (optional)
5. Save the project **at the root of this repository** so that `Synergy.xcodeproj` sits alongside the `Synergy/` source folder

### 2. Add source files

In Xcode's Project Navigator, right-click the **Synergy** group → **Add Files to "Synergy"…**

Select the entire `Synergy/` directory. Make sure:
- "Copy items if needed" is **unchecked** (files are already in place)
- "Create groups" is selected
- Target **Synergy** is checked

This will import all directories with their group structure:
```
Synergy/
  App/
  Features/
    Chat/
    Feed/
    Onboarding/
    Profile/
    Subscription/
    Today/
  Models/
  Services/
  UI/
    Animations/
    Components/
```

### 3. Add custom fonts

Synergy uses **Space Grotesk** (headlines) and **Inter** (body text).

**Download the fonts:**
- Space Grotesk: https://fonts.google.com/specimen/Space+Grotesk — download the variable or static family
- Inter: https://fonts.google.com/specimen/Inter — download Regular, Medium, SemiBold, Bold weights

**Add to Xcode:**
1. Create a `Resources/Fonts/` folder inside the Synergy group in Xcode
2. Drag all `.ttf` files into that group
3. In the file inspector for each font file, ensure the **Synergy** target is checked under "Target Membership"

**Register in Info.plist:**

Add the key `Fonts provided by application` (array type) and include each font filename:

```xml
<key>UIAppFonts</key>
<array>
    <string>SpaceGrotesk-Regular.ttf</string>
    <string>SpaceGrotesk-Medium.ttf</string>
    <string>SpaceGrotesk-SemiBold.ttf</string>
    <string>SpaceGrotesk-Bold.ttf</string>
    <string>Inter-Regular.ttf</string>
    <string>Inter-Medium.ttf</string>
    <string>Inter-SemiBold.ttf</string>
    <string>Inter-Bold.ttf</string>
</array>
```

> The app will fall back to system San Francisco fonts if custom fonts are not found. You can verify font loading with `UIFont.familyNames` in a debug print.

### 4. Info.plist — required keys

Add these entries to `Info.plist` (or `Synergy-Info.plist`):

| Key | Type | Value |
|-----|------|-------|
| `NSPhotoLibraryUsageDescription` | String | `Synergy uses your photo library to set your profile photo.` |
| `NSCameraUsageDescription` | String | `Synergy uses your camera to take a profile photo.` |
| `NSLocationWhenInUseUsageDescription` | String | `Synergy uses your location to find matches nearby.` |
| `UIUserInterfaceStyle` | String | `Dark` |

In Xcode 15+ you can edit these directly in the `.xcodeproj` target's **Info** tab.

### 5. Build settings

In the project target → **Build Settings**:
- **iOS Deployment Target**: `16.0`
- **Swift Language Version**: `Swift 5`
- **Supported Destinations**: iPhone only (remove iPad if desired)

### 6. Run the app

1. Select a simulator or physical device (iOS 16+)
2. Press **⌘R** (or the ▶ button)
3. The app launches with the splash screen → onboarding flow → main app

All data is mocked. No backend, API keys, or accounts required.

---

## App Structure

```
SynergyApp (@main)
└── AppRootView (AppCoordinator)
    ├── SplashView           — animated SYNERGY wordmark
    ├── OnboardingContainerView
    │   ├── Step 1: WelcomeView
    │   ├── Step 2: BirthChartCaptureView
    │   ├── Step 3: ChartRevealView
    │   ├── Step 4: IntentionView
    │   ├── Step 5: ProfileSetupView
    │   ├── Step 6: NotificationOptInView
    │   └── Step 7: FirstMatchRevealView
    └── MainTabView
        ├── Tab 1: FeedView         (swipe deck)
        ├── Tab 2: TodayView        (horoscope + rituals)
        ├── Tab 3: ConversationsView / ChatView
        └── Tab 4: ProfileView      (with PaywallView sheet)
```

## Subscription Tiers

| Tier | Price | Features |
|------|-------|---------|
| Stardust | Free | 5 matches/day, basic synastry |
| Cosmic | £14.99/mo | Unlimited matches, full chart, daily reading |
| Oracle | £34.99/mo | Everything + AI insights, ritual planner |

---

## Design System

Colors defined in `Synergy/UI/Theme.swift`:

| Token | Hex | Usage |
|-------|-----|-------|
| `cosmicDark` | `#202124` | Background |
| `cosmicCyan` | `#00F0FF` | Primary accent |
| `cosmicPurple` | `#7D5FFF` | Secondary accent |
| `cosmicNeutral` | `#F8F9FA` | Primary text |
| `cosmicMuted` | `#9AA0A6` | Secondary text |

Typography in `Synergy/UI/Typography.swift`:
- Headlines: Space Grotesk
- Body: Inter
- System labels: SF Mono / system monospaced (CAPS + 1pt kerning)

---

## Production Roadmap

- [ ] Swiss Ephemeris via C bridge for real birth chart calculation
- [ ] StoreKit 2 for subscription management
- [ ] Firebase / Supabase backend with real-time chat
- [ ] Signal Protocol E2E encryption for messages
- [ ] Core ML on-device synastry scoring
- [ ] Apple Sign In + Google Sign In
- [ ] Google Places API for city autocomplete
- [ ] Push notifications via APNs
