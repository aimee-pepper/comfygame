# Player feedback — wood, Hide stacks, Apex status and notices

**6 September 2026 · Direct Aimee decisions relayed by PM; implementation pending.** This is one bounded feedback batch, not a replacement for the six whole-shop contracts or an additional audit. Engineering owns implementation. No new delivery or phone verification is claimed.

## 1. Wood should read as wood from this world

**Accepted:** most wood comes from actual trees coloured by the world's colours. The exact tree wood colour follows the resulting Logs, shaped Hafts and their gear regions. Fallen logs are a permitted supporting source before a good Axe; standing still beside a large tree should not be the only early option.

**Current source distinction:** `Resources.timber` still has the public name “Timber”, while the new physical registry already distinguishes `flora.log.softwood` and `flora.log.hardwood`. The early source-colour contract already has a world foliage base/explicit source assignment owner. These facts do not prove every renderer and old yield uses the same wood colour.

Use **Logs** as the common player-facing word, with **Softwood Logs** and **Hardwood Logs** when known. Rename the old “Timber” display term across harvest narration, stock, recipe requirements and choices; retain its stable legacy resource ID, quantity, price and lawful uses. If old type is unknown, show “Logs” with a legacy/unknown-type detail rather than inventing Softwood or Hardwood. The historical term may appear once in explanatory migration text, not as a competing new resource.

Existing untyped Timber that is genuinely wood may satisfy an **any-Log** requirement through the explicit legacy-stock adapter, preserving its real owner/unknown appearance. This includes early Axe/Pick raw-material improvements and appropriate foundations. It must not pass a Hardwood-only bow/Haft requirement by name alone or be copied into both typed stocks. No stock deletion, automatic packing, new Axe gate or free improved tool. Starting Axe1 and small-tree routes remain valid; explain smaller trees/fallen wood when a standing tree needs a better Axe.

For opted-in tree production, freeze the actual rules-owned wood base colour from the world's resolved palette/source assignment at generation, and use that same source value for the visible woody tree region and its harvested material. Keep leaf/lighting/shading treatment distinct from inherent wood colour. Do not sample screenshots, choose a nearby species or recolour a saved Log from the current world. Explicit saved source colour stays exact through harvest, Return, stack selection, Haft preparation, gear construction/refit and recovery. Missing historical colour remains unknown; known source colour does not become unknown merely because final art mapping is pending.

Fallen wood must be an explicit finite loose-log source, not a phantom standing tree or a new universal wood generator. Keep existing lawful placement budgets, reserved source promises and finite yields; no new global spawn quota or guarantee is implied. If a new typed adapter is needed, use the actual source's known wood type/colour, not a guessed Hardwood reward. Gather through its existing underfoot/low-tool action, with no newly imposed high-Axe gate. Do not backfill arbitrary new sources into saved worlds. Standing trees remain the primary route.

## 2. Equivalent Hide should appear as a stack

**Accepted:** equivalent covering materials visibly group on Return, in Storehouse and in material selectors, with a quantity instead of repeated identical rows. The actual underlying source ownership remains intact.

A typed equivalence group uses exact material subtype, quality band, full source colour/Pattern and all recipe-relevant physical facts: coverage, hardness, covering length, flexibility and coveringProtection under the current Hide/Leather contract. Keep unsupported legacy families separate. World/creature/source IDs and genealogy are retained underneath, but do not split otherwise equivalent physical results into separate visible rows. Different genuine properties/bands/colours remain distinct; do not average them or broaden recipe eligibility.

A group is a display/selection aggregation, not destruction or merging of owned source receipts. Returning three equivalent portions from different specimens shows one row ×3. Selecting two allocates two real units once in stable inventory order, with source detail available when requested. Reload/refusal/stale quotes retain all quantities. Return's gathered/lost/kept categories remain separate if their outcome differs.

Old/new nominal price policies do not create fake material types. Quotes sum the actual selected lot prices; a visible physical group with different historic prices must not pretend all units share one price. Preserve custody, chronology, source colour and every actual contribution through preparation, trade and recycling. The complete Tannery's permission to choose different Leather panels remains; grouping equivalent raw parts is not a renewed matching-only crafting restriction.

## 3. A visible Apex needs an explicit label

**Accepted:** Apex status is recognizable beyond lack of movement. Use the actual `WorldEnemy.isApex`/existing Apex authority, never immobility, size, colour, rarity or a guessed species.

