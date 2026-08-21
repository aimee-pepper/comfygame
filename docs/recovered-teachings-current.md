# Recovered teachings — current authority

**Status:** Game Design implementation authority for replacing the Workshop's Instruction, Hand, Lexicon
and Bargain knowledge purchases. The catalogue below is complete; the six-star Constellation decision and
capacity-upgrade compression remain separate decisions.
**Priority:** implement only at the roadmap's Workshop-removal checkpoint. This does not pre-empt opening
combat scaling, the corrected Game Wiki, Starter World Pages or current native presentation work.
**Updated:** 21 August 2026

Validation: `python3 scripts/validate_recovered_teachings.py`.

## 1. Player rule

Knowledge comes from something attributable. A recovered teaching is a field instruction, warning, rubbing
or observation record found in a world. Collecting it permanently records the physical teaching immediately,
even if the expedition later collapses. It occupies no item or resource slot. Its unread object appears on
the Library's appropriate shelf; opening it once teaches the exact rune, focus, Gambit component or advanced
instruction and clears attention. Reading costs no Essence and no world turn.

The Library preserves and explains the teaching; it does not invent or sell it. Party may use already-known
Gambits but never teaches them. Seeing an unknown glyph on a collected World Page still records `??` only and
does not bypass this system.

## 2. Stable record and transaction

Persist one `RecoveredTeachingRecord`:

- `teachingID` and `catalogueVersion`;
- exact `rewardKind` and `rewardID`;
- `recoveredAtOutcomeID`, world seed and source placement identity;
- `recoveredAt` and optional later `readAt` timestamps/order counters;
- frozen title and instruction copy for history;
- `isRead`, derived only from whether the exact teaching receipt has been applied.

The collect transaction first inserts the idempotent record, then removes the world object. Reading applies
the exact reward and marks that record read atomically. A duplicate record or already-known reward is a
harmless no-op which still clears unread attention. Decode never reapplies a reward merely because a record
exists.

## 3. Availability bands

| Band ID | Exact campaign eligibility |
|---|---|
| `opening` | at least one resolved expedition |
| `developing` | Binder level at least 4 **and** at least three resolved expeditions |
| `later` | Binder level at least 8 **and** at least eight resolved expeditions |

An encountered phenomenon may enter Reality/Dictionary as `??` before its teaching band opens. The band
limits the teaching, not honest observation.

## 4. One independent teaching opportunity per world

Recovered teachings are an **additional** writing opportunity. They never replace or reduce the guaranteed
ordinary writing, Diary Page, collected World Page, traveller, site reward or field note already selected for
that world.

After final world generation:

1. Build candidates whose band is open, reward is unknown and evidence query is true in the frozen world.
2. Track `eligibleWorldsWithoutOffer` independently per teaching. A candidate has a deterministic 45% offer
   chance on its first and second eligible worlds and becomes due on its third.
3. Offer at most one teaching. Select due candidates first; then the smallest `firstEligibleOutcomeIndex`;
   then catalogue order; use world seed only as the final tie-breaker.
4. If an offered teaching is not collected, keep it due so the next eligible world offers it again. Collection
   removes it from all future candidate pools even before the player reads it.
5. A resolved expedition with no candidate does not advance any counter. Collapse after collection cannot
   undo recovery. Collapse or portal exit without collection advances an offered candidate to due.

This is intentionally a chance-and-pity system, not one guaranteed new lesson every world. It prevents a
late-game influx while ensuring an observed eligible concept cannot disappear indefinitely.

## 5. Placement classes

| Placement ID | Exact placement rule |
|---|---|
| `field_instruction` | A revealed-by-exploration writing object on a passable tile, path distance 6–18 from entry, reachable without entering a hazard, site, creature or traveller tile. |
| `local_observation` | Same, but path distance 1–4 from a visible local manifestation of the named source. If the source is world-global and has no legal manifestation tile, fall back to `field_instruction`. |
| `warning_note` | A safe passable tile path distance 2–4 from the nearest matching hazard/hostile manifestation; the route from entry to the note may not cross that manifestation. |
| `site_rubbing` | An authored reward inside the named searched site. The site transaction owns it; ordinary world placement and pity do not duplicate it. |
| `quiet_counterexample` | A safe passable tile in a world whose frozen source receipt contains `peace`; otherwise ineligible. |

