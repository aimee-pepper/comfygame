# Current Design — Roster Progression and Dependency Guardrails

**Status:** implementation-facing order for content planning. The implemented six have settled
authored order. Later rows are reversible ordering placeholders until their signatures are authored
and measured; their relative system dependencies are current.

Authored order guides clue direction, page recovery priority, expected hand/vocabulary capability and
content validation. It is not a hard recruitment gate: a player who can satisfy a later signature may
find that traveller early when no earlier-band full match occupies that world.

## Story arrival bands

`storyArrivalBand` groups people intended to enter at roughly the same campaign time. It is hidden
authored structure, separate from the older descriptive `campaignPhase` strings:

| Band | Intended arrival cluster | Travellers |
|---:|---|---|
| 0 | Opening economy | Vance, Noll, Halloway |
| 1 | Opening exploration | Mara, Edren |
| 2 | Hand and formation hinge | Isolde, Sela, Bryn, Orsa |
| 3 | Mature field practice | Talin, Nessa, Corrin, Dagg, Rook, Lys |
| 4 | Equipment specialists | Bracken, Fen, Wren, Kestrel, Maud |
| 5 | Late infrastructure | Marrick, Sabine, Grimmond, Oda, Auber |
| 6 | Late interpretation | Ashe, Tovin, Perren |
| 7 | Endgame | Nine, Tam |

When several eligible full signatures match one world, the earliest represented band wins. Recovered
location clues and causally matching player writing break ties only inside that band; authored order
then stable ID resolve equality. A later band can still appear early when it is clue-eligible, fully
matches and no earlier-band candidate matches that world. New roster insertions author a band and a
unique order independently.

## Order and campaign phase

| Order | Traveller | Schema phase | Conditions | Main progression reason |
|---:|---|---|---:|---|
| 1 | Vance | `opening` | 1 | Opens rotating merchant stock and a gold destination through the Trading Post |
| 2 | Noll *(working name)* | `opening` | 2 | Gives finished surplus an honest material-recovery choice |
| 3 | Halloway | `opening` | 2 | Makes early world resources useful |
| 4 | Mara | `opening` | 1 | Introduces deliberate searching and measurement |
| 5 | Edren | `opening` | 2 | Points toward sites and diary-bearing ruins |
| 6 | Isolde | `startOfMid` | 2 | Required hand-progression hinge |
| 7 | Sela | `mid` | 3 | First hunt that exercises the expanded hand |
| 8 | Bryn | `early-mid` | 3 | First dedicated formation specialist |
| 9 | Orsa | `early-mid` | 3 | Adds social clue recovery before the cast becomes broad |
| 10 | Talin | `mid` | 3 | Introduces a deliberate plated-foe answer |
| 11 | Nessa | `mid` | 4 | Preparation and escape matter for most of the campaign |
| 12 | Corrin | `mid` | 4 | Capacity and light protection as material variety grows |
| 13 | Dagg | `mid` | 4 | Contrasts Talin with slow commitment and recovery |
| 14 | Rook | `mid` | 4 | Makes reach and opening exchange legible |
| 15 | Lys | `mid` | 4 | Cross-reference arrives when the page corpus needs it |
| 16 | Bracken | `mid` | 5 | Advanced armour after ordinary gear is understood |
| 17 | Fen | `mid` | 5 | Advanced physical ranged craft |
| 18 | Wren | `mid-late` | 5 | Adds tempo tools as encounters become denser |
| 19 | Kestrel | `mid-late` | 5 | Joins mature bestiary knowledge to material recovery |
| 20 | Maud | `mid-late` | 5–6 | Completes advanced physical equipment specialisation |
| 21 | Marrick | `late` | 6 | Long-fight formation support once parties are mature |
| 22 | Sabine | `late` | 7 | Opens the complete animal-companion branch |
| 23 | Grimmond | `late` | 7 | Opens deep material/site access |
| 24 | Oda | `late` | 7–8 | Channelworks follows physical weapon literacy |
| 25 | Auber | `late` | 8 | Distillery deepens an already-familiar essence economy |
| 26 | Ashe | `late` | 8 | Embodied emanation follows Channelworks vocabulary |
| 27 | Tovin | `late` | 8 | Last major systemic expansion: permanent realms |
| 28 | Perren | `late` | 9 | Reframes established diary reading and cult history |
| 29 | Nine | `endgame` | 9 | Late interpretive/identity arc after ordinary diaries are familiar |
| 30 | Tam | `endgame` | ≤10 | Held until their unique endgame act is real |

The roster remains expandable. New people are inserted where their human and mechanical contribution
belongs; they are not appended merely because a row number is available.

## Changes from the older worksheet

- Nessa precedes Corrin so field preparation is useful longer; they remain neighbours in practice.
- Wren and Kestrel separate the three equipment specialists instead of creating an uninterrupted shop
  block.
- Grimmond precedes Oda/Auber's deepest transformation chain, so advanced outputs follow access to
  advanced world resources.
- Tovin is late but not endgame. The player should have meaningful time to build an anchored-realm
  portfolio before Perren, Nine and the unresolved ending material.

## Hard dependency guardrails

1. **No self-keyed signature.** A traveller's signature may never require the focus taught by that
   traveller's diary.
2. **No future-only requirement.** Every condition must have at least one realistically available
   writing route before that row. Random world drops may offer shortcuts, but cannot be the sole path
   for a progression-critical traveller.
3. **Hand capacity must precede condition count.** Isolde's Scriptorium is the only current required
   named-traveller hinge. Later signatures assume the hand unlocked before them, never a future one.
4. **A station must have something to act on.** Opening Trading Post and Recycler act on first-expedition
   holdings and are deliberately cheap to establish; Library follows a page corpus; advanced shops
   follow ordinary gear; Distillery follows essence; Anchorage follows enough disposable worlds for
   permanence to mean something.
5. **Teaching ownership is singular.** A diary-exclusive focus or gambit component has one authored
   owner. Research must not quietly duplicate it.
6. **Clues point forward without enforcing sequence.** Earlier diaries should preferentially mention
   nearby/later people, but cross-links and accidental discovery preserve nonlinearity.
7. **One condition, one location page.** Additional diary pages justify themselves through teaching,
   relationships, sites, world observations or character development.

## Validation expected before any later signature ships

- schema-valid positive unique `authoredOrder` and a campaign phase;
- schema-valid nonnegative `storyArrivalBand` matching the table above;
- every condition can be deliberately written from vocabulary available before that order;
- no condition depends on the traveller's own teaching;
- blank-book accidental-match distribution is appropriate to phase, not forced to one universal
  percentage;
- a deliberate book can reach the signature with the hand expected at that phase;
- sensory clue prose states only what the condition actually guarantees;
- each condition has exactly one location page and the diary includes its exclusive teaching.

## Intentionally unresolved

- Exact signatures for everyone after Tovin.
- Tam's contribution and final order relative to any future endgame additions.
- Exact campaign density in hours or worlds between rows.
- Whether some optional travellers share a phase/order band in UI presentation. Authored order should
  remain unique internally even when the player experiences a nonlinear cluster.
