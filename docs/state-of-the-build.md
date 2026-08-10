# State of the Build — 9 Aug 2026

**Who this is for:** Aimee, and the designer Claude. A single place to see what exists, what's next,
what's blocked on a decision, and where the whole thing is going.

**Where it sits in the docs:** `BACKLOG.md` is the milestone plan and is authoritative for *what v0
is*. `the-queue.md` is the working list of specced-and-unbuilt. This is the overview above both.

**Numbers as of today:** 807 tests at the current full-suite checkpoint; current content has all 28
currently designed recruitable travellers, 233 validated diary pages, 62 focuses and 9 sites.

---

# PART ONE — Where we are

## The one-paragraph version

**The systems are done and the content is thin.** Every major mechanism in the design brief is built
and end-to-end: you write on a page, it resolves into eight pressures, the pressures generate
terrain, plants, animals, sites, resources and people, you walk around in it, fight things derived
from the same numbers, and carry the results home to a base that grows. What's missing is *volume* —
25 recruitable travellers against an expandable high-twenties+ cast, with later packets entering as
their dependencies validate — plus authored meeting/station content and a handful of progression
hooks. Anchoring's three-route core loop is now built.

## What's built, by system

| System | State | Notes |
|---|---|---|
| **Persistence** | ✅ Complete | Three layers kept separate; atomic debounced save after every action; force-quit mid-encounter resumes exactly. **Still wants one on-device force-quit pass** |
| **The writing system** | ✅ Complete | 6×6 page, polyomino footprints, three hands, target-first grammar with clusters and connectors, order-invariant. 62 focuses, 8 subjects, 17 qualifiers |
| **The pressure model** | ✅ Complete | 8 subjects, dual-valued light and heat, diminishing returns, opposed magnitude tracked gross, cross-target constraints, the energy budget |
| **Worldgen** | ✅ Complete | Seeded; terrain, water, chasms, reachability guarantees, sites, resource nodes, day/night |
| **Creatures** | ✅ Complete | Budget-allocated traits, per-world cast, per-spawn jitter, derived identity and names, combat and loot both derived. No drop tables anywhere |
| **Flora** | ✅ Complete | Trait model, the metabolism axis, growth writing the ground, harvest by tissue, hostile plants |
| **Combat** | ✅ Complete | Party of five, ranks, damage triangle, statuses, gambits, 24 skills, three trees × three branches × eight nodes |
| **The search loop** | ✅ Mechanism, ⚠️ content | Signatures, diary pages, the Library, meeting scenes, recruitment, the Firepit. **25 recruitable travellers and 195 validated pages** |
| **The base** | ✅ Mechanism, ⚠️ content | Data-driven stations and found-then-built specialists, including Distillery and Channelworks; 73 research nodes across 8 branches |
| **Analysis** | ⚠️ Partial, design resolved | Acquisition and tier 2 exist; session 18 specifies the missing field loop, grades and tier 3–5 outputs (`instrument-system-audit.md`) |
| **Apexes** | ✅ Core loop | Eight weapon rules, cache lottery, bestiary sightings and consent rules work; authored hunting affinities remain (`apex-system-audit.md`) |
| **Crafting** | ⚠️ Partial | Apothecary and instrument crafting plus all 21 designed physical families/profiles across Blacksmith/Tannery/Bowyer/Armoury/Weaponsmith exist; later station systems remain |
| **Anchoring** | ✅ Core loop | All three routes converge on durable realms; revisit, explicit sustain settlement, dormancy/reactivation and assignments work |

## The last five days, in one line each

- **The greed model was wrong twice and is now right.** It charged you for daylight; then it charged
  the clamped outcome instead of the ask.
- **Writing started at zero instead of at ordinary** — Aimee caught it. A third of the vocabulary
  wrote literally nothing. Fixed, and it was the deepest fault in the system.
