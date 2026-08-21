# Village progression and production-asset matrix — current

**Status:** implementation and asset authority for destination type, district placement, building
progression, and the visual identity of the Binder House, Library root, and village stations.
Numeric costs and capacity values remain debug tuning. The six-star Constellation arrangement is the
current Game Design recommendation pending Aimee's direct review; every other rule below may proceed
without depending on that final price/gate choice. In particular, building capabilities and art may proceed;
the new district-mastery purchase/gating consumer may not ship before that review.

**Owners:** Game Design owns purpose, geography, tiers, state changes and required visual referents;
Asset Design owns finished pixel execution within this matrix; Engineering owns saved receipts,
rules adapters, exact layout and wiki generation; Aimee owns final visual and design acceptance.

**Updated:** 21 August 2026

## 1. The model in one page

The station catalogue currently mixes buildings, rooms, interfaces, collection shelves, progression
surfaces and removed compatibility content. They are not one visual family.

| Kind | Members | Progression presentation |
|---|---|---|
| **Village building** | Storehouse, Firepit/Tavern, Trading Post, Recycler, Blacksmith, Tannery, Bowyer, Armoury, Weaponsmith, Scriptorium, Survey Post, Apothecary, Reliquary, Wayfarer's Table, Distillery, Channelworks, Anchorage | Known-buildable plot, built tier 0, improved tier 1, mastered tier 2, plus independent attention overlay |
| **House room/hotspot** | Writing Desk, Library | Same Binder House cutaway; tools and collection contents change, not a separately rebuilt structure |
| **House interface** | Party | Common-room table/party objects grow from roster and current party; no station tier |
| **House-yard feature** | Essence Spring | Basin/runoff visibly deepen with its own refining upgrades; no district gate |
| **Library shelf** | Bestiary | One of five Library bookcase sections; count-derived folio/book growth, no building model |
| **Progression surface** | Constellation | Star chart/aperture; purchased stars illuminate; no ordinary building tier |
| **Removed compatibility** | Workshop | Decode-only route; no hotspot, building, plot, sign or current asset |

No village structure is ever damaged. The complete lifecycle is **absent → known buildable → built →
improved → mastered**, with attention as a removable overlay on the current form.

### Canonical destination register

This table is the exact geography/kind mapping for Engineering, Asset manifests and the Game Wiki. Legacy
`homeSection`, catalogue sort order and current `maxTier` never infer any of these values.

| Stable ID | Player name | Kind | Exact place | Keeper/build authority |
|---|---|---|---|---|
| `writing_desk` | Writing Desk | house room | Binder House · writing study | opening; Isolde deepens writing tools |
| `storehouse` | Storehouse | village building | Commons | opening infrastructure |
| `workshop` | Workshop | removed compatibility | nowhere | decode/redirect only |
| `party` | Party | house interface | Binder House · common room | opening interface |
| `essence_spring` | Essence Spring | house-yard feature | Binder House · yard | opening feature; own refining path |
| `constellation` | Constellation | progression surface | Binder House · removable wall chart | current route preserved; proposed expansion review-gated |
| `library` | Library | house room | Binder House · Library corner | opening; Lys deepens cataloguing |
| `trading_post` | Trading Post | village building | Commerce Row | Vance; first found trader/building |
| `recycler` | Recycler | village building | Commerce Row | Noll; second found trader/building |
| `blacksmith` | Blacksmith | village building | Makers' Row | Halloway; first found maker/building |
| `tannery` | Tannery | village building | Makers' Row | Corrin |
| `bowyer` | Bowyer | village building | Makers' Row | Fen |
| `armoury` | Armoury | village building | Makers' Row | Bracken |
| `weaponsmith` | Weaponsmith | village building | Makers' Row | Maud |
| `scriptorium` | Scriptorium | village building | Makers' Row | Isolde |
| `firepit` | Firepit / Tavern | village building | Commons | opening Firepit; Orsa deepens it |
| `bestiary` | Bestiary | Library shelf | Library · Bestiary shelf | collection-derived |
| `survey_post` | Survey Post | village building | Commons | Mara |
| `apothecary` | Apothecary | village building | Makers' Row | Nessa |
| `reliquary` | Reliquary | village building | Commons | Edren |
| `wayfarers_table` | Wayfarer's Table | village building | Commons | Sela |
| `distillery` | Distillery | village building | Makers' Row | Auber |
| `channelworks` | Channelworks | village building | Makers' Row | Oda |
| `anchorage` | Anchorage | village building | Commons | Tovin |

