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

### Solid deposits and step-to-mine — decided intended behavior

**Substantial solid deposits and boulders block their physical base.** In the first overhaul, Iron and Coal deposits each block one square. Small loose stones, herbs, Salt crust, Clay and low gathering patches remain walkable. Their existing gathering or pickup actions remain; a decorative rock does not automatically become a new source of loot.

With the required **packed Pick selected**, deliberately step toward an adjacent harvestable deposit to mine from where you are standing. You do not stand on the deposit to use Interact. Each successful hit takes **one world turn**, gives the source’s normal yield and leaves you beside it. Iron and Coal still take three hits and give two units per hit. The final hit clears the deposit’s base; your **next step** enters the cleared square at its ordinary movement cost.

A missing, wrong or insufficient tool spends no mining turn and takes no material. Cancelled, stale or failed-save attempts also grant no mining result or progress. Existing encounters and pending interactions keep their priority. Mining success and the opened space must be saved together.

**Automatic routes never mine.** They go around blocking deposits or stop. Reaching nearby ground does not begin mining, spend harvesting turns or switch tools. Small gathering patches remain walkable; already-loose pickups retain their usual pickup behavior. Existing worlds keep their saved behavior while this new rule awaits delivery.

Blocking sources may create detours and opened shortcuts while preserving essential return, starter-resource and tool-acquisition routes. Each required deposit has a reachable adjacent working position. There is no requirement for an Iron Pick to reach the only starter Iron source. Deliberately fully tool-gated optional areas are later work. Clearing a deposit does not remove nearby tree canopy or alter the underlying height rules.

### Three-quarter world view — decided intended behavior

The world will use a **three-quarter top-down view** over the existing square grid. Ground remains readable from above, while the fronts of trees, rocks, characters, and cliffs make height clearer. This is an accepted direction awaiting an in-game proof and implementation; it is not a newly delivered renderer or finished artwork.

Water belongs to a local bed and surface height. A low river and a pond on raised land can coexist. Shallow water can show its visible bed beneath the water surface, shoreline, and above-water objects; deeper water may hide more of the bed. Water in a lower area does not paint over unrelated higher ground. Its appearance does not change which liquid it is or reveal hidden deposits.

The first version has one supporting ground level at each map position, with optional water above it. Legal steps and slopes connect neighbouring heights. A bare cliff is not a walking route; a larger climb needs a connected route through the land. The initial step or slope adds no movement surcharge beyond the ground’s existing cost. Shallow water remains traversable where a legal shore route reaches it, while deep water and chasms retain their ordinary movement restrictions. Multi-level bridges with walkable space underneath are outside this first version.

A tree’s upper artwork may overlap several squares, but its **trunk base** owns blocking and Axe targeting. With the suitable packed Axe selected at a reachable adjacent position, a small base highlight and **Chop tree** show the valid action. The impact lands at the trunk. Looking at leaves alone does not grant a harvest. Tool requirements, one-turn successful hits, saved partial work, and each tree’s own canopy remain as already decided.

Foreground trees, bushes, and objects partly fade when their artwork covers the character, then return to normal when the character emerges. A faint silhouette and the already-visible blocking base remain understandable. For raised terrain, only the obstructing foreground cliff face fades; the entire plateau does not disappear.

**Fading is a visual aid, not extra sight.** It reveals only the character and surroundings already permitted by the game’s visibility rules. It cannot expose fogged terrain, hidden creatures or resources, or things still concealed by gameplay canopy. The existing canopy rule remains: a second consecutive canopy square conceals what lies beyond; standing beneath canopy gives the local exception around the party. That exception does not erase other sight restrictions. Earned minimap knowledge remains earned. Fading itself spends no turn and changes no collision, target, harvest, or discovery.

**Unsettled renderer proposal:** actual 3D rendering with sprites and a fixed orthographic camera is under consideration, partly for atmosphere and Blender authoring. A small Simulator comparison would show one existing grid patch, depth and foreground fading, local water, a simple shadow and one atmospheric effect. Engineering recommends a separate 3D trial, but no renderer, Blender import or performance demonstration is implemented. The full shallow-water-bed demonstration still needs explicit water-depth and bed-height facts; hidden terrain must not leak through shadows or reflections. The renderer has not been chosen. This would preserve the square-grid actions, saved worlds and fog rules; it does not decide stacked floors, physics, camera rotation or a day/night system. The current playable overhaul continues before broad terrain production.

**Accepted for later, low priority:** trees, elevated land, bushes, resource nodes, and the player character should have shadows in the three-quarter view. Their shape and treatment will be worked out after the new world geometry and foreground visibility are established. This is a presentation direction, not a decision to add dynamic lighting or a day/night system. The playable overhaul takes priority.

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

**When early recovered lessons begin:** after your first expedition ends, newly generated worlds can offer the opening recovered lessons. Seeing water or Iron on that first expedition does not yet create a recovered lesson or count toward its repeated-miss protection. Returning does not add a lesson retrospectively to that world. The introductory Illumination and Sun teaching is separate and remains recoverable. This first-expedition gate is retained in the accepted early progression rules; whether its pacing feels good is still being playtested.

**How repeated-miss protection works in development:** it applies to suitable opportunities, not every expedition. When the same traveller is selected again after two failed arrival-chance rolls, their arrival chance is certain; finding suitable land or placing that person does not automatically complete the invitation. Fully causing their required world conditions can also make the arrival chance certain. A different traveller being selected, unsuitable land, or leaving before meeting a placed traveller does not count as a failed arrival roll for Nessa.

Water lessons likewise need a suitable learning opportunity: safely observable liquid water for the water target, then an actually generated River and the known target for the River lesson. Repeated eligible misses make a lesson due, while older due lessons retain priority. Ice alone does not qualify under the current rule. There is no decided promise of these lessons or Nessa within a fixed number of expeditions. Whether the opening gives enough reliable progress before healing is available remains a playtesting question.

Old diaries and collected Pages remain yours. An older location clue continues to help you find its person, with an updated location hint alongside its original record. Existing people, buildings, tools, knowledge, and unlocked abilities remain. Already-created worlds keep their original contents.

