# Engineering questions for Aimee

**Purpose:** a short running list of choices discovered during implementation. Engineering may use
a deliberately reversible placeholder where waiting would block progress. A placeholder is not a
design decision; it remains here until Aimee or the game-design lead resolves it.

## Open / temporarily implemented

### EQ33 — Simplify three inert-prone reforge ranks to one honest improvement?

- **Audit finding:** Live reforging adds 0.2 effective power three times. Because weapons multiply by
  2 and round final attack once, the three purchases change attack by 0, +1 and +1 relative to rank
  0; the first and third purchases can do nothing. Protective ranks have the same boundary problem.
- **Game Design recommendation:** Replace the meter with one +0.5 within-tier Reforge using the
  current first-step price (2 qualifying samples at 30+, 8 Essence). Preserve existing rank 1/2/3
  as exact frozen +0.2/+0.4/+0.6 paid power; do not fold it into Legacy-masterwork credit.
- **Why:** One meaningful retained-object improvement is clearer and less chore-like than inventing
  secondary mechanics to justify three pips. It remains below the next construction tier.
- **Review:** Aimee approves, revises or rejects the simplification before native migration.
  Authority: `reforge-progression-audit-current.md` / DRQ-065.

### EQ31 — Noll exact prose and Field Separation Kit

- **Playtest promotion:** Game Design has approved Noll/`noll`, they/them, Salvager, authored order 2,
  story-arrival band 0, the two-condition signature, Recycler ownership and the
  15-Essence/no-resource comparison cost as reversible playtest content. Current stable-ID
  meeting/diary units may ship labelled Provisional in the DEBUG Atlas so the Recycler owner is no
  longer blocked on final-copy review.
- **Still open:** Aimee's exact prose selections and whether `field_separation_kit` is worth a packed
  slot, turn and confirmation interaction.
- **Boundary:** Do not grant or expose the Field Separation Kit. Later prose revision preserves
  stable exchange/page IDs and cannot undo earned recruitment or Recycler state.
- **Status:** Nonblocking review after native Noll promotion; `noll-opening-review-packet-current.md`.

### EQ27 — Binder appearance and Quill authored identity

- **Settled safety boundary:** Binder, Quill, named travellers and generated people are distinct
  persisted visual-origin cases. The accepted 28 named travellers are not being reopened, and no
  missing case may borrow another person's sprite or reroll from roster/world state.
- **Design recommendation:** New Game includes a compact, non-stat Binder appearance chooser built
  from bounded authored body/hair/garment/palette/accent options. Quill receives one fixed authored
  descriptor reviewed against the entire Binder range, named cast and generated combinations.
- **Questions for regular review:** Should Binder appearance be editable later at Base, or final at
  campaign creation? What exact authored Quill descriptor should Asset promote?
- **Nonblocking placeholder:** Persist the closed identity union first; keep the existing structured
  fallback/diagnostic for Binder and Quill until their content is reviewed. Never use the proof-only
  Binder template as a canonical default.
- **Status:** Schema and migration are implementation-ready in
  `binder-quill-generated-visual-identity-current.md`; exact visual content remains reviewable.

### EQ24 — Color vocabulary and acquisition

- **Settled direction:** Rough charcoal is the starting medium. Brush/Fountain marks use Ash by
  default; both charcoal and Ash mean color unspecified and resolve randomly at bind. Deliberate
  colored ink is an optional CMY+Depth recipe attached
  to a source mark, not another rune or collectible qualifier. Flora and Creature remain separate
  technical scopes.
- **Progression owner:** Isolde's Scriptorium replaces Pencil with **Brush**. **Ink Mixing** is a
  direct adjacent tier-1 node requiring Brush; it permanently exposes the Ink well and saved
  mixtures at the Writing Desk. Fountain pen remains the final hand.
- **Implementation recommendation:** Begin with the closed Sun/Smoke/Granite/Bloom allowlist. Store
  exact recipes and conversion versions; distinguish nil/open from explicit mixed black. Prepared
  vials use the current resource-derived base/application contract.
- **Temporary proof choice:** AssetLab may retain named swatches as accessibility/gamut fixtures,
  but they are not shipped vocabulary or acquisition authority.
- **Status:** Ownership and semantics are current; exact upgrade cost and conversion coefficients
  remain playtest/open tuning.

### EQ22 — Legacy gear power during specialist-shop migration

