# World arrival description grammar — current

**Status:** Game Design implementation authority
**Priority:** B1.6a Engineering receipt/prose checkpoint before native reveal promotion
**Owner:** Engineering implements a pure rules function; Asset receives only its frozen output
**Updated:** 21 August 2026

## Purpose

Generate a short, immediately parseable description of the exact bound world. The copy tells the player
what kind of place appeared and, when causally true, what their known writing did. It is not the existing
Writing Desk/History description, a clue, a riddle, a pressure report or flavour text selected by an LLM.

The v1 output is deterministic, local, offline and frozen into `WorldArrivalReceipt` at successful bind.

## Output contract

- exactly **two sentences** in v1;
- **18–55 words total**;
- first sentence: actual dominant ground and water structure;
- second sentence: up to two causally authored known marks, otherwise the strongest actual air/light/growth
  relationship;
- normal sentence case and punctuation;
- no numbers, counts, pressure names, internal IDs or parameter vocabulary;
- no undiscovered entity, site, resource or unknown-mark identity;
- the same structured receipt always produces the same string.

The receipt stores the final string. Relaunch does not regenerate it against a newer catalogue.

After selecting both sentences, count whitespace-delimited words. If the total is below 18, append
`, while the ground beyond the entry remains open to exploration` before Sentence 2's final period. If the
total exceeds 55, remove the second causal fact and re-evaluate; if it still exceeds 55, use the strongest
environmental fallback. A valid mark display name that can still force more than 55 words fails the receipt
instead of being silently truncated.

## Required frozen facts

Engineering derives these once from the generated map, pressure/visual receipts and source page:

```text
TerrainSummary
  countByGroundID: [GroundType: Int]
  dominantDryGroundID: GroundType
  wetTileCount: Int
  deepWaterTileCount: Int
  nonChasmTileCount: Int

CausalVisualFact[]
  markInstanceID: stable page mark identity
  markDisplayName: String?          // nil when the player does not know it
  sourcePageOrder: Int
  scope: ground | water | flora | light | atmosphere
  resultBand: closed scope-owned band
  wasNecessary: Bool                // result would not hold without the actual authored contribution

EnvironmentSummary
  illuminationBand: trueDark | dim | ordinary | bright | blazing
  suspendedMedium: none | smoke | airborneAsh | mist | miasma
  suspendedDensity: none | trace | light | heavy | dense
  precipitation: none | rain | snow | mixedRainSnow
  precipitationIntensity: none | trace | light | heavy
  atmosphereMotion: calm | moving | strong
  floraCoverageBand: none | sparse | present | abundant
  floraHabit: solitary | clustered | spreading | mixed
```

`dominantDryGroundID` excludes `water`, `deepWater` and `chasm`; ties use this exact order:
`stone, soil, sand, ice, ash, rubble, mud, growth, groundcover`. Empty/all-water malformed input fails; it
does not fabricate “ordinary ground.”

`wasNecessary` is a causal receipt, not `wasWritten`. Compare the exact resolved visible band with the same
world roll after removing that authored mark's contribution. A known mark that merely agrees with what the
seed already supplied does not earn “Your mark made…” wording. Removing marks for this comparison cannot
reroll the world or alter any unrelated random stream.

## Sentence 1: ground and water

### Water classifier

```text
wetShare = wetTileCount / nonChasmTileCount
deepShare = deepWaterTileCount / max(1, wetTileCount)

dry             wetShare == 0
scatteredPools  0 < wetShare <= 0.08
wetHollows      wetShare > 0.08 and deepShare < 0.25
mixedDepth      0.08 < wetShare <= 0.35 and deepShare >= 0.25
waterDominant   wetShare > 0.35
```

The classifier describes material relationship, not literal routes or every connected component. It never
names a portal or says which water is traversable.

### Ground tokens

| Ground | Sentence token |
|---|---|
| stone | stone |
| soil | earthen ground |
| sand | sandy ground |
| ice | ice |
| ash | ash-covered ground |
| rubble | broken stone |
| mud | muddy ground |
| growth | tall growth |
| groundcover | low ground cover |

### Structural template selection

Select at most one **necessary, known** structural fact in source-page order, with scope order
`ground → water`. The current starter structural names have these exact templates:

| Known necessary mark | Template |
|---|---|
| Plains | `Broad {ground} {waterEnding}` |
| Archipelago | `{groundCap} shelves {waterEnding}` |
| Caverns | `{groundCap} closes around {waterEnding}` |

`{ground}` uses the table above. `{groundCap}` capitalizes only its first character. Water endings are:

