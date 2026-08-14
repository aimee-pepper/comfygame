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
**102 pass** the contract without changes. **36 were revised in the production catalogue** because
their operative fact was missing, ambiguous or buried beneath figurative language:

`sela_where_2`, `tovin_where_0`, `tovin_where_1`, `tovin_where_2`, `isolde_where_1`,
`tovin_about_isolde`, `vance_where_0`, `corrin_where_2`, `dagg_where_0`, `dagg_where_3`,
`bracken_where_4`, `wren_where_0`, `wren_where_1`, `wren_where_3`, `kestrel_where_3`,
`marrick_where_0`, `marrick_where_2`, `oda_where_0`, `oda_where_1`, `oda_where_2`,
`grimmond_where_1`, `grimmond_where_3`, `auber_where_0`, `auber_where_2`, `auber_where_7`,
`ashe_where_1`, `ashe_where_3`, `perren_where_0`, `perren_where_3`, `perren_where_4`,
`perren_where_6`, `perren_where_7`, `perren_where_8`, `nine_where_1`, `nine_where_5`,
`nine_where_6`.

The previous Oda line “The land contains each disturbance…” is specifically retired. Its live
replacement describes close walls, narrow passages and nearby echoes before asking the player to
infer a low-openness world-writing route.

## Implementation gate

Catalogue decode and stable-ID coverage must remain green. A future authored-copy validator or
review tool should present every location clue beside its hidden signature condition and require a
human clarity disposition; prose style checks alone cannot prove that a sentence communicates the
correct world fact.
