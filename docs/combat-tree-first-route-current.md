# First complete combat route — Fortitude

**Status:** Game Design complete; implementation is Band 4.7 and must not pre-empt opening systems  
**Owner:** Game Design owns route selection and balance intent; Engineering owns consumers,
persistence and scenario proof  
**Authority:** `combat-tree-v2-authority.json`, `combat-node-viability-current.md`,
`combat-tree-opening-choices-current.md`

## Decision

The first complete eight-point route is the pure **Defense · Fortitude** route:

```text
Thick Hide
├─ Iron Skin ─ Constitution ─ Ward
└─ Brace ───── Endurance ─── Unyielding
                 \          /
                  Immovable
```

The exact eight owned stable nodes are Thick Hide, Iron Skin, Brace, Constitution, Endurance, Ward,
Unyielding and Immovable. The capstone remains point 8 and level 9 at the earliest for a character
with no authored bonus points.

This does not make Fortitude the recommended or canonical build. It is the first route completed for
campaign testing because it addresses the earliest observed failure—new parties being erased before
their choices matter—without depending on a particular weapon drop, coating, Channelworks attack,
enemy covering or multi-foe composition. It also exercises both passive and active nodes, status
duration, typed harm, low-HP state, a once-per-encounter receipt and the all-kind armour capstone.

## Intended play identity

Fortitude lets one person remain actionable through sustained pressure. It does not taunt foes,
protect the entire party, evade contact, increase damage or make recovery free; those remain
Protection, Evasion, Offense, Craft and preparation identities.

The route should feel like layered survival rather than one enormous health bar:

- **Thick Hide** creates visible expedition HP headroom.
- **Iron Skin** makes ordinary physical attrition smaller.
- **Brace** is a deliberate answer to the next damaging hostile action slot.
- **Constitution** shortens afflictions applied to this exact actor.
- **Endurance** changes the danger curve once this actor reaches half HP.
- **Ward** asks the player to read and choose one disclosed harm kind for two rounds.
- **Unyielding** preserves one action window at 1 HP once per encounter.
- **Immovable** makes equipment/sturdiness/Iron Skin armour relevant against Pierce and emanation
  harm without creating a second armour pool.

## Non-negotiable boundaries

- Endurance reduces final incoming damage by 25% only at half HP or less and still respects the
  global minimum; it is not regeneration.
- Brace consumes through the next hostile action slot that actually damages this actor. Misses,
  zero-harm setup, ally hits and friendly effects do not waste it; a qualifying multi-hit slot is
  one event, not one charge per packet.
- Constitution halves remaining Burn, Poison, Dazzle and Bleed rounds when applied, rounded up. It
  changes duration once, not tick magnitude, and cannot repeatedly halve on reload/refresh.
- Ward requires an explicit disclosed Heat/Caustic/Light/Crush/Pierce/Slash choice, lasts through
  this round and the next, and reduces matching direct harm by 60%. It does not cure afflictions.
- Unyielding triggers after all normal mitigation on otherwise-pass-out harm, once per encounter;
  it cannot prevent scripted non-combat consequences or revive an already passed-out person.
- Immovable routes Pierce, Heat, Caustic and Light through the same authoritative armour calculation
  as ordinary protected kinds. It does not duplicate equipment, sturdiness, Iron Skin or formation
  contributions and does not make armour apply to affliction ticks unless that tick already uses
  the normal direct-harm path.
- Preview, combat log and committed harm share one breakdown. No screen adds these values again.

## Why not the other first routes

- Force and Precision need reliable matching weapons and foe profiles before a pure route can be
  judged fairly.
- Swiftness depends heavily on complete action-order and multi-action consumers.
- Protection needs a larger stable party and readable foe intent to show its identity.
- Evasion needs enough incoming attacks for probability to be judged without feeling arbitrary.
- Venom and Emanation depend on complete affliction/source composition and preparation/Channelworks
  routes.
- Shadow is a strong next candidate because it supports encounter avoidance, but it spans field,
  opening, concealment and retreat receipts; it should follow the already-settled Scent Mask route
  and visibility/contact acceptance rather than become their substitute.

## Implementation order inside the held checkpoint

Existing source-complete consumers remain preserved. Missing work lands in consumer-shaped slices,
but the production route is not called complete until all eight are functional:

1. verify Thick Hide and Iron Skin against current expedition-health and armour receipts;
2. land Brace and Constitution together only at their shared incoming-affliction boundary;
3. land Endurance through the shared incoming-damage preview/commit calculation;
4. land explicit-choice Ward and once-per-encounter Unyielding receipts;
5. promote Immovable only after every included harm kind uses the same armour breakdown;
6. purchase/migration and true-graph UI expose the full connected route atomically.

## Acceptance

1. A no-lean level-9 character can buy exactly the eight-node pure route with zero points left; no
   node auto-purchases and the capstone is impossible at point 7.
2. Every node has an exact-owner counterfactual in preview and committed combat plus relaunch proof.
3. One controlled physical, Pierce and each emanation hit proves a single armour contribution before
   and after Immovable; status ticks and armour-ignored harm prove exclusions.
4. Brace handles miss, single hit, multi-hit, apex slot, ally target, relaunch and expiry without
   duplicate consumption.
5. Constitution covers all four canonical afflictions, refresh/stronger replacement and old-save
   adoption without repeated halving.
6. Ward covers all six selectable harm kinds, stale selection, refresh/expiry and mixed-kind events.
7. Unyielding covers exact lethal threshold, multi-packet events, once-only state, relaunch and
   already-passed-out exclusion.
8. Recommended level-9 ordinary encounters still threaten the character; Teeming and apex pressure
   can defeat poor decisions. A pure Fortitude character survives measurably longer but does not
   make the party immortal or become mandatory for every composition.
9. Phone play compares pure Fortitude against one three-point Offense/Craft build and one mixed
   Defense build at matched level/gear. Record rounds conscious, HP lost, actions preserved, active
   skill use and whether each purchase was noticed.

