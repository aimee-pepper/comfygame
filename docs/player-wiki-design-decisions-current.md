# Design decisions · 4 September 2026

Updated 11 September 2026. This reference keeps the accepted decisions and subsequent deliveries together. **Decided intended behavior** describes the game we are making; it does not mean that behavior is already available on your phone. **First-pass tuning** gives concrete starting numbers that can change through play. **Unsettled proposals** still need design work or a choice.

## Terrain, mist and rain — installed; remaining atmosphere separate

**Current startup status — build376:** Build376 is installed and retains the startup correction from369. Successful phone launch, usable entry and a physical playthrough of376 have not been verified. The further reported opening crash remains unconfirmed and is not claimed fixed by this update. Build372 previously passed ordinary launch and over106 seconds of sustained operation with no new crash report. The earlier368 startup failure remains part of the record.

**Current behavior — installed in368:** Build368 adds the existing terrain textures to normal 3D ground and liquid surfaces, including grass, shallow water, deep water and solid ice. Their detail follows the world’s existing colours. Snow and settled ash keep their separate patches. Moving surface detail does not move the ground or change a turn. Remembered terrain keeps its last-observed appearance without live animation; older plain-looking memories keep that appearance until you see the place again.

**Current solid-side textures — installed in371:** All nine solid terrain families now have recolorable side textures in the normal campaign: stone, soil, sand, ash, rubble, mud, growth, groundcover and ice. Build371 completes the five families remaining after370. Existing face shapes, world colours, saved observations and movement routes stay intact.

**Build371 verification:** The nine side families and authored Clay passed internal review at ordinary campaign scale. Six focused checks covered normal integration, Clay, compatible launch and saved ownership. Phone installation and bounded sustained-process checks are verified. These do not establish every world palette, final physical-screen appearance or a gameplay walkthrough. Iron Ingot used its previous placeholder in371. Build372 adds the accepted Iron Ingot icon in Stockpiles. Build374 adds the accepted Softwood Haft, Hardwood Haft, Iron Collar and Bone Collar icons there. These category pictures do not sample or average the colours inside a stack; expanding it retains exact source colours and honest unknown labels. Build375 also uses those four pictures and Iron Ingot in the carried-items bar. Stockpiles expanded material text is clearer, while source colours, quality frames and grouping stay unchanged.

**Remaining appearance limits:** The existing solid-side artwork is delivered. A visible shallow-water bed can still have a support face whose material is unspecified; it keeps its plain appearance rather than becoming invented stone or soil. Hidden deep beds and chasms do not gain support. Smoke, airborne ash, miasma, falling snow and mixed rain/snow remain unfinished normal atmosphere effects. Existing settled snow/ash and isolated Settings studies keep their separate behavior.

**Decided water and chasm boundaries:** A bank beside water belongs to the land forming that bank and keeps its colours. Seeing water does not reveal an unknown bed or what it is made of. Deep-water beds remain hidden, and chasms do not gain floors or walls to fill an artwork gap. Older water retains its recorded appearance rather than gaining guessed measurements. Real waterfalls and shore steps keep their own shapes and rules; they are not ordinary support walls.

**Decided complete texture coverage:** Every existing terrain type should have texture detail that follows its world colours, including exposed sides where those sides exist. A textured top does not finish an otherwise plain side. Preserve suitable existing artwork, make missing recolorable detail, and keep stone, soil, vegetation, ice and water recognisable. This does not add cliffs, floors or terrain types where none exist. Ground textures arrived in368, and all nine existing solid side families are delivered by371. Unspecified wet-bed materials and the atmosphere families beyond mist and rain remain unfinished.

**Current mist and rain — installed in374:** Build374 brings mist and rain into normal expeditions when the world calls for them, including both together. Mist forms low banks that keep their contours as wind moves them past terrain and creatures, with the world’s authored mist colour where present. Rain falls even in still air, follows wind, and has four distinct coverage levels from trace to dense; it keeps its own blue-grey colour beside coloured mist. These effects preserve existing sight, saved worlds and gameplay rules. Internal normal-entry, colour, motion and restored-view checks passed, with bounded visual review of raised land, shallow water and combined weather. Phone installation is verified; successful phone launch and a physical playthrough remain unverified.

**Decided complete atmosphere:** Show the atmosphere the world actually has: smoke, airborne ash, mist or miasma, with rain or snow where the existing world conditions call for them. Moving air changes the drift of existing effects. Mist forms low-lying banks that keep their shapes as they drift past terrain and creatures; higher ground can rise above parts of them. Looking around or climbing during an expedition does not lift or reshuffle the banks. Heavier mist increases coverage, while wind controls drift. An authored mist colour sets its main tone, with shadows and highlights preserving the contours; without one, mist keeps its pale, cool appearance. Rain ranges from sparse traces through light and heavy rain to dense streaks; greater intensity increases coverage without speeding up the fall. It falls even in still air, while wind carries it in its direction. Rain keeps its blue-grey appearance when coloured mist is present. The exact coverage of these four rain levels is initial visual tuning. These visuals do not create new weather damage, slippery ground, puddles, freezing or accumulated snow. Unseen places stay hidden, remembered places show their last-observed state without live weather, and characters, useful objects, warnings and controls remain readable.

**Unsettled presentation choices:** Specific cloud layers, volumetric fog techniques, sun shafts and day/night lighting treatments remain proposals. Existing sky and cloud authoring references stay available; this work does not replace that creative direction or add a new decision checklist.

Existing worlds, resources, travel rules and earned stock stay intact. The delivered texture batch reuses existing artwork; no extra trial or new colour-generation system is added.

**Verified scope:** Build368 installed the texture update but crashed during startup; its earlier process-start result did not establish successful startup. Build369 now retains those textures with the bounded startup recovery described above. Internal checks covered the existing terrain families, remembered appearance and surface motion; supplied views were reviewed at normal campaign scale and in a separate six-terrain example. The At this place text is also lighter and more readable. These checks do not establish a physical-phone playthrough, every moving-camera or waterfall view, or final artistic acceptance.

## First departure preparation — corrected in366

**Current behavior — installed in366:** newly prepared ordinary worlds can try another layout before payment when the original layout cannot fit its required sources. Preparation keeps the same world identity, written properties, source colours and original required resources. It accepts the first valid layout; it does not choose a world for better rewards. If preparation cannot succeed, it refuses without spending or issuing a world. Existing saved worlds are not regenerated.

**Verified scope:** seven focused internal checks passed, including recovery of the first blank request that had previously refused preparation. Its required sources and safe introductory route were retained. Installation and ordinary app launch are verified; the ongoing natural acquisition journey is still incomplete, and no physical-phone playthrough is claimed. The original refusal remains part of the earlier test record.

**Decided behavior retained:** an alternate layout cannot qualify by dropping required resources or introductory lessons. Plant coverage and appearance reflect the plants actually placed. Reopening or continuing an existing world preserves that world.

## Tutorials toggle — installed in364

**Current behavior:** Settings now includes **Tutorials**, On by default. Turning it Off stops automatic tips, guided prompts and tutorial-only suggestions. Your choice stays saved across app restarts and campaigns. Warnings, real results, necessary choices and ordinary help remain available. Writing still explains whether to bind the first blank request, continue the introduction or read recovered lessons in the Library.

Settings → Field Notes remains readable. **Replay on its screen** requests one lesson, even while Tutorials is Off. It waits for its valid screen and situation without moving you there. Once shown and dismissed, it does not repeat or enable other tutorials. A newer request replaces the previous one; leaving the campaign or closing the app clears a waiting request. Replay does not reset completed lessons, read anything for you or grant a rune.

**Decided behavior retained:** turning Tutorials back On resumes relevant teaching at its next normal opportunity without a backlog of popups. The delivered setting and focused replay routes have passed internal checks; not every tutorial situation or the full re-enable sequence has been reviewed in play. No further design decision is needed.

**Got it — corrected in367:** acknowledging guidance now stops its automatic reminders for that campaign, including on later expeditions and after reopening. This does not count as performing the taught action. Manual replay still works once without resetting progress. A separate internal journey verified these steps and the transition between lessons. Installation and ordinary launch are verified; physical-phone visual acceptance remains separate.

**Decided behavior retained:** Got it remembers that you have acknowledged the guidance for this campaign and stops its automatic reminders. It does not count as performing the action being taught. Not now postpones guidance until a relevant later opportunity; Replay on its screen remains available when you want a reminder, without resetting progress.

## Current installed update —376

Build376 enables solid creature materials in newly written books: Fur Pelt, Overlapping Scales, Armoured Scales, Chitin, Chitin Plate, Shell, Protective Spines, Flight Feathers, Contour Feathers and useful Horn. Actual body parts determine what can be recovered. Existing books, creatures and earned stock keep their saved rules; Hide and Bone retain their existing recovery paths. The Forge now accepts2 Shell for a Shield face or1 useful Horn for a Pointed Blade or Cutting Blade grip. Pay the ordinary remaining components; starter alternatives and0 Essence crafting stay unchanged. Shell contributes Protection; Horn contributes support workmanship without extra Power. Refitting returns displaced current components once, retaining their exact source details. The discovery journey, carried-item artwork and Stockpiles readability from375, and mist/rain from374, remain included. Fifteen internal checks passed, including new-book activation, old-book preservation and a controlled Shell source → reward → Return → Forge → reopening journey. That route used existing screens and controlled encounters; it does not establish natural material frequency or complete tap navigation. Installation is verified, but successful phone launch and physical usability remain unverified. The ten material icons are interim and are being polished; final creature artwork is also unfinished.

### Earlier update —367

Build367 delivers durable Got it acknowledgement with corrected tutorial sequencing, and reuses existing material artwork in the carried-items bar. The Clay icon was checked in a separate internal scene; dedicated 3D Clay artwork followed in371. Build366’s pre-payment world preparation recovery remains included. The natural early-progression journey remains under review.

Build365 adds snow and settled-ash patches to normal3D terrain. The patches keep the ground visible, follow its existing height and preserve the colours and cover you last observed. Separate shore ramps and crossings keep their previous appearance. Existing worlds and gameplay rules are unchanged; the build364 improvements below remain included.

Build364 adds remembered non-enemy discoveries, consistent material totals with expandable exact variants, saved-reward gathering feedback, shared source placement and careful overlap repair. It also adds the blue Raw Essence droplet, the Tutorials switch, clearer opening guidance and square inventory quality frames. Terrain colours, fixed controls, supporting land faces and the earlier plant, Diary and waterfall corrections remain intact.

Installation and ordinary app launch are verified. The focused internal checks do not amount to a physical-phone playthrough or your final visual acceptance. Raw Essence was collected and stayed collected after reopening in an ordinary internal expedition; its appearance while remembered in fog has not yet been visually checked.

The intermittent **Securing action** hang remains unreproduced and has not been confirmed fixed. Long bare upper stems and weak needle/frond distinction remain appearance limitations. The waterfall's contact and sampled downward movement passed a bounded review; real-time smoothness, flicker and natural occurrence remain unverified. Older delivery notes below describe their own checkpoints; their earlier launch restrictions are not a current production blocker.

## Only notifications move — corrected in362

Only the notification pane switches edges as your character approaches. At this place, movement controls, minimap, Use Tile, Look, satchel and Field Kit stay fixed in their original bottom layout. Notification movement does not resize or reframe the map. Exact Diary page links and notice expiry remain intact. This corrects the unintended whole-navigation movement in359–361. Internal layout and input checks passed; no further decision is waiting on you.

## Raised land and shadows — installed in362

Raised terrain now has exposed supporting faces wherever the relevant heights are known. A visible bank can end at the known water surface without revealing an unknown riverbed. Unseen edges do not disclose hidden heights. Existing shore crossings, slopes and waterfall connections keep their rules; this does not regenerate your world or change movement.

Currently visible terrain, plants, mineral nodes and creatures can cast shadows alongside your character. Remembered or hidden objects do not cast live shadows. Supporting faces fade where necessary to keep the character readable. The bounded internal review passed; this is not final lighting or artwork acceptance.

## World terrain colours — installed in363

Terrain tops, water and exposed banks use the saved colours of their world. Looking away retains the terrain colours you actually observed, without revealing unseen changes. Older observations missing a saved colour keep their previous appearance until seen again. Flora and resource colours keep their own identities. Internal palette and memory checks and the supplied image review passed.

**Snow and settled ash — installed in365:** existing cover now appears in normal3D. Internal checks and a bounded still-image review passed for distinct patches, exposed ground, uncovered cliff faces and readable nearby objects and controls. Installation and ordinary app launch are verified; this is not a physical-phone playthrough or final aesthetic acceptance.

**Current cover:** saved snow and settled ash appear as separate patches on the terrain’s existing solid top, with colours belonging to that world. Both can be present while leaving the underlying ground visible. Cover stops at exposed edges; cliff faces keep the underlying ground material. It does not create deeper snow, new ledges, slippery ground, a harvestable node or a different route. Water and missing ground do not gain a cover surface.

Outside current sight, cover keeps only its last-observed pattern and colours. Older observations without that information wait until the ground is seen again. Existing worlds and resources remain intact. Separate shore ramps and crossings are not newly coated; their appearance and movement rules remain unchanged.

**Unsettled proposals, not implemented:** deeper snowdrifts, melting, weather-driven accumulation, and coating plants or whole cliff faces. None follows automatically from the delivered surface patches.

## Clay in the world — installed in371

**Current behavior:** Build371 replaces the generic marker for known Clay sources with a low grey-brown exposure of folded clay. It remains walkable and gathered by hand: one action yields two Clay. Gathering removes the depleted source, and its stock and depletion survive reopening. The carried Clay icon remains separate from the world model. Older remembered markers without a known Clay identity retain their earlier appearance until seen again.

**Behavior and verified scope:** Clay keeps its existing source quantities, routes and gathering cost. Discovered Clay shows only its last-observed state outside sight; it does not reveal hidden changes. Internal native gathering, depletion and reopening checks passed, and the supplied appearance was accepted. This does not establish a physical-phone playthrough or a finished pixel filter for the whole 3D scene.

This is team artwork and integration work; no new decision is waiting on you.

## Field and inventory corrections — installed in364

**Current gathering feedback:** supported collected materials rise briefly from their actual source after the reward is saved. The short local motion takes less than half a second and never delays your next action or spends another turn. A work hit without a reward shows no collected item. The effect follows your Mining and gathering results setting, which is Off by default. A result involving several kinds or sources keeps its normal breakdown without this extra motion. Materials awaiting suitable artwork may also keep their ordinary result display; your reward is unchanged.

**Current growth, minerals and loose finds:** a physical plant base, mineral node or loose find reserves its tile against separate physical sources, both during world creation and later placement. Leaves may overhang neighbouring tiles, ground cover may remain, and one plant may provide several materials. Adjacent mining stays valid.

Existing overlaps are repaired only when the whole affected group can be preserved, with its work, quantities and access intact. A discovered source moves only to a known suitable position, with a saved correction notice and updated remembered location. Its historical origin and already earned materials remain unchanged. Ambiguous old sources, conflicting remembered objects or missing safe destinations leave the affected overlap intact for correction rather than deleting or guessing at your possessions. This is not a claim that every old campaign overlap has been repaired.

**Current remembered discoveries:** observed plants, resource nodes, loose finds, travellers and places keep their last-known appearance and position outside sight. Enemy mobs disappear. Remembered objects reveal no hidden movement, harvest, depletion or danger. An observed pickup or removal updates the saved memory, so reopening does not restore the collected find. Remembered presence does not grant remote interaction or guarantee that an object is still there. Older saves keep only the details they actually recorded; missing details are filled in when seen again.

**Current material stacks:** the same real material, subtype and existing quality share one visible total. Tap to expand the exact colour, properties, composition and origin of its underlying pieces. Ordinary flora and processed plant textiles remain ungraded. Field holdings, Return, Storehouse and the supported shop displays use this grouping while preserving exact crafting choices, quantities and prices. Different qualities and different materials remain separate; stored and carried holdings are not combined.

**Current artwork and remaining work:** square quality frames preserve each icon's proportions. Nineteen reviewed replacement icons are included, and the four approved originals remain unchanged. Build372 adds the accepted Iron Ingot icon in Stockpiles. Build374 adds the accepted Softwood Haft, Hardwood Haft, Iron Collar and Bone Collar icons there. These category pictures do not sample or average the colours inside a stack; expanding it retains exact source colours and honest unknown labels. Build375 also uses those four pictures and Iron Ingot in the carried-items bar. Stockpiles expanded material text is clearer, while source colours, quality frames and grouping stay unchanged. Broader final visual acceptance remains separate from the delivered grouping rules.

**Current Raw Essence:** loose Raw Essence uses a grounded blue droplet in normal3D. Collecting it adds the actual quantity and removes the find; reopening preserves that collection. It is distinct from an Essence Crystal and a Mote. Its remembered-fog appearance still needs a visual check.

**Decided behavior retained:** exact material colours and source details stay available for crafting without creating colour-only duplicate stacks. A collapsed stack icon identifies its material category; it does not sample or average the colours of the pieces inside. Expand the stack for exact source colours. When crafting equipment, each component keeps the colour of its selected material. Source repair must never erase earned stock, invent provenance or reveal an unseen object. Remaining artwork and visual checks do not change those rules.

## Waterfall ledge contact and motion — installed in361

When an admitted waterfall overlaps its own shore step, the falling sheet now sits just beyond the receiving side of that ledge, with a narrow connection to the upper water. Its actual drop, width, landing height and crossing rules stay the same. Brighter streaks move down the falling sheet; nearby pools and shore surfaces remain still. Terrain can naturally obscure a fall viewed from behind, and hidden endpoints do not reveal a waterfall.

Internal geometry and disclosure checks passed. Asset reviewed sequential frames from the corrected example and accepted its contact, exposed falling face and sampled downward progression, with no obvious detachment or spill. This resolves the reviewed overlap defect. It does not establish real-time smoothness or flicker quality, natural waterfall occurrence, appearance at physical-phone size, universal naturalistic readability or your visual acceptance. No new test or preference is added.

## Normal expeditions in3D — installed in357

**Current:** Bind, Enter and Continue use the3D exploration view in the same campaign, without a new mode choice or separate progression path. Home, crafting, combat and Return keep their current screens. Tile selection, movement, Look and Use Tile retain their ordinary rules.

Newly written ordinary worlds use the normal3D resource rules, including suitable mineral deposits previously omitted for2D recordings. Existing books and active expeditions keep their actual terrain, resources, progress and saved appearances; switching the view does not regenerate them. Settings trials retain their separate saves.

Internal checks passed binding, entering, movement and controls, reopening through Continue, and returning Home. Installation on your phone is verified; these checks do not establish physical-phone play acceptance or finished artwork. Build360 subsequently delivers the bounded stem/cap correction; selective iridescence and further plant refinement remain unfinished.

## 3D authoring direction

**Decided intended production:** beautiful conventional Blender-authored3D parts will be assembled and varied in game. Their geometry should not be made of modeled pixels or deliberately crude blocks. A later pixel-art treatment belongs to the rendered game image and remains unfinished; inventory pixel-art icons are a separate kind of artwork. Essence is blue. The earlier purple crystal candidate is withdrawn; its blue replacement still awaits in-game integration and review. The six resource-node replacements are delivered in build348’s existing3D view; their earlier code-authored meshes are historical interim artwork. Stable assets such as Coal do not need placeholder authoring; an exception needs a concrete unsettled-design reason. The procedural flora and creature direction remains intact. Quality, coherence and playability govern this work.

**Reusable flora artwork — retained in installed355:** newly bound books use reviewed Blender trunks, branches, broad leaves, fibrous blades, needles and fronds in the existing3D view. Parts retain each plant’s source colour and saved structure. Existing books keep their recorded artwork. Build357 now uses the3D view for normal expeditions as well. These replacements add no new species type, organ or harvest. Earlier versions left some fibrous stems too dominant and some fleshy foliage buried; the revision below addresses those shapes. Your final review of the overall plant appearance remains open.

