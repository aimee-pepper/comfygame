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

Ordinary consumable and physical-gear crafts now confirm success only after their result is saved. If saving fails, these crafts refuse without spending ingredients or granting the item. This correction has been delivered and checked with focused tests; an interactive crafting playthrough has not yet been completed. This does not mean every economy action or the material overhaul has changed. The Binder and human Gambits/Training presentation update has also been delivered, with clearer rule colours, capitalized labels, and the corrected earned-automation explanation. Existing unlocks, entitlements, Training rules, and Gambit rules are unchanged. Interactive phone navigation and visual acceptance remain pending. The Apothecary’s new recipe tiles, recipe details, and preparation presentation are also delivered. Its existing recipes, learned knowledge, and material choices are unchanged; the early recipes below have not arrived with this presentation update. Physical-phone visual acceptance and a campaign playthrough remain pending. The unfinished world-entry artwork is not made current by these deliveries.

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

### Three-quarter world view — decided intended behavior

The world will use a **three-quarter top-down view** over the existing square grid. Ground remains readable from above, while the fronts of trees, rocks, characters, and cliffs make height clearer. This is an accepted direction awaiting an in-game proof and implementation; it is not a newly delivered renderer or finished artwork.

Water belongs to a local bed and surface height. A low river and a pond on raised land can coexist. Shallow water can show its visible bed beneath the water surface, shoreline, and above-water objects; deeper water may hide more of the bed. Water in a lower area does not paint over unrelated higher ground. Its appearance does not change which liquid it is or reveal hidden deposits.

The first version has one supporting ground level at each map position, with optional water above it. Legal steps and slopes connect neighbouring heights. A bare cliff is not a walking route; a larger climb needs a connected route through the land. The initial step or slope adds no movement surcharge beyond the ground’s existing cost. Shallow water remains traversable where a legal shore route reaches it, while deep water and chasms retain their ordinary movement restrictions. Multi-level bridges with walkable space underneath are outside this first version.

A tree’s upper artwork may overlap several squares, but its **trunk base** owns blocking and Axe targeting. With the suitable packed Axe selected at a reachable adjacent position, a small base highlight and **Chop tree** show the valid action. The impact lands at the trunk. Looking at leaves alone does not grant a harvest. Tool requirements, one-turn successful hits, saved partial work, and each tree’s own canopy remain as already decided.

Foreground trees, bushes, and objects partly fade when their artwork covers the character, then return to normal when the character emerges. A faint silhouette and the already-visible blocking base remain understandable. For raised terrain, only the obstructing foreground cliff face fades; the entire plateau does not disappear.

**Fading is a visual aid, not extra sight.** It reveals only the character and surroundings already permitted by the game’s visibility rules. It cannot expose fogged terrain, hidden creatures or resources, or things still concealed by gameplay canopy. The existing canopy rule remains: a second consecutive canopy square conceals what lies beyond; standing beneath canopy gives the local exception around the party. That exception does not erase other sight restrictions. Earned minimap knowledge remains earned. Fading itself spends no turn and changes no collision, target, harvest, or discovery.

Existing saved worlds keep their movement and contents. The initial proof will check a tree to walk behind and chop, a visible shallow-water bed, a raised pond, a legal height connection, and foreground overlap before final artwork is specified. Exact dimensions, composition, opacity, and fade timing remain production work. The active crafting overhaul continues alongside this bounded proof; this view does not introduce new world-writing guarantees, celestial cycles, or a fluid simulation.

### Recipe tracking

Pin a known recipe to see relevant sources highlighted **as soon as they become normally visible**, including a newly generated creature. You do not need to inspect, harvest, encounter, or kill it first. The highlight means “this can provide something needed for your recipe.” A creature's random drop is still only possible. Pinning does not reveal a full loot table, hidden rewards, or anything through fog.

**Relevance and tool readiness are separate.** An Iron source can be useful even when your Pick is too weak; selecting it explains the requirement. The highlight uses a thin, softly pulsing outline that preserves the source's colours. A brief sparkle marks collection of a needed material or completion of the gathering goal. Tracking uses its own consistent colour rather than an equipment-quality colour.

### Learning to Write and find people

The intended new campaign begins with no known runes. The introductory world safely provides Illumination and Sun, and missing either does not block a retry. Learned discoveries survive defeat, return, and reopening. At home, the player connects Illumination to Sun and sees the effect of that choice in the world they bind. Unwritten features remain generated. Existing campaigns keep their knowledge and Pages.

