# First creature-material consumer: Hide to Leather — V1

**4 September 2026 · Decided intended behavior; unmeasured first-pass numerical tuning.**

This is the bounded next production extension after the early plant-cloth Tannery. It adds only the actual
Salt, covering materials, processing and garment needed here. It does not replace the full creature cast,
require a named Earth animal, or block the first Salve, Pick, Scythe or woven garments. Exact rows accompany
this document in [early-leather-production-v1.json](early-leather-production-v1.json).

## 1. Material assignment follows generated anatomy

Use the existing energy-budgeted creature generator, persisted habitat, primary-covering priority,
covering measurements, body plan and contact-eligible placement rules. Do not assign a grazer or force a
Hide-producing body into every world. The existing morphology priority first determines whether the
primary covering is Hide at all. Feathers, Scales, Shell, Chitin, Plate and Pelt do not become Hide just to
feed a recipe. This slice only subdivides a primary `hide` result:

| Exact subtype | Additional classification after primary Hide wins |
|---|---|
| Smooth Skin | Aquatic habitat or piscine body plan |
| Supple Hide | Otherwise, covering hardness below 25 |
| Tough Hide | Otherwise, covering hardness at least 25 |

IDs and predicates are in JSON. This is generation-time physical classification. A recipe later checks
those exact IDs; it never asks the player for an invisible hardness threshold. Existing primary-covering
rules already require coverage at least 15 and exclude inappropriate harder/longer coverings first.
Name, hue, ornament and species identity remain generated. Source colour follows the frozen creature.

For a qualified creature, a **70%** primary-covering reward roll on defeat yields the existing size-based
quantity `clamp(1 + floor(size / 25), 1, 4)`. Freeze the possible reward, quantity and quality on the creature;
add a versioned per-foe covering-roll receipt and consume its frozen decision once; do not assume the current reward model already contains such a roll. The player can see recipe relevance without inspection, but
that means a possible drop, not a promised one. This row replaces the old primary-Hide reward branch for
new-generation creatures; it must not append a duplicate reward to the legacy family projection.
Other anatomical rewards remain their existing versioned rules, and are not silently promoted to newly
invented subtypes by this packet. No harvesting tool is required after defeat. Avoiding an animal remains
valid; none of this is required for the ordinary starter path.

Do not alter enemy population or combat difficulty to manufacture materials. Retain the existing minimum
65% contact-eligible ordinary-placement policy, entry protection and guardian-habitat checks. Habitat
components now read the saved new region/liquid facts and actual passable graph, not a water colour.
At least two tiles are still needed for an eligible habitat component. A species without a legal component
is not placed. The frequency check reports how often real eligible creatures occur; it must not turn a
failed material-frequency target into a body-plan override.

## 2. Four real quality bands and retained source values

For these covering parts, `partExpression` is the **unrounded** mean of covering coverage and the existing
derived flexibility. Flexibility is `clamp((100-hardness) * (0.5+length/200), 0, 100)`. Score is rounded half
up once after `0.75 * partExpression + 0.25 * sourceWorldDangerValue`. Danger 0–5 maps to 20/35/50/65/80/95
before party/debug scaling. Use Poor 0–24, Common 25–59, Rare 60–84, Exceptional 85–100; stat multipliers
0.75/1/1.25/1.5. Do not reuse the obsolete six-band projection or round the part mean before scoring.

Freeze colour, coverage, hardness, length, flexibility, covering protection (`hardness*coverage/100`),
source-world Danger and band in the source lot. A material's quality does not change its quantity. Do not
recompute saved quality after future tuning or a party-level change. Older ambiguous creature stock keeps
its supported legacy uses; only exact retained anatomy may classify a subtype, without duplicating balance.

## 3. Salt is a real separate geological producer

`world.salt` is ungraded Salt; proven old scalar Salt maps 1:1 with old value overrides, never fabricated
provenance. `early.gather.salt_crust.v1` requires a saved physical salt-crust deposit on an entry-connected,
passable, unfrozen, unsubmerged site with salinity at least 60. White terrain is not proof of Salt.

**5 September closure:** ordinary current shoreline adjacency may generate **saline shore deposition**;
it does not prove a receded shoreline. No recession-history simulator is required for this slice. The
previous `receded_saline_liquid_margin` wording is replaced for new ordinary generation by a truthful
`saline_shore_deposition` host basis. Do not add fictional historical events to a saved world.

