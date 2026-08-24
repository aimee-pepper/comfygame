# Player-visible identity native integration audit v1

**Status:** read-only Asset-to-native audit; no native edits, no art promotion
**Native source baseline:** `d50324844ea74874f1d4c6bd73c919f66e96644b`
**Asset checkpoint:** `4e02b1e90cc5d886416b8175b57961566ebb8796`
**Priority:** Expedition Return first, then shared Storehouse/item/material consumers
**Excluded from substitution:** named travellers, creatures/apex, Binder, Quill, legacy receipts without a stable modern identity

This receipt distinguishes three materially different situations:

- **A — integration seam only:** a final asset exists at the correct truthful profile and the consumer already has enough stable state to select it.
- **B — profile/state mapping unresolved:** final art exists, but only for another approved consumer profile or the current state cannot select it without a new mapping decision.
- **C — final art absent:** no truthful final asset exists. Keep the current honest fallback or fail closed; do not fabricate a substitute.

Functional action, navigation, slot, warning, disclosure and status glyphs are not stable world/item identities and are outside this audit.

## Frozen accepted authorities

| Authority | Exact receipt | Integration fact |
|---|---|---|
| Exploration promotion | `AssetLab/integration/exploration-map-final-art-promotion-v1/promotion-receipt.json`; file SHA-256 `51b9a0780171341e18c75576964bd8e3725e52d13fd2cad1847851ee41a51da2`; promotion commit `0eb9bf4d77735f7d09d6c7172542b55d33c45d7c` | Promotes source commits `d3dce437a3c33dae3316d13de7625d5dc9fe9c8f`, `33aac2dc9254ecbd4d3e256ee4efdd390d56482d`, `bfd49d52bb3814c708161c4fe0256631dfadcb95`; map canvas `16×19`, pivot `(8,18)`; minimap `7×7`; full may use premade frames, remembered is frame 0, hidden requests nothing. |
| Resource Sprites v1 | `AssetLab/integration/resource-sprites-v1/manifest.json`; file SHA-256 `a3e3134b51225f2b4dad61380e2e425780571a099e97e1572f7164589f307c11`; body `f55fe0c1c27d78497661126c63ce9df57a0173b995edc1590165009c9e778323`; commit `199cfee75aa2f8b97634e2c1ec1d6fe083ea3f6d` | 23 stable resources; exact immutable profiles are inventory `32×32`, map `16×16`, field `8×8`. Mote has no map profile. |
| Mob/material + gear v1 | `AssetLab/integration/mob-gear-sprites-v1/manifest.json`; file SHA-256 `1ad0b3729a36a732912ec63b28ae9ea190fdd3e42f512c1ff94fc5ce6aec7b98`; body `ee65afce662d74615ed3c602a7654650ab6e317df1e3d43b612820a6ede40fc9`; commit `42fd5105403167c06f026ff7a82087b3bbbce371` | Final `32×32` sprites for all 16 `MaterialKind` cases, all 24 gear families and all 75 current catalogue gear identities. |
| Catalogue objects map pack | `AssetLab/integration/exploration-catalogue-objects-v1/runtime/manifest.json`; file SHA-256 `71dcb608dae62dc6503f9333f0114ac6b9d75871f39a1c3f222b9645d027e239`; runtime aggregate `9731e732f698580965faf8ecf9bdc0494b21d68746b4b19ec0f432cf4c6ad70a`; promoted source commit `bfd49d52bb3814c708161c4fe0256631dfadcb95` | 27 identified final **map-profile** sprites at `16×19`, pivot `(8,18)`, static; one opaque unknown-curio map identity. This does not silently approve a `32×32` item-grid profile. |
| Exploration identity pack | `AssetLab/integration/exploration-map-identities-v1/runtime/manifest.json`; file SHA-256 `e0d926e86128def14a1bdc488311d9d0e65ab60464d16126bfb44b9514d83b80`; runtime aggregate `32ada00ca207d6eac6d8eee1de4917cfb6da03cc968d218a0b2b3b4ff197e990` | Final map/minimap identities for promoted sites, generic hazards, portals, Pages and writings. |
| Loose Raw Essence v1 | `AssetLab/integration/exploration-loose-essence-v1/promotion-receipt.json`; file SHA-256 `abe9fa779f6cbc14c808be1a2b5c303e8328ae95cb41df5181a5206ef8fcdcf9`; checkpoint `4e02b1e90cc5d886416b8175b57961566ebb8796` | Final four-frame `16×19`, pivot `(8,18)` World loose-drop identity; approved and queued for native consumption behind Traveller. It does not supply spendable-Essence UI art. |

## Return Recap — first integration batch

