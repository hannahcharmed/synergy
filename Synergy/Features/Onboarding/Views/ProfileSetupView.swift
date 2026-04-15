import SwiftUI
import PhotosUI

// MARK: - Screen 05: Profile Setup

// NOTE: iOS 15 Compatibility
// PhotosPicker (iOS 16+) replaced with PHPickerRepresentable below.
// TextEditor .scrollContentBackground(.hidden) (iOS 16+) replaced with
// UITextView.appearance().backgroundColor = .clear in SynergyApp.init().
// When upgrading to iOS 16+:
//   - Replace @State private var showPhotoPicker + .sheet(isPresented: $showPhotoPicker)
//     with the PhotosPicker / PhotosPickerItem pattern
//   - Add .scrollContentBackground(.hidden) back to TextEditor
//   - Delete PHPickerRepresentable at the bottom of this file

struct ProfileSetupView: View {
    @EnvironmentObject var vm: OnboardingViewModel
    @State private var showPhotoPicker = false
    @State private var promptDraft: [String] = ["", "", ""]
    @State private var promptQuestions: [PromptQuestion] = [.wrongAboutSign, .perfectDay, .loveLanguage]
    @State private var activePromptSlots: Int = 1
    @State private var showPromptPicker = false
    @State private var pickingSlot: Int = 0

    private var signPrompt: String {
        guard let chart = vm.computedChart else { return "What do people always get wrong about you?" }
        return "What do people always get wrong about your \(chart.sunSign.rawValue)?"
    }