## Clearer plant silhouettes — installed in355

**Current in newly bound books, installed in355:** leaf-bearing, unbranched fibrous plants have slimmer stems and show more of their existing leaf length. Upright plants keep their height; basal rosettes get a shorter central support so the low leaf cluster defines their shape. Fleshy branches start at the body’s actual outside and carry their existing foliage beyond it. Previously buried unbranched fleshy growth also attaches at the surface.

Already-readable branched woody and fibrous plants, bare forms and corrected unbranched fleshy rosettes keep their current shapes. This changes how existing parts are arranged and proportioned, while preserving anatomy, leaf/branch counts, materials, rewards and older books.

**Tradeoff:** basal rosettes look shorter, and fleshy branch fans occupy more visible space around their unchanged central body. Some rear foliage can still be hidden. You approved this revision and asked to see matched before/after examples of the same plants. The completed comparisons show clearer upright leaves, compact basal clusters and fleshy branch fans emerging outside the body. Internal checks also preserved source counts, materials and older saved plants. Your final visual acceptance remains pending. Build355 is installed on your phone. Existing books keep their saved plant shapes. Ordinary phone entry has not been checked.

## Fungal caps and contact — installed in360

Newly written worlds use authored fungal caps in place of the earlier rounded placeholder shape. Existing cap sizes and repeated groups remain intact. An existing spore-bearing feature now sits against the actual cap surface instead of floating above it. This adds no parts or changes to source colours, harvests or material values. Existing books keep their saved appearances.

Asset's matched review passed for this cap replacement. The small attachment is not separately legible in the images; its contact is established by Engineering's geometry checks, not by visual inference. Repeated caps can still look stacked; this is not final whole-plant realism.

## Tapered plant supports — installed in360

Newly written worlds keep355's foliage improvements while replacing ordinary fleshy egg-shaped supports with straight, gently tapered stems. Upright forms keep their height; unbranched basal rosettes use a short central support and read as compact radial clusters. Branches, leaves and thorns attach to the actual stem surface. Anatomy, counts, source colours, harvests, material values and older saved shapes stay intact.

Internal contact, source-count and saved-world checks passed. Asset reviewed all16 matched before/after images and accepted the bounded stem and cap replacement. Upright needle and frond forms still have long bare upper stems and can be difficult to distinguish at ordinary scale. This does not establish final plant believability or your visual acceptance.

Swollen cactus or succulent forms still require actual supporting anatomy. Fleshy tissue, thorns or needle-shaped growth alone do not establish a cactus, and current plant records have no separate swollen storage stem.

## Plant crowns and leaf arrangement — installed in372

Newly written worlds now give leafy upright and branched fleshy plants shorter, more tapered supports and distribute their existing foliage farther up the plant. Leaves attach to their actual stems and branches, while opposite, alternating and grouped arrangements keep their identities. Fronds show their broad faces in a consistent plant-relative orientation; needles remain narrow. No leaves or branches are added to fill gaps.

Compact basal rosettes and other plant families retain their previous forms. Existing books keep their saved plants; colours, materials, counts and harvests are unchanged. Internal comparisons support improved placement and silhouettes, though fine needles and some supporting shapes remain difficult to read. Normal world entry, movement and reopening passed internal checks; that expedition contained fungi, so it does not establish a natural encounter with the changed fleshy plants. Further artwork and your visual acceptance remain separate.

**Unsettled future possibilities:** additional branch orders, multiple stems, storage organs, separately variable leaflet or needle-cluster counts, and more detailed flowers would need their own source structures. They are not added by this refinement, and they do not block it.

## Generated 3D life and connected waterfalls

**Decided intended behavior:** plants and creatures are generated in game when you write a world. The game may combine reusable body bases, plant parts and attachments, but choosing a finished premade species is not the generation system. World conditions shape the available life; its actual traits determine structure, proportions, colour and Pattern. A saved world keeps its identities and appearance when reopened. Harvested flora and creature materials keep their actual source colours through supported crafting uses.

**Current behavior — installed in build333:** newly written ordinary worlds now generate modular plants and creatures and use the measured-water rules. Build357 subsequently brings their3D presentation into normal expeditions; the Settings trials remain separate. Existing books, saved worlds and unfinished opening expeditions retain their frozen generation; reopening them does not reroll their life or terrain. Artwork remains partial.

**What has been verified:** an internal native ordinary expedition contained four creature kinds and two flora kinds. Movement, a creature encounter, Withdraw, Continue and reopening that same expedition passed. The short route reached no usable harvest. All four water areas kept their earlier presentation because the new geometry could not be admitted; **no naturally generated waterfall was witnessed**. A separate controlled native example verified a connected one-level waterfall and legal shore slopes/steps. Build333 launched normally at its delivery, but Aimee's expedition was not played and phone performance was not established. See the latest installation status above for the current build.

**Appearance — current in installed build336:** stripes have softer transitions, and new woody assemblies use tapered supports and gently bowed, tapered branches. Opposite or alternating broad leaves have varied tilt. Build336 gives newly generated broad-leaved woody plants a fuller crown above a shorter bare support by adjusting support, branch-base and leaf proportions. Leaf counts, source traits, materials and the accepted profiles stay unchanged; old saved assemblies keep their shapes.

These refinements have internal native specimen evidence. The earlier ordinary movement/encounter/reopen check contained fleshy flora, so no natural woody encounter, Aimee expedition or phone-performance result is claimed. Foliage still looks clustered; finished organic richness and full finish treatment remain incomplete, and dense stripe patterns can still lose contrast. The height-route rules below are separately installed in338; launch was unverified at that checkpoint; later344/345 delivery includes ordinary launch, with feature play acceptance still separate.

**Creature design requirement:** all intended forms must have coherent structure rules before dependent generation is built. The existing seven body labels have23 habitat/body combinations, but that is only the starting classification. Dragon DNA’s independently varied wings and limbs, horn style/direction, spine style/height and tail shape/length are the model for the deeper modular design. The reference has now been read, and the draft replaces the restrictive single-appendage choice with independent part groups. An axial creature with three or five to eight support limbs is grouped as **Many-legged** when legitimately recorded; two and four retain their own groups. Independent structures and their source rules are enabled for newly written worlds in333; existing saved classifications remain preserved.

**The same principle applies to flora:** woody, fibrous, fleshy, fungal and chemosynthetic structures combine independently appropriate support, branching, leaves or other growth shapes, surface features and reproductive/display structures, plus colour, Pattern and finish. Fungi do not acquire ordinary leaves, and chemical growth does not become a flowering tree. Different actual wood and foliage colours stay distinct and harvested flora keeps its source colours through supported crafting. Visible blossoms, fruiting shapes or spines do not by themselves add a new harvest reward. A world’s flora kinds stay stable across their patches; there is no fresh biological reroll per tile.