Every village building exports the same state-key family: `<id>.foundation`, `<id>.built`,
`<id>.improved`, `<id>.mastered` and a separate `<id>.attention` overlay. Firepit's improved/mastered
forms may be called Tavern/Guest Wing to the player while retaining stable `firepit.*` keys. Non-buildings
export only their own named content/state products and never receive fabricated construction keys.

## 2. District mastery and Motes

### Recommended Constellation shape

Use two visually distinct three-star clusters and one smaller central utility star:

| Cluster | Star | Cost recommendation | Permission granted |
|---|---|---:|---|
| Person | Offensive Mastery | 1 Mote | Offense depth 4–5 may be bought normally for every current/future person in this campaign |
| Person | Defensive Mastery | 1 Mote | Defense depth 4–5 may be bought normally |
| Person | Fieldcraft Mastery | 1 Mote | Craft/Fieldcraft depth 4–5 may be bought normally |
| Village | Commerce Mastery | 1 Mote | Tier-2/mastered upgrades may be activated at Commerce Row buildings |
| Village | Makers' Mastery | 1 Mote | Tier-2/mastered upgrades may be activated at Makers' Row buildings |
| Village | Commons Mastery | 1 Mote | Tier-2/mastered upgrades may be activated at Commons buildings |
| Centre | The Long Instruction | current authored cost | +1 Gambit rule capacity; not part of either trio |

The Mote buys **one district-wide permission**, never an individual building, recipe, item or skill.
Each Tier-2 building upgrade still requires that building to exist, its Tier-1 rung or an equivalent
keeper-earned tier, its own resources, and any explicit teaching. This produces six memorable Mote
decisions rather than a tax repeated at every shop.

Constellation purchases live in the save's Reality layer. They survive any later Base/Great-Work
cycle inside that campaign. A genuinely separate save slot/New Game starts clean; global account-wide
unlocking would invalidate fresh-save balance tests.

### Keeper-earned tiers

`effectiveTier = max(purchasedTier, keeperEarnedTier)` remains true. A district mastery is a separate
permission applying equally to paid and keeper-earned routes: effective Tier 2 does not activate its
mastered capability until the matching district star is owned. Earned progress is retained and becomes
active immediately when the star is purchased; no XP or paid tier is lost.

### Why two upgrades per village building

- Tier 0 makes every building useful immediately.
- Tier 1 adds the building's first new decision using ordinary campaign resources.
- Tier 2 is a late, visible culmination shared under one district permission.
- Built/improved/mastered provides enough visual growth to make the village feel constructed without
  producing nine nearly identical shelving rungs or requiring a bespoke tree per station.

Quality is not capped by station tier. Exceptional inputs may still produce exceptional quality. Tiers
open schematics, choices, convenience or system reach; they do not turn good materials into an
arbitrarily worse result.

## 3. District and upgrade authority

### Commerce Row

#### Trading Post — Vance

**Purpose:** merchant with rotating stock; buy and sell for Gold Coins; appraisal and circulation.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Complete ordinary rotating stock: world resources, eligible Creature materials, known basic consumables, one ordinary gear line and the bounded Essence offer; safe buy/sell and exact price preview | Small timber merchant frontage with open counter, striped cloth awning, ledger, hanging balance, tagged shelves/crates and a coin drawer |
| Improved · Tier 1 — **Commission Board** | Choose one broad legal request for the next refresh—World resource, Creature material, consumable or ordinary gear. It guarantees one eligible line from that category but never a specific undiscovered/rare/world-only identity | Same frontage gains a roofed side bay, visible request board with neutral category tokens, larger balance and secured stock cabinet |
| Mastered · Tier 2 — **Merchant Network** | Hold one current stock line through one refresh and permit one progression-band-legal uncommon/rare supplier line; still excludes unique, apex, story and undiscovered knowledge | Same building gains a connected covered loading bay, pulley, sealed strongbox and one additional awning span; it must remain visibly the original Trading Post |

**Never depict:** exchange arrows as the main identity, a bank, auction house, supermarket, tavern,
caravan route map or piles of treasure. The player should read “merchant who handles varied goods,” not
“convert resource A into resource B.”

#### Recycler — Noll

