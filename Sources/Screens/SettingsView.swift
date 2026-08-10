import SwiftUI

/// Settings. Currently appearance; it'll grow.
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Appearance", icon: "circle.lefthalf.filled") {
                    ForEach(AppTheme.allCases) { theme in
                        Button {
                            settings.theme = theme
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: theme.icon)
                                    .frame(width: 24)
                                    .foregroundStyle(.tint)
                                Text(theme.displayName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if settings.theme == theme {
                                    Image(systemName: "checkmark").foregroundStyle(.tint)
                                }
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                NavigationLink {
                    FieldNotesView().environmentObject(store)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "text.book.closed").frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Field Notes")
                            Text("How writing and expeditions work")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                    }
                    .frame(minHeight: 44)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.field-notes")

#if DEBUG
                NavigationLink {
                    BalancingView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Balancing")
                            Text(settings.debugTuning.isDefault ? "Defaults" : "Custom tuning active")
                                .font(.caption)
                                .foregroundStyle(settings.debugTuning.isDefault ? Color.secondary : Color.orange)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(minHeight: 44)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.balancing")
#endif

                Label {
                    Text("System follows your phone, including its sunset schedule. Dark overrides it — for when the phone is bright and you are not.")
                } icon: {
                    Image(systemName: "moon.zzz")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                ComingLater("Text size, haptics and a colour-blind-safe palette belong here too — milestone 6 is the ergonomics pass.")
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
private struct BalancingView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            if !settings.debugTuning.isDefault {
                Section {
                    Label("Custom tuning applies to the next world you bind.", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                }
            }

            Section("Resources") {
                tuningSlider("Raw essence frequency", value: $settings.debugTuning.rawEssenceFrequencyMultiplier)
                tuningSlider("Raw essence yield", value: $settings.debugTuning.rawEssenceYieldMultiplier)
                tuningSlider("World-resource node density", value: $settings.debugTuning.resourceNodeDensityMultiplier)
                resetSection("Resources") {
                    settings.debugTuning.rawEssenceFrequencyMultiplier = 1
                    settings.debugTuning.rawEssenceYieldMultiplier = 1
                    settings.debugTuning.resourceNodeDensityMultiplier = 1
                }
            }

            Section("Writing") {
                percentageSlider("Chance of a second page",
                                 value: $settings.debugTuning.additionalPageChance,
                                 range: 0...0.5,
                                 defaultValue: Tuning.Library.additionalPageChance)
                percentageSlider("Diary share",
                                 value: $settings.debugTuning.diaryWritingShare,
                                 range: 0...1,
                                 defaultValue: Tuning.Library.diaryWritingShare)
                integerStepper("Diary patience floor",
                               value: $settings.debugTuning.diaryPatienceWorlds,
                               range: 0...20,
                               suffix: " worlds",
                               defaultValue: Tuning.Library.patienceInWorlds)
                Text("Every world still guarantees one writing. This only controls the chance of another.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                resetSection("Writing") {
                    settings.debugTuning.additionalPageChance = Tuning.Library.additionalPageChance
                    settings.debugTuning.diaryWritingShare = Tuning.Library.diaryWritingShare
                    settings.debugTuning.diaryPatienceWorlds = Tuning.Library.patienceInWorlds
                }
            }

            Section("Creatures") {
                tuningSlider("Creature density", value: $settings.debugTuning.creatureDensityMultiplier)
                tuningSlider("Apex chance", value: $settings.debugTuning.apexChanceMultiplier,
                             range: 0...3)
                resetSection("Creatures") {
                    settings.debugTuning.creatureDensityMultiplier = 1
                    settings.debugTuning.apexChanceMultiplier = 1
                }
            }

            Section {
                tuningSlider("Stability duration", value: $settings.debugTuning.stabilityDurationMultiplier,
                             range: 0.5...2)
                percentageSlider("Collapse recovery",
                                 value: $settings.debugTuning.collapseRecoveryFraction,
                                 range: 0...1,
                                 defaultValue: Tuning.World.collapseHaulKeptFraction)
                resetSection("World duration") {
                    settings.debugTuning.stabilityDurationMultiplier = 1
                    settings.debugTuning.collapseRecoveryFraction = Tuning.World.collapseHaulKeptFraction
                }
            } header: {
                Text("World duration")
            } footer: {
                Text("Scope: next world. Existing expeditions keep the values they began with.")
            }

            Section("Navigation") {
                integerStepper("Base vision radius",
                               value: $settings.debugTuning.baseVisionRadius,
                               range: 1...6,
                               suffix: " tiles",
                               defaultValue: Tuning.World.baseVisionRadius)
                integerStepper("Slow-ground extra turns",
                               value: $settings.debugTuning.slowGroundExtraTurns,
                               range: 0...3, suffix: " turns", defaultValue: 1)
                resetSection("Navigation") {
                    settings.debugTuning.baseVisionRadius = Tuning.World.baseVisionRadius
                    settings.debugTuning.slowGroundExtraTurns = 1
                }
            }

            Section("Flora") {
                tuningSlider("Active-flora frequency",
                             value: $settings.debugTuning.activeFloraFrequencyMultiplier,
                             range: 0...3)
                tuningSlider("Thorn / toxin severity",
                             value: $settings.debugTuning.floraHazardSeverityMultiplier,
                             range: 0.5...2)
                resetSection("Flora") {
                    settings.debugTuning.activeFloraFrequencyMultiplier = 1
                    settings.debugTuning.floraHazardSeverityMultiplier = 1
                }
            }

            Section {
                Button("Reset All", role: .destructive) {
                    settings.debugTuning = .defaults
                }
                .disabled(settings.debugTuning.isDefault)
            } footer: {
                Text("This profile is stored separately from your game save. Existing worlds never change.")
            }
        }
        .navigationTitle("Balancing")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tuningSlider(_ title: String, value: Binding<Double>,
                              range: ClosedRange<Double> = 0.25...3,
                              defaultValue: Double = 1) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue.formatted(.number.precision(.fractionLength(2)))
                     + "× · default \(defaultValue.formatted(.number.precision(.fractionLength(2))))×")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 0.25)
                .accessibilityLabel(title)
        }
        .padding(.vertical, 4)
    }

    private func percentageSlider(_ title: String, value: Binding<Double>,
                                  range: ClosedRange<Double>, defaultValue: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue.formatted(.percent.precision(.fractionLength(0)))
                     + " · default \(defaultValue.formatted(.percent.precision(.fractionLength(0))))")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 0.05)
                .accessibilityLabel(title)
        }
        .padding(.vertical, 4)
    }

    private func integerStepper(_ title: String, value: Binding<Int>,
                                range: ClosedRange<Int>, suffix: String,
                                defaultValue: Int) -> some View {
        Stepper(value: value, in: range) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text("\(value.wrappedValue)\(suffix) · default \(defaultValue)\(suffix)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func resetSection(_ name: String, action: @escaping () -> Void) -> some View {
        Button("Reset \(name)", action: action)
            .font(.caption)
    }
}
#endif

#Preview {
    NavigationStack {
        SettingsView().environmentObject(AppSettings())
    }
}
