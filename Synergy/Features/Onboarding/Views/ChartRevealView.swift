import SwiftUI

// MARK: - Screen 03: Chart Reveal
// "The magic moment" — first time the user gets something back.
// Animated chart wheel + AI narration. Avg 42s dwell time.

struct ChartRevealView: View {
    @EnvironmentObject var vm: OnboardingViewModel
    @State private var wheelRotation: Double = -90
    @State private var planetOpacities: [Double] = Array(repeating: 0, count: 12)
    @State private var planetScales: [CGFloat] = Array(repeating: 0, count: 12)
    @State private var narrationOpacity: Double = 0
    @State private var traitsOpacity: Double = 0
    @State private var hasAnimated = false

    // Dramatic reveal states
    @State private var wheelScale: CGFloat = 0.3
    @State private var wheelOpacity: Double = 0
    @State private var ringPulse: CGFloat = 1.0
    @State private var glowBurst: Double = 0
    @State private var scanningOpacity: Double = 0
    @State private var scanningDots: Int = 0

    private var chart: BirthChart? { vm.computedChart }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                // Header
                header

                // Chart wheel
                ZStack {
                    // Pulsing outer glow ring (always visible once wheel appears)
                    Circle()
                        .stroke(LinearGradient.cosmicGradient, lineWidth: 1.5)
                        .frame(width: 300, height: 300)
                        .scaleEffect(ringPulse)
                        .opacity(wheelOpacity * 0.4)
                        .blur(radius: 6)

                    // Burst flash ring at the reveal moment
                    Circle()
                        .stroke(Color.cosmicCyan, lineWidth: 2)
                        .frame(width: 320, height: 320)
                        .scaleEffect(1.0 + glowBurst * 0.3)
                        .opacity(glowBurst * 0.8)
                        .blur(radius: 4)

                    chartWheel
                        .scaleEffect(wheelScale)
                        .opacity(wheelOpacity)
                }
                .frame(height: 320)

                // Scanning / calculating label
                Text("CALCULATING_POSITIONS\(String(repeating: ".", count: scanningDots))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.cosmicCyan)
                    .kerning(1.5)
                    .opacity(scanningOpacity)
                    .frame(height: 18)

                // AI narration card
                if let chart = chart {
                    narrationCard(chart: chart)
                        .opacity(narrationOpacity)

                    // Top traits
                    traitsRow(chart: chart)
                        .opacity(traitsOpacity)
                }

                // CTA
                CosmicButton("Find my matches →", variant: .gradient) {
                    vm.advance()
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
            }
            .padding(.top, Spacing.lg)
        }
        .onAppear { runAnimation() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            Text("SEQUENCE // 03")
                .systemLabel()
                .foregroundColor(.cosmicCyan.opacity(0.8))

            Text("Your birth chart")
                .font(SynergyFont.headline(30))
                .foregroundColor(.cosmicNeutral)

            if let chart = chart {
                Text(chart.shortSummary)
                    .font(SynergyFont.headlineMedium(16))
                    .foregroundColor(.cosmicCyan)
            }
        }
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Chart Wheel (animated SVG substitute in SwiftUI)