**Purpose:** truthfully dismantle eligible gear into recorded or authored reclaimed materials.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Exact preview and 40% recovery floor/profile route; player chooses among eligible recorded outputs | Open-sided salvage workshop with a long sorting bench, hand vise/separation jig, parts laid in removal order, shallow labelled bins and a rack of intact tools |
| Improved · Tier 1 — **Fine Separation Bench** | 55% recovery and the diary-taught Field Separation Kit uses this efficiency | Same structure gains a lit precision bench, small clamps, divided drawers and a hanging sequence rack; no industrial conveyor |
| Mastered · Tier 2 — **Ordered Recovery** | 70% recovery; the preview may prioritize one selected eligible component without changing provenance or exceeding capacity | Same building gains a modest overhead hand hoist, second clean table and more finely divided storage; original bench and vise stay recognizable |

**Never depict:** recycling arrows, trash piles, incinerator, crusher, scrapyard chaos, modern factory,
smelter or Blacksmith forge. Noll separates and records; they do not melt provenance away.

### Makers' Row

#### Blacksmith — Halloway

**Purpose:** foundational rigid physical gear, repair/reforge and the base for later specialist shops.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Foundational rigid weapon/protection/tool schematics and truthful reforge | Stone-and-clay hearth, tall smoke hood/chimney, anvil on stump, quench trough, hand tools and stacked billets; fire is contained and functional |
| Improved · Tier 1 — **Refitting Floor** | Refitting: preserve an eligible item's primary construction while replacing an authored secondary component through exact preview/receipt | Same forge gains a fitting table, measuring jigs, wall templates, brighter task lamp and improved bellows; original hearth/anvil remain |
| Mastered · Tier 2 — **Foundation Masterwork** | Opens masterwork structural variants of foundational families; it never replaces Armoury, Weaponsmith or Bowyer specializations and never caps natural quality | Same building gains a larger hood, overhead hand crane and precision tool chest; no fantasy blast furnace or weapon showroom |

#### Tannery — Corrin

**Purpose:** flexible Creature materials, light protection, bindings and carrying equipment.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Supple coat, working gloves/boots and first post-starter satchel project | Ventilated timber shed with stretching frames, scraping beam, wash tubs, hanging flexible sheets/cords and covered drying rack; clean craft, not gore |
| Improved · Tier 1 — **Carry Frames** | Second satchel project plus advanced bindings/linings and flexible Storehouse fittings | Same shed gains reinforced stitching table, shaped pack frames, additional covered rack and organized rolls |
| Mastered · Tier 2 — **Travelling Work** | Final satchel project and masterwork flexible field-gear schematics | Same footprint gains a lofted drying rail, fitted mannequin/pack stand and fine-tool cabinet; materials stay protected from rain |

#### Bowyer — Fen

**Purpose:** all nonmagical ranged weapon families; no ammunition inventory.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Longbow root and ordinary maintained ammunition fiction | Long narrow workshop, bow stave rack, tillering tree, cord spool, low shaving bench and outdoor test target |
| Improved · Tier 1 — **Range Bench** | Sling and throwing-set families plus broader fitting choices | Same shop gains projectile drawers, second tillering station and marked testing lane; not a gun shop |
| Mastered · Tier 2 — **Measured Release** | Masterwork ranged schematics/refitting choices; any later mechanical launcher requires its own real combat behavior before inclusion | Same building gains enclosed dry stave loft, precision draw scale and longer marked test frame |

#### Armoury — Bracken

**Purpose:** advanced protective gear and deliberate rigid/insulated/balanced defensive profiles.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Rigid Shell profile root and rebuild preview | Broad masonry workshop with articulated armour stand, forming stakes, plate rack and fitting dais; heavier and wider than Blacksmith |
| Improved · Tier 1 — **Layering Room** | Insulated Layer and Balanced Laminate profiles | Same structure gains padded fitting screen, layered material racks and second mannequin; no weapons display |
| Mastered · Tier 2 — **Defensive Masterwork** | Masterwork profile/socket choices; quality still follows inputs | Same building gains overhead fitting rail, enclosed testing frame and reinforced store; original armour stand remains focal |

#### Weaponsmith — Maud

**Purpose:** advanced nonmagical melee weapons fitted to repeatable motion, reach and consequence.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Fitted Point root | Compact precision forge/workshop with balance beam, weapon vise, fitting marks, grip rack and one clear point fixture; visually distinct from Halloway's general forge |
| Improved · Tier 1 — **Balance and Consequence** | Fitted Edge and Fitted Maul roots | Same building gains two additional test fixtures, weighted balance rack and broader fitting table |
| Mastered · Tier 2 — **Masterwork Leverage** | Masterwork advanced-melee variants; diary-taught polearm remains independently knowledge-gated | Same shop gains long-haft ceiling rack, leverage frame and precision drawer chest; not a generic weapon store |