    private var vibeChipSuggestions: [String] {
        guard let chart = vm.computedChart else {
            return ["Intense", "Curious", "Dreamy", "Grounded", "Electric", "Magnetic"]
        }
        switch chart.sunSign {
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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header
                photoSection
                bioSection
                vibeSection
                promptsSection
                ctaButton
                    .padding(.bottom, Spacing.xxxl)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.lg)
        }
        .sheet(isPresented: $showPhotoPicker) {
            PHPickerRepresentable(maxSelection: max(1, 6 - vm.photos.count)) { images in
                vm.photos.append(contentsOf: images)
            }
        }
        .sheet(isPresented: $showPromptPicker) {
            PromptPickerSheet(selectedQuestion: promptQuestions[pickingSlot]) { chosen in
                promptQuestions[pickingSlot] = chosen
                showPromptPicker = false
            }
        }
        .onDisappear { syncPromptsToVM() }
    }

    private func syncPromptsToVM() {
        vm.prompts = zip(promptQuestions.prefix(activePromptSlots), promptDraft.prefix(activePromptSlots))
            .compactMap { q, a in
                let trimmed = a.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : ProfilePrompt(question: q.rawValue, answer: trimmed)
            }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("04 / 07")
                .systemLabel()
                .foregroundColor(.cosmicCyan.opacity(0.8))

            Text("Your profile")
                .font(SynergyFont.headline(30))
                .foregroundColor(.cosmicNeutral)

            Text("Show your cosmic self")
                .font(SynergyFont.body(15))
                .foregroundColor(.cosmicMuted)
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("PHOTOS")
                    .systemLabel()
                Spacer()
                Text("\(vm.photos.count) / 6")
                    .systemLabel()
                    .foregroundColor(vm.photos.isEmpty ? .cosmicError : .cosmicCyan)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                ForEach(vm.photos.indices, id: \.self) { i in
                    photoThumbnail(image: vm.photos[i], index: i)
                }

                if vm.photos.count < 6 {
                    Button { showPhotoPicker = true } label: {
                        addPhotoButton
                    }
                }
            }

            if vm.photos.isEmpty {
                Label("Add at least 1 photo to continue", systemImage: "info.circle")
                    .font(SynergyFont.body(12))
                    .foregroundColor(.cosmicError.opacity(0.8))
            }
        }
    }

    private func photoThumbnail(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))

            Button {
                vm.photos.remove(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.cosmicDark)
                    .background(Circle().fill(Color.cosmicNeutral))
                    .padding(4)
            }
        }
    }

    private var addPhotoButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.sm)
                .fill(Color.cosmicDarkAlt)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .strokeBorder(Color.cosmicBorder, style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                )

            VStack(spacing: Spacing.xs) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(.cosmicCyan)
                Text("Add")
                    .font(SynergyFont.body(11))
                    .foregroundColor(.cosmicMuted)
            }
        }
        .frame(width: 100, height: 120)
    }

    // MARK: - Bio Section

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("ASTRO_PROMPT")
                .systemLabel()

            Text(signPrompt)
                .font(SynergyFont.body(14))
                .foregroundColor(.cosmicNeutral.opacity(0.7))
                .lineSpacing(3)

            ZStack(alignment: .topLeading) {
                if vm.bio.isEmpty {
                    Text("Share your answer...")
                        .font(SynergyFont.body(15))
                        .foregroundColor(.cosmicMuted.opacity(0.5))
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                }

                TextEditor(text: $vm.bio)
                    .font(SynergyFont.body(15))
                    .foregroundColor(.cosmicNeutral)
                    // iOS 16+: restore .scrollContentBackground(.hidden)
                    // iOS 15: handled by UITextView.appearance().backgroundColor = .clear in SynergyApp
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.sm)
                    .frame(minHeight: 100)
                    .onChange(of: vm.bio) { newValue in
                        if newValue.count > 300 { vm.bio = String(newValue.prefix(300)) }
                    }
            }
            .background(Color.cosmicDarkAlt)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .strokeBorder(Color.cosmicBorder, lineWidth: 1)
            )

            HStack {
                Spacer()
                Text("\(vm.bio.count)/300")
                    .systemLabel()
                    .foregroundColor(vm.bio.count > 270 ? .cosmicError : .cosmicMuted)
            }
        }
    }

    // MARK: - Vibe Words

    private var vibeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("COSMIC_VIBE")
                    .systemLabel()
                Spacer()
                Text("\(vm.vibeWords.count) / 3")
                    .systemLabel()
                    .foregroundColor(vm.vibeWords.count == 3 ? .cosmicCyan : .cosmicMuted)
            }

            // Selected vibe words chips
            if !vm.vibeWords.isEmpty {
                ChipRow(spacing: Spacing.sm) {
                    ForEach(Array(vm.vibeWords.enumerated()), id: \.offset) { i, word in
                        HStack(spacing: 4) {
                            Text(word)
                                .font(SynergyFont.body(13, weight: .medium))
                                .foregroundColor(.cosmicNeutral)
                            Button { vm.removeVibeWord(at: i) } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.cosmicMuted)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.cosmicCyan.opacity(0.15))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.cosmicCyan.opacity(0.5), lineWidth: 1))
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Zodiac-based suggestion chips
            if vm.vibeWords.count < 3 {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Suggestions for your sign")
                        .font(SynergyFont.body(11))
                        .foregroundColor(.cosmicMuted)
                    ChipRow(spacing: Spacing.sm) {
                        ForEach(vibeChipSuggestions.filter { !vm.vibeWords.contains($0) }, id: \.self) { chip in
                            Button {
                                if vm.vibeWords.count < 3 {
                                    withAnimation(.spring(response: 0.3)) {
                                        vm.vibeWords.append(chip)
                                    }
                                }
                            } label: {
                                Text(chip)
                                    .font(SynergyFont.body(13))
                                    .foregroundColor(.cosmicCyan.opacity(0.9))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.cosmicCyan.opacity(0.06))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().strokeBorder(Color.cosmicCyan.opacity(0.25), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Custom input
            if vm.vibeWords.count < 3 {
                HStack {
                    TextField("Or type your own...", text: $vm.vibeInput)
                        .font(SynergyFont.body(15))
                        .foregroundColor(.cosmicNeutral)
                        .submitLabel(.done)
                        .onSubmit { vm.addVibeWord() }

                    if !vm.vibeInput.isEmpty {
                        Button { vm.addVibeWord() } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.cosmicCyan)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .frame(height: 48)
                .background(Color.cosmicDarkAlt)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .strokeBorder(Color.cosmicBorder, lineWidth: 1)
                )
            }

            Text("These appear on your match card and spark conversation")
                .font(SynergyFont.body(11))
                .foregroundColor(.cosmicMuted)
        }
        .animation(.spring(response: 0.3), value: vm.vibeWords.count)
    }

    // MARK: - Prompts Section

    private var promptsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("YOUR_PROMPTS")
                    .systemLabel()
                Spacer()
                Text("\(activePromptSlots) / 3")
                    .systemLabel()
                    .foregroundColor(.cosmicMuted)
            }

            ForEach(0..<activePromptSlots, id: \.self) { i in
                promptSlot(index: i)
            }

            if activePromptSlots < 3 {
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        activePromptSlots += 1
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.cosmicCyan)
                        Text("Add another prompt")
                            .font(SynergyFont.body(14))
                            .foregroundColor(.cosmicCyan)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .background(Color.cosmicDarkAlt)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .strokeBorder(Color.cosmicBorder, style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
                }
                .buttonStyle(.plain)
            }

            Text("Prompts help matches get to know the real you")
                .font(SynergyFont.body(11))
                .foregroundColor(.cosmicMuted)
        }
    }

    private func promptSlot(index: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Question picker — Hinge-style sheet
            Button {
                pickingSlot = index
                showPromptPicker = true
            } label: {
                HStack {
                    Text(promptQuestions[index].rawValue)
                        .font(SynergyFont.body(13, weight: .semibold))
                        .foregroundColor(.cosmicCyan)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(.cosmicCyan)
                }
            }
            .buttonStyle(.plain)

            // Answer text editor
            ZStack(alignment: .topLeading) {
                if promptDraft[index].isEmpty {
                    Text("Your answer...")
                        .font(SynergyFont.body(14))
                        .foregroundColor(.cosmicMuted.opacity(0.5))
                        .padding(.horizontal, Spacing.sm)
                        .padding(.top, Spacing.sm)
                }
                TextEditor(text: $promptDraft[index])
                    .font(SynergyFont.body(14))
                    .foregroundColor(.cosmicNeutral)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.sm)
                    .frame(minHeight: 80)
                    .onChange(of: promptDraft[index]) { v in
                        if v.count > 150 { promptDraft[index] = String(v.prefix(150)) }
                    }
            }
            .background(Color.cosmicDarkAlt)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .strokeBorder(Color.cosmicBorder, lineWidth: 1)
            )

            HStack {
                Spacer()
                Text("\(promptDraft[index].count)/150")
                    .systemLabel()
                    .foregroundColor(promptDraft[index].count > 130 ? .cosmicError : .cosmicMuted)
                if index > 0 {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            if index < promptDraft.count { promptDraft[index] = "" }
                            activePromptSlots -= 1
                        }
                    } label: {
                        Text("Remove")
                            .font(SynergyFont.body(11))
                            .foregroundColor(.cosmicError.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.cosmicCard)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.sm)
                .strokeBorder(Color.cosmicBorder, lineWidth: 1)
        )
    }

    // MARK: - CTA

    private var ctaButton: some View {
        VStack(spacing: Spacing.sm) {
            CosmicButton(
                "Looks good →",
                variant: vm.canAdvanceFromProfile ? .gradient : .outlined
            ) {
                vm.advance()
            }
            .disabled(!vm.canAdvanceFromProfile)
            .opacity(vm.canAdvanceFromProfile ? 1.0 : 0.4)

            if !vm.canAdvanceFromProfile {
                Button("Complete later") { vm.advance() }
                    .font(SynergyFont.body(13))
                    .foregroundColor(.cosmicMuted)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.canAdvanceFromProfile)
    }
}

