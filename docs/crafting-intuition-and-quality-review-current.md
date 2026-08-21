# Crafting intuition and loot quality — current review

**Status:** Core model and exact physical content authority are settled: six quality bands, 70/30
primary/secondary weighting, no hard station quality caps, Refitting, complete material profiles and all 21
physical schematic sockets. Engineering may begin only through the ordered migration after the current
playability primary permits it. The territory-find mix remains a separate open tuning decision.
**Supersedes for review:** the continuous six-property player-facing recipe puzzle, the
`0.6 × weakest + 0.4 × average` output rule, and hard station quality caps in
`loot-quality-hybrid-review-current.md` and `gear-crafting-families-current.md`.
**Does not change yet:** live saves, `MaterialSample`, current recipes, current gear power, Trading Post,
Recycler, Distillery, or any native UI.
**Updated:** 21 August 2026

The exact disposition of all 75 currently live Gear catalogue IDs is now frozen separately in
`gear-catalogue-disposition-authority.json`. It prevents legacy found objects, apex rules and resource-named
placeholder gear from being mistaken for interchangeable crafted Schematics during this migration.

## Audit conclusion

The live crafting implementation is logically consistent but too difficult to predict from ordinary game
knowledge. A player currently must understand:

- six continuous values from 0–100 on every exact sample;
- one or two numeric floors per recipe component;
- kind restrictions that sometimes matter and sometimes do not;
- automatic weakest-qualifying selection;
- a separate continuous grade;
- `0.6 × minimum grade + 0.4 × average grade`;
- conversion from that score into construction Tier 1–4;
- a station/recipe cap that may discard otherwise valid input quality;
- a separate reforge rank and sometimes another specialist reconstruction profile.

This produces internally defensible but unintuitive outcomes: a surprising body part can qualify for a grip
because of an unseen number; a high-quality primary component can be dragged down by an incidental binding;
and a foundational shop can discard legendary input quality because the shop has a numerical ceiling. The
player is solving the data model instead of making an object.

The current model should not be polished. It should be simplified before its UI and material migration are
expanded.

## Player-facing rule

Crafting should be explainable in three sentences:

1. Pick the object **schematic** you want to make.
2. Choose a material for each pictured component; the component says what broad materials fit there.
3. The primary component has the strongest effect, while fittings change secondary stats, appearance and
   value. Better-colour inputs make a better-colour finished object.

No ordinary player-facing recipe asks for `hardness 65`, `flexibility 55` or another continuous number.
Generated traits may still decide what material family/quality a source produces, but the crafting surface
uses material names, component fit and compact qualitative effects.

## Three distinct identities

Do not collapse these into one universal “better” number:

| Identity | Question answered | Example |
|---|---|---|
| **Schematic** | What object and combat/tool behavior is this? | Pointed Blade, Long Spear, Supple Coat |
| **Material** | What characteristic does this component add? | Adamant is forceful/heavy; Pelt insulates; Gold is valuable/conductive |
| **Quality** | How exceptional is this particular material or finished object? | Rough, Standard, Fine, Superior, Exceptional, Peerless |

`Schematic` is the player-facing word for what earlier documents and internal stable IDs may call a
`Pattern`: the recipe/object plan, not a textile print or a random appearance pattern. Existing stable
PatternIDs may remain decode aliases, but new UI and content copy say **Schematic**.

Material identity is not a total ordering. Adamant is not “higher-quality Gold.” They are different inputs
with different uses. A recipe may permit both Pelt and Gold in a grip/trim component; the Pelt version gains
its authored comfort/insulation treatment and visual wrap, while the Gold version gains its authored
value/conduction treatment and visible fitting. Neither is a hidden numerical substitute for the other.

## Six quality bands

The approved vocabulary uses the familiar loot hierarchy:

| Rank | Colour | Label | Player expectation |
|---:|---|---|---|
| 0 | grey | Rough | vendor trash, damaged or crude output |
| 1 | white | Standard | common ordinary loot |
| 2 | green | Fine | uncommon |
| 3 | blue | Superior | rare |
| 4 | purple | Exceptional | epic |
| 5 | orange | Peerless | legendary |

The label, frame geometry and colour communicate the same state. Colour is never the only cue. The game does
not add a second Common/Uncommon/Rare field beside these bands.

Quality applies to ordinary gear and materials where yield quality matters. It does not apply to Gold Coins,
Raw/refined Essence, Motes, pages, runes, keys, quest objects, or fixed-effect consumables unless a later
recipe actually varies their potency.

## Material component profiles

Every craftable material family receives one authored `ComponentProfile`, not six player-facing continuous
bars. The complete table must exist before Engineering migration begins. Each profile contains:

- eligible component roles;
- one primary visible contribution for each eligible role;
- at most one trade-off where the material genuinely has one;
- one palette/texture/silhouette treatment for the output component;
- base merchant value;
- quality scaling for its named contribution.

First component roles are deliberately small:

| Role | Meaning | Examples |
|---|---|---|
| **Core** | blade/head/working mass or principal tool part | metal, bone, fang, plate, hard wood |
| **Body** | main protective or structural layer | plate, scale, hide, pelt, chitin, timber |
| **Grip** | held contact surface | hide, pelt, fibre, cloth, shaped Gold fitting where allowed |
| **Binding** | flexible joint/attachment | fibre, hide, tendon-like creature material, soft metal fitting where allowed |
| **Lining** | inner protective layer | pelt, down, hide, fibre |
| **Fitting** | guard, trim, clasp, counterweight or conductive detail | Gold, Silver, bone, horn, metal, carved stone |

A recipe lists exact component sockets and broad eligible families/tags. It never says “any sample” merely
because one hidden value passes. A surprising substitution is allowed only when the component fiction and
previewed result make sense.

### Required first-table examples

These examples establish the grammar; the complete dispatch table is
`crafting-components-and-schematics-current.md`:

| Material in role | Visible contribution | Trade-off/limit |
|---|---|---|
| Adamant Core/Body | strongest physical power or protection contribution | heavy; cannot become soft lining |
| Gold Fitting/Grip | value plus conductive/lustrous secondary contribution | weak as a physical blade/core |
| Pelt Grip/Lining | insulation and comfortable/flexible treatment | not a rigid striking core |
| Hide Grip/Binding/Body | flexible balanced physical treatment | less insulation than Pelt, less armour than Plate |
| Plate Core/Body | armour/impact contribution | heavy and inflexible |
| Bone Core/Fitting | balanced physical structure; pale carved visual | less extreme than specialist metal |
| Feather/Down Lining | lightness or insulation depending family | no rigid core use |
| Timber Core/Body/Grip | ordinary structural/haft contribution | vulnerable in recipes needing metal edge behavior |

The output preview names the material consequence directly: `Pelt-wrapped · +insulation`, not
`flexibility 63`.

## Output quality: component importance, not weakest-input punishment

The old weakest-input rule existed to stop one legendary component from hiding several pieces of junk. That
goal is sensible, but a global minimum is the wrong model: a sword's binding should not count as much as its
blade, and a legendary pommel should not make a crude blade legendary.

Use authored component importance instead:

```text
outputQualityScore = 0.70 × average(primary component quality ranks)
                   + 0.30 × average(secondary component quality ranks)
outputQualityBand = nearest whole band, halves round upward
```

- Core/Body sockets are normally primary.
- Grip/Binding/Lining/Fitting sockets are normally secondary.
- A schematic may mark two structural sockets primary; they split the 70% share equally.
- If a recipe has no secondary socket, primary components own 100%.
- A recipe may not change weights merely to force its intended output colour.

Examples with ranks 0–5:

| Primary | Secondary | Score | Output |
|---|---|---:|---|
| Peerless 5 | Peerless 5 | 5.0 | Peerless / orange |
| Peerless 5 | Rough 0 | 3.5 | Exceptional / purple |
| Rough 0 | Peerless 5 | 1.5 | Fine / green |
| Superior 3 | Standard 1 | 2.4 | Fine / green |
| Standard 1 | Superior 3 | 1.6 | Fine / green |

This incorporates both directions the earlier formula missed: exceptional supporting work can improve a
plain core, and an exceptional core can carry ordinary fittings, but component importance decides which has
more influence. All-Peerless inputs always produce a Peerless output.

**Settled starting rule:** 70/30 is the authored starting weight. It is exposed in DEBUG tuning during the
first complete crafting fixture; changing it changes future crafts only, never existing frozen gear.

## Stations and schematics: no hard quality cap

Remove the hard rule that a Blacksmith cannot preserve quality above Tier 2 or a specialist cannot preserve
quality above another numerical cap. If a station can make the schematic and every selected component is
Peerless, the finished object is Peerless.

Station progression instead controls:

- which schematics are available;
- how many meaningful component sockets/choices a schematic supports;
- specialist combat/tool profiles;
- deterministic material efficiency where explicitly authored;
- later refitting/reconstruction options.

Examples:

- Halloway can make a Peerless Pointed Blade from Peerless inputs, but it remains the straightforward
  close-pierce Pointed Blade schematic.
- Maud's Weaponsmith unlocks Fitted Point, Fitted Edge, Fitted Maul and Fitted Polearm schematics with advanced
  base profiles and fittings. A Standard Fitted Point may have behavior a Pointed Blade never gains.
- Bracken's Armoury unlocks Rigid, Insulated and Balanced protective profiles. Colour does not replace the
  profile choice.

Schematic and quality both affect final performance:

```text
finished performance = authored schematic baseline
                     + quality-band contribution
                     + named material component modifiers
                     + preserved legacy credit, if any
```

Exact combat numbers remain a balance table, not something Engineering infers from colour multipliers.

## Refitting replaces the opaque reforge ladder

For new gear, Halloway's repeatable improvement should become **Refit**:

1. choose an exact owned physical item;
2. choose one installed component socket;
3. choose a compatible replacement material stack;
4. preview output quality, named material modifier, appearance and performance before/after;
5. confirm one atomic replacement.