- **Design-lead placeholder:** Convert `catalogue tier + old upgradeLevel` into construction tier up
  to 4; preserve any excess as visible non-growing Legacy masterwork credit. New reforges are rank
  0–3 at 0.2 power each and never raise construction tier.
- **Reason:** This preserves every paid old upgrade without preserving the Blacksmith's ability to
  bypass Armoury, Bowyer and Weaponsmith tiers for future items.
- **Temporary implementation:** Safe only with the lossless stored/equipped profile and migration
  fixtures in `crafted-gear-migration-current.md`. Do not fabricate old material provenance.
- **Review:** Compare legacy pieces, three new reforges and specialist rebuild warnings in combat/UI.
- **Status:** Reversible migration placeholder under DRQ-110.

### EQ21 — Waystone's repeatable rare material

- **Design-lead placeholder:** Replace the Waystone's one Adamant with one Rift-glass. Retain its one
  hardness-70 world resource, one Mote, 30 essence and immediate full-haul return effect.
- **Reason:** Rift-glass expresses crossing an unstable boundary, while Adamant already gates eight
  units of permanent late analysis progression and made the safety item unusually hoardable.
- **Temporary implementation:** Safe to implement as tuning data. This does not create generic Glass
  or assign Glass, Quartz or Rift-glass to Tam.
- **Review:** Compare Waystone crafting/use against Rift-glass availability after both loops are
  playable; restore or retune only through an explicit disposition.
- **Status:** Reversible playtest placeholder under DRQ-026.

### EQ20 — Random versus chosen failure recovery

- **Settled safety boundary:** Only net-new unbanked haul is at risk. Unused pre-departure field-kit
  items must return in full; current whole-inventory random retention is a bug.
- **Design-lead recommendation for review:** Compare current saved-RNG random item retention against
  a Base-side “What did you hold onto?” choice using the same 50% budget.
- **Temporary implementation:** Keep deterministic random selection after partitioning acquired
  items correctly; add explicit Recovered/Lost summary sections. See
  `expedition-outcomes-current.md`.
- **Status:** Safety fix is not optional; agency model and 50% rate remain review/playtest questions.

### EQ19 — Final 23-focus expansion

- **Design-lead recommendation:** Use the exact 62→85 cut in `focus-expansion-85-current.md`, with
  metadata and fixtures per batch. Use **Chill**, not the older Frost proposal, for hydrology-free
  cold.
- **Question after content play:** Do the additions fill ordinary expressive gaps without making the
  palette noisy or weakening discovery?
- **Temporary implementation:** Implement in acquisition bands; signs/purposes are current,
  magnitudes reversible. Glass remains outside this generic batch.
- **Status:** Review naming and distribution as batches land; not a blocker for current traveller work.

### EQ18 — New-station build bundles

- **Design-lead placeholder:** Use the keeper/cost/tier matrix in
  `station-integration-matrix-current.md`; all new bundles are debug-tunable and every station has one
  useful tier-0 action.
- **Question after play:** Are the mid/late construction costs several purposeful hauls without
  making recruitment feel like receiving a bill?
- **Temporary implementation:** Safe to use reversibly. Oda's single carried Heat Conduit resolves
  her pre-Auber dependency.
- **Status:** Review across the full station rollout.

### EQ17 — Deep-site frequency and bracing

- **Design-lead placeholder:** One Buried seam appears in 20% of eligible hard/relieved worlds with
  3–5 finite safe pulls. One brace may convert one support unit using hard/flexible world resources
  plus 10 essence, but must leave support behind.
- **Question after play:** Is the site rare enough to feel like deliberate late depth while common
  enough for Grimmond's station to matter?
- **Temporary implementation:** Safe to tune reversibly; no underground map or cave-in chance. See
  `deep-works-system-current.md`.
- **Status:** Review with Grimmond and repeated anchored-world visits.

### EQ16 — Distillery cost and potency

- **Design-lead placeholder:** A blank crystal costs 40 essence + 2 Quartz. Attunement costs 15
  essence, a named bulk catalyst and one qualifying provenanced world resource; potency is 70% sample
  grade + 30% relevant property.
- **Question after play:** Do cores remain valuable finite choices without making Channelworks too
  expensive to retune?
- **Temporary implementation:** Safe to tune reversibly. Infusion remains unimplemented, not a
  placeholder button. See `distillery-system-current.md`.
- **Status:** Review with the first Heat Conduit fixture.