#### Scriptorium — Isolde

**Purpose:** writing hands, inks, compounds and page grammar—not Library storage.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Brush hand and the Penmanship root | Bright plaster-and-timber room with north-facing window, absolutely stable writing table, brush rack, charcoal/paper, drying line and ruled boards |
| Improved · Tier 1 — **A Table That Doesn't Rock** | Ink Mixing, Compound Assembly and Chaining become independently available after their real prerequisites | Same room gains pigment drawers, ceramic mixing wells, drying rack, join/compound boards and a visibly braced table |
| Mastered · Tier 2 — **A Ruling Frame** | Fountain Pen after Chaining; no requirement to own Ink Mixing/Compound Assembly | Same structure gains large precision ruling frame, nib/pen tools, fitted ink cabinet and finer task light; it is still a writing workshop, not a printing press |

#### Apothecary — Nessa

**Purpose:** consumable remedies, coatings and preparations from world-grown inputs.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Current basic salves, antidotes and coatings | Clean herb room with heat-safe ceramic vessels, mortar, drying bundles, narrow shelves and one small controlled burner |
| Improved · Tier 1 — **Concentration Bench** | Advanced authored remedies and safe two-dose batch recipes where the recipe explicitly supports batching | Same room gains condenser coil, second mortar, labelled bottle cabinet and washable stone worktop |
| Mastered · Tier 2 — **Compound Cabinet** | Masterwork preparation recipes with authored dual-purpose behavior; never combines effects generically | Same structure gains locked reagent cabinet, precision scales and separated hot/cold work areas |

#### Distillery — Auber

**Purpose:** crystallise Essence and create authored emanation cores; not ordinary potion making.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Blank crystallisation and repeatable Heat-core root | Tall clean vessel train, crystal racks, clay receiver bowls and visible fraction lines; more mineral/glass than Apothecary |
| Improved · Tier 1 — **Separated Fractions** | Additional authored single-emanation core families | Same building gains second fraction column, cooling basin and individually isolated residue shelves |
| Mastered · Tier 2 — **Attunement Chamber** | Masterwork core recipes and controlled retuning allowed by exact core authority; never invents new statuses | Same structure gains enclosed crystal chamber, silver/quartz braces and separated input drawers |

#### Channelworks — Oda

**Purpose:** all magical weapons, from contained cores to projected emanation housings.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Restore Oda's carried Heat Conduit and make the first contained housing | Heavy containment bench, shielded core cradle, one short housing jig and heat-safe boundary plates; no Blacksmith fire |
| Improved · Tier 1 — **Shaped Reach** | Close/mid/far housing families and safe core swapping where authored | Same building gains three visibly different length jigs, projection frame and insulated handling arms |
| Mastered · Tier 2 — **Contained Projection** | Masterwork housing variants with one authored shaping choice; no generic element/status mixing | Same structure gains enclosed test aperture, stronger braces and remote lever station; still compact and controlled |

### The Commons

#### Storehouse — opening infrastructure

**Purpose:** town-wide persistent items, Waiting overflow and visible accumulation. World resources and
Creature materials stack in their reserves and never consume item slots.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | 16 item stacks plus ordinary resources/material reserves and Waiting | Timber-and-stone warehouse with broad double doors, visible shelving, sacks/crates, covered loading apron and manual hoist |
| Improved · Tier 1 — **Ordered Shelving** | Recommended 28 item stacks; exact +12 remains tuning | Same warehouse gains a side shelving bay, taller labelled racks and second loading door |
| Mastered · Tier 2 — **Receiving Annex** | Recommended 40 item stacks; exact +12 remains tuning | Same structure gains connected annex, stronger hoist and covered receiving bay; not an infinitely taller tower |

The old nine nearly identical shelving rungs map to the nearest equal-or-better 16/28/40 entitlement.
No existing save loses capacity.

#### Firepit → Tavern — Orsa

**Purpose:** initially seats recruited people; later becomes the visitor/resting social place.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 — Firepit | Safe place for recruited people before any keeper building exists | Open communal stone hearth, broad low fire, log/stone benches, kettle hook and windbreak; no tiny altar flame under a roof |
| Improved · Tier 1 — Tavern | Rotating visitors, ordinary rest and three visitor seats | A timber open hall is constructed around the **same central hearth**, with smoke hood, long table, benches, serving shelf and sheltered sleeping alcove |
| Mastered · Tier 2 — **Guest Wing** | One additional visitor seat and one visitor may remain through the next expedition refresh; deeper clue/rest benefits remain authored, not random bonuses | Same Tavern gains a side guest room/loft, larger notice board and longer table; central hearth and original windbreak stones remain visible |