All five render as writing, disclose no unrevealed POI on the minimap and use the ordinary writing collection
interaction. The object label is `A field instruction`, `An observation`, `A warning`, or `A rubbing` until
collected; it never prints its unknown reward ID on the map.

## 6. Gambit and advanced-instruction catalogue

These entries use `field_instruction`. Their evidence query is simply the open band; they do not require a
matching combat event. The copy is intentionally direct instructional prose, not a riddle or character voice.

| Order | Teaching ID | Band | Reward | Title | Frozen instruction copy |
|---:|---|---|---|---|---|
| 1 | `teaching.gambit.subject_self` | opening | Gambit `subject_self` | Check yourself | “Put SELF first when the rule needs to check the person following it.” |
| 2 | `teaching.gambit.act_flee` | opening | Gambit `act_flee` | Leave the fight | “FLEE tells the person following the rule to break away when its conditions are true.” |
| 3 | `teaching.gambit.act_skill` | opening | Gambit `act_skill` | Use your skill | “SKILL uses that person's equipped combat skill when it is ready. The rest of the rule decides when.” |
| 4 | `teaching.gambit.thr_30` | developing | Gambit `thr_30` | Mark thirty percent | “THIRTY PERCENT makes a health condition wait until only three parts in ten remain.” |
| 5 | `teaching.gambit.thr_70` | developing | Gambit `thr_70` | Mark seventy percent | “SEVENTY PERCENT lets a health condition act before the target is badly hurt.” |
| 6 | `teaching.gambit.cmp_above` | developing | Gambit `cmp_above` | Read above the mark | “ABOVE makes the condition true when the measured value is greater than its chosen mark.” |
| 7 | `teaching.gambit.thr_10` | later | Gambit `thr_10` | Mark ten percent | “TEN PERCENT is the last health mark. Use it only when the rule should wait for an emergency.” |
| 8 | `teaching.gambit.subject_foe_lowest` | later | Gambit `subject_foe_lowest` | Choose the weakest foe | “FOE: LOWEST HP evaluates the living enemy with the least health remaining.” |
| 9 | `teaching.gambit.subject_foe_highest` | later | Gambit `subject_foe_highest` | Choose the strongest foe | “FOE: HIGHEST HP evaluates the living enemy with the most health remaining.” |
| 10 | `teaching.instruction.automate_self` | later | capability `automate_self` | Let your own rules run | “This instruction lets the Binder follow their prepared Gambit rules. Turning it on does not change or add any rule.” |

The three entries within a band share the global opportunity algorithm; they do not arrive as a batch. The
advanced `automate_self` entry becomes eligible only after all three opening Gambit teachings are known.
The two removed paid `+1 Gambit slot` nodes have no recovered-teaching replacements: personal Wit remains
ordinary capacity and The Long Instruction remains the one campaign-wide Constellation option.

## 7. Focus catalogue

For every focus entry, the evidence query is exact:
`world.frozenGeneratedPressureSourceIDs contains rewardID`. This receipt includes authored, World Page and
undefined/random sources but is never shown to the player as a semantic preview. Placement is
`local_observation` beside a legitimate visible manifestation where one exists.

