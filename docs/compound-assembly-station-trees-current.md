# Compound assembly and station trees — current design

**Status:** Current structural design; costs and unlock placement are playtest placeholders.  
**Scope:** Player-authored writing compounds and the ownership of non-combat progression.

## Audit result

Per-building research trees are not wholly unbuilt. The content model already assigns branches to a
station and gates nodes by station tier; the Scriptorium and Survey Post use this architecture.
Future station progression should extend that same system rather than introduce private upgrade UIs.

Compound *placement* also exists for authored catalog compounds. What is missing is the promised
player-facing assembly/formalization loop and its gate.

## What a player-authored compound is

A compound is one reusable glyph that preserves the exact meaning of several known atomic sigils at
a smaller footprint. It changes notation, not world output: spelling a statement out and writing its
compound must produce identical pressure contributions, secondaries, contradictions, danger and
greed before footprint is considered.

Player-authored compounds:

- contain 2–5 known atomic sigils;
- describe one complete self-contained statement with one target;
- store normalized semantic components, not the temporary positions used in the assembly popup;
- cannot contain another compound recursively;
- cannot contain unknown components;
- use `ceil(sum of atomic footprints × 0.6)` in the current hand, minimum 1;
- receive a player nickname, while their component reading remains inspectable.

The 2–5 limit keeps the popup legible on a phone and prevents one late glyph from swallowing an
entire world specification. Chaining remains the tool for joining distinct statements or regions.

## Unlock and formalization

**Compound Assembly** is a reliable midgame Penmanship node at the Scriptorium. It requires the
pencil and Scriptorium tier 1, and should sit alongside Chaining rather than behind the fountain pen.
Its placeholder purchase cost is 180 essence, 6 quartz and 8 pulp.

After unlocking it, the player may formalize any eligible composition they have successfully bound
at least once. One successful world is evidence enough; requiring repeated identical worlds would
turn experimentation into rote farming. Formalization happens in the runebook/Scriptorium and costs
a placeholder 20 essence plus 4 pulp. Saving, renaming and deleting a personal notation is free;
deletion does not revoke its atomic vocabulary.

The page-writing screen opens a compact assembly popup. The player chooses known components, sees the
fully expanded reading, footprint and projected world effect, names it, and places the result. The
page itself remains a one-screen placement surface.

## Found and taught compounds

- Catalog, diary and NPC compounds coexist with personal compounds in the runebook.
- An unidentified found compound remains usable but cannot be copied, edited or nested. Once every
  component is known, it can be rewritten in the player's hand under the normal footprint rule.
- Exact semantic duplicates share one component reading. Authored names/provenance remain visible as
  alternate hands rather than creating mechanically different copies.
- A personal compound never grants an atomic rune the player does not already know.

## Station-tree rules

Every non-combat permanent unlock belongs either to the Workshop or to the station whose practice it
deepens:

1. Knowledge worked out without a specialist belongs at the Workshop.
2. Knowledge taught through a traveller's trade belongs at that traveller's station.
3. Recipe catalogues, station capabilities, efficiency and station tier may share a branch, but a
   node should unlock a new decision or a visible family—not merely +5% throughput.
4. Building the station exposes its roots. `needsStationTier` controls later nodes. Keeper-earned
   tier uses the same effective-tier rule as purchased tier.
5. No essential storage, party-management or basic writing function waits on a late random
   traveller. The Scriptorium is the explicit exception already chosen: improved hands require
   Isolde because that meeting is core progression.
6. A recipe may require a station tier without also requiring a redundant research node unless the
   node represents learning that recipe family.

The Workshop therefore remains the home of self-taught general systems and cross-station
infrastructure. It is not a duplicate catalogue of everything every specialist knows.

## Implementation invariants

- Saves store a personal compound's stable ID, atomic expansion, nickname and provenance; they do
  not rely on regenerating meaning from mutable catalog content.
- Normalize component order only where grammar says order is immaterial. Never merge two statements
  whose ordering changes meaning.
- Validate that expanded and compound forms resolve to identical world pressures and costs apart
  from page footprint.
- Compound deletion must repair pages/runebook references safely or be refused while referenced.
- All costs and the five-component cap are debug-exposed; semantic equivalence is not tuning.