A shoreline candidate is empty, unprotected dry soil or sand, cardinally adjacent to actual `water` or
`deepWater` whose resolved identity is ordinary water with known chemistry and salinity >=60. The current
map's shoreline topology is used; this does not implement the future physical water-height renderer.
Mud is not dry exposed salt crust. Ice, snow, liquid, stone, ash, broken ground and unknown surfaces do not
qualify. A whole-region salinity value without an actual adjacent liquid tile is not shoreline evidence.

For an original region with eligible shoreline sites, draw once at the existing **50%** chance. A success
resolves an exposed salt-crust deposit opportunity only at those eligible sites. If there are no eligible
shoreline sites, an arid region with known ordinary-water chemistry, salinity >=60 and available root
water <25 may instead take the **35%** evaporite roll. Its success resolves **both salt-bearing evaporite
and exposed salt-crust deposit opportunities** on eligible dry soil/sand sites. It does not merely create
an inaccessible buried formation and then wait for an unspecified second exposure mechanism. A failed
shoreline roll does not also try the arid roll. The two branches never stack their probabilities.

Salt crust is a saved site-level surface deposit over its recorded base substrate. Keep the actual base
ground, bedrock, elevation and liquid facts; do not replace every surface in the region or drain/thaw the
map. Persist the basis, original region, roll result and exact eligible/selected anchor facts under a
versioned new-generation contract. Exact existing soil/sand values are eligible base substrate; “exact”
in the region adapter is not by itself an authored ban on a surface deposit. An explicitly assigned or
protected incompatible surface, critical/occupied site or already-promised content cannot be overwritten.
A selected salt source occupies that anchor before optional flora; it cannot also host a gatherable plant.
No salt host flag can grant inventory without the actual placed finite producer.

Use a stable separate stream per original region and branch, never per rendering, harvest, source depletion,
new region partition or retry. Freeze host eligibility before allocating optional sources and preserve it
through later map adapters. Old worlds keep their saved contents; missing legacy physical facts do not
backfill new ordinary Salt or invent recession history. The generic first-pass written-resource rules are
intended authority, but the exact callable Salt binding is not closed and no executable written-Salt adapter
is established by this packet. Ordinary Salt does not require that adapter. See the precise remaining
decisions below; do not invent a trigger, terrain preparation, guarantee or before-spend refusal for Salt.

One eligible Salt gather is reserved within the existing loose-earth budget after written guarantees and
ordinary Clay reservations. If the budget or legal placement is exhausted, it competes in future eligible
worlds; do not enlarge the starter budget to guarantee every material. It is one underfoot hand action,
2 Salt, then depleted. No Pick, tool level, regrowth, hidden hazard or arbitrary Salt appearing in fresh
forest is added. Ordinary source route targets remain 4–12/6–24, with recorded legal small-map fallbacks.

## 4. Corrin processes Leather and makes a useful garment

At the built T1 Tannery, learn **2 of one exact eligible Hide/Skin subtype, one band and one output-equivalent source group +
1 Salt → 1 Leather** for zero Essence. Eligible inputs are exactly Smooth Skin, Supple Hide and Tough Hide.
Leather retains that input quality, source measurements and colour beneath its stack. Two Poor parts do
not become Common; two qualities or colours cannot silently average into a new one. Pelt, Chitin, generic
legacy Hide, Cloth and unrelated soft material are not implicit substitutes. This is a new optional recipe,
not a replacement for the initial Cloth/Cord crafts and not a new facility gate.

**Leather Guard:** 2 matching Leather from one output-equivalent source group/band/colour + 1 Plant Cord, no Essence,
Tannery T1, Body slot. This adds an alternative physical garment, never automatic replacement/equipment.
Its total Protection is:

`roundToQuarter(4 * (0.50 + retainedCoveringProtection / 200) * qualityMultiplier + 0.25)`.

The 4-point primary ceiling and baseline/measurement/quality formula follow the published role model;
Cord contributes the fixed 0.25 structural amount and no Initiative. There is no extra quality-base added
afterwards, heat ward, accuracy, durability or random affix. Show the actual final Protection before paying.
Only the Leather primary socket votes for finished quality: Poor→Rough, Common→Fine, Rare→Superior,
Exceptional→Exceptional. Minor Cord does not drag quality toward Fine. Body and ties keep their chosen
material colours; quality stays on name/border. Leather remains intermediate stock, not Peerless equipment.

Dismantle the finished garment to its recorded 2 Leather + 1 Cord, not raw Hide/Salt as well. Processing
has no reverse action. Salt is consumed and never returned. JSON gives four-band sale values and twice-sale
purchase values; purchase listings remain subject to normal stock. These values are chosen so buying raw
parts, processing, crafting or dismantling cannot generate profit at base prices. Preserve legacy values.
Source-lot selection, durable save, Return custody and finished-item destination follow the earlier packets.

