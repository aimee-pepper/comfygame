# Design → implementation conformance audit — current

**Snapshot:** 13 Aug 2026, source HEAD `0eac8a0` plus the explicitly listed uncommitted UI
boundaries.  
**Purpose:** answer one question honestly: *does the game currently implement settled design?*  
**Scheduling authority:** `Sources/Content/Data/playability-roadmap.json`; this document diagnoses
coverage and must not become a second queue.

## Status vocabulary

These terms are deliberately not interchangeable:

- **Accepted:** implemented, verified in source, and passed the required physical-phone/playtest gate.
- **Source-complete:** model/rules/persistence/UI and focused tests satisfy the current contract;
  phone or campaign acceptance remains.
- **Partial:** a useful playable slice exists, but a current promised consumer or progression step is
  absent.
- **Designed only:** an implementation-ready authority exists but no live end-to-end system does.
- **Held:** deliberately awaits a player decision, evidence, or a prerequisite; not an Engineering
  omission.
- **Historical/stale:** prose or data describes an older implementation and must not be read as live
  truth.

`readyToTest` in the live roadmap means **source-complete, not accepted**. `complete` is reserved for
a closed source checkpoint whose remaining observations are ordinary regression reports rather than
an explicit acceptance gate.

## Executive finding

Bookbinder has a broad playable core, but it is **not fully implemented as designed**. The largest
conformance gaps are concentrated rather than random:

1. the 72-node combat graph is only partly promoted into real consumers;
2. Penmanship still exposes the obsolete Pencil lineage and lacks Brush/Ink Mixing progression;
3. several later stations/systems are designed but not live (Deep Works, Tavern/random companions,
   Menagerie/taming, bounded predation, compound assembly, Lys catalogue depth);
4. Channelworks has a real first fixture and construction action but still conflates Oda's one-time
   restoration with repeatable conduit construction;
5. six compound `enemyTierDelta` values remain a hidden difficulty fossil;
6. most final item art and Binder/Quill/generated-person identity still resolve through functional
   placeholders or SF Symbols;
7. 21 traveller meetings and the reviewed Isolde/Sabine replacements remain review corpus rather
   than live copy; and
8. many source-green systems still need Aimee's physical-phone or multi-run balance acceptance.

The audit also found the inverse error: Trading Post shelf breadth, Apothecary reachability, typed
return receipts, outcome-wide failure retention and canonical afflictions were still labelled
**queued** after their implementation commits landed. The live roadmap is corrected with this audit.

## Whole-game conformance ledger