### EQ15 — Animal trust cadence and Menagerie capacity

- **Design-lead placeholder:** Attend reveals one deterministic want. Patient presence takes two
  turns; a reachable property offering is the only alternate. The Menagerie has no hard cap.
- **Question after play:** Is two-condition variety enough, and does a long animal list need only
  grouping/search or a meaningful capacity rule?
- **Temporary implementation:** Safe to build reversibly; do not add capture odds, breeding or a
  kennel tax. See `animal-taming-menagerie-current.md`.
- **Status:** Review once Sabine and mixed parties are playable.

### EQ14 — Anchored-realm production cadence

- **Design-lead placeholder:** Worldwork covers sustain first; each four surplus points produces one
  selected discovered renewable unit into a six-unit per-realm delivery tray.
- **Question after play:** Does this make a kept world feel dependable without turning assignment
  into mandatory collection upkeep?
- **Temporary implementation:** Values may be used reversibly; the manifest/source-state structure
  is the important part. See `anchored-realm-production-current.md`.
- **Status:** Review after several staffed realms run across short and long sessions.

### EQ32 — Opening expedition safety

*Renumbered from the accidentally duplicated `EQ13`; the earlier `EQ13` remains the resolved minimap
disclosure decision.*

- **Design-lead recommendation:** Do not create a secretly neutral or weakened tutorial world.
- **Question after fresh-save testing:** Is a visible, debug-tunable opening-campaign encounter
  envelope needed, or does the game's safe partial-haul failure teach the intended loop well enough?
- **Temporary implementation:** None; ordinary generation remains honest. See
  `tutorial-discoverability-current.md`.
- **Status:** Open playtest question, not a current blocker.

### EQ9 — Great Work, Reality reset and Tam

- **Settled boundary:** Rebuilding the Atlas through re-anchored realms is the Great Work; completed
  progress is final and can never be reversed. Engineering should preserve the realm history listed
  in `great-work-boundary-current.md` without showing an ending score.
- **Question for a future dedicated discussion:** What emotional act completes restoration, whether a
  Reality reset still belongs, what makes a realm meaningful to Atlas progress, and only then what
  unique act Tam can perform.
- **Temporary implementation:** None. Do not invent a quota, reset, ending trigger, Tam ability or
  Glass ownership.
- **Status:** Explicit design hold requested by Aimee; does not block ordinary campaign systems.

### EQ7 — First Anchoring balance values

- **Temporary implementation:** Born anchored costs the written book plus the greater of 100
  essence or twice the book cost. Atlas Seam uses `max(10, 25% of born premium)`; Anchor Frames use
  six property-matched samples plus 60 essence. Return settlement, dormancy and explicit
  reactivation are implemented. Sustain is temporarily 10 essence per realm after the first.
- **Review:** The born premium and sustain escalation curve. Route relationships, Atlas Seam's 25%
  rate and saved expedition state follow the current spec.
- **Impact:** Late-game economy and how often a kept realm can be revisited.
- **Status:** Open; model and tuning are deliberately reversible.

### EQ4 — Lure targeting

- **Temporary implementation:** Using a Lure wakes the nearest non-sessile, non-apex creature and
  the ordinary end-of-turn movement draws it one step toward the party. It does not create a new
  creature, teleport one, or override apex restraint rules.
- **Review:** Whether a later version should choose a known species or target tile. This is local
  and reversible; current behavior implements “draws a creature to you” without new UI.

### EQ11 — Kestrel's “unrecorded species” timing

- **Temporary implementation:** A foe qualifies when its species was absent from the bestiary at
  the beginning of the current encounter. The snapshot lasts for that fight, because encounter
  setup currently records the species and specimen before the first gambit can evaluate.
- **Review:** Whether a later bestiary should distinguish sighting, partial observation and a
  separately completed record. If so, Kestrel should read that explicit completion state instead.
- **Impact:** Her teaching works on a species' first encounter without redefining existing bestiary
  saves or making the subject impossible to trigger.
- **Status:** Open, reversible save-tolerant placeholder.

### EQ12 — Marrick thermal-range clue tuning

- **Temporary implementation:** Thermal range ≤10 rather than the authored placeholder ≤25.
- **Reason:** At 25 the condition holds in 88% of generated-world fixtures, exceeding the existing
  85% maximum for an informative individual clue; 20 preserves the settled steady-temperature
  direction and prose. A first trial at ≤20 still matched 87.25%.
