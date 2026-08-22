# Compound assembly and station trees — current design

**Status:** Implementation-ready structural design; costs remain playtest placeholders.
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
Brush and Scriptorium tier 1, and sits alongside Ink Mixing and Chaining rather than behind the
fountain pen.
Its placeholder purchase cost is 180 essence, 6 quartz and 8 pulp.

After unlocking it, the player may formalize any eligible composition they have successfully bound
at least once. One successful world is evidence enough; requiring repeated identical worlds would
turn experimentation into rote farming. Formalization happens in the runebook/Scriptorium and costs
a placeholder 20 essence plus 4 pulp. Saving, renaming and deleting a personal notation is free;
deletion does not revoke its atomic vocabulary.

The successful bind records a normalized **proven-statement receipt**: the exact target, source,
qualifiers/structural semantics, atomic vocabulary versions and statement fingerprint. It does not
record temporary page coordinates, world RNG, resolved uncontrolled facts or the world's outcome.
Writing the same statement in another arrangement/hand satisfies the same receipt when grammar says
those differences are immaterial.

At the Scriptorium's **Runebook · Formalize** tab, the player chooses one eligible proven statement,
sees its full Subject-and-Focus reading, written and compressed footprints in each owned hand, exact
effect equivalence and cost, then names and confirms it. The player cannot select arbitrary Sigils here to create an
unproven compressed statement. They experiment by spelling that statement out on a page and binding
it first.

The Writing Desk's Compounds palette places already formalized/found/taught compounds. Its anchored
detail shows nickname, full expansion, provenance and current-hand footprint without leaving the
one-screen page. The Desk may offer **Spell this out** for an unformalized proven statement, but it
cannot charge, name or mint a compound.

## Scriptorium Penmanship topology

The current branch is one taught progression with deliberate breadth after the first hand:

1. **Brush** — the required first ink-capable hand; replaces Pencil.
2. **A table that doesn't rock** — the purchased route that raises the Scriptorium to tier 1.
3. At effective tier 1 after Brush, three direct Brush-child capabilities become possible:
   - **Ink mixing** — deliberate CMY+Depth color authorship and saved mixtures;
   - **Compound Assembly** — formalize proven complete statements;
   - **Chaining** — join multiple statements/foci where grammar permits.
4. **A ruling frame** is the purchased route to Scriptorium tier 2.
5. **A fountain pen** remains the final hand and still requires Chaining plus effective tier 2.

The table/frame are not duplicated as hard prerequisite edges: keeper-earned tier satisfies the same
settled effective-tier gate. The three tier-1 capabilities do not require each other. Ink Mixing is
a direct adjacent Brush unlock; it changes the medium, Compound
Assembly compresses one proven statement, and Chaining joins distinct statements; merging their
gates would make three different writing decisions feel like one linear upgrade. Exact node costs
and whether the table is purchased immediately before all three remain playtest tuning; Isolde and
the Scriptorium remain mandatory ownership.

## Found and taught compounds

- Catalog, diary and NPC compounds coexist with personal compounds in the runebook.
- An unidentified found compound remains usable but cannot be copied, edited or nested. Once every
  component is known, it can be rewritten in the player's hand under the normal footprint rule.
- Exact semantic duplicates share one component reading. Authored names/provenance remain visible as
  alternate hands rather than creating mechanically different copies.
- A personal compound never grants an atomic rune the player does not already know.
- A found/taught compound does not create a proven-statement receipt merely by being owned or placed.
  Successfully binding its fully understood expansion may create the receipt; unidentified meaning
  cannot be laundered into personal notation.

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
- Saves store proven-statement receipts separately from compounds. A receipt is idempotent by
  semantic fingerprint and survives save/load without duplicating after repeated worlds.
- Normalize component order only where grammar says order is immaterial. Never merge two statements
  whose ordering changes meaning.
- Validate that expanded and compound forms resolve to identical world pressures and costs apart
  from page footprint.
- Every placed personal compound snapshots its stable ID and frozen atomic expansion. Deleting its
  Runebook entry removes it from future placement but never mutates an authored page, bound book or
  world that already contains it. A deleted compound can be formalized again from its retained
  proven receipt; this creates a new stable personal ID and never aliases historical marks.
- All costs and the five-component cap are debug-exposed; semantic equivalence is not tuning.

## Phone and interruption gates

1. The Scriptorium shows **Hands · Inks · Runebook** as compact real-capability tabs; a locked tab is
   absent until its root is legitimately known rather than exposing future secret content.
2. Formalize lists proven eligible statements as three-column glyph/reading tiles, not full-width
   prose rows. Selection opens one contained detail with expansion, footprints, name, cost and confirm.
3. Statements with unknown Sigils, nested Compounds, more than five Sigils or no complete Subject/Focus
   reading explain the exact ineligibility and cannot spend resources.
4. Confirmation is one atomic action over receipt fingerprint, cost quote and chosen nickname.
   Stale/missing receipt or stock rejects with zero mutation and refreshes the preview.
5. Force-quit before confirm loses only the draft nickname. Force-quit after confirm resumes one
   committed compound; it never charges twice or creates two IDs.
6. Renaming is free and updates only the Runebook label. Historical page/bound-book provenance remains
   inspectable and its frozen semantic expansion never changes.
7. Dynamic Type, VoiceOver and grayscale distinguish written Sigil expansion, compressed footprint,
   eligibility, selected statement and destructive deletion without relying on color alone.

The player-facing Sigil count is exactly `receipt.vocabulary.count`: the frozen written Subject, Focus and
Modifier identities. Semantic atoms remain internal persisted mechanics for effect equivalence and
footprint calculation and never drive that displayed count.
