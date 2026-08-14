# Location clue clarity audit — current

**Status:** production correction set; 14 Aug 2026
**Authority:** `Sources/Content/Data/travellers.json`

## Player contract

A traveller location clue describes an observable world property in readily parseable language. The
player's puzzle is choosing sigils that could create that property. The puzzle is never interpreting
a metaphor, ethical argument, professional analogy or sphinx-like riddle to discover what property
the page meant.

- The first sentence must let a player accurately paraphrase the relevant condition after one read.
- It must not expose internal target names, numbers, thresholds or a required sigil.
- Character voice may sharpen or complicate the observation only after the world fact is clear.
- Stable page ID, owner, clue index and mechanical signature condition do not change during a prose
  correction.

## Corpus disposition

All **138** live `locationClue` pages were compared with the matching traveller signature condition.
The first pass promoted 36 corrections, but its `102 pass` claim was too permissive: it accepted
several sentences whose meaning could be inferred only after translating a professional metaphor.
The 14 Aug campaign-order re-audit adds **39 corrections**. Across both passes, **75 clues have now
been revised in the production catalogue and 63 retain copy that passed the stricter second review.**

`sela_where_2`, `tovin_where_0`, `tovin_where_1`, `tovin_where_2`, `isolde_where_1`,
`tovin_about_isolde`, `vance_where_0`, `corrin_where_2`, `dagg_where_0`, `dagg_where_3`,
`bracken_where_4`, `wren_where_0`, `wren_where_1`, `wren_where_3`, `kestrel_where_3`,
`marrick_where_0`, `marrick_where_2`, `oda_where_0`, `oda_where_1`, `oda_where_2`,
`grimmond_where_1`, `grimmond_where_3`, `auber_where_0`, `auber_where_2`, `auber_where_7`,
`ashe_where_1`, `ashe_where_3`, `perren_where_0`, `perren_where_3`, `perren_where_4`,
`perren_where_6`, `perren_where_7`, `perren_where_8`, `nine_where_1`, `nine_where_5`,
`nine_where_6`.

Second-pass additions:

`bryn_where_0`, `bryn_where_1`, `bryn_where_2`, `orsa_where_0`, `orsa_where_1`, `orsa_where_2`,
`noll_where_0`, `noll_where_1`, `talin_where_0`, `nessa_where_0`, `nessa_where_1`,
`nessa_where_3`, `corrin_where_0`, `corrin_where_1`, `corrin_where_3`, `dagg_where_1`,
`dagg_where_2`, `rook_where_0`, `rook_where_2`, `lys_where_0`, `lys_where_1`, `lys_where_3`.

`fen_where_0`, `fen_where_2`, `fen_where_3`, `fen_where_4`, `maud_where_0`, `maud_where_3`,
`maud_where_4`, `marrick_where_3`, `marrick_where_4`.

`bracken_where_3`, `maud_where_2`, `sabine_where_0`, `grimmond_where_5`, `oda_where_7`,
`auber_where_4`, `ashe_where_7`, `nine_where_3`.

The previous Oda line “The land contains each disturbance…” is specifically retired. Its live
replacement describes close walls, narrow passages and nearby echoes before asking the player to
infer a low-openness world-writing route.

## Implementation gate

Catalogue decode and stable-ID coverage must remain green. A future authored-copy validator or
review tool should present every location clue beside its hidden signature condition and require a
human clarity disposition; prose style checks alone cannot prove that a sentence communicates the
correct world fact. `ContentTests` now also enforces, for every traveller, that ordered self-clue
pages exactly match the corresponding signature passages; this prevents the Library clue and
traveller-arrival truth from silently diverging during future prose corrections.
