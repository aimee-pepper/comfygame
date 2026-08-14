# Combat Trees — full spec

> **Current economy:** `combat-progression-current.md` resolves the implemented depth, point income,
> level cap and respec questions below. This file remains the node-content authority.

> **Current structure:** the 72 node effects remain content authority and are arranged by the
> current five-depth fan-and-fork graphs in `combat-tree-true-graph-current.md`. The live
> ordered depth ladders are legacy implementation, not current design.

> **Current semantics:** `combat-node-viability-current.md` owns exact triggers, stacking, targeting
> and receipts. Many live `Loadout` fields currently have no gameplay consumer; their JSON presence
> does not prove that the node works.

**Supersedes `combat-trees.md`**, which had the structure but no nodes. This has every branch and every node.

**Three trees. Three lanes each. Eight ranks per lane. 72 nodes total.**

All numbers **[PLACEHOLDER]**. Skill names in **bold** are skills that already exist in `skills.json` — they now have homes.

---

## 1. The shape

| Tree | Branch | Branch | Branch |
|---|---|---|---|
| **Offense** | **Force** | **Precision** | **Swiftness** |
| **Defense** | **Fortitude** | **Protection** | **Evasion** |
| **Craft** | **Venom** | **Emanation** *(legacy ID `kindling`)* | **Shadow** |

**A class is where you spent.** Nobody is assigned one.

**Max level: 24 standard points, enough for three eight-node capstone routes.** A player may take
one route through each tree, specialize more heavily in one tree, or leave several partial routes.
The three chosen capstone lanes still produce the established 27 named combinations when one
capstone is owned in each tree. Authored calling-lean points sit above the standard budget.

### Node economy — [PROPOSAL]

- **8 nodes per branch, 1 point each.** Depth comes from nodes getting *stronger*, not costlier — easier to reason about on a phone.
- **24 points** completes three valid capstone routes.
- **1 point per level → max level 25.**
- **Partial investment is legal.** The cap is on total points; prerequisites and the five-node
  capstone commitment determine which routes remain reachable.

### Node kinds

Each branch runs **passive → skill → passive → skill → passive → capstone**, so every branch gives two active skills and a defining capstone.

---

## 2. OFFENSE

### Force — crush, stagger, weight
*Answers armoured foes. Costs initiative.*

| # | Node | Effect |
|---|---|---|
| 1 | Heavy Hand | +crush damage |
| 2 | Follow Through | Bonus damage against high-armour foes |
| 3 | **Overbear** ⚔️ | Heavy crush; you act last next turn |
| 4 | Bracing Stance | +damage on a turn you didn't change rank |
| 5 | Stagger | Crush hits may slow |
| 6 | **Shatter** ⚔️ | Permanently reduces a foe's armour for the fight |
| 7 | Momentum | Damage scales with how low your initiative is |
| 8 | **Breaking Blow** ★ | Ignores armour entirely and staggers |

### Precision — pierce, gaps, finishing
*Answers plated foes. Costs raw damage.*

| # | Node | Effect |
|---|---|---|
| 1 | Keen Eye | +pierce damage |
| 2 | Weak Point | Bonus against dense coverings |
| 3 | **Pry** ⚔️ | Ignores armour, low damage |
| 4 | Steady Hand | +critical chance |
| 5 | Exploit | Bonus damage to foes carrying a status |
| 6 | **Finish** ⚔️ | Large damage to foes below a threshold |
| 7 | **Anatomy** | **Butchery yields improve** — ties Precision to the material chain |
| 8 | **Killing Stroke** ★ | Foes below a threshold die outright |

### Swiftness — initiative, extra actions, multiple targets
*Answers swarms, and anything you want dead before it acts.*

| # | Node | Effect |
|---|---|---|
| 1 | Quick Step | +initiative |
| 2 | Light Touch | Reduced initiative penalty from heavy gear |
| 3 | **Quicken** ⚔️ | Act twice next turn, then skip one |
| 4 | Second Wind | Recover a little on a kill |
| 5 | Flurry | Attacks strike a second foe |
| 6 | **First Strike** ⚔️ | Your first committed attack gains force and cannot be retaliated against |
| 7 | Cascade | Each kill grants initiative |
| 8 | **Blur** ★ | Two full actions in a turn, once per fight |

---

## 3. DEFENSE

### Fortitude — HP, armour, resistance
*Answers attrition. Costs speed.*

| # | Node | Effect |
|---|---|---|
| 1 | Thick Hide | +max HP |
| 2 | Iron Skin | +armour |
| 3 | **Brace** ⚔️ | Reduce all incoming damage for a turn |
| 4 | Constitution | Resist bleed and poison |
| 5 | Endurance | Reduced damage taken below half health |
| 6 | **Ward** ⚔️ | Reduce one damage type for two turns |
| 7 | Unyielding | Cannot drop below 1 HP, once per fight |
| 8 | **Immovable** ★ | Armour applies to **every** damage type, pierce included |

### Evasion — dodge, initiative, mobility
*Answers single heavy hitters. Costs toughness.*

| # | Node | Effect |
|---|---|---|
| 1 | Footwork | +evasion |
| 2 | Light Frame | +initiative |
| 3 | **Sidestep** ⚔️ | Dodge the next attack outright |
| 4 | Slippery | Cryptic creatures ambush you less often |
| 5 | **Fall Back** ⚔️ | Change rank without spending the turn |
| 6 | Feint | Attacking raises your evasion until your next turn |
| 7 | Untouchable | Evasion rises each turn you go unhit |
| 8 | **Ghost** ★ | The first attack against you each fight always misses |

### Protection — guarding, drawing, sharing
*Answers protecting a fragile back rank.*

