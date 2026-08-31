# Player Wiki crafting systems — implemented source copy V1

**Publication status:** player-facing source copy for mechanics currently implemented at
`a93077f1a13871809d61baf5d6510436e8ad449a`. This packet deliberately excludes every proposed cost,
resource use, purchase contract and progression gate in the resource progression design packets.

Publish a section only when its station/action is legitimately visible to that player. Links name intended
Player Wiki subjects; the publication manifest owns their runtime routes.

## How making works

Bookbinder uses four kinds of cost. A recipe tells you which one it needs:

- **Stored resources** are counted supplies returned from worlds, such as Iron Ore, Timber and Resin.
- **Exact materials** are individual recovered pieces. Their family, properties and origin can determine
  whether they fit a component.
- **Essence Crystals** pay for Binding, construction, research and magical or permanent work.
- **Motes** belong to Reality and appear only in specific permanent or extraordinary costs.

A counted stockpile is not interchangeable with an exact material. Selecting an exact piece reserves that
piece's real identity and properties for the previewed output.

All making happens at Home. A station must be available, its recipe or schematic must be known, every
ingredient must still be present, and the finished object must have a legal Storehouse or Waiting
destination. A changed ingredient, recipe, station or storage destination requires a fresh preview.

**See also:** [Resources], [Exact Materials], [Essence Spring], [Motes], [Storehouse and Waiting].

## Station access

The Essence Spring, Storehouse and Writing Desk are opening Home destinations. Specialist stations become
available only after meeting their keeper and paying the exact current foundation cost:

| Station | Keeper | Current foundation |
|---|---|---|
| Recycler | Noll | 15 Essence Crystals |
| Blacksmith | Halloway | 30 Essence, Iron Ore 12, Fibre 6 |
| Survey Post | Mara | 50 Essence, Timber 10, Iron Ore 8, Quartz 2 |
| Scriptorium | Isolde | 60 Essence, Timber 14, Clay 10 |
| Tannery | Corrin | 80 Essence, Timber 12, Fibre 20, Salt 8 |
| Apothecary | Nessa | 85 Essence, Clay 16, Quartz 6, Reagent 12 |
| Bowyer | Fen | 110 Essence, Timber 24, Fibre 18, Resin 8 |
| Armoury | Bracken | 120 Essence, Iron Ore 28, Clay 12, Copper 8 |
| Weaponsmith | Maud | 150 Essence, Iron Ore 32, Copper 12, Gold 4 |
| Distillery | Auber | 200 Essence, Quartz 30, Silver 20, Clay 30 |
| Channelworks | Oda | 200 Essence, Iron Ore 50, Quartz 20, Silver 20 |
| Anchorage | Tovin | 200 Essence, Iron Ore 40, Quartz 20, Pulp 18 |

Finding a keeper does not spend the foundation automatically. Construction happens at Home and is
unavailable during an active expedition. Later recipe and research gates remain separate from whether the
room itself has been built.

**See also:** [Home], [Village Buildings], [Traveller Meetings], [Construction Costs].

## Essence Spring — refining Raw Essence

The Essence Spring converts returned Raw Essence into spendable Essence Crystals. Each Raw Essence
normally becomes 2 Essence Crystals. After Second Pass is learned, each becomes 3. Continuous Settling can
refine only the Raw Essence returned by its exact completed expedition when its current setting and
research allow it.

Refining never creates a material sample or a Distillery Core. It spends counted Raw Essence and adds the
matching amount to the existing Essence Crystal wallet.

**Ready when:** Raw Essence is stored at Home. Second Pass and Continuous Settling use their existing
research, practice and station requirements.

**See also:** [Raw Essence], [Essence Crystals], [Expedition Return], [Research].

## Apothecary — preparations

The Apothecary prepares consumable remedies, coatings and field tools. An ordinary recipe needs the
Apothecary, knowledge of that recipe, every counted ingredient, one exact material meeting the shown
property where required, and room for the result. The least potent valid exact material is offered first;
the chosen piece remains visible before preparation.

Scent Mask uses a separate exact creature-material recipe. It accepts one Hide, Pelt, Down or Oil unit and
one Reagent. It does not silently substitute a counted resource or another creature part.

### Remedies

| Preparation | Implemented inputs | Current output role |
|---|---|---|
| Lesser Salve | one flexible exact material at 25 or better; Resin 1 | restores health |
| Salve | one insulating exact material at 40 or better; Pulp 2, Spore 1, Resin 1 | restores more health |
| Greater Salve | one reactive exact material at 60 or better; Ichor 1, Spore 2, Resin 2 | strongest current Salve |
| Draught of Clearing | one reactive exact material at 35 or better; Pulp 1, Salt 1 | clears poison or bleeding |
| Quenching Draught | one insulating exact material at 45 or better; Reagent 1, Resin 1 | clears burning or dazzle |
| Broad Antidote | one reactive exact material at 65 or better; Ichor 1, Reagent 1, Spore 1 | clears one eligible affliction |
| Stonebark Tonic | one hard exact material at 45 or better; Timber 1, Resin 1 | protects against the next affliction |