## 5. Minimum production and acceptance evidence

Hand-authored fixtures in JSON close two distinct physical producers using the existing primary-covering
rules: one terrestrial soft-covered body and one shallow-water soft-covered body. They are **integration
fixtures**, not fixed species to inject into campaigns. Generate actual animals normally and apply the
classifier after morphology is complete. This avoids an entire speculative creature catalogue prerequisite.

From an already-built Tannery, one Leather Guard needs **4 matching raw parts, 2 Salt, 2 Plant Fibre**.
That includes both Leather operations and one Cord operation. At size-band 2 a successful covering drop
provides two parts; two successful drops therefore suffice. At 70% success, two successful rewards require
about 2.86 eligible defeats on average, **not a guarantee or measured expedition count**. Source-lot matching,
habitat occurrence, travel and combat may extend this; report them separately. More valuable creature
variants and chosen colours can remain exploration goals beyond a single useful trip.

Engineering checks: primary-covering exclusions; three exact classifications at boundaries; size quantities;
once-only 70% reward across relaunch; source-Danger-before-scaling and unrounded-mean four-band boundaries;
actual reachable habitat/shore contacts; no Salt without a physical host; Cloth route still usable without
any creature or Salt; exact processing homogeneity; stat preview/quality formula; base-price and merchant
modifier no-arbitrage; old-world/legacy-material preservation; failure/duplicate reward/Return/craft rollback.
In seeds 0–999 report eligible creature share, contact accessibility, successful primary rewards and matches
large enough for one Leather, plus Salt host/placement rates. No arbitrary minimum is imposed on every biome.
Evaluate complete garment journeys in compatible worlds before claiming ordinary availability is pleasant.

**Ready:** subtype projection, qualified reward, four-band source retention, Salt host/producer, Leather
process, one meaningful garment and exact fixtures. **Depends on:** the current-model creature projection,
new region adapter and source-lot/custody implementation; not a whole replacement creature generator.
**Still separate:** additional anatomical families and consumers, expanded creature ecology, broad encounter
balance and later facilities. This packet does not claim those catalogues are finished or runtime-delivered.

## Source grouping clarification

A source group is not one harvested instance or one historical receipt. Combine owned units whose exact
material subtype, quality (when present), colour and recipe-relevant source measurements are identical,
while retaining every parent receipt and selected quantity. Two matching patches may supply one Cloth;
two matching animals may supply four Hide. No numerical averaging, guessed provenance, or loss of parent
identity is permitted. In the picker, identical-result groups need no duplicate choices. Different
measurements or colours still require an explicit choice; grouping never makes an ineligible type qualify.

## Narrow implementation authority and broader creature status — 5 September 2026

PM relayed Aimee's direct approval of this packet's Hide producer and required habitat projection, now
recorded at the top of `docs/documentation-authority-current.md` in the shared checkout. Her boundary:
“Just no further UI/integration work on the bestiary in the library. Until game design has finished the
creature rework, and as far as I know that hasn’t happened”. This supersedes the historical blanket hold
only for the approved Leather producer/projection scope. It does not dispatch Library Bestiary work,
a broader creature catalogue or additional paid searches.

The wider creature rework is not complete. The retained 4 September former-Design handoff still lists
body-plan/habitat/creature-material work to finish; this packet closes only the named primary-Hide, Salt,
processing and Leather Guard route. Additional anatomical families/consumers, expanded ecology and broad
encounter balance remain separate. Earlier ecology specifications and their obsolete six-band passages
are not a current comprehensive completion receipt. No Library integration automatically resumes from
this packet's readiness or eventual bounded runtime acceptance.

## Written Salt: exact binding remains unclosed — 5 September 2026

The phrase “existing written Salt guarantees” in earlier revisions overstated the retained authority.
`resource-world-first-pass-tuning-v1.md`, Geological placement, settles a generic base-resource promise:
one hand-gathering placement, two units, entry-connected within 3–8 movement steps, ordinary-budget credit
and truthful quote. Its compatibility section settles a disclosed winner/influence when competing direct
promises cannot coexist. Neither section maps Salt's concrete grammar to that promise.

`pressure_sources.json` permits Salt on Hydrology, Substrate and Vitality, with their existing salinity,
ground and life-pressure contributions. The recovered Salt lesson names a substrate source. These are not
a closed presence-guarantee trigger. `early-written-iron-guarantee-v1.md` explicitly closes Iron only;
copying its negation, local outcrop permission or refusal into Salt would be a new decision.

