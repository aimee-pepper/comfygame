# Existing Six Travellers — Design Audit

**Status:** Audit completed; current directions consolidated in `traveller-identities-existing-six-current.md`  
**Scope:** Mara, Edren, Sela, Tovin, Halloway and Isolde  
**Compared:** live `travellers.json`, station/research data, `cast-roster.md`, `the-cast.md`, and
`traveller-template.md`

## Outcome

**Process update:** Do not finalize these six separately. Their recommendations are inputs to a
whole-roster pass so names, roles, teachings, signatures, diaries and progression can be approved as
one comprehensive cast.

The six meetings are the strongest part of the current cast. Each traveller is found doing
something characteristic, each has a distinct rhythm, and none reads like a quest dispenser. The
cast does **not** need wholesale rewriting.

The incomplete parts are structural:

1. The newer roster assigns all six a progression purpose, but only Mara, Halloway and Isolde have
   implemented stations. Edren, Sela and Tovin still lack their planned buildings.
2. No explicit campaign order exists in traveller data, despite order governing reachability and
   the proposed rune-pity system.
3. Five planned exclusive teachings are absent. Tovin alone teaches a focus, and it is the old
   placeholder `verdigris_bloom`, not his planned **Drift**.
4. Existing diaries range from 2–7 pages. Only Sela and Tovin reach the ordinary 5–10-page target,
   and Tovin's count includes a clue about Isolde rather than a fuller arc of his own.
5. Several clue passages no longer truthfully describe the condition they test. This is the most
   important content-quality problem because the game promises clues that are partial but never
   wrong.
6. One clear continuity error remains: Sela calls Halloway **“a man”** while Halloway’s implemented
   meeting consistently uses she/her.

## Recommended authored order

| Order | Traveller | Phase | Conditions now | Recommendation |
|---|---|---:|---:|---|
| 1 | **Mara** | Opening | 1 | Keep first; she introduces deliberate search and analysis |
| 2 | **Edren** | Opening | 2 | Keep early; ruins and diary discovery feed the search loop |
| 3 | **Halloway** | Opening | 2 | Keep early; first material-to-equipment payoff |
| 4 | **Isolde** | Start of mid | 2 | Keep as the required hand-progression hinge |
| 5 | **Sela** | Mid | 3 | Keep after pencil access; her three-condition search proves the expanded page |
| 6 | **Tovin** | Late | 4 | Keep last of the six, but eventually raise toward 7–8 conditions |

This order is already implicit in the current roster. Make it explicit in data before rune pity or
vocabulary reachability depends on it. **Recommendation:** do not use raw array order as design
state; add an authored order field and a phase field.

## Side-by-side status

| Traveller | Voice | Honest signature | Diary | Progression purpose | Overall |
|---|---|---|---|---|---|
| **Mara** | Strong | ⚠️ Peak/shadow mismatch | 2 pages; thin | Survey Post built; teaching absent | Expand and repair clue |
| **Edren** | Strong | ⚠️ Hard ≠ worked; cold ≠ dark | 4 pages | Reliquary absent; teaching absent | Clarify clue language and role |
| **Halloway** | Strong | Strong | 3 pages; thin | Blacksmith built; teaching absent | Mostly additive work |
| **Isolde** | Strong | ❌ Prose no longer follows thresholds | 3 own pages + external redundancy | Scriptorium built; teaching absent | Highest-priority clue repair |
| **Sela** | Strong | ⚠️ Water wording overclaims motion | 5 pages | Shed absent; teaching absent | Resolve calling/building fit |
| **Tovin** | Strong | Mostly strong | 7 pages, but late arc still thin | Anchorage absent; wrong teaching | Expand hunt and replace placeholder |

---

## 1. Mara — surveyor

### What already works

- Her stick-and-sighting opening communicates her trade before she names it.
- Her dry precision, persistence and need for fixed points give her an immediate emotional shape.
- The Survey Post and field instruments now provide an excellent reason to recruit her.
- Her `shadow` and `swiftness` lean reads as observation, positioning and lightness rather than a
  generic combat class.

