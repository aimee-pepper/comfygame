# The Queue — everything still to build

**What this is.** `BACKLOG.md` is the milestone plan and is authoritative for *what v0 is*. This is
the working list: everything specced-or-decided and not yet built, in the order I'd take it, with
what blocks what. Kept current by the implementation engineer.

**For the overview** — where the whole build stands, what's blocked on a decision, and the long-term
plan — read `state-of-the-build.md` first. This file is the detail under it.

**Last updated 11 Aug 2026.** The partial-haul safety boundary now preserves unused supplies packed
before departure while risking only newly acquired haul. Flora, instruments, apexes, the implemented-six traveller repair,
Apothecary catalogue, and its field-item loop are complete. **Anchoring's first complete loop is
built**: all three acquisition routes, durable saves/revisits, the Anchorage portfolio, explicit
return settlement, dormancy/reactivation and companion assignments. Authored aptitude identities
and deeper renewable production remain later depth.

---

## The order, and why

### ~~1. Flora~~ — **built**

The material half first: the six organic resources stopped reading vitality's `peak` (which counts
herds) and started reading `produced`, so a world of grazing animals and no plants no longer yields
timber. Then the terrain half — the trait model, the metabolism axis, growth writing the ground,
harvest by tissue, defended flora.

**What it changed that's worth knowing:**

- **Nothing paints growth but plants.** Cover used to be scattered per-tile off Vitality, so it had
  nothing to do with what grew there. Habit now decides patterning and stature decides whether it
  breaks a sightline — a world can be topographically open and still be a maze
- **A lightless volcanic world teems.** Chemosynthesis lifts both life caps, because eating basalt
  needs neither light nor water. It was capped twice over for two reasons that don't apply
- **A world with nowhere to make a living carries no food web** — no producers, therefore no
  herbivores, therefore no predators. ~3% of worlds, and writable on purpose
- **Organic nodes stand where something is growing**, and which one it is comes off the plant

**Resolved Q48, corrected 14 Aug:** flora and creatures keep separate budgets. Flora tissue remains
scaled by Vitality under its own authority; ordinary creature species use a fixed budget while
Vitality peak controls cast/population and `trophicDepth` redistributes investment. They still
influence one another through producer productivity and trophic depth.

### 2. The real instrument system — **complete**

Eight field-instrument purchases and the four lens gates exist. The Survey Post now configures a
carried loadout, snapshotted at departure and shown with consumables in the mid-run Field Kit.
Survey uses that whole carried kit for one world turn, records permanent compact observations, and gates the Desk and World History on
subjects actually calibrated rather than merely owned. Tier 3 now exposes per-focus primary and
secondary contributions at the Desk and in World History. Tier 5 now shows allocator-derived trait
ranges and ecological-role likelihoods. Good and fine grades are now made from property-matched
material samples at the Survey Post, consume the weakest qualifying samples first, and their grade
is frozen with the carried kit at departure. Tier 4's numerical breakdown and contributor-derived
marking are built. See `instrument-system-audit.md`.

### 3. Apex encounters — **core loop built; hunting signatures later**

The creature, restraint rules, greed draw, all eight weapon rules, locked-cache bonus lottery and
explicit bestiary sightings work. Authored condition affinities remain the later layer that turns
specific apex hunting into a world-writing goal. See `apex-system-audit.md`.

### 4. The traveller roster — **29 live/recruitable**

The live catalogue contains 29 recruitable travellers. Eight have live meeting objects; the other
twenty-one retain the generic recruitment fallback while their authored meetings remain review-only.
Bryn through Lys also have authored
signatures, global order/phase and dependency-safe diary packets. Bryn, Dagg and Rook's exclusive
gambit teachings work end to end; diary-exclusive focus acquisition can no longer be pre-empted by
random caches. Dangling relationship pages and Talin's configurable armour component remain deferred.
All 29 live travellers have explicit authored order and campaign phase,
one honest location page per condition, and their approved focus teachings. Mara's Survey Post,
Edren's Reliquary, Halloway's forge, Isolde's Scriptorium, Sela's Wayfarer's Table and Tovin's
Anchorage are represented. Tovin uses the current eight-condition late signature.

The reusable structure is in `traveller-template.md`; current identities, signatures and diary
packets are indexed in `current-design-index.md`. The whole-roster audit was completed before the
individual packets were treated as final direction.