| Order | Teaching ID | Band | Reward | Title | Frozen instruction copy |
|---:|---|---|---|---|---|
| 11 | `teaching.focus.stars` | opening | focus `stars` | Starlight | “Stars are a faint source of illumination. Write STARS when you want them to contribute light.” |
| 12 | `teaching.focus.mist` | opening | focus `mist` | Mist | “Mist adds suspended water to the atmosphere and softens distance. Write MIST to ask for that air.” |
| 13 | `teaching.focus.river` | opening | focus `river` | River | “A river is connected moving surface water. Write RIVER when the water should travel across the land.” |
| 14 | `teaching.focus.salt` | opening | focus `salt` | Salt | “Salt remains when water withdraws and changes what can grow. Write SALT to add that substrate source.” |
| 15 | `teaching.focus.silt` | opening | focus `silt` | Silt | “Silt is fine ground carried and sorted by water. Write SILT to add it to the world's substrate.” |
| 16 | `teaching.focus.fungus` | opening | focus `fungus` | Fungus | “Fungus is growth that does not need ordinary light. Write FUNGUS to add that kind of vitality.” |
| 17 | `teaching.focus.marsh` | developing | focus `marsh` | Marsh | “A marsh is saturated ground between land and standing water. Write MARSH to spread that hydrology.” |
| 18 | `teaching.focus.geyser` | developing | focus `geyser` | Geyser | “A geyser brings hot water from below. Write GEYSER when hydrology and heat should rise together.” |
| 19 | `teaching.focus.thin_air` | developing | focus `thin_air` | Thin air | “Thin air reduces the world's atmosphere. No other focus lowers that subject in the same way.” |
| 20 | `teaching.focus.wildfire` | developing | focus `wildfire` | Wildfire | “Wildfire is active landscape fire. Write WILDFIRE to add strong heat and the damage it causes to growth.” |
| 21 | `teaching.focus.rot` | developing | focus `rot` | Rot | “Rot is vitality breaking down after growth. Write ROT when decay should become part of the living world.” |
| 22 | `teaching.focus.tide` | developing | focus `tide` | Tide | “A tide makes water rise and withdraw in a repeating pull. Write TIDE to add that cycle to hydrology.” |
| 23 | `teaching.focus.crystal` | developing | focus `crystal` | Crystal | “Crystal is ordered mineral growth that can carry light through stone. Write CRYSTAL for that substrate and illumination source.” |
| 24 | `teaching.focus.volcano` | later | focus `volcano` | Volcano | “A volcano is relief built by moving hot rock. Write VOLCANO to raise that pressure in the land.” |
| 25 | `teaching.focus.magma` | later | focus `magma` | Magma | “Magma is molten stone beneath or across the surface. Write MAGMA to add intense thermal pressure.” |
| 26 | `teaching.focus.sulfur` | later | focus `sulfur` | Sulfur | “Sulfur is a reactive yellow mineral associated with vents. Write SULFUR to add it to the substrate.” |
| 27 | `teaching.focus.swarm` | later | focus `swarm` | Swarming life | “SWARM describes many small living things as a vitality source. It is not the Swarm danger rune.” |
| 28 | `teaching.focus.miasma` | later | focus `miasma` | Foul air | “MIASMA describes foul airborne matter as an atmosphere source. It is not the Miasma danger rune.” |
| 29 | `teaching.focus.orrery` | later | focus `orrery` | Orrery | “An orrery is a built mechanism that imposes a repeating celestial cycle. Write ORRERY to add that clockwork source.” |

Focuses registered as traveller Diary teachings in `diary-teaching-registry-current.md` never enter this
catalogue or its pity pool.

## 8. Danger-rune catalogue

Danger teachings use `warning_note`; the exact evidence query may be satisfied by the named composite source
or by its actual live hazard result. Copy says what the rune asks for without concealing the cost.