### Gaps and conflicts

- Her sole condition is `illumination.peak ≥ 60`, but **“There is no shadow anywhere”** describes a
  high illumination floor or uniform diffuse light. A bright peak can coexist with deep shadow.
- She has only two authored pages: her location clue and a whereabouts page about Sela.
- **Bluff**, her current planned exclusive focus, is not taught by her diary.
- `leansToward` includes `worldWorthWriting`, but she has no page of that kind.

### Recommendation

Keep her identity, meeting, signature difficulty and Survey Post. Discuss one of two clue repairs:

1. Keep the peak-brightness mechanic and rewrite the passage around glare, a fixed bright source or
   a horizon too bright to sight along; or
2. Keep “no shadow anywhere” and change the condition to a reading that actually represents
   pervasive illumination, if the pressure model exposes one reliably.

**Recommended diary target: 6 pages** — 1 location, the existing Sela whereabouts, Bluff, a
world-worth-writing observation, a surveyed site/landmark, and one personal or cross-cast fragment.

### Coherence sentence

> Because Mara was a **surveyor**, she measures unstable places and records what makes them
> legible, which is why recruiting her gives the player **field instruments and better mapping**.

---

## 2. Edren — archaeologist

### What already works

- His meeting is exceptionally coherent: floor, trowel, tomorrow, and the repeated idea that
  everywhere used to be somewhere.
- His diary already has the best functional assortment among the early cast: two location clues, a
  ruin, and a research lead.
- The newer separation of Edren’s **Reliquary** from Lys’s **Library** is correct. Edren is about
  sites in the field; Lys is about pages and records at home.

### Gaps and conflicts

- `substrate.form.hard ≥ 35` guarantees hard material, not **worked** stone or a buried floor.
- `thermal.floor ≤ 25` guarantees cold, not that **“the dark comes with it.”**
- The Reliquary and its site-focused branch do not exist in station data.
- His planned **Ruin** teaching is absent.
- Older live documents still describe the unattached Library as Edren’s; the current roster assigns
  it to Lys. Engineering data currently assigns it to nobody.

### Recommendation

Keep the hard/cold two-condition opening signature, but make both passages describe only what those
conditions guarantee. Preserve worked floors and darkness as Edren’s observations elsewhere in
the diary unless matching conditions are added.

**Recommended diary target: 7 pages** — 2 location, existing ruin and research lead, Ruin as his
exclusive teaching, one whereabouts/cast connection, and one archaeological fragment that changes
how the player reads the Sundering or the Atlas.

Build the Reliquary only after its distinction from the Library is reflected in the station and
research plans.

### Coherence sentence

> Because Edren was an **archaeologist**, he recognises inhabited places beneath what the worlds
> became, which is why recruiting him gives the player **better site discovery and interpretation**.

---

## 3. Halloway — smith

### What already works

- Her voice is economical and concrete. The kept fire is both an action and a complete emotional
  image.
- Both clues closely match their mechanics: strong heat and ductile substrate.
- The Blacksmith exists, is built by Halloway, and gives her an immediate material payoff.
- Two free Force points are a clear, credible starting lean.

### Gaps and conflicts

- She has only three pages: two location clues and one world worth writing.
- Her planned **Gold ore** teaching is absent.
- Sela’s page calls Halloway “a man.” This is a continuity defect, not a design choice.
- Her broader cast relationships are absent despite the fire providing an obvious motif for people
  remembering or seeking her.

### Recommendation

Preserve her meeting and signature. Correct Sela’s pronoun only when this batch is approved for
revision.

**Recommended diary target: 6 pages** — 2 location, the existing worthwhile-world page, Gold ore,
one forge/resource site, and one relationship or kept-fire fragment. Her diary should remain one of
the terser books; concise writing suits her.

### Coherence sentence

