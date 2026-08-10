# Tutorial later-system hooks — exact slice 6

**Status:** Implementation-ready final tutorial slice. A hook ships only with its owning playable
system; absent systems leave their lesson IDs tolerant and unseen.  
**Updated:** 9 Aug 2026

This slice teaches decision boundaries, not catalogue contents. It never translates diary prose,
reveals a hidden target, chooses an anchor route, identifies a curio automatically or recommends an
optimal worker.

## Priority and suppression

These hooks have no global sequence. Each becomes eligible only in its owning context, and the
existing one-card-per-screen rule chooses the lowest priority number on that screen. Encounter,
loot/spillover choice, imminent-collapse warning, anchor settlement and destructive confirmation
always outrank teaching. `Not now` returns only in the same owning context.

| Priority | Stable ID | Eligible when | Complete when | Anchor and copy |
|---:|---|---|---|---|
| 1 | `writing.complete_clue_set.v1` | First traveller location set becomes complete and that diary is visible in Library | Writing Desk opens with the complete diary available for reference | Complete diary: **You have every location passage for {traveller}.** A world matching all of them guarantees their appearance on the next eligible bind, but the Library will not translate the prose into marks for you. |
| 2 | `base.first_build_site.v1` | First station build site is affordable or first opened deliberately | Its exact build preview has been opened | Build preview: **People make new places possible.** Building spends the shown Base resources permanently; preview names the keeper, function and every cost before confirmation. |
| 3 | `world.first_instrument.v1` | First carried instrument's subject is measurable in an active world | Its subject is surveyed/measured once | Instrument readout: **This instrument measures {subject}.** It reveals what its precision allows in this world; it does not change the world or explain an unlearned cause. |
| 4 | `knowledge.first_curio.v1` | First unidentified curio enters carried or Home inventory | Player opens its Try, Analyse or Identify choices | Curio choices: **Unknown objects can be tried, analysed or identified.** A valid attributable use may teach the family; recognition is lasting knowledge, not a label attached only to this copy. |
| 5 | `world.first_full_satchel.v1` | First real keep/leave loot decision appears because carried capacity is full | Player commits that exact decision | Loot choice: **The satchel is the expedition limit.** Choose what travels; Home storage is separate, and nothing shown here is discarded without this decision. |
| 6 | `world.first_collapse.v1` | First run reaches zero Stability and the ordinary collapse warning is acknowledged | Player spends another world turn, returns, or is carried out | Stability/floor: **Zero begins collapse; it is not an instant ending.** Warned floor may fail as turns pass. A portal still returns the full haul while a route remains. |
| 7 | `anchoring.three_routes.v1` | Anchorage first opens with at least one route genuinely available | Player opens all currently available route disclosures | Route selector: **Every route makes the same permanent kind of realm.** Born-anchored pays at binding, an Atlas Seam is found in-world, and an Anchor Frame is carried and placed; availability and costs differ. |
| 8 | `anchoring.worldwork.v1` | First anchored realm exposes assignment | Player opens one companion's contribution preview | Assignment preview: **Worldwork pays sustain first.** Surplus supports one chosen discovered renewable yield. Assignment changes only on expedition return and takes that person away from Party and Home work. |

## Exact boundaries

### Complete clue guarantee

- Eligibility requires the complete authored location set, not every page in a traveller's longer
  diary.
- “Next eligible bind” respects already-found travellers and any explicit one-at-a-time guaranteed
  traveller queue. It does not promise several complete diaries will all spawn simultaneously.
- The lesson may emphasize matching prose in Preview/History, but never identifies the required
  focuses, qualifiers or values.

### Buildings

- Buildability is never a tutorial unlock. The traveller, station definition and exact resources
  must already make the site real.
- Completion is opening the exact preview, not spending. Declining or saving resources remains a
  fully taught choice.
- Every station with more than one paid action keeps a permanent **How this place works** section
  containing: keeper/assignment effect, effective tier, Home discount if any, destructive actions,
  and what persists after leaving.

### Instruments and analysis

- The card names only the instrument's authored subject and current precision.
- A field reading and World History use the same analysis gate. Improving an instrument may reveal
  more in old records; it never rewrites stored facts.
- No instrument hook fires merely because an instrument is owned at Home; it must be carried into a
  world where its verb is available.

### Curios

- `Try` appears only where the current action has a valid attributable effect; random consumption
  with no learning route is not teaching.
- `Analyse` reports only the current instrument/station gate. `Identify` uses the Storehouse path.
- The tutorial does not recommend the safest route, reveal a key's destination or consume the item.

### Satchel and collapse

- A warning before a real loot decision may explain capacity, but cannot auto-drop the weakest or
  least rare object.
- Items packed from Home remain protected according to the current expedition outcome rules; the
  card must not simplify this into “everything can be lost.”
- Collapse teaching uses the real warned-tile/crumble pipeline and current map. It adds no grace
  turn, route reveal or portal relocation.

### Anchoring and Worldwork

- Unavailable routes remain visible only if ordinary Anchorage UI already shows a concrete unlock
  reason; tutorial copy cannot expose a hidden Seam or grant a Frame.
- Route disclosure always names that all three produce the same durable realm and distinguishes
  when payment occurs.
- Worldwork preview shows the exact contribution formula and projected sustain result already
  settled in `companion-worldwork-current.md`; it does not rank people as “best.”
- Assignment is a three-way location choice: Party, Home or anchored realm. Home discount and realm
  production can never apply simultaneously.

## Field Notes groups

- **Writing:** Complete location evidence.
- **Worlds:** Measuring a subject; Full satchel; Collapse; Three anchoring routes; Worldwork.
- **People:** People enable buildings; Assignments.
- **Base:** Building permanently; How each complex station works; Curio choices.

Combat hooks remain in `tutorial-combat-recruit-slice-current.md`. Do not duplicate them here merely
because a station later teaches a combat recipe.

## Debug and verification

1. Complete two traveller clue sets together; only the real guarantee queue is described and no
   multi-traveller influx is promised.
2. Open an affordable build preview, decline, save/reload and build later; the lesson completes at
   preview while the spending decision remains untouched.
3. Carry instruments of different precision into old/new worlds; card and History never exceed the
   same gate.
4. Exercise Try/Analyse/Identify, including an invalid Try context; no item is consumed or family
   learned merely by lesson eligibility.
5. Fill satchel with protected Home items plus new loot; preview and commit name exact retained and
   displaced stacks.
6. Trigger zero Stability beside warned floor, portal and encounter; ordinary warnings/outcomes win
   card priority and no safety state changes.
7. Open Anchorage with one, two and three available routes; copy never claims an unavailable route
   can be selected.
8. Assign the same companion Party → Home → realm across expedition returns; only one benefit is
   active after each saved transition.
9. Replay every hook from Field Notes without recreating loot, build, collapse, curio or anchor
   state.
10. Unknown lesson IDs and removed owning systems round-trip without blocking a save.
