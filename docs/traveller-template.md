# Named Traveller Template

**Status:** Current design tool — session 18  
**Purpose:** Create and review named travellers consistently before they are added to
`Sources/Content/Data/travellers.json`.  
**Derived from:** Mara, Edren, Sela, Tovin, Halloway and Isolde.

This is a design worksheet, not a demand that every traveller receive the same amount of lore.
The required sections define the playable search-and-recruit loop. Optional sections should be
used only when they sharpen the person or connect them to another part of the cast.

## Design principles

1. **Named travellers are people the player looks for.** Their diary and signature distinguish
   them from random companions, who are people the player happens to meet.
2. **The hunt is the recruitment cost.** A named traveller does not also demand payment or a want.
3. **The clue is prose; the condition is machinery.** The player reads a remembered place, never a
   threshold or system label.
4. **What they unlock follows from what they knew.** Calling, building, teaching, combat lean and
   diary content should feel like parts of one life.
5. **A calling creates a lean, not a class prison.** Anyone can grow through the shared combat
   trees after recruitment.
6. **Every traveller changes something.** They must add a useful capability, body, technique,
   piece of knowledge, relationship or story development—not merely increase the roster count.
7. **Voice lives in choices and observations.** Avoid biography delivered as exposition. The
   existing meetings work because Mara measures, Edren digs, Sela keeps walking, Halloway tends a
   fire, Isolde rules lines and Tovin reads the authorship in a sky.

---

# Traveller Sheet

## 1. Identity — required

| Field | Entry |
|---|---|
| **Status** | Proposal / approved / implemented |
| **Name** | |
| **ID** | Lowercase implementation identifier |
| **Pronouns** | |
| **Calling** | What they did or were before the Sundering |
| **Cast type** | Trade / fighter / strange |
| **One-line blurb** | The compact roster description; ideally two linked sentences |
| **Map icon** | Prefer an existing symbol unless a unique one materially helps recognition |
| **Campaign phase** | Opening / start of mid / mid / late / endgame |
| **Authored order** | Their position in traveller progression and rune pity |
| **Required?** | Normally no; explain any yes because it can block a campaign |

### Voice anchors — required

Write three short anchors, not a biography:

- **Habit:** What are they doing when nobody needs anything from them?
- **Attitude:** How do they meet uncertainty, danger and other people?
- **Tension:** What belief, want or contradiction keeps them from feeling solved on arrival?

### Voice boundaries — optional

- Words, rhythms or kinds of humour they favour:
- Things they would never say or explain directly:
- A line from their meeting that best proves the voice:

## 2. Place in the game — required

Complete the fields relevant to the cast type; write **none by design** rather than leaving an
accidental blank.

| Field | Entry |
|---|---|
| **Reason to seek them** | What makes the player actively want this person? |
| **Building / station** | Trade travellers usually unlock one; fighters and strange travellers may not |
| **Building function** | What new verb or progression route appears? |
| **Research relationship** | Branch, starting nodes, or none by design |
| **Exclusive teaching** | Precise focus, gambit component, technique, or other knowledge |
| **Combat starting lean** | Shared-tree branch IDs and free starting points |
| **Staffing role** | What posting them does, if they own a station |
| **Anchored-world role** | Only if they have a distinctive one beyond normal assignment |

### Coherence sentence — required

> Because they were **[calling]**, they **[behaviour/knowledge]**, which is why recruiting them
> gives the player **[gameplay contribution]**.

If this sentence is strained, the rewards are probably attached to the wrong person.

## 3. Search signature — required

### Difficulty budget

| Field | Entry |
|---|---|
| **Target phase** | |
| **Hand available** | Rough charcoal / Brush / Fountain pen / refined + compounds |
| **Condition count** | Opening 1–2; mid 3–5; late 6–9; endgame 9–10; absolute maximum 10 |
| **Required vocabulary** | Every focus/qualifier needed to deliberately write the signature |
| **Acquisition check** | Confirm every required word is obtainable before this authored order |
| **Accidental-match target** | To be set during traveller-pacing work; never rely on intuition alone |

### Conditions and clue passages

| # | Mechanical condition | Traveller’s prose | Why this place fits them |
|---|---|---|---|
| 1 | | | |

Rules:

- Every condition must materially narrow the world; do not use ordinary baseline values as clues.
- Every condition must be deliberately writable by the intended phase.
- The passages should form one memorable place when read together, not a shopping list of weather.
- A required traveller receives stricter reachability and redundancy tests.
- Difficulty comes from literacy and composition, not opaque rarity or arbitrary run counts.

### Signature summary — required

Write the place in one sentence. If the summary is incoherent, the mechanically valid conditions
do not yet describe a believable destination.

> **[Name] is in a world that is…**

## 4. Diary packet — required

Most named travellers have **5–10 authored pages**. Late travellers may have longer diaries when
their signatures require more location clues. The packet should feel like an assortment from a
life, not several versions of the same hint; added location pages do not replace knowledge, sites,
relationships and other kinds of writing.

