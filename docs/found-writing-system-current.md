# Found writing — the one-writing-per-world promise

**Status:** Current implementation-facing first slice; mix and placement distance are playtest values.  
**Updated:** 9 Aug 2026

## Player promise

Every generated expedition world contains at least one **discoverable piece of writing**. While both
pools are eligible, the guaranteed slot begins at roughly **70% diary / 30% other writing**. A 10%
chance adds a second piece. Exhaustion or temporary ineligibility reweights the choice; it never
creates an empty world to protect a ratio.

“Discoverable” is stronger than merely instantiated somewhere on the map:

- the writing is on a passable tile in the start-connected reachable region;
- ordinary navigation can reach it before collapse under the world's projected safe-turn budget;
- it is not placed on the entry tile or behind a mandatory combat/site interaction;
- the first-slice placement band is the nearest third of eligible reachable tiles, excluding the
  first two steps, with the band exposed in debug tuning;
- collecting it banks its knowledge immediately, as diary pages already do.

The promise is about finding writing through ordinary exploration, not receiving it in the entry
summary or seeing its exact location through fog.

## Two separate content models

### Diary pages

Diary pages remain finite authored fragments belonging to a named traveller. They carry that
person's voice and may teach a focus, gambit, lead, site or whereabouts clue. Existing condition
preference and the one-page-at-a-time eight-world patience fallback apply only to this pool.

### Found writing

Found writing is not secretly assigned to a traveller and does not count toward a diary's completion.
It uses short authored templates populated only from resolved, disclosure-safe facts about the
current world. It exists so the world can contain human traces without accelerating every personal
diary at once.

This is a deliberate 9 Aug 2026 extension of the older “all pages are diary pages” rule. The older
rule remains useful history, but cannot satisfy Aimee's newer requirement that diary and other
writing types interleave while every world still contains writing.

## First-slice families

| Family | Eligibility | What is recorded | Mechanical value |
|---|---|---|---|
| **Field note** | Always | One qualitative fact already observable in the reached area: terrain, weather/light, common growth or a plainly seen creature trace | Adds a named note to this world's History; never grants analysis precision |
| **Route mark** | World has at least one meaningful navigable contrast | A short instruction about a nearby costly/safer terrain relationship using directions relative to the page tile | Reveals only the traversed local route segment; no remote map or site reveal |
| **Site fragment** | A site is already revealed or the writing is physically hosted at that visible site | One authored fragment from the site's family | Records that site's known family and prose; never reveals a site through fog |
| **Working scrap** | One currently reachable research/station lead is eligible | A finite authored partial lead tied to an existing node/recipe | Grants only the defined partial lead; never chooses locked future systems |
| **Vocabulary trace** | One eligible unowned world-drop word exists | A stable typed source or qualifier teaching from a separately approved vocabulary track | Permanently teaches exactly that word; never grants an item or analysis |

Selection within the other-writing pool starts at:

- Field note: 55%
- Route mark: 20%
- Site fragment: 15% when eligible
- Working scrap: 10% when eligible

Vocabulary traces are selected only when a separately approved vocabulary track supplies eligible
words and pacing. Ink colors are not vocabulary traces: deliberate mixing comes from Isolde's
Scriptorium, while Ash leaves color open to world generation. A vocabulary floor may never create a
third writing or displace a selected diary.

Ineligible weight flows to Field note. These are debug/playtest weights, not story canon.

## Repeatability without junk

Field notes and route marks may repeat as families but are unique records because they bind to a
world ID, tile/region and selected fact. The Library groups them under **World notes**, not under a
traveller. Re-reading a collected record shows it again but grants no second reward.

Templates must not say only “the ground was wet.” Each note should preserve a useful relation or
human action, for example that someone chose the firmer edge of a flooded path, or saw the same
groundcover stop at the ash boundary. The generated facts supply nouns and relationships; authored
sentence shapes supply voice without pretending one recurring anonymous author exists.

The authoritative fact families, stable template IDs and disclosure rules are in
`field-note-grammar-current.md`; the current three generic implementation lines are only a tolerant
legacy fallback, not the completed content pool.

Working scraps are finite and deduplicated. If no genuine lead is currently meaningful, select a
world note instead. Do not generate currency, generic research points or inert “lore fragments” just
to pay the guaranteed slot.

## Disclosure and host selection

Content is selected before a physical host. A valid writing can use a loose-page tile, visible site,
abandoned camp/marker dressing or other presentation, but its reward cannot depend on the world
rolling that host.

- Never mention an unrevealed site, resource, traveller, apex or species identity.
- Plainly visible anatomy and terrain can be described; analysis-only causes, percentages and
  inferred mechanics cannot.
- A Field note may become more precise in the Library after the player independently earns the
  relevant analysis, while the recovered prose itself remains unchanged.
- The guaranteed writing does not consume the site's ordinary contents draw or add a second
  Stability cost.

## Placement and pacing algorithm

1. Resolve the diary and other-writing eligibility pools without changing them.
2. Fill one guaranteed slot using the 70/30 starting mix, dynamically reweighted.
3. Apply any due typed-vocabulary dry floor to the remaining optional slot, then otherwise roll the
   10% additional slot from remaining eligible content; do not duplicate the selected ID or create
   a third writing.
4. Choose disclosure-safe content facts from the resolved world state.
5. Choose reachable hosts independently, preferring distinct tiles when two writings appear.
6. Persist chosen IDs, facts, prose variant and positions with the run; reload never rerolls them.
7. Advance the diary patience queue only according to its own rules. Selecting other writing neither
   resets nor accelerates that wait.

## Debug controls and telemetry

Expose:

- guaranteed writing on/off override;
- diary/other mix;
- second-writing chance;
- eligible placement-distance band;
- per-family other-writing weights;
- forced family and forced exhausted-diary-pool fixtures.

Record generated/collected counts by family, distance from start, safe turns remaining at collection,
missed writing on resolved expeditions and diary patience state. The main success metric is not only
“a writing spawned”; it is whether ordinary play actually found it.

## Verification

1. Every generated world has at least one reachable persisted writing, including an empty diary pool.
2. A temporarily condition-ineligible diary pool falls back to other writing without making all
   diary pages universally eligible.
3. No found writing reveals fogged content or grants unavailable research.
4. Two-writing worlds never place duplicate content or require one site to exist.
5. Save/reload and anchored revisit preserve collected state and exact prose/facts.
6. Long simulations approach the configured mix while never violating the per-world guarantee.

The implementation contract for the three post-Field-note families is
`found-writing-breadth-current.md`.