### Ordinary gathering — decided intended behavior

The early materials have ordinary sources as well as deliberate Writing routes. Iron needs an Iron-bearing formation; Coal needs a compatible seam. Clay comes from a genuine Clay placement. Resin, Logs, and Plant Fibre come from plants suited to the land, light, water, and temperature. A stone-coloured tile does not automatically contain Iron, and green ground is not automatically harvestable.

Suitable worlds set aside some source opportunities for the early crafts. They do not put the whole starter catalogue into every world. Cold, submerged, corrosive, or otherwise unsuitable ground can support different things. Sunlight by itself does not guarantee a forest or a safe journey. Your pinned recipe can help you notice relevant sources when you can normally see them.

**First-pass source tuning:** where the necessary hosts exist, reserve one ordinary Iron node, one Coal node, and up to two Clay gathers, limited by the number of suitable deposit sites. Suitable growing land starts with two Stem Fibre patches, one Leaf Fibre plant, one Resin shrub, and two small Softwoods. More plants and nodes depend on the world’s size, growth, and eligible sources. Hardwood can appear before you have the Axe needed to harvest it. Intended written guarantees count toward these source budgets; they are not duplicate bonus caches. The explicit written Iron guarantee and its budget credit are now implemented and tested in development, as described below. This does not add written Coal, Clay or Resin guarantees or new vocabulary.

The intended first healing trip needs six harvest actions before travel and encounters. Building the forge and improving the Pick needs thirteen harvest actions across enough source-bearing worlds. Those are ingredient calculations, **not measured trip lengths**. The complete route still needs testing for travel, survival, returning safely, and enough Essence left to bind another world. A useful expedition should not require clearing its whole map.

### Writing Iron into the ground — decided intended behavior

**Implemented and tested in development; this is not current phone behavior.** Deliberately writing Iron into Substrate promises **one cluster of two reachable Iron deposits**, provided the complete promise can be fulfilled. A compound saying the same thing counts too. Repeating the request or changing Count, Scale or Intensity does not multiply the guaranteed cluster; those words keep their existing effects on the world and writing costs. Iron left for the world to choose does not receive this written guarantee. Absent Iron, Iron bound to another subject, or an Iron statement that negates its own Substrate effect does not qualify. Negating one statement does not cancel a separate positive one.

The two deposits use the existing Pick 1 rule and contain twelve Iron altogether. They count within the ordinary mineral budget and satisfy its ordinary Iron reservation. They are not two bonus deposits on top of it.

Use existing suitable exposed rock first. Where necessary, the world may expose compatible rock at no more than the two deposit sites in otherwise empty, dry, unfrozen ordinary soil. Both deposits belong to one compatible region. This cannot drain water, thaw ice, change heights, remove a source or object, or overwrite protected arrival, teaching or return routes. The exposed ground stops counting as growing soil.

Distances refer to where you can stand to mine: the first working position is three to eight walkable steps from the entrance, and the second is at most four steps from the first. Both must remain reachable after the deposits are placed.

Before Binding, the quote identifies the complete promise and the known tool requirement. If two reachable deposits cannot fit, the page is refused before spending; it does not silently promise just one. A genuine conflict between direct written guarantees follows the existing compatibility rule: the quote names which promise wins and which remains an influence before you Bind. Existing worlds keep their original contents. This first binding adds no new writable Coal, Clay or Resin vocabulary.

**Development check:** selecting a collected Iron-written Page, reviewing its quote, Binding and entering the world succeeded in the native app. The quote promised two reachable deposits requiring Pick 1, and the resulting world kept that promise. This test used an arranged campaign; it does not establish the natural route to learning Iron or making your own first Iron page. Direct and compound Iron statements, incomplete promises, changed quotes, saving and reopening have separate rules checks. Phone delivery and natural progression remain pending.

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

**Development check:** the native forge now completes Pick and Axe improvements, the T2 upgrade, Iron smelting and the Scythe improvement, preserving each tool and its place in the roll after reopening. An arranged field test then harvested a Tall Stem Patch for 3 Stem Fibre in one turn. The harvest saved successfully; a tutorial interrupted the subsequent test navigation, and a separate reopen confirmed the depleted patch and retained Fibre. This is a completed functional forge-to-harvest milestone, not a natural affordability test or phone delivery.

**Tannery development check:** building the Tannery, making Cord and Cloth, crafting both woven garments and reopening the saved game now succeed in an arranged native playthrough. The garments keep their intended Protection and value, arrive in Storehouse or Waiting, and are not automatically equipped. Focused checks cover matching ingredient groups, keeping every material source, dismantling into the recorded prepared components, and refusing stale or failed-save transactions without double spending. Early Stem, Leaf and tall-stem plants inherit the world’s saved foliage colour unless a plant has a specifically assigned shade. That colour stays with its harvested Fibre, then its Cord or Cloth. A garment’s body uses the chosen Cloth colour and its ties use the chosen Cord colour; dismantling preserves those prepared components. Matching fibres from different plants may combine, but different colours are never silently averaged.

Older fibres without a recorded colour remain owned and usable for their existing ordinary costs. New colour-bearing Cord and Cloth recipes require fibres with a known colour; they do not guess or overwrite an older source. The colour rules are now implemented and tested in development, including newly generated plants through harvesting, Return and reopening. The native crafting check shows deliberately assigned ingredient-colour swatches. It does not yet prove the complete visible journey from a naturally coloured plant to finished garment artwork: garment thumbnails still use a generic placeholder, and the field-colour display has not had that full visual check. Final artwork, natural affordability and phone delivery remain pending.

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

**Carry development check:** the two Storehouse projects now complete in the native app and preserve 14 spaces after reopening. In an arranged opening campaign, buying both left 25 Essence; the next actual Bind cost 10, leaving 15 Essence and a bound pack with 14 spaces. This verifies the purchase and next-Bind flow, not how naturally the ingredients are gathered.