| Feature family | Current state | Evidence | Remaining conformance gate |
|---|---|---|---|
| Save persistence | Source-complete | Three-layer Codable state, atomic file IO, tolerance and persistence tests | One physical-device force-quit/resume pass |
| Campaign save slots | Source-complete | `SaveSlotTests`, `CampaignStartPresentationTests`; post-load Continue/New/Load/Delete route | Phone migration, corruption and delete acceptance |
| Static launch + in-app loading | Source-complete | `98a5252`; one fixed geometry and truthful measured fill | Cold-launch and selected-save physical-phone recording |
| Core page writing | Source-complete | 6×6 spatial page, footprints, clusters, links, move/remove, bind and order-invariance tests | Ongoing phone feel; final rune art is separately Aimee-owned |
| Penmanship tools and ink | **Partial / contradictory** | Live `research.json` and diary rewards still use `pen_pencil`; current design requires `pen_brush`, Brush-gated Ink Mixing and Fountain Pen | Implement `writing-tool-progression-current.md` and lossless migration |
| Pressure model | Source-complete | Eight targets, source resolution, constraints, opposed magnitude and energy-budget suites | Remove only proven fossils; do not retune without evidence |
| World generation | Source-complete | Seeded terrain/water/chasm/site/resource/flora/creature/reachability tests | Physical/campaign diversity acceptance remains ongoing |
| Compound hostility | **Contradictory** | `BookRules.enemyTier` still sums six authored `enemyTierDelta` values | Run same-seed comparison and migrate the complete fossil coherently |
| World color + terrain/flora renderer | Source-complete | Frozen world-grade-2 receipt, native pack/hash/conformance tests | Physical-phone relative-diversity and grayscale acceptance |
| Exploration controls/contact | Source-complete | Look, fixed controls, fog-gated minimap, safe apex/flora adjacency and direct-entry contact tests | Phone geometry and encounter-contact feel |
| Found writing/pages | Source-complete core | One reachable writing guarantee, single patience nominee, immediate knowledge banking | Broader non-diary corpus and campaign distribution telemetry |
| Library | Source-complete | Stable recovered-page set; author and subject indexes; old IDs remain visible | Phone cross-author/count/readability pass |
| Traveller selection/pacing | Source-complete | One full match/world, story bands, causal-writing confidence, near-miss protection and clue bucket weighting | Fresh-save and campaign distribution acceptance |
| Traveller meetings/voice | **Partial** | Ordered independent replies are live; only 8 live meeting objects for 29 travellers; remaining drafts/revisions live only in DEBUG review corpus | Aimee reviews stable units before any prose promotion |
| Combat encounter core | Source-complete | Five-person party, ranks, exact action ownership, persisted openings, targeting, gambits and typed damage paths | Continued physical combat feel testing |
| Encounter/apex scaling | Source-complete mechanism, **unaccepted balance** | Full-party/level receipts and apex-only scaling tests | Controlled Normal/Teeming 2- and 5-person phone samples; tune the diagnosed authority only |
| Combat graph/progression | **Partial, active** | True 72-node graph and migration authority are live; 23 nodes have real scenario consumers through `6bb37ca` | Promote remaining consumers in dependency waves; no inert purchasable nodes; Shatter/Distiller remain Homework-held |
| Afflictions | Source-complete | `16fab7a`; one typed Burn/Poison/Dazzle/Bleed collection, exact targets, cures, coatings, Stonebark and legacy adoption | Phone combat presentation/selection pass |
| Gear inventory/equipment | Source-complete core | Stable instances, frozen profiles/slots, exact-source transfers, overflow and lossless migration tests | Final item identities and continued phone comparison-flow acceptance |
| Blacksmith/Tannery/Bowyer/Armoury/Weaponsmith | Source-complete first systems | Property recipes, exact samples, receipts, station tiers and atomic commits | Phone flows; reforge's inert paid-rank progression still needs its separate correction |
| Trading Post | Source-complete | Sell/buy/refresh plus mixed resource/material/item shelves in `9ab833d` | Phone buy/sell/capacity/stale acceptance and later economy tuning |
| Recycler | Source-complete | Receipt-first salvage, protected cases, exact identity and opening Noll route | Phone sell→recycle→make→bind acceptance |
| Apothecary | Source-complete | Nessa lifecycle, build, Lesser Salve teaching, recipe-ID/cost/coating corrections in `13f0c13` | Phone build/inference/craft/use pass |
| Scent Mask | **Designed only** | Exact recipe, 12-turn chemo-only hesitation and composition matrix specified | Implement only after Apothecary acceptance |
| Essence continuation/refining | Source-complete candidate | Raw drops, continuation subsidy and Spring 2:1→3:1/continuous-settling implementation/tests | Multi-expedition economy and Spring-phone acceptance |
| Expedition return receipt | Source-complete | One typed constructor, stable resource/item/material identity and atomic runway in `07c9aee` | Phone all-category portal/failure recap and legacy display pass |
| Failure retention | Source-complete | Outcome-wide discrete budgets and stable largest-remainder resources in `f9ec86c` | Phone defeat/collapse receipt pass; player recovery agency remains Homework-held |
| Base/station routing | Partial but broad | 24 station routes resolve and main maker/knowledge/realm destinations exist | Later station payoff systems below must not be mistaken for route completeness |
| Anchorage/realms/person placement | Source-complete core | Durable realms, explicit sustain/rest settlement, exclusive Party/Home/realm placement and receipts | Phone multi-realm settlement/assignment acceptance |
| Anchored production | **Designed only beyond core posting** | Worldwork/posting exists; renewable source/outcome/delivery depth is authority-only | Implement after current playability gates, not before them |
| Distillery | Source-complete first slice | Blank crystallisation, three typed cores, provenance and first Heat consumer | Retuning/Infuse held; phone economy pass |
| Channelworks | **Partial / misleading UI** | First Heat fixture exists and can be constructed | Add one-time restoration receipt and label repeatable action “Build another conduit” |
| Deep Works | **Designed only** | No live route/model/rules/tests found; current document is an implementation contract, not implementation | Implement only at its roadmap phase after existing systems close |
| Tavern/random companions | **Designed only** | Firepit exists; no live Tavern route/visitor/wants system | Later roadmap phase |
| Menagerie/taming | **Designed only** | No live Menagerie route or trust/assignment engine | Later roadmap phase |
| Living-world predation | **Partial pressure effect only** | Swarm/Predation alter generated population/tier; creatures do not yet act on one another during a run | Implement bounded simulation later; do not claim living-world behavior now |
| Flora | Source-complete core | Traits, metabolism, ground-writing, tissue harvest and active flora tests | Continued tuning and final art acceptance |
| Creatures/bestiary | Source-complete core | Generated species/specimens, derived combat/loot/names and truthful Bestiary records | Final creature art and longer campaign balance |
| Analysis/instruments | Source-complete first system | Eight instruments, loadout, calibrated observations, upgrades and Lens consumption | Values and phone density remain playtest tuning |
| Apex loop | Source-complete core | Direct-contact consent, eight weapon identities, rewards and Bestiary sightings | Difficulty bands and later condition-favoured hunting |
| Item visual identity | **Partial** | Stable ItemID reaches consumers; consumables have a frozen functional placeholder pack; most catalogue items retain explicit fallback | Aimee-authored immutable `catalogue-items-v1` pack plus one generated registry |
| Character visual identity | **Partial** | All 29 named travellers have placeholder-pack consumers across major screens | Binder, Quill, generated people and final Aimee-authored replacement art remain |
| Place/station visual identity | **Proof only / not a native pack** | AssetLab contains reviewed place sheets, but no place manifest appears in the native visual runtime | Freeze an integration pack and add stable StationID/SiteID consumers before claiming native place art |
| Combat-stage visual system | **Proof only / partial native presentation** | AssetLab combat and combat-UI sheets establish camera, rank/reach and state grammar | Native combat remains ordinary SwiftUI/SF-symbol presentation; port only after gameplay consumers stabilize |
| AssetLab conformance | Strong proof boundary | Five frozen integration manifests exist; the visible-command golden contains 293 hashes | A proof/contact sheet is not implementation. Only manifest-pinned native consumers count as integrated |
| Bug reporting | Source-complete local queue | Screenshot/context capture, durable outbox, export, semantic trail and honest Save/Done | Phone save/share pass; direct submission remains unavailable until approved relay/credential |
| DEBUG roadmap/provenance | **Partial truth boundary** | Current diagnostics correctly call the JSON value a bundled roadmap claim | The app cannot prove which commit is installed; signed build provenance remains an external receipt rather than runtime-observed truth |
| Bestiary/Living Analysis | Source-complete mechanism, **modelled evidence** | Both derive deterministic generated reference samples and now label them as samples | Retain approximate/sample wording; never present these as measured wild-population truth |
| Provisional catalogue values | **Partial disclosure** | Content validation classifies settled, playtest-tuning, provisional-copy and legacy-only fields | Ordinary release UI still presents many playtest/provisional values without a visible provenance distinction; correct only where the distinction matters to player decisions |
| Tutorials | Partial and deliberately last | Contextual opening slices exist and overlay rather than reflow main UI | All additional tutorial content stays dead last |
| Great Work/endgame | **Held** | Boundary/history requirements are documented; no ending/reset is invented | Dedicated later emotional/endgame review with Aimee |

