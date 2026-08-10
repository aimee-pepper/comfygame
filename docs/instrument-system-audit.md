# Instrument System Audit — 8 Aug 2026

**Implementation update, 8 Aug:** the field loop now exists. The Survey Post configures the next
run's instrument loadout, departure freezes it, and the mid-run Field Kit shows it alongside
out-of-combat consumables. Survey uses every carried instrument for
one world turn, stores compact permanent observations, and calibrates the Desk/History knowledge
gate. Starter instruments report crude qualitative bands. Tier 3 attributes every written focus's
scaled primary and secondary effects and preserves them in World History. Crafted good/fine
replacements remain. Tier 5 now shows sampled creature trait ranges, likely ecological roles and
flora trait/metabolism distributions from the same allocators worldgen uses. Tier 4's numerical
greed/contradiction/size/danger breakdown is built, and focus marking is derived from the page's
actual marginal stability arithmetic rather than authored prose polarity.
The red/green prose underline remains the tier-4 presentation of that derived result.

Source design: `decisions-log.md` session 8 and `crafting-spec (1).md` Part Two.

## Clause-level status

| Design clause | Status | Evidence / deviation |
|---|---|---|
| Eight field instruments, one per pressure subject | ✅ Built | Eight nodes grant the eight subject IDs |
| Instruments belong to Mara's Survey Post | ✅ Built | Station, route, research branch, costs and UI exist; Mara is `builtBy` |
| Page lens belongs to Isolde's Scriptorium | ✅ Built | Four purchasable upgrades raise analysis tier 1→5 |
| Lens tiers require increasing field kit | ✅ Built | Gates require 2, 4, 6 and 8 instruments |
| Materials follow the authored instrument list | ✅ Mostly | Named costs match the spec; the Vivometer depends on resin, which flora does not yet yield |
| Field instruments are carried into a world and take readings after generation | ❌ Missing | Buying an instrument immediately inserts its subject into a permanent global set; there is no field action, carried kit, world reading or observation record |
| Field readings feed the lens | ⚠️ Reinterpreted | The lens is gated by instruments **owned**, not observations taken. Ownership and measurement are currently the same boolean |
| Instrument grade affects precision | ❌ Missing | Instruments have no instances, materials, grade or precision |
| Readings are stored as permanent observations, like specimens | ❌ Missing | Visited worlds store resolved readings, but not instrument observations or their precision; instrument ownership alone is permanent |
| Tier 1: qualitative description | ✅ Built | Prose is always available and independent of tier |
| Tier 2: subject values only where measured | ✅ On the Writing Desk | Exact peak/floor values are limited to owned instrument subjects |
| Tier 2 gate applies in World History too | ❌ Leak | World History shows every subject at tier 2, ignoring the owned-instrument set |
| Tier 3: attribute effects to sigils, including secondaries | ❌ Missing | The page shows its written chains, but not each sigil's primary and secondary numeric contributions |
| Tier 4: greed vs contradiction breakdown and contributor marking | ⚠️ Partial | Contradictions become named and clauses gain authored red/green underlines; there is no numerical greed-versus-contradiction breakdown and underlines are not derived per contributor |
| Tier 5: living-layer distributions and predicted spawns | ✅ Built | Qualitative clues remain early; tier 5 adds allocator-derived trait ranges, ecological-role likelihoods and flora distributions at the Desk and in newly recorded World History |
| Sight and Read scale with analysis | ⚠️ Partial | Sight's combat information scales with tiers; no separate Read implementation was found in this audit |
| Analysis is crafted, not generic research | ⚠️ Functionally material-gated | Instruments and lenses are material-cost nodes in building-owned trees, not crafted item instances |

## The central design discrepancy

The source design describes a fieldwork loop:

> make instrument → carry it into a generated world → take a reading → retain the observation →
> improve what the page lens can predict

The implementation is a purchase ladder:

> buy instrument node → that subject is globally measured forever → buy lens tier → see exact values

The latter closes the progression gate but removes the reason to take an instrument into a world,
the specimen-like observation record, and the role of instrument grade.

## Settled completion design — approved by Aimee, 8 Aug 2026

### 1. Restore field measurement without making it repetitive

Owning an instrument should reveal that subject's reading in the world where the instrument is
used. The first reading permanently calibrates that subject for the page lens; later readings
improve precision rather than repeatedly unlocking it.

- One **Survey** action in a world reads every instrument carried, rather than eight separate taps.
- Surveying costs one world turn: it is a field action under the same instability pressure as
  harvesting and searching.
- Store compact permanent knowledge per subject: observations taken, observed range, and best
  precision—not every raw UI event.
- A newly made instrument is useful immediately in the field, but does not calibrate the desk lens
  until the player has taken it somewhere.

### 2. Give grade a bounded, legible job

- Crude: qualitative band and broad range.
- Good: narrower range.
- Fine: exact value.
- Lens tier controls **what kind of explanation** is possible; instrument grade controls **how
  precise the subject reading is**. This prevents two progression axes from doing the same job.

The current catalog nodes can grant a starter-grade instrument. Later crafting can replace it with
better material-derived instances when the general recipe system lands.

### 3. Preserve opacity at each lens tier

- Tier 1 — prose only.
- Tier 2 — calibrated subject readings, at instrument precision.
- Tier 3 — each written focus's primary and secondary contributions; no stability judgement yet.
- Tier 4 — numerical greed and contradiction breakdown, with marking derived from the actual
  contributors rather than authored clause polarity.
- Tier 5 — flora/creature trait tendencies, likely ecological roles, and spawn likelihoods. Move
  detailed life prediction here; earlier tiers may retain only the qualitative prose needed for
  clue deduction.

### 4. Make all reading surfaces obey the same knowledge gate

The Writing Desk, current-world panel and World History should call one shared rule for whether a
subject is known and at what precision. Historical worlds then become newly readable as the kit and
lens improve, without revealing unmeasured subjects accidentally.

## Decisions

1. **Restore the fieldwork loop.** Owning an instrument is not the same as having calibrated the
   page lens with it.
2. **Survey costs one world turn.** One action uses every carried instrument.
3. **Crude → good → fine controls precision:** broad range → narrow range → exact value.
4. **Retain qualitative flora/life forecasting at early tiers.** Detailed distributions and spawn
   predictions belong to tier 5.

These decisions resolve the design portion of this audit. The remaining items are implementation
and placeholder tuning.