**First-pass proposed tuning:** exact dimensions, part proportions, presence weights and shape variants remain revisable production choices. Trunk-bodied land and sky creatures can start from either a two-limb or four-limb preference, then vary with world conditions; land creatures initially favour four. This makes two-legged animals an actual generation possibility. Fins are selected independently in Water and Amphibious habitats, with suitable world conditions affecting their chance of appearing; they are not compulsory for every swimmer. These structural drafts now cover the relevant systems from the [Dragon DNA reference](https://github.com/aimee-pepper/dragon_game), with Bookbinder’s world conditions and compatibility rules shaping the results. Breeding and inheritance gameplay are not added. The functional generators and connected-water rules are delivered in333. Remaining work includes organic shape refinement and complete opacity/Schiller treatment. Build361 delivers the bounded waterfall contact/motion correction described above; the current models do not establish the intended finished richness. Ordinary harvesting with these new forms and a naturally generated waterfall remain unverified on the bounded native route. Tree sources link to suitable flora from that same world; when no suitable kind exists, the existing tree and its obtainable wood remain available rather than inventing a plant or removing the resource. Creature descriptions must agree with actual anatomy: wings alone do not make a ground-dwelling creature a flier, and attack strength alone does not establish fangs or tusks.

**Your clarified ambition:** substantial creature and flora richness, at least halfway towards Spore in spirit, while staying well below full Spore complexity. This is a qualitative direction, not a percentage target or a promise of Spore's creature editor, breeding or simulation systems.

**Research-informed direction — first shape refinements in334, wider work pending:** make reusable parts expressive through curvature, taper and coordinated proportions; make plants follow a clear overall silhouette with gradual variation along their stems. These recommendations draw on the original [Spore Rigblocks paper](https://www.cs.cmu.edu/~ajw/s2007/0248-Rigblocks.pdf) and [plant-form research](https://algorithmicbotany.org/papers/positional.sig2001.html). For example, a six-legged animal's support limbs should read separately from its wings, and a woody plant's branches and foliage should form a coherent crown. The approved independent groups remain the foundation. Exact shape refinements remain production choices, and working primitive models alone do not establish the intended finished richness.

**Waterfalls need a real connection:** an elevated pool or channel must have an open outlet leading down into actual receiving water. Both local water levels, the connecting edge and the exposed drop must be generated and saved. Separate pools keep their own levels; overlap on screen, a lower pool behind a ridge, frozen water or a blocked outlet does not create a waterfall. The shared shore rule is now specified: slopes and short steps must preserve every existing walkable crossing and its movement cost. A shallow crossing can sit beside a real drop when its supporting ground remains traversable; deep water keeps its existing restriction. If new water geometry cannot preserve those crossings, that connected body of water keeps its current presentation. This replaces the earlier deep-water-only starting proposal. These rules are implemented for newly written worlds in333, with numerical depths and step dimensions still revisable first-pass tuning. Build361 adds the bounded waterfall contact/motion correction; natural occurrence and finished appearance beyond the sampled review remain unverified. Old worlds do not acquire guessed measurements.

The existing3D trial remains the consumer; this adds no menu, swimming, erosion, flooding simulation or new material rewards. Large artwork does not enlarge a creature’s occupied space or a tree’s blocking base. Hidden actors and unseen water endpoints stay hidden, and remembered scenery does not reveal current movement or changes. Later shops and Essence recovery remain outside this work. No new decision homework is required from you.

## Pressure-led families — installed in351, phone entry unverified

You approved a lightweight family → species → individual hierarchy for both creatures and flora. World conditions and actual habitat support should influence which families are likely, while leaving several compatible solutions and plenty of independent variation. This develops the existing generator; it does not add all eight ranks of biological taxonomy or an ancestry/breeding simulation.

**Current foundation:** creatures already choose among six body layouts according to habitat, with independent limbs, wings, fins and other parts. Flora already uses five construction families linked to metabolism and tissue. World pressures influence their source traits. The new family-selection and repetition rules below are implemented, internally checked and installed in351 for newly bound books. Existing books keep their earlier family-selection rules. Ordinary phone entry and playtest readiness remain unverified; installation alone does not establish them.

**Current behavior for newly bound books:** broad families provide consistent structural rules, species retain their own generated anatomy and traits, and individuals keep their supported saved variation. A wet world may support multiple kinds of swimmers, shore creatures and nearby land life rather than funneling everything into one fish family. Plants use equivalent relevant structure: supported metabolism, body tissue, branches, leaves or other growth, and actual display parts. Independent counts, dimensions, colours and Pattern remain; family labels do not manufacture harvests, food, organs, abilities or Apex status.

**Design first-pass tuning:** favour compatible body families using the creature's already-resolved traits, and gently reduce the chance of repeatedly selecting the same family. For flora, choose among pressure-supported families before allocating its existing tissue budget, then ensure those tissues actually match the selected family. Keep multiple choices possible wherever supported; do not force every world to contain every family or add creatures just to fill a category. Family selection does not add to the existing trait budget. The three photosynthetic plant families share their existing metabolism chance, so adding categories does not make photosynthesis three times as likely. A family can recur in different habitats and worlds with different species. The system reuses existing construction rules rather than requiring a finished model for every species.

**Intended benefits:** coherent variety, recognizable differences between worlds and the amount of content supported by each added structure. It is not a promise of more simultaneous creatures, faster rendering or a larger map. First-pass weights passed their bounded implementation checks; broader diversity and balance still need evidence from actual play.

**Preserved:** the Bestiary stays Sky, Water, Amphibious and Land with its existing body groups. These remain browsing categories, not ancestry claims. Family membership never reveals an unseen species or guarantees a material. Existing worlds, specimens, learned records and owned source colours remain unchanged; newly bound books in351 use the new choices without updating older books. Current morphology corrections can finish independently. This accepted direction adds no decision homework.

**Internal verification:** the new rules preserve supported habitats, spend each species’ existing trait budget once, and keep older books on their saved generation rules. A retained expedition passed Binding, entry, one movement and reopening with unchanged saved creatures, plants and material records. No harvest or visual review of its hidden species was claimed. This does not establish richer-looking plants, statistical variety or phone playtest readiness; the fibrous foliage readability issue remains open.

## Morphology v2 — installed in339

**Decided direction:** make generated life read as coherent, distinctive forms rather than collections of simple parts. Build339 enables the consolidated six creature layouts and five flora families for new early-game books, retaining the Bind fix and terrain rules. It preserves actual anatomy, source colours, material rewards, occupied tiles and existing saved appearances.

**Installed first-pass construction:** these are Design-authored starting choices, not final artistic acceptance. Exact proportions remain revisable. Existing books and frozen appearances are not upgraded on reopening.

| Existing form | Installed shape construction |
| --- | --- |
| Two-legged axial creature | A more upright, compact torso with its head and supporting limbs placed to match |
| Four-legged and many-legged axial creature | A horizontal body with clearly spaced supporting limbs; limb count remains distinct from wings and fins |
| Serpentine | Connected, gradually tapered sections following its saved curve |
| Segmented | Visible sections and narrower connecting waists |
| Radial | A regular arrangement around a central body |
| Amorphous | Unequal, overlapping masses that stay connected and visibly differ from radial forms |
| Fish-shaped | A broader front tapering towards the rear, with only its actual fins, tail and shore-supporting limbs |
| Woody flora | Retain delivered taper and crown improvements, then distribute branches and leaves along their actual supports |
| Fibrous flora | Tapered stalks with blades, leaves or fronds arranged along the support |
| Fleshy flora | Pads or rosettes attached to the actual body surface |
| Fungal flora | Caps, shelves or tufts arranged on their own nonwoody supports |
| Chemosynthetic flora | Low crusts and plates, or distinct tube growth, instead of treating every form like a tree |

Independent wings, fins, horns, spines and tails keep their saved presence and counts while gaining clearer shapes. Feathered wings gain overlapping contour shapes; fins and tails taper; horn styles remain distinct. More visual pieces do not mean more harvestable anatomy. In this batch, a creature with both a ridge or sail and a protective spiny covering shows both features. If both traits call for the same row of spikes, one row represents them together rather than doubling it. This preserves its generated traits without adding weapons or material rewards. Leaf sizes vary in small coordinated groups, with opposite pairs kept together and roots attached to real support.

**Attachment correction — included in339, focused internal review passed:** the retained examples now close the reported detached limb and dorsal-spike gaps. Radial and amorphous heads also show a visible join after the head-only adjustment, preserving head size, orientation and attached features without adding a neck. Supporting limbs retain their planted feet. This closes the specific reviewed contact defects. Separate Engineering checks now cover two-legged height and grounding; final two-legged artwork and finished procedural richness remain unaccepted. Some join polish and pattern seams remain incomplete.

**Flora review — included in339, focused internal checks passed:** the retained woody, fibrous, fungal and chemosynthetic examples show the planned support and growth arrangements. The fleshy rosette's direction correction now also passes: leaves extend outward from their existing roots and the display stays attached. Only that example was rechecked; the other four comparisons remain valid. These are bounded findings for five retained examples; phone installation is a separate delivery fact and does not prove every family has been naturally encountered. Dense overlaps, edge-on leaves and unfinished styling still limit the appearance; complete flora richness remains unproved.

Existing size, build, tissue, stature, shape and part fields supply the variation. World conditions influence those source traits first; appearance does not secretly reroll biology or add another cold, darkness or water bonus. No new breeding, creature editor, gait system or plant lifecycle is part of this batch. The batch is implemented and installed in339, with the bounded internal evidence described here. Build352 adds shared markings for newly bound books; complete Schiller and final artistic richness remain unfinished.

**Delivery and usable entry:** build339 installation and device readback are verified. Ordinary phone launch was not attempted, and a usable physical-phone entry remains unverified; this is not a claim of phone playtest readiness. Internal checks passed new-book appearance selection, older recipe preservation, source traits, part contacts and flora orientation. One retained ordinary3D campaign passed Bind, movement, Return and reopening with four creature kinds and two flora kinds; it reached no usable harvest and does not establish a natural creature encounter or full appearance coverage.

**Aquatic admission correction — included in339:** a deep-water creature in a habitat with valid shallow-water contact no longer causes world preparation to fail merely because its starting tile is not player-walkable. Allowed remote-only aquatic habitats still do not require a contact route. No creature or source is relocated. This preserves dark-water starts beyond your reach and existing awareness, movement and sight rules.

Pressure-led family generation is installed351 for newly bound books, with phone entry still unverified. Build352 adds the bounded colour, shine and continuous-marking improvements below; full Schiller remains unfinished, while the shared3D cues described below are installed353. Existing campaigns and owned source colours are preserved.

## Surface finishes and markings — installed in352, Schiller unfinished

**Decided intended scope:** iridescence can have a place on suitable plants and animals. Dragon DNA is inspiration for useful detail, rather than a blueprint to copy wholesale. Some feathered or scaled animals are the first specified examples; suitable plant surfaces may also use the finish. This is selective: it does not make every species or surface iridescent. The first plant specification allows selective iridescence on actual leaves, blossoms and fruiting displays of woody, fibrous and fleshy plants. Stems, wood, thorns, rough regions, fungal forms and chemical forms keep their ordinary finish in this first pass. Repeated leaves or blossom pieces share their source group’s finish; extra pieces do not create extra chances. The visible effect remains unfinished. Existing source colours and material calculations stay intact; Schiller is not being turned into an organ count.

**Current for newly bound books:** the existing3D view preserves each creature’s or plant’s actual colours and finish, including distinct body regions, wood, foliage and supported individual differences. Surfaces stay opaque; shine affects the highlight while rough surfaces retain their softer appearance. Markings share a direction and scale through connected parts of the same region, and fine bands soften at a distance. Distinct regions can keep separate patterns. Colours used in harvesting and crafting remain tied to the actual source.

**First-pass tuning:** each eligible plant foliage or display group has a 25% selection chance. This is adjustable design tuning, not a promise about how many plants in each world will shimmer. Strength follows the source’s existing finish and can be very subtle or absent at zero. No organs, harvests, material values or stack divisions are added.

**Current crafting connection:** stored Schiller contributes to material Lustre and some material capability calculations. The missing angle-dependent visual effect does not make that stored value unused. Replacing it with a plant count would therefore require a separate crafting decision.

**Plant structure remains independent:** branching, leaf repetition and arrangement keep their own variation. True multiple stems or flower heads are separate missing capabilities, not a settled replacement trait. Visible parts do not automatically yield extra harvest units.

**Older books:** existing books retain their earlier appearance, including the older markings that can restart at part joins. Reopening a saved world does not apply the new finish automatically. Future Schiller improvements must likewise preserve already-saved appearances.

**Decided intended appearance, not yet delivered:** selective iridescence adds a subtle, angle-dependent reflected colour relative to the source colour, with neutral sheen on neutral-coloured sources. That visible effect is not implemented yet. Painted rainbow colours, emitted light or a metallic replacement do not count as Schiller. Markings and shine improvements do not establish the complete finished appearance or resolve the fibrous plants’ proportions.

**Verification limits:** close and ordinary-scale views showed readable leaf bands that soften with distance while preserving the tree outline. Checks also covered connected creature markings, saved source colours and reopening. A later short, controlled camera-movement check found no obvious pattern jumps or large brightness pulses in the sampled views. This does not establish flicker-free behavior at every speed or distance, or your visual acceptance. These improvements remain included in installed build354, but ordinary phone entry and playtest readiness remain unverified following the earlier locked-phone launch refusal.

## Reading plants, creatures and targets in 3D — installed in353, phone entry unverified

**Current in the existing3D view:** a harmful plant has one static warning at its base while fully in sight. Visible creatures now show their actual Apex and alert status, and the selected resource shows its action and readiness at its own base. These cues follow the same visibility and action rules as the rest of the game.

**Reading the cues:** the 3D view makes the existing distinctions clear. A harmful patch gets one generic **Dangerous growth** cue from first full sight; it needs no prior injury or learning. An actually visible Apex gets its own Apex distinction. Size, stillness, colours, thorns or impressive artwork do not create either status. A distant warning keeps its existing limited meaning and does not reveal a creature's body or materials.

Use the existing tile action or selected directional tool command to choose a source; the highlight belongs to its actual base. With a suitable packed Axe and a legal working position, a tree's base highlight and **Chop tree** identify the action. Other sources keep their own tools, reach and action rules. A visible source may still require a different tool or approach; its selected explanation should say why. Success feedback follows the actual saved action, never a cancelled attempt. Its optional work-impact cue follows your Mining and gathering results setting. Muting it still leaves the actual harvested or depleted source visible, along with targeting, danger and required explanations. Source colours remain intact beneath separate warnings and selection marks.

**Memory and fading — extended in364:** remembered plants, non-enemy finds and places keep their last-observed appearance; remembered trees can fade when covering you. They do not disclose current hidden harvests, danger or changed shadows. Enemy mobs disappear outside sight; a remembered traveller marks only its last-known position. Fading restores the view of your character using only information already allowed by sight; it does not reveal a hidden target.

**Installed in353; verification limits:** the selected source now has its action text and a small base outline when ready; visible creatures can show their actual Apex and alert status. Success cues follow saved work and your notice settings. Resource gathering saves before showing success; a failed save leaves the prior resource state and holdings intact. Several nearby sources do not cause an arbitrary target to be chosen. The existing view admits creature labels only at full sight. The reviewed examples passed their visual checks, while every possible overlap and the final cleared-source symbol have not been visually checked. Existing danger and tree-fading rules are retained. This introduces no new test menu, knowledge requirement or decision homework. Installation is verified; ordinary phone entry and readiness for your playtest remain unverified following the earlier locked-phone launch refusal.

## Height routes and inaccessible scenery — installed in338

**Installed implementation — newly bound worlds:** you can move between neighbouring tiles only when their supporting ground differs by at most one elevation level. This applies going down as well as up: there is no jump or drop shortcut. To reach a higher area, find a connected route of steps each no larger than one level. Existing terrain height steps define the level; water depth or artwork size does not redefine it. Deep water still requires its existing restrictions, and flowing water does not create a walking route.

Most high ground should have a valid route from the expedition's actual entrance. Steep cliffs may remain along its sides while a gentler approach leads around them. A few isolated elevated areas may remain scenery. They may show trees, foliage and water, but contain **no animals or resource nodes**. Decorative trees and plants there cannot be harvested and do not count towards promised resources. Real sources remain obtainable from valid work positions with the appropriate existing tools; a tree above a two-level cliff cannot be chopped from below.

Some aquatic creatures can begin beyond player reach and approach shallow water only after noticing the player; a distant spawn is not an invalid habitat merely because it cannot be contacted immediately. A lake beside a reachable high shore may still support aquatic creatures, even where the party cannot enter deep water. An isolated high lake with no accessible shore has no animals. A waterfall linking it to lower accessible water does not change that. Animals cannot wander onto excluded scenery later, and vegetation there cannot silently become a source of Logs or medicine.

**Implemented first-pass tuning:** require at least90% of elevated dry terrain to be reachable. Allow at most one isolated scenic district per map, with a25% initial selection chance and no more than10% of elevated dry area; no isolated district is required. These numbers are starting production choices, not values supplied by you. Required paths and resources take priority.

**Delivery and evidence:** build338 is installed on your iPhone, but ordinary phone launch remains unverified because the device was locked. This is an installed implementation with internal native evidence, not a claim of phone playtest readiness. Internal checks passed cliff refusal without spending a turn, a stepped ascent, new-world binding and reopening, water preservation and resource-route constraints. One ordinary3D expedition also passed movement, encounter and reopening; it had no isolated scenic district and reached no harvest. That example does not establish natural scenery frequency or complete balance.

**Preserved behavior:** existing saved worlds and unfinished opening expeditions keep their earlier routes, creatures and resources. New water geometry respects the height limits even when it falls back to simpler water presentation. Ordinary gameplay remains2D, with the existing Settings3D view available. The337 Bind correction is retained. This adds no swimming, climbing or new trial menu. The later morphology, finish/marking and shared readability batches remain intended, not included in338.

## Recording, notifications and finding lessons

**Diary notification — installed in358:** collecting a diary page says **Diary page collected**, with **Read now** available before the notice fades. It opens that exact page; closing returns to the same expedition without spending another turn. The open reader stays available even after the notice expires. If you ignore the notice, the page remains in your Library. Collection keeps its learning and reward timing; opening the prose never grants them twice. Internal pickup, exact-page, expiry and return checks passed, and phone installation is verified. This is not a physical-phone play acceptance claim.

**Earlier recording restriction — retained in existing books:** build344 omitted unfinished box deposits for **Iron, Coal, Quartz, Sulfur, Mercury and Rift Glass**, including equivalent unfinished deposit sources. Trees, Clay, Salt Crust, plant/root gathers and ordinary rubble remain. Existing saved worlds and earned stock stay unchanged. A world's contents do not appear or disappear when its view changes; worlds created through the3D route keep their normal resource sources. Installation and ordinary phone launch are verified, with new-world movement and reopening checked internally. No physical-phone recording journey is claimed.

**Existing restricted books — new books use normal3D resources from357:** these missing deposits may block Iron-learning, Forge, Ingots, metal tools and affected specialist crafts. That earlier restriction supported recording the pre3D appearance, with no substitute materials or alternate progression route. At that checkpoint, ordinary worlds could still generate and explicit Iron writing explained its unavailability before spending. Salt writing and retained gathers keep their rules. Build357 ends this restriction for newly written ordinary worlds; suitable deposits follow normal generation rules rather than being guaranteed everywhere. Existing books retain their saved contents. Further2D node artwork and the interim Iron-picture substitution remain superseded.

**Encounter crash — fixed on your phone in343, retained in344:** you confirmed the further correction resolves the encounter crash reported on342. Your campaign was preserved.

**Current mining prompts — shortened in344:** if you own a suitable tool but have not selected it, the cue names it, such as **“Select your Stone Pick.”** If you lack a strong enough Pick, it states the minimum, such as **“Requires Pick Lv 2+.”** Other blocked actions give their actual obstacle; hidden deposits reveal no tool or material requirements. Mining rules stay the same. Shared event messages retain the wrapping support delivered in342.

**Notification wording — current in347:** field events, Schematic notices, auto-path warnings, actions, shop feedback, refusals and combat messages now use the consolidated shorter wording. Required targets, quantities, durations and choices remain visible; healing messages report the health actually restored, including when healing is capped. A failure without a known specific cause uses a brief unavailable message rather than an invented requirement. Survey keeps concise name-and-value readings when Measured is locked, and crumbling reports uncollected finds. Full underlying events and prose remain preserved. Engineering reports installation and ordinary launch; your visual acceptance of individual surfaces remains separate.

**Story chronology — current correction in344:** the cataclysm happened roughly a month ago at the beginning of the story. Halloway now says she has kept the fire **“Since everything broke.”** Her former nine-years reply was inconsistent. Earlier careers, old objects and pre-cataclysm history can still span years: Isolde's forty years of teaching remain valid. This establishes story context, not an exact day counter or a new time-travel rule.

**Unread Findings — current in345:** the Library has a distinct **Unread Findings** section with a count of recovered unread lessons, including any that still need another lesson first. Return’s **Read findings** shortcut opens it directly. Opening an eligible lesson teaches it free, and it leaves the unread list only after learning is saved. Its detail stays open with **Learned**; Back returns to the remaining list. When none remain, the section says **No unread findings.** Learned records stay in Field Notes and learned words in the Dictionary; unread lessons are not duplicated in Field Notes. This section covers recovered lessons, rather than every unread Bestiary or history entry.

**Current lesson route:** use **Library → Unread Findings**, or **Read findings** on Return. In connected-opening campaigns, Wildfire requires any one of **Hydrology, Thermal or Vitality**. Older campaigns retain their existing eligibility; the reported older campaign can read Wildfire immediately. Reading still happens on opening the lesson, with no extra Read button, Essence cost or world turn. Build345 preserves these rules and the learned result after reopening.

**Material stacks — current Hide correction in345:** the same material subtype and source quality share one visible Hide total in Return and Storehouse. For example, eight and two Common Supple Hide appear as **Common Supple Hide ×10**, even with different measurements or colours. Tap the stack to see exact variants and their quantities, swatches and rounded useful properties. Exact underlying pieces and values stay stored for crafting; display grouping does not blend them into a new material. Player details no longer expose source IDs, raw colour numbers or unfinished-rendering messages. The same subtype/quality grouping remains the intended rule for other quality-bearing materials; ordinary flora remains ungraded.

**Material inventory artwork — prepared, not yet delivered:** replacement icons must match the pixel-art style already used in game. A revised set now has broader pixel shapes and usable transparent images. Integration, readability at inventory size and final style acceptance remain pending. Preparing icons does not resolve the separately reported stacking issue; the grouping rules above remain unchanged.

**3D deposits — current in348:** Coal, Iron, Quartz, Sulfur, Mercury and Rift Glass now use their Blender-authored artwork in the existing Settings3D view. Engineering reports physical-phone installation and ordinary launch; your visual acceptance remains separate. The earlier code-authored meshes are historical interim artwork. Their recognizable direction is retained: Mercury as a solid mineral-bearing host with silver exposed faces, Sulfur as a low yellow crust, and Rift Glass as broad opaque shards. This artwork changes no mining reward or liquid interaction. Build357 subsequently brings it into normal3D expeditions and removes the temporary mineral restriction for newly written books; existing book contents stay intact.

## The beginning as one connected path

**Bind navigation fix — retained in installed341:** build339 could crash when opening the Writing Desk’s **Bind** review in a campaign carrying gear; the earlier337 fix did not cover that case. The focused correction is now installed, device readback is verified and ordinary phone launch succeeded. Internal checks using a separate copy of the affected campaign passed opening the review and reopening the save without changing inventory or departing. Physical-phone **Bind** interaction remains unconfirmed; ordinary app launch does not establish that this navigation is fixed on the phone.

**Departure save correction — installed in341:** the separate **Bind & Depart** refusal is corrected and verified using the exact retained campaign that failed. Internal checks passed departure, world entry and reopening after a restart, with no alternate seed or reset. Build341 installation, device readback and ordinary phone launch are verified. Physical campaign navigation remains unconfirmed; the internal pass is not a phone playthrough. This corrects a save-consistency fault without changing gameplay costs or harmful-flora rules. The family-generation policy, surface finishes and shared readability remain upcoming.


**Bind crash correction — installed in337:** opening the Bind review no longer follows the render path that caused the reported crash. Internal native testing passed Home → Writing Desk → Bind → departure into the existing 2D world → reopening. Installation and ordinary phone launch were verified; the Bind pane was not played on your physical phone. Gameplay, campaigns and the existing 2D flow are preserved. This hotfix does not include the new terrain or morphology plans.

**Current behavior — installed in build331:** new campaigns begin with no learned Subjects, Focuses, Modifiers or Compounds. The generated introduction, safe light lessons, first usable Sun writing, missing-Subject learning routes and early traveler/material/tool/maker connections are delivered together. Stone tools and the delivered Apothecary, Forge, Tannery, Bowyer and Weaponsmith remain available through their normal requirements. Existing campaigns keep their knowledge, physical Pages and progress; your phone save was not reset.

**Decided direction:** the beginning should connect what you learn, where you explore, what you can gather, who you meet and what their first shop lets you make. You start without known runes and discover Illumination and Sun on the safe path through a broadly generated introductory world. The same unfinished introduction remains available, and collected discoveries stay learned. At Home you join the two words and shape one thing about your next world. Unwritten features remain generated.

**Why the first sigil bin is empty:** you have not learned any words yet. Bind the blank page to begin the introduction, collect Illumination and Sun, then return Home and read both lessons free in the Library. Collected-but-unread lessons do not yet supply writing words. If the introduction is unfinished, continue that same world for the missing discoveries. Once both are learned, open the Illumination bin to place and connect them; empty Modifier or Compound bins do not mean those two words are missing. This ordinary next-step explanation remains available when automatic tutorials are off.

**Design first pass — delivered in331, with natural pacing still to learn from play:** the stages and teaching changes below turn that direction into a connected opening. They are revisable design choices, not a promise that each stage takes exactly one expedition.

| Step | What you do | Why it matters next |
| --- | --- | --- |
| Start and discover light | Begin with no known Subjects, Focuses, Modifiers or Compounds; carry the stone Pick, Axe and Scythe. Collect Illumination and Sun in the introduction and read them free at Home | You learn what a Subject and source mean before being asked to compose a world |
| Shape your first world | Join Illumination and Sun in Rough charcoal | Your choice affects the light and heat; it does not promise a forest, fresh water or a particular traveler |
| Follow useful discoveries | Find water/growing land or exposed ground/Iron; collect lessons, clues and materials you can reach | These lead into the plant/remedy/textile and Iron/tool branches |
| Learn to seek materials | Learn Hydrology/River and Substrate/Iron from their actual world evidence | You can shape water or ask for the existing reachable Iron deposits. You need no shop or upgraded tool to read these lessons |
| Meet people | Invite a traveler you actually find | Nessa connects plants to remedies; Halloway connects Iron to gear and tools; Corrin connects Fibre to textiles and clothing |
| Make something useful | Build the available maker you want and use their first recipe | A Salve, a raw-material weapon/tool improvement or a woven garment has an immediate use. You need not build all three in a fixed order |
| Follow the next capability | Improve the Pick for Quartz or the Axe for Hardwood; later upgrade the Forge for Ingots | Harder sources and prepared components arrive after their simpler uses make sense |

### Practical lessons should not send you around in circles

**Current first-pass teaching rule:** once the introduction is complete, a world with real suitable evidence and a reachable lesson position offers the needed Hydrology/River or Substrate/Iron lesson without another teaching-chance roll. Water alone teaches Hydrology; River requires an actual River source. Exposed ground teaches Substrate; Iron requires actual workable Iron evidence.

A Subject and Focus can be recovered together as two clearly named lessons and read in order at Home. You do not have to learn the Subject, pay for another expedition and hope to find the same phenomenon again just to collect its Focus. Each lesson teaches one word, costs nothing to read and survives an expedition ending. A missed lesson stays eligible for its next suitable opportunity.

This guarantees an eligible lesson, **not suitable land or every material in every world**. Other lessons keep their ordinary discovery routes and protection against repeated misses.

The rest of the empty-start vocabulary now has real routes. Relief with Granite/Sand, Thermal with Ice, Vitality with Bloom and Atmosphere with Cloud follow ordinary attributable source lessons; a missing Subject accompanies the selected source lesson. Moon, Lake, Rain, Root, Herd, Sea, Snow and Wind become learnable source observations instead of automatic starter gifts. Cycle comes with an appropriate actual source. Diary-exclusive words remain with their diaries. If you lawfully learn a Focus from a cache, diary or another route, its missing Subject can also be learned free from that acquired knowledge. A Focus you already know can teach its other applicable Subjects through the Library; you do not need to find the same source again. Owning a printed Page with an unknown word is still different from knowing that Focus.

Faint and Moderate are the first later instruction, recorded after your first self-authored Sun expedition resolves and learned by reading its lessons. Small/Minute and Single/Pair follow in the opening; stronger intensity, larger extent and larger counts follow the developing/later lesson bands. Each of these13 usable Modifiers is learned separately. Frozen, Solid, Liquid and Vaporous currently have no working writing effect, so their lessons are deferred until they do. They do not block the opening or appear as newly learned but unusable rewards. Existing Pages containing them remain readable with their current warnings. Ordinary unqualified writing still works before those lessons. Printed words on your three existing physical starter Pages do not become known merely because you own or use the Page; starter Compounds are not silently restored.

### People and materials support the same branches

**Existing early access:** Vance, Nessa and Halloway can be discovered from the beginning. Bryn, Corrin and Noll become ordinarily eligible after one recruit; known location clues can reach ahead. A world contains at most one new person, and matching conditions are not the same as having met them.

**Current in331:** those first six share the opening selection band, retaining their individual entry requirements. A relevant recovered clue can then help you pursue Corrin without losing solely because an earlier person occupies a higher-priority band. They are opportunities, not a compulsory line of six arrivals. Existing habitat checks and arrival protection remain; a person is not guaranteed on an arbitrary numbered expedition.

| Person | Look for | First useful connection |
| --- | --- | --- |
| Nessa | Fresh, lit growing land with Resin shrubs and usable trees | Apothecary and a first Salve |
| Halloway | Exposed Iron that a stone Pick can work | Raw-material gear and Pick/Axe improvements |
| Corrin | Damp growing land with fibrous stems and tough leaves | Cord, Cloth and woven clothing |
| Vance | Broad open country | Optional trading; not a prerequisite for gathering |
| Bryn | Close, bending paths | A companion, not a required shop unlock |
| Noll | Hard ground with concentrated useful material | Optional recovery of a crafted item's actual components |

**Current invitation — installed in build329:** the traveler invitation offers **Invite Them** without **Not now**. Bringing someone home should not need a decline branch. Recruiting them and choosing an active party are separate actions. A clue never automatically recruits its subject.

### The first useful recipes use starting-tool materials

Iron and Coal use Pick1. Clay is gathered by hand. Stem/Leaf Fibre and Resin use Scythe1. Small Softwoods use Axe1. These supply the first three maker foundations; Hardwood, Quartz, Salt and creature drops are not hidden prerequisites for all of them.

| First project | Existing base foundation | First useful recipe or improvement |
| --- | --- | --- |
| Apothecary | Nessa;20 Essence,4 Clay,4 Logs | Salve:1 Resin+1 Fibre; no Essence fee |
| Forge | Halloway;20 Essence,8 Iron,4 Fibre,4 Logs | Raw Pointed Blade or one Pick/Axe improvement:4 Iron+1 Coal+1 Log+2 Fibre; no Essence fee |
| Tannery | Corrin;20 Essence,6 Logs,4 Clay,4 Fibre | Cord from2 Fibre; Cloth from4 Fibre; Woven Guard or Gloves from1 Cloth+1 Cord; no Essence fees |
| Early carrying | Opening Storehouse; no recruit |5 Essence+4 Fibre reaches11 slots; then10 Essence+6 Fibre+1 Resin reaches14. Optional comfort, not permission to gather or craft |
| ForgeT2 |20 Essence,8 Iron,4 Clay,4 Logs after the first Forge |2 Iron+1 Coal makes an Ingot; Ingots are useful now, rather than required before the first forge |

One Iron seam yields6 Iron, so a single seam cannot pay the8-Iron Forge foundation. Two depleted seams provide enough for that foundation and one tool improvement. Logs and Fibre can come from multiple trips. The game should present the project you want, not the cost of every possible upgrade as one opening checklist.

Pick2 opens Quartz and Axe2 opens small Hardwood. Neither needs those harder materials to make itself. Woven gear is useful before Hide/Salt Leather. Optional animal-free routes remain complete. Harvested flora retains its actual colours for supported crafting uses; different materials can be interesting for their appearance as well as their stats.

**Scope:** Essence recovery is deferred at your request. This pass keeps existing costs as references and focuses on learning and dependencies. It adds no new player-facing trial. The specifically requested 3D trials stay in Settings; the unrequested wood-colour trial entry is removed in build329, while normal wood-colour gameplay remains.

The empty start and its real lesson, writing and prerequisite-learning routes are delivered together in331. Later Scriptorium, ink and shop upgrades are not entry requirements. No new decision homework is waiting on you for this first pass.

**Continuing the introduction:** an interrupted active visit resumes normally. After returning, missing light lessons remain reachable along the same saved world’s protected learning path without a new payment or Page. Collected and depleted state remains recorded; continuation adds no new world, expedition outcome or reward roll. If both lessons are collected but unread, read them free in the Library instead of making another trip. This continuation ends when both words are learned.

**What has been checked:** Engineering continued the same native Simulator campaign through the introduction and one naturally generated authored Sun expedition. The player collected Substrate/Iron lessons, returned through the actual portal, read those lessons plus the earned Faint/Moderate instructions, reopened, and reached an available Faint → Sun → Illumination quote. All six lessons remained read. No third expedition was purchased. This short route did not exercise harvesting, recruitment or combat; separate rules checks cover the material → recruit → Apothecary → Salve connection, prerequisite learning and saving failures. Natural pacing and your play feedback remain open. Build331 installed successfully; automatic launch was refused because the phone was locked. The follow-through changed no application code and required no new phone install.

**Return lessons — current in345:** Return lists new recovered lessons from that expedition. **Read findings** completes the existing Return acknowledgment and opens the Library’s Unread Findings section directly, where all recovered unread lessons are available. A failed save does not complete the transition or learning. This replaces build332’s generic Library shortcut; opening an eligible lesson remains the free learning action. Engineering supplied internal route, exact-stock and saved-learning evidence plus installation and ordinary launch; physical feature acceptance remains separate.


## Invitation and 3D corrections — installed in329

Traveler invitations now offer Invite Them without the decline control. The unrequested wood-colour trial entry is removed; the specifically requested3D trials remain. This does not implement the new opening rune sequence or its first-six selection adjustment.

The3D trial now uses the same displayed tile size as the2D map. Opaque trees covering the player’s body or occupied tile—including remembered trees—take part in the existing fading treatment, using only already-known geometry. Engineering supplied focused and native Simulator evidence. Build330 expands the3D view to the full normal Explore viewport while preserving that tile size, clipping and knowledge limits. The update is installed and ordinary launch succeeded; the supplied movement/reopen checks are Simulator evidence, not a phone-performance or visual-acceptance claim.

## Whole-shop update · 5 September

Complete first-pass plans now cover all 19 Apothecary preparations, Forge, Tannery, Bowyer, Weaponsmith and Armoury; the complete Apothecary implementation now has Engineering-reported focused and native checks, and is delivered in phone build322. The full first Tannery pass is now delivered in build323; the first Forge equipment/Bone pass is delivered in build324; Bowyer and source-preserving Hafts are delivered in build325; Weaponsmith and both Collars are delivered in328; remaining specialist routes are pending. [Crafting Overhaul · Shop by Shop](crafting-shop-overhaul.html) records the complete scope, current rules, accepted destination and the complete first-pass recipes, producers and services for those six makers, now including shared ordinary equipment services, the complete Survey Post, Scriptorium/Writing Desk, Distillery and nine-configuration Channelworks plans. It supersedes isolated next-recipe assignments. The ingredient bridges below are temporary compatibility steps; they do not settle the final recipes or replace the accepted excursion-long coating lifetime.

## Apothecary implementation progress · 6 September

**Current behavior: the full batch is delivered in phone build322, installed and ordinarily launched on6 September.** All19 recognizable-ingredient recipes, finite named plant/mineral sources, acquisition learning, source colour/Pattern retention and all four full-excursion weapon coatings are included. The reported checks cover39 focused cases and4 native routes, including harvesting Bitter Root, returning home, learning and preparing its medicine. Shared mixed Cord/Cloth and advanced Forge/tool dependencies are included; build323 subsequently completes the first Tannery garment/pricing/refit and source-swatch routes; broader equipment composition remains pending. Older books keep their existing contents.

The older recipes and ingredient bridges below are historical compatibility references; the delivered whole-shop recipes are current. The animal-material alternatives in the new creature proposal are separate future work and are not part of this Apothecary batch.

## Tannery delivered · phone build323

**Current behavior:** the complete first Tannery pass is installed and ordinarily launched on6 September. One eligible Skin/Hide plus Salt makes one Leather. All seven garment variants are available, with independently chosen Leather panels, exact component prices and no crafting Essence toll. Refit/remake keeps the same owned item, and recovery returns only its currently attached components once.

Ordered source-colour swatches now appear in stock, crafting/refit review and equipment details. Mixed Cord strands and Cloth sections remain distinct; missing RGB is shown as unknown rather than guessed. Known Leather colour facts stay visible. Equipment comparisons preserve fractional Protection. Carry and supported paid improvements remain intact.

Engineering reports47 focused checks and3 native routes passed. This completes the first Tannery batch, not the separate creature anatomy/equipment proposals or the remaining Forge and specialist makers.

## Forge and Bone delivered · phone build324

**Current behavior:** the complete first Forge equipment pass and typed Bone source/reward/trading route are installed and ordinarily launched on6 September. T1 offers Pointed Blade, Cutting Blade, Hand Maul and Shield; T2 adds Long Spear, Helm, Rigid Guard and refitting. These are seven equipment families. Pick remains the same owned tool progression, alongside Axe and Scythe; the smelting and T3/tool dependencies already arrived in build322.

The delivered recipes use their exact Iron, Ingot, Quartz, Bone and Shield-wood working/support choices. Power and Protection retain quarter precision, workmanship stays separate, and new prices use frozen component values. Same-item refit keeps the actual piece and returns only displaced current components once. Coal remains spent process fuel, not a component, statistic or recovery reward.

Eligible new Bone keeps its actual source density, size, colour/Pattern and history through victory, Return, storage and trading. It has no extra recovery roll or generic duplicate. Forge now consumes this typed Bone; unsupported older property-only services do not. No Hollow/Dense subtype or wider anatomy rollout is implied.

Engineering reports16 distinct focused/native checks passed, including50 working/support combinations and two native journeys. Iron Collar follows in328 through its Weaponsmith/Armoury-backed recipe. Build325 subsequently delivers Bowyer and the Forge presentation update; Weaponsmith and Iron/Bone Collars follow in328; remaining specialist batches are pending.

## Wood, Hide, Apex labels and notices · 6 September

**Status:** all four directions are accepted. Hide grouping is delivered in build 318, Apex labels in build 319 with their styling integrated in build 320, and notice controls in build 320. New-world wood colour through harvested Logs is delivered in build321; Mixed Cord/Cloth is delivered in build322; Tannery equipment source swatches/refit/recovery are delivered in build323; source-preserving Hafts are delivered in build325; the broader specialist equipment journey remains pending.

**Wood comes from the world.** Trees are the main source of wood, with their actual world-derived wood colour carried into Logs, Hafts and the corresponding equipment parts. Leaves and changing light do not change the material's inherent colour. Smaller trees and fallen logs provide supporting early routes; an improved Axe must not become a circular requirement for getting its own wood.

Use **Logs**, **Softwood Logs** and **Hardwood Logs** consistently. Older stock called Timber keeps its quantity, value and lawful uses as Logs. Unknown old wood does not become invented Hardwood or Softwood: it can serve a requirement for any Log where appropriate, but cannot satisfy a Hardwood-only recipe without a known type. Saved colours remain saved, and unknown historic colours remain unknown. Fallen logs are finite existing-world resources; this decision does not promise a new guaranteed supply in every world.

**Wood colour — first-pass source mapping current in build321:** a tree's own recorded wood colour takes priority. Otherwise its wood uses the world's saved flora palette, including a palette directed through Bloom. If no flora colour was authored, wood receives a generated colour shared by its species in that world; early sources without a species use their known wood-source family. The generated range includes muted, vivid and nearly colourless shades rather than only browns. These distribution choices are starting tuning, not extra personal approvals from Aimee.

The visible woody stem and its harvested Logs now share one saved base colour for new-world sources. Leaves and changing illumination keep their separate roles; wood does not take its colour from how the leaves happen to look. Remembered trees retain their observed colour, and stock colour chips show the saved material colour. Legacy Logs retain their supported any-Log uses; older unknown colour stays unknown. Engineering reports build321 installed and ordinarily launched on6 September, with the native harvest/reopen route passing.

**Colour journey — partly delivered:** actual wood colour now survives Log-to-Haft processing in build325; further specialist equipment presentation remains separate. Build322 adds ordered mixed Cord/Cloth; build323 completes the Tannery source-swatch/refit/recovery route. Bowyer construction, refit and recovery are delivered in325; remaining specialist routes are pending. Colour itself changes no wood type, stats, price or yield.

**Flora colour — accepted clarification from Aimee,6 September; textile and Tannery source-swatch journey delivered, wider equipment pending:** harvested flora parts keep their actual source colour and pattern for crafting. Coloured Stem or Leaf Fibre carries that appearance into Cord strands, Cloth sections and the corresponding equipment bindings or woven panels. Choosing differently coloured ingredients preserves those separate contributions. Processing, returning home, reopening, refitting and recovering components must not silently replace their colours. This is visible material appearance, not just a source note.

A part with its own colour keeps that colour rather than borrowing the colour of the whole plant. New harvestable parts need an explicit source-colour mapping; older unknown colours remain unknown. Flora stays ungraded, and colour alone adds no stats. Existing remedies keep their recognizable finished colours, while extracted pigments and ink follow their specific recipes; preserving a plant's colour does not make every plant a dye ingredient.

**Named flora source colours delivered in build322:** the six Apothecary plant profiles and Dyer’s Root retain their actual assigned plant species’ complete colour and Pattern through harvesting, Return and stock. Existing Stem/Leaf/Tall Stem colours remain unchanged; mixed Cord strands and Cloth sections now preserve their ordered actual constituents. No RGB colour is guessed where its approved visual mapping is absent; the source colour facts remain preserved for crafting.

**Hide grouping — current in345:** Return and Storehouse group the same subtype and source quality, including different useful properties and colours. Exact variants expand on tap. Ownership, provenance, destinations and recipe consumption remain intact. This completes the partial grouping introduced in318/330. Tannery uses one eligible Skin/Hide plus one Salt per Leather, delivered in323; older receipts retain their actual values.

**Apex labels — current in build 319:** actual Apex creatures are identified on the existing visible field/minimap markers, current-sight details and encounter header. Ordinary creatures that stand still do not acquire an Apex label. Existing visibility remains authoritative; this adds no hidden creature, proper name or reward reveal. Engineering reports the visible Apex → move into encounter → reopen route passed and cumulative build 319 installed and launched on 6 September. Asset styling is also integrated in build 320; Engineering reports the map → encounter → reopen route passed.

**Optional field notices — current in build 320:** Monster notices and mining/gathering results can be switched separately. Muting them changes the popups, not the actual world, resource collection, map labels, Diary or inventory. A visible Apex badge remains visible.

**Current starting settings — Design first-pass tuning:**

| Category | Starting setting | Optional notices |
| --- | --- | --- |
| Monster notices | On | Sightings and alerts for creatures already disclosed |
| Mining and gathering results | Off | Routine progress, yields and depletion popups, including the separate mining result overlay |
| Finds and learning | On | Discoveries, learned content, loot/Essence results and animal progress |

You can change these settings; an existing saved choice is preserved. Damage, danger, failed actions/saves, a full satchel, required choices, combat and return summaries still explain what happened. Reading or inspecting something explicitly still shows its result. A muted gathering result must never hide damage from the same action. Fully muted results leave no empty panel, and switching notices back on does not replay old messages.

The category defaults are Design-authored starting choices, not additional personal decisions attributed to Aimee. Notice controls and Apex styling are delivered in320; wood colour follows in321 and whole-shop replacements in322–328 as specified above. The earlier notice test preserved both muted settings and collected Salt after reopening.

## Defeat summaries · delivered 6 September

**Delivery reported:** Engineering reports the actual-cause return summary installed and launched in build 317 on 6 September. The real Attack → fatal poison → return summary → restart route passed its native check; Design has not repeated the delivery checks.

**Current behavior:** the return summary names the event that actually brought you down: for example, “Defeated by poison” for a fatal poison tick, or “Defeated by [known creature]” for its fatal attack. Burning, bleeding, toxic air and dangerous growth use their own supported causes. An undisclosed creature stays unnamed, and an unavailable older cause is honestly unknown. The following line still explains that you were carried home; this does not add permanent death or change the haul rules.

The Binder going down already ends the excursion; a companion falling alone does not mean the whole party was defeated. Reopening preserves the same recorded cause without replaying damage or guessing from the enemies left nearby. This is a reporting change, not new damage or combat mechanics.

## Weaponsmith and neutral 3D marker — current in328

Build328 was installed and ordinarily launched on6 September Pacific. Maud’s complete Weaponsmith now offers Point, Edge, Maul and the diary-gated three-damage Polearm, with actual material bundles, Balanced/Driving, same-item refit and exact current-component recovery. Both Collar producers are current: Iron at ForgeT2 after either Weaponsmith or Armoury construction, Bone at built Maud. Their complete recipes and values are in [Crafting Overhaul](crafting-shop-overhaul.html).

Engineering supplied8 distinct focused/native passing checks, including152 bundle/fitting combinations, current durability, six-row combat/coatings, native crafting/refit/reopen and Bone Collar. Included knowledge persists through construction and compatible launch; building never invents the Polearm diary lesson. Armoury’s full14-choice replacement remains pending.

Build328 introduced rounded neutral purple creature markers. Existing worlds without the new generation retain their earlier representation; new worlds in333 use modular creature forms. They represent neither species anatomy nor source-material colours. The marker’s isolated bounds/preview check adds no extra expedition, combat, harvesting or phone-performance evidence; the327 trial limits still apply. Design used supplied receipts without device rechecks.

## Bowyer, Hafts and Forge presentation — current in build325

Build325 was installed and ordinarily launched on6 September Pacific. It delivers all three Bowyer weapon families, their exact component choices and previewed values, same-weapon refit, and current-component recovery. Maud teaches both Haft recipes: one matching Log becomes one Softwood or Hardwood Haft for no Essence, retaining actual source wood colour; sale1/buy2 Gold. Longbow limbs still use Hardwood Logs. The complete recipes are in [Crafting Overhaul](crafting-shop-overhaul.html).

The Forge now presents clearly labelled part choices, individually numbered source pieces, and a review separating the finished result, returned parts and attached parts. This changes presentation without changing its prices, statistics or transactions.

Engineering supplied16 distinct Bowyer/shared focused and native passing checks, plus the integrated Forge regression. These cover all17 Bowyer combinations, source colour, combat/coatings, same-item refit/reopen and save-failure recovery. Design has not repeated device checks. Build325 retained the separate Early Overhaul Playtest choice; build326 removes it as described below. The Settings ordinary3D trial follows in build327 below. The zero-rune opening was unchanged at325;331 delivers it as recorded above.

## Main-campaign overhaul integration — current in build326

The delivered gameplay overhaul is now the normal campaign experience. Open **Settings → Campaigns → New Game** to create a normal campaign directly; there is no regular-versus-Early Overhaul choice. Continue and campaign selection retain compatible existing campaigns, including their names, inventory, resources, learned words, tools, paid progress and active worlds. You do not need a fresh game to activate the delivered rules in a compatible save. Compatible saves are preserved; saves between updates are not guaranteed, while saving and reopening within the current version remain required. At326, new games still received Sun/Illumination;331 replaces that startup with the connected introduction for new campaigns. Engineering reports build326 installed and ordinarily launched on6 September Pacific, with three focused/native checks covering direct New Game, compatible owned-state preservation and restart/Continue. Design used that supplied receipt without repeating device checks.

The 3D expedition trial stays in **Settings → Owner Tools → 3D Trials**, with isolated saved test state. It does not become a main-campaign renderer switch or another New Game mode.

## Ordinary 3D expedition trial — current in build327

Build327 delivers **Settings → Owner Tools → 3D Trials → Start 3D trial**, with saved test state kept separate from your campaign. **Continue 3D trial** resumes that state, including Home after Return. The phone trial is fresh for you; the checked Simulator save was not copied to it. It uses the current starting setup, normal game costs and an unscreened generated world. There are no demonstration-only resource grants. At that delivery, the ordinary campaign remained2D. Build357 subsequently moves normal expeditions to3D while preserving the separate trial saves; placeholder visuals remain allowed.

The trial stays in that Settings menu, using **Start 3D trial** or **Continue 3D trial** for its existing save. The view stays north-up/east-right with the accepted square-projected three-quarter presentation. Movement, packed tools, harvest targets, creatures/encounters, visibility, remembered terrain and foreground fading keep their existing rules.

The trial is a small usability check of what you naturally encounter: moving, using a tool, and interacting with a creature where normal contact allows it. At the end, a quick save check means leaving normally and reopening the same trial once. It is not a campaign/progression test, a full-map task or a requirement to encounter every feature. Anything absent from that expedition is simply untested; no extra worlds or fixture grants are needed to complete a checklist.

This demonstrates only the ordinary actions actually tried in3D. It does not establish full3D readiness, final artwork, new slope/water physics or complete game balance. Wider creature changes remain separate;331 subsequently delivers the normal connected introduction without broadening this3D proof. The earlier authored terrain/water study remains a separate example scene. Engineering reports build327 installed and ordinarily launched on6 September Pacific. Its bounded Simulator check passed: one unscreened expedition, north then south to the portal, normal Return after two turns and one restart into the same saved Home. Neutral purple creature markers were visible and agreed with the minimap. Combat contact and usable harvesting were not encountered; no extra worlds or grants filled those gaps. Three focused geometry/disclosure checks also passed. This is Simulator interaction evidence; physical-phone gameplay and performance have not been accepted. Design has not repeated the supplied checks.

## Field and terrain feedback · 5 September

**Notification placement — corrected in362:** only notifications move. At this place and its details stay fixed, as do all navigation and carried-item controls in their original bottom layout. The map keeps its size and tile scale during notification switches. Exact Read now identity, normal expiry and safe touches remain. If both edges are too close, the notification stays put. This replaces the unintended whole-navigation movement in359–361.

**Forecast wording — installed in357:** the approximate collapse countdown says **About 588 turns left**, for example, instead of using a tilde that can look like a minus sign. The estimate and collapse rules are unchanged.

**Tool gesture — current behavior, delivered in build 315:** hold **Interact for 0.40 seconds**, keep the same finger down while sliding onto a packed tool, then release to select it. No second tap is needed. Release outside a choice or cancel to retain the previous valid tool. A completed hold never turns into an accidental Interact tap; choosing a tool does not harvest or spend a turn. A later Interact tap or direction toward a blocking node performs the ordinary eligible action. The movement-centre hold remains the separate quick-item menu. Hovering over a tool does not commit the choice; releasing over it does. The exact chosen tool remains your preference after reopening and on the next visit. The existing tap-to-open tool menu also remains available. Engineering reported delivery and four focused passing checks, including the continuous gesture, on 5 September (Pacific time); Design has not repeated the phone checks.

**One tile, one resource node — decided:** mineral, plant and loose-resource placement must share this rule, including guaranteed resources. One node may yield several units, and canopy artwork may extend over neighbouring tiles; neither means that two underlying gatherable resources may share a tile. **Latest clarification:** actual growth bases, mineral nodes and loose finds share the same occupancy rule, including later placement. The reported overlap correction is still pending; source coordinates determine actual conflicts, and adjacent mining remains valid. Existing-world repairs must preserve sources, progress and known locations, as described above.

**Authored water study — requested illustrative tuning, pending implementation:** you found the example too shallow. The revised example makes both bodies five times deeper: lower channel bed −0.50 / surface 0.75 beside bank 1; raised pond bed 1.50 / surface 2.75 inside bank 3. Both depths are 1.25 abstract height levels, with their own independent contained surfaces and explicitly known beds. These are illustration values, not a production depth scale or new swimming rule.

The study should face north-up and east-right, with downward camera pitch rather than a diagonal compass rotation. You liked the tree fading. The requested flat dry connected walking area should allow all four ordinary directions; slopes, wading and swimming are separate. This feedback does not approve a full 3D migration. The scene stays labelled **Terrain and water study — example heights, not a generated expedition**.

## Remembering seen trees · delivered 5 September

**Current behavior — delivered in build 316:** fully seen trees now retain their last-observed appearance after leaving sight, including after restarting. Engineering reports build 316 installed and launched successfully on Aimee’s iPhone 16 Pro on 5 September (Pacific time).

**Accepted behavior, now delivered:** remembered ground retains a tree’s last-observed shape and position. It refreshes when legitimately seen again, including a stump or observed absence. Unseen growth, removal or new trees remain unknown; an old remembered tree is not proof that it still exists now. A glimpse of canopy or previously seen ground alone does not reveal a new tree.

The remembered image reveals no hidden enemies, resources, active hazard warnings or changed shadows/effects. Remembered trees do not cast current shadows or react to current lighting. Older saves without a sufficient actual tree observation keep honest remembered ground until a new sighting. Existing fading of currently visible trees is preserved. Engineering reports model/render checks and walking-away/restart checks; Design has not repeated them. This is a bounded stationary-tree correction, not approval of a full 3D migration.

## Complete Scriptorium/Writing Desk first pass · 6 September

**Design-authored first pass complete; implementation pending.** [The writing plan](crafting-shop-overhaul.html) covers the foundation, all seven Penmanship choices, four page-lens upgrades, Pulp, pigment sources, prepared ink, personal Compounds and Seamward. Foundation plus Brush is 65 Essence before discounts; the three practices stay independent and the separate lens still uses actual field calibration.

Dyer's Root supplies a named new Magenta route, while Copper, Sulfur and Obsidian supply the other channels. The new sources are pending implementation. Just-in-time preparation still produces twelve applications, free drafting remains, and a successful Bind spends the matching ink. Old costs and world-node Ichor instructions are superseded without deleting old stock or purchases.

Build331 delivers the paired introduction/knowledge correction for the zero-rune opening, separately from the later writing-shop replacement. Existing campaigns lose no words or Pages. Lantern/Light's exact recipe and mechanical details remain separately unresolved; its accepted activation-before-illumination boundary stays intact. No new homework answer is needed for the known writing batch. The connected opening is the current priority; later content planning is paused.

## Complete Survey Post first pass · 6 September

**Design-authored first-pass plan complete; implementation pending.** The [Survey Post tables](crafting-shop-overhaul.html) now cover its foundation, eight initial instruments and all sixteen Good/Fine improvements. Named physical ingredients replace the old property-sample search. Instruments remain permanent capabilities: one Survey reads all carried subjects for one turn, and actual fieldwork calibrates the page lens.

The new foundation is 20 Essence plus 6 Logs, 4 Clay and 4 Plant Fibre. Level and Hygrometer provide a route before Quartz or Ingots: foundation plus those two Crude instruments totals 55 Essence before discounts. Good and Fine retain the deliberate first-pass 20/50 Essence service fees. No animal-fluid producer, random grade, extra station tier or equipment slot is required.

An improved instrument must be used on a later field Survey to improve its best calibration. Existing precision, observations, explicit packing choices and ongoing excursions remain intact. The page lens's separate 2/4/6/8 distinct-subject gates and costs remain. This batch adds no owner homework; the complete Scriptorium/Writing Desk plan is now also specified above.

## Shared equipment services · 6 September

**Design-authored first pass complete; Tannery services delivered in323 and Forge refitting in324; Bowyer services delivered in325 and Weaponsmith in328; other full maker services pending.** [The full service plan](crafting-shop-overhaul.html) now explains component refit, Tannery remakes, Armoury rebuilds, Weaponsmith fitting, exact recovery and older paid-work preservation across the six makers. Ordinary refit/remake/rebuild costs no Essence beyond the actual replacement recipe; fitting uses the unchanged weapon parts.

An item's previous constructions remain its history, not extra salvage. New material equipment gains no generic old Reforge rank bonus or historical unapproved +0.5 upgrade. Older paid upgrades stay on their supported existing route until an accurate conversion can preserve them. The later Peerless guarantee remains accepted, with its Mote-on-miss outcome unresolved; ordinary services do not wait on that answer.

## Whole Armoury first-pass plan · 6 September

The complete [Armoury plan](crafting-shop-overhaul.html) now specifies all 14 supported Rigid/Insulated/Balanced slot choices, actual materials, Protection/Heat Ward, quality, prices and exact rebuild/refit/recovery. **New Design-authored first-pass rules remain pending implementation.** The foundation is 35 Essence, 4 Ingots, 2 Cloth and 2 Cord, with ordinary rebuilds/refits at no Essence cost. Insulated still excludes shields.

New linings count once through Heat Ward, retaining the existing 50-point equipment cap and 60% combined heat-mitigation cap. Mixed sets can reach the ward cap while preserving Rigid pieces. Rebuilding returns old active parts once; historical versions do not become extra salvage. Bracken's foundation teaches the same Forge Iron Collar recipe so Maud is optional. Legacy gear, credits and services stay supported. The shared equipment-service plan now specifies ordinary refit/rebuild, active-component recovery and preservation of older paid work. Its implementation is pending; the later Peerless Mote-on-miss question stays in homework.

## Whole Weaponsmith first pass · delivered in328

The complete [Weaponsmith plan](crafting-shop-overhaul.html) now covers Fitted Point, Edge, Maul and all three Polearm damage choices, real Haft/Collar production, prices, recovery/refit and legacy services. **These Design-authored first-pass choices are delivered in328.** The 40-Essence base foundation also needs 4 Ingots, 2 Hafts and 2 Cord; ordinary crafts/refits cost no Essence. Polearm retains Maud's singular diary-teaching requirement.

Choose Balanced for +1 Initiative or Driving for +0.75 Power, using existing combat stats and the same actual components. No wearer lock or extra action is added. Fen's Hafts have named consumers, and Iron Collar casts directly from Iron and Coal without a second mandatory Ingot-processing step. Early Forge recipes remain unchanged. Existing owned items and paid progress are preserved; the complete Armoury plan is also now specified above.

## Whole Bowyer first pass · delivered in build325

The complete [Bowyer plan](crafting-shop-overhaul.html) covers Longbow/Pierce/Far, Sling/Crush/Far and Throwing Set/Rend/Far. **These Design-authored first-pass rules are delivered in build325.** Fen's base foundation is 30 Essence, 6 Logs, 2 Cord and 2 Resin, including all three families and ordinary refit; their crafts cost no Essence.

Hardwood supplies real bow limbs, Bone is used for hard points/shot/edges, and the recipes share Tannery textiles/Leather and Forge Ingots. There is an animal-free Clay Sling route and no ammunition inventory or replenishment chore. Working Power, four-band workmanship, component prices/recovery and refit are delivered together; owned legacy weapons stay unchanged. Every physical ranged family uses the accepted excursion-long coating lifetime. The subsequent Weaponsmith plan is also now specified above.

## Whole Tannery first-pass plan · 5 September

The complete [Tannery plan](crafting-shop-overhaul.html) now covers Cord, Cloth, Leather, three clothing families with seven variants, prices, recovery, refitting and Carry. **These Design-authored first-pass choices are delivered in build323.** Fibre portions may combine as real coloured textile constituents. Dressing uses one eligible Skin/Hide plus Salt; a Guard may use two independently chosen Leather panels. Existing stock and clothing keep their saved qualities, colours and prices.

Ordinary crafts and refit cost no Essence. New garments use the same recoverable-component pricing as the Forge. Woven Guard/Gloves/Boots remain useful before ingots or animal materials; Buckled Guard uses the existing Forge T2 Ingot. Carry stays 8→11→14→23 plus Sela's separate 2, and Home shelving still reaches 70. No extra Tannery tier, root toll or individual recipe approval is introduced. The full tables and examples are in the linked shop plan.

## Whole Forge first pass · delivered in build324

The complete [Forge/Blacksmith plan](crafting-shop-overhaul.html) now covers all eight catalogue families, one coherent Pick progression, T1–T3 facilities, all three level-3 tools, Bone/metal/wood component choices, statistics, prices, recovery and deterministic refit. The seven equipment families and typed Bone route are **delivered in build324**; the tool/smelting/T3 progression was delivered in322. The first-pass numbers remain revisable Design choices, not personal recipe approvals attributed to you.

T3 uses 40 Essence, 6 Ingots, 8 Clay, 6 Logs and 2 Quartz. A level-2 tool improves to 3 using 4 Ingots, 1 Log, 1 Cord and 2 Coal, with no Essence fee. Pick 2 can gather the Quartz first, so the route to Rift-glass has no circular rare-material requirement. Raw starter recipes remain before ingots and do not need matching colours.

New Forge pieces use a consistent component-value and recovery policy. Already owned items keep their saved stats and prices, including the earlier 10-Gold starter blade. A newly made equivalent under the revised plan is worth 11 Gold. Bone’s former isolated recipe proposal is now covered by the full shop, including valid mixtures of new Bone and other supported new materials; no individual Bone homework is needed.

## 1. Current behavior

The game currently contains both older rules and delivered early-overhaul paths. The table identifies those differences; the later intended/proposed sections do not become playable merely by being written here.

| System | Current behavior |
| --- | --- |
| Blacksmith | Build324 delivers all seven first-pass equipment families, typed Bone choices, prices and same-item refitting. Build322 supplies smelting/T3/tool progression. Earlier30-Essence and quality-fee rules describe only the old route. |
| Apothecary | The early overhaul has a reported 20-Essence foundation and Lesser Salve from Resin plus Plant Fibre. Briar Oil’s new material selection is reported delivered in phone build 310. Other older recipes remain; the complete19-recipe overhaul and excursion-long coatings are delivered in build322. |
| Refinement | The complete new refinement journey is not available. This guide does not promise a paid Reforge improvement or a Mote-based Peerless attempt. |
| First Writing | Build331 begins new campaigns with no learned words. Collect Illumination and Sun in the introduction, then read them free at Home. Existing campaigns keep their vocabulary and progress. |
| Scent Mask and Seamlight | Both can be prepared. Field Kit use has not yet been verified for the current phone build. Earlier descriptions disagreed about their availability; neither a working field action nor its absence is confirmed here. |
| Recipe tracking and visual changes | Automatic ingredient highlighting, the complete material-colour treatment, and the new world palettes are intended changes; this update is not a claim they are already playable. |

Ordinary consumable and physical-gear crafts now confirm success only after their result is saved. If saving fails, these crafts refuse without spending ingredients or granting the item. This correction has been delivered and checked with focused tests; an interactive crafting playthrough has not yet been completed. This does not mean every economy action or the material overhaul has changed. The Binder and human Gambits/Training presentation update has also been delivered, with clearer rule colours, capitalized labels, and the corrected earned-automation explanation. Existing unlocks, entitlements, Training rules, and Gambit rules are unchanged. Interactive phone navigation and visual acceptance remain pending. The Apothecary’s new recipe tiles, recipe details, and preparation presentation are also delivered. Its existing recipes, learned knowledge, and material choices are unchanged; that presentation delivery alone did not include the early recipes; their later reported implementations are recorded separately. Physical-phone visual acceptance and a campaign playthrough remain pending. The unfinished world-entry artwork is not made current by these deliveries.

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

The world will use a **three-quarter top-down view** over the existing square grid. Ground remains readable from above, while the fronts of trees, rocks, characters, and cliffs make height clearer. The existing Settings3D trial implements the functional view, with modular life and admitted water geometry added in333. Finished artwork and the intended procedural richness remain incomplete.

Water belongs to a local bed and surface height. A low river and a pond on raised land can coexist. Shallow water can show its visible bed beneath the water surface, shoreline, and above-water objects; deeper water may hide more of the bed. Water in a lower area does not paint over unrelated higher ground. Its appearance does not change which liquid it is or reveal hidden deposits.

The first version has one supporting ground level at each map position, with optional water above it. Legal steps and slopes connect neighbouring heights. A bare cliff is not a walking route; a larger climb needs a connected route through the land. The initial step or slope adds no movement surcharge beyond the ground’s existing cost. Shallow water remains traversable where a legal shore route reaches it, while deep water and chasms retain their ordinary movement restrictions. Multi-level bridges with walkable space underneath are outside this first version.

A tree’s upper artwork may overlap several squares, but its **trunk base** owns blocking and Axe targeting. With the suitable packed Axe selected at a reachable adjacent position, a small base highlight and **Chop tree** show the valid action. The impact lands at the trunk. Looking at leaves alone does not grant a harvest. Tool requirements, one-turn successful hits, saved partial work, and each tree’s own canopy remain as already decided.

Foreground trees, bushes, and objects partly fade when their artwork covers the character, then return to normal when the character emerges. A faint silhouette and the already-visible blocking base remain understandable. For raised terrain, only the obstructing foreground cliff face fades; the entire plateau does not disappear.

**Fading is a visual aid, not extra sight.** It reveals only the character and surroundings already permitted by the game’s visibility rules. It cannot expose fogged terrain, hidden creatures or resources, or things still concealed by gameplay canopy. The existing canopy rule remains: a second consecutive canopy square conceals what lies beyond; standing beneath canopy gives the local exception around the party. That exception does not erase other sight restrictions. Earned minimap knowledge remains earned. Fading itself spends no turn and changes no collision, target, harvest, or discovery.

**3D direction:** the ordinary expedition trial described above is approved for the existing Settings test menu. The earlier fixed-camera example study remains separate. Full-game renderer migration and general performance readiness are not established by this approval. Build348 separately delivers the named Blender nodes and first woody component pair within this existing3D consumer. Existing square-grid actions, saved world facts and visibility remain authoritative; hidden terrain must not leak through shadows or reflections. This does not add stacked floors, physics, camera rotation or a day/night system.

**Approved water demonstration — implementation pending:** use a small, separate terrain study with deliberately chosen example heights: a shallow pond on raised land, a lower channel, and dry ground between them. The pond and channel will each have their own water level, with visible beds only where the study permits them. You approved this separate study on 5 September. It will be clearly labelled as an example scene, not a generated expedition. Existing saves do not contain measured water depths, so its example depths stay within the study and your campaigns remain unchanged. The existing-world camera trial can continue independently.

The water study uses a dry, level route; the later feedback above requests deeper example water, north-up orientation and all four directions on its connected flat walking area. It demonstrates the earlier appearance study. Build333 separately implements measured water and shared shore crossings for new worlds, with a controlled native waterfall/shore example verified. The ordinary native world retained earlier water presentation, so natural waterfall occurrence remains unverified. This earlier study does not establish a universal wading depth. A visible water surface would never, by itself, reveal an unknown bottom, deposit or creature. The approval is recorded as complete in [Aimee Homework](aimee-homework.html).

**Accepted for later, low priority:** trees, elevated land, bushes, resource nodes, and the player character should have shadows in the three-quarter view. Their shape and treatment will be worked out after the new world geometry and foreground visibility are established. This is a presentation direction, not a decision to add dynamic lighting or a day/night system. The playable overhaul takes priority.

Existing saved worlds keep their movement and contents. The initial proof will check a tree to walk behind and chop, a visible shallow-water bed, a raised pond, a legal height connection, and foreground overlap before final artwork is specified. Existing tree fading keeps its delivered treatment. Exact artwork for additional object and cliff-face consumers remains production work. The active crafting overhaul continues alongside this bounded proof; this view does not introduce new world-writing guarantees, celestial cycles, or a fluid simulation.

### Harmful flora warnings

**Current behavior — included in installed build310:** a generic static **Dangerous growth** marker appears on first full sight of an actual harmful contact/toxin patch. Engineering reports five focused admission/native checks passing, including a turn-zero view where only hazardous bases are marked and closing/reopening without entry harm or purchases. Ordinary plants of the same species, hidden or partly seen patches, remembered-only terrain, removed/stale patches and harmless placements remain unmarked. The warning disappears when full sight is lost.

**Delivery:** Engineering’s build310 receipt explicitly includes this warning and confirms installation and ordinary launch. The older307/308 exclusion no longer describes current availability. The supplied warning checks are internal native evidence; final visual acceptance remains separate.

**Existing intended behavior:** known nearby harm should have a readable warning that works without animation. Dedicated 2D flora animation is deferred while the 3D work proceeds. Warning artwork must respect current sight and must never identify hidden plants, creatures or resources.

**Decided behavior — delivered warning rule:** you approved a small static **Dangerous growth** marker on first full sight of an actual harmful contact/toxin patch. No prior injury, learning, Look action or field-guide recognition is required. This replaces the older learning requirement for this marker. It appears only while that exact harmful patch is fully visible, still present and enterable. Ordinary plants of the same species, hidden or partly seen growth, remembered-only terrain and stale patches stay unmarked. Rooted creatures keep their separate discovery rules. The generic marker adds no level, damage, duration, yield or unseen-enemy information; existing Look and harm rules remain unchanged. Your decision is complete in [Aimee Homework](aimee-homework.html).

### Recipe tracking

Pin a known recipe to see relevant sources highlighted **as soon as they become normally visible**, including a newly generated creature. You do not need to inspect, harvest, encounter, or kill it first. The highlight means “this can provide something needed for your recipe.” A creature's random drop is still only possible. Pinning does not reveal a full loot table, hidden rewards, or anything through fog.

**Relevance and tool readiness are separate.** An Iron source can be useful even when your Pick is too weak; selecting it explains the requirement. The highlight uses a thin, softly pulsing outline that preserves the source's colours. A brief sparkle marks collection of a needed material or completion of the gathering goal. Tracking uses its own consistent colour rather than an equipment-quality colour.

### Learning to Write and find people

The **beginning as one connected path** at the top of this reference records the sequence delivered in331 for new campaigns. Existing campaigns retain their learned words and physical Pages. The first pass links the two safe light lessons to practical water/Iron learning, actual material sources, the first six travelers and useful starter crafts.

It replaces the four practical lessons’ extra chance/second-world prerequisite loop and lets the first six share a discovery band with their individual entry requirements. Broader ordinary teaching protection remains. No extra knowledge comes from merely owning a physical World Page, and no clue automatically recruits a traveler. Costs remain existing reference values; Essence recovery is deferred. The invitation’s Not now branch is removed in329; no unrequested player-facing trial is added.

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

**Development check:** the native forge now completes Pick and Axe improvements, the T2 upgrade, Iron smelting and the Scythe improvement, preserving each tool and its place in the roll after reopening. An arranged field test then harvested a Tall Stem Patch for 3 Stem Fibre in one turn. The harvest saved successfully; a tutorial interrupted the subsequent test navigation, and a separate reopen confirmed the depleted patch and retained Fibre. This is a completed functional forge-to-harvest milestone, not a natural affordability test or physical-phone playthrough.

**Tannery development check:** building the Tannery, making Cord and Cloth, crafting both woven garments and reopening the saved game now succeed in an arranged native playthrough. The garments keep their intended Protection and value, arrive in Storehouse or Waiting, and are not automatically equipped. Focused checks cover matching ingredient groups, keeping every material source, dismantling into the recorded prepared components, and refusing stale or failed-save transactions without double spending. Early Stem, Leaf and tall-stem plants inherit the world’s saved foliage colour unless a plant has a specifically assigned shade. That colour stays with its harvested Fibre, then its Cord or Cloth. A garment’s body uses the chosen Cloth colour and its ties use the chosen Cord colour; dismantling preserves those prepared components. Matching fibres from different plants may combine, but different colours are never silently averaged.

Older fibres without a recorded colour remain owned and usable for their existing ordinary costs. New colour-bearing Cord and Cloth recipes require fibres with a known colour; they do not guess or overwrite an older source. The colour rules are now implemented and tested in development, including newly generated plants through harvesting, Return and reopening. The native crafting check shows deliberately assigned ingredient-colour swatches. It does not yet prove the complete visible journey from a naturally coloured plant to finished garment artwork: garment thumbnails still use a generic placeholder, and the field-colour display has not had that full visual check. Final artwork, natural affordability and physical-phone playthrough remain pending.

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

A separate arranged specialist campaign saved Corrin’s expansion to 23 spaces. Its test then looked for Sela in the wrong menu; continuing through the existing Realms foundation completed her separate bonus and confirmed 25 after reopening, without buying Corrin’s project again. Focused checks preserve old purchase credit, prevent duplicate benefits, and keep an active expedition’s pack and contents intact. The larger capacity applies at the next packing boundary. Existing campaigns are not silently switched into the overhaul. The separate Woven Gloves and Boots checks are recorded below; physical-phone playthrough and full journey affordability remain pending.

The first project leaves 35 of the opening 40 Essence before other spending; both early projects leave 25. From an opening campaign without the Tannery, all three pack projects and its foundation together need **55 Essence, 26 Plant Fibre, 2 Resin, 6 Logs and 4 Clay**. These are optional stages across trips, not an opening shopping list. The isolated next-Bind check above passes; full journey testing must still measure gathering, other spending and later affordability.

The built Tannery also teaches **Woven Gloves** and **Woven Boots**, with no extra lesson cost or free stock. Gloves use **1 Plant Cloth and 1 Plant Cord**. Boots use the same plus **1 Resin**. Each costs no Essence and gives **Fine equipment with total Protection 1.0** in its own slot, with no Initiative, heat protection or harvesting bonus. Either needs 6 raw Plant Fibre after processing; Boots also need the Resin. Cloth and Cord keep the chosen colours. Neither recipe requires animal materials, smelting, or the pack projects. Existing equipment and patterns remain available while the update is being made.

**Gloves and Boots development check:** preparing their Cloth and Cord, crafting both items and reopening their details now pass in an arranged native playthrough. The quotes show the intended Hands or Feet slot, Fine quality, Protection 1.0, ingredients and value. A separate native Recycler check dismantled both and confirmed the original 2 Cloth, 2 Cord and 1 Resin after reopening, with their recorded sources preserved. The pack had no Carry purchases, confirming that these recipes do not require that progression.

Focused checks also cover full Storehouse delivery to Waiting, exact colours and source quantities, partial Resin recovery, older Resin stock and save failures without duplicate crafting or refunds. Ingredient-colour swatches and source details are verified; generic item icons remain placeholders. Natural affordability, finished component-coloured artwork and physical-phone playthrough remain pending.

### Creature bodies and habitats — decided intended behavior

**Current in333:** newly written worlds use compatible creature layouts and independent limb, wing and fin groups. The ordinary native check encountered generated creatures and preserved their expedition across Withdraw, Continue and reopen. Existing worlds retain their frozen generation. This does not establish every habitat or material reward through ordinary play.

Creatures will have a body and movement that suit the home their world provides. The set includes four-legged, two-legged, many-legged, serpentine, segmented, radial, fish-shaped and amorphous bodies; wings, fins and other appendages remain separate features. World conditions influence the possibilities without promising a named species.

| Habitat | Decided movement |
|---|---|
| Land | Suitable connected ground; ordinary land creatures do not enter water |
| Shore | Shallows and their adjacent banks; a fish-shaped shore creature needs supporting limbs to use land |
| Aquatic | Connected shallow and deep liquid water; swimming bodies do not always need separate fins |
| Aerial | Suitable ground and water, including deep water; membrane or feathered wings are required, but a perch is not |

Flight does not open a party route across deep water. A creature beyond the party's current reach cannot be pulled into an ordinary encounter for convenience. Trees, blocking deposits, chasms and crumbled gaps remain obstacles in this first slice. Ice is not liquid habitat, though passable ice can support movement as ground.

A habitat needs at least two connected suitable tiles. Most ordinary placement slots remain reserved for habitat areas the player can make contact with; this is not a promise that every animal starts on a reachable tile. A creature may move within its own area, but it cannot teleport out when blocked. Aquatic life in remote deep water may remain out of reach.

**Clarified intended behavior:** some aquatic creatures may start in dark water beyond your reach and only approach shallow water after they notice you. They do not need to begin on a square you can enter or fight them on. Their actual senses, behaviour and legal water routes determine whether they approach; this is not a guarantee that every swimmer comes ashore or becomes reachable. Darkness and depth are separate conditions, and the creature stays hidden unless your own sight rules allow you to see it. Existing exclusions for isolated elevated scenery still apply. The current admission correction must preserve these remote starts; this clarification alone is not a new delivery claim.

Existing worlds retain their creatures and movement. The completed Hide path keeps its actual-source checks, drop chance, Anatomy benefit, quality, colour and material history.

**Still unfinished:** the wider creature rework, additional anatomical materials and their recipes, and food, nesting and weather relationships. Aimee has lifted the Bestiary work hold after approving the arrangement below. This first habitat slice needs no new Aimee decision.

### Body-to-material rewards — installed in376

**Current — installed in376:** Build376 enables solid creature materials in newly written books: Fur Pelt, Overlapping Scales, Armoured Scales, Chitin, Chitin Plate, Shell, Protective Spines, Flight Feathers, Contour Feathers and useful Horn. Actual body parts determine what can be recovered. Existing books, creatures and earned stock keep their saved rules; Hide and Bone retain their existing recovery paths. After victory, qualifying solid parts have no separate recovery roll. Look can say “After victory: Shell” for a supported visible source; it does not reveal hidden measurements or grant a reward. Exact recovered portions retain their source colour, Pattern and quality through Return, grouped stock, trade and supported crafting. Matching subtype and quality share one stack; tap it for the individual source details. The Forge now accepts2 Shell for a Shield face or1 useful Horn for a Pointed Blade or Cutting Blade grip. Pay the ordinary remaining components; starter alternatives and0 Essence crafting stay unchanged. Shell contributes Protection; Horn contributes support workmanship without extra Power. Refitting returns displaced current components once, retaining their exact source details. Later Armoury and Weaponsmith additions, new organs and fluids remain unfinished.

The generated creature already records its body covering, wings and horns. Build376 uses those actual parts for newly written books. Body covering, appendages, horns and skeleton are separate regions. Feathers on wings do not erase a hard or furry body covering, and water habitat does not automatically mean Scales or Oil. A tissue cannot be recovered twice under different names.

| Actual body part | Recovered material or pending proposal | Boundary |
| --- | --- | --- |
| Supported soft skin or hide | Existing Smooth Skin, Supple Hide or Tough Hide | Retains the existing Hide rules and recovery chance |
| Internal mineralized skeleton | Bone | Retains the specified plain Bone rules; no automatic Hollow Bone |
| Dense fur covering | Fur Pelt | One actual fur-bearing covering |
| Overlapping scaled covering | Overlapping Scales or Armoured Scales | No invented Fish/Lizard classification or generic Plate |
| Jointed segmented hard covering | Chitin or Chitin Plate | One type/subtype, not two rewards from the same tissue |
| Declared rigid shell | Shell | No invented layered subtype or internal skeleton |
| Long rigid protective covering | Protective Spines | Not feather quills or an automatic writing ingredient |
| Feathered flying appendages | Flight Feathers | Actual supported Sky/winged body required |
| Other feathered appendages | Contour Feathers | No flight claim |
| Actual useful cranial horns | Horn | Meaningful crushing armament and a real horn, not any head ornament |
| Actual membrane sheet | Membrane | Complete sheet and Tannery proposal below; not implemented |

The delivered modular generator uses these starting covering choices: coverage below15 supplies no primary covering; hard, long covering becomes protective spines; hard segmented/radial covering becomes chitin/shell; other hardness70 or more gives armoured scales,35 or more gives overlapping scales; dense long soft covering gives fur. These rules define the saved body; collecting a reward will not choose a different covering afterward. They are not an inventory screen guessing anatomy from appearance, and they do not rewrite old creatures.

**Additional anatomy now specified as a proposal:** teeth/claws/tusks, a separate Down layer, fin/membrane sheets and actual fluid reservoirs/chemistry are detailed below. These require real new anatomical records. Damage, insulation, warning colour or emanation never substitutes for the missing part; the current creature keeps its real attacks and defenses.

**Quantity and quality:** eligible new solid parts are recovered on the existing successful-victory reward route, with no new knife, harvesting turn, fee or separate chance roll. Body-covering portions use the existing1–4 size scale, feathers the1–4 size/actual-wing-count scale, and useful horns1–2 portions. These are material portions, not literal counts of wings or horns. Anatomy applies once; quantities1/2/3/4 become2/3/4/5. Bone keeps its separate1–3 base rule and Hide its own recovery rule.

Quality uses the actual part's two relevant source measurements: covering insulation/coverage for Pelt, protection/coverage for Scales, hardness/protection for Chitin or Shell, hardness/length for Spines, actual wing extent/lustre for Feathers, and crushing strength/skeletal density for Horn. The existing75% part-expression plus25% source-Danger rule produces Poor, Common, Rare or Exceptional, with one final rounding. Species quantity is frozen; actual specimen measurements determine that specimen's quality.

**Colour and Pattern:** each recovered part retains its actual specimen colour and Pattern, or its explicit part-specific colour when one exists. Pelt is not automatically brown, Feather white or Shell neutral. Exact source portions remain selectable beneath grouped stock and carry their appearance into any later supported crafting component. Old unknown colours stay unknown. New raw solid-part sale values start at2/4/8/16 by quality, with buy values twice sale; this does not create merchant stock or change older prices.

**Current uses:** the solid-part route now connects victory rewards, Return, storage, ordinary sale and buyback, with the optional Shell and Horn Forge choices above. These materials are not universal substitutes for Bone, Leather, Ingots or Cloth. Spines and Feathers remain raw-sale-only. Later specialist panels, Pelt lining and Horn Collars remain intended; Membrane and creature fluids need their separately proposed anatomy. The existing shops already use Resin, Toxic Sap and Dyer's Root without those fluids.

**Build376 verification and artwork:** Fifteen internal checks passed, including new-book activation, old-book preservation and a controlled Shell source → reward → Return → Forge → reopening journey. That route used existing screens and controlled encounters; it does not establish natural material frequency or complete tap navigation. Installation is verified, but successful phone launch and physical usability remain unverified. The ten material icons are interim and are being polished; final creature artwork is also unfinished.

The material plan adds no hidden Bestiary reveal, food system, nest, weather immunity or deep-water harvesting. Build375 separately delivers legitimate Seen notes and the existing-material discovery journey below. Recovered material can be associated with its actual known source; existing encounter records keep their measurements without requiring a victory. Implementation of the specified food/anatomy/equipment relationships, unsupported feeding mechanisms and natural exploration/crafting feel remain open. All three creature homework goals therefore stay unchecked; this is concrete partial progress, not a claim that the generator is finished.

### Remaining anatomical materials — first-pass proposal, not implemented

The missing parts now have proposed physical definitions and optional crafting uses. **These require new actual anatomy records; the present attack types do not establish them.** A piercing creature may have no useful Fang, a toxic creature may have no Venom gland, and a glowing creature may have no dye-bearing fluid.

| Actual source required | Proposed material | Narrow optional use |
| --- | --- | --- |
| A jaw-anchored elongated tooth with a usable point | Fang | A point for the Forge Pointed Blade, Longbow or Weaponsmith Pointed Weapon/Polearm |
| A usable hard cutting claw on an actual limb | Claw | A Forge/Weaponsmith cutting edge, or either separately chosen Throwing Set edge |
| A projecting tooth with a usable long point | Tusk | A Weaponsmith Polearm point |
| A real separate soft body-feather layer | Down | The Armoury's Insulated lining:2 portions for Body,1 for Head/Hands/Feet, instead of that lining's Cloth |
| A measured skin sheet on a membrane appendage or webbed fin | Membrane |1 Membrane +1 Salt makes1 Leather |
| A real reservoir of suitable combustible oil | Creature Oil | Optional Heat Core:16 Essence,2 Sulfur and1 Oil; still potency60 |
| A real Venom gland, duct and injection structure with suitable chemistry | Creature Venom | Optional Venom coating:1 Venom +1 Plant Fibre; the same full-excursion preparation |
| Actual body fluid with extractable Magenta chemistry | Dye-bearing Ichor |1 portion makes4 Magenta pigment measures |

Ordinary teeth and solid fleshy fins need no generic stock token. Fins only provide Membrane when they actually have a useful skin web. A tusk is not also a Fang; one feathered body region cannot also pay out as Fur Pelt or Hide. Separate wing feathers and a genuine Down layer can coexist.

Hard points/edges use their actual hardness and structural integrity, with the existing four quality bands. These alternatives replace only the named Bone component, retaining every other grip, haft, binding and fitting. Down changes its lining's workmanship contribution and source appearance, not the profile's fixed Heat Ward or Protection. It grants no weather immunity. Membrane Leather retains the actual sheet measurements and source colour.

Recoverable portions belong to the actual species part or reservoir, not the attack score. Anatomy improves recovery once without inventing organs. Actual colour/Pattern stays with the selected material through Return, crafting and component recovery; unknown old appearance is not guessed. An explicitly pigment-bearing fluid can produce Magenta even when the creature's outside is another colour, but a pink or luminous creature does not automatically supply dye.

**Existing routes remain sufficient:** ordinary gear still uses its existing Bone/metal/textile alternatives; Heat Cores use Resin, Venom preparation uses Toxic Sap, and Magenta uses Dyer's Root. No new hunt or individual recipe approval blocks those shops. New creature anatomy, these optional adapters and natural source prevalence still require implementation and combined playtesting. The Forge Shell-face and Horn-grip roles below are delivered in376; specialist roles and natural prevalence remain unfinished. All three broader creature goals stay open.

### Solid materials in equipment — Forge delivered, specialist roles intended

**Current:** build376 delivers the Shell Shield face and Horn short-blade grip. **Decided intended:** the remaining specialist panels, Pelt lining and Horn Collar roles below are not implemented. **Not every drop needs a recipe:** Protective Spines and both Flight and Contour Feathers remain raw-sale-only in this first pass. A useful anatomical material does not automatically become a blade, bow spring, fletching bonus or magical insulator.

| Material | Exact use and delivery boundary | Quantity |
| --- | --- | --- |
| Shell | Forge Shield face — delivered376 |2 portions, with the ordinary brace paid separately |
| Overlapping Scales or Chitin | Armoury Balanced outer |2 portions for Body;1 for Offhand/Head/Hands/Feet |
| Armoured Scales, Chitin Plate or Shell | Armoury Rigid outer |4 portions for Body;2 for Offhand/Head/Hands/Feet |
| Fur Pelt | Armoury Insulated lining, as an alternative to Cloth or the separate Down proposal |2 portions for Body;1 for Head/Hands/Feet; the ordinary outer and binding remain required |
| Horn | Forge Pointed Blade or Cutting Blade short grip — delivered376 |1 portion; the working point/edge is paid separately |
| Horn | Weaponsmith Horn Collar, then an existing Weaponsmith or Balanced Armoury Collar socket |1 Horn makes1 Collar for no Essence; the full ordinary equipment bundle remains required |
| Protective Spines; Flight/Contour Feathers | Ordinary raw-material trading |No new equipment recipe, damage bonus or writing requirement |

Scales, Chitin and Shell panels use their actual covering protection and source quality for the named structural role. Horn grips/Collars and Pelt lining contribute to the existing workmanship calculation and their own visible material appearance; they add no hidden Power or Protection. Heat Ward remains fixed by the Armoury profile, so a rarer Pelt does not secretly grant weather protection or stronger ward. A better support can leave the rounded workmanship label unchanged; the preview must show the actual result.

Choose each complete material group explicitly. Two Shell panels can come from differently coloured sources, but the recipe does not silently combine Shell with Chitin Plate in one all-of-type bundle. Each actual colour and Pattern survives crafting, Return and refitting. Inner lining colours appear where the lining is exposed, without repainting the outer. Horn is not automatically ivory and Pelt is not automatically brown.

New gear value is the sum of its actual active components' preserved values. Horn Collar retains the selected Horn's value and quality. Refit replaces only the chosen component group, returns old parts once and keeps the same item identity. A recovered Horn Collar remains a Collar; its recorded raw Horn is not also returned. No recipe recovers both a prepared part and its ancestors.

**Example:** Rare Shell with actual protection64 gives a Forge Shield2.0 Protection; the brace adds no hidden protection. An Exceptional Horn grip can improve a Common Bone blade's workmanship to Superior while leaving its3.0 Power unchanged. Two Rare Pelt lining portions with ordinary Cloth/Cord still give the Insulated Body profile's2.0 Protection and25 Heat Ward, even if workmanship remains Fine.

**Remaining intended work:** the optional Forge uses are delivered. Specialist panels, Pelt lining and Horn Collars remain unfinished, followed separately by proposed new anatomy and ecological relationships. Natural source frequency, useful repeated rewards, unsupported feeding mechanisms and the combined exploration/crafting experience remain unresolved. No new Aimee decision blocks the specified recipes, and the three broader creature goals stay open.

### Learning about creatures and materials — complete first-pass journey

**Current — installed in375 and extended in376:** Build375 records a limited Seen note when a creature is genuinely in full current sight, including on normal expedition entry or resume. Look remains read-only and explains supported visible parts. Actual encounters retain their existing specimens, measurements and discovery reward without requiring victory. Only committed rewards confirm recovered type, quantity, quality and source colour/Pattern; Return records kept or lost portions, and Library history remains after those portions are spent or lost. Seen, Encountered and Recovered facts share one known identity without granting stock or Writing knowledge again.

**Verified scope:** Ten focused and normal-route checks passed, including durable sight recording, source-specific Bone history, encounter rewards, Return and reopening. The internal journey used controlled encounters and existing screens; it does not establish natural difficulty, complete tap navigation or final creature artwork. Installation is verified; successful phone launch and physical usability remain unverified.

**Decided behavior, delivered for supported materials:** keep **Seen**, **Encountered** and **Recovered materials** as different facts in one Bestiary entry. They are not paid ranks or a mandatory sequence. A concealed creature can be encountered before you ever see it from a distance.

| Moment | What you learn | What stays separate |
| --- | --- | --- |
| First full sight of an actually visible creature | A Seen note with its lawful name, observed appearance, supported body shape and actual habitat chapter | No measured specimen, encounter count, XP, hidden chemistry or material award |
| Look | Visible body/movement and supported exterior materials; eligible solid parts use After victory, while chance-bearing hints retain uncertainty | Read-only: no turn, fee, harvest, reward or new analysis action |
| Actual encounter or existing Read/remember | Existing specimen facts and measurements, even without victory | The earlier sighting neither consumes nor duplicates the normal first-encounter discovery reward |
| Committed material reward | Exact recovered type, quality, quantity, colour/Pattern and source | Evidence from this specimen, not an automatic promise for every member of its kind |
| Return | The actual kept/lost material outcome with its source link | Knowledge stays learned even if those portions are lost, sold or crafted |
| Library / Bestiary | One known identity combining the facts you actually earned | A sighting is not a second species, specimen or spendable material |

Only **full current sight** with the creature actually visible records a new Seen note. Fringe silhouettes, remembered ground, hidden movement, sounds and a distant Apex marker do not reveal its body or materials. Reopening the game does not scan old worlds for missed discoveries. Existing unknown habitat/shape stays honestly unclassified until a real supported observation supplies it.

A full sight may record the creature's actual supported habitat for the approved Sky/Water/Amphibious/Land arrangement. Standing in shallow water or merely having wings does not determine that chapter. Sight-only entries say **“Seen in [world]. No close encounter recorded.”** Encountered entries retain their real comparison specimens; a newer distant appearance does not quietly replace their measured traits.

**Look is useful without being a complete anatomy test.** It can describe a genuinely observed furry covering, scaled body, feathered appendages or horns. A **Possible materials** hint appears only when that actual visible part has a supported implemented reward/collection route. It names a possible material without promising its quality or quantity. A future-only recipe or body part does not become obtainable because the Wiki describes it.

The source's visible colour and pattern can be remembered, but a sighting does not add numerical material scores or hidden chemistry. Flight does not prove hollow bones; warning colour does not prove Venom; insulation does not prove Oil; glow does not prove Ichor or pigment. Existing full specimen measurements remain accessible where already earned. Look does not inspect a new creature’s hidden Bone plan because another member of its kind was encountered. It may say “Previously recovered from this kind: Bone” only from an actual committed reward linked to that known kind; this is history, separate from Possible materials. Existing earned specimen measurements remain available.

**Recovered materials are confirmed knowledge.** For example, **“Recovered: Common Supple Hide ×2, from this specimen.”** The Library may then say **“Recovered from this kind before.”** It must not say every future creature guarantees the same quality, count or colour. One failed Hide recovery does not prove a species lacks skin. Actual source portions remain selectable beneath grouped stock; the Library history itself cannot be sold, crafted or collected again.

Look keeps its existing interaction range and remains read-only. Explicit inspection stays visible even when optional notices are muted. Automatic knowledge can update quietly; it needs no second popup. Library search/counts include only genuinely known entries, deduplicate Seen/Encountered records, and preserve old read state. No hidden-species total or locked silhouette is added. Previously earned knowledge and the existing Writing-creature unlocks remain intact; a new Seen-only note does not automatically award that separate writing knowledge.

**Apex remains its own actual status.** Existing legitimate markers keep their warning role. An outside-full-sight marker is not a new specimen or a trophy reveal; a real full sight records only the lawful Apex label and appearance. Size, stillness and rare-looking material do not create Apex identity. Rooted hostile flora stays on its existing flora/discovery path.

**Still unfinished:** the already named missing anatomical parts and their equipment uses; food requirements, prey/forage relationships, actual nesting/den behavior and meaningful weather responses; and playtesting the resulting exploration/crafting experience. This contract creates none of those systems, no deep-water harvesting route and no new approval chores. All three creature homework goals stay open.

### Food, habitat and nesting — bounded first-pass proposal

**Current behavior:** the generator already uses photosynthetic, fungal and chemosynthetic producers to support life. Dark worlds can have fungal or chemosynthetic ecosystems. Individual creature traits and combat roles do not yet establish exact diets, food sources or nest ownership.

**Proposed generation consistency, not implemented:** record a small supported food relationship where a creature's actual body, habitat and placed sources justify it. This adds no hunger, breeding, feeding animation, hunting AI, population replacement, food item or player-eating action. Existing creatures, world generation and shop production remain unchanged until explicit implementation.

The first pass covers ordinary mobile Land/Amphibious creatures with supported four-legged, two-legged, serpentine or segmented bodies. A feeding profile is explicitly assigned; body shape or weak weapons alone does not prove diet. Other bodies and habitats remain valid creatures with diet unspecified by this narrow pass.

| Proposed relationship | Actual support required | What cannot substitute |
| --- | --- | --- |
| Browsing low leafy growth | An assigned browsing capability and actual reachable ordinary low leaf-bearing growth with an explicit forage profile in each occupied habitat area | Green terrain, a growth score, harvested Fibre, Logs, Cloth, or a plant across an impassable river |
| Feeding on soft fungal growth | An assigned fungal-feeding capability and actual reachable fleshy fungal growth in a suitable damp/unfrozen host, with its own forage profile | Fungal potential alone, every Spore item, medicinal mushrooms or presumed poison immunity |
| Feeding on smaller ordinary prey | An assigned hunting profile, meaningful natural armament and actual reachable smaller non-toxic ordinary prey whose own food support is established | Apex creatures, guardians, party animals, unreachable prey or a circular chain with nothing at its base |

Food profiles are new explicit ecological declarations for the compatible animal, **not claims that these plants are safe for the player to eat**. The first pass excludes defended/predatory or unresolved chemical sources. It also excludes all six named Apothecary plant profiles and Dyer's Root unless a future exact dual-use relation is authored. A soothing ingredient is not automatically food; Toxic Sap being safe to harvest does not make it edible.

The starting predator rule requires prey at least15 lower on the existing size scale. Species are resolved from smaller to larger, so a prey chain must eventually reach an actual forage source. When several supported feeding profiles are available, the starting choice is uniform among them. These are Design-authored tuning proposals, not personal Aimee approvals or a simulation of who would win a fight.

A source must be reachable using that creature's existing movement and actual connected habitat. Amphibious bank access is not unrestricted deep-water access; a tree canopy is not low forage. If no supported relation exists, the result is **diet unspecified**. The pass does not add food patches, remove the creature, reroll its traits or claim starvation. Existing chemosynthetic life remains valid even though this narrow proposal does not yet define its particular consumers' chemical intake.

Food support is a fact about **when the world was generated**. Later harvesting or defeating prey does not trigger hunger, replacement spawns, migration or altered loot. A source can support several plausible relationships, but this presence check does not claim sufficient calories or a solved population balance. Materials and their colour/Pattern remain with their actual sources; eating relationships do not create new meat, Bone, Venom or other drops.

**Roles stay honest:** only an actually selected, supported leaf-browser profile can make the future Grazer label eligible, and the existing role fit still decides whether that name is appropriate. Horns do not prove carnivory. Pursuer/Ambusher describe behavior, not a diet; Tank does not mean herbivore; Swarmer does not mean colony. New feeding profiles change no hostility, attacks, movement or rewards.

**Cover is not a nest.** Reachable vegetation or a sheltered bank may offer cover; it does not prove a den, nest, eggs or young. Calling a structure a nest/den requires an actual persisted structure or authored site with suitable access. Calling it *this creature's* home additionally requires an explicit real ownership/use relationship. Nearby presence, a Sentinel label, a tree mesh or a loot story is insufficient. Fliers retain their accepted lack of a perch requirement.

An already authored abandoned nest can remain an abandoned nest without assigning its present owner. The older optional territory-find proposal cannot invent a high nest or den just because the animal's habitat fits; those descriptions need real structure evidence. No territory-find roll, shelter asset, nesting behavior or additional approval task is enabled here.

**Player knowledge remains separate:** first sight does not reveal hidden digestion or every linked prey species. A future implemented feeding-profile description could truthfully say **“Can browse low leafy growth,”** but it must not say a feeding event was observed or reveal an undiscovered food source. Existing earned Bestiary facts stay intact.

**Remaining work:** aquatic/aerial and other unsupported feeding mechanisms, chemosynthetic intake, other food types if useful, natural source prevalence and population support, actual shelter use where worthwhile, useful weather responses, learning particular food relationships, implementation of the specified anatomy/recipes and playtesting the combined experience. The three creature goals remain incomplete. No new owner decision blocks the independent proposal above.

### Remaining diets — supported and unspecified

**First-pass Design disposition, not implemented feeding behavior.** The existing proposal supports three explicitly assigned relationships: low-leaf browsing, soft-fungal feeding and smaller-prey hunting for its compatible mobile Land/Amphibious bodies. Each needs actual suitable food, access in every occupied habitat area and, for prey, a supported chain back to forage. Body shape and movement alone do not establish any of these.

| Remaining case | What is still missing before a diet can be claimed |
| --- | --- |
| Fully aquatic plant feeder | Actual suitable submerged food and a supported way for that body to take it in |
| Fully aquatic predator | A supported in-water feeding relation, real contact and prey with a supported food chain |
| Fish-shaped Amphibious creature | A supported feeding capability; its real walking limbs do not establish what it eats |
| Aerial plant/fungal feeder or predator | A real way to obtain and handle the food; flying over it does not establish landing, perching, diving or feeding |
| Radial animal | Its actual intake capability and suitable food; radial shape does not prove filter feeding |
| Amorphous animal | An actual intake/processing mechanism and compatible food; shape does not prove absorption |
| Chemical-energy animal | Animal metabolic capability and an actual usable chemical source; smell/taste, glow and toxic defence are insufficient |
| Eating chemosynthetic growth, detritus, carrion, nectar, seeds or hazardous tissue | The actual edible part/chemistry, availability and a compatible feeding relation; nearby appearance or a material name is insufficient |

These cases remain **diet unspecified** in this first pass. That does not mean the animal does not eat, is starving or should disappear. Real photosynthetic, fungal and chemosynthetic flora retain their existing world-support rules; chemical growth can support a dark world without proving that a nearby animal eats minerals. A high chemical-sense trait means smell and taste, not chemical metabolism.

A land-bound feathered or membrane creature can still qualify for one of the supported ground profiles when its actual body, capability and food access fit. Wings alone do not change its diet. No fourth generic diet, invented food patch, feeding simulation, new recipe or owner approval is added.

### Natural availability and play — next acceptance questions

**Plan only; no new world sample or spawn frequency has been chosen.** Once an actual creature source and its named crafting use are implemented, use the ordinary source-to-craft route already being played. Record what was seen, what was reachable, what was actually recovered and kept, and what choice the real recipe offered. A second normal route is useful only for a concrete unanswered question; there is no requirement to clear a map or search a quota of worlds.

The questions are practical: could the player understand and reach the source, was its recovery useful, did colour/Pattern survive into the component, did quality match the preview, and did the optional creature material offer a worthwhile choice while ordinary crafting remained possible? For food, only an actual supported relation justifies the claim. An intentionally unspecified diet is not a failed simulation.

Not encountering a material does not prove zero availability. Seeing an unreachable swimmer does not make its drop obtainable. Losing a reward before Return is different from never receiving it. A rare lining may leave the rounded workmanship label unchanged. Repeated sale-only drops may justify adjusting which families appear, rather than inventing recipes for every part.

The later handoff should state what happened, what remains unknown and the one change or observation that would resolve the concern. Whole-world material counts, hidden cast lists and assumed spawn percentages are unnecessary. All three broader creature goals remain open until the actual integrated exploration/crafting experience supports closing them.

### Climate and creature observations — first-pass proposal, not implemented

World conditions already influence how bodies are generated: cold tends toward larger, more covered creatures; the wetter cold branch favours bulk with less extra covering; heat favours smaller, less covered bodies. These are tendencies within the same individual budget. Cold lows and hot highs can both shape one world's creatures. None guarantees a particular material, safe temperature range or immunity.

The next proposal keeps those relationships explicit for plants and animals. Cold can favour lower, woodier, clustered flora, while hot dry conditions can favour smaller, fleshy, defended growth. Food still needs its actual suitable plant part, physical host and reachable source. Rain does not create a river or edible forage; snow alone does not determine whether a particular water component is liquid. A sheltered-looking tree does not establish a den or weather protection. Ordinary plant material still keeps its own colour for crafting.

**Proposed Bestiary addition:** an actual sighting can retain a short note such as “Seen in a world with rain,” “Seen in a world with snow,” or “Seen in a world with mist.” Smoke, airborne ash, miasma, mixed rain/snow and strong moving air have equally specific notes. They use conditions actually presented during the sighting, with up to three distinct recent condition notes and their source worlds.

These are past observations about where the creature was seen. They do not mean that it thrives there, is immune to the atmosphere, hunts during storms or cannot occur elsewhere. Hidden creatures earn no note; opening the Library, repeated frames and old unknown weather do not invent observations. A sighting grants no extra specimen measurements, materials, temperature readings or discovery reward.

**Still unselected:** wet coats, body-temperature meters, weather-driven migration, shelter seeking and seasonal breeding. These are possible future systems, not accepted promises or prerequisites for this first pass. The three broader creature goals remain open pending the named implementations and natural exploration/crafting playtests.

### Bestiary arrangement

**Current arrangement, included in delivered310:** Browse the Bestiary through **Sky, Water, Amphibious and Land**, then by body shape within each section: **Four-legged, Two-legged, Serpentine, Segmented, Radial, Fish-shaped and Amorphous**. For example: Sky → Serpentine → creature entry, or Water → Fish-shaped → creature entry.

A creature’s supported habitat determines its section. Amphibious means suited to water and adjacent land; it does not mean the Earth animal class or unrestricted travel through every depth. Wings on a land-bound creature do not place it in Sky. Body shape describes its main body, rather than counting every wing, fin or other appendage. A category does not grant new abilities or reveal undiscovered creature information.

**Development check:** five focused checks and a native Library → Bestiary route passed, covering represented chapters, missing older classifications, an older entry and Back. Saved knowledge survives reopening and individual-record pruning. The temporary bug-report button can overlap the overall counter; section counters were visible. Presentation refinement and Aimee’s visual acceptance remain pending. The wider creature rework is unfinished.

**Current Simulator browsing:** chapters and body-shape groups appear when represented by recorded kinds, followed by Unclassified where needed. Empty categories add no books, locked creature silhouettes or collection targets.

### What the Bestiary knows

**Current record behavior:** an ordinary encounter records the creature kind and, when available, an individual record. You do not need to win the fight to keep that record. Existing recorded measurements and comparisons remain available. Build375 also records separate Seen notes from genuine full current sight, without granting those encounter measurements.

**Tested Simulator sorting behavior:** habitat and body-shape grouping use what your records actually establish. Search and counts include recorded kinds only, never creatures hidden elsewhere in a world. Several individual records of the same kind still count as one kind.

Older records stay available. A known Water creature with no trustworthy shape record belongs under **Water → Shape not recorded**. A creature with no recorded habitat stays **Unclassified**, even if its picture has wings. These are labels for incomplete records, not new habitats or body types. The game will not guess Four-legged from an old missing value.

A kind’s body-shape grouping follows its **latest recorded shape**. Some broad kinds contain several individual records; when a later encounter establishes a different shape, the grouping may move while the older individual records remain accessible. A recorded classification stays known even when the oldest detailed specimen records are no longer retained. Habitat stays tied to its recorded movement category.

Empty collections and searches explain that no recorded creatures match; empty chapter and body groups are omitted. There is no hidden-species total, completion percentage, or search suggestion drawn from undiscovered creatures. Opening or sorting the Bestiary does not create a new discovery, specimen or material reward.

**Discovery journey — installed in375:** full-sight Seen notes, read-only Look and actual-reward history now work together as described above, including legitimately visible unreachable creatures without treating them as measured specimens. Weather-context notes remain a separate unimplemented proposal, and build376 separately adds the supported solid materials for newly written books.

### Creature descriptions that match their lives

**Current for the modular creatures introduced in333 and retained in355:** new creature names and role descriptions follow their actual supported bodies and behavior. A flying creature can be described as a flier; a land-bound membrane creature cannot. Fins and body proportions alone do not establish an eel identity, and low bone density does not establish hollow bones.

An Ambusher needs the existing concealed close-range striking traits. Pursuers can still fight and chase without a separate natural weapon. Swarmer describes an existing multi-strike or area attack profile, not a promise of a colony; Sentinel does not promise nest guarding. Ordinary creatures must not gain the separate Apex identity just because they are large and well-armed.

A grazing diet is not yet defined, so new descriptions will not call a creature a Grazer merely because it has weak weapons or lives near plants. Its diet stays unspecified. These naming rules add no new behavior or food simulation; existing worlds retain their names, and source materials keep their own rules.

**Still open:** actual food relationships, nesting, weather responses and the full creature experience. This is partial progress on ecological coherence, not a completed ecology system.

### Climate and creature bodies

**Current generation rules:** cold tends to favour larger bodies and more covering. The wetter cold response favours bulk with less extra covering length than the drier response; heat tends toward smaller, less-covered bodies. These are tendencies that leave room for different creatures, not promises that every animal has fur, fat or protection from the weather. These relationships have not yet had a complete creature-experience playtest.

**Current for modular creatures in newly written worlds:** the cold-water tendency toward additional appendages applies only to supported water or amphibious creatures. Older worlds preserve their existing bodies. A land creature or flier will keep ordinary body variation, but will not receive that particular water-related tendency just because its world is cold or wet. Amphibious creatures can still qualify while on their bank; their supported water-and-land habitat is what matters.

Ice alone is not liquid habitat. This correction adds no new swimming or flying ability, weather immunity, material reward or food simulation. A creature’s body stays fixed after generation, and existing worlds keep their creatures. Cold land can still produce many-legged creatures through ordinary variation.

**Still unsettled:** actual diets, nesting and useful responses to changing weather. Wet coats, shelter seeking, migration and seasonal body changes are possible future ideas, not selected features. This is partial progress on weather/body coherence, not a complete weather ecology system.

### Bone — first material beyond Hide

**Current behavior, delivered in build324:** Bone rewards, source history, Return, ordinary trading and the complete Forge typed-Bone choices now work. This is delivered partial progress, not a completed anatomy catalogue or every specialist crafting route.

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

**Forge crafting delivered:** typed Bone now fills its specified points, grips, heads and protective components in the complete Forge recipes, with actual source statistics, workmanship, price and recovery. Bowyer consumers are delivered in325; Weaponsmith consumers and Bone Collars are delivered in328; Armoury consumers remain pending. Unsupported old property-only recipes cannot take new Bone merely because its family name matches; older Bone retains its supported uses.

**Now specified in the whole Forge first-pass plan:** the existing Pointed Blade can use a new Bone point and Bone grip for 0 Essence, or the other explicitly supported new-material bundles. The point uses actual skeletal density and material quality for Power; the grip adds structure, colour and its workmanship share without an invented handling bonus. A Common point at density 40 gives 2.75 Power.

The new Forge plan applies one component-value and recovery policy to Bone, Iron, Ingots and wood. Two Common Bone portions give an 8-Gold blade; its eligible new-component recovery returns those actual portions. Older gear retains its existing prices and recovery. These are Design-authored first-pass rules under your whole-shop direction, not a personal approval attributed to you. Bone production and this full crafting update still need implementation. See [the complete family tables](crafting-shop-overhaul.html).

The first creature Homework task stays unchecked. Bone production and trading are specified; the complete body-part catalogue, crafting connections and natural gathering experience still need work.

### Apothecary — whole-shop review replaces separate recipe assignments

**Historical ingredient bridge, before build322:** Briar Oil’s build310 recipe still used a separate flexible sample and coatings lasted one strike. Build322 supersedes that bridge with the complete recognizable-ingredient recipes and all four coatings lasting the full excursion on their exact weapon. The separately labelled legacy recipe route remains available for supported older stock.

**Decided intended behavior:** all four weapon coatings last one excursion on the selected weapon, across encounters and reopening. The ingredient-only compatibility work never replaced that decision. Ordinary new preparations use recognizable material roles and cost no Essence; supernatural exceptions stay explicit.

**Complete first-pass Design plan — implementation pending:** all 19 preparations now have exact recipes using six named plant parts, four named mineral sources and the existing early materials. Aromatic Leaf, Soothing Leaf, Bitter Root, Restorative Spore, Toxic Sap and Tough Bark replace the earlier unnamed ingredient placeholders. The new Briar recipe is 2 Plant Fibre plus 1 Resin; Venom uses 1 Toxic Sap plus 1 Plant Fibre, with no extra property sample. Ordinary preparations no longer depend on unfinished creature-fluid drops or a universal Reagent/Toxin item.

These are Design-authored, revisable content and tuning choices under your whole-shop direction, not personal approvals attributed to you. The packet includes source availability, tools/yields, learning, prices, custody and all four excursion-long coatings. Pick-3 access remains the named later Blacksmith dependency for Rift-glass supplies. No new Mote source or merchant stock is granted.
See [the complete Apothecary recipe matrix and all-shop plan](crafting-shop-overhaul.html).

### Optional Hide-to-Leather path — current in build323

Some generated animals can provide **Smooth Skin, Supple Hide, or Tough Hide**, according to their actual covering. A feathered, scaled, shelled, or furry animal does not silently become a Hide source. Relevant creatures can be highlighted for a known recipe as soon as normally visible, but a possible drop is not a promise. Their appearance and species remain generated.

**First-pass reward tuning:** a qualifying creature has a 70% chance to provide its covering after defeat, yielding a base 1–4 parts according to body size. The part’s actual source determines its Poor, Common, Rare, or Exceptional quality and its colour. Better quality improves its contribution to an eligible craft; it does not make the animal drop more pieces. No tool is required to collect that defeat reward.

**Anatomy is preserved:** if the expedition already has the earned Anatomy benefit, a successful covering drop keeps that bonus. Base yields of 1, 2, 3 or 4 become 2, 3, 4 or 5 parts. Anatomy does not improve the 70% chance or turn a failed drop into a success, and it does not change the part’s quality or colour. The expedition’s saved benefit applies once to each successful drop; changing the party later cannot reroll or multiply it.

**Animal-material development check:** the new source rules now save a qualifying creature’s actual covering, colour, quality and possible reward before combat. An arranged native encounter awarded 2 Supple Hide after victory and kept that reward after reopening. Focused checks cover physical habitat, all three part types, successful and failed drops, Anatomy, existing-material compatibility and saving without duplicate rewards. This replaces the eligible old Hide reward once; it does not add a second covering reward.

The native encounter used a prepared foe, so it does not measure how often suitable animals occur or how comfortable the gathering journey feels. Broader compatibility tests retain six failures also reproduced before this reward change; they have not been claimed as fixed. Leather processing and the Guard have their own development check below. Complete recipe highlighting, final artwork and physical-phone playthrough remain separate work.

Salt comes from exposed crust on suitable dry soil or sand beside saline water, or from an exposed deposit in dry saline ground. It is gathered by hand: 2 Salt in one action, then that placement is depleted. White ground alone does not promise Salt; wet mud, ice and submerged deposits are not hand-gatherable crust. Fresh growing country does not automatically supply Salt. This separate gathering trip is one reason Leather is optional rather than a prerequisite for the first Tannery crafts.

**Salt generation — decided first-pass tuning:** an eligible saline-shore region has a 50% chance to provide exposed crust sites. A region without eligible shoreline sites may instead use the dry saline deposit route at 35%. A failed shoreline check does not receive a second roll. Suitable sites still share the existing gathering budget, after promised sources and ordinary Clay; these chances do not guarantee a Salt gather in every world or change the amount of water. Existing worlds keep their contents.

**Ordinary Salt development check:** an isolated generated sandy-shore test now gathers 2 Salt by hand, depletes the crust and keeps the result after reopening. Focused tests cover both generation routes, physical host requirements, older-world preservation, saving and Return. A successful Salt-site roll still cannot displace required Clay when the gathering budget is full. This proves the ordinary source and harvest flow; it is not a natural expedition or phone-delivery test.

**Written Salt — decided behavior, now tested in development:** explicitly writing Salt into Substrate promises one reachable Salt Crust, gathered by hand for 2 Salt. Its standable location is three to eight walking steps from entry. Repeated requests, compounds, Count, Scale and Intensity do not multiply the promise. Salt written into Hydrology or Vitality keeps its pressure effects without this deposit guarantee. An Absent or locally negated statement makes no promise of its own; it does not cancel a separate positive Salt statement.

Use a suitable exposed crust first. Otherwise, the written material may form one small crust on empty, dry, unfrozen soil or sand with known ordinary-water chemistry. The surrounding world can remain fresh: this request does not require a salty-water climate or a lucky ordinary Salt roll. It preserves water, heights, underlying ground and protected sources, and cannot drain a pool, thaw ice or clear a path to make room. The crust’s own patch cannot also be a growing plant.

The promised deposit uses one existing earth-gathering place before ordinary Clay and Salt allocation, and counts toward the ordinary Salt reservation. It is not extra stock or an enlarged source budget. Before Binding, the quote must confirm the reachable hand-gathering deposit. If no legal site or budget fits, it refuses without spending. Only a genuine conflict with another direct written promise follows the existing disclosed winner-and-influence rule; a failed placement cannot silently become pressure only. Older books keep their existing behavior. This introduces no new word, free knowledge or phone-delivery claim; ordinary Salt already works independently in development.

**Written-Salt development check:** an isolated native Writing Desk quote showed one reachable hand-gathered deposit and a 2-Salt yield. Binding cost 14 Essence, leaving 26 from 40. The expedition followed the actual seven-step route to the crust, gathered 2 Salt in one action and retained both the Salt and depleted source after reopening. Nineteen focused checks passed, including compound statements, conflicting or absent requests, shared Iron/Salt placement, old books, source budgets and saving without duplicate spending. This proves the quoted generation-to-gather route; it does not establish natural vocabulary learning, pacing or physical-phone playthrough. The natural campaign remains at Home with 29 Essence after three expeditions.

| Optional Tannery recipe | Inputs | Result |
| --- | --- | --- |
| Leather |1 eligible Smooth Skin, Supple Hide or Tough Hide +1 Salt |1 Leather retaining that actual part’s quality, measurements and colour |
| Leather Guard |2 independently chosen Leather +1 Plant Cord |Body equipment with Protection calculated from the actual selected panels; the preview shows the exact result |

Both recipes cost no Essence. A complete Leather Guard uses **2 eligible raw Skin/Hide portions,2 Salt and2 Plant Fibre**, including its Leather and Cord preparation. The two Leather panels may have different source types, qualities, colours and relevant measurements; each contributes independently. Tanning never blends raw portions into an invented average material, and crafting keeps every source history.

The full animal colour and pattern data stays with the material. An exact on-screen creature-to-Leather colour conversion is not yet established, so a generic icon is not a preview of that finished colour. Retaining known source colour and completing crafting transactions does not itself prove the final artwork matches it.

Leather panels determine the garment’s workmanship: their actual quality ranks are averaged and rounded once; all-Poor gives Rough, all-Common Fine, all-Rare Superior and all-Exceptional Exceptional. Minor Cord does not reduce that workmanship. It adds no hidden Initiative, heat protection, or durability. Dismantling returns the recorded prepared Leather and Cord; it does not also refund the raw parts or spent Salt. Existing equipment and older materials remain available through their supported uses.

**Tannery presentation development check:** the updated panels, ingredient selection and complete recipe quotes are now integrated and tested in the native app. Plant-stock checks cover Cord, Cloth and the woven garment preview. A separate existing-stock check covers the missing-Hide explanation with Review unavailable, Leather and Cord selection, the full Leather Guard quote, Cancel and reopening. Cancelling preserved all materials and Essence. This was a presentation check, not another craft. The eligible raw-Hide selector has since passed in the connected playtest below. An injected save-failure message has not yet been visually checked; final material-colour artwork and physical-phone acceptance remain pending.

**Leather crafting development check:** an arranged native playthrough now tans two Leather, makes Cord, crafts a Leather Guard and confirms the item after reopening. The chosen test materials made a Fine Guard with Protection 2.50, no Essence cost and sell/buy values of 10/20 Gold. Protection still depends on the selected Leather; 2.50 is this example, not a fixed value for every Fine Guard. A separate native Recycler check dismantled it and confirmed exactly 2 Leather and 1 Cord after reopening, with no raw Hide or spent Salt returned.

All 25 focused checks in this consumer test run passed, covering exact source matching, all four quality/stat/value bands, preserved colours and parents, full storage, older Salt, saving and duplicate-action refusal. The six older compatibility failures described above remain separate and unresolved. Value records do not themselves add merchant stock or a new material-selling route.

Animal frequency, source matching during ordinary play, combat, recipe highlighting and the complete gathering journey still need playtesting. Ordinary Salt, the limited animal-source rules, Leather processing and the Leather Guard now have bounded development checks; this does not establish natural affordability or physical-phone playthrough. The wider creature rework is still unfinished, including additional body-derived materials, their uses and broader ecology. This Leather work does not update the Library Bestiary or establish that the whole creature rework is complete.

### Fresh-start overhaul playtest

**Now available as a separate Simulator build, using the existing 2D view.** Start at Home with the ordinary **40 Essence**, party and stone Pick, Axe and Scythe. No crafting materials, recruited makers, completed buildings or preselected world are supplied. Your campaign is created independently of the tested route, and reopening resumes it.

Begin with **Bind & Depart**, review the actual price, and explore visible opportunities. An empty page currently costs 10 Essence. Gather sources you can reach with your starting tools, speak to travellers you meet, collect writing, and Return with useful stock. Read recovered lessons through **Study → Library → Field Notes** for free. You do not need to clear the map.

**Verified in a separate ordinary campaign:** two paid blank-page expeditions, visible gathering and encounters, Return, a next-departure quote, and a naturally discovered Substrate lesson collected, read for free and retained after reopening. The first expedition brought Home 6 Iron and 5 raw Essence; the second ended with 26 spendable Essence, those materials and Substrate learned. No maker had joined. These are observations of that campaign, not promises about your first worlds.

**Next progression to test:** naturally find and invite Nessa, build the Apothecary for 20 Essence, 4 Clay and 4 Logs, then make and use a Lesser Salve for 1 Resin and 1 Plant Fibre at no Essence cost. Check your live next-departure price and the option to refine collected raw Essence before spending. The full natural Halloway, forge and T2 acquisition path also remains unverified.

The maker services and early crafting transactions are implemented and have separate controlled checks. This fresh-start build lets you test their ordinary acquisition; it does not establish that the complete opening is balanced. Later maker/material migrations, later tiers, the wider creature rework and new terrain-height/liquid behavior remain unfinished. Bestiary sorting has now passed in a separate later Simulator build; at that earlier checkpoint 3D was under consideration; the separate ordinary trial is now delivered in327, with the limited evidence described above. This original Simulator entry remains separate from the phone campaign entry below.

### Overhaul campaign entry on phone build 307

**Historical build307 entry, superseded by326:** that build offered a separate Early Overhaul Playtest campaign. Current **Settings → Campaigns → New Game** creates the normal game directly with delivered overhaul rules; compatible existing campaigns also receive those rules while retaining owned progress. The observations below describe the earlier checkpoint.

Creating the separate campaign and continuing it after reopening passed in the Simulator. Phone installation and ordinary launch were confirmed, but the physical phone screen and full progression route have not yet had visual/playthrough acceptance. The early maker, gathering, teaching and carrying work is included for playtesting; natural Nessa recruitment, first crafting and the full Halloway/T2 route remain unverified together.

The later **Bestiary sorting update is not in build 307**. Neither the wider creature generator changes nor a 3D renderer are delivered by that phone build.

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

**Still unproven:** finding and learning everything naturally, creature/material availability, combat and economy pacing, and affording the next expedition through ordinary play. The natural campaign remains separately preserved at Home with 29 Essence after three expeditions. No fourth search was made. At that historical checkpoint the overhaul was off for ordinary campaigns; build326 now enables the delivered rules normally; final creature/Leather artwork, the wider creature rework and physical-phone acceptance remain unfinished.

### The Binder’s own Gambits

Self-automation remains an earned ability; opening Party does not grant it. Existing unlocked campaigns keep it. The intended owner is the recovered instruction **Let your own rules run**, found in a world and read in the Library. Party uses learned Gambits and never teaches this ability. Reading does not create a rule or change any rule's enabled state.

The first-pass plan makes this later instruction eligible after Binder level 8, eight resolved expeditions, and the three opening Gambit teachings: **Check yourself**, **Leave the fight**, and **Use your skill**. Those timing values remain revisable. The replacement teaching route is not yet verified as delivered; old Workshop wording must not be read as proof that a current route exists. Until the ability is learned, the Binder takes manual turns. The delivered locked message now reads: “Your turns are manual. Following your own Gambits is a learned ability.” This removes the obsolete Workshop direction without promising that the replacement teaching is already available.

### World and equipment colour

Worlds use stable, coordinated palettes, with separate foliage, water, and sky colours. Grass belongs visually to foliage; that does not make every patch harvestable. A specifically assigned shade takes precedence. Returning or reopening keeps the same world colours.

Tint preserves shading and recognizable material cues. Water still reads as water through reflections, shores, and surface patterns; colour alone does not declare danger. Equipment keeps consistent silhouettes and shading, and **every material component region** receives its chosen tint. Quality appears in the item-name highlight and the square thumbnail border, not as a recolouring of the item artwork. Potions and remedies keep their recognizable authored colours.

**Resource icon development check:** the selected original Coal, Hardwood Log, Leaf Fibre and Softwood Log pictures now appear in Storehouse stockpiles and the Field Kit. They keep their original colours, complete framing and source dimensions, with the selected transparent backgrounds; the game fits them into its existing icon spaces without recolouring them. Native checks confirm the correct pictures beside their material names and quantities. They are included in phone build 307; physical-phone visual acceptance remains pending. This does not complete other material or garment artwork.

The Library books Aimee is drawing remain in progress. Sky and cloud homework is optional exploratory artwork; final world-entry layer sizes, placement, and movement are still being worked out. These studies are not finished in-game artwork.

### Reliable progress

**Current playtest compatibility:** saves between game updates are not guaranteed for now. Saving and reopening within the current version must still work reliably.

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

### World-generation findings — development results, not physical-phone playthrough

The first test of **1,000 completely unwritten worlds**, before the latest corrections, found suitable Iron ground in 98.2%, Coal ground in 90.5%, and fresh growing land in only **3.6%**. That missed the intended 25% review target and exposed a real early-gathering problem. These historical results are not final encounter rates. Seven generation failures also occurred under the older generator.

**Historical development finding:** a small amount of Ice must not erase ordinary unfrozen water available to plant roots. Six direct checks covered retaining background water before freezing. This earlier test note is not a current phone-delivery statement or a new request to repeat the availability study.

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

**Development fixes encountered on this route:** the same second departure exposed repeated teaching-route searches that stalled Bind preparation. Reusing those unchanged route results reduced that specific diagnostic from about 99 seconds to about 2 seconds; ten focused checks and the same native departure passed. A separate lookup correction made the existing early Substrate teaching collectable without silently reading it or granting extra knowledge; four focused checks and native pickup passed. These are development results, not physical-phone playthrough or a general performance claim. An older save refusal from an unrecorded seed remains unresolved; passing these trips does not establish its cause or fix.

**Historical development checkpoint:** the observations above predate the later delivered whole-shop passes and connected opening. They do not assign another campaign run or Essence-runway project. Essence recovery is deferred. Current work follows the connected opening and active player fixes; use the current feature sections above for delivered recipes, source guarantees and remaining appearance work.

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

**Current Tannery prices in build323:** new gear uses its actual recoverable-component values. Older receipts retain their existing value; mixed Leather panels use their own actual prices.

| Prepared material or item | Sell | Buy, when offered |
| --- | ---: | ---: |
| Iron Ingot | 4 Gold | 8 Gold |
| Plant Cord | 1 Gold | 2 Gold |
| Plant Cloth | 2 Gold | 4 Gold |
| New Woven Guard or Woven Gloves |3 Gold |6 Gold |
| New Woven Boots |5 Gold |10 Gold |
| New Buckled Woven Guard |9 Gold |18 Gold |
| Salt | 1 Gold | 2 Gold |
| New-world Skin/Hide: Poor / Common / Rare / Exceptional |2 /3 /6 /12 Gold |4 /6 /12 /24 Gold |
| Leather from those new raw portions, including Salt |3 /4 /7 /13 Gold |6 /8 /14 /26 Gold |
| New Leather Guard, two equal-grade new-price panels |7 /9 /15 /27 Gold |14 /18 /30 /54 Gold |
| New Leather Gloves, new-price Leather |4 /5 /8 /14 Gold |8 /10 /16 /28 Gold |
| New Leather Boots, new-price Leather |6 /7 /10 /16 Gold |12 /14 /20 /32 Gold |

Dismantling a Woven Guard or Woven Gloves returns its Cloth and Cord. Woven Boots also return their recorded Resin. The Buckled version also returns its recorded Ingot. Prepared materials do not also refund their raw inputs, and spent fuel or Salt never returns. These are starting prices, not a promise that every merchant stocks every item.

Buying the blade's full raw bundle costs 26 Gold. Dismantling that blade returns its recorded 4 Iron, 1 Log, and 2 Plant Fibre; the spent Coal does not return. Those recovered materials sell for 11 Gold. No new tool-dismantling route is added. Buying, making, and selling must not create an ordinary unlimited-profit loop.

## 4. Accepted refinement direction and unsettled tuning

### Blacksmith growth alongside the Village

Blacksmith T2 Iron Ingots and the first T3 tool progression are delivered in322. Other metals and wider later-facility progression remain open. New processes should arrive with something useful to make from them.

### Refining a favourite piece toward Peerless

**Accepted direction, not implemented:** Aimee likes improving an existing piece instead of making disposable copies. Refinement preserves the item's identity and chosen appearance; a miss never destroys or downgrades it.

| Advantages available, after ordinary recipe or service access | Accepted opportunity; partial odds remain unsettled |
| --- | --- |
| Any one of a maximum-level shop, its attending matching keeper, or an offered Mote | A disclosed chance at Peerless |
| Any two | A better disclosed chance |
| All three | 100% Peerless, consuming one Mote |

The accepted direction includes Mote-only and keeper-only attempts; maximum shop level is not secretly required for every attempt. It must also accommodate eligible all-metal-and-wood gear without adding creature-material quality as a fourth guarantee requirement. Peerless remains a finished-equipment quality and an optional ambition, never a requirement for ordinary progression.

**Still unsettled:** partial-setup odds; what happens with none of the three advantages; whether a Mote is spent on a miss and what lasting benefit it buys; refinement prices; what a preview reveals; how cancellation or reopening avoids free rerolls; and how any older bad-luck progress carries over. The former 3%/5% chance and twentieth-copy guarantee are reopened design, not an additional settled rule to apply alongside the accepted direction. Their replacement is not yet implemented.

Motes also serve other ambitions, including Constellation and keeping worlds. Refinement must be balanced alongside those uses. The one personal choice needed now is in **Aimee Homework**; exact balancing numbers remain design work.

## 5. Where to follow up

Use **Aimee Homework** for choices needing Aimee and **Asset Homework** for optional drawing. The subject guides carry the relevant current/intended summaries. The older overhaul references retain the wider system rules; today's explicit changes take precedence over an older fixed cost, fixed order, or settled Peerless claim.

## Hide grouping correction and current thumbnail borders

**Current in345:** Common Supple Hide shares one visible subtype-and-quality stack in Return and Storehouse even when its source measurements differ. Tapping expands the exact variants. Quantities, colours, sources and measurements remain stored without destructive merging. This restores the existing rule; build330’s remaining property-based split is superseded.

**Current quality display:** Thumbnail borders show quality: Poor/rough white, Common/Fine green, Rare/Superior blue, Exceptional purple. Orange is reserved for genuine legendary/Peerless equipment, never an extra raw-material grade or a guess from species, source or rarity. Known ordinary ungraded materials use normal green without acquiring a quality stat; unknown quality stays explicitly unknown. Material artwork keeps its actual colours.

Older Standard equipment keeps its existing label/stats and uses ordinary green; this does not add a new quality tier. The old grey Rough/white Standard convention is superseded by your latest instruction. Build330 delivered these quality borders and partial colour grouping; build345 completes the reported Hide grouping correction. Engineering supplied seven focused checks, including native movement/reopen and a return → Storehouse → Tannery case showing two preserved colour pairs as four total pieces with two exact choices. These checks used the target viewport at default text and current appearance. Installation and ordinary launch succeeded; your visual acceptance remains separate.
