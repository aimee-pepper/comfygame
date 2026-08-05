# Research Pass #3 — Mystcraft Symbol Catalog, FF12 Gambit Catalog, Adjacent Precedents

(Repo export of the chat artifact, content unchanged, inline source links stripped; the chat artifact retains citations.)

## TL;DR
- Complete Mystcraft v0.13 (1.7.10–1.12.2) symbol catalog below by category (~95% coverage). Exact numeric instability values essentially do not exist in any authoritative source — Mystcraft computes block instability at runtime by profiling how much an age's resource abundance exceeds the overworld baseline ("greed"). Only concrete community figures: Accelerated ≈275, Dense Ores ≈600, from one ~2013 decompile flagged uncertain.
- Full FF12 gambit catalog (~120+ pieces, ~99% coverage) below. Key finding: the ORIGINAL PS2 game gated gambits behind story progression — the "logic gets more granular over time" model this project wants — whereas Zodiac Age makes all gambits purchasable after Nalbina Dungeons. Mirror the original.
- For "more instability = more value" and assigned harvesters: Path of Exile map juicing (reward mods coupled to danger mods; players veto-roll unsurvivable quirks) and Palworld work-suitability (visible, specialized workers) are the strongest precedents; WoW's Garrison mission table is the "menu-game" failure mode to avoid.

## PART 1 — MYSTCRAFT SYMBOL / PARAMETER CATALOG

**Structural rules.** Modifiers are written BEFORE the symbol they modify (adjective→noun). Every age needs exactly one Biome Distribution, one Lighting, one Weather, one World Landscape, and ≥1 each of Sun/Moon/Stars. Unsatisfied grammar doesn't directly cause instability, but symbols auto-added to satisfy it can. Instability comes from "greed" (valuable/abundant resources vs. overworld baseline), grammar errors, dangling modifiers, and a few specific symbols; "dangerous" symbols add base stability.

### 1A. Biome Distributions (controllers — pick exactly one)
- Huge / Large / Medium / Small / Tiny Biome Distribution — min 3 biome modifiers; controls biome size
- Tiled Biome Distribution — min 2 biomes; alternating per-chunk (heightmap per 4×4 chunks)
- Grid-form Biome Distribution — min 2 biomes; alternating every chunk
- Single Biome Distribution — exactly 1 biome; infinite single biome
- Native Biome Distribution — 0 modifiers; overworld-style distribution

### 1B. World Landscape (terrain generators — pick one)
Standard World, Cave World (Nether generator), Island World (single floating island, optional infinite ocean or "No Seas"), Flat World, Void World (blank slate — no block modifiers, deadly without flight), Amplified World (exaggerated heightmap).

### 1C. Celestials + Length / Angle / Phase modifiers
Bodies: Normal Sun, Normal Moon, Normal Stars, Dark Sun, Dark Moon, Dark Stars, Ender Starfield, Twinkling Stars.
- Suns/Moons accept Direction, Length, Phase, Sunset Color (cannot be recolored). Stars accept Direction, Length, Color/Gradient (no Phase). "Dark X" = "no X"; a Dark Sun removes daylight, so undead don't burn and spiders stay hostile.
- Length (orbit speed + gradient duration; multiple blend to midpoint): Zero (0.0, fixed), Half (0.5 ≈ 10-min day), Full (1.0 ≈ 20-min day), Double (2.0 ≈ 40-min day).
- Angle/Direction (rise direction; blend): North (0/360), East (90), South (180), West (270).
- Phase (start position; blend): Rising, Zenith, Setting, Nadir.