A separate arranged specialist campaign saved Corrin’s expansion to 23 spaces. Its test then looked for Sela in the wrong menu; continuing through the existing Realms foundation completed her separate bonus and confirmed 25 after reopening, without buying Corrin’s project again. Focused checks preserve old purchase credit, prevent duplicate benefits, and keep an active expedition’s pack and contents intact. The larger capacity applies at the next packing boundary. Existing campaigns are not silently switched into the overhaul. The separate Woven Gloves and Boots checks are recorded below; phone delivery and full journey affordability remain pending.

The first project leaves 35 of the opening 40 Essence before other spending; both early projects leave 25. From an opening campaign without the Tannery, all three pack projects and its foundation together need **55 Essence, 26 Plant Fibre, 2 Resin, 6 Logs and 4 Clay**. These are optional stages across trips, not an opening shopping list. The isolated next-Bind check above passes; full journey testing must still measure gathering, other spending and later affordability.

The built Tannery also teaches **Woven Gloves** and **Woven Boots**, with no extra lesson cost or free stock. Gloves use **1 Plant Cloth and 1 Plant Cord**. Boots use the same plus **1 Resin**. Each costs no Essence and gives **Fine equipment with total Protection 1.0** in its own slot, with no Initiative, heat protection or harvesting bonus. Either needs 6 raw Plant Fibre after processing; Boots also need the Resin. Cloth and Cord keep the chosen colours. Neither recipe requires animal materials, smelting, or the pack projects. Existing equipment and patterns remain available while the update is being made.

**Gloves and Boots development check:** preparing their Cloth and Cord, crafting both items and reopening their details now pass in an arranged native playthrough. The quotes show the intended Hands or Feet slot, Fine quality, Protection 1.0, ingredients and value. A separate native Recycler check dismantled both and confirmed the original 2 Cloth, 2 Cord and 1 Resin after reopening, with their recorded sources preserved. The pack had no Carry purchases, confirming that these recipes do not require that progression.

Focused checks also cover full Storehouse delivery to Waiting, exact colours and source quantities, partial Resin recovery, older Resin stock and save failures without duplicate crafting or refunds. Ingredient-colour swatches and source details are verified; generic item icons remain placeholders. Natural affordability, finished component-coloured artwork and phone delivery remain pending.

### Creature bodies and habitats — decided intended behavior

**Current development status:** physical habitat placement and the narrow Hide reward have development checks. Generation does not yet consistently choose a body suited to its habitat, and flying movement is still more restricted than the intended water crossing below. These new compatibility rules are designed, not delivered to the phone.

Creatures will have a body and movement that suit the home their world provides. The first set uses four-legged, two-legged, serpentine, segmented, radial, fish-shaped and amorphous bodies; wings, fins and other appendages remain separate features. World conditions influence the possibilities without promising a named species.

| Habitat | Decided movement |
|---|---|
| Land | Suitable connected ground; ordinary land creatures do not enter water |
| Shore | Shallows and their adjacent banks; a fish-shaped shore creature needs supporting limbs to use land |
| Aquatic | Connected shallow and deep liquid water; swimming bodies do not always need separate fins |
| Aerial | Suitable ground and water, including deep water; membrane or feathered wings are required, but a perch is not |

Flight does not open a party route across deep water. A creature beyond the party's current reach cannot be pulled into an ordinary encounter for convenience. Trees, blocking deposits, chasms and crumbled gaps remain obstacles in this first slice. Ice is not liquid habitat, though passable ice can support movement as ground.

A habitat needs at least two connected suitable tiles. Most ordinary placement slots remain reserved for habitat areas the player can make contact with; this is not a promise that every animal starts on a reachable tile. A creature may move within its own area, but it cannot teleport out when blocked. Aquatic life in remote deep water may remain out of reach.

Existing worlds retain their creatures and movement. The completed Hide path keeps its actual-source checks, drop chance, Anatomy benefit, quality, colour and material history.

**Still unfinished:** the wider creature rework, additional anatomical materials and their recipes, and food, nesting and weather relationships. Aimee has lifted the Bestiary work hold after approving the arrangement below. This first habitat slice needs no new Aimee decision.

### Bestiary arrangement

**Decided intended behavior · approved 5 September; not yet implemented.** Browse the Bestiary through **Sky, Water, Amphibious and Land**, then by body shape within each section: **Four-legged, Two-legged, Serpentine, Segmented, Radial, Fish-shaped and Amorphous**. For example: Sky → Serpentine → creature entry, or Water → Fish-shaped → creature entry.

A creature’s supported habitat determines its section. Amphibious means suited to water and adjacent land; it does not mean the Earth animal class or unrestricted travel through every depth. Wings on a land-bound creature do not place it in Sky. Body shape describes its main body, rather than counting every wing, fin or other appendage. A category does not grant new abilities or reveal undiscovered creature information.

**Bestiary work can now proceed:** Aimee explicitly lifted its hold after approving this structure. The wider creature rework remains unfinished. Materials and known source details belong inside each entry.

**Browsing proposal:** show body-shape subcategories represented by recorded creatures, without suggesting that every possible combination must be collected. This display treatment remains a recommendation.

### Creature descriptions that match their lives

**Decided intended behavior; not yet implemented.** New creature names and role descriptions should reflect their actual supported bodies and behavior. A flying creature can be described as a flier; a land-bound membrane creature cannot. Fins and body proportions alone do not establish an eel identity, and low bone density does not establish hollow bones.

An Ambusher needs the existing concealed close-range striking traits. Pursuers can still fight and chase without a separate natural weapon. Swarmer describes an existing multi-strike or area attack profile, not a promise of a colony; Sentinel does not promise nest guarding. Ordinary creatures must not gain the separate Apex identity just because they are large and well-armed.

A grazing diet is not yet defined, so new descriptions will not call a creature a Grazer merely because it has weak weapons or lives near plants. Its diet stays unspecified. These naming rules add no new behavior or food simulation; existing worlds retain their names, and source materials keep their own rules.

**Still open:** actual food relationships, nesting, weather responses and the full creature experience. This is partial progress on ecological coherence, not a completed ecology system.

### Bone — first material beyond Hide

**Decided intended behavior; not yet implemented.** This is partial progress on the body-to-materials design, covering Bone rewards, source history, Return and ordinary trading. It does not finish the anatomy catalogue or the new crafting route.