Still needed for the Salt adapter: (1) exact qualifying source/target, intensity, local denial and canonical
compound/dedup rules; (2) permitted host preparation when no exposed compatible saline site exists,
including whether any local salinity or substrate can change; (3) exact quote/spend disposition for
physical or capacity failure, distinguished from the already-closed competing-guarantee conflict rule.
No automatic guarantee on every Salt sigil, new vocabulary, chemistry rewrite or inferred refusal is
selected here. This is a Design dependency, not Aimee Homework; ordinary Salt and the approved Leather
producer/consumer scope can proceed independently. Old worlds and pressure-only Writing stay intact.

## Anatomy and placed-body compatibility — 5 September 2026

The primary-covering quantity formula is **base yield**. Preserve the existing earned, expedition-frozen
`AnatomyButcheryReceiptV1` after a successful 70% drop. Use its current strongest-once formula:
`final = base + max(1, floor(base * 35 / 100))`. For base 1/2/3/4, Anatomy gives 2/3/4/5; without it the
base remains 1/2/3/4. The 70% chance is unchanged, and a failed roll yields zero even with Anatomy. The
minimum +1 must never manufacture a drop on failure. Bonus units have the same exact subtype, quality,
source colour and parent identity. There is no new benefit, fee, stacking or quality bonus. Later roster,
respec or health changes do not rewrite the saved departure bonus; other anatomical rewards stay unchanged.

Add a real versioned per-foe covering-roll receipt for new-generation typed covering rewards, preserving
eligibility, base quantity, policy and random decision before evaluating the reward. Persist the applied
existing departure Anatomy receipt and final quantity in the committed reward result. Save/retry/reopen
cannot reroll success or apply the bonus twice. Old creatures and already-resolved rewards retain their
existing policy; missing old roll data is not fabricated. Report base and bonus separately when measuring
yields. The earlier average-defeat calculation describes base-yield tuning without an Anatomy benefit.

Typed Hide is a replacement, not an extra body reward: the persisted species projection must contain an
existing primary Hide branch **and** the actual placed body's established primary-covering priority must
still resolve eligible Hide. Use the actual placed measurements for the typed source, retaining the parent
species projection and exact source evidence. A species-level Pelt branch cannot gain new typed Hide merely
because specimen jitter looks softer; nor can an ineligible placed covering be typed as Hide. Never grant
both the replaced legacy Hide and its typed replacement. Preserve other family branches. On a mismatch,
keep the supported legacy reward policy, grant no newly typed Hide, and do not claim full creature-material
migration. New Leather recipes continue to require exact Skin/Supple/Tough stock. Reprojecting all coverings
or migrating other anatomical families remains outside this bounded slice.

## Leather colour identity and prepared grouping — 5 September 2026

No exact accepted native creature-to-sRGB conversion is established by the inspected source. The current
`CreaturePixelIdentity` uses primary/orange functional silhouettes; the world-grade species conversion
belongs to flora, the ink conversion belongs to authored ink/paper, and the old AssetLab creature generator
is prototype presentation. None supplies an authoritative Leather body swatch. Do not copy these formulas
or choose a plant palette as a creature colour. Exact creature/material RGB and pattern presentation remains
unaccepted, without opening Library Bestiary UI/integration or assigning new final artwork.

For the functional Leather slice, the actual typed-source receipt's full validated frozen `Coloration`
(Cyan, Magenta, Yellow, Depth, Patterning) is the source-colour identity. Compare those exact saved values,
without averaging, rounding, normalizing again, or rerolling. A missing RGB receipt alone is not unknown
colour: the source descriptor already exists. Preserve it through Hide, prepared Leather, the Guard's body,
and prepared-component salvage. Truly missing or malformed source colour cannot establish a matching group.
Never repair missing historical evidence through `Coloration` default values or a species/world lookup.
A neutral functional icon or source text may support transactions, but is not proof of the chosen swatch;
keep exact rendered source-to-Leather/garment colour acceptance pending. A later versioned renderer must
consume the retained descriptor without replacing its source or rewriting old choices.

Raw Hide/Skin processing still requires one exact eligible raw subtype plus matching band, full colour and
relevant measurements. Prepared output is the single `processed.leather` material. For the Guard's two
Leather units, raw ancestry does not itself split an otherwise identical-result group: match quality band,
full frozen Coloration, coverage, hardness, length, flexibility and covering protection exactly. Historical
animal/world IDs, raw subtype and source Danger remain in every parent receipt but are not extra group
keys when all the recipe's output-relevant values match. Do not average different measurements or colours,
discard parents, or let this rule turn an ineligible raw family into Leather. Guard body retains selected
Leather colour identity, ties retain the existing Cord colour, and each remains its own component lineage.