// MARK: - Prompt Picker Sheet (Hinge-style)

struct PromptPickerSheet: View {
    let selectedQuestion: PromptQuestion
    let onSelect: (PromptQuestion) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicDark.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(PromptQuestion.allCases, id: \.self) { question in
                            Button {
                                onSelect(question)
                            } label: {
                                HStack(spacing: Spacing.md) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(question.rawValue)
                                            .font(SynergyFont.body(15))
                                            .foregroundColor(.cosmicNeutral)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer()
                                    if question == selectedQuestion {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.cosmicCyan)
                                    }
                                }
                                .padding(.horizontal, Spacing.xl)
                                .padding(.vertical, Spacing.md)
                                .background(
                                    question == selectedQuestion
                                        ? Color.cosmicCyan.opacity(0.08)
                                        : Color.clear
                                )
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .overlay(Color.cosmicBorder)
                                .padding(.leading, Spacing.xl)
                        }
                    }
                    .padding(.top, Spacing.sm)
                }
            }
            .navigationTitle("Choose a prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.cosmicMuted)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - ChipRow (horizontal scrolling chip container, iOS 15 compatible)

struct ChipRow<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()   // call builder immediately; avoids @escaping on non-escaping param
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                content
            }
        }
    }
}

// MARK: - PHPickerRepresentable (iOS 15 fallback for PhotosPicker)
// Delete this when upgrading to iOS 16+ (see note at top of file)

struct PHPickerRepresentable: UIViewControllerRepresentable {
    let maxSelection: Int
    var onPicked: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = maxSelection
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPicked: onPicked) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPicked: ([UIImage]) -> Void
        init(onPicked: @escaping ([UIImage]) -> Void) { self.onPicked = onPicked }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            var images: [UIImage] = []
            let group = DispatchGroup()
            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let image = object as? UIImage {
                        let sized = image.preparingThumbnail(of: CGSize(width: 1200, height: 1200)) ?? image
                        images.append(sized)
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) { self.onPicked(images) }
        }
    }
}