Bone comes from a qualifying internal skeleton. A hard shell, horn or armoured hide does not automatically supply it, and an amorphous creature does not leave Bone. Aquatic and flying creatures may have skeletons; flight alone does not make their Bone hollow. The first material is simply **Bone**. Hollow Bone and Dense Bone are not newly promised subtypes.

**Retained first-pass yield:** the species determines 1–3 useful Bone portions. A qualifying defeated creature supplies those portions through the normal victorious-encounter reward; Bone does not share Hide’s 70% roll. The existing Anatomy benefit raises base yields of 1, 2 or 3 to 2, 3 or 4. Individual size variation does not reroll that quantity.

The actual creature’s skeletal density and size determine part quality using the agreed four-band calculation and source-world Danger. Its full source colour and material history stay recorded. Exact finished colour artwork remains pending.

| Bone quality | Ordinary sell value per portion | Buy price if legitimately offered |
|---|---:|---:|
| Poor | 2 Gold | 4 Gold |
| Common | 4 Gold | 8 Gold |
| Rare | 8 Gold | 16 Gold |
| Exceptional | 16 Gold | 32 Gold |

These are the agreed raw-material prices, not the multipliers used for equipment statistics. Colour and species do not add a hidden sale premium. This does not add shop stock. Older Bone keeps its existing value and uses.

**Crafting still unfinished:** the existing Bone-compatible Pointed Blade uses the older crafting rules. The new Bone material needs a compatible crafting update before entering that recipe. No new Bone weapon cost, recipe or unlock is approved by this source design. Older Bone recipes and crafted items remain available through their existing rules.

The first creature Homework task stays unchecked. Bone production and trading are specified; the complete body-part catalogue, crafting connections and natural gathering experience still need work.

### Optional Hide-to-Leather path — decided intended behavior

Some generated animals can provide **Smooth Skin, Supple Hide, or Tough Hide**, according to their actual covering. A feathered, scaled, shelled, or furry animal does not silently become a Hide source. Relevant creatures can be highlighted for a known recipe as soon as normally visible, but a possible drop is not a promise. Their appearance and species remain generated.

**First-pass reward tuning:** a qualifying creature has a 70% chance to provide its covering after defeat, yielding a base 1–4 parts according to body size. The part’s actual source determines its Poor, Common, Rare, or Exceptional quality and its colour. Better quality improves its contribution to an eligible craft; it does not make the animal drop more pieces. No tool is required to collect that defeat reward.

**Anatomy is preserved:** if the expedition already has the earned Anatomy benefit, a successful covering drop keeps that bonus. Base yields of 1, 2, 3 or 4 become 2, 3, 4 or 5 parts. Anatomy does not improve the 70% chance or turn a failed drop into a success, and it does not change the part’s quality or colour. The expedition’s saved benefit applies once to each successful drop; changing the party later cannot reroll or multiply it.

**Animal-material development check:** the new source rules now save a qualifying creature’s actual covering, colour, quality and possible reward before combat. An arranged native encounter awarded 2 Supple Hide after victory and kept that reward after reopening. Focused checks cover physical habitat, all three part types, successful and failed drops, Anatomy, existing-material compatibility and saving without duplicate rewards. This replaces the eligible old Hide reward once; it does not add a second covering reward.

The native encounter used a prepared foe, so it does not measure how often suitable animals occur or how comfortable the gathering journey feels. Broader compatibility tests retain six failures also reproduced before this reward change; they have not been claimed as fixed. Leather processing and the Guard have their own development check below. Complete recipe highlighting, final artwork and phone delivery remain separate work.

Salt comes from exposed crust on suitable dry soil or sand beside saline water, or from an exposed deposit in dry saline ground. It is gathered by hand: 2 Salt in one action, then that placement is depleted. White ground alone does not promise Salt; wet mud, ice and submerged deposits are not hand-gatherable crust. Fresh growing country does not automatically supply Salt. This separate gathering trip is one reason Leather is optional rather than a prerequisite for the first Tannery crafts.

**Salt generation — decided first-pass tuning:** an eligible saline-shore region has a 50% chance to provide exposed crust sites. A region without eligible shoreline sites may instead use the dry saline deposit route at 35%. A failed shoreline check does not receive a second roll. Suitable sites still share the existing gathering budget, after promised sources and ordinary Clay; these chances do not guarantee a Salt gather in every world or change the amount of water. Existing worlds keep their contents.

**Ordinary Salt development check:** an isolated generated sandy-shore test now gathers 2 Salt by hand, depletes the crust and keeps the result after reopening. Focused tests cover both generation routes, physical host requirements, older-world preservation, saving and Return. A successful Salt-site roll still cannot displace required Clay when the gathering budget is full. This proves the ordinary source and harvest flow; it is not a natural expedition or phone-delivery test.

**Written Salt — decided behavior, now tested in development:** explicitly writing Salt into Substrate promises one reachable Salt Crust, gathered by hand for 2 Salt. Its standable location is three to eight walking steps from entry. Repeated requests, compounds, Count, Scale and Intensity do not multiply the promise. Salt written into Hydrology or Vitality keeps its pressure effects without this deposit guarantee. An Absent or locally negated statement makes no promise of its own; it does not cancel a separate positive Salt statement.

Use a suitable exposed crust first. Otherwise, the written material may form one small crust on empty, dry, unfrozen soil or sand with known ordinary-water chemistry. The surrounding world can remain fresh: this request does not require a salty-water climate or a lucky ordinary Salt roll. It preserves water, heights, underlying ground and protected sources, and cannot drain a pool, thaw ice or clear a path to make room. The crust’s own patch cannot also be a growing plant.

The promised deposit uses one existing earth-gathering place before ordinary Clay and Salt allocation, and counts toward the ordinary Salt reservation. It is not extra stock or an enlarged source budget. Before Binding, the quote must confirm the reachable hand-gathering deposit. If no legal site or budget fits, it refuses without spending. Only a genuine conflict with another direct written promise follows the existing disclosed winner-and-influence rule; a failed placement cannot silently become pressure only. Older books keep their existing behavior. This introduces no new word, free knowledge or phone-delivery claim; ordinary Salt already works independently in development.

