# Authored colored ink and open color resolution — current design

**Status:** current implementation-ready CMY + Depth economy. Color-space coefficients and the
12-application vial yield remain reversible playtest tuning.  
**Owner:** Game Design owns authorship/randomness; Asset owns calibrated conversion and patterns;
Engineering owns mixing, binding, persistence and rules-owned scope.  
**Supersedes:** the provisional twelve collectible named-color qualifier catalogue formerly in this
file. Its Asset proof remains useful accessibility research, not live vocabulary authority.

## Core distinction

The starting writing medium is **Rough charcoal**. After the Brush is learned, the ordinary liquid
medium is **Ash ink**. Both draw a dark readable page mark but semantically mean **color
unspecified**; neither asks the world to make that focus black.

The player may instead mix a **colored ink** and write a focus with it. That mixed ink is an explicit
color instruction on the focus.

| Page state | Stored authorship | Bind meaning |
|---|---|---|
| Rough charcoal | `inkRecipe: nil`; crude hand | Color remains fully open; mixed liquid ink is ineligible |
| Brush/Fountain pen with Ash ink | `inkRecipe: nil` | Color remains fully open to the world's bind-time roll |
| Mixed ink | exact CMY + Depth recipe | This focus resolves from the written color recipe |
| Explicit mixed black | non-nil recipe whose result is black | The player deliberately asks for black |

Ash and explicit Black may look similarly dark on the paper, so the UI must distinguish them by
name/pattern/state. They are never inferred from rendered pixels.

## Why subtractive CMY, not RGB

Use a subtractive ink model. RGB describes emitted light; the player is mixing pigment on a page.
CMY also produces intuitive physical relationships:

- Cyan + Yellow → Green
- Magenta + Yellow → Red
- Cyan + Magenta → Blue/Violet
- all three together move toward neutral/dark

The player-facing controls are **Cyan · Magenta · Yellow · Depth**. Depth is the black (`K`) channel
but avoids making the standard Ash medium sound like a selected K value. The system may be called
CMYK in technical/debug documentation; ordinary UI says **Mix ink**.

Each channel is an integer `0...100`. At least one of C/M/Y/Depth must be nonzero to save/apply a
mixed recipe; the all-zero state is “No colored ink mixed,” not White. Ink cannot author White by
adding white light. Pale colors come from low pigment/depth over the page/world material, subject to
the renderer's legibility clamps.

## Ink is an attribute, not another page rune

Colored ink does **not** consume another page cell and is not a `QualifierDef` ladder. It changes the
medium used to write one source/focus mark; it does not add a new word beside that focus.

- A source/focus mark stores optional `InkRecipe`.
- Its connected target and modifiers may render in the same ink for a coherent written sigil, but
  only the source's stored ink owns world-color meaning.
- With chaining, each source may carry a different ink recipe. Connection/set/placement order never
  chooses which color belongs to which source.
- Re-inking a focus is an edit to that mark. Before binding it costs no Essence and changes no world.
- Target-only and qualifier-only components cannot declare a global color. Until connected to a
  source they may be drawn with the current pen color as page presentation, but validation names the
  absence of a color-bearing focus.

Color remains mechanically visual: it changes no pressure contribution, greed, Stability, heat,
toxicity, visibility radius, resource chance, species stats or encounter difficulty.

## Penmaker progression gate

Rough charcoal is the Binder's starting tool. **The Brush is the first ink-capable hand**, and
deliberate ink mixing is unlocked by Isolde's Scriptorium as an adjacent Penmanship node; neither is
available at a new save's Writing Desk and neither introduces another traveller or shop.

The first color-capability node is **Ink Mixing**: a Scriptorium tier-1 upgrade directly after the
**Brush**.
Buying it permanently adds the Ink well and saved-mixture library to every Writing Desk. This
placement is reversible tuning, but the ownership is settled: Isolde teaches the Binder to make and
control colored inks. The fountain pen and Scriptorium tier 2 are not required for ordinary mixing.