> Because Halloway was a **smith**, she understands heat, workable ground and the discipline of
> staying with a process, which is why recruiting her gives the player **the forge and reforging**.

---

## 4. Isolde — calligrapher

### What already works

- Her meeting is the clearest tutorial-through-character scene in the cast. “You can only write
  smaller” states the page-space progression without sounding like UI copy.
- Her insistence on line, light and a stable table is precise and memorable.
- The Scriptorium, hands and page lens make her genuinely load-bearing.
- Tovin’s page gives her independent clue redundancy, appropriate for the only required traveller.

### Gaps and conflicts

- Her repaired conditions are `relief.peak ≥ 55` and `substrate.peak ≥ 55`. Her passages instead
  claim stone above and below, total stillness, and rock that emits or holds light. None of those
  properties follows from the current thresholds.
- The signature is mechanically reachable now but narratively misleading. Because she is required,
  this is the highest-priority clue repair.
- She has only three pages of her own: two location clues and one hand/progression observation.
- Her settled exclusive focus is **Hush** (air that does not move), but no page teaches it.
- `leansToward` says location/world-worth-writing only, leaving no preference for teaching or
  relationships.

### Recommendation

Keep her current reachable thresholds until an alternative is proven safe, and rewrite the two
location passages to describe exceptional vertical relief and unusually abundant substrate. Retain
her desire for still air and steady light in her voice, meeting, Hush page and non-location diary
material rather than falsely presenting those as current signature conditions.

**Recommended diary target: 7 pages** — 2 location, the existing hand page, Hush, one penmanship or
compound knowledge page, one relationship page, and one site/world observation. Keep Tovin’s
external reference as additional redundancy, not part of her own seven.

### Coherence sentence

> Because Isolde was a **calligrapher and teacher**, she understands how a hand changes what can fit
> into a world, which is why recruiting her gives the player **smaller writing, compounds and the
> page lens**.

---

## 5. Sela — wanderer / proposed forager

### What already works

- Her opening refuses the static “NPC waiting to be collected” posture: she is already moving and
  asks the player to keep up.
- Her humour and resistance to destinations are distinct from every other traveller.
- Three conditions make her a good first test of the pencil’s expanded page.
- Five pages already meet the ordinary diary range and contain location, whereabouts and a world
  worth writing.

### Gaps and conflicts

- The live character calls her **a wanderer**; the new roster calls her **a forager** and gives her
  the Forager’s Shed. Changing the calling would make the mechanic tidier but flatten the strongest
  part of her identity.
- `hydrology.available ≥ 30` guarantees usable water, not **water everywhere** or that none of it is
  still. The passage overclaims both quantity and motion.
- The Forager’s Shed does not exist in station data.
- Her planned **Pond** teaching is absent.
- Her Halloway whereabouts page has the pronoun error noted above.

### Recommendation

**Keep “wanderer” as her calling.** Let foraging be knowledge acquired by a life spent walking, not
the noun that replaces that life. **Later resolution, 9 Aug 2026:** her station is **The Wayfarer's
Table**, a shared place for routes, provisions and field knowledge rather than a counter or shop.
The Forager's Shed name is superseded.

Rewrite the water passage around accessible/running water only if the reading guarantees it; do not
claim motion from generic availability.

**Recommended diary target: 7 pages** — 3 location, existing Halloway whereabouts and worthwhile-
world page, Pond, and one site/route or relationship fragment.

### Coherence sentence

> Because Sela was always a **wanderer**, she knows how to find food, water and a route through an
> unfamiliar place, which is why recruiting her gives the player **fieldcraft and organic-harvest
> knowledge**.

---

## 6. Tovin — binder

### What already works

- He is the character most directly tied to the player’s act of writing worlds.
- His meeting contains the clearest statement of the game’s temptation: knowing a world is too
  greedy does not stop someone staying for what they want.