Expansion follows `roster-progression-current.md`; Ashe is the latest live eight-condition slice.
Her twelve dependency-valid pages, active-emanation gambit teaching and traveller-specific Ground
technique are live. Auber's Distillery now
crystallises blank cores and attunes Heat, Caustic and Light cores from an explicitly selected
provenanced sample; Channelworks restores Oda's one authored fixture and consumes repeatable Heat
cores for subsequent fixtures. `maud_fitting_pattern` is now a persistent diary reward powering the
advanced melee recipe, so the page grants a real usable pattern rather than an inert save flag.
The Home roster is no longer incorrectly capped at five; five is active combat party size including
the Binder.

Perren and Nine completed the original 28-traveller rollout. Noll is now the live twenty-ninth
traveller and second opening-economy identity with a provisional DEBUG-labelled meeting; the held
Field Separation Kit remains separate review content. Perren has a fixed authored
opposed-world fixture proving all nine conditions and at least ten playable turns. Nine's full packet
is live; her reversible Thermal range placeholder was tightened to ≤12 after distribution testing.
Tam remains deliberately held by the Great Work boundary.

---

## Everything else, grouped

### Specced and unbuilt

| | Where | Note |
|---|---|---|
| **Debug balancing expansion** | `debug-balancing-surface-current.md` | Batch 2 controls are built and snapshotted, including the explicit fresh-first-expedition Natural/Gentle/Clear approach envelope; generation diagnostics now persist writing selection/placement, Raw Essence, populations, apex, duration, traveller and full-profile facts. Deterministic forcing/export remain before long-campaign breadth |
| **Traveller meeting corpus** | `traveller-meeting-interaction-current.md`, `traveller-meeting-corpus-plan-current.md` | Ordered/terminal behavior and DEBUG atlas are built (`9cc0f10`); Noll's provisional meeting is live, while the generated review corpus retains 21 draft-only missing-live meetings plus Auber's separate revision. None of those remaining drafts promotes without explicit review |
| **Party/minimap corrections** | `playtest-ui-corrections-current.md` | Core-stat strip removed; minimap sits beside D-pad above Portal home; every POI is now fog/discovery-gated by default per `minimap-disclosure-current.md` |
| ~~**Crafting recipes**~~ | `gear-crafting-families-current.md` | **Built:** all 21 physical families/profiles, durable migration, exact selected-sample receipts, specialist tiers/confirmations, keeper-at-Home discounts and stale atomic commits |
| ~~**Bowyer**~~ | `gear-crafting-families-current.md` | **Built:** Fen lifecycle/build bundle, immediate Longbow, tier-1 Sling/Throwing Set, tier-2 Tier-4 cap, exact samples, far-reach triangle and honest below-headline confirmation |
| ~~**Armoury rebuild**~~ | `armoury-rebuild-implementation-current.md`, `armoury-profile-offset-audit-current.md` | **Built:** stored/worn in-place rebuild, Rigid/Balanced/Insulated tier matrix, exact sample provenance/receipts, fractional protection offsets, legacy guard, atomic stale/affordability handling and keeper-supplied research presentation. Initial 0/−0.5/−1.0 profile now has comparable-fight retuning gates under DRQ-123 |
| **Reforge progression correction** | `reforge-progression-audit-current.md` | **Aimee review:** current 0.2×3 meter contains paid ranks with no final combat change. Recommend one +0.5 within-tier reforge, first-step price, and exact grandfathered 0/0.2/0.4/0.6 migration rather than inventing extra effects |
| ~~**Weaponsmith**~~ | `weaponsmith-implementation-current.md` | **Built:** exact Maud lifecycle/rungs, fitted point/edge/maul, persistent diary-pattern polearm with chosen physical kind, visible lean advice, no wearer-fit subsystem, exact receipts and atomic commits |
| ~~**Tannery**~~ | `tannery-system-current.md` | **Built:** exact lifecycle/bundle, free foundational Wear with old-save inference, paid Tier-2 fitting, paid Carry/Keep capabilities, advanced-capacity gates, exact samples and Corrin's three families |
| ~~**Distillery first slice**~~ | `distillery-system-current.md` | **Built:** safe blank crystallisation, three attunements, potency/provenance, stacking/save behavior and first repeatable Heat Conduit consumer. Retuning and Infuse remain held by design |
| **Deep Works** | `deep-works-system-current.md` | Implementation-audited one-site first slice: dedicated saved sign/profile state, isolated bind RNG, finite pulls and atomic brace selection; thresholds/frequency remain DRQ-129 playtest values |
| **Channelworks** | `channelworks-system-current.md` | Implementation-audited first slice: receipt-bearing emanation profile, shared combat path, atomic construction/retuning and three reversible housing curves under DRQ-130 |
| **Site catalogue** | `site-system-catalogue-current.md` | Implementation-audited six-profile expansion; stale Raw Essence yields, inert Stability data, typed placement predicates and independent writing hosting precede breadth under DRQ-131 |
| **Consumables** | `crafting-spec (1).md` PART FOUR, `apothecary-coating-identity-current.md` | **17 authored:** healing, cures, Stonebark, four coatings, all world items, Solvent and Lure. Nessa/Apothecary reachability remains queued; that checkpoint must also apply zero-Essence ordinary costs, fix invalid Venom `fibre`→`fiber`, and separate Briar Oil as Fiber + Resin |
| **Building staffing** | `building-staffing-current.md` | ✅ Shared max(purchased, keeper-earned) tier and correct-owner-at-Home discount rules are built with assignment/rounding fixtures; extend paid-action consumers as each station surface lands |
| **Station catalogue expansion** | `station-integration-matrix-current.md` | Design-ready lifecycle/cost/dependency matrix for every current keeper station |
| **Compound assembly** | `compound-assembly-station-trees-current.md` | Design-ready; needs personal compound schema, runebook/popup and Scriptorium gate |
| **Per-building research trees** | `compound-assembly-station-trees-current.md` | Core station ownership/gating architecture exists; expand it as specialist stations land |
| **The Trading Post / Recycler** | `trading-post-recycler-current.md` + `opening-economy-trio-promotion-audit-current.md` | **Built at `aaf6280`:** Vance/Trading Post, Noll/Recycler and Halloway/Blacksmith now form the opening 1/2/3 economy sequence. Source tests are green; signed-phone installation and fresh-save sell→recycle→make→bind acceptance remain. Exact Noll prose and Field Separation Kit stay separate review work |
| **The Tavern** | `tavern-random-companions-current.md` | Implementation-audited: Firepit upgrade, stable generated-person identity, durable met pool, persisted outcome-refreshed visitors and atomic wants |
| **Predation** | `predation-living-worlds-current.md` | Design-ready bounded behavior; group-motion texture may follow performance testing |
| **Anchoring depth** | `anchoring-system-current.md`, `anchored-realm-production-current.md` | Core loop and authored Worldwork aptitudes built; renewable production is design-ready |
| **Tutorial / discoverability — DEAD LAST** | `tutorial-discoverability-current.md` | Slices 1–4 are built. Slices 5–6 remain intentionally last behind every current playability, correctness, visual, progression and content-system priority; never pull them forward as filler work |
| **Tutorial slices 1–2** | `tutorial-opening-slices-current.md` | ✅ Versioned state/migration, one-card Desk/world essentials, suppression, Field Notes replay, and outcome completion built; fresh-save playfeel still belongs in ongoing observation |
| **Debug Batch 2** | `debug-balancing-surface-current.md` | Complete first slice: all expedition-feel controls are live and per-run snapshotted; opening envelope deterministically relocates only ordinary mobile entry enemies on a fresh first expedition; the DEBUG report reads saved generation facts rather than mutable tiles or rerun RNG. Broader deterministic forcing/export remains a separate Test Setup batch. |
| ~~**Expedition loss boundary**~~ | `expedition-outcomes-current.md` | **Built:** pre-departure property is protected, only net-new haul enters partial loss, exit kinds persist separately, and recap shows Recovered/Lost/Kept-for-good; random-vs-chosen recovery remains review-only |
| **Random companions** | `tavern-random-companions-current.md` | Design-ready; persistent generated identity, reachable want, no diary/station |
| **Combat trees** | `combat-tree-true-graph-current.md`, `combat-node-viability-current.md` | **Immediate enabling priority:** replace live ladders and rejected Asset v0.2 with the true 3-root/6/6/6/3 fan-and-fork graph; Asset proof and Engineering schema use this authority |
| **Generated companion arrival builds** | `generated-companion-arrival-builds-current.md` | Existing branch-step arrival data needs the true-graph migration to explicit stable-node route plans; XP/stats/free-point budget and repair semantics remain current |
| **Animal taming / Menagerie** | `animal-taming-menagerie-current.md` | Implementation-audited deterministic Attend→one trust condition→accept loop with awareness integration, exact sample offering and atomic stable-animal transition; no capture odds or breeding |
| **Library / Lys depth** | `library-lys-progression-current.md` | Design-ready keeper exception: basic Library remains opening; Lys adds search, cross-reference and study |