Before Brush, every mark is Rough charcoal. After Brush but before Ink Mixing, Brush marks use Ash.
Both leave world color open. This makes the progression legible: early writing discovers colors
through world generation; the Penmaker first teaches liquid ink and then deliberate color. Existing
saves migrate the old Pencil hand to Brush without repurchasing it; Ink Mixing remains its own
capability rather than being granted by that migration.

## Mixing and saved inks

The Writing Desk has a compact **Ink well** control. Ash is always the default and always available.
Opening Mix ink shows:

- four Cyan/Magenta/Yellow/Depth sliders with numeric accessibility values;
- a large resultant swatch plus deterministic redundant pattern;
- a plain generated description such as **deep teal** or **muted red**, labelled as descriptive
  rather than a separate collectible word;
- **Use for next focus**, **Apply to selected focus**, **Save mixture**, and **Return to Ash**;
- a small set of ordinary preset shortcuts (Red, Yellow, Green, Cyan, Blue, Violet, Neutral dark)
  generated from the same recipes. Presets are convenience, not owned vocabulary or stronger inks.

Saved mixtures store exact channel values, conversion version, pattern ID/seed and an optional player
label. There is no arbitrary hard cap in the first slice; sort pinned, then recent. Duplicate recipes
may share one saved entry without changing marks already using it.

## Pigment bases and the resource loop

`ink-economy-friction-audit-current.md` preserves the recipe below and owns the reversible first-slice
interaction: vial preparation automatically processes the minimum exact world-resource shortfall.
Stored measures remain real station-local state, but separate manual pigment processing is not an
ordinary player-facing action unless later play proves that batching decision worthwhile.

Ink Mixing teaches a process; it does not create pigment. The Scriptorium prepares four stored base
stocks—**Cyan, Magenta, Yellow and Depth**—from world resources. A saved mixture is a formula, not
inventory. Preparing a vial from that formula consumes the quoted amounts of those base stocks plus
an ordinary binder; the vial then supplies a bounded number of colored focus applications.

The first economy proof uses **12 applications per vial** as a DEBUG-visible placeholder. Applying,
moving, recoloring or removing marks while drafting reserves nothing. Binding atomically consumes one
application for each mixed-ink source mark in the committed page; cancel, failed validation and stale
commit consume none. Repeated linked components rendered in the source's ink do not cost extra. Ash,
blank pages and uncolored marks cost no pigment.

This keeps experimentation free but makes deliberate color part of the world-resource loop. Ash is
unlimited, so missing pigment can never prevent an ordinary bind or campaign continuation. Existing
colored pages/vials preserve their frozen recipe/yield version if later tuning changes batch size.

### Resource provenance boundary

Do not assign a base from an item's name or rendered pixels. Pigment yield must be an authored or
persisted property of the exact world resource:

- fungible minerals may own a versioned canonical pigment-yield profile;
- flora/creature-derived resource samples may freeze a pigment profile from the source species when
  harvested, alongside their existing provenance/properties;
- a qualifying sample may contribute several bases in truthful proportions; processing records the
  exact consumed stable sample and resulting base receipt;
- generic Toxin/Reagent/Pulp is not automatically Magenta merely because a recipe needs a red
  ingredient. If source coloration was not persisted, it cannot claim that color after the fact.

The first live recipe family is:

| Base | World resource | Reason / gate |
|---|---|---|
| Cyan | **1 Copper → 4 Cyan measures** | A processed blue-green copper pigment; Copper remains recognizably copper before processing |
| Magenta | **1 Ichor → 4 Magenta measures** | Ichor is already a rare world resource with a canonical dark-magenta identity; no fabricated generic biological sample is needed |
| Yellow | **1 Sulfur → 4 Yellow measures** | A truthful strong mineral yellow with a deliberate world-writing route |
| Depth | **1 Obsidian → 4 Depth measures** | A dark volcanic pigment, distinct from unlimited semantic Ash |