| # | Node | Effect |
|---|---|---|
| 1 | Bulwark | +personal armour and a larger same-rank ally armour bonus |
| 2 | Watchful | An ordinary ambush still occurs, but does not steal the opening order |
| 3 | **Draw Off** ⚔️ | Force a foe to target you |
| 4 | Cover | Take a share of damage aimed at the back rank |
| 5 | Shieldwall | Front rank gains armour while you stand |
| 6 | **Interpose** ⚔️ | Take a hit meant for an ally |
| 7 | Rally | Allies recover a little when you kill |
| 8 | **Guardian** ★ | While you stand, the back rank cannot be targeted at all |

---

## 4. CRAFT

*Not magic — this world has none. Craft is alchemy, concealment and emanation: what the Apothecary and the Emanant actually do.*

### Venom — toxins, damage over turns, coatings
*Answers high-HP foes, and anything armour would blunt.*

| # | Node | Effect |
|---|---|---|
| 1 | Tainted Edge | Attacks apply weak poison |
| 2 | Apothecary's Hand | Consumables are more effective in your hands |
| 3 | **Envenom** ⚔️ | Coat a weapon for several hits |
| 4 | Virulence | Poison lasts longer |
| 5 | **Flense** ⚔️ | Bleed scaling with the foe's covering |
| 6 | Corrode | Your poison also reduces armour |
| 7 | Distiller | Coatings cost fewer materials |
| 8 | **Blight** ★ | Poison spreads between adjacent foes |

### Shadow — concealment, ambush, avoidance
*Answers fights you'd rather not have, and opening the ones you want on your terms.*

| # | Node | Effect |
|---|---|---|
| 1 | Quiet Step | Fewer encounters trigger in the world |
| 2 | Low Profile | Creatures detect you at shorter range |
| 3 | **Conceal** ⚔️ | Untargetable for one turn |
| 4 | Opportunist | Bonus damage from concealment |
| 5 | **Ambush** ⚔️ | Open a fight with a free attack |
| 6 | Vanish | Leave a fight without the stability cost, once per run |
| 7 | Shadowed | The whole party is detected later |
| 8 | **Unseen** ★ | Begin every encounter concealed |

### Emanation *(new ID `emanation`; legacy decode ID `kindling`)* — projection, affliction and resistance
*Answers warded and elemental foes.*

| # | Node | Effect |
|---|---|---|
| 1 | Sparkhand | Attacks apply weak burn |
| 2 | Insulation | Resist one element |
| 3 | **Emanation Strike** ⚔️ | Strike with heat, caustic or light emanation, applying burn, poison or dazzle |
| 4 | Attunement | Your elemental damage scales |
| 5 | **Snuff** ⚔️ | Remove a foe's emanation |
| 6 | Quench | Cure one emanation affliction on an ally |
| 7 | Conduction | Elemental damage chains to a second foe |
| 8 | **Emanant** ★ | You carry an emanation permanently |

---

## 5. Builds these produce

| Branches | Emerges as |
|---|---|
| Swiftness · Evasion · Shadow | **Rogue** *(Aimee's example)* |
| Force · Fortitude · Kindling | **Knight** |
| Precision · Evasion · Venom | **Hunter** |
| Force · Protection · Fortitude | **Bulwark** |
| Precision · Fortitude · Shadow | **Assassin** |
| Swiftness · Protection · Kindling | **Skirmisher-captain** |
| Force · Evasion · Venom | **Duelist** |
| Precision · Protection · Kindling | **Warden** |
| Swiftness · Fortitude · Venom | **Harrier** |

**Twenty-seven in total**, each permanently distinct.

## 6. Callings, leans, and generated companions

**A calling gives a starting lean, never a limit.** Halloway the smith begins with a point or two in Force; nothing stops you making her a knife-fighter.

Generated people arrive at the Binder's level with a visible, coherent three-branch plan and their
earned points already spent. They use the ordinary full Essence Spring respec. Exact persistence and
arrival rules are current in `generated-companion-arrival-builds-current.md`.

“Wild companion” is retired here because it confused generated people with tamed animals. Animals
do not use human trees; see `animal-companion-combat-current.md`.

## 7. What this gives the existing skills

**All thirteen built skills now have a home**, and the gaps show what's missing:

| Existing skill | Branch |
|---|---|
| Overbear | Force 3 |
| Pry | Precision 3 |
| Quicken | Swiftness 3 |
| Ward | Fortitude 6 |
| Fall Back | Evasion 5 |
| Draw Off | Protection 3 |
| Flense | Venom 5 |
| Snuff | Kindling 5 |
| Steady | *(→ Kindling 6, Quench)* |
| Sight · Read | **no branch** — see below |
| Rout | *(→ Shadow 6, Vanish)* |
| Unbind · Mend | baseline, untreed |

**Sight and Read don't fit any of the nine**, and that's informative: they're **knowledge** skills in a game whose progression is literacy. **[PROPOSAL]** they belong to the **analysis** progression — instruments and tiers — rather than to combat, which also gives `clause-audit.md` F2 another hook to hang on.

**Nodes needing new skills:** Shatter · Finish · First Strike · Brace · Sidestep · Interpose · Envenom · Conceal · Ambush · Emanation Strike — **ten new skills**, plus nine capstones.

## 8. Historical open questions — current status

1. **Branch depth:** current at 8; playtest timing.
2. **Point income:** current at 1 per level, cap 25.
3. **Respec:** implemented as paid full respec at the Spring.
4. **Animals:** current placeholder uses no tree; see `animal-companion-combat-current.md`.
5. **Discipline naming superseded by the graph migration:** new identity is `emanation`; decode-only
   `kindling` maps one-way to it so old saves remain valid without two writable names.
6. **Whether capstones are too strong.** Guardian and Killing Stroke especially — both are near-absolute, and near-absolute is what a capstone should be, but they want testing.