### The writing system

| | Note |
|---|---|
| **Writing every world** | Design-ready in `found-writing-system-current.md`; one reachable guaranteed writing, 70/30 diary/other starting mix and repeatable world-note fallback |
| **Rune pacing** | Design-ready in `rune-pacing-library-legibility-current.md`; one authored target and a six-resolved-world floor |
| **"You don't have the words for this one"** | Design-ready in `rune-pacing-library-legibility-current.md`; passage-level non-spoiling reachability marker |
| **Void as a cap** | Design-ready in `void-cap-current.md`; suppresses whole celestial causes while preserving non-celestial light |
| **Light and Shadow sections** | Design-ready in `writing-palette-vocabulary-migration-current.md`, with Thermal and Vitality counterparts |
| **Count reaching the description** | Design-ready in `count-description-current.md`; focus-specific prose metadata remains content work |
| **The vocabulary rename** | Migration-ready in `writing-palette-vocabulary-migration-current.md`; old symbols become compounds without content loss |
| **Focus expansion 62→85** | Exact 23-entry scope plus 7/3/4/5/4 rollout in `focus-expansion-implementation-batches-current.md`; every obtainable batch passes consequence, acquisition and distribution gates |
| **Qualifier grammar** | ✅ Scale offsets, strict prospective link validation, tolerant legacy warnings and decode-only hidden Hydrology Phase are implemented; no replacement Water Form modifier in the first grammar |
| **Found writing** | Core guarantee is built; resolved-fact Field-note grammar, all three remaining families and the complete 15-site fragment corpus are implementation-ready; telemetry/debug forcing remain |
| **Expedition outcomes** | ✅ Explicit exit kinds, collapse-only loss counting, and Recovered/Lost/Kept-for-good recap ordering are implemented; recovery agency remains review-only |
| **Cycle world clock** | Core clock built from `cycle-system-current.md`: magnitude bands, deterministic regularity jitter, stopped phase, migration, History, earned preview and read-only next-transition diagnostics; debug forcing remains |
| **Quirk pattern** | Current audit in `quirk-pattern-audit-current.md`; keep systemic paired tradeoffs; separate quirk deck and veto/reroll are retired |
| **Contradiction / danger** | `contradiction-danger-audit-current.md`; keep narrow catalogue effects, disable stale Green-in-dark firing, and do not promise dormant Negate entries before a readable grammar exists |
| **Description / analysis consistency** | Core correction built from `description-analysis-surface-current.md`: calibrated structured effects at Desk/History, tolerant legacy filtering, corrected copy and Tier-4 accessibility meaning; phone-density collapsing remains optional follow-up |