### Location material

List the diary page or passage carrying each signature clue and any second diary that independently
names this traveller. Pages guide the search; possessing them is not currently a gate.

| Page ID | Author | Kind | About / clue | Prose purpose |
|---|---|---|---|---|
| | | locationClue | | |

### Other pages

Use only pages that do at least two jobs: develop voice or relationships **and** deliver a valid
page unlock such as a whereabouts clue, research lead, site, focus, or world worth writing.

| Page ID | Kind / unlock | What it reveals about the writer | Cross-link or preferred world |
|---|---|---|---|
| | | | |

### Diary arc — required

- **What the first likely page makes us think:**
- **What later pages complicate or overturn:**
- **What remains unresolved after recruitment:**

The pages can be found out of order. The arc must be interesting in fragments and must not depend
on a single fixed reveal order unless the system explicitly supports it.

### Working page mix — recommendation for the pacing audit

For an ordinary **5–10 page** diary, begin testing with:

- **2–5 location pages**, collectively describing the full signature;
- **1 knowledge page**, teaching a precise focus, gambit component, research lead or comparable
  piece of expertise;
- **2–4 varied pages** drawn from sites of note, another traveller's whereabouts, a world worth
  writing, relationships and personal fragments. A personal fragment should still carry a valid
  mechanical page purpose rather than becoming lore-only loot.

This is a starting composition, not a fixed quota. Different diaries should have different shapes.

### Location-clue scaling — settled structure, tuning still to test

Keep the implementation's current **one location page per signature condition** relationship. Each
page gives the player one discrete deduction, and a late traveller is allowed to have a longer book
because their search is correspondingly more involved.

No traveller signature should exceed **10 conditions**. A ten-condition traveller therefore has ten
location pages plus whatever knowledge, site, whereabouts, world and character pages their diary
needs. Do not compress several mechanical conditions into one page merely to meet the ordinary
5–10-page range.

## 5. Meeting scene — required

The existing structure is the standard:

1. **Opening:** The player finds them already doing something characteristic.
2. **Three optional questions:** Each reveals a different facet; none is required to recruit.
3. **Offer:** One line in the player’s voice.
4. **Accepted:** Their decision and a small physical action.
5. **Declined:** They remain in the world and acknowledge the player leaving.

| Beat | Draft |
|---|---|
| **Opening** | |
| **Question 1** | |
| **Reply 1** | |
| **Question 2** | |
| **Reply 2** | |
| **Question 3** | |
| **Reply 3** | |
| **Offer** | |
| **Accepted** | |
| **Declined** | |

Meeting checklist:

- The opening visually proves the calling or personality before explaining it.
- Each answer sounds like this person and could not be reassigned unchanged to another traveller.
- At least one answer locates them emotionally after the Sundering.
- At least one answer reveals useful knowledge, a relationship, or a changed interpretation.
- Recruitment is warm enough for the game without erasing grief, strangeness or disagreement.
- The scene is concise enough to encounter while world stability is still running.

## 6. Cast connections — optional, usually valuable

| Connection | Entry |
|---|---|
| **People they knew** | |
| **Who mentions them** | Gives clue redundancy and makes the cast feel connected |
| **Whom they mention** | |
| **Building/economy dependency** | |
| **Conflict or affinity at home** | Reserve for observable use; do not write unused lore |

## 7. Implementation handoff — required before build

| Field | Entry |
|---|---|
| `id`, `name`, `calling`, `icon`, `blurb` | |
| `signature[]` and passages | |
| `leansToward[]` | |
| `lean{}` | |
| `meeting{}` | |
| `isRequired` | |
| Diary page records | |
| Station / research / teaching references | |
| Authored order / campaign phase | Requires schema support if not yet present |

### Validation before approval

- [ ] Signature fits the page and vocabulary available at its authored order.
- [ ] Each clue has a measured useful prevalence; combined accidental-match rate is tested.
- [ ] Required travellers have redundancy and cannot deadlock a save.
- [ ] Every diary page has exactly one mechanical unlock.
- [ ] Page IDs, clue indices and cross-references resolve.
- [ ] Exclusive teachings do not duplicate another traveller or ordinary acquisition route.
- [ ] Building ownership agrees across roster, station data and research data.
- [ ] Combat lean uses valid shared-tree branches and is free starting identity, not spent levels.
- [ ] The traveller has a clear player-facing reason to recruit them.
- [ ] Meeting scene and diary fragments share a recognisable voice.
- [ ] No field is placeholder prose when the traveller is marked implemented.

## 8. Approval record

| Area | State | Notes |
|---|---|---|
| Identity and voice | Draft / approved | |
| Gameplay contribution | Draft / approved | |
| Signature and pacing | Draft / approved | |
| Diary packet | Draft / approved | |
| Meeting scene | Draft / approved | |
| Engineering handoff | Not ready / ready / built | |