- **The party of five actually fights together**, and the Party screen shows the party.
- **Flora, the instruments and apexes** landed this week, in that order.
- **The fossil audit is cleared** — the slot taxonomy is gone, along with everything that only made
  sense inside it.

---

# PART TWO — What's next

## The immediate queue, in order

### 1. Anchoring — **core loop built**

All three routes now work. Born-anchored worlds show the exact premium; Atlas Seams appear
deterministically in 25% of worlds and offer the cheaper confirmed route; Anchor Frames consume six
distinct property-matched samples plus 60 essence and are consumed only on valid placement. Realms
survive as save-compatible Atlas records, revisit without regeneration, and enter an explicit
player-choice essence settlement on return. Unpaid realms become dormant, never deleted, and can be
reactivated. Companion assignment uses visible authored Worldwork aptitude plus level growth.

### 2. The traveller roster — **25 implemented; expansion queued**

**25 recruitable travellers of an expandable high-twenties+ cast**. Bryn, Orsa, Vance, Talin,
Nessa, Corrin, Dagg, Rook, Lys, Bracken, Fen, Wren, Kestrel, Maud, Marrick, Sabine, Grimmond, Oda and Auber now have authored signatures and dependency-safe diary slices; their stations
and authored meeting prose remain later integration work. This is the single highest-value thing left,
because **the cast is what the search loop is for**. Every mechanism is built: signatures, diary
pages, the Library, meeting scenes, recruitment, found-then-built buildings, starting leans.

**What each traveller needs, and only the first is mine:**

| | Who |
|---|---|
| A condition signature | Claude Code can derive one to a target rarity |
| **A name and a calling** | **Aimee / designer** |
| **A voice — the meeting scene** | **Aimee / designer** |
| Usually **5–10 diary pages**, longer for late signatures; mix location, knowledge, sites, people and character material | **Aimee / designer** |
| A building, or none | Designer — and see the trades list below |
| A starting lean | Claude Code |

**Traveller placement is resolved.** Signatures are physical truth: a genuinely matching blank or
accidental book may find somebody, and diary pages guide rather than gate. The incompatible
Traveller's Token remains held for Aimee's review; see `travellers-token-audit-current.md`.

### 3. Consumables and the Apothecary

**17 now exist with property-based recipes**: healing, all four cures, four one-hit weapon coatings,
all four world-facing items, Solvent and Lure. The **Waystone** immediately returns the full haul
from anywhere in one atomic save; Torch, Stillwater, Farsight and Lure affect the active world, and
Solvent identifies a carried curio in the field. Combat presents an item and recipient chooser
rather than silently using the first carried stack. Traveller's Token remains held on Q47.

The station, screen, recipe discovery and crafting rules are implemented and exercisable through the
debug harness. Nessa's identity, signature and seven currently dependency-safe pages are live;
production access still needs her authored meeting/station integration.

### 4. Crafting recipes