#### Survey Post — Mara

**Purpose:** field instruments, survey loadout and progressively more exact analysis.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Current instruments/loadout and Tier-3 analysis outputs | Raised broad observation deck with horizon mast, lens bench, weather vane, measuring rods and open sightline |
| Improved · Tier 1 — **Calibrating Baseline** | Tier-4 instrument upgrades and comparison against saved observations | Same post gains longer marked baseline, second lens mount and protected calibration cabinet |
| Mastered · Tier 2 — **Long Measure** | Tier-5 instrument upgrades and the most exact authored readings | Same structure gains elevated fixed lens, long horizontal measuring beam and enclosed record drawer; not a lighthouse or radio tower |

#### Reliquary — Edren

**Purpose:** discovered sites, field interpretation, earlier habitation and honest recovered-site yield.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Catalogue legitimately discovered sites, interpret them and apply the authored site-yield bonus | Low enclosed stone-and-timber study with broad plan table, fragment niches, tagged trays and partial floor-plan rubbings |
| Improved · Tier 1 — **Provenance Tables** | Revealed sites show their known family and authored likelihood band before use; no remote revelation | Same building gains second plan table, conservation drawers and wall-mounted site rubbings |
| Mastered · Tier 2 — **Site Tracing** | After at least half a world's passable tiles are revealed, may mark one broad approximate area containing an unrevealed site; never exact tile/type/reward and never through fog by default | Same structure gains tall map frame, triangulation arms and sealed fragment cabinet; not a shrine, museum treasure room or generic Library |

#### Wayfarer's Table — Sela

**Purpose:** passive shared fieldcraft, packing, organic yield and visible-flora recognition. It is not a
route planner, departure hub, world graph, Party screen or supplies shop.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Existing +2 satchel capacity, +1 organic node yield and exact visible-flora field note | Open weatherproof field shelter centred on one broad map/packing table, field guide, folded cloth, sample tins and provision hooks; no counter |
| Improved · Tier 1 — **Packing Frame** | One ordinary satchel expansion (+3 current tuning) and clearer authored packing shortfalls | Same shelter gains fitted pack frame, hanging kit board and protected folio cabinet |
| Mastered · Tier 2 — **Shared Field Cabinet** | One further satchel expansion and one additional organic-yield step; it still creates no new route/departure UI | Same structure gains larger field cabinet, drying/sample drawers and second packing surface; no interactive world map |

#### Anchorage — Tovin

**Purpose:** all three anchoring routes, realm portfolio, settlement, assignments and deliveries.

| Form | Player capability | Required physical change |
|---|---|---|
| Built · Tier 0 | Craft Anchor Frames; view/manage the realm portfolio and all legitimately known anchoring routes | Quiet heavy timber/stone hall around one large open anchoring frame, Atlas lectern, tension braces and clear empty centre; not a portal itself |
| Improved · Tier 1 — **Mooring Gallery** | Work/assignment and Delivery views for anchored realms; no passive/offline production | Same hall gains side mooring frame, assignment board and delivery trays, preserving the original open centre |
| Mastered · Tier 2 — **Deep Mooring** | Allows one realm's next sustain obligation to be prepaid and held visibly; it does not remove sustain, add a realm cap or make worlds permanent for free | Same structure gains reinforced outer brace, sealed sustain chest and second Atlas rail; no glowing multiverse control room |

## 4. Non-building destination progression

| Destination | Visual progression authority |
|---|---|
| Writing Desk | Rough Charcoal opening tray → Brush/ink-mixing tools after Scriptorium knowledge → Fountain Pen/nib rack at final hand. These are owned-tool receipts, not Desk tiers. Templates appear as physical tracings and must support one-action placement. |
| Library | Wider Library corner appears in the Binder House. Its destination is a close-up of one large bookcase, at most two adjoining cases only if target geometry requires it. Five clickable shelf sections: Diaries, Bestiary, Dictionary, Field Notes, World History. Contents grow from real counts. |
| Party | One common-room table with current party tokens/gear rolls. Roster growth may add chairs/tokens, never a building upgrade or teaching UI. |
| Essence Spring | Yard basin. Built-in conversion is visible at opening; Deepen the Spring enlarges the basin/runoff. Additional refining capabilities require a separate Spring authority before a second purchased visual form is claimed. |
| Constellation | Two three-star clusters plus central Long Instruction. Unowned stars are visible only when their existence is legitimately disclosed. Purchased stars illuminate permanently. |
| Bestiary | Physical Library shelf/folio growth only; not a village building or House hotspot. |

