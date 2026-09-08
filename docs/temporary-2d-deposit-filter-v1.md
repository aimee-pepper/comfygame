# Temporary2D deposit filter — recording scope

7 September2026. **Direct Aimee direction, delivered344; new-world behavior internally verified.** Aimee wants footage of the game before its3D transition and explicitly accepts missing progression. No further approval, progression balancing or alternate-resource design is needed. Encounter crash and shared text wrapping remain Engineering's urgent priorities;3D node graphics replace further2D resource-art work.

## Exact eligibility and exclusions

Scope is the existing **blocking mineral/deposit class represented by generic boxes**, including analogous legacy emissions of the same unfinished deposits. It is not every resource or every source without a recent art receipt. Engineering's `EarlyMaterialProducerDefinition.blockingDeposit` supplies the exact six current materials:

| Producer | Material | New restricted ordinary2D world |
| --- | --- | --- |
| iron | Iron | Do not generate |
| coal | Coal | Do not generate |
| quartz | Quartz | Do not generate |
| sulfur | Sulfur | Do not generate |
| mercury | Mercury | Do not generate |
| riftGlass | Rift Glass | Do not generate |

**Finished-art allowlist for this unfinished class is empty.** Coal's selected original is inventory-icon approval, and Quartz's available legacy sprite is not its current finished early-deposit map consumer. The withdrawn ore→Iron substitution is not finished approval. No additional acceptance audit is required: existing recognizably rendered sources outside this class remain sufficient for the recording scope.

Keep existing trees, Clay, Salt Crust, Stem/Leaf/tall-stem patches, Resin shrubs, named Apothecary plants and Dyer's Root, plus existing distinct rendered source classes outside the excluded deposit class. Retain their current source identity, costs, tools, quantities and graphics without new2D art. Do not delete these because their approval history is older. No new resource alias or alternative source may bypass the six exclusions. Equivalent legacy generic-box deposits must use the same admission exclusion rather than reintroducing them in a later pass; unrelated already rendered legacy sources remain unchanged.

**Legacy/source boundary clarification:** Salt Crust and other existing hand-gathered Salt are retained, including written Salt guarantees. Rubble as ground or an existing loose hand-gather is retained; do not delete terrain or invent a new rubble-deposit category. Legacy harvestable ore nodes representing Iron follow the Iron exclusion, while underlying ore-bearing geology remains. The legacy mineral candidate list also contains copper/silver/obsidian/gold/adamant: preserve an existing recognizably rendered source rather than demanding fresh approval, and exclude only actual generic-box deposit consumers or excluded-material equivalents. Use a fixed current source/consumer mapping at authoring/generation, not current image-load success, fog, renderer selection or a new art census. Do not rewrap a suppressed new Iron node as a legacy source to bypass the rule.

## Creation, saves and guarantees

Use a frozen new-world creation policy, proposed `BoundBook.recording2DNodePolicyVersion=1`, for **newly generated ordinary2D worlds only**. It is internal generation policy, not a new mode, menu, trial, reset or automatic two-world counter. PM controls its later removal through an ordinary implementation update. The actual quote/preparation context selects it before spending; both factory branches, source placement and final admission consume the same frozen value. Existing written drafts may be reviewed under the creation policy before generating a new world; do not silently reuse an incompatible earlier quote.

**Minimal factory context approved:** Engineering may add a persistent creation-context field on the existing private3D campaign state, assigned by `OrthographicTrialSession` before quotes/new-book preparation. The existing factory can consume that GameState context to leave the optional recording policy nil for3D/old books and stamp1 on newly created ordinary2D books. Actual3D session/save provenance may establish context for future binds in an older private3D session; it never alters that session's existing worlds or retags a normal user campaign because its renderer changed. Quote and preparation must read the same context; no broad new mode or UI/context system is required.

Existing saved/generated/anchored worlds and unfinished opening continuations retain all sources, visible markers, work progress, blockers, memories and inventory unchanged. Never make existing unfinished deposits invisible, delete them, auto-harvest/refund them, mark them depleted or edit the user's campaign. Their older graphics may remain visible because existing-world removal is outside scope. Existing earned/packed stock remains usable. A renderer switch never spawns/deletes nodes or changes the stored policy.3D-created worlds retain normal node generation; a previously restricted world does not acquire deposits just because opened in3D.

Exclude the six producers before reservation planning/placement, not as a draw-only mask or after-save deletion. Do not create their source receipts, occupancy/blocking flags or harvest targets. Keep underlying terrain/geology and other content unchanged. All relevant generation passes use the same static producer classification, never current image-load success or camera state.