### Prepared weapon coatings

| Coating | Implemented inputs | Effect on the next eligible successful weapon hit |
|---|---|---|
| Venom | one reactive exact material at 55 or better; Toxin 1, Fibre 1 | poison |
| Firebrand | one reactive exact material at 60 or better; Reagent 1, Sulfur 1 | burning |
| Briar Oil | one flexible exact material at 50 or better; Fibre 1, Resin 1 | bleeding |
| Flashsalt | one lustrous exact material at 55 or better; Reagent 1, Mercury 1 | dazzle |

The coating is a prepared combat supply, not a permanent weapon property. Its current replacement rules
must be shown by the combat action that applies it; this page does not promise an unimplemented choice.

### Field preparations

| Preparation | Implemented inputs | Current output role |
|---|---|---|
| Seamlight | Quartz 1, Resin 1, Fibre 1 | temporary portal guidance; no illumination |
| Scent Mask | one exact Hide, Pelt, Down or Oil; Reagent 1 | temporary protection from scent-only detection |
| Solvent | one reactive exact material at 40 or better; Reagent 1, Salt 1 | identifies one carried unidentified Curio |
| Lure | one reactive exact material at 50 or better; Toxin 1, Pulp 1 | draws the nearest eligible visible roaming creature |
| Stillwater | one lustrous exact material at 60 or better; Rift-glass 1, Mercury 1, Essence Crystals 6 | restores world Stability |
| Waystone | one hard exact material at 70 or better; Rift-glass 1, Mote 1, Essence Crystals 12 | returns with the full eligible haul |
| Torch | one reactive exact material at 30 or better; Resin 1, Timber 2 | raises current expedition vision to Torch level |
| Farsight Draught | one lustrous exact material at 50 or better; Quartz 1, Ichor 1 | reveals the nearest eligible unrevealed site |

Preparing an item does not apply it or spend a world turn. Field/combat use owns the target, action cost and
effect.

**See also:** [Apothecary], [Remedies], [Afflictions], [Prepared Coatings], [Field Kit], [Curios],
[Stability], [Portals], [Sites].

## Blacksmith — pointed blades

The current reachable Blacksmith recipe is the Pointed Blade. It uses one exact point material and one
exact grip material, both accepted by the displayed component rules, plus the Essence cost of the output
quality. The stable schematic and station requirements must be met.

The finished weapon is a close-reaching pierce weapon. Its construction record preserves the chosen
materials and quality. Definitions that do not appear in the live Blacksmith recipe list are not Player
Wiki recipes.

**Ready when:** the Blacksmith is built, the Pointed Blade schematic is known, both exact components remain
available, the quality can be paid, and the output can be stored.

**See also:** [Blacksmith], [Pointed Blade], [Weapon Reach], [Pierce Damage], [Exact Materials], [Schematics].

## Tannery — flexible protective gear

The Tannery currently makes three protective families:

- **Supple Coat:** body protection assembled from suitable facing, lining and binding materials.
- **Working Gloves:** hand protection assembled from suitable palm, facing and binding materials.
- **Working Boots:** foot protection assembled from suitable upper, sole and binding materials.

Each component has its own allowed material families and property requirements. Quality and Essence follow
the current physical-making rules; a high property number does not let an unsuitable family fill every
component.

**Ready when:** Corrin has enabled and the player has built the Tannery; the relevant wear research/tier and
schematic are available; every exact component and the Essence cost remain payable; output storage exists.

**See also:** [Tannery], [Protective Gear], [Equipment Slots], [Exact Materials], [Schematics].

## Bowyer — far-reaching weapons

The Bowyer currently makes:

- **Longbow:** far-reaching pierce weapon built from suitable limbs, string and grip.
- **Sling:** far-reaching crush weapon built from suitable pouch, cords and projectiles.
- **Throwing Set:** far-reaching rend weapon built from suitable projectiles, edges and grip materials.

The chosen components freeze into the physical weapon's construction record. Broader and masterwork
recipes follow the current Bowyer research and station tier rather than appearing merely because the
materials are owned.

**Ready when:** Fen has enabled and the player has built the Bowyer; the recipe/schematic and effective
station tier permit the family; exact components, Essence and storage are available.

**See also:** [Bowyer], [Longbow], [Sling], [Throwing Set], [Weapon Reach], [Damage Kinds], [Schematics].

## Weaponsmith — fitted close weapons

