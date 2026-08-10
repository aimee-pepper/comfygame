# Engineering questions for Aimee

**Purpose:** a short running list of choices discovered during implementation. Engineering may use
a deliberately reversible placeholder where waiting would block progress. A placeholder is not a
design decision; it remains here until Aimee or the game-design lead resolves it.

## Open / temporarily implemented

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

### EQ13 — Opening expedition safety

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

### EQ2 — Traveller's Token placement rule

- **Design-lead recommendation:** Cut the item. A complete signature already places its unrecruited
  traveller deterministically; placing somebody in a non-matching world would make their diary clues
  dishonest. See `travellers-token-audit-current.md`.
- **Temporary choice:** Continue holding this one item; the other seventeen form a coherent catalog.
- **Impact:** World generation and traveller pacing.
- **Status:** Open for Aimee's review; no engineering placeholder is requested.

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

### EQ13 — Minimap writing disclosure

- **Aimee's direct instruction:** The minimap should always display apex, portal and page icons.
- **Later design-lead recommendation:** `playtest-ui-corrections-current.md` calls unrevealed page
  icons a disclosure bug and asks that diary/other writing appear only after reveal.
- **Temporary implementation:** Preserve Aimee's explicit always-visible page instruction, including
  the new anonymous writing type. Portal and apex behavior is unchanged.
- **Review:** Whether the newer fog-of-war recommendation intentionally supersedes the direct
  always-visible-page decision.
- **Impact:** Search guidance and how literal the guaranteed-writing promise feels in play.
- **Status:** Open; it does not block found-writing persistence or collection.

## Resolved

Move entries here with the deciding source and date; preserve the temporary choice so later audits
can distinguish an intentional migration from an accidental behavior change.

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

- **Resolved 9 Aug 2026 by Game Design Lead:** 1 Mara `opening`, 2 Edren `opening`, 3 Halloway
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
