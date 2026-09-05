# Cold-water appendage coherence — bounded weather/body contract

**5 September 2026 · Decided intended Design correction, unimplemented and not assigned.** This advances the weather/body part of ecological coherence. It changes only where an existing cold-water appendage-count tendency applies in future opted-in ordinary creatures. The fresh-start campaign, phone-delivery candidate and Bestiary sorting work receive no runtime change from this document.

## Authority and observed mismatch

The existing creature specification associates additional appendages with **Hydrology plus cold**. Current Engineering source `594cb61c23c198337b2c42ad4ccebc10023a1817` (tree `1c8501453bd2c360a3dced3f047e18dad95c8a55`) in `Sources/Rules/LifeRules.swift`, `WorldTendencies.init`, instead adds `1.2 * cold` inside the thermal branch for every creature. The comment says “cold water grows extra limbs,” but the branch has no water/habitat condition. This is source evidence, not a new mounted result.

This resolves that mismatch using the already-decided physical habitat contract. It does not establish a real-world biological law or prescribe an Earth species. Several appendages remain a tendency and variation within the game's existing grammar.

Dependencies: [body/habitat compatibility](generated-creature-body-habitat-v1.md), including certified liquid components and stable ordinary species; existing fixed individual budget, source-material rules and legacy preservation. Companion authored data: `creature-cold-water-appendages-v1.json`.

## Retained climate rules

Keep current resolved world pressures, sampling order and numerical weights. In particular, cold begins below thermal floor 30, heat above peak 70, and the existing wet-versus-dry covering branch uses available Hydrology above 45. Those are current tuning values, not new climate guarantees.

Cold continues to favour larger bodies and more covering; the wetter cold branch favours bulk with less extra covering length than the drier branch. Heat continues to favour smaller bodies, reduced covering coverage, farther reach and paler coloration. These are allocation tendencies under the same fixed budget, not minimum survival requirements, damage immunity, guaranteed Fur/Fat/Down drops, or a local skin-wetness simulation. Both existing thermal branches can apply to a world with cold lows and hot highs; preserve their order.

Do not use older productivity-sized budget helpers to replace the current fixed `WorldTendencies.budget`. Vitality continues to affect population/cast size, not free individual power.

## Exact correction

Introduce a distinct optional future policy, suggested `creatureColdWaterAppendageVersion = 1`, requiring `creatureBodyHabitatVersion = 1`. Missing policy preserves the original count, including body/habitat-only worlds. Do not activate the policy in the current early-game playtest.

Compute the existing cold amount from the finite resolved thermal floor:

```text
cold = floor < 30 ? min(1, (30 - floor) / 30) : 0
coldCountBias = 1.2 * cold
```

Retain this bias only when the species has **Shore or Aquatic habitat validated against a component containing certified liquid water**. The body/habitat contract already defines that certification; rendered blue tiles, snow/ice, high water pressure, rainfall, and root moisture are not substitutes. A shore animal may be on its bank: its frozen water-and-land mode establishes the connection, not the tile occupied this turn.

Terrestrial and Aerial species do not receive this particular bias, even beside water or while flying over it. They retain the ordinary appendage variation, darkness contribution and all other climate effects. This does not prohibit many-legged land creatures or multi-winged fliers.

Current physical-root rules exclude frozen liquid below thermal floor 25. Therefore the ordinary liquid-water examples use floor 25: the retained cold-water bias is 0.2 there, falling to zero at 30. The full 1.2 arithmetic example applies to correcting severe dry cold, not to inventing unfrozen water at floor 0. Preserve the existing freeze boundary; do not thaw a source or stretch the cold ramp to make the effect larger.

An invalid Shore/Aquatic component is an existing body/habitat validation failure, not permission to downgrade its species to Land or silently apply a dry fallback.

## Preserve sampling, then round once

The correction happens after a supported habitat is selected but before final body/count validation and source projection. It overrides only the “preserve original sampled count” portion of body/habitat step 5 for this additional opt-in.