The Weaponsmith currently makes a Fitted Point, Fitted Edge and Fitted Maul. They serve close-range pierce,
rend and crush specialists. Each family uses its own valid exact metal/creature components and the current
physical construction cost; selected materials remain part of the completed object's history.

**Ready when:** Maud has enabled and the player has built the Weaponsmith; the specific fitted recipe,
station tier and schematic are available; exact components, Essence and storage remain valid.

**See also:** [Weaponsmith], [Fitted Weapons], [Pierce Damage], [Rend Damage], [Crush Damage], [Schematics].

## Armoury — rebuilding protective gear

The Armoury does not create an unrelated replacement from nothing. It rebuilds one exact eligible
protective item through one of the currently available profiles:

- **Rigid:** emphasizes a hard shell.
- **Insulated:** emphasizes protective insulation.
- **Balanced:** combines the two approaches.

The preview identifies the original piece, chosen exact materials, resulting profile and Essence cost.
Commit preserves the item's stable physical history and adds the new construction facts.

**Ready when:** Bracken has enabled and the player has built the Armoury; the selected item is eligible and
still in the quoted custody; the profile/tier is available; materials, Essence and output custody remain
valid.

**See also:** [Armoury], [Protective Gear], [Rebuilding], [Exact Materials], [Recycler].

## Reforging — improving an existing physical item

Reforging improves one eligible physical item's current stats within its construction tier. The selected
exact material must satisfy the property requirement shown for that item and the Essence cost must remain
available. Reforging preserves the item's identity and original construction receipt; it does not replace
the object with a generic catalogue copy.

**Ready when:** the item is eligible, the required station/capability is available, the exact item and
material still match the preview, and the payment can be committed.

**See also:** [Reforging], [Physical Equipment], [Construction History], [Recycler].

## Survey Post — improving field instruments

The Survey Post supports eight instruments: Sunglass, Level, Thermoscope, Hygrometer, Loupe, Vivometer,
Barometer and Chronometer. Each measures one world subject.

- **Crude to Good:** two exact materials at the instrument's linked property 35 or better, plus 20 Essence
  Crystals.
- **Good to Fine:** three exact materials at the linked property 65 or better, plus 50 Essence Crystals.

Improvement is permanent. Good instruments narrow a reading; Fine instruments can report the exact value.
The selected materials and current instrument grade must still match the preview.

**Ready when:** Mara has enabled and the player has built the Survey Post; the exact instrument is owned;
the next grade is legal; all selected materials and Essence remain available.

**See also:** [Survey Post], [Field Instruments], [Survey], [World Pressures], [Writing Desk Analysis].

## Scriptorium and Writing Desk — prepared ink

Ink preparation has two steps:

1. Convert one counted pigment resource into 4 measures: Copper makes Cyan, Ichor makes Magenta, Sulfur
   makes Yellow and Obsidian makes Depth.
2. Bind prepared measures with 1 Resin into a vial holding 12 applications.

Measures remain available between preparations. The vial records its exact colour and remaining
applications; filling it does not apply ink to a Page. The Writing Desk owns the later exact mark use.

**Ready when:** the required Scriptorium/Ink Mixing capability is available, pigment stock and Resin are
present, and the prepared vial has a legal destination.

**See also:** [Scriptorium], [Writing Desk], [Prepared Ink], [Page Marks], [Copper], [Ichor], [Sulfur],
[Obsidian], [Resin].

## Scriptorium Runebook — personal Compounds

Compound Assembly can formalize a complete statement the player has already bound successfully. The
chosen receipt must still be present, use known Sigils, describe one eligible self-contained statement and
not already have a personal Compound. Formalizing costs 20 Essence Crystals and 4 Pulp.

The result keeps its Subject, exact Sigil expansion, proven meaning and player-chosen name. It compresses
notation; it does not change the world's pressures or grant an unknown Sigil. Renaming and deleting a
Runebook entry are free. Deletion removes it from future placement but does not rewrite Pages or worlds
that already used it.

**Ready when:** Isolde has enabled and the player has built the Scriptorium; Brush, Scriptorium tier 1 and
Compound Assembly are known; no expedition is active; an eligible proven statement and the exact payment
remain available.

**See also:** [Scriptorium], [Runebook], [Compounds], [Sigils], [Writing Desk].

## Scriptorium — Seamward inscription

Seamward can be written onto one exact Body or Keepsake item that does not already carry an inscription.
Installing it consumes one identified Seamlight, 10 Essence and one ink application. Ash is permitted
without a prepared vial; choosing prepared ink consumes one exact matching application.

The same gear item remains in its stored or worn location with a permanent inscription receipt. Seamward
stays dormant during ordinary exploration. During collapse it wakes automatically without consuming a
turn or another item and guides toward the nearest currently reachable portal. Multiple active Seamwards
do not stack. Erasing the exact current Seamward is free and returns no ingredients.

