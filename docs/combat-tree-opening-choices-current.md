# First three combat points — current implementation boundary

**Status:** Game Design complete; implementation-ready after the current Band-1/2 phone blockers  
**Owner:** Game Design owns the playable choice set and release gate; Engineering owns stable-node
purchase, persistence and consumers; Asset Design owns the accepted true-graph presentation  
**Depends on:** `combat-tree-v2-authority.json`, `combat-node-viability-current.md`,
`combat-tree-progression-experience-current.md`  
**Roadmap:** `combat-tree-opening-choices` (Band 3.7)

## Player outcome

At levels 2, 3 and 4, each earned combat point creates a real build decision. The player may begin
in any of the nine disciplines, take either fundamental after its root, cross into an authored
adjacent hybrid, return for the sibling fundamental, or begin another root. No visible purchasable
node may be an inert promise and the screen may never collapse these choices into **buy next**.

This is the smallest honest early-game slice. “Three points” does **not** mean three selected nodes:
after two legal purchases, every depth-3 development whose same-discipline or hybrid prerequisite is
met can be the third purchase. Therefore the exact reachable set is all **45 nodes at graph depths
1–3**: nine roots, eighteen fundamentals and eighteen developments.

## Exact opening set

| Tree | Roots | Fundamentals | Developments reachable as point 3 |
|---|---|---|---|
| Offense | Heavy Hand; Keen Eye; Quick Step | Follow Through; Overbear; Weak Point; Pry; Light Touch; Quicken | Bracing Stance; Stagger; Steady Hand; Exploit; Second Wind; Flurry |
| Defense | Thick Hide; Bulwark; Footwork | Iron Skin; Brace; Watchful; Draw Off; Light Frame; Sidestep | Constitution; Endurance; Cover; Shieldwall; Slippery; Fall Back |
| Craft | Tainted Edge; Sparkhand; Quiet Step | Apothecary's Hand; Envenom; Insulation; Emanation Strike; Low Profile; Conceal | Virulence; Flense; Attunement; Snuff; Opportunist; Ambush |

The generated graph remains the prerequisite authority. In particular, these authored point-three
hybrids must work without silently requiring the destination root:

- Pry → Bracing Stance or Second Wind; Overbear → Steady Hand;
- Quicken → Exploit; Draw Off → Constitution or Slippery;
- Brace or Sidestep → Cover;
- Emanation Strike → Virulence or Opportunist;
- Envenom or Conceal → Attunement.

Left and right disciplines never jump directly across the centre.

## Temporary early-build boundary

Aimee is the sole player during this implementation phase. Depths 4–5 may remain visible in the
accepted full-tree geometry so the shape is truthful, but until their consumers land they are
explicitly non-purchasable development-build content. They must not consume points, claim a level or
gear prerequisite, or pretend their effect works. This is temporary diagnostic honesty, not final
game progression or tutorial copy.

The next implementation band must arrive before ordinary play reaches its fourth spendable point.
Final promotion removes every implementation hold; the shipped game cannot expose a node as
unavailable merely because its consumer was unfinished.

## Purchase and persistence contract

- One purchase targets one stable node ID and spends exactly one durable unspent point atomically.
- Legal purchase means: node is in the currently implemented set; exact normal or authored hybrid
  prerequisite is owned; any typed selection required by the node is supplied; one point exists.
- Current equipment affects **Works now** copy, never whether a node may be learned.
- Cancel, stale detail, missing point, illegal parent, unavailable consumer and invalid typed choice
  change nothing and leave a concise reason.
- Ownership, selections and unspent points survive relaunch, save-slot switching, party changes and
  expedition boundaries.
- Migration translates legacy investment only through the settled stable-ID migration. Any node
  that cannot be resolved refunds its point; it is never replaced by a nearby-looking node.
- Companion calling-lean nodes remain authored bonus ownership and do not consume the person's
  level-earned flexible points.

## Functional release gate

The opening checkpoint is not complete when 45 JSON records parse. Every one needs one shared
preview/commit consumer and a stable-ID counterfactual proving the same action differs when that
exact node is absent. Existing legacy mechanics may be adapted; parallel replacement engines are
not required.

Required scenario matrix:

1. all 45 nodes are classified as implemented by executable consumer coverage;
2. all nine roots have a useful ordinary opening scenario, including no-weapon/off-kind disclosure
   for Heavy Hand, Keen Eye, Tainted Edge and Sparkhand;
3. both fundamentals after every root can be purchased independently and create different play;
4. every listed hybrid can be the legal third purchase and the same destination is illegal without
   either of its exact parents;
5. every active technique has exact target, action/turn cost, cooldown/charges and relaunch state;
6. every passive changes its real field, encounter, combat, item or survival consumer—not only a
   derived-stat/debug structure;
7. preview and committed resolution use the same authority and show exact node provenance in DEBUG;
8. three-point spending, banking, respec, save/reload and legacy migration conserve points exactly;
9. on a 368×800 phone the player can see the three roots, follow connectors, inspect a node and
   purchase without the graph becoming three vertical lists or requiring a tutorial overlay;
10. a fresh campaign can reach level 4 and complete at least three materially different builds:
    one focused route, one sibling-fundamental route and one authored hybrid route.

## Playtest evidence

For each of the three phone builds, record the character, owned stable IDs, current gear, level,
unspent points, selected path, one combat/field situation where each purchase mattered, and whether
the alternative felt understandable and tempting. Balance numbers remain tunable; an effect being
unnoticeable, impossible to trigger in ordinary opening play, or dominated in every sampled choice
is a design failure even when its transaction is technically correct.