Processing is lossless and deterministic: one exact resource unit becomes four measures of its one
base. It costs no Essence and no Resin. **Preparing** a vial consumes stored measures first, then
automatically processes the minimum whole source-resource units needed for any shortfall, retains
the excess measures, and consumes one Resin. For each channel, the vial costs `ceil(channel / 25)` measures when that
channel is nonzero and zero otherwise. Thus a 100-Cyan vial costs 4 Cyan measures + 1 Resin; a
100-Cyan/100-Yellow green costs 4 Cyan + 4 Yellow + 1 Resin; an explicit four-channel maximum costs
4 of each base + 1 Resin. Slider values stay exact even though stock cost uses four readable bands.

The vial supplies the current DEBUG placeholder of 12 focus applications regardless of mixture.
This keeps cost legible, avoids fractional stocks and makes complex dark mixtures more materially
demanding without charging for experimentation. The preparation preview must show exact existing
measures, source-resource shortfall, retained excess, Resin and applications before confirmation.
The combined processing/preparation transaction is atomic; cancel, insufficient stock, interruption
and stale confirmation consume nothing.

Ichor's rarity is acceptable because deliberate color is optional and Ink Mixing arrives after the
opening. Trading Post stock and authored Ichor-producing worlds provide independent acquisition
routes. Do not grant a magical free Magenta stock with the upgrade. If play shows Magenta functionally
unavailable, tune Ichor access or add a second explicitly authored magenta resource recipe; never make
an arbitrary colorful sample qualify. Later Scriptorium nodes may improve yield or organization but
must preserve the four base identities.

## Scope remains game-owned

The player chooses a mixed ink and a focus, not a rendering scope. The closed source-ID mapping still
derives where that focus's color can truthfully act. First proof/live mappings remain:

| Source | Scope | Colored-ink result |
|---|---|---|
| Sun | Emitter | hue/chroma of that Sun's current emitted light |
| Smoke | Atmosphere | scattering color of explicit visible smoke |
| Granite | Material | bounded eligible granite-material palette |
| Bloom | Flora | generation-time flora palette tendency persisted per species |

Flora and Creature remain separate. Bloom ink cannot recolor creatures. Unsupported sources reject
colored ink before bind with **“This focus has no visible color to direct yet.”** Ash remains valid on
every source because nil makes no unsupported request.

The allowlist grows only when rules provide a truthful consumer. Asset code never derives scope from
target, pressure contribution, name, list order or the ink color itself.

## Unspecified color is genuinely open

At bind, every resolved visible identity whose color was not explicitly authored remains eligible for
the full color-generation range appropriate to its scope. This includes:

- an Ash-written eligible source;
- a source the world generated into an unwritten subject;
- ordinary generated flora/creatures/material/atmosphere/emitters with no written color instruction.

“Open” does not mean a neutral beige fallback or a runtime reroll. Game rules draw once from a
versioned perceptual gamut/distribution during world binding and persist the exact resolved recipe or
species coloration. The range includes vivid, muted, warm, cool and achromatic outcomes where that
scope can truthfully support them. It is not restricted to a small named-swatch list.

Randomness operates at identity-appropriate scale:

- material/atmosphere/emitter declarations resolve once per source instance/family as defined by the
  game descriptor, never independently per tile/frame;
- flora and creature colors resolve into persisted species identities, with bounded specimen jitter
  that cannot change species identity;
- a world-level palette compositor may keep simultaneously rolled layers readable/coherent, but it
  cannot erase or replace an explicit ink recipe.

Resolved random color is a meaningful resolved fact. Two worlds with the same pressures but different
color rolls may legitimately look different; two worlds with similar resolved colors should still
look related. This refines—not rejects—the relative-diversity rule: visual distance follows both
authored facts and persisted random outcomes, never world ID or a novelty quota.

## Preview and disclosure

For a colored eligible focus, the Desk previews the authored color and truthful scope:

- “This Sun's light will carry your deep yellow ink.”
- “Visible smoke will carry your muted violet ink.”
- “Granite may form in these red tones.”
- “Flora shaped by Bloom may favor these blue-green tones.”

For Ash/unwritten color, preview says **Color left open** and shows a restrained multi-swatch range,
not one promised neutral sample. It must not reveal the actual bind roll before the player commits if
other open world facts also remain unresolved. A DEBUG deterministic preview may show fixture seeds
but is clearly development-only.

