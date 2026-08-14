# DEBUG World Color review — current

**Status:** implementation-ready acceptance tool for the installed world-grade-2 checkpoint  
**Owner:** Game Design owns comparison questions; Engineering owns native rendering/receipt access  
**Scope:** DEBUG only; no campaign mutation, tutorial, player-facing analysis or new art

## Purpose

The current phone gate asks whether meaningful world differences produce proportionate visual
differences while related worlds remain related. Looking at unrelated expeditions cannot isolate
that question: map seed, topology, flora cast and authored statements all change together. Aimee
needs one compact native review surface that shows controlled pairs through the exact shipped
renderer and separately confirms that actual bound worlds retain their frozen receipts.

This surface is an evidence viewer, not a balance editor. It never grants vocabulary, spends
Essence, advances seeds, creates History, reveals campaign fog or changes a saved world.

## DEBUG destination

Add **World Color** as a DEBUG tab/destination beside Roadmap, Balancing and Authored Text.

The landing surface has two tabs:

1. **Controlled pairs** — fixed nonmutating requests rendered natively.
2. **My worlds** — actual grade-2 receipts already present in the active campaign/History.

Remember only the selected review tab and grayscale preference as DEBUG UI state. Do not persist
fixture selection into the campaign save.

## Controlled pairs

Use the frozen `world-grade-2-v1` request/descriptor resolver and native map compositor. Every pair
uses the same 9×9 map fixture, topology, placements, reveal mask, route, resources and species IDs;
only the named visual fact changes. Each card shows A and B side by side at a phone-readable scale,
then a full-size tap detail.

Required set:

| Pair | A → B | Expected judgment |
|---|---|---|
| Material near | same identity/palette; one small legal transform step | visibly related; no novelty-forced split |
| Material threshold | cool mineral → warm mineral with otherwise matched facts | coherent but clearly different material family |
| Hydrology response | dry → wet transform within one eligible earth family | bounded material response; water itself retains identity |
| Granite ownership | open Granite source absent → present | only eligible material palette receives Granite ownership |
| Atmosphere none/smoke | none → moderate Smoke | visible medium appears; geometry and hazards do not change |
| Atmosphere density | faint Smoke → great Smoke | ordered density, same medium family |
| Emitter ownership | open Sun A → deliberately opposed Sun color | light layer changes; inherent terrain recipe does not |
| Flora tendency | same realized cast, open → deliberately opposed Bloom tendency | species palettes shift within shared anatomy/forms |
| Flora realization | generated two-species cast, one placed → both placed | only visible species enters receipt; coverage remains truthful |
| Neutral far | cool/wet mineral-heavy → warm/dry earth-heavy, no explicit color | neutral does not collapse both into beige |
| Similar composite | two close material/flora/atmosphere requests | related overall family is acceptable and desirable |
| Opposed composite | far material + atmosphere + flora facts | strong whole-frame distinction, not one accent tile |

The exact request bytes and resolved descriptor hash appear in expandable DEBUG detail, not on the
comparison face. Fixture definitions are versioned data checked against the pack schema; views do
not reconstruct requests from labels.

## Review controls

- **Color / literal grayscale** toggle rerenders both halves from the same native pixels. Grayscale
  is a literal conversion, not an alternate hand-authored palette.
- **Labels on/off** allows a blind first judgment; turning labels on names only the intended changed
  facts and expected relationship.
- **Swap A/B** proves reading is not an assumed left-to-right improvement.
- **Mark**: Too similar / Proportionate / Too different, plus optional note. Marks live in a DEBUG
  review export/outbox and never tune the renderer automatically.
- **Export evidence** creates one lossless paired image plus a small JSON receipt containing build,
  pack/adapter/renderer versions, fixture IDs, descriptor hashes, grayscale state and judgment.

Do not add palette sliders here. Authoring/tuning inputs belong in AssetLab or the existing
Balancing authority; this surface answers whether a pinned candidate works in the actual app.

## My worlds

List only actual current-campaign worlds:

- grade-2 worlds show frozen thumbnail, world/history identity, adapter/pipeline/renderer versions,
  descriptor hash and whether the receipt validates;
- legacy grade-1 worlds show **Legacy appearance · intentionally not recolored** and no fabricated
  descriptor;
- active, saved History and anchored copies sharing one world identity must show the same receipt
  hash;
- invalid/tampered receipts diagnose in DEBUG and retain the ordinary safe-load policy; this screen
  never repairs or replaces them.

Selecting exactly two grade-2 worlds opens **Compare receipts**. It names material identity/family,
atmosphere medium/density, realized flora species/coverage/richness and emitter presence at the
receipt level. It does not expose unrevealed POIs, creature placements, resources, hidden rolls or
pressure facts absent from the receipt.

## Acceptance

1. Opening, judging, swapping, toggling grayscale and exporting consume no campaign-save mutation,
   seed, Essence, turn or discovery; DEBUG preferences/review evidence remain outside campaign data.
2. All twelve controlled pairs use equal geometry/disclosure hashes; only their intended descriptor
   fields differ.
3. Native pair pixels match direct `MapAssetRenderer` output for the same fixture and descriptor;
   the review view owns no recoloring path.
4. Literal grayscale preserves water/deep water, chasm, route, cracking, elevation and POI/party
   shape distinctions without relying on hue.
5. A newly bound world appears with its exact receipt after save/relaunch; active, History and
   anchored copies agree byte-for-byte.
6. A receipt-less legacy world remains grade 1 and is never silently upgraded by opening the tool.
7. The 368×800 surface compares without horizontal scrolling; full-size detail may scroll
   vertically, and all controls remain at least 44 points.
8. Export is lossless and versioned; failure leaves the review mark locally visible and offers an
   honest retry/share path rather than claiming submission.