- **Review:** Revisit with broader playtest telemetry; this is magnitude tuning only.
- **Status:** Open, reversible playtest value.

## Resolved

Move entries here with the deciding source and date; preserve the temporary choice so later audits
can distinguish an intentional migration from an accidental behavior change.

### EQ23 — Station ordering authority

- **Resolved/built by 11 Aug 2026:** Native station definitions author `homeSection` plus unique
  `sectionOrder`; Base presents Home/Make/Study/Realms through deterministic grid ordering and
  foundation/built states. Array-shuffle and unique-position tests are live.
- **Party boundary:** A hidden `party` station row remains in the compatibility map at Home 2 but is
  filtered from destinations; Party appears exactly once in the persistent bottom utility. Visible
  Home therefore need not use contiguous encoded order values.
- **Expansion:** Recycler uses Make 1 between Trading Post/Blacksmith; Menagerie Realms 1 and Deep
  Works Realms 2. Adding a row cannot reveal it before legitimate foundation/unlock state.
- **Legacy `sortOrder`:** compatibility only; no presentation may read its duplicated values.
  Authority: `base-destination-board-current.md` / DRQ-142.

### EQ2 — Traveller's Token placement rule

- **Resolved 11 Aug 2026 by Game Design Lead / Decision 189:** Cut Traveller's Token. A complete
  signature already enters the one-person story-band selector; biasing an incomplete signature or
  placing somebody in a nonmatching world would falsify recovered clues.
- **Boundary:** Current consumable catalogue remains seventeen; legacy item IDs may decode only and
  no recipe, stock, reward or UI may expose the Token. Scent Mask remains independently justified.
  Authority: `travellers-token-audit-current.md` and `quirk-pattern-audit-current.md`.

### EQ13 — Minimap writing disclosure

- **Resolved 9 Aug 2026 by Aimee:** Every POI—including writing, sites, resources/items,
  travellers, encounters, apexes and portals—is fog/discovery-gated by default. Only an explicit
  invested skill/station/consumable may reveal bounded information early.
- **Historical behavior:** type-based portal/page/apex exceptions leaked through fog. They remain
  rejected. Authority: `minimap-disclosure-current.md` / DRQ-106.

### EQ29 — Universal baseline combat skills

- **Resolved 11 Aug 2026 by Game Design Lead / Decision 185:** Remove the universal four-technique
  grant. Binder owns Unbind/Sight; Quill owns Mend/Read; Ashe owns Ground; exact graph nodes,
  instruments/items and future authored-person sources grant everything else.
- **Consequence accepted for reversible playtesting:** A Quill-free expedition may have no renewable
  Mend. Departure/Party preview states that fact and carried healing uses; the system must not hide
  it by cloning Quill's identity across the party.
- **Migration:** Generic people gain no private replacement; obsolete catalogue owner strings and
  the temporary baseline allowlist become decode/compatibility only. Authority:
  `combat-v2-review-batch-current.md` and `combat-baseline-technique-ownership-review-current.md`.

### EQ28 — Unbind damage versus Unbind retreat

- **Resolved 11 Aug 2026 by Game Design Lead / Decision 185:** Keep **Unbind** for the Binder's
  signature damage action. Ordinary retreat is **Withdraw**. Vanish modifies one confirmed Withdraw
  per expedition; legacy Rout is decode-only and grants no turn/action.
- **Boundary:** Never present two actions called Unbind and never preserve Rout as a duplicate escape
  technique merely for migration convenience. Authority:
  `combat-unbind-retreat-name-collision-review-current.md`.

### EQ26 — Essence refining station ownership

- **Resolved 11 Aug 2026 by Game Design Lead / Decision 186:** All player-facing Raw Essence
  refinement moves to the Essence Spring. Workshop retains writing/research infrastructure;
  Auber's Distillery retains crystals/attunement and never owns Raw conversion.
- **Reversible progression:** free selected/all 2:1 baseline; Second pass at 50 lifetime Raw refined
  + 80 Essence/10 Quartz changes future conversion to 3:1; Continuous settling follows at Spring
  tier 1 for 120 Essence/12 Quartz/8 Pulp and auto-refines only newly retained Raw once per outcome;
  Deepen remains parallel.
- **Migration:** existing balances and completed Deepen state persist; no past conversion is
  recomputed. Authority: `essence-spring-review-batch-current.md` and
  `essence-refining-progression-current.md`.