That first lesson should make authorship visible. Traveller clues should describe recognizable world facts using vocabulary the player has had a chance to learn. They should not require guessing an invisible threshold. The first practical makers now have a decided intended discovery priority, shown below. Later people keep their relative order and existing early-access opportunities for this step; a wider campaign redesign remains separate.

### Earlier practical makers — decided intended behavior

The intended priority is **Vance → Nessa and Halloway → Bryn, Corrin, and Noll**. These are opportunities, not six compulsory arrivals in a line. A new world still offers at most one new person, and finding a useful clue can let you reach ahead.

| Person | Intended place to look | Earliest ordinary discovery |
| --- | --- | --- |
| Vance | Broad, open country | From the beginning |
| Nessa | Fresh growing land with daylight, resin-bearing shrubs, and trees | From the beginning |
| Halloway | Exposed Iron that a stone Pick can work | From the beginning |
| Bryn | Close, bending paths with limited approaches | After one person joins |
| Corrin | Damp growing land with fibrous stems and tough leaves | After one person joins |
| Noll | Hard ground with concentrated useful material | After one person joins |

Nessa no longer asks you to seek toxic air and reactive ground before making your first healing supply. Halloway no longer requires an unusually hot world. The old requirement to recruit three people first will not secretly delay the new early makers. These changes are intended; the character directory continues to describe the delivered game until the replacement arrives.

Early location clues give Nessa and Halloway extra attention. The next useful Writing lessons explain water, River, ground, and Iron. Each lesson teaches one thing when read in the Library, without an Essence charge. Finding a clue does not itself teach all the words in it. Learning opportunities come from the world and retain their protection against repeated unlucky misses.

Old diaries and collected Pages remain yours. An older location clue continues to help you find its person, with an updated location hint alongside its original record. Existing people, buildings, tools, knowledge, and unlocked abilities remain. Already-created worlds keep their original contents.

### Ordinary gathering — decided intended behavior

The early materials have ordinary sources as well as deliberate Writing routes. Iron needs an Iron-bearing formation; Coal needs a compatible seam. Clay comes from a genuine Clay placement. Resin, Logs, and Plant Fibre come from plants suited to the land, light, water, and temperature. A stone-coloured tile does not automatically contain Iron, and green ground is not automatically harvestable.

Suitable worlds set aside some source opportunities for the early crafts. They do not put the whole starter catalogue into every world. Cold, submerged, corrosive, or otherwise unsuitable ground can support different things. Sunlight by itself does not guarantee a forest or a safe journey. Your pinned recipe can help you notice relevant sources when you can normally see them.

**First-pass source tuning:** where the necessary hosts exist, reserve one ordinary Iron node, one Coal node, and two Clay gathers. Suitable growing land starts with two Stem Fibre patches, one Leaf Fibre plant, one Resin shrub, and two small Softwoods. More plants and nodes depend on the world’s size, growth, and eligible sources. Hardwood can appear before you have the Axe needed to harvest it. Written guarantees count toward these source budgets; they are not duplicate bonus caches.

The intended first healing trip needs six harvest actions before travel and encounters. Building the forge and improving the Pick needs thirteen harvest actions across enough source-bearing worlds. Those are ingredient calculations, **not measured trip lengths**. The complete route still needs testing for travel, survival, returning safely, and enough Essence left to bind another world. A useful expedition should not require clearing its whole map.

### T2 smelting and useful specialist crafts — decided intended behavior

**Iron Ingot making opens at Blacksmith T2.** Upgrade the working forge with raw materials you can already gather. Its earlier raw-material recipes remain available. The first Ingots have two useful destinations: a better Scythe and a reinforced cloth garment at Corrin’s Tannery.

The Tannery also has a useful first garment made entirely from plant materials. You do not need to upgrade the forge, find Salt, or hunt an animal just to use your new cloth-making room. Leather becomes a separate optional path.

**First-pass recipes and costs — not current phone recipes:**