Show a clear **Apex** badge with the already displayed creature marker/target name, and repeat it in the existing creature detail/encounter header where that creature is legitimately disclosed. A sessile ordinary creature is not an Apex. “Apex creature” is sufficient when its proper identity is still unknown.

The badge uses the creature's existing permitted visibility/disclosure result, including any already-authorized Apex range rule; it creates no extra fog bypass, hidden enemy marker or off-screen alert. No lingering marker where an enemy is no longer legitimately displayed, and no hidden species name, reward or movement information. Keep Apex's actual encounter/movement rules unchanged. This is a native semantic marker first; Asset gets no speculative artwork assignment before the implemented consumer is named.

## 4. Category controls for optional field notices

**Accepted:** Settings exposes separate monster-notice and mining/gather-result controls. Muting presentation never disables creature behavior, harvesting, resources, knowledge, receipts or necessary decisions.

Current consumers are `SettingsView`/`AppSettings`, `GameStore.WorldFieldEventBatchV1` and `WorldFieldNarration`, the compact/expanded event panes in `WorldView`, and the separate `WorldMiningFeedbackGroupV1`. Inventory of current event families: enemy sight/alert; resource pickups/harvest/early-material hits; portals/caches/travellers/pages/learning/loot/Essence/animal progress; blocked/refused actions, extra-turn ground, damage/poison, full satchel, crumbling/collapse and ejection. This is the relevant existing field feedback, not OS push notifications or a new notification framework.

**Design first-pass grouping/defaults:**

| Settings toggle | Default | Routine events controlled |
| --- | --- | --- |
| Monster notices | On | `enemySighted`, `enemyAlerted` and any equivalent optional, already-disclosed monster popup |
| Mining and gathering results | Off | Routine `pickedUp` resource, `harvested`, `earlyMaterialHit` progress/yield/depletion popups and the mining-result overlay |
| Finds and learning | On | Optional portal/cache/traveller discovery, learned words/patterns/schematics/Gambits, loot/Essence results, animal-attendance/trust/join progress notices |

These defaults are Design tuning, not additional personal approvals attributed to Aimee. Preserve an existing explicit preference if one exists; do not overwrite user choices on launch/update. Persist through the existing app-settings owner, with no new gameplay save/knowledge dependency. The user may change any of these category choices.

**Always preserve:** blocked/refused/failed-save explanations; actual damage and poison; extra-turn ground feedback; satchel-full/Waiting decisions; instability/crumbling/collapse/ejection; combat entry/choices and return summaries; and explicitly requested reading/inspection/use content when the notice is the only result presentation. For example a requested page's prose must not disappear because “Finds and learning” is off. Existing permanent map markers, target details, yields/stock/depletion state and Diary/knowledge remain available. The Apex badge itself is not an optional monster popup.

Classify by typed event/action/disposition, never by matching English words. A single action can have both muted gathering results and an essential hazard; filter individual optional presentations, never suppress the whole action/batch. Keep canonical raw event IDs, commit/disclosure/receipt data and rule execution unchanged. Filter the event panel **and** the separate mining overlay so the setting actually silences duplicate result surfaces. Visible Read-all counts and Dismiss/advance refer to the remaining presented messages, not invisible notices.

A batch with no remaining visible notices produces no empty card or invisible tap target. Turning a category off removes its queued optional presentation; turning it back on affects future notices rather than dumping an old muted queue. Do not reset deadlines, replay rewards or replace actual required interaction with a notification. Keep this a small event-category projection/settings change inside the current owners.

## Handoff cases and dependencies

Use normal focused implementation cases, no Design phone rerun: old Timber stock remains usable for an early any-Log Axe requirement; a known world-coloured tree→Logs→Haft→gear/refit/recovery keeps its exact base colour; unknown old wood is not upgraded to Hardwood; three equivalent Hide portions show ×3 and allocate two once; a different genuine Hide stays distinct; moving/sessile/Apex visibility cases preserve disclosure; mining-off plus same-action damage still shows damage; monster-off leaves the visible Apex badge; requested page prose and satchel/failed-save decisions remain; settings persist and no empty muted pane remains.

Update the public Wiki as **decided intended / pending implementation**, with the notification defaults labelled first-pass Design choices. Only move each feature to current on its own Engineering delivery report. No new Aimee answer is required for the accepted feedback; the separate shared-service Mote-on-miss decision remains open.
