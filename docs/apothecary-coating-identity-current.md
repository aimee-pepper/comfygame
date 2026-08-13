# Apothecary coating identity

**Status:** settled first-slice names, effects and recipes; native correctness patch queued

**Updated:** 11 Aug 2026

**Authority:** DRQ-002; `combat-affliction-authority-current.md`;
`consumable-economy-field-kit-current.md`

## The four preparations

| Stable item ID | Name | One-hit affliction | Exact first-slice recipe |
|---|---|---|---|
| `venom` | **Venom** | Poison | Toxin 1, Fiber 1, one reactive world resource 55+ |
| `firebrand` | **Firebrand** | Burn | Reagent 1, Sulfur 1, one reactive world resource 60+ |
| `briar_oil` | **Briar Oil** | Bleed | Fiber 1, Resin 1, one flexible world resource 50+ |
| `flashsalt` | **Flashsalt** | Dazzle | Reagent 1, Mercury 1, one lustrous world resource 55+ |

All four ordinary coatings cost **0 refined Essence**. Their named and property-qualified world
resources are the price. Each is applied to one eligible physical weapon and consumed by its next
successful strike; a miss does not spend the prepared coating. Channelworks weapons remain
ineligible because their persistent core is a different weapon system.

The names are no longer placeholders. They communicate the effect without promising a cut status:

- Venom is toxin held in a reactive fibrous carrier;
- Firebrand is a reactive sulfur preparation that continues burning after impact;
- Briar Oil suspends fine hooked fibres in resin so the landed blow leaves an open wound; and
- Flashsalt uses lustrous mercurial grains that flare when struck.

Player-facing recipe text says **world resource**, never “material sample.” Exact provenance and
properties remain inspectable details on the selected resource instance.

## Vocabulary boundary

The affliction set remains exactly Burn, Poison, Dazzle and Bleed. There is no Freeze or Shock.
Rimeoil and Stormsalt are retired display names because they promise those absent mechanics;
decode-only aliases may remain if any historical save used them.

Briar Oil does not infer Bleed from Poison, and Flashsalt does not infer Dazzle from Light. The item
definitions explicitly reference their stable affliction IDs. The typed affliction registry owns
duration, damage, cure and presentation; a coating does not copy those numbers.

## Live correctness findings

The current Venom recipe requests resource ID `fibre`, while the catalogue's stable ID is `fiber`.
Generated Fibre therefore cannot satisfy the recipe. This is an implementation bug, not a reason to
rename the catalogue or add a duplicate resource.

The current Briar Oil recipe spends Toxin + Resin, which blurs it into Venom and does not support the
name. Replace Toxin with catalogue `fiber`; keep Resin and the flexible-resource requirement.

Current native coating recipes also still charge 9/11/11/13 refined Essence. That conflicts with
the settled sustainable-consumable profile: ordinary coatings cost zero Essence so preparation does
not compete with writing another world. Correct this with the broader Apothecary reachability/cost
checkpoint rather than special-casing only these four in presentation.

## Required fixtures

1. Every recipe resource ID resolves to exactly one live catalogue resource; `fibre` resolves
   nowhere in current content and may not remain in a recipe.
2. Each coating crafts from the exact table above with zero Essence and consumes the exact chosen
   property-bearing resource instance once.
3. Missing ingredients, full storage/spillover, stale selection and cancel are atomic.
4. Each coating prepares only an eligible physical weapon and persists through relaunch until a
   successful strike or encounter end according to the shared coating boundary.
5. The successful strike applies exactly Poison/Burn/Bleed/Dazzle and consumes one coating.
6. Typed cures, Stonebark and Broad Antidote use the shared affliction registry; no coating creates
   Freeze or Shock.
7. Release copy contains no placeholder prose, Rimeoil, Stormsalt, `fibre` resource ID, Freeze or
   Shock promise.
8. Six-across Apothecary and Field Kit tiles use the shared item identity and anchored details,
   without full-width recipe rows.
