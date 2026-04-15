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
    @State private var selectedPlacement: PlanetaryPosition? = nil

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
                    Circle()
                        .stroke(LinearGradient.cosmicGradient, lineWidth: 1.5)
                        .frame(width: 300, height: 300)
                        .scaleEffect(ringPulse)
                        .opacity(wheelOpacity * 0.4)
                        .blur(radius: 6)

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

                    // Planetary placements list
                    placementsSection(chart: chart)
                        .opacity(narrationOpacity)
                }

                // Bottom padding so the last row clears the sticky button
                Color.clear.frame(height: 100)
            }
            .padding(.top, Spacing.lg)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            stickyMatchButton
        }
        .onAppear { runAnimation() }
        .sheet(item: $selectedPlacement) { placement in
            if let chart = chart {
                PlacementDetailSheet(placement: placement, chart: chart)
            }
        }
    }

    // MARK: - Sticky CTA

    private var stickyMatchButton: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.cosmicBorder)
            CosmicButton("Find my matches →", variant: .gradient) {
                vm.advance()
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .background(Color.cosmicDark)
        .opacity(narrationOpacity > 0.3 ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: narrationOpacity)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            Text("02 / 07")
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

    // MARK: - Chart Wheel

    private var chartWheel: some View {
        ZStack {
            OrbitalRingView(diameter: 260)
            OrbitalRingView(diameter: 210, dashed: true)
            OrbitalRingView(diameter: 160)

            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(Color.cosmicCyan.opacity(0.08))
                    .frame(width: 1, height: 130)
                    .offset(y: -65)
                    .rotationEffect(.degrees(Double(i) * 30))
            }

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

    // MARK: - AI Narration Card

    private func narrationCard(chart: BirthChart) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(.cosmicCyan)
                Text("PLANET_INSIGHTS")
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

    // MARK: - Planetary Placements List

    private func placementsSection(chart: BirthChart) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "list.star")
                    .font(.system(size: 11))
                    .foregroundColor(.cosmicCyan)
                Text("CHART_BREAKDOWN")
                    .systemLabel()
                    .foregroundColor(.cosmicCyan.opacity(0.8))
                Spacer()
                Text("TAP TO EXPLORE")
                    .systemLabel()
                    .foregroundColor(.cosmicMuted.opacity(0.6))
            }
            .padding(.horizontal, Spacing.xl)

            VStack(spacing: 1) {
                ForEach(chart.positions) { position in
                    Button {
                        selectedPlacement = position
                    } label: {
                        placementRow(position)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.cosmicCard)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(Color.cosmicBorder, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.xl)
        }
    }

    private func placementRow(_ position: PlanetaryPosition) -> some View {
        HStack(spacing: Spacing.md) {
            // Planet symbol
            Text(position.planet.symbol)
                .font(.system(size: position.planet == .ascendant || position.planet == .midheaven ? 11 : 16))
                .foregroundColor(planetColor(position.planet))
                .frame(width: 26)

            // Planet name
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(position.planet.rawValue)
                        .font(SynergyFont.body(14, weight: .medium))
                        .foregroundColor(.cosmicNeutral)
                    if position.isRetrograde {
                        Text("℞")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.cosmicError.opacity(0.8))
                    }
                }
                Text("House \(position.houseNumber)")
                    .font(SynergyFont.body(11))
                    .foregroundColor(.cosmicMuted)
            }

            Spacer()

            // Sign + degree
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(position.sign.symbol)
                        .font(.system(size: 13))
                        .foregroundColor(.cosmicCyan.opacity(0.8))
                    Text(position.sign.rawValue)
                        .font(SynergyFont.body(13, weight: .medium))
                        .foregroundColor(.cosmicNeutral)
                }
                Text(position.formattedDegree)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.cosmicMuted)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(.cosmicMuted.opacity(0.5))
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, 12)
        .background(Color.cosmicCard)
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(Color.cosmicBorder.opacity(0.5))
                .padding(.leading, Spacing.lg)
        }
    }

    private func planetColor(_ planet: Planet) -> Color {
        switch planet {
        case .sun:       return .cosmicFire
        case .moon:      return .cosmicWater
        case .venus:     return Color(hex: "#FF6B9D")
        case .mars:      return .cosmicFire
        case .ascendant: return .cosmicCyan
        case .midheaven: return .cosmicPurple
        default:         return .cosmicCyan.opacity(0.7)
        }
    }

    // MARK: - Animation

    private func runAnimation() {
        guard !hasAnimated else { return }
        hasAnimated = true

        withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
            wheelScale = 1.0
            wheelOpacity = 1.0
        }

        withAnimation(.easeIn(duration: 0.25).delay(0.3)) {
            scanningOpacity = 1.0
        }
        for tick in 0..<9 {
            let d = 0.4 + Double(tick) * 0.22
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                withAnimation(.easeInOut(duration: 0.12)) { scanningDots = tick % 4 }
            }
        }

        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(0.3)) {
            ringPulse = 1.07
        }

        for i in 0..<12 {
            let delay = 0.5 + Double(i) * 0.18
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55).delay(delay)) {
                if i < planetOpacities.count { planetOpacities[i] = 1.0 }
                if i < planetScales.count { planetScales[i] = 1.0 }
            }
        }

        withAnimation(.easeIn(duration: 0.2).delay(2.8)) {
            glowBurst = 1.0
            scanningOpacity = 0.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(3.0)) {
            glowBurst = 0.0
        }

        withAnimation(.easeOut(duration: 0.7).delay(3.1)) {
            narrationOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.6).delay(3.5)) {
            traitsOpacity = 1.0
        }
    }
}

