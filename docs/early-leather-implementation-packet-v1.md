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
use its persisted defeat-reward roll once. The player can see recipe relevance without inspection, but
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
backfill new ordinary Salt or invent recession history. Existing written Salt guarantees must also resolve
a compatible physical host; the ordinary probabilities do not veto a valid written guarantee or create an
additional bonus deposit. No new written-Salt geometry or vocabulary is added by this clarification.

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