The Desk never reveals that hidden smoke/flora/resources/creatures will exist. In-world appearance
may reveal color before its cause is analysed, but minimap/fog/POI disclosure remains unchanged.

## Data and persistence contract

Recommended closed types:

```text
InkRecipe {
  cyan: UInt8       // 0...100
  magenta: UInt8    // 0...100
  yellow: UInt8     // 0...100
  depth: UInt8      // 0...100
  conversionVersion: String
}

PlacedRune.inkRecipe: InkRecipe?   // meaningful on source marks
```

Binding converts a non-nil recipe through one versioned subtractive/perceptual transform and persists
the resulting game-owned scoped color declaration with source instance/ID and scope. A nil recipe
invokes the versioned scope randomizer and persists its resolved output. Renderers consume only these
persisted resolved facts.

- Existing pages decode missing ink as nil/Ash/open.
- Existing bound renderer-v1 worlds retain their historical tuple/pixels; migration does not roll
  new colors into them.
- Newly bound worlds store color resolver/randomizer versions and exact outputs; save/load, redraw
  and anchored revisit never reroll.
- Editing a saved ink formula never changes marks/pages already storing its exact recipe.
- Do not store platform `Color`, CSS strings or a generated color name as authority.

## First implementation checkpoints

1. **Unlock + mixer proof:** native-sized locked Ash-only Desk and unlocked mixer after Isolde's
   Scriptorium Ink mixing node, with four sliders, presets, saved mixtures, patterns, VoiceOver,
   grayscale and large text. No world effect yet.
2. **Page schema:** optional exact recipe on source marks; ash/mixed-black distinction; re-inking,
   connection and save/load fixtures.
3. **Scoped bind:** Sun/Smoke/Granite/Bloom explicit conversion plus nil/open random resolution;
   persist exact recipes and versions.
4. **Asset/native conformance:** explicit and random near/mid/far colors preserve terrain/species/
   disclosure grammar and relative resolved diversity.
5. **Phone play:** write the same focus once in Ash and several mixed inks, bind repeated controlled
   worlds, and verify that Ash outcomes span the open range rather than collapsing to black/neutral.

## Acceptance gates

1. Ash Sun is visually ash-black on the page but can resolve to any valid emitter color; it does not
   request black.
2. Explicit mixed Black Sun reliably resolves black/dark emitted color within legibility clamps and
   is visibly/semantically distinguishable from Ash before binding.
3. CMY primary/secondary relationships match the mixer preview; Depth darkens without changing
   visibility radius or mechanical intensity.
4. Applying ink uses no page cell and attaches to the selected source regardless of connection order.
5. Unsupported colored source rejects before Essence spend; the same source in Ash remains legal and
   open/default.
6. Nil random resolution spans the reviewed gamut/distribution over deterministic seed sweeps, with
   no neutral/black collapse and no per-frame/tile noise.
7. Explicit recipes override only their source scope; random other layers remain open and cannot
   overwrite the explicit result.
8. Identical book + seed + resolver versions reproduce exact colors; changed seed may change only
   genuinely open facts. Anchored revisit/relaunch is identical.
9. Colorblind/grayscale/High Contrast and VoiceOver distinguish Ash/open, explicit Black, saved
   mixtures, selected ink and invalid scope without color alone.
10. Existing pages/worlds migrate colorless without mutation; no fixed-swatch ownership or obsolete
    color-pity state is fabricated.
11. A fresh save has Ash but no mixer; purchasing Isolde's Ink mixing node unlocks it everywhere,
    save/load preserves that access, and an eligible older save is migrated without paying twice.

## Open tuning

- exact subtractive conversion/color space and gamut clamps;
- random scope distributions and coherence strength;
- preset recipes and generated descriptive naming;
- whether later pigment ingredients add meaningful preparation rather than chores;
- gradients/bands and multi-ink source treatment after the single-ink slice.

These do not reopen Ash=nil, subtractive mixing, source-owned ink, full bind-time randomness for open
color, or persistence after resolution.
