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

    private var signPrompt: String {
        guard let chart = vm.computedChart else { return "What do people always get wrong about you?" }
        return "What do people always get wrong about your \(chart.sunSign.rawValue)?"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header
                photoSection
                bioSection
                vibeSection
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
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("SEQUENCE // 05")
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
                Text("3 words max")
                    .systemLabel()
            }

            if !vm.vibeWords.isEmpty {
                HStack(spacing: Spacing.sm) {
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
                        .background(Color.cosmicCyan.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.cosmicCyan.opacity(0.4), lineWidth: 1))
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            if vm.vibeWords.count < 3 {
                HStack {
                    TextField("e.g. Intense", text: $vm.vibeInput)
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