| Water band | Plains | Archipelago | Caverns |
|---|---|---|---|
| dry | `stretches into the distance.` | `break across the visible ground.` | `narrow paths.` |
| scatteredPools | `runs between shallow pools.` | `break around scattered shallow pools.` | `narrow paths and shallow pools.` |
| wetHollows | `runs around wet hollows.` | `break around wet hollows.` | `narrow paths and wet hollows.` |
| mixedDepth | `runs between shallow and deep water.` | `break a wide run of shallow and deep water.` | `narrow paths and wet hollows.` |
| waterDominant | `forms a few broad islands.` | `rise as islands from shallow and deep water.` | `forms chambers above shallow and deep water.` |

If no necessary known structural mark owns Sentence 1, use the actual classifier fallback:

| Water band | Fallback |
|---|---|
| dry | `{groundCap} stretches across the visible ground.` |
| scatteredPools | `{groundCap} runs between scattered shallow pools.` |
| wetHollows | `{groundCap} borders a series of wet hollows.` |
| mixedDepth | `{groundCap} breaks around shallow and deep water.` |
| waterDominant | `Patches of {ground} rise among shallow and deep water.` |

## Sentence 2: causality or environment

### Causal clause

Eligible facts must all be:

- from the source page;
- meaning-known to the player at bind time;
- `wasNecessary == true` for the named visible result;
- not already consumed solely to choose Sentence 1, unless the clause names a different scope;
- one of `ground, water, flora, light, atmosphere`.

Sort eligible facts by source-page order, then scope order `ground, water, flora, light, atmosphere`. Use at
most two different marks. The generic clause fragments are:

| Scope | Verb phrase |
|---|---|
| ground | `shaped the ground` |
| water | `shaped the water` |
| flora | `gathered {floraPhrase}` |
| light | `set the light` |
| atmosphere | `changed the air` |

Starter fragments are exact reviewed overrides, keyed by stable symbol ID rather than display text:

| Symbol ID | Scope | Verb phrase |
|---|---|---|
| plains | ground | `opened the terrain` |
| verdant | flora | `gathered low growth along the few wet and stony edges` |
| archipelago | water | `divided the route` |
| caverns | ground | `shaped the enclosure` |
| common_ore | ground | `drew ore through it` |

One fact: `Your {mark} mark {verb phrase}.`
Two facts: `Your {first mark} mark {first verb phrase}, while your {second mark} mark {second verb phrase}.`

When exactly one causal fact exists, pair it with the strongest meaningful environmental fragment if one
exists: `Your {mark} mark {verb phrase}, while {environment fragment}.` Environmental fragments use the
same fallback priority below, rendered as a lower-case material clause. Examples: `sparse growth settled on
the open stone`, `heavy rain crossed the open ground`, `thin smoke drifted through the hollows`. If the only
environmental state is ordinary fallback, use the one-fact sentence instead.

Do not name a symbol that is unknown even if its visible result is obvious. Do not treat a matching random
result as authorship.

### Environmental fallback

If no eligible causal fact remains, select exactly one relationship in this order:

1. `suspendedDensity` heavy/dense;
2. `precipitationIntensity` heavy;
3. `illuminationBand` trueDark/blazing;
4. `suspendedDensity` trace/light when medium is not none;
5. `precipitationIntensity` trace/light when precipitation is not none;
6. `illuminationBand` dim/bright;
7. `floraCoverageBand` abundant/present/sparse;
8. ordinary fallback.

| Fact | Exact sentence |
|---|---|
| heavy/dense smoke | `Smoke hangs thickly across the farther ground.` |
| heavy/dense airborne ash | `Airborne ash forms heavy banks across the farther ground.` |
| heavy/dense mist | `Mist gathers in broad banks beyond the entry.` |
| heavy/dense miasma | `Miasma lies heavily over the farther ground.` |
| heavy rain | `Heavy rain crosses the open ground.` |
| heavy snow | `Heavy snow crosses the open ground.` |
| heavy mixed rain/snow | `Rain and snow cross the open ground together.` |
| trueDark | `Only the ground nearest the entry is clearly visible.` |
| blazing | `Hard light reaches every open surface.` |
| trace/light smoke | `Thin smoke drifts through the open ground.` |
| trace/light airborne ash | `A light fall of ash moves through the air.` |
| trace/light mist | `Light mist gathers in the lower ground.` |
| trace/light miasma | `A thin miasma hangs over the lower ground.` |
| trace/light rain | `Light rain crosses the open ground.` |
| trace/light snow | `Light snow crosses the open ground.` |
| trace/light mixed rain/snow | `Light rain and snow cross the open ground together.` |
| dim | `Dim light leaves the farther ground subdued.` |
| bright | `Clear light separates the open surfaces.` |
| abundant spreading flora | `Growth spreads across most open ground.` |
| abundant clustered flora | `Dense growth gathers in broad clusters.` |
| abundant other flora | `Growth occupies most open ground.` |
| present spreading flora | `Growth spreads through the open ground.` |
| present clustered flora | `Growth gathers in distinct clusters.` |
| present other flora | `Growth is established across the open ground.` |
| sparse flora | `Sparse growth holds to a few open patches.` |
| ordinary fallback | `No single visible condition dominates the farther ground, which remains open to exploration.` |

