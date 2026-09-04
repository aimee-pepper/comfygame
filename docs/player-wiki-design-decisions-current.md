# Design decisions · 4 September 2026

This is the current record of the changes agreed today. **Decided intended behavior** describes the game we are making; it does not mean that behavior is already available on your phone. **First-pass tuning** gives concrete starting numbers that can change through play. **Unsettled proposals** still need design work or a choice.

## 1. Current behavior

The existing campaign, costs, recipes, and character order remain the current-game reference until their replacements are delivered. Today's decisions do not change an installed game by themselves.

| System | Current behavior |
| --- | --- |
| Blacksmith | Halloway's foundation costs 30 Essence, 12 Iron Ore, and 6 Fibre. Pointed Blade uses a suitable point and a different suitable grip, with an Essence price based on quality. The new raw-Iron recipe and tool improvements below are intended replacements. |
| Apothecary | Nessa's foundation costs 85 Essence, 16 Clay, 6 Quartz, and 12 Reagent. Lesser Salve uses a flexible material at 25 or better and 1 Resin. Building teaches the recipe; it does not give a free Salve. |
| Refinement | The complete new refinement journey is not available. This guide does not promise a paid Reforge improvement or a Mote-based Peerless attempt. |
| First Writing | A fresh campaign currently begins with known symbols and starter World Pages. The learn-Illumination-and-Sun opening below is intended behavior. |
| Scent Mask and Seamlight | Both can be prepared. Field Kit use has not yet been verified for the current phone build. Earlier descriptions disagreed about their availability; neither a working field action nor its absence is confirmed here. |
| Recipe tracking and visual changes | Automatic ingredient highlighting, the complete material-colour treatment, and the new world palettes are intended changes; this update is not a claim they are already playable. |

Ordinary consumable and physical-gear crafts now confirm success only after their result is saved. If saving fails, these crafts refuse without spending ingredients or granting the item. This correction has been delivered and checked with focused tests; an interactive crafting playthrough has not yet been completed. This does not mean every economy action or the material overhaul has changed. The Binder and human Gambits/Training presentation update has also been delivered, with clearer rule colours, capitalized labels, and the corrected earned-automation explanation. Existing unlocks, entitlements, Training rules, and Gambit rules are unchanged. Interactive phone navigation and visual acceptance remain pending. The unfinished world-entry artwork is not made current by either delivery.

## 2. Decided intended behavior

### An understandable start

Recipes, upgrade prices, and the order of people and buildings may all change for a more enjoyable, coherent journey. Existing tables are reference values and starting points, not permanent commitments. Physical making should be easy to understand: a blade needs a point, a handle, a binding, and heat. The player should not need to solve a hidden numerical riddle to recognize a usable ingredient.

The opening kit includes a **stone Pick, stone Axe, and stone Scythe**, ready for the first excursion. They occupy the dedicated three-place tool roll, not supply or ordinary item spaces. There is no introductory tool-crafting chore or new durability system.

The basic Blacksmith makes starter gear directly from raw materials and offers the first Pick and Axe improvements with iron working parts. Halloway does the heating and shaping as part of the finished craft: there is no separate Ingot, Haft, or Cord to make first. Upgrading one tool preserves that tool and its place in the roll; the other tools are independent choices.

Basic healing should not require a later mineral upgrade. Quartz leaves the intended Apothecary foundation. Building still teaches Lesser Salve without granting a free dose. Quartz remains useful for later optical and instrument work.

Later specialist recipes can ask for prepared components where those steps earn their place. A newly opened shop must have a useful action. Its first recipe must not depend on an upgrade that itself needs that recipe's output. Earlier raw-material recipes remain available after a shop upgrade.

### Materials worth exploring for

Mined materials and ordinary plant materials are ungraded. The early set is Iron, Coal, Clay, Resin, Softwood Logs, Hardwood Logs, Stem Fibre, and Leaf Fibre. For these starter recipes, **any Log** means Softwood or Hardwood Log; **Plant Fibre** means Stem or Leaf Fibre. Other materials are not silently added because their names sound similar.

Materials may be desirable for stronger statistics, a preferred colour, or both. Colour is a valid reason to go exploring. When source choice changes the result, the preview shows that difference; an operation whose result is identical does not need an extra source picker. Older ambiguous Timber or Fibre remains usable through its supported old uses or exchange, without being guessed into a new subtype.

### Exploration without routine full-map completion

A good expedition can achieve one worthwhile intention, reveal something unexpected, and still leave places to wonder about. Trees, canopy, and branching paths create choices between a detour, gathering, clearing a route, and following another lead. Larger worlds do not automatically receive enough Stability to clear every reachable tile.

Teaching discoveries, written guarantees, and the required route home remain reachable. Once a feature is discovered, its earned minimap record remains. There is no artificial exploration cap, compulsory completion percentage, universal clear-map reward, or padding with empty travel. Small or unusually favourable worlds may still be thoroughly explored.

