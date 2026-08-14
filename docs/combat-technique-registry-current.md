# Combat-tree technique registry — current

**Status:** implementation-ready Game Design authority for which of the 72 nodes grant an explicit
combat action. Numerical power/cooldown remains rules/content tuning.
**Related authority:** `combat-tree-true-graph-current.md` owns topology;
`combat-node-viability-current.md` owns exact consequences; `combat-action-palette-current.md` owns
selection/target presentation.

The exact 20-entry grant map is materialized as `techniqueIDByNode` in schema-v2
`combat-tree-v2-authority.json`. This table explains target/commit semantics; it is not a second
machine authority. Asset proofs consume the generated authority map rather than maintaining their
own grant dictionary.

## Why this registry is necessary

Graph role does not imply an action. The current generated v2 content exposes only
`legacyTechniqueID`, omits Blur despite its explicit player-triggered effect, and retains the stale
Quench→`steady` and Emanation Strike→`elemental_strike` mappings. A capstone flag, effect kind or
legacy payload cannot be used to decide whether a tile belongs in the action palette.

Exactly these **20** stable nodes grant a technique:

| Stable node suffix | Stable `TechniqueID` | Target | Required parameter | Commit form |
|---|---|---|---|---|
| `offense.force.overbear` | `overbear` | one legal foe | none | action |
| `offense.force.shatter` | `shatter` | one legal foe | none | action |
| `offense.precision.pry` | `pry` | one legal foe | none | action |
| `offense.precision.finish` | `finish` | one legal foe | none | action |
| `offense.swiftness.quicken` | `quicken` | self | none | zero-turn at fresh scheduled turn; two normal actions now, skip next scheduled turn |
| `offense.swiftness.first_strike` | `first_strike` | one legal foe | none | normal-cost action; first normal-cost encounter action only |
| `offense.swiftness.blur` | `blur` | self | none | zero-turn; once per encounter |
| `defense.fortitude.brace` | `brace` | self | none | action |
| `defense.fortitude.ward` | `ward` | self | harm kind | action |
| `defense.protection.draw_off` | `draw_off` | one legal foe | none | action |
| `defense.protection.interpose` | `interpose` | self | none | action |
| `defense.evasion.sidestep` | `sidestep` | self | none | action |
| `defense.evasion.fall_back` | `fall_back` | self | legal different rank | zero-turn, then ordinary action |
| `craft.venom.envenom` | `envenom` | self | none | action |
| `craft.venom.flense` | `flense` | one legal foe | none | action |
| `craft.emanation.emanation_strike` | `emanation_strike` | one legal foe | Heat/Caustic/Light | action |
| `craft.emanation.snuff` | `snuff` | one legal emanating foe | none | action |
| `craft.emanation.quench` | `quench` | one conscious ally/self with eligible condition | exact burn/poison/dazzle instance | action |
| `craft.shadow.conceal` | `conceal` | self | none | action |
| `craft.shadow.ambush` | `ambush` | one legal foe | none | zero-turn shared opening opportunity |

All other nodes are passives, purchase-time durable choices, rule modifiers or conditional automatic
receipts. In particular:

- Vanish modifies the ordinary retreat command; it is not a second retreat technique tile.
- Insulation and Emanant make a durable Heat/Caustic/Light choice when purchased; they are not combat
  actions.
- Unyielding, Ghost and other once-per-encounter passives trigger automatically and expose their
  unspent/spent state without asking the player to press them.
- Breaking Blow, Killing Stroke and similar capstones remain passive merely because Blur is active;
  capstone role never decides interaction kind.

## Consumer completion audit — 11 August 2026

The grant map is final, but grant identity and gameplay-consumer completion are different gates.
Exactly **19 of 20** granted actions now have implementation-ready semantics in
`combat-tree-v2-consumer-plan-current.md`; **Shatter** remains one explicit Aimee review rather than
an invitation for Engineering to infer behavior.

