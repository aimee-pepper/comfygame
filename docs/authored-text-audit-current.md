# Authored Text Audit — Current

**Status:** first complete manual corpus pass; production-first playtest policy is current. Reviewed
content may enter the live catalogue without waiting for advance Atlas approval so Aimee can judge it
in ordinary play. Every promotion retains stable IDs and preserves the prior text in the decision
archive or Git history; the Atlas remains a review and flagging tool, not a content-release gate.

**Live corpus at first audit:** 28 travellers, 233 diary pages, 7 travellers with authored meeting
objects (Mara, Edren, Sela, Tovin, Halloway, Isolde and Auber). A DEBUG atlas must distinguish
“missing meeting” from “not yet implemented” rather than implying the other 21 have been reviewed.

**Current corpus correction, 12 Aug 2026:** Noll is the live twenty-ninth recruitable identity and
has a provisional DEBUG-labelled meeting. The live corpus therefore has 29 travellers and 8 meeting
objects. The review corpus still has 23 meeting objects: 21 for live travellers missing meetings,
Noll's replacement candidate and Auber's side-by-side revision.
`debug-authored-text-atlas-current.md` owns the derived-union tooling boundary.

## First-pass completion summary

- **Meetings at first audit:** all 7 then-live objects reviewed; Mara, Edren, Sela, Tovin and
  Halloway were Good; Isolde and Auber need revision. Noll's later provisional eighth object remains
  review copy, and 21 travellers visibly lack meeting objects.
- **Diary corpus:** all 233 pages reviewed by category: 138 location clues, 18 focus teachings,
  7 gambit teachings, 1 pattern, 3 research leads, 39 whereabouts, 14 worlds worth writing, 9 site/
  ruin pages, 3 accounts and 1 interpretive turn.
- **Historical prose revision candidates:** the original packet held 18 location pages. The complete
  production audit in `location-clue-clarity-audit-current.md` subsequently reviewed all 138 live
  location clues and promoted 75 exact clarity corrections across two passes. Isolde/Auber meeting work remains
  separate from this clue checkpoint.
- **Exact review surface:** `location-clue-clarity-audit-current.md` is current production truth;
  `location-clue-revision-packet-current.md` is historical where its smaller candidate set differs.
  `traveller-meeting-voice-revision-packet-current.md` still owns the Auber meeting candidate.
- **Mechanical metadata bug:** `tovin_about_isolde` moves from Isolde clue index 0 to 1 without a
  prose change.
- **Comprehension checks:** several otherwise-keep pages are routed to atlas review; they are not
  pre-emptively labelled Needs revision.

This completes Design's requested independent prose audit. The DEBUG atlas supports playtest review
and flagging; it does not prevent approved authored content from becoming reachable in-game.

## Review rubric

Player-facing writing should pass five tests:

1. **Standalone sense:** a page or selected reply makes sense without adjacent catalogue entries.
2. **Concrete foothold:** location clues begin with observable world evidence before interpretation.
3. **Mechanical usefulness:** a clue points toward the correct condition without exposing debug
   vocabulary or exact numbers.
4. **Voice ownership:** removing the name should not make every traveller sound interchangeable.
5. **Economy:** one strong metaphor or reversal per short passage; repeated “X is not Y” thesis
   constructions are reserved for moments that earn them.

Review results are **Good**, **Revise**, **Blocked by implementation**, or **Missing**. “Good” means
fit for the current game, not immutable final prose.

## Batch 1 — live meetings