Native owner: `Sources/App/RootView.swift`, `receiptTile(_:)` at lines 633–653 and writing rows at 580–586 / 712–746 on the pinned baseline.

| Stable identity/state | Current native consumer/fallback | Classification | Exact resolver seam |
|---|---|---:|---|
| Every `ResourceID` receipt line | `ResourceIconTile` → `ResourcePixelIdentity` → Resource Sprites inventory `32×32`; SF only if the exact asset is absent | already integrated | Preserve `resourceID`; no change. Do not infer from fallback name/icon. |
| 75 exact gear catalogue IDs | `ItemIconTile` → `CatalogueItemPixelIdentity` → `CatalogueGearSpriteV1Registry` `32×32` | already integrated | Preserve exact `catalogID` + identified state. |
| 16 exact `MaterialKind` sample lines: `plate`, `quill`, `pelt`, `down`, `hide`, `chitin`, `fang`, `tusk`, `claw`, `bone`, `ichor`, `timber`, `fibre`, `pulp`, `toxin`, `reagent` | Recap currently calls `ItemIconTile(catalogueID: material.catalogID)` and omits `materialKind`, bypassing `MaterialSamplePixelIdentity`; SF/item fallback results | **A** | Pass `material.sample.kind` through the existing `materialKind` input. Keep grade, source and inherited properties as text/state; sprite selection is kind-only. No new resolver or asset required. |
| 17 identified consumables listed below | `CatalogueItemCompositeV1Registry` currently returns `catalogue-consumables-placeholder-v1` `32×32` functional placeholders | **B** | Final identity exists only as approved `catalogue-item/<id>/identified` `16×19` map art. Freeze a final item-grid profile policy/asset before replacing the `32×32` placeholder; do not upscale or reinterpret the map pivot silently. |
| 10 identified treasure/curio/key objects listed below | Composite registry marks them unsupported; `CatalogueItemPixelIdentity` uses their SF Symbol fallback | **B** | Same final `16×19` map assets exist, but no approved `32×32` item-grid profile/adapter row exists. Decide exact native display profile, then add exact-ID rows—never map by name, rarity or kind alone. |
| Collected World Page | `Image/Label(systemName: "doc.text")` | **B** | Final `loose_world_page/ordinary/frame-0` exists at `16×19`, pivot `(8,18)`, SHA `63ade8207da25c590ca41232e5b8c94e5a5a42ccb799f3fabf1b308d360aa668`; using it outside the map needs an explicit native display-profile decision. |
| Diary Page | `Image(systemName: "doc.text.fill")` | **B** | Final `diary_page/ordinary/frame-0`, SHA `486c2a3b517729375ee9886eebd3d293ae8b8dba56e45421cc473a04a73d69ca`; pin item-row sizing/profile before reuse. |
| Found writing | `Image(systemName: "doc.text.fill")` | **B** | Final `found_writing/ordinary/frame-0`, SHA `5869e2189151813d957050b6a469c4c2e2bd22801191f7641d443e95416c8830`; pin item-row sizing/profile before reuse. |
| Legacy receipt line | `LegacyReceiptIconTile` + archived SF icon | **C** | There is no trustworthy modern stable ID. Preserve the explicit legacy fallback and legacy copy; never substitute a same-name current identity. |

### Exact 17 final-map / placeholder-UI object IDs

`salve_lesser`, `salve`, `salve_greater`, `draught_clearing`, `draught_quenching`, `antidote_broad`, `stonebark_tonic`, `venom`, `firebrand`, `briar_oil`, `flashsalt`, `solvent`, `lure`, `stillwater`, `waystone`, `torch`, `farsight_draught`.

### Exact 10 final-map / SF-UI object IDs

`essence_crystal`, `heat_core`, `caustic_core`, `light_core`, `conduit_fixture`, `curio_humming_shard`, `curio_bound_knot`, `cache_key`, `anchor_frame`, `scent_mask`.

### Return Recap batch recommendation

1. **R1 — material samples:** one call-site correction using the already-installed `MaterialSamplePixelIdentity`; closes 16 exact identities with no new art or profile choice.
2. **R2 — catalogue object item profile:** one shared `CatalogueItemPixelIdentity` registry extension, but only after Asset/Aimee pins whether the final map sprites may be mounted at native size inside item tiles or whether final `32×32` profiles must be authored. It closes the same 27 IDs in Return, Storehouse, Loot Decision, Field Kit, Trading Post, Apothecary and World pickup detail at once.
3. **R3 — writing rows:** one shared Page/writing row identity profile after the same non-map sizing decision. Do not block R1 on it.
4. Keep legacy receipts unchanged.

