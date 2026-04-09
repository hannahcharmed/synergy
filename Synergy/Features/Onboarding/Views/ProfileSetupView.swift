import SwiftUI
import PhotosUI

// MARK: - Screen 05: Profile Setup
// Astro-native prompts, 3-word vibe tags, 1-6 photos.
// Target 80%+ completion, avg 4.2 min on screen.

struct ProfileSetupView: View {
    @EnvironmentObject var vm: OnboardingViewModel
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var showPhotoTip = false

    private var signPrompt: String {
        guard let chart = vm.computedChart else { return "What do people always get wrong about you?" }
        return "What do people always get wrong about your \(chart.sunSign.rawValue)?"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // Header
                header

                // Photo grid
                photoSection

                // Astro-native bio prompt
                bioSection

                // 3-word vibe tags
                vibeSection

                // CTA
                ctaButton
                    .padding(.bottom, Spacing.xxxl)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.lg)
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
                // Existing photos
                ForEach(vm.photos.indices, id: \.self) { i in
                    photoThumbnail(image: vm.photos[i], index: i)
                }

                // Add button (if < 6 photos)
                if vm.photos.count < 6 {
                    PhotosPicker(
                        selection: $photoPickerItems,
                        maxSelectionCount: 6 - vm.photos.count,
                        matching: .images
                    ) {
                        addPhotoButton
                    }
                    .onChange(of: photoPickerItems) { items in
                        loadPhotos(from: items)
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

    private func loadPhotos(from items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                if case .success(let data) = result, let data = data,
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        // Compress to 1200px max per spec
                        let compressed = image.preparingThumbnail(of: CGSize(width: 1200, height: 1200)) ?? image
                        vm.photos.append(compressed)
                    }
                }
            }
        }
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
                    .scrollContentBackground(.hidden)
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

            // Current vibe tags
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

            // Input row
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
