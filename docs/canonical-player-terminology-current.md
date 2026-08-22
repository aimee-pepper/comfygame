# Canonical game terminology — current

**Status:** Game Design implementation authority; immediate P0 copy-consistency correction  
**Machine authority:** `canonical-game-terminology.json`  
**Owner:** Game Design owns concept names; Engineering applies them to every human-readable surface  
**Updated:** 22 August 2026

## Non-negotiable rule

One game concept has one canonical name everywhere. The player UI, DEBUG tools, accessibility, internal wiki,
tests, human-readable logs and current documentation do not maintain separate vocabularies.

Code identifiers and persisted keys may remain technical where changing them would risk save compatibility,
but they are identifiers, not alternative names. When a DEBUG tool genuinely needs one, show the canonical
name first and the raw key only as secondary metadata:

```text
Gold
Internal ID: resource.gold
```

Never show only `resource.gold`, `materialSample`, `receiptLine`, `node`, `profile` or another implementation
category where a canonical concept exists. A more granular implementation type appears as a property of the
same concept, not a renamed concept: `Creature material · Hides · Fine`, not `material sample`.

## Canonical vocabulary

| Concept | Use everywhere | Retire as a human-readable substitute |
|---|---|---|
| a symbol written on a page | **Sigil** | mark, rune |
| what a sentence describes | **Subject** | target |
| the main thing said about that subject | **Focus** | source, cause |
| a narrowing word | **Modifier** | qualifier |
| an assembled reusable sigil | **Compound** | atom bundle, precomposed symbol |
| predicted result before binding | **World preview** | projection |
| one generated input such as Hydrology or Light | **World pressure** | pressure value, generated input |
| ordinary campaign generation | **Normal world** | ordinary world |
| current spendable currency | **Essence available** | Essence runway, spendable runway |
| estimated count affordable at a stated cost | **Worlds you can afford** | binding runway, authored binds remaining |
| a world whose page the player composed | **World written by you** | authored bind |
| a station/research graph entry | **Upgrade** | node |
| a combat-tree graph entry | **Skill** | node |
| a gear-building choice | **Construction** | profile |
| persisted outcome presented to a person | **Expedition record** | receipt |
| historical fact captured at an event | **Saved at the time** | frozen |
| compatibility content a person must understand | **From an older save** | legacy |
| permanent knowledge recovered this expedition | **Writing found** | marks, current draft |
| a newly recruited traveller | **Joined the village** | returned |
| experience gained | **XP earned** | progress, party total |

This table governs capitalization and pluralization, not only rough meaning. Existing approved proper nouns,
resource names, item names, station names and character names remain unchanged.

## Return recap correction

The photographed return header currently says both **Returned through a portal** and **You returned through a
portal**. Keep the exact outcome title; replace the second line with a rules-frozen statement about the actual
world at departure.

New outcomes freeze `WorldDepartureState` from the active run before it is cleared:

| State | Rules test | Exact ordinary copy |
|---|---|---|
| `holding` | no crumbled or cracking ground and collapse has not begun | **The world was still holding together when you left.** |
| `cracking` | cracking ground exists but none has fallen | **Cracks were spreading when you left.** |
| `breaking` | at least one ground tile has fallen but the party was not ejected by its own tile | **Parts of the world had already fallen away when you left.** |
| `collapseReachedParty` | the party's current tile fell and caused the return | **The collapsing ground finally reached the party.** |

Portal, Waystone, defeat, collapse and abandon all use the same frozen state vocabulary. Outcome kind still
owns the title and loss rules. Old saves lacking this field keep their saved reason rather than guessing from
current state.

### Permanent gains panel

The current prototype is incorrect, not merely unclear:

- `N marks / current draft` is recovered knowledge, not a mutation of the player's current Writing Desk page;
- `N returned` is newly recruited people, not the departure party coming back; and
- `+N progress / party total` aggregates level gains under a meaningless category.

Replace **KEPT WITH YOU / Writing & travellers** with **PERMANENT GAINS / Knowledge, people & party**. Its
compact cells are data-dependent:

| Receipt fact | Exact display rule |
|---|---|
| diary pages + other recovered writing > 0 | `1 piece of writing found` / `Added to the Library`; pluralize naturally |
| no recruited traveller | `No one joined the village`; never show `0 returned / none` |
| recruited travellers > 0 | `1 person joined the village` or `{N} people joined the village`; names underneath |
| every active member earned the same XP | `+{N} XP each`; names underneath |
| XP differs | `Party earned XP`; each person's exact `+N XP` remains in the Progress detail |
| level gains > 0 | `{N} level-up(s) across the party`; supplemental to XP, never called progress |

Omit an empty writing cell rather than showing `0 marks`. People may keep the explicit all-clear sentence
because `No one joined the village` answers a real outcome question.

## Current release-facing inconsistencies

The first implementation sweep covers these exact surfaces; this is a correction queue, not permission for a
cosmetic redesign:

| Surface | Current wording | Canonical replacement |
|---|---|---|
| Return recap | marks / current draft / returned / progress / party total | rules above |
| World preview | Projection | World preview |
| Base construction preview | authored bind / runway / binds | world written by you / Essence available / worlds you can afford |
| Research purchase preview | node prerequisite / authored bind / runway | Requires no earlier upgrade / world written by you / worlds you can afford |

### Essence affordability presentation

Construction, Research, Anchorage settlement and the Return recap use one factual distinction:

- **Essence available now** is refined Essence already held in `BaseState.essence`; convertible Raw Essence is not available now.
- **Essence after refining Raw Essence** adds the exact currently refinable equivalent and appears only when that equivalent is positive.
- After-action potential subtracts the exact construction or study cost from the after-refining total. Its label names refining whenever Raw Essence contributes.
- Affordable-world counts are advisory. They name both the basis and the action: the recent-five median is **Typical cost of a recent world written by you**; Research may fall back to **Current World preview cost**.
- Advisory potential never changes whether a transaction is currently affordable and never performs refinement automatically.
- Anchorage states its exact denominator. Return labels its frozen potential total **ESSENCE AVAILABLE**, `{N} after refining`, and **Enough to bind at least one more world**.
| Combat tree | node prerequisite | Requires no earlier skill |
| Writing Desk | exact frozen expansion / marks | footprint / Sigils |
| Gear rebuild | profile / Identity raw catalogue key | Construction / item name; raw key only secondary in DEBUG |
| Return detail | Legacy receipt / Identity raw catalogue key | From an older save / item name |
| Compound Assembly | atoms | Sigils in this Compound |

DEBUG-only explanatory numbers may remain more detailed, but the concept label is identical. There is no
DEBUG terminology exemption.

## Implementation order

1. Correct Return receipt/state capture and the photographed header/permanent-gains panel first.
2. Migrate World preview and Writing Desk terminology together so page composition uses one vocabulary.
3. Migrate all Essence affordability presentations through one shared formatter.
4. Migrate Research and Combat prerequisites through one shared `Requires …` formatter.
5. Migrate gear and compatibility detail surfaces; never expose a raw key as the primary value.
6. Regenerate GameWiki labels from this machine authority and run a complete human-visible string census.

### Research and Combat requirement relationship

Research requirements are earlier **Upgrades** and every listed Upgrade is required. Combat requirements
are earlier **Skills** and any one listed alternative is sufficient. Both surfaces, their accessibility copy
and DEBUG acceptance routes use the same rules-owned formatter; an unresolved authored ID fails closed as
unavailable requirement information rather than appearing to have no earlier requirement.

Research details are headed `Earlier Upgrades`. Combat Capstones retain their additional connected-route
gate and state it separately: `Capstone requirement: learn a connected route of 7 earlier Skills in this
tree, including this discipline’s Root, one Fundamental, one Development, and one Mastery.`
### Gear, maker stock and compatibility detail

- Maker inputs are **stock** and naturally pluralized **piece(s) of stock**.
- **Construction** names the rebuild choice while internal profile identifiers remain unchanged.
- Older-save compatibility is named plainly and never exposed as legacy/masterwork implementation jargon.
- Recycler routes say whether they return recorded construction stock or standard salvage.
- Maud teaches the **Fitted Polearm Schematic** while the persisted pattern wire identity remains unchanged.
- Item and resource detail leads with the canonical name and does not expose raw catalogue keys.

Do not rewrite model symbols, Codable keys or historical archives merely to make a grep count reach zero.
Do make every newly rendered label, accessibility string, DEBUG label, wiki heading, current test fixture and
current authority use the canonical name.

## Gates

1. The photographed Return states render exact new copy at 368×800 with no clipping.
2. Four forced `WorldDepartureState` fixtures prove the copy derives from the saved run before `activeRun`
   clears; relaunch replays it byte-equivalently.
3. Full/partial/Waystone/defeat/abandon outcome paths use the same state constructor.
4. Return contains no player-visible `marks`, `current draft`, bare `returned`, `progress` or `party total`.
5. Every human-visible occurrence of a retired term is either removed or explicitly approved as ordinary
   prose with a different meaning; the exception list stores path, line owner and rationale.
6. DEBUG labels lead with the canonical concept; raw IDs are secondary and accessibility reads the canonical
   name before technical metadata.
7. The wiki generator consumes the canonical term table and its search aliases route retired terms to the
   canonical page without displaying them as parallel concepts.
8. Source tests pin shared formatters and semantic output, not scattered copies of obsolete text.

## Exclusions

- no layout redesign beyond the existing return cells accommodating truthful copy;
- no tutorial, accessibility edge-case expansion or historical archive rewrite;
- no rename of stable IDs, Codable keys or catalogue IDs;
- no change to return rewards, XP, recruitment, binding costs or world generation.