- Remove ordinary required Iron/Coal and any other excluded-deposit counts from this policy's reservation expectations, budgets and final source/work-route assertions. An otherwise valid ordinary recording world must not fail because an intentionally excluded node is absent.
- Preserve Clay/Salt/flora/tree reservations, protected entrance/portal/lesson/traveler routes, legitimate physical-host constraints, shared occupancy and all remaining validation. Do not disable the entire early-source validator to implement the filter.
- **Explicit Iron writing:** if the selected writing requires guaranteed Iron deposits, show **“Iron deposits are temporarily unavailable in2D.”** before spending or committing that world. This is a clear availability refusal, not an invalid-candidate/save error, silent promise removal, paid failure or substitute material grant. Keep the page/draft and owned knowledge. Apply the same rule to any already implemented explicit guarantee for another excluded deposit.
- Written Salt is outside the exclusion and retains its valid plan/guarantee. Do not discard it merely because the Iron-plan path changes. No new writing subject or material is introduced.
- Check both new-world factory branches and `Worldgen` writtenIronPlan/writtenSaltPlan/reservedPoints/source-placement/final-work-route consumers against this single policy. No legacy pass, fallback grant or opening reservation may silently regenerate an excluded deposit. Other genuine preparation failures keep their existing atomic refusal behavior.

## Accepted temporary consequences

No new Iron/Coal/Quartz/Sulfur/Mercury/Rift Glass acquisition from these excluded nodes in restricted2D worlds. Iron-learning and Iron/Coal-dependent Forge, Ingots, metal tool/gear progression may be unavailable without already owned stock. Specialist mineral crafting is similarly limited. This is accepted recording scope, not a bug to solve with altered recipes, free resources, guaranteed merchant stock, a substitute mineral or a new progression route. Existing obtainable plants/Clay/Salt/wood remain as they work today. Do not promise full opening completion under this temporary restriction.

Ordinary2D recording journeys must enter, explore, encounter and save/reopen through their existing route once Engineering's crash correction is verified. No new player trial, fresh campaign reset, forced3D migration, source hunt, recipe audit or phone operation is assigned to Design. A future return to normal spawning applies to subsequently generated worlds; do not populate already frozen recording worlds on load.

## 3D node art priority and implemented consumer

**Consumer implemented in342; Blender replacements authored and native verified, phone integration pending:** Engineering `docs/resource-node-renderer-seam-2026-09-07.md` in world-crash-and-notifications names `Sources/VisualRuntime/OrthographicResourceNodeRenderer.swift`, called by `OrthographicWorldPrototypeView` using sanitized `OrthographicResourceNodePresentation` from the adapter. Input is disclosed nondepleted source identity, producer/material, completedHits/requiredHits; depleted sources yield no presentation. One tile=one unit, +Y up, ground-contact tile-center root; X/Z±0.45,Y0…1. Final assets/components are authored in Blender and exported to the existing bundled asset consumer; runtime assembly remains code-owned. Earlier code-authored meshes are interim. OptionalPNG≤512×512;≤32meshparts/4096triangles per node. Grey boxes remain unfinished artwork. This is the ready consumer for the already-assigned Asset3D node batch, not a new2D export or additional trial.

Phone342 source359b16b74695f437cf2d4bf44fb9e3d7262e45d8/treeda51d711bf893cee785db036b7f41320c4cc14e6 installed/read back2026-09-08T00:21:46.217413Z and ordinarily launched, per `phone-342-delivery-2026-09-07.md`. Integrated4PASS covers retained-world encounter/reopen, notification wrapping and typed-node consumer. It does not establish finished artwork, physical encounter acceptance or delivery of this temporary2D filter. Asset has the exact consumer/output/actual-target route; use existing Settings3D ordinary route at iPhone16Pro402×874pt/1206×2622px/default text/current appearance. No new world search or phone campaign manipulation. Follow the existing shared readability contract for source/action disclosure and preserve actual world placement/work/occupancy/rewards.

Bounded Engineering acceptance: both new ordinary2D branches omit all six unfinished deposits without invisible occupancy; retained source classes and valid ordinary Bind remain; explicit Iron guarantee refuses clearly before spend while written Salt still works; existing world/stock remains unchanged after reopen;3D creation retains nodes and renderer toggles do not mutate either policy. Reuse existing focused/native routes while fixing the actual encounter crash/wrapping; no art census or duplicate Design tests. Route failures needing Aimee engagement to PM.


### All six deposit models — internal Asset milestone