| Consumer cohort | Techniques | Authority | Readiness |
|---|---|---|---|
| Personal-block scheduler | Overbear, Quicken, First Strike, Blur, Fall Back | Decisions265, 273 | ready after shared scheduler receipt |
| Direct/affliction attacks | Pry, Finish, Flense | Decision274 | ready after direct-hit and canonical-affliction primitives |
| Contradictory attack | Shatter | DRQ-197 | **held:** choose landed Crush hit+armour damage or honest non-damaging debuff |
| Incoming mitigation | Brace, Ward | Decision271 | ready after typed incoming-harm receipt |
| Target intervention | Draw Off, Interpose | Decision264 | ready after one target-intent pipeline |
| Guaranteed avoidance | Sidestep | Decision270 | ready after final-target avoidance receipt |
| Prepared craft actions | Envenom, Emanation Strike | Decision273 | ready after affliction-source merge and typed choice migration |
| Foe suppression / selected cure | Snuff, Quench | Decision271 | ready after scheduled foe-block and canonical-affliction authority |
| Conceal/opening | Conceal, Ambush | Decisions273, 266 | ready after opening and reveal receipts |

This audit does not claim those 19 are implemented in release. Most still adapt legacy behavior that
derives ownership from the old linear tree. It means their outcome, timing, invalid-action behavior,
saved state, preview and test boundary are no longer design-ambiguous.

### Implementation order within combat v2

Do not displace the roadmap's current launch/fresh-balance acceptance or the already-named Thick Hide
next slice. Once combat-v2 work resumes, use dependency order rather than registry/table order:

1. finish actor derivation and frozen ownership, beginning with Thick Hide;
2. land canonical affliction and direct-hit consequence authorities;
3. land the personal-block scheduler, opening classification, targeting and incoming-harm pipelines;
4. attach the 19 ready techniques to those shared consumers in the cohorts above; and
5. attach Shatter only after Aimee chooses DRQ-197, then prove the exact 20/52 palette boundary.

Do not create temporary per-technique clocks or action counters to make a tile appear earlier. That
would have to be replaced by the shared receipts and is therefore out-of-stage work under the current
playability-first policy.

## Identity and migration

The v2 node content must carry an explicit optional `techniqueID`. It is `null` for the other 52
nodes. `legacyTechniqueID` is decode/migration input only and cannot drive runtime palette presence.

- `steady` migrates one way to `quench` for cooldowns, gambits and saved action selection originating
  from the sole Quench source;
- `elemental_strike` migrates one way to `emanation_strike`, including its saved kind preference;
- Blur receives new stable ID `blur`; no legacy ID exists and no ownership is granted unless the
  exact Blur node is owned;
- unknown future technique IDs round-trip but remain unavailable until their definition exists;
- removing/respeccing a granting node removes the derived technique after safely clearing ephemeral
  selection; it does not rewrite completed action logs.

Technique IDs are distinct from node IDs because one identifies an owned graph concept and the other
identifies a committed action. The grant is explicit and one-to-one in this version; code must not
assume it will always remain so.

## Glyph and palette correspondence

An active node and its action-palette tile use the same exact technique pictogram/identity. The graph
adds node state, discipline motif, technique pip and capstone frame around it; the palette adds
ready/cooldown/selected state. Neither redraws the central action into a different symbol. Passive
nodes retain their node glyph and never acquire an action tile.

## Validation gates

1. Exact set comparison reports 20 non-null grants and 52 null grants; no unknown/duplicate
   `TechniqueID` exists.
2. Every grant has a catalogue definition, rules consumer, target preview and scenario test; every
   catalogue tree technique has exactly one granting node.
3. Blur appears for a Blur owner, is absent otherwise, commits once per encounter at zero turn and
   shares the action-expansion exclusion with Quicken.
4. Quench and Emanation Strike expose only their corrected stable IDs after migration.
5. Vanish never appears as a duplicate retreat tile and modifies only the confirmed ordinary retreat
   transaction.
6. Graph, action palette, gambit editor, battle log and VoiceOver resolve the same stable technique
   name/glyph/target kind.
7. Respec and save/relaunch cannot leave an orphan selected action, duplicate cooldown or technique
   without its granting node.