**Written-Salt development check:** an isolated native Writing Desk quote showed one reachable hand-gathered deposit and a 2-Salt yield. Binding cost 14 Essence, leaving 26 from 40. The expedition followed the actual seven-step route to the crust, gathered 2 Salt in one action and retained both the Salt and depleted source after reopening. Nineteen focused checks passed, including compound statements, conflicting or absent requests, shared Iron/Salt placement, old books, source budgets and saving without duplicate spending. This proves the quoted generation-to-gather route; it does not establish natural vocabulary learning, pacing or phone delivery. The natural campaign remains at Home with 29 Essence after three expeditions.

| Optional Tannery recipe | Inputs | Result |
| --- | --- | --- |
| Leather | 2 matching Smooth Skin, Supple Hide, or Tough Hide, plus 1 Salt | 1 Leather retaining the parts’ quality and colour |
| Leather Guard | 2 matching Leather plus 1 Plant Cord | Body equipment with Protection calculated from that Leather; the preview shows the exact result |

Both recipes cost no Essence. Matching parts can come from several animals when their type, quality, colour, and relevant properties are the same. Different qualities or colours are not silently averaged together. A complete Leather Guard uses **4 matching raw parts, 2 Salt, and 2 Plant Fibre**, including its processing steps.

Before tanning, the two raw parts must be the same kind. Once prepared, matching Leather may be combined even if its original parts came from different kinds of Skin or Hide, provided the retained quality, colour and relevant physical properties are identical. Every ingredient keeps its source history; different results are not silently blended.

The full animal colour and pattern data stays with the material. An exact on-screen creature-to-Leather colour conversion is not yet established, so a generic icon is not a preview of that finished colour. Retaining known source colour and completing crafting transactions does not itself prove the final artwork matches it.

Leather determines the garment’s finished quality: Poor parts make Rough work, Common makes Fine, Rare makes Superior, and Exceptional makes Exceptional. It adds no hidden Initiative, heat protection, or durability. Dismantling returns the recorded prepared Leather and Cord; it does not also refund the raw parts or spent Salt. Existing equipment and older materials remain available through their supported uses.

**Tannery presentation development check:** the updated panels, ingredient selection and complete recipe quotes are now integrated and tested in the native app. Plant-stock checks cover Cord, Cloth and the woven garment preview. A separate existing-stock check covers the missing-Hide explanation with Review unavailable, Leather and Cord selection, the full Leather Guard quote, Cancel and reopening. Cancelling preserved all materials and Essence. This was a presentation check, not another craft. The eligible raw-Hide selector has since passed in the connected playtest below. An injected save-failure message has not yet been visually checked; final material-colour artwork and physical-phone acceptance remain pending.

**Leather crafting development check:** an arranged native playthrough now tans two Leather, makes Cord, crafts a Leather Guard and confirms the item after reopening. The chosen test materials made a Fine Guard with Protection 2.50, no Essence cost and sell/buy values of 10/20 Gold. Protection still depends on the selected Leather; 2.50 is this example, not a fixed value for every Fine Guard. A separate native Recycler check dismantled it and confirmed exactly 2 Leather and 1 Cord after reopening, with no raw Hide or spent Salt returned.

All 25 focused checks in this consumer test run passed, covering exact source matching, all four quality/stat/value bands, preserved colours and parents, full storage, older Salt, saving and duplicate-action refusal. The six older compatibility failures described above remain separate and unresolved. Value records do not themselves add merchant stock or a new material-selling route.

Animal frequency, source matching during ordinary play, combat, recipe highlighting and the complete gathering journey still need playtesting. Ordinary Salt, the limited animal-source rules, Leather processing and the Leather Guard now have bounded development checks; this does not establish natural affordability or phone delivery. The wider creature rework is still unfinished, including additional body-derived materials, their uses and broader ecology. This Leather work does not update the Library Bestiary or establish that the whole creature rework is complete.

### Connected material development playtest

**Now available as a prepared Simulator playtest; not a phone release.** One connected native run gathered Salt, returned it Home, used that exact Salt to tan the supplied Hide, made a Leather Guard, and completed the first two pack projects. The item, material history and 14-slot capacity survived reopening.

**Carry presentation development check:** the updated capacity panels and full review are integrated. Opening a project review and cancelling keeps the original capacity; reopening the completed route shows 14 spaces and both projects applied. The prepared playtest now uses this presentation. Missing-stock, next-Bind affordability warnings and save-refusal presentation still need their own visual checks. Prices and purchase rules are unchanged; physical-phone acceptance remains pending.

The separate player copy starts beside an unharvested Salt Crust. Four matching Common Supple Hide, coloured Fibre, Resin and supporting stock are already supplied at Home, with the relevant buildings ready. The short route is:

1. Gather 2 Salt by hand, then walk back to the portal and Return.
2. At the Tannery, select the Common Supple Hide and confirm two Leather recipes.
3. Make Plant Cord, then review and make the Leather Guard.
4. At Storehouse → Satchel, complete Reinforced Stitching and Balanced Straps to increase capacity from 8 to 11 to 14.
5. Reopen to check the saved results. You can Cancel at any quote.

The checked materials produced a Fine Leather Guard with 2.50 Protection; that number belongs to those selected materials. The completed acceptance run ended with 10 Essence, one Guard, no raw Hide or Salt, and the two recorded Leather preparations. Village income occurred during play, so use the live quotes rather than assuming the wallet stays at its starting value.

This route also checked the eligible raw-Hide selector. A repeatedly returning tutorial was corrected: **Not now** now lasts for the current app session; reopening or explicitly replaying the tutorial may show it again. It does not mark the lesson completed.

**Still unproven:** finding and learning everything naturally, creature/material availability, combat and economy pacing, and affording the next expedition through ordinary play. The natural campaign remains separately preserved at Home with 29 Essence after three expeditions. No fourth search was made. The overhaul remains off for ordinary campaigns; final creature/Leather artwork, the wider creature rework and physical-phone acceptance remain unfinished.