## Confirmed implementation defects or truth gaps

### P0/P1 — correct before claiming current systems complete

1. **Roadmap drift:** five implemented commits remained `queued`; combat consumer count and active
   boundary were stale. Corrected in the operational JSON with this audit.
2. **Penmanship identity contradiction:** Pencil is still live in research and diary data despite the
   settled Brush design. This is not presentation-only; it needs stable-ID migration.
3. **Compound difficulty fossil:** ordinary compounds still mutate enemy tier through the retired
   flat path. It can invalidate encounter-balance evidence and therefore precedes final tuning.
4. **Channelworks entitlement ambiguity:** construction grants/restores Oda's fixture, while the
   visible action still says `Construct Heat Conduit fixture`; no durable separate restoration
   receipt exists.
5. **Combat v2 incompleteness:** the graph can be displayed before all 72 effects are live. Native
   purchase promotion must remain DEBUG/test-only until unsupported nodes cannot be bought as if
   functional.
6. **Authored-text incompleteness:** missing/review dialogue must remain visibly provisional or
   absent; DEBUG drafts cannot silently become release prose.
7. **Installed-build provenance:** the bundled roadmap is not device introspection. It may describe
   the latest signed install receipt, but DEBUG/export must continue calling it a bundled claim.
8. **Synthetic analysis authority:** Bestiary and Living Analysis use deterministic generated
   reference samples, not observed ecology. Current approximate/sample language is required and
   exact percentages must not regain “in nature” wording.