## Shared-consumer census

| Consumer family | Current result | Classification / handoff |
|---|---|---|
| Storehouse Items / Field Kit / Waiting and anchored details (`StationViews.swift`) | Shared `ItemIconTile`; gear final, 17 consumables placeholder, 10 objects SF fallback | Gear integrated; object family **B**, solved once by R2. |
| Storehouse Resources and material reserve | `ResourceIconTile` and `ItemIconTile(materialKind:)` | already integrated. |
| Gear/Body/Party (`GearView.swift`, `PartyRosterView.swift`) | Exact gear through `CatalogueItemPixelIdentity`; empty-slot glyph is functional state | already integrated; no Asset identity gap. |
| Loot Decision / Encounter loot | Shared `ItemIconTile` for carried/offered exact stacks | Gear integrated; object family **B**, solved by R2. |
| World pickup/supply detail | World map uses promoted final packs; detail/tray uses shared item adapter | Map is integrated. Object detail is **B**, solved by R2. |
| Trading Post / Recycler | Shared resource/material/item tiles | Resource/material/gear integrated; object family **B**, solved by R2. |
| Apothecary recipe/output rows | `CatalogueItemPixelIdentity` | Current 17 consumables are functional placeholders; **B**, solved by R2 only after final profile approval. |
| Blacksmith/Armoury material sockets and detail rows | Several paths use `MaterialSamplePixelIdentity`; direct SF paths remain at `BlacksmithView.swift` lines 553, 808, 904, 982 and 1151 | **A**. Replace those identity-bearing SF images/labels with the same exact `MaterialSamplePixelIdentity(kind:)` at native 20–24 pt presentation; keep property/action icons unchanged. |
| Workshop Ore/Fiber currency chips | `CurrencyChip` accepts SF only (`cube`, `scribble`) | **A**. Exact Resource Sprite exists; add a resource-identity chip seam and choose an existing immutable profile (`field 8×8` or `map 16×16`) without recolor. |
| Mote chips | SF `star.fill`; Resource Sprite has inventory/field but no map profile | **A** for non-map UI once a chip profile is pinned. Never request a map identity. |
| Spendable Essence chips | SF drop; spendable Essence is not `essence_raw` | **C**. Do not substitute Raw Essence, Essence Crystal or Mote. |
| Exploration map/minimap | Promoted final packs and Resource Sprite map profile installed | already integrated for promoted families. Named travellers, creatures/apex, Binder and Quill remain deliberately blocked. |
| Debug/simple map renderer | Symbols remain in a debug-only fallback renderer | outside player-production integration; do not use as proof of a production leak. |

## Smallest shared batches by impact

1. **Return R1: MaterialKind pass-through** — 16 identities, one existing resolver, no art/profile change.
2. **Shared catalogue object profile R2** — 27 identities across Return, Storehouse, Field Kit, Loot Decision, Encounter, Trading Post, Recycler, Apothecary and World detail. This is the highest visual payoff but remains **B** until the final item-grid profile is expressly pinned.
3. **Blacksmith material inline identity** — closes five direct identity-bearing SF seams by reusing the installed 16-kind registry.
4. **Shared resource/currency chip identity** — closes Ore/Fiber/Mote identity glyphs in multiple stations; spendable Essence remains a separate **C** gap.
5. **Page/writing row profile** — closes Return recap document symbols after exact non-map sizing is approved.

## Native presentation rules

- Never recolor accepted item/resource/material pixels by rarity, theme, grade or WorldGrade. Surrounding borders and text may convey state.
- `32×32` inventory/material/gear profiles remain nearest-neighbor and centered in the existing 44-point minimum tile.
- Exploration sprites retain their exact `16×19` canvas and `(8,18)` bottom pivot on map. Category-only minimap sprites remain native `7×7` centered; no subtype disclosure.
- Full map visibility may select only premade authorized frames on the shared display clock; remembered is exact frame 0; hidden performs no identity lookup and draws nothing.
- Unknown identity is a disclosure state, not permission to reveal an identified sprite. Missing exact IDs fail closed to the existing honest fallback.
- No adapter may select by player-facing name, fallback symbol, rarity, slot, sort position or catalogue order.

## Explicit unresolved gaps

- Final non-map profiles for the 27 promoted catalogue objects are not frozen.
- Final Loose Raw Essence is approved at checkpoint `4e02b1e9` and has its own exact native handoff. It remains
  queued behind Traveller and does not close any Return Recap identity because spendable Essence is a distinct
  identity.
- Spendable Essence has no final UI identity and must not borrow Raw Essence.
- Legacy receipts and blocked named/creature families lack truthful stable final art.
