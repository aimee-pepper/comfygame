import SwiftUI

/// Settings. Currently appearance; it'll grow.
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

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

#Preview {
    NavigationStack {
        SettingsView().environmentObject(AppSettings())
    }
}