### 1D. Lighting (pick one)
- Bright Lighting — night-vision-like visibility (visual only; doesn't change actual light level). ADDS instability ("a small amount," per 0.11.0.00 changelog; no number published).
- Normal Lighting — overworld light; accepts Color/Gradient. Adds stability.
- Dark Lighting — much darker; daylight won't burn undead or pacify spiders. Qualitative.
Note: lighting symbols do NOT change mob-spawn light-level mechanics. This directly informs the "Dim Sky" quirk: in vanilla Mystcraft darkness is a visibility/undead-burn tradeoff, not a spawn-rate multiplier — the "more nocturnal creatures spawn" side of the quirk is this project's own addition.

### 1E. Weather (pick one)
Normal, No Weather, Slow, Fast, Eternal Weather, Eternal Rain, Eternal Snow, Eternal Storm. (Eternal variants force weather even in biomes that wouldn't normally have it.)

### 1F. Visuals (cosmetic)
Boundless Sky (removes below-horizon fog — for Void/Skylands), Cloud Color, Fog Color, Sky Color, Night Sky Color, Sunset Color, Foliage Color, Grass Color, Water Color, Rainbow (accepts Direction). Most accept Color and/or Gradient; Foliage/Grass/Water accept Color but NOT gradients. Natural Visuals accept no modifiers and mimic the biome/overworld.

### 1G. Color modifiers & mixing grammar
One page per color (Black, Blue, Cyan, White, Red, etc.). Mixing grammar: Color pages + Length pages → Gradient Page → target (e.g., Sky Color). Length sets how long each color lasts before fading; ≥2 colors needed for a gradient. Gradient length ≈ half of celestial length; matching Length pages can sync a color shift to a celestial's motion.

### 1H. Effects
- Accelerated — extra random ticks (faster crops/farms). ADDS instability (community-decompiled ≈275, uncertain, later rebalanced).
- Lightning (Charged) — lightning strikes; accepts Color/Gradient. ADDS base STABILITY.
- Meteors — falling meteors; eventually destroys the age. ADDS base STABILITY.
- Scorched Surface — sky-exposed entities catch fire (roofs = safety). ADDS base STABILITY (stacking bonus capped to apply once).
- Spontaneous Explosions — random explosions anywhere (even blast-proof rooms; can destroy linkbooks); eventually destroys the age. ADDS base STABILITY.

### 1I. World Features (V11 vs V12 schemes)
Older ("Populators" + "Terrain Alterations") vs V12+ ("Small / Medium / Large Features"). In V12 each category has a "Lacking …" dummy: Lacking Small and Lacking Medium ADD instability; Lacking Large does not.
- Small: Crystalline Formations (restricted materials: Glass, Ice, Packed Ice, Snow, Glowstone, Nether Quartz Ore, Crystal), Deep Lakes, Obelisks (material), Star Fissure (guaranteed exit to home dimension), Surface Lakes, Lacking Small Features.
- Medium: Dungeons, Mineshafts, Nether Fortress, Ravines, Spheres (material), Spikes (material), Strongholds (×3, End portals nonfunctional), Villages, Lacking Medium Features.
- Large: Caves, Dense Ores (extra ore; historically large instability), Floating Islands (material + biome), Huge Trees, Skylands, Tendrils (material), Lacking Large Features.
Community rule of thumb from stable-age builders: use ≥5 feature symbols per category to "crowd out" random additions; don't stack more than ~3 of one type.

### 1J. Block / Material modifiers
One page per block/ore ("Block of X"). Any solid block; ores and valuable blocks (Diamond Ore, Gold Block, Glowstone, etc.) drive instability. Used to specify terrain fill, feature materials, and liquids (Water/Lava). Instability is NOT a fixed per-block number — Mystcraft profiles the overworld at runtime (re-checked roughly every 100 chunks explored) and adds instability proportional to how much a block's abundance in the age exceeds its overworld baseline. Diamond costs more than Glowstone only because it's rarer at baseline. balance.cfg exposes per-block fields (instability.factor_accessibility, instability.factor_flat) but ships them blank so profiling fills them. Crucial nuance: "Void World + Dense Ores + Diamond Ore Block" produces NO instability because there's no stone to convert — instability comes from blocks actually generated, not from a symbol's mere presence.

### 1K. Biome modifiers
One page per vanilla biome, plus mod biomes registered with Forge. Special cases: Hell Biome (Stone base, no Nether water/bed ban), Ocean/Aquatic (water only below Y63), Sky Biome (Enderdragon may spawn at 0,0), Mushroom Island (mycelium top, no hostile spawns), The Void Biome (empty 33×33 platform). Biome-top replacement (grass/dirt/vegetation) only if the world's base material is Stone.

### 1L. Structural / grammar symbols
Clear Modifiers (removes dangling/unused modifiers — place at end of book; "essential once you have it"), and Sunset Color (doubles as a global default sunset when left dangling rather than adding instability).

### Instability numeric reality (critical for "more instability = more value")
- No authoritative per-symbol numbers exist. XCompWiz's balance code was never published; the only public GitHub repo (Mystcraft-Issues) contains issue-tracking + language files, no numbers.
- Only concrete community figures: Accelerated ≈275, Dense Ores ≈600 (single ~2013 decompile, self-flagged uncertain, later rebalanced).
- Danger symbols reduce instability but no number is published; the Scorched/Lightning stabilizing bonus is capped to apply once.
- Internal model = a 5-tier "card deck": Tier 1 surface-only potion debuffs → potion effects indoors/underground → dangerous environment (scorched/explosions/charged) → world destruction (meteors, decay blocks, erosion). Higher total instability draws from more dangerous tiers, faster. Total readable in-game via /myst-dbg; no published "unstable at N" threshold.
- Decay blocks (endgame instability): black, red, blue, purple (can damage the player), white (fastest, armor-penetrating, eats other decay) — the "world will be destroyed given enough time" endpoint.

**Acquisition (maps to the discovered-vs-researched axis).** Three vanilla routes: (1) an Archivist in a village (a couple of pages at his house), (2) exploring ages → cobblestone temples with pages + Sealed Notebooks (most common), (3) dungeons. Pages don't vary in quality/condition.

**Coverage estimate: ~95%** of base v0.13 symbols. Gaps: 1-per-entry enumeration of every vanilla color and biome page (predictable, 1:1 with vanilla), and mod-added symbols ("Ages of Mystcraft – Symbols" sub-mod adds many, config-toggleable). Numeric instability values: only ~10% documented.

## PART 2 — FF12 GAMBIT CATALOG

**Headline finding.** In the original PS2 FF12, gambits become purchasable incrementally as the story progresses — the "logic unlocks and gets more granular over time" model. In Zodiac Age, all gambits are purchasable after Nalbina Dungeons. Mirror the original for staged unlocking.
- Gambits unlock functionally when Penelo joins; customization opens when Balthier & Fran join.
- Slot progression: 0 → 2 → up to 12 slots, unlocked per character via the License Board.
- Structure: Target + Condition → Action, evaluated top-down; first satisfiable gambit fires; list re-evaluates each turn. Manual commands override gambits. Editing is menu-only (out of combat).
- Zodiac Age shops: Yamoora's (Rabanastre), Morning Star (Nalbina), Bashketi's (Bhujerba), Lebleu's (Archades), Waterfront (Balfonheim); plus Burrogh's limited set in Barheim Passage. Pricing: most single-condition gambits flat 50 Gil; multi-item conditions (e.g., "Ally: item AMT >10") 100 Gil; community-cited overall range 30–300 gil.

### 2A. FOE gambits
- Positional/targeting: party leader's target, nearest visible, any, nearest, furthest, targeted by ally, not targeted by ally, targeting leader, targeting self, targeting ally, targeting Vaan / Ashe / Fran / Balthier / Basch / Penelo.
- Stat-extreme (highest/lowest): HP, max HP, MP, max MP, level, strength, magick power, speed, defense, magick resist.
- HP absolute: HP > and HP < each at 500, 1,000, 2,000, 3,000, 5,000, 10,000, 50,000, 100,000.
- HP percent: HP = 100/90/70/50/30/10%; HP < 90/70/50/30/10%.
- Status (has-status): Petrify, Stop, Sleep, Confuse, Doom, Blind, Poison, Silence, Sap, Oil, Reverse, Disable, Immobilize, Slow, Disease, Protect, Shell, Haste, Bravery, Faith, Reflect, Regen, Berserk, HP Critical.
- Element weakness: fire / lightning / ice / earth / water / wind / holy / dark — each with "-weak" and "-vulnerable" variants.
- Type: undead, flying.
- Character-conditional (checks the acting character's own state before targeting a foe): character status = Blind/Silence/Bravery/Faith/HP Critical; Character HP = 100% and HP >/< 90/70/50/30/10%; Character MP < 90/70/50/30/10%.
- Count: 2+/3+/4+/5+ foes present; 2+/3+ allies present; item AMT > 10.

### 2B. ALLY gambits
any, party leader, Vaan, Ashe, Fran, Balthier, Basch, Penelo, guest, lowest HP, strongest weapon, lowest defense, lowest magick resist.
- HP %: HP < 100/90/80/70/60/50/40/30/20/10%.
- MP %: Ally MP < 100/90/80/70/60/50/40/30/20/10%.
- Status: KO, Stone, Petrify, Stop, Sleep, Confuse, Doom, Blind, Poison, Silence, Sap, Oil, Reverse, Disable, Immobilize, Slow, Disease, Lure, Protect, Shell, Haste, Bravery, Faith, Reflect, Invisible, Regen, Float, Berserk, Bubble, HP Critical.
- Count: 2+/3+/4+/5+ foes present; item AMT > 10.

### 2C. SELF gambits
Self (any); HP < 100/90/80/70/60/50/40/30/20/10%; MP < 100/90/80/70/60/50/40/30/20/10%; status = Petrify/Doom/Blind/Poison/Silence/Sap/Oil/Reverse/Immobilize/Slow/Disease/Lure/Protect/Shell/Haste/Bravery/Faith/Reflect/Invisible/Regen/Float/Bubble/HP Critical; 2+/3+/4+/5+ foes present; targeted by foe; targeted by ally; item AMT > 10.

### Granularity progression (design takeaway)
Early gambits are coarse (Foe: any, Ally: any, Self). Granularity scales along four axes that unlock later in the original game: (1) positional precision (any → nearest visible → party leader's target → targeting-a-specific-character); (2) threshold precision (has-status → HP% bands → exact numeric HP thresholds up to 100,000); (3) compound conditions (stacked lines: element-weak + flying + HP threshold); (4) stat-comparison targeting (lowest HP to finish, highest magick power, etc.). Endgame best practice: "Foe: lowest HP" and "Foe: party leader's target" for focus-fire.

**Coverage estimate: ~99%** for the piece list. Per-gambit gil prices partly documented (most 50 Gil; range 30–300); the original game's exact story-tier→gambit mapping only ~30% documented.

## PART 3 — SUPPORTING PRECEDENT BRIEFS

### 3A. Environmental tradeoff modifiers ("quirks")
**Path of Exile map "juicing" — closest analog to "more instability = more value."** Maps carry implicit/reward modifiers (item quantity/rarity, pack size, more rares) and explicit downside modifiers (e.g., players −20% elemental resistances, monster damage/speed auras) — coupled: rolling more/nastier downsides generates the reward rolls. Players juice by layering currency (Chisels → quality/quantity, Alchemy/Exalts → more mods, Vaal corruption gamble T15→T16 or brick, scarabs/sextants/Atlas tree). Fully juiced T16 ≈ 20–50 Divine Orbs/run vs near-nothing un-juiced. Core player decision: "which mods can my build actually run?" — players keep an explicit reroll/veto list of unsurvivable mods; standing advice: run the highest tier you can COMPLETE consistently. Lessons: couple reward magnitude to danger magnitude on one knob; allow per-quirk veto/reroll; make "how much danger can I safely tank" the skill expression; worst-case failure costs the run.
**Terraria secret seeds** — named quirk bundles: For the Worthy (difficulty up-tiered to secret Legendary; water→lava, live bombs, exploding bunnies), Don't Dig Up (spawn in Underworld, inverted progression), No Traps, Not the Bees, The Constant, Get Fixed Boi/Zenith (all combined; unique Mechdusa boss; world-exclusive reward). Model: named danger bundle trading survivability for uniqueness + exclusive drops.
**Risk of Rain 2 artifacts** — clean opt-in pairs: Sacrifice (monsters drop items, no chests), Glass (500% damage, 10% health, no one-shot protection), Swarms (double spawns, half monster HP → double drops), Command, Evolution, Honor.
**Don't Starve world customization** — per-parameter sliders (none/rare/default/often/always) for resources/animals/monsters plus season lengths and day/night ratios; curated presets ("Lights Out" = permanent night). Model: granular independent sliders + authored presets.

### 3B. Discovery / bestiary preview UI
Pattern: undiscovered = silhouette; discovered = full art + spawn data (icon, %, ratio, behavior). Strong examples: Pokédex silhouette convention; Slay the Spire bestiary/codex with progressive reveal of movesets and intent probability distributions (direct analog for "icon + % likelihood + ratio"); Monster Hunter ecology guide filling in weaknesses/habitat with research; collection games with spawn % (Animal Crossing Critterpedia, Stardew fish tooltips via mods, Dredge). APICO's Predictor/Microscope fits the same pattern. Doubles as completion driver AND the pre-bind planning tool.

### 3C. Passive off-world harvesting with assigned workers
**Palworld work-suitability — the model to emulate.** Each Pal has innate Work Suitabilities across 12 job types (Kindling, Watering, Planting, Gathering, Lumbering, Mining, Handiwork, Medicine Production, Cooling, Transporting, Generating Electricity, Farming); natural levels 1–8, max 10 via Essence Condenser (+1 per use, up to 4) and Applied Technique books. Base-assigned Pals auto-select tasks via work priority and generate resources without micromanagement (Ranch holds 4 Farming Pals with species-fixed drops; Vixy's datamined weighted table: Pal Sphere 59.5% / Arrow 23.8% / Gold Coin 11.9% / Bone 4.8%, higher spheres at ranks 3/4/5). Feels alive because: workers physically walk to stations with visible animations; have needs (hunger/sanity) that can break the loop; specialization genuinely matters; a Monitoring Stand pins a Pal to one job. Maps ~1:1 to "minion harvesters with gambits in anchored worlds."
**Failure mode — WoW Garrison/Mission Table:** the archetypal "menu game" — match follower traits vs mission threats toward 100%, hit go, log off; add-ons one-button-solved it; Blizzard discontinued it. Lesson: if optimal play is solvable menu-math an add-on could automate, it's a chore.
**Making it alive:** physical presence/animation, workers with needs/personality, visible in-world consequences, meaningful specialization, authored logic (gambits) so the player expresses strategy, not arithmetic. Other precedents (brief): Fallout Shelter/76 expeditions (dwellers with level/gear requirements, revivable), Slime Rancher drones, Kenshi squad automation, Suikoden / Pathfinder: Kingmaker kingdom assignments, generic mission boards.
**For the great-cost permanent anchor:** gate high-instability anchoring behind ongoing visible worker risk (harvesters can be harmed/lost in unstable worlds) rather than a one-time toll, connecting instability, harvesting, and companions into one loop.

## Caveats (from the research pass)
- Numeric instability values essentially undocumented; magnitudes are inference, directions (adds vs subtracts) documented. Version drift across Mystcraft releases; sub-mods add symbols. Vanilla Dark Lighting is visibility/undead only — the nocturnal-spawn benefit is this project's addition. FF12 pricing/story-gate data partial. FF Wiki gambits page was paywalled on direct fetch but recovered via corroborated secondary sources (Game8, Jegged).