### The Binder’s own Gambits

Self-automation remains an earned ability; opening Party does not grant it. Existing unlocked campaigns keep it. The intended owner is the recovered instruction **Let your own rules run**, found in a world and read in the Library. Party uses learned Gambits and never teaches this ability. Reading does not create a rule or change any rule's enabled state.

The first-pass plan makes this later instruction eligible after Binder level 8, eight resolved expeditions, and the three opening Gambit teachings: **Check yourself**, **Leave the fight**, and **Use your skill**. Those timing values remain revisable. The replacement teaching route is not yet verified as delivered; old Workshop wording must not be read as proof that a current route exists. Until the ability is learned, the Binder takes manual turns. The delivered locked message now reads: “Your turns are manual. Following your own Gambits is a learned ability.” This removes the obsolete Workshop direction without promising that the replacement teaching is already available.

### World and equipment colour

Worlds use stable, coordinated palettes, with separate foliage, water, and sky colours. Grass belongs visually to foliage; that does not make every patch harvestable. A specifically assigned shade takes precedence. Returning or reopening keeps the same world colours.

Tint preserves shading and recognizable material cues. Water still reads as water through reflections, shores, and surface patterns; colour alone does not declare danger. Equipment keeps consistent silhouettes and shading, and **every material component region** receives its chosen tint. Quality appears in the item-name highlight and the square thumbnail border, not as a recolouring of the item artwork. Potions and remedies keep their recognizable authored colours.

**Resource icon development check:** the selected original Coal, Hardwood Log, Leaf Fibre and Softwood Log pictures now appear in Storehouse stockpiles and the Field Kit. They keep their original colours, complete framing and source dimensions, with the selected transparent backgrounds; the game fits them into its existing icon spaces without recolouring them. Native checks confirm the correct pictures beside their material names and quantities. They have not yet been delivered or visually accepted on the physical phone. This does not complete other material or garment artwork.

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
| Iron | Iron-bearing formations in Granite, Sandstone, or Basalt; selected Pick 1, deliberate step toward the blocking base | Three hits, 2 Iron each: 6 per node |
| Coal | Fuel-bearing Sandstone formation; selected Pick 1, deliberate step toward the blocking base | Three hits, 2 Coal each: 6 per node |
| Clay | Explicit loose Clay deposit on passable, unfrozen Clay soil or a compatible muddy margin; gathered by hand | One action, 2 Clay |
| Stem Fibre | Ordinary medium stem-fibre patch; Scythe 1 | One hit, 2 Stem Fibre |
| Leaf Fibre | Ordinary low leaf-fibre rosette; Scythe 1 | One hit, 1 Leaf Fibre |
| Resin | Ordinary low resin-producing shrub; Scythe 1 | One hit, 1 Resin; a direct harvest, not a lucky bonus |
| Softwood Log | Small softwood tree; Axe 1 | One hit, 2 Logs |
| Hardwood Log | Small hardwood tree; Axe 2 | Two hits, 5 Logs on completion |

These starter plants belong to compatible cool, temperate, or warm habitats with fresh damp or moist roots and sufficient daylight, without intrinsic danger, frozen or submerged roots, acid precipitation, or corrosive air. A tree has a small cross-shaped crown; its trunk and canopy change together when felled. A successful gathering hit spends one world turn. Cancelling or choosing an unsuitable tool spends none. Partly harvested sources retain their progress and do not regrow in this first set.


Ordinary background moisture counts as water even when the written conditions only reduce its amount. Sea, Tide and Brine still carry their actual saltiness. A Mercury seam is local: it does not turn every river or plant root in the world into Mercury. Mercury itself supplies no ordinary watering, and roots actually touching Mercury, another non-water liquid, or an unidentified liquid are unsuitable for these starter plants. Nearby ordinary water keeps its own identity.

Early ingredients must have ordinary gathering routes; they cannot depend exclusively on a lucky merchant offer, recycling, creature loot, or a later resource-Writing symbol. An arranged development journey now completes gathering, Return, building the Apothecary, preparing and packing a Salve, the next Bind, and using it. Natural generated-world pacing still needs playtesting.

### World-generation findings — development results, not phone delivery

The first test of **1,000 completely unwritten worlds**, before the latest corrections, found suitable Iron ground in 98.2%, Coal ground in 90.5%, and fresh growing land in only **3.6%**. That missed the intended 25% review target and exposed a real early-gathering problem. These historical results are not final encounter rates. Seven generation failures also occurred under the older generator.

**Decided calculation correction, checked in development:** a small amount of Ice must not erase the ordinary unfrozen water already available to plant roots. Background water remains represented before actual freezing conditions are applied. The six direct checks pass. This correction is not yet delivered to your phone.

**Decided intended tuning for new early worlds:** make extreme conditions less common when the world chooses something you left unwritten. Faint / Moderate / Great / Overwhelming have starting weights of **70% / 25% / 4% / 1%**. Every source type and all four intensities remain possible. Your own written choices and already-created worlds stay unchanged. The current game keeps its existing rules until this update is delivered.

With the chosen sources held fixed, those weights improved suitable soil-condition checks from **6.7% to 30.6%** for unwritten inputs and **20.3% to 41.7%** with a moderate Sun. Soil conditions alone do not prove that gathering sources appear on the map.

**Latest full actual-map test:** one set of **1,000 completely unwritten worlds** used the corrected root water, adopted intensity weights, blocking deposits and connected-habitat check. **999 maps generated; one failed.** All percentages below use the full 1,000 requested worlds.

| Measure | Worlds out of 1,000 |
| --- | ---: |
| Fresh growing habitat, previous single-region check on these same maps | 202 (20.2%) |
| Fresh growing habitat, connected-area check | **296 (29.6%)** |
| Fibre-bearing habitat, previous check → connected-area check | 278 → 299 |
| Iron actually placed | 997 |
| Suitable Coal hosts → worlds with Coal actually placed | 928 → 927 |
| Resin actually placed | 296 |
| Softwood actually placed | 293 |
| Stem Fibre actually placed | 299 |
| Leaf Fibre actually placed | 299 |

