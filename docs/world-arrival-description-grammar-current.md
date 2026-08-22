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
  candidateMarkID: stable page mark identity
  semanticKey: String?              // known stable content key for registered overrides/families
  markDisplayName: String?          // nil when the player does not know it
  sourcePageOrder: Int
  scope: ground | water | flora | resource | light | atmosphere
  resultBand: closed scope-owned band
  contributionKind: none | increased | reduced | reshaped
  withoutAuthoredBand: closed scope-owned band

EnvironmentSummary
  illuminationBand: trueDark | dim | ordinary | bright | blazing
  illuminationSourceClass: sourceless | cyclic | constant
  suspendedMedium: none | smoke | airborneAsh | mist | miasma
  suspendedDensity: none | trace | light | heavy | dense
  precipitation: none | rain | snow | mixedRainSnow
  precipitationIntensity: none | trace | light | heavy
  atmosphereMotion: calm | moving | strong
  floraCoverageBand: none | sparse | present | abundant
  floraHabit: none | solitary | clustered | spreading | mixed
```

`illuminationSourceClass` is `sourceless` when the frozen illumination reading has the `sourceless` tag.
Otherwise it is `cyclic` only when the frozen Cycle reading exceeds
`Tuning.DayNight.stoppedMaximumPeak` **and** illumination range exceeds
`Tuning.Pressure.wideRangeThreshold`, matching `WorldRun.hasDayAndNight`; every other non-sourceless reading
is `constant`. It is never inferred from illumination floor alone. This class affects the scene's
visible-source treatment but does not add speculative source prose in v1.

`dominantDryGroundID` excludes `water`, `deepWater` and `chasm`; ties use this exact order:
`stone, soil, sand, ice, ash, rubble, mud, growth, groundcover`. Empty/all-water malformed input fails; it
does not fabricate “ordinary ground.”

`contributionKind` is a causal receipt, not `wasWritten`. Compare the exact visible result with the same
world roll after removing that authored mark's contribution. Use `reshaped` when the visible band/form
changes, `increased` or `reduced` when the same visible family remains but its exact quantity/magnitude
changes, and `none` when the visible result is unchanged. A known mark that merely agrees with what the seed
already supplied earns no causal wording. An increase never permits “created” wording, and a decrease never
permits “removed” wording. Removing marks for this comparison cannot reroll the world or alter any unrelated
random stream.

The sanitized `resultBand` is not the causal calculator. Rich rules provenance compares the exact
scope-owned form and quantity first, then freezes only its closed presentation band. Consequently an exact
increase may legitimately have the same before/after presentation band. Resource facts use only a resource
family explicitly registered to the speaking mark. Rich comparison uses that family's exact total obtainable
world quantity (node remaining harvests × yield plus matching world drops) while its sanitized band is only
`absent | present`; ordinary item placements, starter guarantees and creature loot are excluded. A random
unrequested resource family is never named or promoted into a causal fact merely because it spawned in the
same world.

For current Compound marks, the non-Reality resource IDs already authored as that symbol's
`yieldModifiers` keys are v1's registration set; those keys identify which family may be compared but do not
become a second spawn multiplier in Worldgen. An atomic source, legacy rune or personal Compound without an
explicit registered family emits no `resource` fact, even if its broader pressure incidentally changes
several resource weights. This conservative omission is preferable to guessing that “substrate” means Ore.

The player-facing mark name is the exact bind-time `markDisplayName` supplied by the canonical Dictionary /
Writing Desk knowledge projection. Grammar never creates copy by splitting, capitalizing or otherwise
guessing from a stable symbol ID. Facts with a nil display name are ineligible. `semanticKey` is present only
when that known candidate has a legitimate stable content key and is used only for registered verb/template
or resource-family overrides; it is never copy. `sourcePageOrder` and then the frozen scope order control
selection even if a serialized array arrives in a different key/order representation.

These display/order fields belong to the rich rules receipt that generates the final frozen description.
The sanitized Asset scene keeps its already accepted five-field `causalVisualFacts` ABI (`markID`, scope,
contribution, result band and without-authored band) because those facts own no pixels. For a known authored
catalogue mark, scene `markID` is its safe `semanticKey`; for a known personal mark without one it is an
opaque candidate key. Unknown/ineligible facts do not enter the scene payload. Asset does not reconstruct
selection, names or prose from this reduced record.

`floraCoverageBand` is computed from total placed flora tiles across all species, divided by non-Chasm
tiles. It is not copied from the first species' per-species coverage. The environment's habit band is a
separate aggregate (`none`, `solitary`, `clustered`, `spreading`, or `mixed`) and must agree with that total. Unknown
ground, water, scope, contribution, resource, light, atmosphere, precipitation, coverage or habit values fail the
receipt; they never become plausible generic prose.

Cross-field combinations are closed rather than merely enum-valid: suspended medium is `none` if and only
if suspended density is `none`; precipitation is `none` if and only if precipitation intensity is `none`;
flora coverage is `none` if and only if flora habit is `none`. Nonempty flora with one placed habit uses that
habit; more than one uses `mixed`. Any impossible pairing fails before copy selection.

### Causal candidate construction

Candidate ownership follows the physical source page; it is not reconstructed from sorted pressure output:

1. `sourcePageOrder` is the mark's index in the frozen `Page.runes` insertion array. Stable mark ID breaks a
   malformed duplicate-order tie but never replaces insertion order.
2. A self-contained Compound, personal Compound or legacy whole-rune mark is one candidate. In an atomic
   target/source cluster, each connected **source** mark is one candidate. Target anchors and qualifier marks
   are never separately named causal candidates.
3. A qualifier's effect belongs to the source mark it modifies. Removing that source for the counterfactual
   also removes its attached qualifier effect. This prevents copy such as “your Sun mark strengthened the
   light, while your Great mark strengthened the light.”
4. Unjoined/inert marks, clusters without a target, and marks that resolve to no live pressure are not
   candidates. Candidate construction uses the same speaking-cluster authority as bind.
5. A candidate is meaning-known only when every lexeme needed to name it is known in the exact bind-time
   Dictionary projection. Its display label is frozen at bind (`source name`, Compound name or personal
   nickname); legacy whole-rune copy uses its existing legitimate display text. Any missing label makes the
   fact ineligible rather than exposing a stable ID.
6. Build the counterfactual by removing the complete candidate mark from the frozen page. Retain every exact
   actual rolled sigil for subjects that were already unwritten. If a subject becomes newly silent only
   because of this removal, give it the target-keyed sigil from the one full-empty-page baseline roll for the
   same seed. Resolve that combined set with the same generator version. Never call the current skipping
   `rollUnwritten(after: remaining)` path, because omitting an earlier target would advance unrelated rolls.
7. One candidate may affect several scopes. Freeze one fact per changed scope, but sentence selection may
   name that candidate only once: retain its earliest fact in the exact scope order
   `ground, water, flora, resource, light, atmosphere`.

### Starter counterfactual receipts

These receipts freeze why the three current starter descriptions use their exact verbs. They are evidence
for the causal classifier, not starter-only prose branches:

| World | Same-seed mark removal | Accepted causal reading |
|---|---|---|
| Open Flats 67 | Removing Plains changes the world from broad sand/soil to a stone-heavy, wetter form. Removing Verdant leaves the same pithy-succulent family but lowers its placed coverage from 21 to 15 tiles. | Plains `reshaped`; Verdant `increased`, so it “spread low growth farther” and did not create it. |
| Rainwashed Shore 26 | Removing Archipelago replaces the stone-shelf water structure with an ash/rubble-heavy form and a different water balance. | Archipelago `reshaped`. |
| Stone Hollow 23 | Removing Caverns produces chasms, much more sand and far less stone. Removing Ore leaves the same ore family but lowers ore placement from 56 to 18. | Caverns `reshaped`; Ore `increased`, so it “made ore more plentiful” and did not create it. |

Revalidation must compare the same generator version, seed and ordered random stream. If a generator change
invalidates one of these receipts, the starter copy and receipt must be reaccepted together.

## Sentence 1: ground and water

### Water classifier

```text
wetShare = wetTileCount / nonChasmTileCount
deepShare = deepWaterTileCount / max(1, wetTileCount)