## 5. Shared production-art contract

### Pixel deliverables

- **Village building source canvas:** 96×80 logical pixels, transparent RGBA, fixed ground pivot and
  entrance anchor across foundation/built/improved/mastered states. A justified wider specialist may use
  112×80, but every state for that building uses the same canvas.
- **District scene:** 184×319 logical pixels, exported at exact 2× nearest-neighbour for 368-wide phone
  review. Buildings are composited from the standalone sources, not redrawn into the scene.
- **Binder House/yard:** 184×319 logical scene plus separate hotspot metadata; exact 2× phone export.
- **Library destination:** 184×260 logical close-up bookcase; exact 2× export. The wider room exists only
  inside the House cutaway.
- **Review crops:** label-free transparent source at 400% nearest-neighbour, then labelled composite.
  The label-free crop is the primary identity test.

### Camera and style

- House and district buildings use one side-on/very slightly oblique orthographic pixel-art family with
  a small visible roof plane. No perspective vanishing point, isometric camera or top-down world camera.
- Library is nearly front-facing so its five shelves are tappable geometry.
- Use dark warm-brown outlines, not pure black slabs. Natural timber, clay plaster, local stone, cloth,
  paper, dull metal and glass each need a deliberate 3–5-tone ramp plus small texture clusters.
- Lighting is warm late-afternoon exterior and warm task light inside, with restrained cool blue/green
  ambient shadows. Attention uses a separate warm-gold rim; do not bake attention into base pixels.
- Pixel clusters must describe material and object, not merely subdivide rectangles. Avoid smooth vector
  gradients, CSS shapes, modern flat icons and noise sprinkled without form.
- Buildings may use standardized façade/door signs, but every built form must remain identifiable after
  all text and pictograms are removed.

### State continuity

- Foundation shows the future footprint and one truthful major fixture, not a miniature complete building.
- Improved/mastered forms add onto the same structure. Preserve roofline, entrance, major functional
  fixture and at least two material landmarks.
- Attention is an independent overlay and must work on every constructed state.
- No damaged, defended, ruined, repaired or rebuilt sprites.
- Unknown/absent means no silhouette, sign, hotspot or accessibility element.

### Per-building visual key

The accepted Trading Post style gate establishes final cluster density and shared environmental palette.
The table below fixes what must remain distinct inside that style. Accent names describe relative palette
roles, not permission to recolour one generic façade.