Motion affects atmosphere animation, not this sentence in v1. Do not add generic wind prose without a typed
atmosphere medium to carry it.

## Flora phrase for causal clauses

| Coverage | Habit | Phrase |
|---|---|---|
| sparse | any | `sparse growth` |
| present | solitary | `scattered growth` |
| present | clustered | `clustered growth` |
| present | spreading | `spreading growth` |
| present | mixed | `growth across the open ground` |
| abundant | solitary | `growth across most open ground` |
| abundant | clustered | `dense clustered growth` |
| abundant | spreading | `dense spreading growth` |
| abundant | mixed | `dense growth` |
| none | any | malformed causal receipt; fail |

Coverage bands derive from actual placed flora tiles divided by non-Chasm tiles:
`none == 0`, `sparse > 0–< 8%`, `present 8–< 22%`, `abundant >= 22%`.

## Starter acceptance strings

The exact current starter receipts must produce:

1. `Broad sandy ground runs between shallow pools. Your Plains mark opened the terrain, while your Verdant
   mark gathered low growth along the few wet and stony edges.`
2. `Stone shelves break a wide run of shallow and deep water. Your Archipelago mark divided the route,
   while sparse growth settled on the open stone.`
3. `Stone closes around narrow paths and wet hollows. Your Caverns mark shaped the enclosure, while your Ore
   mark drew ore through it.`

These are outputs of the ordinary rules: structural selection, generic one/two-fact assembly and
environmental fallback. There is no starter-ID prose branch. If a generator change alters the underlying
receipt, the ordinary grammar produces a different truthful string and the pinned acceptance fixture fails
until reviewed.

## Register and prohibited language

This surface is plain field description. Reject generated output containing, case-insensitively:

- `remembers`, `wants`, `refuses`, `consents`, `innocence`, `evidence`, `boundary`, `truth`;
- `as if`, `perhaps`, `somehow`, `seems to`, `you will`, `you must`;
- a question mark, semicolon, em dash or quotation mark;
- raw pressure target IDs, stable IDs, camelCase ground IDs or numerical values.

Also reject:

- personification where land/world/ground is the grammatical subject of a human mental verb;
- metaphor in place of a material fact;
- aphorisms or advice;
- creature/resource/site/traveller names absent from legitimate entry disclosure;
- unknown symbol names anywhere in the final string.

The filter is a test guard, not a substitute for authored templates. Failure shows a DEBUG diagnostic and
uses the safe two-sentence actual-ground + ordinary fallback grammar; Release never prints an error token.

## Persistence and change policy

- Freeze `grammarVersion`, structured source facts and final string in the arrival receipt.
- Existing receipts keep their final string after copy changes.
- A new grammar version applies only to newly bound worlds.
- History may display the frozen arrival string; it must not regenerate old worlds from current rules.
- Asset receives only the final string and cannot choose another template.
- The existing `descriptions.json` remains Desk/History pressure prose and is not the source for arrival copy.

## Engineering fixtures

1. three starter exact strings and 18–55 word bounds;
2. no authored marks → environmental fallback;
3. authored mark agrees by chance → no causal claim;
4. one necessary known mark → one causal fragment;
5. two necessary known marks → stable page order;
6. necessary unknown mark → omitted without meaning leak;
7. hidden site/resource/traveller/apex mutation → identical string;
8. every water classifier boundary;
9. every ground token and malformed all-water failure;
10. every atmosphere medium at light and heavy density;
11. flora coverage boundaries at 0, 7.99, 8, 21.99 and 22 percent;
12. banned-register corpus;
13. key-order and relaunch determinism;
14. grammar-version migration preserving frozen old output.

## Out of scope

- clue/page rewriting;
- the longer analytical World History description;
- runtime LLM/network generation;
- local biome names;
- exact weather consequences;
- a third tension sentence in v1;
- tutorial copy.