dry             wetShare == 0
scatteredPools  0 < wetShare <= 0.08
wetHollows      0.08 < wetShare <= 0.35 and deepShare < 0.25
mixedDepth      0.08 < wetShare <= 0.35 and deepShare >= 0.25
waterDominant   wetShare > 0.35
```

The classifier describes material relationship, not literal routes or every connected component. It never
names a portal or says which water is traversable. For `scatteredPools`, `{scatteredWater}` is `shallow
pools` when `deepWaterTileCount == 0`, otherwise `scattered pools of shallow and deep water`; no template may
call a known deep-water tile shallow.

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

Select at most one **known `reshaped`** structural fact that has a registered template below, in source-page
order with scope order `ground → water`. A different reshaping mark does not inherit the nearest template;
Sentence 1 uses the actual classifier fallback until Design registers its own structural template. The
current registered structural names are:

| Known reshaping mark | Template |
|---|---|
| Plains | `Broad {ground} {waterEnding}` |
| Archipelago | `{groundCap} shelves {waterEnding}` |
| Caverns | `{groundCap} closes around {waterEnding}` |

`{ground}` uses the table above. `{groundCap}` capitalizes only its first character. Water endings are:

| Water band | Plains | Archipelago | Caverns |
|---|---|---|---|
| dry | `stretches into the distance.` | `break across the visible ground.` | `narrow paths.` |
| scatteredPools | `runs between {scatteredWater}.` | `break around {scatteredWater}.` | `narrow paths and {scatteredWater}.` |
| wetHollows | `runs around wet hollows.` | `break around wet hollows.` | `narrow paths and wet hollows.` |
| mixedDepth | `runs between shallow and deep water.` | `break a wide run of shallow and deep water.` | `narrow paths and wet hollows.` |
| waterDominant | `forms a few broad islands.` | `rise as islands from shallow and deep water.` | `forms chambers above shallow and deep water.` |

If no known reshaping structural mark owns Sentence 1, use the actual classifier fallback:

| Water band | Fallback |
|---|---|
| dry | `{groundCap} stretches across the visible ground.` |
| scatteredPools | `{groundCap} runs between {scatteredWater}.` |
| wetHollows | `{groundCap} borders a series of wet hollows.` |
| mixedDepth | `{groundCap} breaks around shallow and deep water.` |
| waterDominant | `Patches of {ground} rise among shallow and deep water.` |

## Sentence 2: causality or environment

### Causal clause

Eligible facts must all be:

- from the source page;
- meaning-known to the player at bind time;
- `contributionKind != none` for the named visible result;
- one of `ground, water, flora, resource, light, atmosphere`.

A structural fact may also appear in Sentence 2: Sentence 1 describes the place; Sentence 2 explains the
player's causal contribution. This is deliberate, not duplicate receipt data.

Sort eligible facts by source-page order. A malformed duplicate page-order tie breaks by stable candidate
mark ID; facts belonging to that candidate then use scope order
`ground, water, flora, resource, light, atmosphere`. Use at most two different marks. The generic clause
fragments are:

| Scope | `reshaped` verb phrase | `increased` verb phrase | `reduced` verb phrase |
|---|---|
| ground | `reshaped the ground` | `made that ground more prevalent` | `made that ground less prevalent` |
| water | `reshaped the water` | `made water more prevalent` | `made water less prevalent` |
| flora | `reshaped {floraPhrase}` | `spread {floraPhrase} farther` | `left less {floraPhrase}` |
| resource | `changed the material deposits` | `made those deposits more plentiful` | `made those deposits scarcer` |
| light | `changed the light` | `strengthened the light` | `subdued the light` |
| atmosphere | `changed the air` | `strengthened that condition in the air` | `weakened that condition in the air` |

Starter fragments are exact reviewed overrides, keyed by stable symbol ID rather than display text:

| Symbol ID | Contribution | Verb phrase |
|---|---|---|
| plains | reshaped ground | `opened the terrain` |
| verdant | increased flora | `spread low growth farther along the few wet and stony edges` |
| archipelago | reshaped water | `divided the route` |
| caverns | reshaped ground | `shaped the enclosure` |
| common_ore | increased resource expression | `made ore more plentiful` |

One fact: `Your {mark} mark {verb phrase}.`
Two facts: `Your {first mark} mark {first verb phrase}, while your {second mark} mark {second verb phrase}.`

When exactly one causal fact exists, pair it with the strongest meaningful environmental fragment if one
exists: `Your {mark} mark {verb phrase}, while {environment fragment}.` Environmental fragments use the
following exact paired priority and the lower-case past-tense table below: heavy/dense suspended medium;
heavy precipitation; true darkness/blazing light; trace/light suspended medium; trace/light precipitation;
abundant/present/sparse flora; dim/bright ordinary-range light. This differs deliberately from the no-causal
fallback only at the last two steps: once one authored cause already owns the sentence, concrete growth is
more place-specific than routine dim/bright illumination, but it never suppresses true darkness or blazing
light. `{ground}` is the dominant ground token without an article. If the only environmental state is
ordinary fallback, use the one-fact sentence instead; never append an empty or generic clause.

| Environmental fact | Exact paired fragment |
|---|---|
| heavy/dense smoke | `thick smoke hung across the farther ground` |
| heavy/dense airborne ash | `airborne ash formed heavy banks across the farther ground` |
| heavy/dense mist | `mist gathered in broad banks beyond the entry` |
| heavy/dense miasma | `miasma lay heavily over the farther ground` |
| heavy rain | `heavy rain crossed the open ground` |
| heavy snow | `heavy snow crossed the open ground` |
| heavy mixed rain/snow | `rain and snow crossed the open ground together` |
| trueDark | `only the ground nearest the entry remained clearly visible` |
| blazing | `hard light reached every open surface` |
| trace/light smoke | `thin smoke drifted through the open ground` |
| trace/light airborne ash | `a light fall of ash moved through the air` |
| trace/light mist | `light mist gathered in the lower ground` |
| trace/light miasma | `a thin miasma hung over the lower ground` |
| trace/light rain | `light rain crossed the open ground` |
| trace/light snow | `light snow crossed the open ground` |
| trace/light mixed rain/snow | `light rain and snow crossed the open ground together` |
| abundant spreading flora | `growth spread across most open ground` |
| abundant clustered flora | `dense growth gathered in broad clusters` |
| abundant other flora | `growth occupied most open ground` |
| present spreading flora | `growth spread through the open ground` |
| present clustered flora | `growth gathered in distinct clusters` |
| present other flora | `growth established itself across the open ground` |
| sparse flora + dominant stone | `sparse growth settled on the open stone` |
| sparse flora + any other ground | `sparse growth settled across a few open patches` |
| dim | `dim light left the farther ground subdued` |
| bright | `clear light separated the open surfaces` |

Do not name a symbol that is unknown even if its visible result is obvious. Do not treat a matching random
result as authorship. `increased` phrasing must acknowledge strengthening rather than imply creation.

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

These present-tense sentences are independent authored tokens. Do not obtain them by capitalizing the
past-tense paired-fragment table; `Thin smoke drifts…` and `thin smoke drifted…` deliberately serve different
sentence structures.

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
   mark spread low growth farther along the few wet and stony edges.`
