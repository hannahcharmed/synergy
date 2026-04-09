import SwiftUI

// MARK: - Text Field with ASTRO_OS system aesthetic

struct CosmicTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var icon: String? = nil
    var isSecure: Bool = false
    var isFocused: Bool = false

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // System-style label
            Text(label)
                .systemLabel()

            // Input field
            HStack(spacing: Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(focused ? .cosmicCyan : .cosmicMuted)
                        .frame(width: 20)
                }

                if isSecure {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.cosmicMuted))
                        .font(SynergyFont.body(16))
                        .foregroundColor(.cosmicNeutral)
                        .focused($focused)
                } else {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.cosmicMuted.opacity(0.6)))
                        .font(SynergyFont.body(16))
                        .foregroundColor(.cosmicNeutral)
                        .keyboardType(keyboardType)
                        .focused($focused)
                }
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 52)
            .background(Color.cosmicDarkAlt)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .strokeBorder(
                        focused ? Color.cosmicCyan.opacity(0.7) : Color.cosmicBorder,
                        lineWidth: focused ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: focused)
        }
    }
}

// MARK: - Date Field (YYYY · MM · DD style)

struct CosmicDateField: View {
    let label: String
    @Binding var date: Date?
    var isOptional: Bool = false

    @State private var showPicker = false
    @State private var tempDate = Date()

    private var displayText: String {
        guard let date = date else { return "YYYY · MM · DD" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy · MM · dd"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(label).systemLabel()
                if isOptional {
                    Text("· optional but recommended")
                        .font(SynergyFont.systemLabel)
                        .foregroundColor(.cosmicCyan.opacity(0.7))
                        .kerning(1)
                }
            }

            Button(action: { showPicker.toggle() }) {
                HStack {
                    Text(displayText)
                        .font(date == nil
                              ? SynergyFont.body(16)
                              : SynergyFont.headlineMedium(16))
                        .foregroundColor(date == nil ? .cosmicMuted.opacity(0.6) : .cosmicNeutral)
                        .kerning(date == nil ? 0 : 1)

                    Spacer()

                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.cosmicMuted)
                }
                .padding(.horizontal, Spacing.md)
                .frame(height: 52)
                .background(Color.cosmicDarkAlt)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .strokeBorder(
                            showPicker ? Color.cosmicCyan.opacity(0.7) : Color.cosmicBorder,
                            lineWidth: showPicker ? 1.5 : 1
                        )
                )
            }
            .buttonStyle(.plain)

            if showPicker {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { date ?? Date() },
                        set: { date = $0; tempDate = $0 }
                    ),
                    in: ...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .colorScheme(.dark)
                .accentColor(.cosmicCyan)
                .padding(Spacing.sm)
                .background(Color.cosmicCard)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showPicker)
    }
}

// MARK: - Time Field

struct CosmicTimeField: View {
    let label: String
    @Binding var time: Date?
    var isOptional: Bool = false

    private var displayText: String {
        guard let time = time else { return "HH : MM" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(label).systemLabel()
                if isOptional {
                    Text("· optional but recommended")
                        .font(SynergyFont.systemLabel)
                        .foregroundColor(.cosmicCyan.opacity(0.7))
                        .kerning(1)
                }
            }

            DatePicker(
                "",
                selection: Binding(
                    get: { time ?? Date() },
                    set: { time = $0 }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)
            .colorScheme(.dark)
            .accentColor(.cosmicCyan)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.md)
            .frame(height: 52)
            .background(Color.cosmicDarkAlt)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .strokeBorder(Color.cosmicBorder, lineWidth: 1)
            )
        }
    }
}