| Stable ID | Foundation clue | Built silhouette and value key | Materials / restrained accents | Protected through Improved and Mastered | Must not converge with |
|---|---|---|---|---|---|
| `trading_post` | two counter posts, shallow loading apron and hanging-balance bracket | medium-width open frontage; light awning over a darker counter/body | dark walnut, worn honey counter, ochre/cream cloth, brass, cool slate shadow | open counter, primary awning, balance, ledger position | Tavern, bank, resource converter, generic house |
| `recycler` | long bench footing, vise base and three shallow sorting bins | low open horizontal workshop with an ordered left-to-right parts flow | weathered oak, blue-grey iron, pale bin wood, small copper clamp highlights | separation bench, vise, ordered bins | Blacksmith forge, scrapyard, modern factory |
| `blacksmith` | stone hearth base, chimney footing and covered anvil stump | tall dark chimney/hood over a bright contained hearth and heavy low anvil | soot slate, clay red-brown, iron charcoal, ember amber | hearth, chimney/hood, anvil, quench trough | Weaponsmith showroom, Armoury, furnace factory |
| `tannery` | drain/wash-stone edge and one upright stretching frame | airy shed with tall lateral frames and a protected open drying side | pale/medium hide browns, sage wash, linen cream, weathered timber; no gore red | stretching frame, scraping beam, covered drying rack | butcher, stable, Storehouse |
| `bowyer` | long sill and tillering-tree uprights | longest narrow Makers façade; repeated vertical staves and an outdoor target gap | honey wood, olive cord, pale shavings, tiny muted target-red accent | stave rack, tillering tree, test target/lane | Weaponsmith, gun shop, generic timber shed |
| `armoury` | broad masonry footing and central fitting-dais plinth | widest/heaviest Makers body; central articulated mannequin against cool light plates | cool stone, blue-grey metal, dark leather, muted indigo padding | armour stand, forming stakes, fitting dais | Blacksmith, Weaponsmith, clothing shop |
| `weaponsmith` | compact vise plinth and horizontal balance-beam sockets | compact precision shop organized around one long horizontal balance line | dark wood, iron, restrained oxblood grip wrap, pale measure marks | weapon vise, balance beam, grip rack | Blacksmith, Bowyer, weapon retailer |
| `scriptorium` | pale wall footing, north-window frame and braced table legs | lightest Makers interior; broad steady horizontal table below a cool bright window | lime plaster, walnut, paper cream, charcoal; tiny cyan/magenta/yellow ink-well accents only after unlocked | north window, stable table, brush/tool rack, drying line | Library, printing press, Apothecary |
| `apothecary` | washable stone work edge, drying-frame posts and burner plinth | small warm workroom with clustered hanging herbs above low vessels | sage/olive plants, amber glass, cream ceramic, copper, warm stone | mortar, ceramic vessels, drying bundles, controlled burner | Distillery, kitchen, potion-shop cliché |
| `distillery` | circular vessel plinths, cooling-basin edge and receiver shelf | tall repeated vessel/column rhythm with cool negative space and crystal highlights | cool grey stone, clear/cyan quartz, silver braces, small heat-amber receivers | primary column, crystal racks, receiver bowls, fraction marks | Apothecary, brewery, generic alchemy shop |
| `channelworks` | boundary-plate rectangle, core-cradle base and lever post | compact heavy frame around a deliberately empty containment aperture | charcoal plate, silver braces, ceramic cream, restrained authored core hue | containment bench, core cradle, boundary plates, remote lever | Blacksmith, Distillery, glowing portal room |
| `storehouse` | broad loading apron, paired threshold stones and hoist socket | broadest Commons façade; two dark door bays beneath a heavy light roofline | grey fieldstone, oak, canvas tan, muted blue-grey doors, rope | double doors/bays, loading apron, manual hoist | merchant shop, house, endless shelf tower |
| `firepit` | exact central ring of windbreak/hearth stones | low open social silhouette with bright central ember and wide seating arc | fieldstone, aged oak, ember orange, muted teal/rust wool | original hearth stones, kettle hook, seating relationship | forge, shrine, campsite damage state |
| `survey_post` | two long baseline posts and central mast socket | raised open deck with one tall thin mast and long horizontal measuring beam | weathered oak, brass, pale canvas, desaturated sky blue | observation deck, mast, baseline, lens bench | lighthouse, radio tower, Wayfarer's shelter |
| `reliquary` | low stone perimeter, central table base and two fragment niches | enclosed low study with a broad pale plan-table plane and repeated wall niches | limestone, walnut, paper cream, muted terracotta fragments | plan table, fragment niches/trays, rubbing wall | Library, shrine, museum treasure room |
| `wayfarers_table` | four shelter posts and the full packing-table footprint | open weatherproof shelter with one dominant broad table and hanging kit edge | field oak, olive canvas, tin blue-grey, paper cream, folded cloth accents | packing table, field guide, sample tins, provision hooks | route planner, Trading Post, Party screen |
| `anchorage` | four heavy frame footings around an unfilled central circle | quiet high-braced hall whose darkest structure surrounds a deliberately empty centre | dark oak, deep stone, iron, cream tension rope, restrained Atlas teal | open anchoring frame, empty centre, Atlas lectern, tension braces | portal, Constellation, glowing control room |

For every row, the foundation clue is the only future-function disclosure permitted on a known-buildable
plot. It may be accompanied by the standard name/pictogram sign and exact construction status, but no stock,
keeper portrait, completed roofline or later-tier fixture appears early.

## 6. Binder House and Library exact art direction

### Binder House/yard

The house is a lived-in bookbinder's home, not a labelled floor diagram. The player-facing wall is removed.

Mandatory visual zones:

1. **Writing study:** stout wooden desk, paper stack, charcoal/owned hand tools, thread, awl, bone folder,
   small press or sewing frame and task lamp/window.
2. **Library corner:** full shelving and a readable bookcase silhouette; this is the Library hotspot, but
   individual Library shelves are not clickable until the close-up destination.
3. **Common/Party room:** central worn table, mismatched chairs, current-party tokens/gear roll; domestic
   crockery or cloth makes it a room rather than a menu.
4. **Noninteractive domestic detail:** modest bed/cot edge, stove/kettle, coat hooks, floorboards, wall
   patches and storage that do not create hotspots.
5. **Yard:** stone Essence Spring basin, controlled runoff, path, grasses and bookbinder clothesline/drying
   paper where plausible.