| Traveller | Result | Audit |
|---|---|---|
| Mara | **Good** | Clear physical business, three independent questions, distinct surveying voice and a recruitment offer that follows naturally. |
| Edren | **Good** | Concrete excavation anchors every answer. “Everywhere used to be somewhere” is memorable and earned by the floor image. |
| Sela | **Good** | Movement structures both scene and voice. Each answer works independently and her offer resolves the precise fear she expresses. |
| Tovin | **Good** | Binding history, failure and missing materials are legible without becoming a lore lecture. Strong progression relevance. |
| Halloway | **Good** | Fire/forge identity is immediate and the material need leads cleanly to recruitment. Keep the impossible carried-fire image as character texture unless art makes it literal in a conflicting way. |
| Isolde | **Revise + implementation bug** | Blank-board practice is usable, but “the hand goes first” is too opaque before the player understands the exercise. Current UI falsely displays all mutually exclusive branches as one conversation and reorders them on selection. |
| Auber | **Revise before broad release** | Functional beats exist, but all three replies are aphorisms without action, sensory detail or punctuation/quoted speech consistent with the other meetings. The refinery offer assumes context rather than showing Auber's distillation practice. |
| Remaining 21 | **Missing** | Identity documents often contain meeting directions, but no live `meeting` object exists. Do not treat a blurb/signature as replacement dialogue. |

### Isolde — recommended branch revision

Keep the opening. The player chooses any optional question; only that question and reply append. The
offer remains available after any reply.

| Choice | Recommended current draft |
|---|---|
| There's nothing on that board. | “The board is for resistance, not ink.” She draws the line again, slower. “If the hand cannot keep its course here, giving it charcoal only records the mistake.” |
| You taught this? | “For forty years. Mostly to people who wanted to write faster.” A short laugh. “They had to learn smaller first. Smaller takes longer.” |
| I've been writing in charcoal. | She looks at you for the first time. “Then every mark has had to carry too much.” She sets the board down. “Show me your hands.” |

The second branch preserves her dry joke but removes an unnecessarily tangled final clause. The
charcoal reply explains the real progression constraint without the confusing “saying about two
things at once” formulation.

### Auber — revision direction

Auber needs one visible distillation action threaded through the branches: condensate forming,
separated fractions, labelled vessels or residue being weighed. Preserve the principle that waste is
only displaced, but let it arise from what the player sees. Do not finalize Auber's exact meeting
until the Distillery/Refinery naming and arrival fixture use the same station fiction.

## Batch 2 — Sabine's location sequence

**Result: revise as a complete seven-page set.** The conditions are coherent; the prose repeatedly
states Sabine's ethical conclusion before showing the ecology. The following are review drafts, not
live replacements:

| ID | Condition intent | Recommended draft |
|---|---|---|
| `sabine_where_0` | high production | Bite the new shoots down at dusk and they stand above the old cut by morning. This place can answer feeding without pretending nothing was taken. |
| `sabine_where_1` | high total life | Every shelter is occupied, and fresh tracks stop at the entrances before turning away. More creatures live here than one keeper could gather. |
| `sabine_where_2` | deep food web | Small grazers crowd the new growth. Larger tracks circle them, and scavengers follow what the hunt leaves behind. Feed one creature here and three others change their route. |
| `sabine_where_3` | clustered life | The same hollows are pressed flat each night while nearby ground goes untouched. Return often enough and absence becomes part of the pattern. |
| `sabine_where_4` | abundant reachable water | Hoofprints, paws and dragging tails reach the water by different banks. No creature has to pass another's shelter to drink. |
| `sabine_where_5` | bounded openness | There is open ground enough to approach and cover near enough to refuse. I could work here without making nearness the only safe choice. |
| `sabine_where_6` | highly regular cycle | The same calls begin at the same interval, and the same paths fill soon after. They can learn when I return; that does not mean they must come. |

The sequence intentionally moves from abundance into distribution, access, approach and reliable
routine. Sabine may still make ethical inferences, but each page now supplies an image a player can
match to a world.

## Completed audit order

The first four passes below are complete across the live corpus: remaining location clues, teaching
and singular-reward pages, whereabouts/relationship pages, and focus usability. Those 21
missing-live meeting objects and Noll's review-only meeting are now written as review drafts. The
next authored-content task is exact atlas review/promotion, not another completeness pass. Late copy
should continue to track stable station/gameplay fiction where that fiction is still moving.
The complete scene-anchor/readiness matrix and four authoring batches are in
`traveller-meeting-corpus-plan-current.md`.