| Project or craft | Inputs | Result |
| --- | --- | --- |
| Blacksmith T2 | 20 Essence, 8 Iron, 4 Clay, 4 Logs | Learn Iron smelting and the Scythe improvement |
| Tannery foundation after Corrin joins | 20 Essence, 6 Logs, 4 Clay, 4 Plant Fibre | Learn Cord, Cloth, and the woven garments; no free stock |
| Iron smelting | 2 Iron, 1 Coal | 1 Iron Ingot |
| Plant Cord | 2 Stem or Leaf Fibre | 1 Plant Cord |
| Plant Cloth | 4 Stem or Leaf Fibre | 1 Plant Cloth |
| Woven Guard | 1 Plant Cloth, 1 Plant Cord | Fine Body equipment with total Protection 1.5 |
| Buckled Woven Guard | 2 Plant Cloth, 1 Plant Cord, 1 Iron Ingot | Fine Body equipment with total Protection 2.0 |
| Scythe 1 → 2 at Blacksmith T2 | Owned Scythe 1, 2 Iron Ingots, 1 Log, 2 Plant Fibre | Improve the same tool with an iron edge |

The listed processing and item recipes cost no Essence. These garments add no Initiative or heat protection. Ingots, Cord, and Cloth are ungraded materials. Cloth and ties retain the chosen plant colours, while buckles use the selected Iron. Matching ingredients can come from several plants; ingredients with different visible results require a deliberate choice rather than silently blending colours.

Scythe 2 can cut tall fibrous stalks on suitable thriving land for 3 Stem Fibre in one harvest action. The ordinary smaller fibre plants remain available with Scythe 1. A tall patch can appear before you have the better tool, and selecting it explains what is needed.

From an existing basic forge, opening the Tannery and making a Woven Guard needs **20 Essence, 6 Logs, 4 Clay, and 10 Plant Fibre** in total. Adding T2 and making the Buckled version instead needs **40 Essence, 10 Logs, 8 Clay, 14 Plant Fibre, 10 Iron, and 1 Coal**. These combined costs are starting balance proposals, not measured affordability. You choose which improvement to pursue; the game does not require buying them all together.

### Carrying and ordinary woven equipment — decided intended behavior

The opening Storehouse handles the first two pack projects; **Corrin’s Tannery handles the larger expansion**. Sela’s existing **+2** remains a separate benefit of her built Wayfarer’s Table. Pack spaces are for the existing Items, Pages and prepared supply families. Materials remain slot-free, and gathering tools keep their own roll.

| Project | Where and when | First-pass cost | Pack spaces before Sela |
| --- | --- | --- | ---: |
| Opening pack | Already owned | Free | 8 |
| Reinforced Stitching | Opening Storehouse | 5 Essence, 4 Plant Fibre | 11 |
| Balanced Straps | Storehouse, after Stitching | 10 Essence, 6 Plant Fibre, 1 Resin | 14 |
| Deepened Satchel | Built Tannery, after both Storehouse projects | 20 Essence, 2 Plant Cloth, 2 Plant Cord, 1 Resin | 23 |

**Carry opens with the Tannery, without another paid lesson.** You do not need Leather, Ingots or an attending keeper to expand this pack. Sela’s Table can add its 2 spaces at any stage: 10, 13, 16 or **25** in total. Its intended foundation costs **30 Essence, 6 Logs and 4 Plant Fibre**, after she joins; other fieldcraft benefits keep their existing rules.

The three later pack increments become one worthwhile project while preserving their full combined benefit. The earlier proposed 20-space ceiling, or 22 with Sela, is replaced by **23 and 25**. Older purchases retain at least their existing capacity and cannot pay out twice. Your current expedition and packing choices remain intact. Storehouse shelving is a separate progression and keeps all nine existing improvements.

The first project leaves 35 of the opening 40 Essence before other spending; both early projects leave 25. From an opening campaign without the Tannery, all three pack projects and its foundation together need **55 Essence, 26 Plant Fibre, 2 Resin, 6 Logs and 4 Clay**. These are optional stages across trips, not an opening shopping list. Journey testing must still check the actual cost of the next Bind.

The built Tannery also teaches **Woven Gloves** and **Woven Boots**, with no extra lesson cost or free stock. Gloves use **1 Plant Cloth and 1 Plant Cord**. Boots use the same plus **1 Resin**. Each costs no Essence and gives **Fine equipment with total Protection 1.0** in its own slot, with no Initiative, heat protection or harvesting bonus. Either needs 6 raw Plant Fibre after processing; Boots also need the Resin. Cloth and Cord keep the chosen colours. Neither recipe requires animal materials, smelting, or the pack projects. Existing equipment and patterns remain available while the update is being made.

### Optional Hide-to-Leather path — decided intended behavior

