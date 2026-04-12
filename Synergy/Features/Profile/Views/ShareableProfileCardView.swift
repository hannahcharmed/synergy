import SwiftUI

// MARK: - Shareable Cosmic Profile Card
// Renders a 9:16 card suitable for screenshot + share.
// Uses UIHostingController snapshot for iOS 15 compatibility.
// iOS 16+: replace with ImageRenderer.

struct ShareableProfileCardView: View {
    let user: User

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#0D0A1A"), Color(hex: "#1A1328"), Color(hex: "#0A0D1A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Star field decoration
            starField

            VStack(spacing: Spacing.xl) {
                // App wordmark
                Text("SYNERGY")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .kerning(6)
                    .foregroundStyle(LinearGradient.cosmicGradient)

                Spacer()

                // Avatar
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

                // Name + age
                VStack(spacing: 6) {
                    Text(user.displayName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("\(user.age) · \(user.locationDisplay)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Big Three
                HStack(spacing: Spacing.lg) {
                    bigThreeItem(symbol: "☉", label: "Sun",
                                 value: user.birthChart.sunSign.rawValue)
                    bigThreeItem(symbol: "☽", label: "Moon",
                                 value: user.birthChart.moonSign.rawValue)
                    bigThreeItem(symbol: "AC", label: "Rising",
                                 value: user.birthChart.risingSign.rawValue)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.lg)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .strokeBorder(LinearGradient.cosmicGradient.opacity(0.4), lineWidth: 1)
                )

                // Vibe words
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
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                        }
                    }
                }

                Spacer()

                // Footer CTA
                VStack(spacing: 6) {
                    Text("Find your cosmic match")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    Text("synergy.app")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(LinearGradient.cosmicGradient)
                }
            }
            .padding(Spacing.xl)
        }
        .frame(width: 320, height: 568)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
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
                let x = CGFloat((i * 137 + 23) % Int(geo.size.width))
                let y = CGFloat((i * 97 + 41) % Int(geo.size.height))
                let size = CGFloat((i % 3) + 1)
                Circle()
                    .fill(Color.white.opacity(Double((i % 5) + 1) * 0.07))
                    .frame(width: size, height: size)
                    .position(x: x, y: y)
            }
        }
    }
}

// MARK: - Share Sheet Helper (iOS 15 compatible)

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Snapshot Helper (iOS 15)

extension View {
    /// Renders this view to a UIImage for sharing (iOS 15 compatible).
    func snapshot(size: CGSize) -> UIImage {
        let controller = UIHostingController(rootView: self.ignoresSafeArea())
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