// MARK: - Placement Detail Sheet

struct PlacementDetailSheet: View {
    let placement: PlanetaryPosition
    let chart: BirthChart
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        // Planet hero
                        planetHero

                        // Position summary
                        positionSummary

                        // Interpretation
                        interpretationCard

                        // Key aspects from this chart
                        keyAspectsCard
                    }
                    .padding(Spacing.xl)
                    .padding(.bottom, Spacing.xxxl)
                }
            }
            .navigationTitle("\(placement.planet.rawValue) in \(placement.sign.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.cosmicCyan)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Planet Hero

    private var planetHero: some View {
        HStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(planetColor.opacity(0.15))
                    .frame(width: 72, height: 72)
                Text(placement.planet.symbol)
                    .font(.system(size: placement.planet == .ascendant || placement.planet == .midheaven ? 22 : 34))
                    .foregroundColor(planetColor)
            }
            .cosmicGlow(color: planetColor, radius: 16)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(placement.planet.rawValue)
                        .font(SynergyFont.headline(22))
                        .foregroundColor(.cosmicNeutral)
                    if placement.isRetrograde {
                        Text("℞")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.cosmicError)
                    }
                }
                HStack(spacing: 6) {
                    Text(placement.sign.symbol)
                        .font(.system(size: 16))
                    Text(placement.sign.rawValue)
                        .font(SynergyFont.headlineMedium(16))
                }
                .foregroundColor(.cosmicCyan)

                Text("House \(placement.houseNumber)  ·  \(placement.formattedDegree)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.cosmicMuted)
            }
        }
    }

    // MARK: - Position Summary chips

    private var positionSummary: some View {
        HStack(spacing: Spacing.sm) {
            tagPill(placement.sign.element.rawValue, color: elementColor)
            tagPill(placement.sign.modality.rawValue, color: .cosmicCyan)
            tagPill("House \(placement.houseNumber)", color: .cosmicPurple)
            if placement.isRetrograde {
                tagPill("Retrograde", color: .cosmicError)
            }
        }
    }

    private func tagPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(SynergyFont.body(12, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Interpretation Card

    private var interpretationCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundColor(.cosmicCyan)
                Text("PLANET_INSIGHTS")
                    .systemLabel()
                    .foregroundColor(.cosmicCyan.opacity(0.8))
            }

            Text(placementInterpretation)
                .font(SynergyFont.body(15))
                .foregroundColor(.cosmicNeutral.opacity(0.85))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .cosmicCard()
    }

    // MARK: - Key Aspects Card

    private var keyAspectsCard: some View {
        let aspects = notableAspects
        guard !aspects.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("KEY_ASPECTS")
                    .systemLabel()
                    .foregroundColor(.cosmicCyan.opacity(0.8))

                ForEach(aspects, id: \.self) { aspect in
                    HStack(spacing: Spacing.sm) {
                        Text("·")
                            .foregroundColor(.cosmicCyan)
                        Text(aspect)
                            .font(SynergyFont.body(14))
                            .foregroundColor(.cosmicNeutral.opacity(0.8))
                            .lineSpacing(3)
                    }
                }
            }
            .padding(Spacing.lg)
            .cosmicCard()
        )
    }

    // MARK: - Interpretation text

    private var placementInterpretation: String {
        let planetMeaning = planetMeaningText(placement.planet)
        let signQuality   = signQualityText(placement.sign)
        let houseContext  = houseContextText(placement.houseNumber)
        let retroNote     = placement.isRetrograde
            ? " With \(placement.planet.rawValue) retrograde, this energy turns inward — inviting reflection and a more deliberate expression."
            : ""
        return "\(planetMeaning) \(signQuality) \(houseContext)\(retroNote)"
    }

    private func planetMeaningText(_ planet: Planet) -> String {
        switch planet {
        case .sun:       return "Your Sun defines your core identity and the energy you radiate into the world."
        case .moon:      return "Your Moon governs your emotional world, instincts, and what makes you feel safe."
        case .mercury:   return "Mercury shapes how you think, communicate, and process information."
        case .venus:     return "Venus reveals how you love, what you're drawn to, and your aesthetic nature."
        case .mars:      return "Mars is your drive — how you pursue desire, assert yourself, and take action."
        case .jupiter:   return "Jupiter shows where you find abundance, wisdom, and your greatest growth."
        case .saturn:    return "Saturn points to where you're asked to build discipline, face challenges, and earn mastery."
        case .uranus:    return "Uranus marks where you crave freedom, originality, and sudden breakthrough."
        case .neptune:   return "Neptune rules your intuition, dreams, and the places where reality dissolves into something more."
        case .pluto:     return "Pluto governs transformation — where life asks you to shed what no longer serves."
        case .ascendant: return "Your Ascendant (Rising sign) is the mask you wear and the first impression you make on the world."
        case .midheaven: return "Your Midheaven reflects your public path, career calling, and how you're seen in the outer world."
        case .chiron:    return "Chiron is the wounded healer — pointing to your deepest wound and your greatest gift."
        case .northNode: return "Your North Node shows the soul's direction in this lifetime — the growth edge you're called toward."
        }
    }

    private func signQualityText(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries:       return "In Aries, this energy is bold, impulsive, and fiercely independent."
        case .taurus:      return "In Taurus, this energy is patient, sensory, and deeply rooted in the material world."
        case .gemini:      return "In Gemini, this energy is quick, curious, and endlessly adaptable."
        case .cancer:      return "In Cancer, this energy is nurturing, intuitive, and protective of those it loves."
        case .leo:         return "In Leo, this energy is radiant, generous, and drawn to creative self-expression."
        case .virgo:       return "In Virgo, this energy is precise, analytical, and devoted to service and craft."
        case .libra:       return "In Libra, this energy seeks harmony, beauty, and deep relational balance."
        case .scorpio:     return "In Scorpio, this energy is intense, transformative, and unafraid of depth."
        case .sagittarius: return "In Sagittarius, this energy is expansive, philosophical, and hungry for truth."
        case .capricorn:   return "In Capricorn, this energy is disciplined, ambitious, and quietly determined."
        case .aquarius:    return "In Aquarius, this energy is visionary, unconventional, and fuelled by a sense of collective purpose."
        case .pisces:      return "In Pisces, this energy is fluid, empathic, and attuned to what lies beyond the visible."
        }
    }

    private func houseContextText(_ house: Int) -> String {
        switch house {
        case 1:  return "Placed in the 1st house, this colours your identity and self-presentation directly."
        case 2:  return "In the 2nd house, this touches your relationship with resources, money, and self-worth."
        case 3:  return "In the 3rd house, this influences communication, learning, and your immediate environment."
        case 4:  return "In the 4th house, this shapes your home, family, and emotional foundations."
        case 5:  return "In the 5th house, this energises creativity, romance, and self-expression."
        case 6:  return "In the 6th house, this influences your daily routines, health, and how you show up in work."
        case 7:  return "In the 7th house, this is most alive in partnerships — romantic, creative, or professional."
        case 8:  return "In the 8th house, this deepens themes of intimacy, shared resources, and transformation."
        case 9:  return "In the 9th house, this expands through travel, philosophy, and the search for higher meaning."
        case 10: return "In the 10th house, this shapes your public life, reputation, and life path."
        case 11: return "In the 11th house, this thrives in community, friendship, and collective vision."
        case 12: return "In the 12th house, this operates quietly behind the scenes — in solitude, dreams, and the unconscious."
        default: return ""
        }
    }

    private var notableAspects: [String] {
        let hasSun    = chart.positions.contains(where: { $0.planet == .sun })
        let hasMoon   = chart.positions.contains(where: { $0.planet == .moon })
        let hasVenus  = chart.positions.contains(where: { $0.planet == .venus })
        let sunElem   = chart.positions.first(where: { $0.planet == .sun })?.sign.element
        let moonElem  = chart.positions.first(where: { $0.planet == .moon })?.sign.element

        var result: [String] = []

        switch placement.planet {
        case .venus:
            if hasMoon {
                result.append("Venus–Moon: your emotional needs and love style are deeply intertwined, giving relationships an almost psychic quality.")
            }
            if hasSun {
                result.append("Venus–Sun: your identity and how you love are closely aligned — you radiate the qualities you're attracted to.")
            }
        case .moon:
            if hasVenus {
                result.append("Moon–Venus: emotional warmth and aesthetic sensitivity blend, making you instinctively nurturing in love.")
            }
        case .mars:
            if hasVenus {
                result.append("Mars–Venus: a charged dynamic between your desire nature and love style — attraction is rarely subtle for you.")
            }
        case .sun:
            if hasMoon {
                let dynamic = sunElem == moonElem ? "harmony" : "creative tension"
                result.append("Sun–Moon: your conscious identity and emotional instincts work in \(dynamic), shaping a complex, layered self.")
            }
        default:
            break
        }

        if result.isEmpty {
            result.append("\(placement.planet.rawValue) in \(placement.sign.rawValue) is a significant placement that colours the way this energy expresses throughout your chart.")
        }

        return result
    }

    // MARK: - Colours

    private var planetColor: Color {
        switch placement.planet {
        case .sun:       return .cosmicFire
        case .moon:      return .cosmicWater
        case .venus:     return Color(hex: "#FF6B9D")
        case .mars:      return .cosmicFire
        case .ascendant: return .cosmicCyan
        case .midheaven: return .cosmicPurple
        default:         return .cosmicCyan
        }
    }

    private var elementColor: Color {
        switch placement.sign.element {
        case .fire:  return .cosmicFire
        case .water: return .cosmicWater
        case .air:   return .cosmicCyan
        case .earth: return Color(hex: "#6BCB77")
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