6. **Exits:** left Commerce, right Makers, down Commons, expressed by paths/doors and compact signs. They
   remain 44pt targets and do not become giant UI cards.

Forbidden: Workshop hotspot, Storehouse inside the house, Bestiary separate hotspot, modern office, generic
fantasy wizard tower, empty tan rectangles, labels carrying room identity, clipped yard or invented walking.

Palette/value authority: slate roof and dark exterior timbers frame warmer limewashed rooms; aged oak floors
and furniture carry mid-values; paper/linen and window light are the brightest non-effect values; faded rust,
rain-blue and olive textiles create domestic colour without turning rooms into color-coded UI. The yard is
cooler/desaturated than the interior, with the Essence Spring's restrained blue-green highlight below paper
brightness. The writing desk, bookcase and common table must remain distinct in literal grayscale.

### Library destination

Use one close-up floor-to-ceiling timber bookcase. A second adjoining case is permitted only if one cannot
provide five honest 44pt shelf targets. The case fills the screen below navigation.

Fixed shelf arrangement:

- full-width upper **Diaries** shelf;
- middle left **Bestiary**, middle right **Dictionary**;
- lower left **Field Notes**, lower right **World History**.

Each section has a small physical brass/paper label, real count and a distinct object grammar. Diaries use
traveller volumes; Bestiary uses habitat folios; Dictionary uses index cards/tracings; Field Notes use worn
notebooks; World History uses atlas volumes. Empty shelves retain only their physical label and space—no fake
books. Count stages are folded paper, stitched folio, softbound, hardcover, full hardcover with slips.

Forbidden: second full-room shot, floor plan, tables/chairs, modern tab bar, five floating cards, fabricated
titles, unknown names/species, bookshelf rendered as a grid of flat coloured rectangles.

Palette/value authority: honey-to-walnut timber, paper cream, aged leather rust/olive/navy and restrained
brass labels under warm side light. Shelf interiors are dark enough to separate paper silhouettes but never
black voids. Section identity comes from physical contents and construction, not five unrelated panel colors;
all five targets and every paper→folio→book stage remain distinct in literal grayscale.

## 7. Asset checkpoint order

Asset Design must not generate the whole town before the style gate passes.

1. **Style gate:** one label-free Trading Post built-tier crop at 400%, its ordinary district placement,
   and literal grayscale. It must pass merchant identity/material/light review.
2. **Opening identity set:** Recycler, Blacksmith, Storehouse and Firepit built forms using the accepted
   style. Compare all five label-free in colour and grayscale.
3. **State continuity:** Trading Post and Firepit foundation/built/improved/mastered rows plus attention
   overlays.
4. **Binder House:** full phone cutaway/yard and label-free 400% crops of Writing, Library and Party zones.
5. **Library close-up:** empty/early/developed/attention states with collision overlay.
6. Only after those pass: later buildings in campaign reachability order, never as one unreviewed wall.

Asset reports must include direct lossless PNG paths, ordinary phone composites, label-free crops, source
dimensions, palette, pivot/anchor manifest, deterministic hashes and a plain-language note naming any brief
requirement not yet met. Technical determinism never substitutes for visual acceptance.

## 8. Engineering and wiki handoff

1. Replace catalogue `maxTier` placeholders with the destination-kind and tier authority above only when
   each upgrade has its real consumer and migration.
2. Store district mastery separately from station tier; it gates Tier-2 activation and does not fabricate
   purchased history.
3. Compress Storehouse legacy rungs without reducing effective capacity; map Recycler's current 40/55/70
   ladder to built/improved/mastered.
4. The Game Wiki ingests this document as current authority. It must distinguish real authored, provisional
   balance, and still-open capabilities rather than treating every catalogue tier as complete.
5. Native art consumes stable building/state keys and must fail to its clearly provisional placeholder when
   a reviewed source is absent; do not silently use another station's façade.

## 9. Decisions still requiring playtest rather than pre-implementation debate

- exact upgrade costs and keeper-level milestones;
- 16/28/40 Storehouse tuning;
- Trading Post request/hold frequency and rare-stock band;
- whether the Tavern Tier-2 visitor hold is useful or administrative;
- whether Wayfarer's Table's second capacity/yield rung is worthwhile;
- the exact Anchorage prepayment amount and whether it reduces friction enough to keep;
- whether one Mote per star gives Motes sufficient weight without causing hoarding.

These values belong in DEBUG tuning/Homework. They do not reopen destination identity, district placement,
the two-upgrade visual ladder, the no-damage rule, or the distinction between House rooms and buildings.