| Order | Teaching ID | Band | Reward | Exact evidence query | Title | Frozen instruction copy |
|---:|---|---|---|---|---|---|
| 30 | `teaching.symbol.swarm_rune` | opening | symbol `swarm_rune` | source `swarm` is Great **or** the world generated a swarm encounter | Ask for a swarm | “The SWARM rune asks for many weaker creatures and makes the world last longer in exchange.” |
| 31 | `teaching.symbol.storm` | opening | symbol `storm` | atmosphere `wind` is Great and hydrology contains rain, **or** a storm hazard exists | Ask for a storm | “The STORM rune adds powerful wind and rain. The dangerous weather buys the world more time.” |
| 32 | `teaching.symbol.predation` | developing | symbol `predation` | trophic depth crosses the live predation threshold **or** an ordinary encounter spawns above its non-predatory band | Ask for predators | “The PREDATION rune produces fewer, stronger animals. Their danger buys the world more time.” |
| 33 | `teaching.symbol.blight` | developing | symbol `blight` | vitality `rot` is Great **or** a blighted/hostile-growth hazard exists | Ask for blight | “The BLIGHT rune adds strong decay and hostile growth. That danger buys the world more time.” |
| 34 | `teaching.symbol.tremor` | developing | symbol `tremor` | a tremor/cracking hazard exists **or** the source receipt contains the exact Tremor composite | Ask for tremors | “The TREMOR rune makes the ground unstable and prone to opening. That danger buys the world more time.” |
| 35 | `teaching.symbol.miasma_rune` | later | symbol `miasma_rune` | atmosphere `miasma` is Great **or** a damaging-air hazard exists | Ask for miasma | “The MIASMA rune makes the air itself harmful. That ongoing danger buys the world more time.” |
| 36 | `teaching.symbol.peace` | later | symbol `peace` | frozen source receipt contains exact composite `peace`; Binder knows at least two of the other six danger runes | Ask for peace | “The PEACE rune suppresses hostility, but the safer world has less time. It reverses the usual danger bargain.” |

`peace` uses `quiet_counterexample`, not `warning_note`. “Buys more time” must be bound to the live stability
effect authority; if a danger rune does not yet implement that bargain, its teaching remains content-held
rather than lying in the UI.

## 9. Hand catalogue

| Order | Teaching ID | Band | Reward | Source | Frozen instruction copy |
|---:|---|---|---|---|---|
| 37 | `teaching.symbol.verdigris_bloom` | developing | symbol `verdigris_bloom` | `site_rubbing` at its existing authored Verdigris site | “VERDIGRIS BLOOM spreads copper-green growth across living ground and metal-rich seams.” |
| 38 | `teaching.symbol.mote_vein` | later | symbol `mote_vein` | `site_rubbing` at the first searched Mote-bearing site after a Mote is legitimately disclosed | “MOTE VEIN asks for buried Motes beside Raw Essence. The page does not promise either will be easy to reach.” |

These site-owned teachings do not consume the independent one-per-world recovered-teaching opportunity and
never appear from generic cache selection.

## 10. Migration

1. Preserve every currently known reward and every completed legacy research ID.
2. Map a completed knowledge node to its exact reward receipt and corresponding teaching record marked read;
   use migration provenance, not a fabricated world seed.
3. Map `automate_self` identically. Preserve the two old Gambit-slot benefits as a frozen legacy slot credit;
   do not turn them into Long Instruction purchases or refund/spend Motes silently.
4. Keep old Workshop node IDs decode-only. New campaigns never display or purchase the four removed branches.
5. If a save has recovered but unread content during a version transition, the recovered record wins and its
   attention remains; decode does not infer reading from unrelated ownership.

## 11. Acceptance gates

1. Exactly 38 primary teaching entries exist: 10 Gambit/instruction, 19 focus, 6 danger, 2 Hand, plus Peace.
2. Every removed knowledge/automation grant has one entry; neither removed ordinary Gambit-slot grant does.
3. No Diary-exclusive focus is present.
4. A teaching never replaces other writing, leaks an unrevealed POI or consumes capacity.
5. First/second eligible worlds use the deterministic 45% offer; the third and subsequent eligible world is
   guaranteed until collection; at most one generic teaching appears in a world.
6. Collection survives collapse and is idempotent; reading is atomic, free and relaunch-safe.
7. All copy names the observable subject and resulting writable term directly. No clue or teaching is a
   sphinx-like riddle.
8. Legacy saves retain every known word, component, automation and slot entitlement.