### Recipe tracking

Pin a known recipe to see relevant sources highlighted **as soon as they become normally visible**, including a newly generated creature. You do not need to inspect, harvest, encounter, or kill it first. The highlight means “this can provide something needed for your recipe.” A creature's random drop is still only possible. Pinning does not reveal a full loot table, hidden rewards, or anything through fog.

**Relevance and tool readiness are separate.** An Iron source can be useful even when your Pick is too weak; selecting it explains the requirement. The highlight uses a thin, softly pulsing outline that preserves the source's colours. A brief sparkle marks collection of a needed material or completion of the gathering goal. Tracking uses its own consistent colour rather than an equipment-quality colour.

### Learning to Write and find people

The intended new campaign begins with no known runes. The introductory world safely provides Illumination and Sun, and missing either does not block a retry. Learned discoveries survive defeat, return, and reopening. At home, the player connects Illumination to Sun and sees the effect of that choice in the world they bind. Unwritten features remain generated. Existing campaigns keep their knowledge and Pages.

That first lesson should make authorship visible. Traveller clues should describe recognizable world facts using vocabulary the player has had a chance to learn. They should not require guessing an invisible threshold. People and later buildings can move earlier so there is time to enjoy their contribution; a complete new order for all twenty-nine people has not been chosen.

### The Binder’s own Gambits

Self-automation remains an earned ability; opening Party does not grant it. Existing unlocked campaigns keep it. The intended owner is the recovered instruction **Let your own rules run**, found in a world and read in the Library. Party uses learned Gambits and never teaches this ability. Reading does not create a rule or change any rule's enabled state.

The first-pass plan makes this later instruction eligible after Binder level 8, eight resolved expeditions, and the three opening Gambit teachings: **Check yourself**, **Leave the fight**, and **Use your skill**. Those timing values remain revisable. The replacement teaching route is not yet verified as delivered; old Workshop wording must not be read as proof that a current route exists. Until the ability is learned, the Binder takes manual turns. The delivered locked message now reads: “Your turns are manual. Following your own Gambits is a learned ability.” This removes the obsolete Workshop direction without promising that the replacement teaching is already available.

### World and equipment colour

Worlds use stable, coordinated palettes, with separate foliage, water, and sky colours. Grass belongs visually to foliage; that does not make every patch harvestable. A specifically assigned shade takes precedence. Returning or reopening keeps the same world colours.

Tint preserves shading and recognizable material cues. Water still reads as water through reflections, shores, and surface patterns; colour alone does not declare danger. Equipment keeps consistent silhouettes and shading, and **every material component region** receives its chosen tint. Quality appears in the item-name highlight and the square thumbnail border, not as a recolouring of the item artwork. Potions and remedies keep their recognizable authored colours.

The Library books Aimee is drawing remain in progress. Sky and cloud homework is optional exploratory artwork; final world-entry layer sizes, placement, and movement are still being worked out. These studies are not finished in-game artwork.

### Reliable progress

Making, upgrading, and returning should preserve the exact materials and items selected. A failed save must not spend ingredients, lose a tool, or report an improvement that cannot be kept. Existing people, buildings, tools, knowledge, and crafted items remain in older saves. The wiki changes to “current behavior” only after the corresponding game change has been delivered and verified.

## 3. First-pass tuning: the first useful crafts

These are the completed starting specifications for the early material path. They are **not current phone recipes**, proven journey costs, or fixed balance commitments. Gathered quantities do not include travel, encounters, or the Essence needed to bind the next world.

| Project | Starting inputs | Result |
| --- | --- | --- |
| Apothecary foundation after Nessa joins | 20 Essence, 4 Clay, 4 Logs | Opens the room and teaches Lesser Salve; no free item |
| Blacksmith foundation after Halloway joins | 20 Essence, 8 Iron, 4 Plant Fibre, 4 Logs | Opens the basic forge, starter blade, and first Pick/Axe improvements |
| Lesser Salve | 1 Resin, 1 Plant Fibre; no Essence | One Salve; base healing 10 with its existing scaling and recognizable appearance |
| Iron Pointed Blade | 4 Iron, 1 Log, 2 Plant Fibre, 1 Coal; no Essence | One Fine, Close Pierce weapon with total Power 2.0; no added Initiative bonus |
| Pick 1 → 2 | Owned Pick plus the blade's raw-material bundle; no Essence | The same Pick improved to level 2 |
| Axe 1 → 2 | Owned Axe plus the blade's raw-material bundle; no Essence | The same Axe improved to level 2 |

Iron is the blade's point, Log its handle, Fibre its binding, and Coal the forge fuel. Handle and binding choices can change colour; they do not add a new statistic to this starter blade. Fuel does not tint equipment. There is no first Scythe improvement specified in this set. Pick 2 opens the first uncommon mineral group, including Quartz; shop level and tool level are separate, so these tool improvements belong at the basic forge.

