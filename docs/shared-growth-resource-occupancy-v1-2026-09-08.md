# Shared growth, mineral and loot occupancy

8 September 2026. **Accepted invariant and correction contract; implementation pending.** Aimee clarified that growth and mineral nodes/lootables must not overlap. This extends the explicit shared resource occupancy contract to actual growth bases and post-generation placement. It does not revoke adjacent mining or treat canopy overlap as duplicate sources. A reported image alone is not proof of a particular conflicting coordinate.

## One canonical physical owner per tile

All placement paths share reservations: a physical tree/bush/plant base, harvest patch, mineral/deposit source or loose loot owner reserves its base tile. Rooted non-harvestable physical plants also reserve their base. Tile.flora, a linked resource producer and its rendered trunk can be references to ONE canonical plant source, not three occupants: deduplicate only with actual source identity/linkage, never because coordinates match. One owner may yield several existing units or material kinds without becoming several nodes.

Canopy/leaf overhang, shadows, terrain's growth-colour layer and purely decorative ground texture are not additional physical owners. Do not erase a grass-covered terrain layer merely because its enum is growth. Conversely, an independently rooted bush is not exempt by being called decorative. Preserve real hazardous-source semantics; this is not a new movement or hazard model.

Generated guarantees, ordinary flora, minerals, loose sources and later loot placement consult the same reservation state before committing. Include previously reserved sites/portals/travellers, actual approach routes and other existing protected content exclusions. Existing actor reach and movement owners stay authoritative; an enemy does not become a permanent resource reservation. Check again at commit after any intervening placement. Reserve atomically with the owner so another pass cannot use a stale empty tile.

## New generation and runtime placement

Keep existing seed, source type/identity, habitat/support rules, quotas, mandatory promises and legal interaction positions. Choose from legal vacant candidates deterministically within each existing generation path. Validate the entire required placement assignment, not each guarantee against an independently empty map. If mandatory hosts cannot fit, use the existing generation retry/failure before paying/admitting the book; optional omissions remain governed by existing quotas. Do not widen terrain, hide guarantees beneath plants, grant an inaccessible workaround or generate substitutes.

For an event that physically places already owed loot, find a vacant destination with the same existing legal pickup/access conditions. First use the intended tile if legal, then nearest legal candidate by movement-path distance from the event's legal access position, with y then x ties; preserve existing broader placement restrictions. Never move an item to inaccessible dark water simply because aquatic creatures may live there. If no legal destination exists, use an already established reward-custody route only if that event already authorizes it. Otherwise preserve the uncommitted/pending reward and route the exact blocked placement to PM; never mark delivery successful, lose the reward, mint it twice or invent automatic satchel/Return delivery.

## Existing saved conflicts: deterministic, atomic, non-destructive

Identify conflicts by canonical owner IDs and source coordinates, including linked flora/producer fields, saved work and reservations. Do not regenerate the world. Build the entire proposed repair before changing saved state. Existing earned inventory is never part of relocation.

Protect fixed entry/portal/site/quest anchors and world geometry. Prefer retaining legitimately discovered or partially worked source anchors over unseen, untouched optional sources. Among equally protected owners, retain rooted/anchored sources before loose loot, then stable owner ID order. Process conflict tiles y then x. This ordering is repair tuning, not new generation probability.

For a displaced owner, move its complete identity/provenance/work/remaining quantity/colour/version bundle only to an unoccupied compatible host with a legal interaction position in the same previously accessible movement component. Search candidates in increasing legal path distance from the old interaction position, then y/x; solve reservations for the whole conflict component before commit so a greedy early move cannot steal the only host for another source. Preserve guarantee routes and quantities, terrain/water quotas and all unrelated placements. Revalidate after the plan; update every location reference atomically with the repair version. Never manufacture a second source ID or duplicate a reward.

A discovered source must not silently move into unexplored terrain. Automatic relocation of a known source is allowed only to an already disclosed compatible destination and with one durable player-facing correction notice identifying the source and its new known position. Update its remembered location in the same receipt; no stale duplicate marker. Unseen sources stay undisclosed. No new discovery reward/XP or hidden facts are exposed by repair. Do not move a currently targeted, pending-interaction or in-flight-work source until its existing action owner is idle.

If the full conflict component has no valid lossless assignment, do not perform a partial repair, delete owners, overwrite stock, change prices, award all overlapping yields or block/reset the campaign. Preserve its exact pre-repair data, reject further placements into its occupied cells and send PM the conflicting IDs, protection constraints and exhausted legal hosts for a concrete correction. The overlap remains explicitly unresolved, never counted as fixed. Other independent valid components may repair. This is the specified safe failure path, not permission to treat overlap as intended behavior.

## Source evidence and completion

Delivered362 Sources/Rules/EarlyMaterialPlacementRules.swift initializes occupied from nonempty tile content, with reservedPoints conditional on reservationVersion. Flora and later events have other state owners; this local set does not establish the complete invariant. Engineering must connect those existing owners rather than add another independent per-pass occupancy allowance.

Focused checks cover root+mineral+loose conflicts across order/post-spawn paths, linked single-source multi-yield, overhang/ground texture, required-host contention, deterministic repair and retry idempotence, saved partial work/quantities, known-location notice/memory, no legal repair and rollback on save failure. Use coordinates to prove occupancy and reuse relevant reachability tests. No natural-world census, new trial or Design native rerun. Report unrepaired components through PM.
