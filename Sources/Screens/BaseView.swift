import SwiftUI

/// The hub. Routes to station subscreens and out into a world.
///
/// The station list is **rendered from `ContentCatalog.stations`**, not hardcoded — v1+ adds a
/// blacksmith, a tavern, a distillery, and each of those should be a JSON entry plus a screen,
/// never a new button welded into this file.
struct BaseView: View {
    @EnvironmentObject private var store: GameStore

    private var state: GameState { store.state }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                purse
                stations
                departure
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Base")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
            ToolbarItem(placement: .topBarTrailing) {
                // Development-only entry to the milestone-1 persistence harness.
                NavigationLink(value: AppRoute.harness) {
                    Image(systemName: "wrench.and.screwdriver")
                }
                .accessibilityLabel("Persistence harness")
            }
        }
    }

    // MARK: Purse

    private var purse: some View {
        HStack(spacing: 12) {
            CurrencyChip(icon: "drop.fill", label: "Essence", value: "\(state.base.essence)", tint: .teal)
            CurrencyChip(icon: "star.fill", label: "Motes", value: "\(state.reality.motes)", tint: .purple)
        }
    }

    // MARK: Stations

    private var stations: some View {
        VStack(spacing: 10) {
            ForEach(unlockedStations) { station in
                NavigationLink(value: AppRoute(rawValue: station.route) ?? .base) {
                    StationRow(station: station, tier: state.base.station(station.id).tier)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var unlockedStations: [StationDef] {
        ContentCatalog.shared.stationsInOrder.filter { state.base.station($0.id).isUnlocked }
    }

    // MARK: Departure

    private var departure: some View {
        VStack(spacing: 8) {
            NavigationLink(value: AppRoute.writingDesk) {
                Label("Bind & Depart", systemImage: "arrow.up.forward.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56) // primary action, thumb zone, well over 44pt
            }
            .buttonStyle(.borderedProminent)

            Text(departureHint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
    }

    private var departureHint: String {
        let projection = store.bookProjection
        let filled = projection.slotPlans.count { !$0.isRandom }
        if filled == 0 {
            return "No symbols placed — the book will be written entirely by chance."
        }
        if projection.isFullySpecified {
            return "A book of \(filled) symbols is waiting at the desk."
        }
        return "\(filled) of \(projection.slotPlans.count) slots chosen; the rest are left to chance."
    }
}

// MARK: - Pieces

private struct StationRow: View {
    let station: StationDef
    let tier: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: station.icon)
                .font(.title2)
                .frame(width: 34)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(station.name).font(.headline)
                    if tier > 0 {
                        Text("tier \(tier)")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemFill), in: Capsule())
                    }
                }
                Text(station.blurb)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(minHeight: 60)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct CurrencyChip: View {
    let icon: String
    let label: String
    let value: String
    var tint: Color = .accentColor

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.headline.monospacedDigit())
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        BaseView().environmentObject(GameStore(io: .temporary(name: "preview-base")))
    }
}
