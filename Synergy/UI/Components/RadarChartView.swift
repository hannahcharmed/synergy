import SwiftUI

// MARK: - Radar Chart (Pentagon / Synastry breakdown)
// Five axes: Synastry Core · Elemental · Intent · Transit · Venus+Moon

struct RadarChartView: View {
    struct Axis {
        let label: String
        let value: Double   // 0.0 – 1.0
        let color: Color
    }

    let axes: [Axis]
    var animated: Bool = true

    @State private var progress: Double = 0

    private let sides: Int = 5
    private let gridLevels: Int = 4

    var body: some View {
        ZStack {
            // Grid rings
            ForEach(1...gridLevels, id: \.self) { level in
                PolygonShape(sides: sides, scale: Double(level) / Double(gridLevels))
                    .stroke(Color.cosmicBorder.opacity(0.4), lineWidth: 1)
            }

            // Axis lines
            ForEach(0..<sides, id: \.self) { i in
                Path { p in
                    p.move(to: center)
                    p.addLine(to: point(index: i, scale: 1.0))
                }
                .stroke(Color.cosmicBorder.opacity(0.3), lineWidth: 1)
            }

            // Filled area
            filledPolygon
                .fill(LinearGradient.cosmicGradient)
                .opacity(0.25)
            filledPolygon
                .stroke(LinearGradient.cosmicGradient, lineWidth: 2)

            // Axis labels
            ForEach(0..<min(sides, axes.count), id: \.self) { i in
                axisLabel(index: i)
            }

            // Value dots
            ForEach(0..<min(sides, axes.count), id: \.self) { i in
                Circle()
                    .fill(axes[i].color)
                    .frame(width: 8, height: 8)
                    .position(point(index: i, scale: axes[i].value * progress))
                    .cosmicGlow(color: axes[i].color, radius: 6)
            }
        }
        .frame(width: 220, height: 220)
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 0.8).delay(0.1)) { progress = 1 }
            } else {
                progress = 1
            }
        }
    }

    // MARK: - Geometry helpers (coordinate origin: centre of 220×220 frame)

    private let size: CGFloat = 220
    private var center: CGPoint { CGPoint(x: size / 2, y: size / 2) }
    private var radius: CGFloat { size / 2 - 28 } // leave room for labels

    private func point(index: Int, scale: Double) -> CGPoint {
        // Start at top (-π/2), rotate clockwise
        let angle = (2 * .pi / Double(sides)) * Double(index) - .pi / 2
        return CGPoint(
            x: center.x + CGFloat(cos(angle) * Double(radius) * scale),
            y: center.y + CGFloat(sin(angle) * Double(radius) * scale)
        )
    }

    private var filledPolygon: Path {
        Path { path in
            guard !axes.isEmpty else { return }
            let first = point(index: 0, scale: axes[0].value * progress)
            path.move(to: first)
            for i in 1..<min(sides, axes.count) {
                path.addLine(to: point(index: i, scale: axes[i].value * progress))
            }
            path.closeSubpath()
        }
    }

    @ViewBuilder
    private func axisLabel(index: Int) -> some View {
        let pt = point(index: index, scale: 1.28)
        Text(axes[index].label)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundColor(.cosmicMuted)
            .multilineTextAlignment(.center)
            .frame(width: 52)
            .position(pt)
    }
}

// MARK: - Polygon background shape

private struct PolygonShape: Shape {
    let sides: Int
    let scale: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2 * CGFloat(scale)
        var path = Path()
        for i in 0..<sides {
            let angle = (2 * .pi / Double(sides)) * Double(i) - .pi / 2
            let pt = CGPoint(x: center.x + r * CGFloat(cos(angle)),
                             y: center.y + r * CGFloat(sin(angle)))
            i == 0 ? path.move(to: pt) : path.addLine(to: pt)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Convenience builder from SynastryResult

extension RadarChartView {
    static func fromSynastry(score: Int) -> RadarChartView {
        let s = Double(score) / 100
        return RadarChartView(axes: [
            Axis(label: "SYNASTRY\nCORE",   value: s * 1.00, color: .cosmicPurple),
            Axis(label: "ELEMENTAL",         value: s * 0.90, color: .cosmicCyan),
            Axis(label: "INTENT\nALIGN",     value: s * 0.85, color: .cosmicSuccess),
            Axis(label: "TRANSIT\nBOOST",    value: s * 0.70, color: Color(hex: "#FFD700")),
            Axis(label: "VENUS\n+ MOON",     value: s * 0.95, color: Color(hex: "#FF6B9D")),
        ])
    }
}
