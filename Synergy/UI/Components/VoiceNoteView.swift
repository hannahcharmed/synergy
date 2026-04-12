import SwiftUI

// MARK: - Voice Note Player (incoming / outgoing bubble)

struct VoiceNotePlayerView: View {
    let duration: Double        // seconds
    let isFromCurrentUser: Bool

    @State private var isPlaying = false
    @State private var playProgress: Double = 0
    @State private var timer: Timer? = nil

    private var accentColor: Color { isFromCurrentUser ? .cosmicNeutral : .cosmicCyan }
    private var bgColor: Color {
        isFromCurrentUser ? Color.white.opacity(0.15) : Color(hex: "#1E2229")
    }
    private var timeLabel: String {
        let remaining = duration * (1 - playProgress)
        return String(format: "%d:%02d", Int(remaining) / 60, Int(remaining) % 60)
    }

    // Deterministic mock waveform bars (20 bars)
    private var barHeights: [CGFloat] {
        (0..<20).map { i in
            let h = abs(sin(Double(i) * 1.4 + duration)) * 0.7 + 0.15
            return CGFloat(h)
        }
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Play / Pause button
            Button {
                togglePlayback()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14))
                    .foregroundColor(accentColor)
                    .frame(width: 30, height: 30)
                    .background(accentColor.opacity(0.2))
                    .clipShape(Circle())
            }

            // Waveform
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(0..<barHeights.count, id: \.self) { i in
                        let played = Double(i) / Double(barHeights.count) <= playProgress
                        Capsule()
                            .fill(played ? accentColor : accentColor.opacity(0.3))
                            .frame(width: 3, height: geo.size.height * barHeights[i])
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 28)

            // Duration
            Text(timeLabel)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(accentColor.opacity(0.8))
                .frame(width: 32)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 10)
        .background(bgColor)
        .clipShape(Capsule())
        .onDisappear { stopPlayback() }
    }

    private func togglePlayback() {
        isPlaying ? stopPlayback() : startPlayback()
    }

    private func startPlayback() {
        isPlaying = true
        if playProgress >= 1 { playProgress = 0 }
        let step = 0.05 / duration
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                if playProgress < 1 {
                    withAnimation(.linear(duration: 0.05)) { playProgress += step }
                } else {
                    stopPlayback()
                }
            }
        }
    }

    private func stopPlayback() {
        isPlaying = false
        timer?.invalidate(); timer = nil
    }
}

// MARK: - Voice Note Recorder (input bar overlay)

struct VoiceNoteRecorderView: View {
    @Binding var isRecording: Bool
    var onSend: (Double) -> Void  // passes mock duration

    @State private var phase: Double = 0
    @State private var elapsed: Double = 0
    @State private var timer: Timer? = nil

    private var timeLabel: String {
        String(format: "%d:%02d", Int(elapsed) / 60, Int(elapsed) % 60)
    }

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Cancel
            Button {
                stop(); isRecording = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16))
                    .foregroundColor(.cosmicError)
            }

            // Waveform pulse
            HStack(spacing: 3) {
                ForEach(0..<12, id: \.self) { i in
                    Capsule()
                        .fill(Color.cosmicError)
                        .frame(width: 3,
                               height: 6 + 16 * CGFloat(abs(sin(phase + Double(i) * 0.6))))
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    phase = .pi * 2
                }
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    Task { @MainActor in elapsed += 0.1 }
                }
            }

            Text(timeLabel)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.cosmicNeutral)
                .monospacedDigit()

            Spacer()

            // Send
            Button {
                let dur = max(1, elapsed)
                stop(); isRecording = false
                onSend(dur)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(LinearGradient.cosmicGradient)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(Color.cosmicDarkAlt)
    }

    private func stop() {
        timer?.invalidate(); timer = nil
    }
}