Instrument upgrades and the Apothecary recipes exist. The physical gear catalogue is now designed
as **21 property-driven recipe families** across the Blacksmith, Armoury, Bowyer and Weaponsmith,
rather than the older rough target of ~60 named recipes. The material economy underneath is
finished — properties, grades and qualifiers inherited from the animal or plant they came off.
Recipes ask for *properties*, never item names, so every family can produce many provenance-rich
objects. The shared crafted-instance schema and lossless migration are now built: stored and worn
gear retain one durable identity and frozen combat profile; old tier + upgrade power maps once into
construction tier plus visible legacy credit; wild growth stays separate; and reforging is a
three-rank within-tier track worth 0.2 rating per rank. Legacy stacked gear expands into unique
instances without loss. Halloway's eight foundational and Corrin's three flexible property-driven
families now share a live deterministic preview/craft engine and construction UI. Players can
replace every automatically chosen sample with an exact qualifying stock instance before committing.
Fen's Bowyer now adds the three far-reach physical families: Longbow is immediately useful at the
built station, tier 1 adds Sling and Throwing Set, and tier 2 alone permits Tier 4. Specialist stock
below the Tier-3 headline remains honestly craftable behind a distinct confirmation. Shared station staffing now uses
max(purchased, keeper-earned) tiers and a station-local owner-at-Home discount; preview,
affordability and atomic debit use the same rounded paid cost. The Tannery now grants foundational
Wear with construction (and migrates already-built saves), then offers paid Tier-2 fitting, Carry and
Keep roots; the latter two gate only advanced capacity. Bracken's Armoury rebuilds stored or worn
protection in place as Rigid, Balanced or Insulated while preserving identity, wearer, slot,
authored display provenance and cumulative honest receipts. Legacy credit has a separate guard,
ordinary reforge work remains visible, and stale/unaffordable commits are atomic. Keeper-earned
tiers now also render as supplied research rungs and count toward branch progress without inventing
a paid completion. Maud's Weaponsmith completes the physical catalogue with fitted point, edge,
maul and diary-pattern polearm construction. Polearms freeze the player's chosen physical
consequence at mid reach; all recipes show ordinary Might/Finesse advice without adding wearer or
fit state, and use the same exact-sample, discount, confirmation and stale-commit contract.


## Smaller unblocked things, roughly by value

| | Where | Size |
|---|---|---|
| **Living worlds** — bounded visible predation | `predation-living-worlds-current.md` | Medium; design-ready |
| **Building staffing** | `building-staffing-current.md` | Medium; design-ready |
| **Compound assembly** + its gate | `compound-assembly-station-trees-current.md` | Medium; design-ready |
| **The Exchange / Recycler** | `exchange-recycler-current.md` | Medium; design-ready |
| **Identification becomes knowledge** | `curio-identification-knowledge-current.md` | Medium; design-ready |
| **Movement cost from terrain** | built | Tall growth and mud cost one extra turn |
| **Void as a cap** | `void-cap-current.md` | Small; design-ready |
| **Count reaching the description** | `count-description-current.md` | Small; design-ready |
| **Palette sections + vocabulary migration** | `writing-palette-vocabulary-migration-current.md` | Small; migration-ready |
| **Tutorial implementation** | `tutorial-discoverability-current.md` | **Slices 1–4 built; combat/recruit and later-system hooks remain** |

**On the tutorial:** the writing system is not discoverable cold. The current design now teaches it
through interruption-safe contextual lessons across the first two bindings, then just-in-time system
hooks. Writing Desk and first-world essentials should begin before the full content catalogue lands.

Writing Desk and first-world essentials now use versioned durable lesson records, one nonblocking
context card at a time, Got it/Not now behavior, encounter/loot suppression, and Settings → Field
Notes replay. Blank binding remains valid, both tap travel and the D-pad teach movement, actions
teach from the current tile, and every real expedition outcome files Return. Pre-tutorial saves
infer already-earned notes only when the tutorial field is absent, avoiding launch takeover while
preserving exact round trips for current saves.

---

# PART THREE — What is genuinely waiting on review

Anchoring's three routes, traveller placement, separate flora/creature budgets, site Stability,
combat-tree depth and animal combat structure are resolved. Historical alternatives remain in the
archive; they are not active questions.

The current running review list is `engineering-questions-for-aimee.md`. The material holds are:

| Area | Current position | Why it remains open |
|---|---|---|
| **Great Work / Reality reset / Tam** | Deliberate hold; preserve realm history but invent no score or ending trigger | These require one dedicated emotional/endgame pass |
| **Talin armour threshold grammar** | Design-ready; implementation pending | Absolute armour marks 1/3/5; HP percentages are not reused. See `gambit-stat-thresholds-current.md` |
| **Traveller's Token** | Design lead recommends cutting it | It contradicts truthful signature placement; awaiting Aimee's review |
| **Waystone material** | Rift-glass recommended over Adamant | Final repeatable demand and Glass vocabulary need review together |
| **First anchoring balance** | Reversible live values | Needs multi-realm campaign play |
| **Kestrel first-record timing** | Encounter-start snapshot placeholder | A deeper bestiary may later distinguish sighting from completed study |
| **Opening safety and tutorial density** | Honest generation; nonblocking contextual lessons | Needs fresh-save observation, not more paper design |
| **Realm production cadence** | Four surplus work per unit, six-unit tray | Needs short- and long-session play |

