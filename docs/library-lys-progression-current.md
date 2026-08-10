# The Library and Lys — current progression

**Status:** implementation-facing authority correction. The Library is an opening Base function;
Lys becomes its keeper and unlocks archival depth rather than constructing it midway through the
diary-led campaign.

## Why this exception is necessary

Recovered writing is the search spine for Mara, Edren, Halloway, Isolde, Sela and every traveller
before Lys. If the Library itself waited for Lys, the player would need its location evidence to find
the person who makes that evidence readable.

Therefore:

- the **Library exists and is open at new game**;
- it is initially an inherited room of loose shelves and the Binder's own arrangement;
- recruiting Lys assigns a specialist keeper and opens research/capabilities;
- Lys does not use ordinary `builtBy` locking and does not charge a construction cost for a room the
  save already uses.

The Firepit remains the only opening social building; this is a different exception—an essential
knowledge interface that later gains its rightful practitioner.

## Opening Library — tier 0

Before Lys, the Library supports every function required to play the traveller loop:

- read every recovered page in full;
- group pages by known diary/person where authorship is known;
- show one traveller hint card with recovered location passages and honest missing count;
- show learned focus/teaching rewards and their source page;
- reopen World History records linked directly from a page;
- preserve unknown authorship and forward references without inventing a name.

Basic reading and diary-focus acquisition never wait for Lys. The player may still make their own
interpretation, take notes mentally and find a valid signature by luck.

## What Lys adds

Recruiting Lys changes the station card to **Lys at the Library** and exposes three short branches.
She makes relationships visible; she does not translate prose into world conditions.

### Catalogue

- search/filter by person, page kind, named place, world and learned teaching;
- persistent cross-reference links between pages that explicitly name one another;
- an **Unresolved references** view for names/places not yet identified.

### Compare

- place two passages or two linked World History descriptions side by side;
- emphasize repeated and conflicting authored phrases without declaring which account is true;
- preserve source, hand and discovery order on both sides.

### Study

- the non-spoiling “You do not yet have the words to ask for this reliably” marker from
  `rune-pacing-library-legibility-current.md`;
- trace a learned focus/compound back to every recovered page that taught or used it;
- later study tools may expose relationships already explicit in text, never a generated solution.

The first implementation needs Catalogue search, explicit cross-reference links and the writability
marker. Side-by-side comparison can follow the tutorial's second-binding World History comparison so
both use one reusable component.

## Keeper/staffing semantics

Library state needs a **keeper** relationship separate from station construction:

- on Lys recruitment, old and new saves attach her as the available keeper;
- Home-posted Lys grants the ordinary Library-specific discount under
  `building-staffing-current.md`;
- taking her in the party contributes XP toward keeper-earned Library tier;
- assigning her elsewhere never hides basic pages or already-unlocked archival tools;
- purchased/effective tier uses the normal max-not-sum rule.

Do not encode Lys as `builtBy` if that field also locks station visibility. A separate `keeperID`,
`deepenedBy` or explicit station exception is safer and truthfully represents the chronology.

## Cross-reference rules

- Links come from authored page fields (`about`, site/world IDs, teaching IDs and explicit relation
  metadata), not keyword guesses over prose.
- An unknown target appears as an unresolved reference only when the page truly contains a stable
  target ID; it does not reveal the target's name early.
- Unlocking the target resolves the label in place without changing discovery order or prose.
- Relationship redundancy never becomes a new traveller-placement gate.

## Complexity boundary

No automatic signature solver, condition checklist, prose-to-number translation, truth score,
AI-generated summary, page rarity, reading timer or Lys-required focus acquisition is added. Search
and comparison organize evidence; interpretation remains the game.

## Required fixtures

1. A new save can read and use early location pages with Lys absent.
2. Recruiting Lys attaches her to the existing station without resetting pages or charging a build.
3. Removing Lys from Home preserves basic and purchased functionality.
4. Unknown stable references resolve in place without leaking names beforehand.
5. Search/cross-reference results never infer links from coincidental prose.
6. The writability marker never names a missing focus, qualifier, compound or exact condition.