### EQ30 — Colored-ink processing interaction

- **Resolved 11 Aug 2026 by Game Design Lead / Decision 164:** First native Ink Mixing uses one
  atomic just-in-time vial transaction. Preview existing CMY+Depth measures plus exact
  Copper/Ichor/Sulfur/Obsidian and Resin shortfall; confirmation processes only the minimum whole
  source units, spends exact measures, retains excess and creates the 12-application vial.
- **No separate ordinary process-pigment action or second screen.** Formula choice and limited use
  are the decisions; deterministic conversion is accounting.
- **Reversible boundary:** Persist station-local base measures so explicit batching can return only
  if play demonstrates a meaningful timing/quantity choice. DRQ-156 is later feel review, not an
  implementation blocker. Authority: `ink-economy-friction-audit-current.md` and
  `authored-color-vocabulary-current.md`.

### EQ25 — Uneven-party combat level reference

- **Resolved 11 Aug 2026 by Game Design Lead:** Replace upper median in newly bound Recommended runs
  with the additive Binder-anchored party-power budget in `encounter-scaling-playtest-current.md`.
  Each companion contributes `clamp(0.5 × 1.09^(level-anchor), 0.25, 1.5)` to a total capped at 3.
  Equal-level parties preserve 1/1.5/2/2.5/3; adding any member cannot lower pressure; apex
  durability/offence read the same budget while action slots continue to read party count.
- **Historical placeholder:** Upper median was retained only long enough to expose its odd-party
  discontinuity. Maximum level was rejected because it makes low-level allies liabilities.

### EQ10 — Armour thresholds in gambit grammar

- **Resolved 9 Aug 2026 by Game Design Lead:** Armour uses typed absolute marks, initially 1/3/5;
  existing percentages remain HP fractions and cannot be paired with Talin's subject. Talin retains
  `subject_foe_armour_above`, which fixes current armour + above while leaving action and priority
  player-authored. See `gambit-stat-thresholds-current.md`; values remain playtest tuning.

### EQ8 — Anchored-realm production aptitude

- **Resolved 9 Aug 2026 by Game Design Lead:** Companions have visible authored `worldwork` 0–3,
  defaulting to 1 for old saves and generated companions. Contribution is
  `1 + worldwork + floor((level - 1) / 5)`. Implemented-six ratings are Mara 2, Edren 2,
  Halloway 2, Isolde 1, Sela 3 and Tovin 3. See `companion-worldwork-current.md`.

### EQ5 — Campaign phases for the implemented six

- **Superseded later 9 Aug 2026 by Aimee:** current order begins Vance 1, Noll 2, Halloway 3,
  Mara 4, Edren 5; see `opening-economy-traveller-reorder-current.md`. Historical resolution was 1 Mara `opening`, 2 Edren `opening`, 3 Halloway
  `opening`, 4 Isolde `startOfMid`, 5 Sela `mid`; Tovin is global authored order **26**, `late`.
  The earlier “sixth of the implemented set” wording was relative, not a global order. `startOfMid`
  remains distinct because Isolde opens hand progression before Sela's expanded-page midgame hunt.
  See DRQ-014, decision 43 and `roster-progression-current.md`.

### EQ6 — Mechanical profiles for implemented-six diary focuses

- **Resolved 9 Aug 2026 by Game Design Lead:** Use the directional profiles in
  `diary-focus-mechanical-profiles-current.md`. Scarp, Ruin, Gold ore, Hush and Pond now use live
  pressure targets; Ruin does not create a Strange target or guarantee a site. Drift retains its
  existing profile and moves from research to Tovin's diary. Exact magnitudes remain playtest tuning.

### EQ1 — Four coatings, three live statuses

- **Resolved 9 Aug 2026 by Game Design Lead:** Keep the narrow taxonomy. Venom applies poison,
  Firebrand burn, placeholder Briar Oil legacy bleed, and placeholder Flashsalt dazzle. Do not add
  freeze or shock. Names and ingredients remain reviewable placeholders. See DRQ-002 and
  `decisions-session-18.md`.

### EQ3 — Unspent Stonebark between encounters

- **Resolved 9 Aug 2026 by Game Design Lead:** Stonebark is encounter-scoped. It blocks exactly the
  next attempted affliction, including bleed; attack damage still lands. If untriggered, it expires
  when combat ends and never carries into another encounter. Existing encounter-state behavior
  already matches. See resolved DRQ-003.
