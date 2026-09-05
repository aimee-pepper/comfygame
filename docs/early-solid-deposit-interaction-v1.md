# Solid deposits and manual bump mining — first cutover

**Authority:** direct Aimee instruction relayed by PM on4 September2026. Decided intended behavior, not delivered. Exact authored rows: `early-solid-deposit-interaction-v1.json`. This supplements the early host/consumer contract without changing the measured availability policy or delaying its bounded world check.

## Physical rule

Substantial solid deposits and boulder-sized forms block at their physical base. First-cutover Iron and Coal deposits each occupy one blocking cell. Their existing Pick1 requirements, three hits and2 units per hit remain. Small loose stones, Clay, Salt crust, herbs and low gathering patches remain walkable, with their existing separate underfoot gathering action and requirements. Merely walking onto a loose source does not gather it.

Only an explicitly defined harvestable producer grants mining output. This does not create a new Rubble producer or turn every decorative rock into loot. A new blocking deposit must sit on supporting ground whose ordinary edge and base become traversable when its obstruction is removed; this does not turn a cliff into stairs, fill a chasm or rewrite water/height rules.

## Deliberate movement becomes one mining action

An explicit cardinal one-cell player step into a normally disclosed live deposit is a mining intent from the adjacent square. An explicit adjacent-cell step has the same meaning. Use the **currently selected, packed qualifying Pick**, preserving its identity and existing tier check. No automatic tool switch, tool grant, or bag change is added.

Resolve that intent through the existing exact harvest proposal and durable owner (`EarlyMaterialGameplayRules.quote/apply`, `EarlyMaterialHarvestRules`, `GameStore.harvestEarlyMaterial`). A successful hit saves its finite work and exact yield, advances **one** world turn and applies the existing world effects once. The actor stays on the original adjacent square, including on the final hit. Full depletion removes this deposit’s obstruction; the next deliberate step enters the cleared square at the ordinary terrain movement cost. Do not combine final mining and movement into one ambiguous action.

Wrong, absent or insufficient tool; hidden/missing/exhausted/stale target; out-of-reach action; existing priority interaction; and save failure retain their existing harvest refusal. They spend **zero mining turns**, make no work/provenance/output change and do not fall through to a separately charged blocked movement. Existing encounter and authored-interaction owners still take priority; this is not a way to bypass them. Normal visibility is required, so a failed bump does not disclose hidden loot or silently mine through fog.

## Automatic movement is different

A live deposit is non-traversable for ordinary pathfinding. An automatic route goes around it or stops. A route can end on explicitly selected reachable adjacent ground, but arrival never queues a mining hit. If a route encounters a newly blocking source, stop or replan through the existing navigation owner. Only a fresh manual mining intent may spend the harvest turn. Do not silently add auto-mining, auto-explore harvesting, repeated mining on arrival, or automatic tool switching.

## Placement and conservation

Protect the route to return, required teaching, early resources and their work positions, and initial tool access. At least one cardinal adjacent work cell must be reachable after all blocking placements, using the actual ground-edge rules. There must be no sole reachable Iron source behind a requirement for an Iron Pick. Deposits may create detours and later-opened shortcuts. Deliberately fully tool-gated optional areas remain later scope; this change does not authorize them.

Use the same finite population budgets and written/ordinary reservations. Essential source access is checked against the final blocking layout, not a pre-placement open map. If a candidate cannot satisfy its declared host, work position and protected route, reject that placement rather than fabricating matter, a tool, or a second reward.

## Separate collision from tree canopy

Engineering’s present `EarlyMaterialProducerDefinition.blockingTrunk` and `EarlyMaterialProducerState.liveCrown` couple movement blocking to a five-cell foliage crown. **Do not mark Iron/Coal as blocking trunks to implement this decision.** A deposit’s physical obstruction is separate from tree/canopy ownership. Mining it must not create or remove foliage, clear a neighbouring tree’s canopy, reveal hidden terrain, or invent a new five-cell sight mask. Existing object/terrain visibility rules remain; literal art waits for a named implemented native consumer and protocol.

## Durable and old-world behavior

Save source identity, work, exact acquired lot, depletion, obstruction, turn and terminal effects in the same existing durable transaction. Publish the mining impact/success only after commit. A failed final-hit save leaves the source solid with its prior work and holdings; retry/reload cannot duplicate yield. On successful depletion remove only that source’s obstruction.

Freeze new source physical semantics at generation. Already-created worlds and older source receipts keep their saved collision behavior; do not turn an old passable source into a blocking tile beneath the player by changing a live producer lookup. Retain saved partial work and anchor state. This is new-cutover behavior, not silent reinterpretation of existing maps.

## Focused integration acceptance

Check manual Iron hits1/2/3 (each2 Iron and1turn, actor still adjacent), final clearing followed by an ordinary step; wrong/no/weak tool refusal without a second movement cost; automatic route detour/stop without mining; failed durable final hit and exact retry/reopen; no overlap-canopy loss; protected return and source-work positions; and legacy collision. These are requirements for the native correction, not completed tests or a phone receipt. Do not expand the active availability experiment or create a new terrain/configuration matrix for this rule.