The **25% growing-habitat review target is met in this sample**. Habitat and placed materials are different measures: recognizing suitable land does not prove that every intended source was placed. The old and new habitat counts come from the same maps, so that difference reflects the counting correction rather than an additional climate improvement. Individual material counts do not by themselves establish how often a world contains the complete set.

**The original overall test failed:** five worlds missed part or all of their intended Softwood reservation, and one missed Coal. Focused diagnosis now separates the causes. Three plant cases genuinely lack enough shared space for Resin and two trees; one also contains a protected exit. Keep the Resin and exit rather than forcing extra trees into unsuitable or occupied ground. The other two plant cases and the Coal case have legal alternatives within their existing source budgets: flexible fibre or Iron placements took the scarce sites first.

**Decided intended allocation correction:** reserve scarce suitable places for required sources before flexible choices and optional plants or minerals consume them. Moving a flexible plant to another legal site can leave room for required Softwood; using the only Coal site for Coal can still leave plenty of Iron. Existing source budgets, habitat requirements, protected routes and saved worlds remain unchanged. The correction is now implemented in development. Focused runtime checks supply both required Softwoods in each of the two affected plant worlds and Coal in the affected mineral world, within the original budgets and with reachable working positions. The three genuine capacity shortages remain explicit. Saved older worlds keep their previous placements. These checks do not turn the original failed full test into a pass or establish new population-wide percentages.

Separately, 22 worlds had only one legal Clay site where two were requested. Those are confirmed capacity limits, and a second deposit is not forced onto unsuitable ground. Every source that was placed retained a reachable working position.

The earlier, smaller comparison contained all four starter plant sources in 16 of 64 unwritten worlds and 23 of 64 moderate-Sun worlds. There has been no new full Sun-written test. The full unwritten result above is the latest measurement, not a promise about every future journey.

**Decided intended habitat correction:** suitable growing ground counts together across the area connected to the entrance. It does not stop counting at a change of soil or elevation. Nessa’s fresh growing land still needs at least twelve suitable ground cells and legal Resin and Softwood sites; Corrin’s fibre-bearing growth needs twelve suitable cells and legal Stem and Leaf sites. Each cell must meet its own habitat requirements. Disconnected, dark, frozen, saline or otherwise unsuitable ground does not help. No extra plants are added, and harvesting does not erase a world’s established suitability.

The previous check required all twelve cells within one terrain region. The connected check is now implemented in development and passes focused cases for split areas, unsuitable and disconnected ground, duplicate cells, missing source sites, and preserved older worlds. It does not change terrain or add plants merely to change the habitat result.

**Water-channel correction, tested in development:** the single failed map had four flowing-water cells divided into channels of two, one and one, although ordinary channels needed two distinct cells. This failure occurs with the adopted conditions; the original conditions generated that world successfully. The corrected allocator uses two two-cell channels, keeping the same water total and all 102 frozen-water cells. That world now generates through material placement, with twelve reachable gathering sources.

For a total of only one flowing-water cell, the intended rule is a short shallow outflow at the map boundary or into existing standing water at the same or lower elevation. The receiving water is not counted twice. With no valid outlet, generation explicitly refuses that layout instead of dropping the water or pretending it is a pond. Focused small-water, saved-world and repeat-generation checks pass. Older worlds keep their previous rules. The original full-sample results above have not been replaced by a new large run.

**Connected journey, tested in development:** an arranged first world has been played through six gathers, Nessa’s invitation, full Return, Apothecary construction, Lesser Salve preparation, packing, the next Bind, and use of the carried Salve. Native use confirmed target selection, consumption and one turn on a full-health character. A separate controlled injury check confirmed the existing 10-point healing effect. Arranged sources and those checks do not establish ordinary gathering time, encounter pressure or next-Bind affordability in naturally generated worlds.

### Three natural trips — measured development findings

A normal paid blank-world journey now supplies and returns the first healing ingredients: **4 Clay, 4 Softwood Logs, 1 Resin and 2 Stem Fibre**, with no material loss. Six harvests and **47 movement turns** took **53 of 546 world turns (9.71%)**. Five natural encounters required ten player Attacks, which did not add to that world-turn counter. The trip met the existing movement and world-budget review targets; the fights still represent real effort. This is one route, not an average-world result.

**Nessa did not appear.** Her clue was read during the trip, and the saved campaign records one Nessa near-miss. Under the existing rules, that means she was selected as the candidate but failed the chance to appear; no person was placed, invited or recruited. The exact original roll was not retained. The first blank attempt’s 25% chance is derived from the rules, not a recovered roll record. Finding the clue after Binding cannot change that already-created world.

On a later suitable world, the clue helps Nessa’s selection priority. With one prior miss, another blank attempt has a 50% arrival chance **if she is selected again**. After two selected misses, the next selected attempt is certain. These are not promises that the next world contains her habitat or selects her, and no extra person is inserted into an existing world.

**Second trip:** one further ordinary blank expedition took 38 movement turns and one encounter with two grazers. It returned five raw Essence and four hides with no loss; the original healing materials remained banked. Substrate teaching was collected once and remained unread. No third Bind has been purchased at this receipt.

This time **Nessa’s habitat did not match**. The saved world was too dark for the starter growing plants: every region failed the daylight requirement. Halloway was the sole eligible candidate and failed his own 25% appearance chance. This was not a second Nessa near-miss, and Halloway did not displace her. Nessa still has her first near-miss for a later world that actually matches and selects her.

| Measured funds across the two trips | Essence |
| --- | ---: |
| Opening, before the first paid Bind | 40 |
| After the first Bind | 30 |
| After the first Return, including 3 from the existing spring | 33 |
| After the second paid Bind | 23 |
| After the second Return, including its spring yield | **26 spendable, plus 5 raw Essence** |
| Manual refinement completed at Home: five raw Essence converted to ten | **36 spendable; no raw Essence left** |
| Earlier blank quote, inspected before refinement and not purchased | Cost 10 from the then-current 26 |
| Two-mark Moderate Sun into Illumination page, later purchased for the third trip | **Paid 14; 36 became 22** |