## Batch 3 — abstraction-cluster location pages

The mechanical scan's abstraction score was useful for routing but produced false positives where a
concrete first sentence earns a reflective second sentence. Manual review changes the priority:

| Traveller | Result | Audit |
|---|---|---|
| Marrick | **Revise six location clues** | All six conditions are recoverable, but the pages speak in formation doctrine before showing bodies, ground, wind, temperature or water. Highest-priority remaining set. |
| Oda | **Targeted revision** | Pages 3–7 are mechanically legible and appropriately technical. Pages 0–2 rely on “one material / another / disturbance / boundary” without enough visible material behaviour; revise those three together. |
| Ashe | **Mostly good; revise page 3** | The body-first sensory language makes geothermal heat, cycling, sourceless light, toxicity, wind, hostile growth and amplitude concrete. `ashe_where_3` ends in an opaque obedience analogy before establishing volatile substrate clearly. |
| Kestrel | **Good** | Tracks, grazing, pursuit, scavenging, folds in land and visible disturbance provide strong evidence-first clues. Reflective second sentences are earned. |
| Nine | **Good for endgame voice; playtest comprehension** | Each page names a repeatable observation before Nine's continuity inference. The abstraction is character-specific and progression-appropriate, though amplitude/dispersion pages should be checked in the atlas without debug labels. |

### Marrick — concrete revision direction

Marrick should sound like someone who sees group routine in physical arrangements, not a policy
manual. Preserve his concern with who a formation excludes, but lead with what a marcher experiences:

| ID | Recommended draft direction |
|---|---|
| `marrick_where_0` | Boots land level here, whether the wearer is first or fifth in line. Hard ground can carry one instruction across several bodies. |
| `marrick_where_1` | Five people could stand abreast and still point to both edges of the clearing. Wider, and a signal would scatter; narrower, and there would be no choice of position. |
| `marrick_where_2` | The same gust reaches every place in the line. Watch longer and it becomes clear who must lean harder to keep it. |
| `marrick_where_3` | The air barely changes temperature from one watch to the next. Fatigue will show here before weather gives anyone an excuse for missing it. |
| `marrick_where_4` | The interval returns closely enough for five people to keep one count. The useful test is what the routine does when the sixth count is missed. |
| `marrick_where_5` | Water meets the route often enough that no one person must carry the group's whole thirst. That is when a provision becomes part of the formation. |

These drafts retain Marrick's distinctive inference while making hard substrate, banded openness,
high air motion, narrow thermal range, regular cycle and available water individually imaginable.

### Targeted page corrections

- `oda_where_0` should show a struck/loaded material keeping its shape before naming a housing.
- `oda_where_1` should show a material flexing, carrying or changing under the same force; avoid using
  “instability” as a substitute for volatile-form evidence.
- `oda_where_2` may keep containment language, but add close walls/returned sound or another visible
  sign of low openness before the moral distinction.
- `ashe_where_3` should begin with ground that shifts, vents or transmits force under pressure. Ashe's
  comparison to their own treatment belongs in an account/relationship page, not the location clue.

No Kestrel or Nine live-copy change is recommended from this pass.

## Batch 4 — teaching and singular-reward pages

The live corpus currently contains 18 focus teachings, 7 gambit-component teachings, Maud's one
pattern page and three research leads. Mechanical ownership matches the current reward registry; no
duplicate teaching owner was found in this prose pass.

### Focus teachings

**Keep as a set for atlas playtest.** The strongest lines define the learned word through a physical
distinction rather than reciting pressure math: Scarp ends ascent, Pond is bounded stoppable water,
Hush stills the air, Chitin protects in articulated pieces, Silk distributes strain, Mercury moves
through low places, Brine carries by concentration and Mirror tests a bounded reversal. Dream also
correctly refuses to imply recovered biography.

Targeted comprehension checks rather than immediate rewrites:

- `tovin_drift` establishes that time can depart from an agreed interval, but the atlas should test
  whether a player understands Drift as directional Cycle change rather than merely irregularity;
