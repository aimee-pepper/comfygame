# Remembered trees — last observed appearance

5 September 2026. Bounded Design contract for Aimee’s report that fully seen trees disappear outside current sight in the 3D trial. **Requested correction, not delivered or verified.** No full 3D migration approval is inferred. Engineering owns the implementation; Design resumes the whole Blacksmith batch after this handoff.

## Intended behavior

A stationary tree that was legitimately fully seen remains represented at its last observed location on remembered terrain when the player walks away. Render its **last observed** shape, appearance and known supporting terrain, not the tree’s hidden present state. A canopy glimpse, fringe sight or previously revealed ground alone is not proof that the tree itself was fully observed.

When the tree’s placement returns to legitimate full sight, refresh its record from the now-disclosable observation, including an observed stump or absence. Persist that new observation so an already observed removal cannot resurrect when the player looks away. Normal full-sight harvesting can update through that same authorized observation boundary. Do not refresh a remembered tree merely because a hidden simulation event changed its current data.

The player may therefore remember a tree after an unseen event has removed it. That is honest memory, not a current-state guarantee. Do not show unseen growth, removal, relocation, depletion, new trees or revealed resource yields through this feature. Its image is not a harvest target or proof of current movement legality; actual actions keep their existing rules and disclosure.

## Knowledge owner and minimum record

`WorldMap.Tile.isRevealed` is persistent terrain knowledge. The tile’s `flora`, `earlyMaterialSourceID`, `earlyBlockingTrunk` and current state are mutable source facts, not a saved observation. A revealed-ground bit must never authorize reading those hidden live fields. The current WorldArrivalReceipt projection only includes flora at full sight; that diagnostic record is evidence of the distinction, not the native runtime memory owner.

Use the actual persisted per-run exploration-knowledge owner (or a minimal optional last-observed stationary-tree entry there) to retain the admitted snapshot: world identity, placement coordinate, safe tree/source identity where previously disclosed, last observation time/order, static trunk/canopy shape and appearance references, and only the support facts needed for that observed representation. An observed absence must replace an older positive record. Do not create a general event logger or duplicate the gameplay placement owner; this record carries knowledge, not another harvestable tree.

The renderer consumes this disclosure-filtered snapshot for remembered trees. It must not resolve a remembered identity back into hidden mutable geometry or today’s source state. If the snapshot references immutable art definitions, only those already admitted static definitions may be read. New growth stage, colour changes, live animation parameters and hidden state remain unavailable until legitimate sight refreshes them.

## Effects and other entities

Remembered geometry must not leak hidden height, nodes, actors or flora through shadows, reflection, transparency, occlusion, normals, collision-driven presentation or lighting. Use only admitted remembered geometry and already public presentation state for its treatment; do not query hidden caster/effect state to make the remembered image look current. Tree fading may keep its established player-facing presentation, without disclosing what exists unseen behind the canopy.

This change is stationary-tree memory only. It does not remember live enemies as present, update their location, reveal new trees or add current Dangerous growth markers on remembered-only terrain. The generic hazard marker remains limited to the actual currently fully visible harmful patch. An old remembered tree is not current evidence of harm. Existing established map/site/portal knowledge remains intact.

## Legacy and persistence

Keep absent new records backward compatible. A prior explicitly saved, sufficiently complete observation can supply the memory record. A generic revealed bit or current hidden tree cannot. If an older save lacks the actual observed tree facts, retain honest existing remembered terrain until a new lawful sighting; do not fabricate a historical tree shape from the live hidden map. Closing/reopening retains actual saved observations without performing an unseen refresh.

## Focused cases for Engineering

- Fully see a tree, walk out of sight, pan/reopen: same last-observed tree remains on remembered ground.
- Hidden simulation removes/changes it: memory does not update; legitimate full sight then updates it, including observed absence.
- See ground without fully seeing tree; fringe/canopy glimpse; never-seen tree nearby: no new tree-memory disclosure.
- Observed harvest/removal followed by leaving and reopening: no resurrected remembered full tree.
- A hidden enemy, hazard patch, changed shadow caster or resource behind the tree changes: memory rendering provides no new information and no remembered active hazard marker.
- Old save has only revealed ground: no guessed live-tree reconstruction; new full observation establishes the record.

Use the actual native consumer and normal bounded implementation check. No extra Design phone delivery verification or configuration matrix is requested.