---

# PART FOUR — The long-term build plan

## The shape of the game, as designed

Four loops, nested:

1. **Write a world** → bind → explore → harvest → come home. *Built.*
2. **Spend what you brought** on being able to bring more. *Built.*
3. **Find people**, who unlock buildings, which unlock what you can make and learn. *Mechanism
   built, cast missing.*
4. **Keep a world.** Anchoring turns a disposable run into a permanent place. *Core loop built.*

Loop 4 is the one that turns this from a good roguelike loop into the game the brief describes, and
it is the one thing entirely blocked on a decision.

## Where the three progression axes stand

The brief's whole thesis is **literacy, not inventory** — you get better by knowing more, not by
carrying more. Three axes carry that:

| Axis | What it is | State |
|---|---|---|
| **Vocabulary** | What you can say. 62 live focuses; exact 23-entry path to 85 | ✅ Working, ⚠️ expanding. See `focus-expansion-85-current.md` |
| **Page space** | What you can fit. The page **never grows** — better hands say the same things in less room | ✅ Complete |
| **Analysis** | What you can *read*. 8 field instruments + later lens tiers | ✅ Field loop and tier behavior built; values remain playtest tuning |

**All three have an acquisition door and a current progression rule.** The analysis gate—*the lens
only shows what you have measured in the field*—remains the key distinction between owning an
instrument and understanding a world.

## A proposed order for what's left

**Phase 1 — Finish the current cast rollout**
All twenty-eight currently designed travellers are live through Nine. Perren's authored opposed
route has a fixed survivability fixture; Nine's complete packet includes every now-valid relationship.
Tam remains the one deliberate endgame hold. Continue deferred relationship pages and downstream
systems rather than reopening roster structure.

**Phase 2 — The making half**
The Apothecary engine and Distillery/Channelworks first slice exist or are in active integration.

Expedition partial-haul resolution now protects the exact quantities packed before departure:
unused starting supplies always return, consumed supplies do not duplicate, and only newly acquired
haul is exposed to the temporary saved-RNG retention roll. Legacy mid-expedition saves reconstruct
that boundary conservatively.

The writable qualifier grammar now rejects ambiguous new links before mutating the page: one
subject, compatible focuses, one directly attached modifier per ladder, and multiple focuses only
after Chaining. Old ambiguous pages remain loadable and receive a visible warning. Scale's written
Minute/Small/Large/Vast offsets correctly straddle the unwritten ordinary value, and inert Hydrology
Phase remains decodable but is absent from the writing palette.

Found writing now has a separate save-tolerant model and Library collection. Every world reserves
one reachable writing host before optional contents, uses the 70/30 diary/world-note starting mix,
and can place a distinct second piece at the configured ten-percent rate. Exhausted diaries reweight
to persisted field notes without advancing or resetting diary patience. Route marks, site fragments
and working scraps remain the next content families.

Expedition summaries persist portal, Waystone, defeat, collapse or future-abandon outcomes. Only a
real collapse increments the collapse counter; partial returns now report recovered and lost
resources/items separately, followed by pages and party progress under “Kept for good.”

Tier-3 focus attribution now obeys the same field-calibration boundary at the Writing Desk and in
World History. History retains structured effects so surveying a new subject can illuminate an old
world later without leaking that secondary beforehand; legacy flattened records filter
conservatively. Tier-4 prose also voices stabilising/destabilising meaning to accessibility tools.