Some generated animals can provide **Smooth Skin, Supple Hide, or Tough Hide**, according to their actual covering. A feathered, scaled, shelled, or furry animal does not silently become a Hide source. Relevant creatures can be highlighted for a known recipe as soon as normally visible, but a possible drop is not a promise. Their appearance and species remain generated.

**First-pass reward tuning:** a qualifying creature has a 70% chance to provide its covering after defeat, yielding 1–4 parts according to body size. The part’s actual source determines its Poor, Common, Rare, or Exceptional quality and its colour. Better quality improves its contribution to an eligible craft; it does not make the animal drop more pieces. No tool is required to collect that defeat reward.

Salt comes from real dry Salt crust around a suitable saline margin or deposit. It is gathered by hand: 2 Salt in one action, then that placement is depleted. Fresh growing country does not automatically supply Salt. This separate gathering trip is one reason Leather is optional rather than a prerequisite for the first Tannery crafts.

| Optional Tannery recipe | Inputs | Result |
| --- | --- | --- |
| Leather | 2 matching Smooth Skin, Supple Hide, or Tough Hide, plus 1 Salt | 1 Leather retaining the parts’ quality and colour |
| Leather Guard | 2 matching Leather plus 1 Plant Cord | Body equipment with Protection calculated from that Leather; the preview shows the exact result |

Both recipes cost no Essence. Matching parts can come from several animals when their type, quality, colour, and relevant properties are the same. Different qualities or colours are not silently averaged together. A complete Leather Guard uses **4 matching raw parts, 2 Salt, and 2 Plant Fibre**, including its processing steps.

Leather determines the garment’s finished quality: Poor parts make Rough work, Common makes Fine, Rare makes Superior, and Exceptional makes Exceptional. It adds no hidden Initiative, heat protection, or durability. Dismantling returns the recorded prepared Leather and Cord; it does not also refund the raw parts or spent Salt. Existing equipment and older materials remain available through their supported uses.

Animal frequency, source matching, combat, and the complete gathering journey still need playtesting. This closes a small useful Leather path; the wider creature catalogue and later material families remain separate work.

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

Iron is the blade's point, Log its handle, Fibre its binding, and Coal the forge fuel. Handle and binding choices can change colour; they do not add a new statistic to this starter blade. Fuel does not tint equipment. The first Scythe improvement belongs to Blacksmith T2, as described above. Pick 2 opens harder deposits; shop level and tool level are separate, so these tool improvements belong at the basic forge. A mineral’s occurrence group is separate from its gathering requirement.

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

These starter plants belong to compatible cool, temperate, or warm habitats with fresh damp or moist roots and sufficient daylight, without intrinsic danger, frozen or submerged roots, acid precipitation, or corrosive air. A tree has a small cross-shaped crown; its trunk and canopy change together when felled. A successful gathering hit spends one world turn. Cancelling or choosing an unsuitable tool spends none. Partly harvested sources retain their progress and do not regrow in this first set.


Ordinary background moisture counts as water even when the written conditions only reduce its amount. Sea, Tide and Brine still carry their actual saltiness. A Mercury seam is local: it does not turn every river or plant root in the world into Mercury. Mercury itself supplies no ordinary watering, and roots actually touching Mercury, another non-water liquid, or an unidentified liquid are unsuitable for these starter plants. Nearby ordinary water keeps its own identity.

Early ingredients must have ordinary gathering routes; they cannot depend exclusively on a lucky merchant offer, recycling, creature loot, or a later resource-Writing symbol. The complete gathering and return journey still needs playtesting.

### First world-generation test — a problem still to fix

An initial test of **1,000 completely unwritten worlds** found suitable Iron ground in 98.2%, Coal ground in 90.5%, but suitable fresh growing land in only **3.6%**. Growing land missed the first review target of 25%. This is a real problem for the intended early gathering route; those numbers are not promised final encounter rates.

The test checked suitable land, not completed gathering trips or the player’s ability to afford another Bind. A follow-up check of the soil conditions passed in 5.3% of completely unwritten cases, or 17.1% with a moderate Sun written. Those follow-up figures do not include the map, suitable soil area or placed gathering sources, so they are not successful-journey rates. The seven world-generation failures also occur under the older generator and are being investigated separately.

**Decided calculation correction, checked in development:** a small amount of Ice must not erase the ordinary unfrozen water already available to plant roots. The correction keeps that background water represented and then applies actual freezing conditions. Its six direct checks pass, but it is not yet delivered to your phone. The follow-up soil-condition results improve to 6.7% for unwritten worlds and 20.3% with a moderate Sun, before map placement. The gathering shortage remains open.