- `orsa_hive`, `vance_amber` and `sabine_coral` earn their character voice after naming the physical
  idea, but their second sentences should be reviewed without developer labels;
- `lys_echo` is concise and accurate, though the UI must make clear that the word itself has been
  learned rather than presenting the sentence as only a diary reflection.

No focus prose change is authorized from this batch alone.

### Gambit teachings

**Mechanically clear enough to keep.** Each page names the actual subject:

- ally in back rank;
- self recovery complete;
- foe cannot reach self;
- at least three foes present;
- unrecorded foe species;
- any ally below the chosen HP mark;
- foe actively emanating.

The pages intentionally teach a subject/trigger, not a complete gambit. UI must show the stable
component name and where it can be installed after collection; prose alone should not have to carry
that onboarding burden. `marrick_teach_ally_hp_any` correctly warns against preselecting a particular
ally, and `dagg_teach_recovery_complete` correctly locates the trigger on the first actionable turn
after debt ends.

### Pattern and research leads

Maud's fitting page clearly describes repeatable motion and allowances and remains aligned with the
Weaponsmith pattern. Halloway/Isolde's paired Brush leads distinguish ferrule pressure from hand
pressure and are mutually reinforcing. Edren's seam lead is intentionally incomplete as a research direction,
but the result card must name the unlocked lead/next station action so “patterns mean somebody put
them there” is not mistaken for the whole mechanical instruction.

### Atlas flags for this batch

Begin all teaching entries Unreviewed. Pre-route Drift, Hive, Amber, Coral and Echo to a
`comprehension-check` filter without marking them Needs revision. Automated validation may flag a
missing teaching ID or target; it may not downgrade metaphorical prose by itself.

## Batch 5 — early/mid location clues

Manual review covered Bryn, Orsa, Vance, Talin, Nessa, Corrin, Dagg, Rook and Lys: 32 location pages.

**Overall result: keep.** These packets generally follow the desired evidence-first grammar. They
show enclosing ground, hard footing, smoke, seams, separate life pockets, material plates, toxic
breath, moisture reactions, cut growth, bending surfaces, consequential footing, visible approaches,
concentrated water, still grass and rewritten ground before drawing character-specific conclusions.
Their voices differ without concealing the searched-for world property.

Atlas comprehension checks, not pre-emptive revisions:

- `orsa_where_0`: confirm that repeated reuse/overnight occupation communicates high total Vitality
  rather than merely animal traffic;
- `nessa_where_1`: the ecological answer-to-poison inference is good character writing, but test it
  beside the condition label because it is less directly measurable than her other three;
- `dagg_where_2`: “long quiet intervals” plus large changes should be tested for the intended cycle
  property rather than read as generic danger;
- `lys_where_3`: the loose-page image is distinct and memorable, but verify the physical world clue
  survives without knowing Lys is a librarian.

No live-copy changes are recommended for Bryn, Vance, Talin, Corrin or Rook from this pass. This
batch should enter the atlas Unreviewed, with only the four lines above pre-routed to comprehension
checks.

## Batch 6 — specialist and late location clues

Manual review covered Bracken, Fen, Wren, Maud, Grimmond, Auber and Perren, in addition to the
previous Sabine pass.

| Traveller | Result | Audit |
|---|---|---|
| Bracken | **Good** | Hardness, expansion/contraction, ledges and pressure at seams are physical, distinct and armour-specific. |
| Fen | **Good** | Long sightline, crosswind on a string, separated living stands, concentrated water obstacles and repeatable interval form a coherent ranged-weapon hunt. |
| Wren | **Revise page 0 only** | Pages 1–4 concretely show moving air, dispersed shallow water, regrowth and cycle amplitude. “There is another line before the first closes” does not establish high openness without the condition label. |
| Maud | **Keep; comprehension-check pages 0–1** | Edge-holding and permanent bending do distinguish hard/ductile forms, but “one part / another part” should be tested in atlas context before revision. Pages 2–4 are legible. |
| Grimmond | **Good** | Darkness, rich narrow seams, load-bearing mass, confined depth and thin air are exceptionally cohesive and keep extraction ethics grounded in mine geometry. |
| Auber | **Good** | Salinity, bounded/standing water, thermal range, reactive seams, vapour and repeated separation are technically concrete; much stronger than Auber's current meeting. |
| Perren | **Good for endgame; retain comprehension gate** | Opposed pressures, framing and repeated evidence are visible before the epistemic critique. This intentionally asks more of a late player and should not be flattened into debug labels. |