Cycle now drives the expedition clock. Resolved magnitude chooses stopped/64/40/28/20-turn bands,
regularity produces bounded deterministic per-cycle jitter, and Stillness genuinely prevents phase
events and roster swaps. The schedule survives save/load and anchored revisits; old mid-run saves
retain their current phase at migration. Calibrated, deliberately written Cycle can name its band
in the preview, and visited worlds retain clock analysis for History. The DEBUG harness reports the
resolved band/pressures, held or advancing phase, and next two light transitions without mutating
the run, alongside compact writing/life/apex counts.

DEBUG expedition-feel controls now cover writing mix and patience, stability duration, collapse
recovery, apex chance and base vision. Values are frozen into a run at binding where changing them
mid-expedition would corrupt comparisons; old saves decode to authored defaults. Each section names
its scope/default and can reset independently.
Continue with the 21 physical families, Tannery and specialist shops on the completed instance and
migration foundation. This is where the resources hauled from authored worlds become deliberate
equipment.

**Phase 3 — Anchoring depth**
The core loop and authored aptitudes are built. Renewable production is design-ready around
discovered source manifests and sustain-first Worldwork; later Atlas progression waits on its
ending-facing threshold.

**Phase 4 — Living worlds and social/deep breadth**
Implement bounded predation, Tavern/generated visitors, animal trust/Menagerie, Deep Works and the
expanded station/site catalogues from their current documents.

**Phase 5 — Teach it**
Continue the tutorial/discoverability design with slices 3–6. The opening two slices are built and
simulator-verified; finish the remaining framework before new systems compound its integration cost.

**Ongoing, in parallel**
Content volume — the exact focus path to 85, sites from 9 toward 15, diary rollout and recipes — plus the device-testing pass
on the numbers that can only be settled by playing: map size, day length, viewport, and the
stability→turns curve.

## What would worry me if I were the designer

1. **The cast is no longer the content bottleneck, but integration follows it.** Twenty-five people
   are live; their later stations and dependency-safe first uses now need to catch up.
2. **Nothing has been played end-to-end for long.** Automated tests prove systems agree with
   themselves; they do not prove a month-long campaign is enjoyable. The most important remaining
   evidence is sustained device play.
3. **Anchoring now needs play balance**, especially premiums, Seam frequency and sustain pressure.
4. **Tutorial implementation continues in bounded slices.** First-return routing and semantic
   two-world comparison now follow the opening lessons; combat/recruit and later-system hooks remain.
5. **There is no failure state worth the name.** Running out of health ejects you home with half a
   haul. That may be exactly right for a comfy game — but it should be a decision, not a default
   nobody revisited.

---

## Appendix — content census, 9 Aug 2026

| | Built | Specced | |
|---|---|---|---|
| Focuses | **62** | **85** | Exact remaining scope in `focus-expansion-85-current.md` |
| Subjects | 9 | 9 | Complete |
| Qualifiers | 17 | ~25 | |
| Resources | 23 | 23 | Complete |
| Items | **78** | — | 52 gear · 17 consumables · 2 curios · 2 keys · 5 treasures |
| Skills | 25 | 25 | Complete |
| Combat tree nodes | 72 | 72 | Complete |
| Research nodes | **72** | — | Current catalogue; station expansion adds authored decisions |
| Sites | **9** | **15** | Six additional profiles are current |
| **Travellers** | **28** | **28 active designs + Tam held** | Designed roster live through Nine; Tam deliberately held |
| Contradictions | 9 | — | |
| Description clauses | 50 | — | Every one reachable, by test |
| Stations | **18** | More keeper stations queued | Lifecycle matrix is current |
| Consumables | **17** | **17 + held Traveller's Token** | Current useful catalogue complete |
| Physical gear recipe families | **21** | **21** | Halloway, Corrin, Bracken, Fen and Maud families are live; tuning remains playtest work |
