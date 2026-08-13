# Catalogue item identity — tier-2 slice

**Status:** handmade-art semantic brief for the first eleven uncovered catalogue items.  
**Scope:** exact live IDs only; 32px six-across inventory/loot/Trading Post/Recycler/equipment use.  
**Authority:** item mechanics and prose remain `Sources/Content/Data/items.json`; Aimee owns final
handmade pixel execution under `handmade-art-ownership-current.md`. This document owns the dominant
object read and collision boundaries; AssetLab may provide only labelled placeholders and conformance.

## Shared rules

- The icon depicts the actual object, not “uncommon,” “tier 2,” its stat increase or its shop.
- Related tier-1/tier-2 objects may share construction ancestry, but tier is never a universal extra
  band, larger silhouette, brighter color or more symmetry.
- Use one dominant mass and one meaningful secondary feature at native size. Tiny scratches, polish
  and hue differences cannot own identity.
- Quantity, rarity, equipped owner, selected/favorite/locked, buy/sell/recycle eligibility and upgrade
  arrows remain outside the object pixels.
- Literal grayscale must preserve every distinction below.

## Exact referents

| Live item ID | Dominant object read | Required distinguishing feature | Must not collapse into |
|---|---|---|---|
| `blade_keen` · Keen Blade | slim, balanced close blade with a centered short guard | clean leaf/needle transition and visibly balanced grip-to-blade proportion | Chipped Blade's damaged irregular edge; Bone Awl's handle-first spike; generic upward triangle |
| `raking_edge` · Raking Edge | close cutting blade with one materially toothed/raked side | 3–4 silhouette-scale backward notches on one edge, large enough to survive grayscale | smooth Keen Blade; Ripping Hook's single dominant hook; generic saw/tool |
| `banded_mace` · Banded Mace | short-hafted compact crushing head | two broad load bands wrapping/dividing the head, with mass still concentrated at the striking end | Field Maul's long rectangular head; Banded Buckler's round face; generic hammer |
| `warded_spear` · Warded Spear | mid-reach spear with a long straight shaft | a clear cross-stop/paired lugs immediately behind the point, expressing controlled distance | Long Pick's asymmetric mining head; Ranked Spear's through-going apex form; fencing-person symbol |
| `banded_buckler` · Banded Buckler | small round hand shield | two broad reinforcement bands crossing the face and a visible off-center grip/boss relationship | Split Board's broken plank silhouette; Banded Guard's torso bands; generic heraldic shield |
| `ridged_helm` · Ridged Helm | open protective head shell | one strong raised ridge that changes the outer crown profile and directs blows sideways | Padded Cap's soft round outline; Visored Casque's closed face; dotted circle |
| `guard_banded` · Banded Guard | wearable torso guard | three overlapping horizontal protective bands following the chest, with open neck/arm ownership | Banded Buckler's circular face; Padded Guard's continuous soft vest; standalone shield |
| `studded_gloves` · Studded Gloves | paired work/fighting gloves | a broad raised knuckle row on each glove, visible as silhouette/value masses rather than tiny dots | Wrapped Hands' cloth spirals; Gauntlets of Hold's enclosed heavy cuffs; single raised-hand glyph |
| `shod_boots` · Shod Boots | paired wearable boots with distinct uppers and soles | blunt metal toe caps that visibly change the front mass, plus one solid sole edge | Worn Boots' soft collapsed toes; Longstriders' lengthened stride form; detached footprints |
| `balanced_pick` · Balanced Pick | deliberate two-handed pick tool | centered haft and intentionally counterweighted/symmetric head balance, while one side remains the working point | Bent Pick's visibly crooked alignment; Corebreaker's concentrated heavy wedge; crossed tools |
| `cold_compass` · Cold Compass | palm-sized round compass/instrument | a suspended needle visibly committed to an unusual diagonal/bearing inside an open ring; one cold-notch/star geometry may support but not replace the needle | Pressed Leaf's organic flat shape; generic sparkle; Cache Key; ordinary north-arrow navigation icon |

## Pair-specific checks

### Weapons

- Keen Blade and Raking Edge must remain distinguishable with their guards/handles cropped to the
  same footprint: the former owns clean balance; the latter owns repeated one-sided teeth.
- Banded Mace and Balanced Pick may both have transverse heads, but the mace is a compact terminal
  mass while the pick is a long tool head balanced around its central haft.
- Warded Spear's cross-stop belongs directly behind a piercing point. It cannot read as an off-hand
  shield attached to a generic spear.

### Worn gear

- Banded Buckler and Banded Guard deliberately share banded construction, but one is a compact round
  held object and the other is an open-neck torso garment.
- Ridged Helm, Studded Gloves and Shod Boots show actual wearable shapes. Slot recognition must not
  depend on a head/hand/foot SF Symbol surrounding an otherwise generic material blob.

### Keepsake

- Cold Compass may remain mysterious, but “mysterious” cannot mean sparkle noise. Its needle and
  casing must support later anchored detail explaining that it points somewhere other than north.
- Do not animate or rotate the inventory identity. If the object later has a world-facing effect,
  state/animation is a separate reviewed layer.

## Required proof

1. One lossless sheet shows these eleven beside their exact accepted tier-1 comparison identities at
   native 32px, six across, in color and literal grayscale.
2. A silhouette-only row removes internal color and proves every tier-2 object remains distinguishable
   from its tier-1 counterpart and from the other ten tier-2 objects.
3. The same exact item ID produces identical object pixels in Stored, loot, Trading Post, Recycler and
   equipment contexts; only surrounding state changes.
4. Pairwise occupied-shape comparison flags near-identical silhouettes for human review rather than
   accepting a different palette/accent.
5. Exact-ID mapping fails closed on an unknown item and never falls back to the catalogue SF Symbol.
6. VoiceOver/name/detail remains authoritative; icon recognition is reinforced after inspection, not
   treated as the only way to learn an object.

## Later slices unaffected

This brief does not authorize tier-3/tier-4 visual escalation, treasure/core identities, wild apex
weapons or crafted-family procedural adaptation. Those remain separate bounded sets in
`asset-dynamic-coverage-audit.md` so one successful tier-2 grammar cannot be extrapolated into
forty-eight unreviewed icons.
