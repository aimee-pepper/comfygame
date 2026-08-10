import Foundation

/// The last of the stand-ins.
///
/// Milestone 2 made binding real, milestone 3 the world, milestone 4 combat. All that's left is a
/// debug way to grant a mote, until milestone 5 gives motes real sources (locked caches, Mythic
/// drops, first clears). Then this file goes.
extension GameStore {
    /// Step the analysis axis, so the later description panels can be seen before instruments —
    /// the thing that actually raises it — exist. Wraps back to tier 1.
    func harnessCycleAnalysisTier() {
        mutate("harness: analysis tier", flush: true) { state in
            let next = state.reality.analysisTier + 1
            state.reality.analysisTier = next > Tuning.Analysis.livingTier ? Tuning.Analysis.startingTier : next
        }
    }

    /// Drop one of every wearable thing into the Storehouse, so the equipping UI can be seen
    /// without first walking to a ruin.
    func harnessGrantGear() {
        mutate("harness: gear", flush: true) { state in
            for item in ContentCatalog.shared.items where item.gear != nil {
                guard !state.base.inventory.stacks.contains(where: { $0.catalogID == item.id }) else { continue }
                state.base.inventory.slots = max(state.base.inventory.slots,
                                                 state.base.inventory.stacks.count + 1)
                state.base.inventory.add(ItemStack(id: InstanceID(rawValue: UInt64(abs(item.id.rawValue.hashValue))),
                                                   catalogID: item.id))
            }
        }
    }

    func harnessGainMote() {
        mutate("found a mote", flush: true) { $0.reality.motes += 1 }
    }

    /// A reproducible visual state for the Survey Post's crafting rows. Debug-only stock, kept out
    /// of production progression so interactive checks do not require finding Mara and butchering
    /// several unusually lustrous creatures first.
    func harnessPrepareInstrumentCrafting() {
        mutate("harness: instrument crafting", flush: true) { state in
            state.base.stations[Stations.surveyPost] = StationState(isUnlocked: true, tier: 1)
            state.base.essence = max(state.base.essence, 100)
            let target: PressureTargetID = "illumination"
            state.reality.instruments.insert(target)
            state.reality.instrumentPrecisions[target] = .crude
            state.base.instrumentLoadout.insert(target)
            let samples = (0..<5).map { index in
                MaterialSample(kind: .chitin,
                               properties: MaterialProperties(lustre: 45 + Double(index) * 10),
                               grade: 45 + Double(index) * 10,
                               source: "harness specimen")
            }
            state.base.inventory.slots = max(state.base.inventory.slots,
                                             state.base.inventory.stacks.count + 1)
            _ = state.base.inventory.add(ItemStack(
                id: InstanceID(rawValue: state.base.nextItemID()),
                catalogID: Items.material,
                materials: samples))
        }
    }

    func harnessPrepareApothecary() {
        mutate("harness: apothecary", flush: true) { state in
            state.base.stations[Stations.apothecary] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = max(state.base.essence, 500)
            state.reality.motes = max(state.reality.motes, 3)
            for resource in ContentCatalog.shared.resources where resource.id != Resources.mote {
                state.base.resources.add(10, of: resource.id)
            }
            let samples = MaterialProperty.allCases.flatMap { property in
                (0..<3).map { index -> MaterialSample in
                    var properties = MaterialProperties()
                    properties[property] = 80 + Double(index)
                    return MaterialSample(kind: .reagent, properties: properties,
                                          grade: 80 + Double(index), source: "harness specimen")
                }
            }
            state.base.inventory.slots = max(state.base.inventory.slots,
                                             state.base.inventory.stacks.count + 1)
            _ = state.base.inventory.add(ItemStack(id: InstanceID(rawValue: state.base.nextItemID()),
                                                   catalogID: Items.material, materials: samples))
            state.base.knownConsumableRecipes = Set(ConsumableCraftingRules.recipes.map(\.output))
        }
    }
}