2. `Stone shelves break a wide run of shallow and deep water. Your Archipelago mark divided the route,
   while sparse growth settled on the open stone.`
3. `Stone closes around narrow paths and wet hollows. Your Caverns mark shaped the enclosure, while your Ore
   mark made ore more plentiful.`

These are outputs of the ordinary rules: structural selection, generic one/two-fact assembly and
environmental fallback. There is no starter-ID prose branch. If a generator change alters the underlying
receipt, the ordinary grammar produces a different truthful string and the pinned acceptance fixture fails
until reviewed.

## Exact 55-word layout-stress fixture

This synthetic receipt exists only to prove the maximum valid copy length. It is a Design-authored,
rules-owned **typography stress string**, not an output the ordinary runtime template selector is required to
invent. Its matching sanitized facts are dominant Stone with secondary Soil; mixed shallow and deep
channelled water; an `Archipelago` reshaping contribution; a `Verdant` increased-growth contribution; dense
growth on damp edges and comparatively bare high exposed ground. Its exact frozen string is:

`Broad stone shelves rise above narrow soil paths and connected pools of shallow water, with deep channels
cutting between the largest dry crossings. Your Archipelago mark divided the route into separate shelves,
while your Verdant mark spread dense low growth across the dampest edges and left the higher exposed ground
comparatively bare near the entry.`