Manual refinement has now completed through the visible Home action: the campaign has **36 spendable Essence and no raw Essence left**. Automatic refinement remains off; no fee, subsidy or extra grant was used. The earlier possible four-Essence shortfall assumed no extra income; this trip earned raw Essence, so that shortfall did not occur. If Nessa were already recruited, 36 would cover her current 20-Essence foundation and a 10-Essence blank Bind with six left. She is not recruited, and another search has its own price and earnings. The complete healing route’s budget therefore remains unproved.

Field health ended at 24/30 and 13/24 on the first trip, then 27/30 and 21/24 on the second. Home recovery is free, and each new departure starts at full current health. There is no paid-rest or Salve requirement to leave again; healing during a world still matters. The natural campaign has enough ingredients but has **not yet recruited Nessa, built her room, prepared a Salve or carried it into another world**.

**Home preparation, verified in development:** the recovered Substrate lesson was read in the Library and taught that target only, at no cost. Existing sources, recipes and materials were unchanged. Nessa’s learned clue was reviewed. The two-mark plain Moderate Sun into Illumination page costs **14 Essence**, leaving 22 from 36; its other seven subjects remain unwritten. It promises neither growing habitat nor a traveller. The quote was first inspected without purchase, and its draft was not saved as a template. The same page was later recreated and used for the third trip below.

**Third trip — the Sun page was used:** the same 14-Essence page was bound normally, leaving 22. The party collected three raw Essence, then was defeated in an encounter with three grazers at world turn eight. The defeat kept two raw Essence and one feather, losing one of each. The existing spring added 3 Essence, and manual refinement of the retained raw Essence brought the actual balance to **29 spendable, no raw Essence left**. The original eleven healing-material units remained safely banked. No fourth search, foundation or Salve was purchased.

**Nessa still did not match, for a different reason:** this world had enough daylight, but every region was too saline for her fresh growing habitat. Sun addressed the earlier light shortage; it did not guarantee fresh water. Halloway was selected and placed, but the expedition ended before he was encountered. This was not a failed Nessa appearance roll and did not add another Nessa near-miss.

**Combat evidence has a limit:** Engineering separately reproduced and corrected a turn-order bug that could skip the next living actor after a defeated or recovering actor. Two regressions demonstrated the bug and eight focused checks passed after the fix. The exact state immediately before this expedition’s defeat was not retained, so the fix has not been shown to prevent that particular loss. The defeat remains the saved outcome and is not reliable evidence for changing ordinary enemy balance. No enemy stats, encounter odds or rewards were changed.

**Current position:** 29 Essence, all initial healing ingredients retained, three paid expeditions and no active world. A hypothetical 20-Essence foundation plus the currently quoted 10-Essence blank Bind totals 30, but Nessa has not been recruited and further search costs remain separate. The campaign can afford to depart; this does not prove the full healing route is affordable. No further paid search is authorized for this test yet.

**What the clue can currently teach the player:** look for daylight **and fresh water** supporting Resin and trees; bright land can still be too salty. The campaign knows Illumination and Substrate, with Sun as its only learned source. Water vocabulary remains unlearned. The existing Diary states the fresh-water requirement, and the Dictionary correctly withholds unidentified words. The current Hydrology lesson requires safely observable **liquid** water; the third world contained ice but no liquid-water tiles, so its exclusion from that lesson was consistent with the decided rule. Counting frozen water as a new learning opportunity has not been adopted. The learning sequence and how it guides this search remain design considerations, with no new reward or ownership change.

**Development fixes encountered on this route:** the same second departure exposed repeated teaching-route searches that stalled Bind preparation. Reusing those unchanged route results reduced that specific diagnostic from about 99 seconds to about 2 seconds; ten focused checks and the same native departure passed. A separate lookup correction made the existing early Substrate teaching collectable without silently reading it or granting extra knowledge; four focused checks and native pickup passed. These are development results, not phone delivery or a general performance claim. An older save refusal from an unrecorded seed remains unresolved; passing these trips does not establish its cause or fix.

**Remaining work:** complete natural recruitment, healing and Essence-runway checks, finish material and garment presentation, verify the visible source-to-finished-item colour journey and prepare delivery. The written Iron guarantee and its budget credit, the forge-to-Scythe harvesting chain, the Tannery’s Cord, Cloth, two woven garments and preserved source colours, and pack projects through 23 spaces plus Sela’s separate 2 are implemented and tested in development. Woven Gloves and Boots also pass native crafting, reopening and prepared-component recovery checks. Ordinary Salt now passes its own generated-source and native hand-gather/reopen checks; typed animal-covering rewards also pass their own focused and arranged native checks. Leather processing, the Guard and exact prepared-component recovery now pass their own native and focused checks too. Written Salt now passes its quoted Bind, seven-step walk, hand-gather and reopen checks, alongside focused rule and save checks. The focused placement and water-channel corrections are complete in development; genuine capacity reductions remain explicit. Keep the adopted intensity weights; the result does not call for another climate change. Drainage has not been adopted as the availability fix, and writing a fainter Sun did not improve the earlier results. **The overhaul remains disabled for new ordinary campaigns and is not delivered to your phone.**

### Mineral occurrence — decided intended behavior

After written sources and suitable early Iron and Coal opportunities, other mineral finds share the remaining space. Their first-pass occurrence groups are:

| Occurrence group | Materials |
| --- | --- |
| Common | Iron, Coal, Quartz |
| Uncommon | Copper, Silver, Obsidian, Sulfur |
| Rare | Gold, Mercury, Adamant, Rift-glass |

Each still needs compatible geology. These groups describe how often a suitable find is selected, not material quality, sale price or the tool needed to gather it. The starting group weights are 70 / 25 / 5; groups with no suitable material are skipped. This does not promise that every world contains each group.

Clay and Salt use their separate hand-gathered deposits. Rubble is held out of this new early mineral selection until its gathering and processing route is ready; existing worlds and owned stock are preserved. These rules are intended tuning. The full actual-map test and arranged journey are recorded above; placement exceptions, natural pacing and delivery remain pending.

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
