# Count in world descriptions — current design

**Status:** Current semantic and prose design; focus-specific wording is content work.  
**Scope:** Count qualifier from page grammar through preview, generated-world prose and history.

## Existing mechanic

Count already changes pressure magnitude sublinearly and pushes dispersible subjects outward. The
remaining defect is representational: the prose often describes the resulting brightness, water or
life but omits that the player explicitly wrote several causes.

Count must remain distinct from Intensity and Scale:

- **Great Sun:** one sun, stronger.
- **Vast Sun:** one sun, larger/more extensive.
- **Few Suns:** three suns, each contributing through the Count rule.

## Count ladder semantics

| Written rung | Semantic quantity | Prose behavior |
|---|---:|---|
| no Count / Single | 1 | singular |
| Pair | 2 | exact “two” or “a pair of” |
| Few | 3 | exact “three” |
| Many | 4 representative | qualitative “many”; do not expose implementation four |
| Countless | 5 representative | qualitative “countless”; do not expose implementation five |

The internal representative values drive diminishing-return math. “Countless” does not claim the
simulator instantiated exactly five objects; five is the authored pressure rung for an uncountable
presence.

When several statements use the same focus, aggregate their semantic quantities for descriptive
purposes only when their physical reading is compatible. Pair Sun plus one unqualified Sun says
**three suns**. Statements with materially different modifiers or negations receive separate clauses
instead of erasing the distinction.

## Focus prose metadata

Each focus authors a `countReading`:

- `discrete`: real countable objects, with singular and plural nouns (`sun`/`suns`,
  `spring`/`springs`);
- `occurrences`: repeated places/events, with an authored clause stem (`storms cross the world`,
  `veins run through the ground`);
- `mass`: quantity is meaningful mechanically but not as numbered objects (`ash`, `mist`), with an
  authored distributive phrase (`falls in separate drifts`, `lies in banks across the routes`).

Discrete focuses use exact numbers through three, then many/countless. Occurrence and mass focuses
use the ladder word plus authored grammar rather than awkward automatic plurals. No focus may silently
drop an explicit Count; a temporary fallback is **“This focus was written as Pair/Few/Many/Countless”**
until prose metadata exists.

## Where it appears

1. The page reading beneath a connected cluster includes the count word.
2. The pre-bind World pane includes a direct authored-cause sentence before consequence clauses:
   **“Three suns cross the sky.”**
3. The generated world's entry description uses the fully resolved written-plus-random composition,
   so a random single source remains singular.
4. World History stores the semantic source/count facts, not only flattened prose, so later copy and
   localization changes do not rewrite what the player authored.
5. The Library never translates traveller clues into Count requirements; this is world description,
   not clue solving.

## Projection and mechanics

The direct count sentence is always available because it repeats what was written or rolled; it does
not require an analysis instrument. Consequence clauses and numerical readings remain analysis-gated
as currently designed.

Description receives the resolved sigil list in addition to pressure readings. Do not attempt to
recover source counts from clamped readings: a world at Illumination 100 cannot reveal whether one
overwhelming sun or countless moderate suns caused it.

## Implementation invariants

1. Count wording never changes pressure math, greed, stability or generation.
2. Explicit Single and absent Count both mean one physical cause.
3. Pair/Few are exact two/three; Many/Countless remain qualitative.
4. Compound expansions carrying Count preserve it; personal compound round-trips do too.
5. Random fill defaults to one unless the rolled mark explicitly contains Count.
6. Fixtures cover one/pair/few/many/countless Sun, Pair Sun + Single Sun, massed Ash and two differently
   negated Sun statements.