Asset commits `841218cc70a2aea878e2171811a4a22654e230c7` then `7e6e68891c266c34fd4c4b0993bb8053dc1db61f` in `resource-node-3d-art-v1` complete Coal, Iron, Quartz, Sulfur, Mercury and Rift Glass in the named renderer. Receipts: `docs/resource-node-3d-art-2026-09-07.md` and `docs/resource-node-3d-remaining-2026-09-07.md` in that worktree. First batch4/4PASS; remaining native checks2/2PASS9.587s, including all-six mesh bounds/budgets and admitted work states. Ordinary-scale review used iPhone16Pro402×874pt/1206×2622px, default text/current dark. Design relies on these supplied receipts; no duplicate native or phone check.

**Mercury depiction accepted:** a solid mineral-bearing host with silver exposed faces is consistent with the existing blocking Pick-mined Mercury producer. The reviewed source registry and material/Apothecary design records specify no conflicting literal host. This is a game depiction, not a new mineralogical claim, liquid pool, refining recipe, hazard or inventory subtype. Existing source yields and tool requirements remain authoritative. Rift Glass is opaque and non-emissive; neither asset introduces a rarity signal.

Engineering owns integration and subsequent delivery evidence. All six are internally reviewed artwork, not yet claimed installed or Aimee-accepted. Finished3D models do not change the temporary2D exclusion. Separately, Aimee confirmed the encounter crash recurs on342: its internal PASS and ordinary launch did not resolve that physical failure; urgent crash work remains first.


### Subsequent343 crash-correction delivery

Engineering receipt `docs/phone-343-delivery-2026-09-07.md` in world-crash-and-notifications supersedes the urgent investigation status above: source91b853f8a83d663b5bd1cb4dd91193f69b59dcf1/tree1001cd3176fbe6e2cbb298b749983abfbdca9188 installed/read back2026-09-08T00:44:29.505163Z, ordinary launch PID87862 survived. Actual342 saved-state movement→encounter→Techniques→cold-reopen passed internally, including a1MiB main-stack executable. Campaign preserved, no phone gameplay; physical encounter resolution remains unclaimed.343 includes neither the recording policy nor Asset artwork. Engineering resumes the settled policy from preserved WIP5cf0d9f4 on343 ancestry; family work remains paused. Design relies on this receipt without repeating delivery checks.


###343 physical closure and concise mining copy

PM relayed Aimee's direct confirmation that343 fixes the physical encounter crash. This supersedes the unconfirmed physical result above; no reruns requested. Aimee also rejects paragraph-length routine mining prompts. Decided copy for the next useful Engineering delivery:

- Preserve actual quote refusal and existing gate order; the current `try?` failure must not imply every failure needs a tool change.
- Disclosed `wrongTool` with an owned qualifying tool: `Select your {tool.displayName}.` Choose a deterministic existing qualifying tool, preferably lowest adequate tier. Examples: `Select your Stone Pick.` / `Select your Iron Pick.`
- No owned qualifying tool: `Requires {Tool} Lv {minimumTier}+.` Example `Requires Pick Lv 2+.` Keep existing class/Lv naming; do not suggest selecting unavailable gear.
- Hidden/missing/stale/exhausted fallback: `Cannot mine here.` No hidden material/tool/tier disclosure.
- Actual priority interaction: `Finish this interaction first.` Actual out-of-reach: `Cannot reach this deposit.` Keep the existing encounter guard.
- Successful quotes harvest as before. No source-name preamble, routine tutorial, new mechanic or turn/tool change. Preserve wrapping capability. No broad copy audit.

Engineering has this exact contract for the recording-policy delivery.343 still carries the verbose copy; concise copy is decided, not yet delivered.


###344 current delivery supersedes pending filter/mining status above

Engineering sourceefeab33303eff0a2bd1a2d1994ca1ae9548aa404/treeeced7872c5ad8310a41ae35748c1eb9388c61b92 is installed/read back2026-09-08T00:58:43.838086Z; ordinary launch87955 survived. Receipt `docs/phone-344-delivery-2026-09-07.md` in recording-2d-node-policy records6/6 cumulative internal checks and actual native north movement/reopen. New ordinary2D six-deposit exclusion/private3D exception, pre-spend Iron refusal, preserved Salt/old worlds/stock and concise mining are delivered. Halloway chronology correction also included. No phone campaign play/new-world acceptance claimed.343 physical encounter success remains closed.3D artwork is still separate. [Current full copy audit](notification-and-chronology-audit-2026-09-07.md) supersedes the earlier narrow-copy scope and documents Mercury's preexisting liquid-in-seam diary without changing the approved solid host depiction.


**Asset closure:**658edadf07fc04a8ecdb049434af799ae8c69196 in resource-nodes-blender-v1 replaces all six code-authored finished meshes with Blender-authored USDZ assets and a cached native loader. Five focused/native checks and asset-byte/bounds/budget verification passed. Current phone346 does not claim this integration; Engineering owns delivery. No new art audit or Aimee decision is needed.