The string is exactly 55 whitespace-delimited words and two sentences. It is a typography and disclosure
fixture, not an authored World Page, a runtime template branch or a promise that ordinary generation will
produce this exact combination. Runtime grammar tests prove every ordinary output stays within the same
18–55-word envelope; the layout test uses this explicit upper-bound specimen. Asset may use this exact
string only with the matching sanitized synthetic receipt above and may not substitute its own stress prose.

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
3. authored mark leaves exact visible output unchanged → no causal claim;
4. authored mark strengthens an existing result → increased, never created, phrasing;
5. one reshaping known mark → one causal fragment;
6. two contributing known marks → stable page order;
7. contributing unknown mark → omitted without meaning leak;
8. hidden site/resource/traveller/apex mutation → identical string;
9. every water classifier boundary;
10. every ground token and malformed all-water failure;
11. every atmosphere medium at light and heavy density;
12. flora coverage boundaries at 0, 7.99, 8, 21.99 and 22 percent;
13. banned-register corpus;
14. key-order and relaunch determinism;
15. grammar-version migration preserving frozen old output;
16. exact two-sentence Design-owned 55-word stress specimen accepted by the copy validator, without adding a
    runtime starter/synthetic branch or permitting truncation, clipping or Asset-authored substitution.
17. atomic target + source + qualifier attributes causality only to the known source mark; removing the sole
    source invokes its target-keyed empty-page baseline roll, two later already-unwritten target readings stay
    byte-equivalent to the actual world, and qualifier/target marks never receive duplicate clauses;
18. Stone Hollow freezes Ore as typed `resource/increased`, plus generic registered-resource reshaped,
    increased and reduced clauses; random unrequested resources remain ineligible;
19. illumination source class covers stopped/moving Cycle × narrow/wide light with sourceless precedence;
    incoherent none/non-none atmosphere, precipitation and flora pairs fail closed.
20. the actual generator and counterfactual classifier call one shared deterministic stage extraction; the
    summary path creates no playable/persisted world, stops after its last required flora/resource result and
    changes automatically when production stage logic changes.

## Out of scope

- clue/page rewriting;
- the longer analytical World History description;
- runtime LLM/network generation;
- local biome names;
- exact weather consequences;
- a third tension sentence in v1;
- tutorial copy.