**Ready when:** the Scriptorium, Brush and Ink Mixing are available; the exact Body/Keepsake item,
Seamlight, chosen ink and Essence still match the preview.

**See also:** [Scriptorium], [Seamward], [Seamlight], [Prepared Ink], [Body Gear], [Keepsakes], [Collapse],
[Portals].

## Distillery — attuned Cores

The Distillery spends 16 Essence Crystals, one exact qualifying material and one named catalyst:

| Core | Exact material | Catalyst | Current result |
|---|---|---|---|
| Heat Core | reactivity 60 or better and insulation 25 or better | Sulfur 2 | a provenance-bearing Heat Core |
| Caustic Core | Reagent, Toxin or Ichor family at reactivity 60 or better | Toxin 2 or Ichor 1 | a provenance-bearing Caustic Core |
| Light Core | lustre 60 or better and hardness 30 or better | Silver 2 | a provenance-bearing Light Core |

The least potent valid material is offered first. The completed Core records attunement, potency, source,
catalyst and Distillery recipe version. Distilling is not Raw Essence refinement.

**Current downstream truth:** the Channelworks can convert one valid Heat Core into one Heat Conduit
Fixture. Caustic and Light Cores can currently be stored and recovered by their existing custody paths but
have no further playable housing/effect. Do not describe proposed Conduit weapons as implemented.

**Ready when:** Auber has enabled and the player has built the Distillery; the exact attunement recipe is
reachable; Essence, catalyst, exact material and output storage remain valid.

**See also:** [Distillery], [Heat Core], [Caustic Core], [Light Core], [Essence Crystals], [Exact Materials].

## Channelworks — Heat Conduit Fixture

The current repeatable Channelworks process consumes one exact valid player-made Heat Core and stores one
Heat Conduit Fixture. Oda's authored restoration can produce its own fixture through its separate story
route. The fixture retains the relevant construction provenance and can be recognized by the Recycler.

The current loop ends with the stored Fixture. A playable Heat weapon, Caustic housing, Light housing and
retuning system are not implemented Player Wiki truth.

**Ready when:** Oda has enabled and the player has built the Channelworks; one valid Heat Core remains in
the exact quoted custody and the Fixture has room.

**See also:** [Channelworks], [Heat Core], [Heat Conduit Fixture], [Recycler].

## Anchorage — Anchor Frames

The Anchorage makes one Anchor Frame from six different exact materials and 60 Essence Crystals:

- two materials with hardness 65 or better;
- two materials with density 65 or better;
- one material with flexibility 55 or better;
- one material with reactivity 65 or better.

No exact material may fill two positions. The completed Frame keeps the selected material history. It can
be packed and carried to a valid natural anchoring point, where the anchoring action consumes it.

**Ready when:** Tovin has enabled and the player has built the Anchorage; all six distinct selections,
Essence and output custody still match the preview.

**See also:** [Anchorage], [Anchor Frame], [Anchoring a World], [Exact Materials], [Field Kit].

## Recycler — recovering materials

The Recycler accepts one eligible exact physical item at Home. A player-made item with a valid construction
or rebuild receipt returns the exact recoverable materials recorded by that receipt. Eligible authored
found gear follows its fixed legacy recovery profile instead. Protected, unique, apex and unsupported
objects are not treated as ordinary salvage.

Recovery goes to the current material/resource reserves under their real domains. It does not turn every
object into generic Iron, invent provenance, or make the Recycler a scalar-to-sample converter.

**Ready when:** Noll has enabled and the Recycler is built; the exact item remains eligible and in custody;
the complete recovery preview and destination capacity remain valid.

**See also:** [Recycler], [Construction History], [Exact Materials], [Storehouse and Waiting].

## Storehouse and Waiting — output custody

Crafted ordinary items are placed in the Storehouse when a compatible stack exists or capacity is
available. Otherwise the current crafting transaction may place the exact result in Waiting when that
route permits it. Waiting is already banked custody, not a failed expedition haul.

An output preview must identify the real destination and whether it merges with an existing stack or
creates a new one. If that destination changes before commit, review the preparation again.

**See also:** [Storehouse], [Waiting], [Item Stacks], [Field Kit].

## Publication exclusions

The following are not implemented crafting truth and must not enter pages derived from this packet:

- a Rubble foundation use;
- discovered-resource Trading contracts;
- a physical Field Pick as the canonical extraction unlock;
- changed late station signature costs;
- revised Briar Oil, Flashsalt, Lure, Draught, Seamlight or Farsight ingredients/forms;
- scalar-to-exact material conversion;
- playable Heat/Caustic/Light Conduit weapons or automatic Lantern behavior;
- any new Infuse action;
- dormant Blacksmith definitions presented as reachable recipes.