**Drainage will not solve the main shortage:** even a generous estimate for well-drained Loam brings unwritten soil conditions to less than 10%, before checking actual soil and gathering places. Drainage has not been adopted as the availability fix. Writing a fainter Sun also did not improve these results.

**Decided intended tuning for new early worlds:** make extreme conditions less common when the world chooses something you left unwritten. Faint / Moderate / Great / Overwhelming will have weights of **70% / 25% / 4% / 1%**. Every source type and all four intensities remain possible. Your own written choices and already-created worlds stay unchanged. The current game still uses its existing rules until this update is delivered.

The comparison kept the chosen sources fixed and changed only their unwritten intensity. Suitable soil conditions rose from **6.7% to 30.6%** for completely unwritten inputs, and from **20.3% to 41.7%** with a moderate Sun. These results support the new starting weights, but do not prove that enough suitable terrain or reachable gathering sources actually appear. A smaller actual-world check comes next, before repeating the large test and checking complete journeys. Drainage is not part of this revision.

### Mineral occurrence — decided intended behavior

After written sources and suitable early Iron and Coal opportunities, other mineral finds share the remaining space. Their first-pass occurrence groups are:

| Occurrence group | Materials |
| --- | --- |
| Common | Iron, Coal, Quartz |
| Uncommon | Copper, Silver, Obsidian, Sulfur |
| Rare | Gold, Mercury, Adamant, Rift-glass |

Each still needs compatible geology. These groups describe how often a suitable find is selected, not material quality, sale price or the tool needed to gather it. The starting group weights are 70 / 25 / 5; groups with no suitable material are skipped. This does not promise that every world contains each group.

Clay and Salt use their separate hand-gathered deposits. Rubble is held out of this new early mineral selection until its gathering and processing route is ready; existing worlds and owned stock are preserved. These rules are intended tuning, with actual world-generation and journey testing still pending.

### Trade and recovery

| Material or item | Sell | Buy, when offered |
| --- | ---: | ---: |
| Iron, Coal, or Resin, per unit | 2 Gold | 4 Gold |
| Clay, either Log, or either Plant Fibre, per unit | 1 Gold | 2 Gold |
| Starter Iron Pointed Blade | 10 Gold | 20 Gold |

**Additional intended trade tuning:**

| Prepared material or item | Sell | Buy, when offered |
| --- | ---: | ---: |
| Iron Ingot | 4 Gold | 8 Gold |
| Plant Cord | 1 Gold | 2 Gold |
| Plant Cloth | 2 Gold | 4 Gold |
| Woven Guard or Woven Gloves | 5 Gold | 10 Gold |
| Woven Boots | 7 Gold | 14 Gold |
| Buckled Woven Guard | 12 Gold | 24 Gold |
| Salt | 1 Gold | 2 Gold |
| Smooth Skin: Poor / Common / Rare / Exceptional | 2 / 2 / 3 / 3 Gold | 4 / 4 / 6 / 6 Gold |
| Supple or Tough Hide: Poor / Common / Rare / Exceptional | 2 / 3 / 4 / 5 Gold | 4 / 6 / 8 / 10 Gold |
| Leather: Poor / Common / Rare / Exceptional | 3 / 4 / 5 / 6 Gold | 6 / 8 / 10 / 12 Gold |
| Leather Guard: Rough / Fine / Superior / Exceptional | 8 / 10 / 13 / 15 Gold | 16 / 20 / 26 / 30 Gold |

Dismantling a Woven Guard or Woven Gloves returns its Cloth and Cord. Woven Boots also return their recorded Resin. The Buckled version also returns its recorded Ingot. Prepared materials do not also refund their raw inputs, and spent fuel or Salt never returns. These are starting prices, not a promise that every merchant stocks every item.

Buying the blade's full raw bundle costs 26 Gold. Dismantling that blade returns its recorded 4 Iron, 1 Log, and 2 Plant Fibre; the spent Coal does not return. Those recovered materials sell for 11 Gold. No new tool-dismantling route is added. Buying, making, and selling must not create an ordinary unlimited-profit loop.

## 4. Unsettled proposals

### Blacksmith growth alongside the Village

Blacksmith T2 is now decided for Iron Ingots, with its first useful consumers specified above. T3, other metal Ingots, and the wider later-facility progression still need design work. A new process will arrive with something useful to make from it.

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