The legacy gameplay draw must consume exactly the same random values, in the same order. During that draw, retain the already-used count jitter and its original appendage-type branch as transient generation facts; do not draw a second jitter. Original type `none` consumes no count-jitter draw. Capturing a value is not another RNG call.

For an original non-none appendage sample:

```text
neutralCountTendency = original unrounded count tendency with only coldCountBias omitted
newCountTrial = neutralCountTendency
              + (validatedShoreOrAquatic ? coldCountBias : 0)
              + originalCountJitter
sampledCount = clamp(Swift default rounded(newCountTrial), 0, 8)
```

Use the original point in the free-axis pipeline, including its existing range clamp, when forming the tendency. With current constants, neutral tendency is 4 plus the existing 1.6 darkness contribution when present. The cold bias is at most 1.2 and the jitter is the existing −1.4...1.4. Do not subtract a rounded bias from an already-rounded integer: a trial of 5.6 becomes 6, but removing 1.2 before rounding gives 4; subtracting rounded(1.2) afterward would incorrectly give 5.

For an original none sample, preserve the existing sampled zero and consume no jitter. The later body/habitat adjustment may still need a positive count when it changes the type; use its existing minima, not a new random count.

Then apply the final supported type and body/habitat clamps: none → 0; other types → 1...8; aerial wings and shore-piscine supporting limbs → 2...8. Main quadruped/biped legs are still intrinsic body shape, not an accessory-count inventory.

Freeze the resulting count with final species traits before material projection, names and specimen creation. Do not recalculate from current weather, time, position, illumination or specimen jitter. A species does not grow or lose appendages during a trip.

## Ownership and compatibility

- No new RNG stream, seed selection, habitat roll, species ID, costly-axis allocation, count quota, spawn weight, combat stat or movement permission.
- Keep the original habitat and morphology streams byte-for-byte. Only the permitted final accessory count can differ for newly opted-in species; body plan/type selection, colour, head, senses, defence and emanation remain unchanged.
- Freeze material capability from the final body using its existing owner. Do not copy a projection of the earlier count. Existing family-specific rules still decide whether anything is produced.
- Narrow Hide and plain Bone do not gain extra drops or altered quantity/quality from this policy. Proposed Fin/Feather material quantities remain their separate unfinished consumer work; an appendage count is not permission to launch them.
- Species names and actual-source receipts retain their established owners. Weather language does not prove Fur, Fat, Oil, insulation efficacy or a new crafting ingredient.
- Legacy worlds, anchored casts, inventory, reward receipts, actual Apex, sessile flora and authored special creatures retain their existing paths.
- Missing or inconsistent new-policy generation facts fail before publishing the new cast. Never reconstruct the lost jitter from a rounded count, reroll it, or rewrite an older world.

## Bounded eventual acceptance

The companion examples specify cold aquatic versus cold terrestrial/aerial results with identical original draws, warm water with no cold bonus, unchanged darkness contribution, original-none sampling, final-none zero, and shore-piscine/aerial minima. Include one explicit invalid ice-only liquid-component refusal.

Focused tests should compare exact RNG state and all unchanged gameplay fields/IDs across the same input, then assert the few permitted count differences and legacy isolation. No broad seed census is needed. A single isolated mounted comparison can inspect the final bodies through existing Field/Look at the actual target iPhone/default text/current appearance and reopen once; do not require another Bestiary renderer, final art, natural expedition or phone installation for this Design checkpoint. Implementation and native validation remain unassigned.

## What this closes, and what remains open

**Closed Design correction:** cold-water appendage bias belongs to validated water-associated species; other climate allocation effects and ordinary morphological variety are preserved.

**Still open:** diet and actual food relationships, nesting, meaningful dynamic weather responses, the full body/material catalogue and the complete player experience. Weather immunity, coat wetting, shelter seeking, migration, freezing/thawing bodies and seasonal anatomy are **unsettled ideas, not selected features**. No new Aimee decision is needed to implement this bounded correction; a new simulation proposal would need its own concrete decision.

Aimee Homework gets partial weather/body progress. All three broader creature goals remain unchecked.