### Identification and knowledge

| | Note |
|---|---|
| **Identification becomes knowledge** | Design-ready in `curio-identification-knowledge-current.md`; two resolutions recognize a family forever |
| **Use-to-identify** | Design-ready in `curio-identification-knowledge-current.md`; only valid attributable contexts commit |

### Awaiting the designer

| | Question |
|---|---|
| **Animal companion tuning** | Combat and taming both have current reversible first slices; review trust cadence and derived kits after Menagerie play |
| **Waystone's rare material** | Reversible playtest placeholder uses Rift-glass instead of Adamant; review after acquisition and repeated emergency-return use are playable |
| **Glass** | Current recommendation: no generic Glass resource; keep Quartz, Rift-glass and the proposed Glass focus distinct |

---

## Recently closed

**The whole fossil audit** — the slot taxonomy and everything that only made sense inside it, the
Constellation node written for one companion, and the site-`stabilityDelta` guard the comprehensive
audit asked for. Plus **flora**, **the instruments** and **apexes**.

**Q47:** signatures remain the placement truth; blank/accidental books may find a genuine match and
clues remain guides rather than gates. The incompatible Traveller's Token is cut.

**Q48:** flora and creatures keep separate budgets and influence one another through productivity and
trophic depth.

**Q49:** all eight weapon rules, the 3% cache bonus, explicit apex sightings and later
condition-favoured hunting are decided in `apex-system-audit.md`. Its earlier immediate-map-reveal
rule is superseded by the settled explore-first boundary in `minimap-disclosure-current.md`: an apex
marker appears only after legitimate discovery or an explicit invested disclosure effect.

**Emanation discipline:** player-facing/new graph ID **Emanation** / `emanation`; legacy `kindling`
maps one-way at graph migration and remains decode-only.

**Combat progression:** eight-point capstone routes through the true graph, one point per level,
level cap 25 and paid Spring
respec are implemented/current. Calling leans are bonus points above the 24 level-earned budget; see
`combat-progression-current.md`.

And before those, all four `clause-audit.md` findings and the two Aimee raised directly:

- **F1** — the bestiary had no screen at all; built, with personal *and* global percentiles
- **F2** — analysis had no door; instruments at the forge *(placeholder, see item 2 above)*
- **F3** — compound assembly's gate; folded into the assembly work, since a gate on a missing
  feature is a dead button
- **F4** — stale: the writing surface already drew glyphs, and the SF Symbol accessor behind it was
  read by nothing
- **The party of five**, and the Party screen showing the party
- **Found travellers stranded** — marked found, never seated, and never placed again