- Dark, fungal, rich substrate and enclosure form a coherent place and mostly match their passages.
- Combining Tovin with the proposed Wright is thematically strong: the Anchorage is binder’s work.
- Seven authored pages already give him the largest current diary.

### Gaps and conflicts

- Four conditions are too few for the late traveller who unlocks permanent worlds. The agreed cap
  is ten; the previous recommendation of roughly 7–8 remains a better target for him.
- His current seven-page count comprises four personal location clues, one clue about Isolde, one
  clue about Edren and one symbol page. It says little about his own eleven written/four held worlds,
  failures, relationships, or anchoring knowledge.
- His symbol page teaches placeholder `verdigris_bloom`, while the roster assigns him **Drift**.
- The Anchorage and sustain branch do not exist.
- “The walls are worth more than the room” may imply valuable ore more specifically than generic
  high substrate peak guarantees. It is closer than the other mismatches but should be verified.

### Recommendation

Keep his identity and meeting. In the later signature-design pass, expand him to **7–8 coherent
conditions**, staying below the absolute ten-condition cap and using vocabulary acquired from the
earlier cast. Do not add conditions merely to hit a number; the final place should read as one
world a binder plausibly chose and regretted.

Expect his finished diary to exceed ten pages: 7–8 personal location pages, Drift, the existing
Edren and Isolde connections, and several pages about written/held/lost worlds or anchoring. The
exact total should follow the material rather than a quota.

Replace `verdigris_bloom` with Drift only after verifying that Drift’s vocabulary role, acquisition
timing and effect are settled.

### Coherence sentence

> Because Tovin was a **binder**, he knows how written worlds drift, fail and can be held, which is
> why recruiting him gives the player **tethers, anchoring and the sustain economy**.

---

## Batched recommendations for review

### A. Preserve all six core identities and meetings

No wholesale rewrites. Expand around what is already strong.

### B. Lock the authored order

**Mara → Edren → Halloway → Isolde → Sela → Tovin.** Add explicit order and phase fields rather
than relying on JSON position.

### C. Repair clue honesty before adding pages

Review Mara, Edren, Sela and especially Isolde passage-to-condition alignment. Prefer prose repair
where the mechanical signature is already balanced and reachable; change mechanics only when the
fiction is essential and reachability can be proven.

### D. Keep Sela a wanderer

Her foraging contribution should follow from her wandering. Do not replace the identity that makes
her voice work merely to match a building label.

### E. Expand diaries to distinct shapes

| Traveller | Current authored pages | Recommended initial target | Shape |
|---|---:|---:|---|
| Mara | 2 | 6 | Small, observational, interconnected |
| Edren | 4 | 7 | Site- and history-heavy |
| Halloway | 3 | 6 | Terse, practical, material |
| Isolde | 3 own + outside reference | 7 own | Teaching, hand and relationships |
| Sela | 5 | 7 | Routes, people and worthwhile worlds |
| Tovin | 7 | Longer than 10 when signature expands | Binder history and the densest cast links |

These are starting targets for drafting, not universal quotas.

### F. Restore their planned progression payloads

- Mara — Survey Post ✅; **Bluff** absent
- Edren — **Reliquary and Ruin** absent
- Halloway — Blacksmith ✅; **Gold ore** absent
- Isolde — Scriptorium ✅; **Hush** absent
- Sela — **Wayfarer's Table/fieldcraft contribution and Pond** absent
- Tovin — **Anchorage and Drift** absent; placeholder teaching conflicts

### G. Fix the unambiguous continuity error

Sela’s Halloway page should use she/her. This is safe editorial correction, but it remains unedited
until the batch is approved under the design-review rule.

## Recommended next discussion order

1. Approve or challenge recommendations A–G.
2. Repair the four questionable clue passages as one prose/mechanics batch.
3. Fill complete traveller sheets for the six, including page lists and campaign order.
4. Draft the missing pages one diary at a time, beginning with Mara and ending with Tovin.
5. Hand approved content and schema additions to engineering.