Recommended `wren_where_0` draft for review, not live replacement:

> The ground stays open far enough to hold several routes in sight at once. Keep seeing the others
> after you decide which line to take.

Sabine remains the only full-set revision in this cluster; use the seven concrete drafts already
recorded in Batch 2 rather than editing her screenshot line alone.

## Batch 7 — implemented-six location clue integrity

Mara, Edren, Sela, Tovin, Halloway and Isolde's direct location pages are concise and mechanically
legible. Their early-campaign simplicity is useful beside the later packets: bright horizon, hard
stone, numbing cold, available water, open view, living growth, dark/fungal/confined/saline/cold/
still/regular world, workable heat/ductility, rising land and abundant stone all point toward the
intended condition without analysis-tier vocabulary.

One metadata mismatch needs correction: `tovin_about_isolde` is an intentional cross-diary Isolde
location clue, but it currently uses `clueIndex: 0` (Isolde's high Relief). Its prose says Isolde
“wanted stone she could see by” and provides no high-land evidence. Route it to Isolde clue index 1,
the high-Substrate condition. This preserves the authored prose and useful redundancy while making
the page honest. Do not rewrite the sentence merely to preserve the mistaken index.

## Batch 8 — whereabouts / relationship pages

Manual review covered all 39 live `whereabouts` pages. **Keep the set.** These pages mechanically
reveal that another traveller exists; they are not extra signature conditions, so they may describe
practice, relationship and likely habits without encoding a precise threshold.

The early brief pages—Mara on Sela, Tovin on Edren and Sela on Halloway—are sparse but useful at that
campaign stage and do not pretend to be complete directions. The later cast develops a strong web of
specific disagreements: protection versus fit, warning versus range, formation versus consent,
extraction versus support, containment versus endurance and evidence versus authorship. Reciprocal
pairs do not merely repeat one opinion from both sides.

Atlas requirements for this category:

- label the page **Word of someone**, never “location condition”;
- show author and `about` target together so relationship direction remains clear;
- validate every target exists and the page does not accidentally occupy a target signature slot;
- keep these pages in the continuous diary order rather than isolating them into a lore appendix.

No prose revision is recommended from this pass. Tovin's special Isolde cross-page remains a
`locationClue`, not part of this 39-page set, and its corrected clue index is covered in Batch 7.

## Batch 9 — worlds, sites, accounts and interpretive turn

Manual review covered all 14 `worldWorthWriting`, 9 `ruin`, 3 `account` and Perren's single `turn`
page. **Keep the corpus.** These categories are allowed more reflection because they do not ask the
player to reverse-engineer a traveller signature.

- World pages consistently propose a concrete exercise or remembered place: fixed line, reused
  floor, heat/soft ground, lost profitable binding, two exits, repair under scarcity, timed opening,
  bodily difference, repeated contact, costly rushing and visible warning.
- Site pages name observable built/natural evidence without promising the site was generated in the
  current world. Atlas presentation must state that collecting one reveals the site definition, not
  a hidden current location.
- Marrick, Grimmond and Ashe's accounts clearly expose who a successful report erased; their moral
  force follows a concrete omission, empty chamber or absorbed warning.
- Perren's `turn` appropriately refuses to invent a single conversion moment and is correctly kept
  outside recovered-memory mechanics.

Route `sela_world` (“Write yourself somewhere with weather”) to comprehension review because it is
the only world exercise whose intended observation remains mostly deferred to “you will understand.”
Do not mark it Needs revision until its result context is seen in the atlas. No other copy change is
recommended from this batch.
