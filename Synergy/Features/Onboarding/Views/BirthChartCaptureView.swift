import SwiftUI

// MARK: - Screen 02: Birth Chart Capture
// Highest-friction step. Users who complete this churn 60% less.
// "optional but recommended" on birth time increases completion 31%

struct BirthChartCaptureView: View {
    @EnvironmentObject var vm: OnboardingViewModel
    @FocusState private var focusedField: Field?

    enum Field { case name, city }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // Header
                header

                // Form fields
                formFields

                // Accuracy callout
                accuracyCallout

                // CTA
                ctaButton
                    .padding(.top, Spacing.sm)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("01 / 07")
                .systemLabel()
                .foregroundColor(.cosmicCyan.opacity(0.8))

            Text("Your birth chart")
                .font(SynergyFont.headline(30))
                .foregroundColor(.cosmicNeutral)

            Text("Your birth details")
                .font(SynergyFont.body(15))
                .foregroundColor(.cosmicMuted)
        }
    }

    // MARK: - Form

    private var formFields: some View {
        VStack(spacing: Spacing.lg) {
            // Full Name
            CosmicTextField(
                label: "FULL_NAME",
                placeholder: "Jordan Smith",
                text: $vm.fullName,
                icon: "person.fill"
            )
            .focused($focusedField, equals: .name)
            .submitLabel(.next)
            .onSubmit { focusedField = .city }

            // Date of Birth
            CosmicDateField(
                label: "BIRTH_DATE",
                date: $vm.birthDate
            )

            // Birth Time
            CosmicTimeField(
                label: "BIRTH_TIME_UTC",
                time: $vm.birthTime,
                isOptional: true
            )

            // Birth City with autocomplete
            cityField
        }
    }

    private var cityField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            CosmicTextField(
                label: "BIRTH_CITY",
                placeholder: "Manchester, UK",
                text: $vm.birthCity,
                icon: "mappin.circle.fill"
            )
            .focused($focusedField, equals: .city)
            .onChange(of: vm.birthCity) { vm.searchCity($0) }

            // Autocomplete suggestions
            if !vm.birthCitySuggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(vm.birthCitySuggestions, id: \.self) { city in
                        Button {
                            vm.selectCity(city)
                            focusedField = nil
                        } label: {
                            HStack {
                                Image(systemName: "mappin.circle")
                                    .font(.system(size: 13))
                                    .foregroundColor(.cosmicCyan)
                                Text(city)
                                    .font(SynergyFont.body(14))
                                    .foregroundColor(.cosmicNeutral)
                                Spacer()
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)

                        if city != vm.birthCitySuggestions.last {
                            Divider().overlay(Color.cosmicBorder)
                        }
                    }
                }
                .background(Color.cosmicCard)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .strokeBorder(Color.cosmicBorder, lineWidth: 1)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: vm.birthCitySuggestions.count)
    }

    // MARK: - Accuracy Callout

    private var accuracyCallout: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "clock.fill")
                .font(.system(size: 12))
                .foregroundColor(.cosmicCyan)

            VStack(alignment: .leading, spacing: 2) {
                Text("With birth time: 94% match precision")
                    .font(SynergyFont.body(12, weight: .medium))
                    .foregroundColor(.cosmicNeutral)
                Text("Without: 71%")
                    .font(SynergyFont.body(11))
                    .foregroundColor(.cosmicMuted)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.cosmicCyan.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.sm)
                .strokeBorder(Color.cosmicCyan.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - CTA

    private var ctaButton: some View {
        CosmicButton(
            "Reveal my chart →",
            variant: vm.canAdvanceFromBirthChart ? .gradient : .outlined,
            isLoading: vm.isLoading
        ) {
            focusedField = nil
            vm.advance()
        }
        .disabled(!vm.canAdvanceFromBirthChart)
        .opacity(vm.canAdvanceFromBirthChart ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 0.2), value: vm.canAdvanceFromBirthChart)
    }
}