    private var chartWheel: some View {
        ZStack {
            // Outer rings
            OrbitalRingView(diameter: 260)
            OrbitalRingView(diameter: 210, dashed: true)
            OrbitalRingView(diameter: 160)

            // House dividers (12 sections)
            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(Color.cosmicCyan.opacity(0.08))
                    .frame(width: 1, height: 130)
                    .offset(y: -65)
                    .rotationEffect(.degrees(Double(i) * 30))
            }

            // Planet symbols on the wheel
            if let chart = chart {
                ForEach(Array(chart.positions.prefix(12).enumerated()), id: \.offset) { idx, position in
                    let angle = position.degree
                    let radius: CGFloat = 105
                    let x = radius * cos((angle - 90) * .pi / 180)
                    let y = radius * sin((angle - 90) * .pi / 180)

                    PlanetDot(planet: position.planet, sign: position.sign)
                        .offset(x: x, y: y)
                        .opacity(planetOpacities.indices.contains(idx) ? planetOpacities[idx] : 0)
                        .scaleEffect(planetScales.indices.contains(idx) ? planetScales[idx] : 0)
                }
            }

            // Center — Sun sign
            if let chart = chart {
                VStack(spacing: 2) {
                    Text(chart.sunSign.symbol)
                        .font(.system(size: 28))
                        .foregroundColor(.cosmicCyan)
                    Text(chart.sunSign.rawValue.uppercased())
                        .font(SynergyFont.systemLabel)
                        .foregroundColor(.cosmicMuted)
                        .kerning(2)
                }
            }
        }
        .frame(width: 280, height: 280)
    }

    // MARK: - Planet Dot

    // MARK: - AI Narration Card

    private func narrationCard(chart: BirthChart) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(.cosmicCyan)
                Text("CHART_NARRATION")
                    .systemLabel()
                    .foregroundColor(.cosmicCyan.opacity(0.8))
                Spacer()
                Text("AI · \(chart.sunSign.rawValue)")
                    .systemLabel()
            }

            Text(narrationText(for: chart))
                .font(SynergyFont.body(15))
                .foregroundColor(.cosmicNeutral.opacity(0.85))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Text("dominant energy: \(chart.dominantElement.rawValue.uppercased())")
                .systemLabel()
                .foregroundColor(.cosmicMuted)
        }
        .padding(Spacing.lg)
        .cosmicCard()
        .padding(.horizontal, Spacing.xl)
    }

    private func narrationText(for chart: BirthChart) -> String {
        "Your \(chart.sunSign.rawValue) Sun + \(chart.risingSign.rawValue) rising creates a rare combination: \(elementalDescription(chart)). You carry \(moonDescription(chart)). In relationships, you need depth, honesty, and someone who can match your frequency."
    }

    private func elementalDescription(_ chart: BirthChart) -> String {
        switch (chart.sunSign.element, chart.risingSign.element) {
        case (.water, .water): return "fierce emotional intelligence with an intuitive, empathic lens"
        case (.fire, .air):    return "bold vision with the social grace to inspire anyone"
        case (.earth, .water): return "grounded presence with a quietly magnetic inner world"
        case (.air, .fire):    return "intellectual brilliance with the warmth to draw people in"
        default:               return "a powerful and layered presence that leaves a mark"
        }
    }

    private func moonDescription(_ chart: BirthChart) -> String {
        "a \(chart.moonSign.rawValue) Moon with \(chart.moonSign.element.rawValue.lowercased()) emotional depths"
    }

    // MARK: - Traits Row

    private func traitsRow(chart: BirthChart) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                PlanetAspectTag(text: "\(chart.sunSign.symbol) \(chart.sunSign.rawValue) Sun", highlighted: true)
                PlanetAspectTag(text: "\(chart.moonSign.symbol) \(chart.moonSign.rawValue) Moon")
                PlanetAspectTag(text: "\(chart.risingSign.symbol) \(chart.risingSign.rawValue) Rising")
                ElementBadge(element: chart.dominantElement.rawValue)
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    // MARK: - Animation (enhanced dramatic reveal)

    private func runAnimation() {
        guard !hasAnimated else { return }
        hasAnimated = true

        // Step 1: Wheel scales in with spring
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
            wheelScale = 1.0
            wheelOpacity = 1.0
        }

        // Step 2: "Calculating" scanning label with animated dots
        withAnimation(.easeIn(duration: 0.25).delay(0.3)) {
            scanningOpacity = 1.0
        }
        // Dot animation: cycle 0→3 dots
        for tick in 0..<9 {
            let d = 0.4 + Double(tick) * 0.22
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                withAnimation(.easeInOut(duration: 0.12)) { scanningDots = tick % 4 }
            }
        }

        // Step 3: Pulsing outer ring
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(0.3)) {
            ringPulse = 1.07
        }

        // Step 4: Reveal planets sequentially (staggered, scale+fade in)
        for i in 0..<12 {
            let delay = 0.5 + Double(i) * 0.18
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55).delay(delay)) {
                if i < planetOpacities.count { planetOpacities[i] = 1.0 }
                if i < planetScales.count { planetScales[i] = 1.0 }
            }
        }

        // Step 5: Flash glow burst at end of planet reveal
        withAnimation(.easeIn(duration: 0.2).delay(2.8)) {
            glowBurst = 1.0
            scanningOpacity = 0.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(3.0)) {
            glowBurst = 0.0
        }

        // Step 6: Narration and traits fade in
        withAnimation(.easeOut(duration: 0.7).delay(3.1)) {
            narrationOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.6).delay(3.5)) {
            traitsOpacity = 1.0
        }
    }
}

// MARK: - Planet Dot Component

struct PlanetDot: View {
    let planet: Planet
    let sign: ZodiacSign

    var body: some View {
        VStack(spacing: 2) {
            Text(planet.symbol)
                .font(.system(size: planet == .sun || planet == .moon ? 14 : 11))
                .foregroundColor(dotColor)

            Text(sign.symbol)
                .font(.system(size: 8))
                .foregroundColor(.cosmicMuted)
        }
        .frame(width: 24, height: 24)
        .background(
            Circle()
                .fill(Color.cosmicDark.opacity(0.9))
                .overlay(Circle().strokeBorder(dotColor.opacity(0.5), lineWidth: 1))
        )
        .cosmicGlow(color: dotColor, radius: planet == .venus || planet == .moon ? 6 : 0)
    }

    private var dotColor: Color {
        switch planet {
        case .sun:    return .cosmicFire
        case .moon:   return .cosmicWater
        case .venus:  return Color(hex: "#FF6B9D")
        case .mars:   return .cosmicFire
        default:      return .cosmicCyan.opacity(0.7)
        }
    }
}