### P2/later — real gaps, correctly deferred

- Scent Mask, compound assembly, Deep Works, Tavern/random companions, Menagerie/taming, bounded
  predation, Lys catalogue depth and anchored renewable production are designed rather than built.
- Reforge's paid fractional ranks can fail to alter rounded combat outcomes; use the settled
  correction rather than polishing the current meter.
- Final handmade item, character, place, sigil and combat-node art remains Aimee-owned. Functional
  placeholders are valid development assets but never “final art.”
- Reviewed AssetLab combat/place/splash/contact sheets are design evidence, not automatically native
  assets. The native runtime currently has pinned world/map, named-traveller-placeholder and
  consumable-placeholder seams; later packs need the same manifest→registry→consumer gate.
- The Great Work/reset/endgame remains intentionally held.

## Source-of-truth defects

- `BACKLOG.md` still contains many unchecked items that are now built and several checked legacy
  promises that current design supersedes. It is a historical milestone ledger, not implementation
  status, despite its old introductory wording.
- `docs/the-queue.md` mixes current, built, designed-only and superseded status in prose; for example,
  it still says Apothecary reachability is queued after `13f0c13`.
- `docs/state-of-the-build.md` is a useful narrative overview but its sentence “every major
  mechanism ... is represented end-to-end” must be read as broad prototype coverage, not full
  design conformance.
- `Sources/Content/Data/playability-roadmap.json` is the only operational status authority. This
  audit updates it; later work should derive summaries from that file instead of manually copying
  status into three prose ledgers.

## Verification rule from now on

A feature may move to:

- **readyToTest** only when its exact current authority maps to model/rules, persistence where
  relevant, reachable player UI, focused scenario tests, migration/tolerance and a named phone gate;
- **complete** only after its required phone/campaign gate passes, or when the gate explicitly says
  future observations are ordinary regression rather than acceptance; and
- **accepted art** only when the native consumer uses the pinned asset/registry and Aimee's approval
  boundary is satisfied.

Every future audit should compare canonical design IDs to live consumers and fail on missing or
extra IDs. Counting documents, screens, tests or commits alone is not conformance evidence.