The old component returns only if an authored recovery rule says it survives; ordinary refitting consumes
it. A refit cannot change the schematic's slot/damage/reach identity. Specialist Rebuild may change the schematic
when its station explicitly allows it.

Existing paid reforge ranks/power remain preserved through migration. They become frozen legacy workmanship
credit and are never deleted or silently reinterpreted as components that were not recorded.

## Resource stacking and provenance

Material inventory stacks by:

```text
domain + material family + quality band
```

Thus Fine Gold and Fine Gold merge; Fine Gold and Superior Gold do not. Component effects are deterministic
from family+role+band, so merged units do not conceal different gameplay numbers.

Bestiary and World History retain known source records. A merged stack does not claim one exact source.
Quest-relevant/singular provenance remains an exact Trophy or Item rather than a fungible material.

## Found gear and ordinary-animal territory finds

Ordinary animals always yield body-derived Creature materials. In addition, a victorious ordinary animal
encounter makes one isolated **territory-find** roll. To preserve the already discussed three-percent gear
rate without tripling the total bonus frequency, recommended initial playtest rates are:

- 3% ordinary campaign-banded gear;
- 1.5% eligible campaign-banded consumable;
- 0.5% ordinary cache key;
- 95% no territory find.

This is implemented as one five-percent find roll followed by category weights 60:30:10, so at most one
such object appears per encounter. It is per encounter, not per creature; Teeming does not multiply it.

The receipt says the object was recovered from a nest, den, discarded pack, swallowed remains or other
territory trace. Keys mean ordinary cache keys only. Quest items, authored uniques, apex weapons and future
story keys remain excluded. Gear quality follows the current campaign/danger source table; consumable
identity follows current recipe/knowledge eligibility. No pity timer in the first slice. DEBUG exposes the
roll, category and selected table.

## Crafting UI contract

The station surface begins with six-across schematic icons, not recipe rows. Selecting one opens an anchored,
edge-clamped detail containing:

1. object silhouette, slot and behavior;
2. pictured component sockets;
3. one material picker per socket, filtered to compatible stacks;
4. output quality frame/name;
5. named material contributions and any trade-off;
6. exact before/after performance for refit/rebuild;
7. costs, storage destination and one confirm action.

Default selection uses the lowest-quality compatible stock that produces the currently previewed band and
never consumes a higher band without showing it. The player may explicitly choose higher-quality components.
No hidden auto-selection occurs at commit; every selected stack and count is frozen in the quote.

## Engineering sequence after content freeze

Do not implement this as scattered consumer patches. The required sequence is:

1. Freeze the complete material-family/component-role/modifier table and current recipe socket table in
   versioned content; validate every family and recipe.
2. Add six-band stack identity beside the current exact reserve and prove lossless migration on a copy of
   every legacy material kind/grade/source shape.
3. Add the component quote/output calculator with 70/30 fixtures; no UI and no current craft mutation yet.
4. Migrate existing Tier 1–4 gear to Standard/Fine/Superior/Exceptional with identical effective power and
   preserve legacy reforge credit.
5. Implement one Pointed Blade vertical slice: stack selection, visual component receipt, output quality,
   material modifier, atomic commit, Recycler receipt and save round-trip.
6. Convert Trading Post, Recycler, Storehouse, failure return and gear presentation to family+band stacks.
7. Convert the remaining current physical schematics and Refitting.
8. Convert Instrument, Scent Mask, Distillery and special consumers only from explicit authored component/
   ingredient rules; none may infer behavior from colour alone.
9. Remove continuous grade/property-floor UI and old hard station caps only after zero current consumers rely
   on them.

Each checkpoint has one source test matrix and one ordinary-phone acceptance card. Engineering does not start
this sequence before the complete ComponentProfile and schematic-socket authorities validate.

## Asset sequence after content freeze

Quality frames are a separate future packet. Asset Design must not begin them until this rule is accepted.
That packet will require:

- six redundant frames in colour and grayscale;
- component socket silhouettes for the first Pointed Blade fixture;
- Gold, Adamant, Pelt, Hide, Plate, Bone, Feather/Down and Timber component treatments;
- one schematic rendered with alternate primary and secondary components while retaining object identity;
- Rough through Peerless output without changing the object's underlying silhouette;
- Storehouse stack tiles and one local pickup treatment.

## Remaining Game Design work and open tuning

Settled: 70/30 component weighting, no station quality caps and Refitting.

The required content is now authored in `crafting-components-and-schematics-current.md`. Before migration,
Engineering validates:

1. the complete World/Creature ComponentProfile dispositions;
2. all 21 physical Schematics and their closed socket lists;
3. deterministic strongest-once material effects and preview/receipt copy;
4. legacy Tier/reforge-to-band equal-performance migration;
5. the Pointed Blade rules/UI/multipart-sprite reference fixture.

The exact territory-find transaction, eligibility and presentation are now specified in
`creature-territory-finds-current.md`. Only its recommended 3%/1.5%/0.5% frequency mix remains open through
Homework `territory-find-frequency`; it is independent of the accepted crafting model.