### Early gathering sources

| Material | Where and how | Starting yield |
| --- | --- | --- |
| Iron | Iron-bearing formations in Granite, Sandstone, or Basalt; Pick 1 | Three hits, 2 Iron each: 6 per node |
| Coal | Fuel-bearing Sandstone formation; Pick 1 | Three hits, 2 Coal each: 6 per node |
| Clay | Explicit loose Clay deposit on passable, unfrozen Clay soil or a compatible muddy margin; gathered by hand | One action, 2 Clay |
| Stem Fibre | Ordinary medium stem-fibre patch; Scythe 1 | One hit, 2 Stem Fibre |
| Leaf Fibre | Ordinary low leaf-fibre rosette; Scythe 1 | One hit, 1 Leaf Fibre |
| Resin | Ordinary low resin-producing shrub; Scythe 1 | One hit, 1 Resin; a direct harvest, not a lucky bonus |
| Softwood Log | Small softwood tree; Axe 1 | One hit, 2 Logs |
| Hardwood Log | Small hardwood tree; Axe 2 | Two hits, 5 Logs on completion |

These starter plants belong to compatible temperate, moist, light-supporting habitats, without intrinsic danger or acid air. A tree has a small cross-shaped crown; its trunk and canopy change together when felled. A successful gathering hit spends one world turn. Cancelling or choosing an unsuitable tool spends none. Partly harvested sources retain their progress and do not regrow in this first set.

Early ingredients must have ordinary gathering routes; they cannot depend exclusively on a lucky merchant offer, recycling, creature loot, or a later resource-Writing symbol. The complete gathering and return journey still needs playtesting.

### Trade and recovery

| Material or item | Sell | Buy, when offered |
| --- | ---: | ---: |
| Iron, Coal, or Resin, per unit | 2 Gold | 4 Gold |
| Clay, either Log, or either Plant Fibre, per unit | 1 Gold | 2 Gold |
| Starter Iron Pointed Blade | 10 Gold | 20 Gold |

Buying the blade's full raw bundle costs 26 Gold. Dismantling that blade returns its recorded 4 Iron, 1 Log, and 2 Plant Fibre; the spent Coal does not return. Those recovered materials sell for 11 Gold. No new tool-dismantling route is added. Buying, making, and selling must not create an ordinary unlimited-profit loop.

## 4. Unsettled proposals

### Blacksmith growth alongside the Village

The recommendation is **T1 raw-material gear → T2 Ingot making → T3 advanced forgework and refinement**. Aimee suggested T2 or T3 for Ingots; the exact placement is not decided. The intention is to introduce exportable prepared metal when specialist shops can use it, while keeping basic recipes simple.

The working conversion is 2 units of the matching solid metal plus 1 Coal for 1 named Ingot, with no Essence cost. The upgrade price and first specialist consumers remain to be settled. Mercury, stone, glass, and creature parts are not smeltable solid metal.

### Earlier practical makers

The proposed opening order is Vance, then Nessa and Halloway, then Bryn, Corrin, and Noll. This is a proposed discovery priority, not six compulsory arrivals in single file. Clues and world availability must support it. It does not silently replace the current character directory's order or complete the later campaign reorder.

### Refining a favourite piece toward Peerless

Aimee likes improving an existing piece instead of making disposable copies. The proposed refinement preserves the item's identity and chosen appearance; a miss never destroys or downgrades it.

| Advantages available, after ordinary recipe or service access | Proposed opportunity |
| --- | --- |
| Any one of a maximum-level shop, its attending matching keeper, or an offered Mote | A disclosed chance at Peerless |
| Any two | A better disclosed chance |
| All three | 100% Peerless, consuming one Mote |

The proposal includes Mote-only and keeper-only attempts; maximum shop level is not secretly required for every attempt. It must also accommodate eligible all-metal-and-wood gear without adding creature-material quality as a fourth guarantee requirement. Peerless remains a finished-equipment quality and an optional ambition, never a requirement for ordinary progression.

**Still unsettled:** partial-setup odds; what happens with none of the three advantages; whether a Mote is spent on a miss and what lasting benefit it buys; refinement prices; what a preview reveals; how cancellation or reopening avoids free rerolls; and how any older bad-luck progress carries over. The former 3%/5% chance and twentieth-copy guarantee are reopened design, not an additional settled rule to apply alongside this proposal. Their replacement is not yet implemented.

Motes also serve other ambitions, including Constellation and keeping worlds. Refinement must be balanced alongside those uses. The one personal choice needed now is in **Aimee Homework**; exact balancing numbers remain design work.

## 5. Where to follow up

Use **Aimee Homework** for choices needing Aimee and **Asset Homework** for optional drawing. The subject guides carry the relevant current/intended summaries. The older overhaul references retain the wider system rules; today's explicit changes take precedence over an older fixed cost, fixed order, or settled Peerless claim.
