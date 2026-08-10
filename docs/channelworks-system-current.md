# The Channelworks — Current System Direction

**Status:** Current design; numerical balance and final item names remain placeholders  
**Owner:** Oda, channelwright

## Core rule

A Channelworks weapon is a crafted **emanation housing** held and aimed like a weapon. It occupies
the ordinary weapon slot but attacks on a different defensive axis:

- lower raw damage than an equivalent physical weapon;
- emanation damage bypasses ordinary armour;
- Ward and relevant insulation/resistance reduce it;
- a successful attack applies a weak form of its attuned existing affliction;
- it cannot accept an Apothecary weapon coating;
- it uses ordinary attacks and cooldown skills—there is no mana, charge wallet or ammunition.

| Attunement | Affliction | Character |
|---|---|---|
| **Heat** | Burn | Short, hard lingering damage |
| **Caustic** | Poison | Slower, longer lingering damage |
| **Light** | Dazzle | Accuracy pressure rather than damage |

Freeze, shock and electrical Arc damage are not introduced. Repeated applications refresh or replace
a weaker instance under existing status rules; they do not stack copies.

## Why coatings remain useful

| Physical weapon + coating | Channelworks weapon |
|---|---|
| Full physical damage and triangle matchup | Lower raw, armour-bypassing emanation damage |
| Coating is consumed on one successful strike | Attunement persists |
| May choose bleed through Briar Oil | No bleed attunement |
| Available before late specialist infrastructure | Requires Oda and prepared attunement materials |
| May carry apex physical rules | Apex weapons are not valid housings initially |

## Three reach families

| Family | Reach | Identity | Trade-off |
|---|---|---|---|
| **Contact housing** | Close | Direct release through a channelled blade, gauntlet or compact implement | Highest raw/affliction potency; accepts melee exposure and retaliation |
| **Conduit housing** | Mid | A stable path across a controlled gap: rod, articulated implement or guided line | Balanced damage, potency and reach; no extra exception |
| **Projection housing** | Far | Lens and frame project a narrow release | Lowest raw/potency; gains far-reach safety and opening control |

The first implementation needs one authored weapon per reach family and three attunement variants,
for nine configurations. Do not multiply them by pierce/crush/rend: Channelworks uses the emanation
axis rather than creating a fourth corner of the physical triangle.

## Craft and modification flow

1. **Auber's Distillery** produces an attuned crystal/item from essence and selected world resources.
2. **Oda's Channelworks** combines it with a close, mid or far housing recipe.
3. The weapon records family and attunement as item properties, not currencies.
4. Oda may retune it at base by consuming another prepared attunement and a refitting cost. Retuning
   is unavailable during a run.
5. Halloway owns ordinary repair/salvage where applicable; Oda owns housing integrity, retuning and
   advanced Channelworks upgrades.

Use authored recipes first. Arbitrary conversion of every physical weapon would create apex,
coating, silhouette and save-migration combinations before it adds a worthwhile choice.

## Progression

- **Recruitment:** one basic Conduit housing and first attunement recipe.
- **Dependency-safe arrival:** Oda carries one damaged Heat Conduit with an intact, non-recoverable
  core. Building the Channelworks restores this authored fixture; repeatable cores still require
  Auber's later Distillery.
- **Next tier:** Contact and Projection housings; retuning at base.
- **Later tier:** mutually exclusive containment choices—improve raw output or affliction potency,
  not both automatically.
- **Final tier:** one specialist property per family only after playtesting; do not pre-author chain,
  area and self-return effects merely to fill the tree.

Numbers, costs and exact tier placement are placeholders. The structural decision is the lower-raw,
armour-bypass, Ward-countered, persistent-attunement trade.

## Interaction rules

- **Ward/insulation:** Intended counter; UI must explain reduced output.
- **Snuff:** Removes a foe's active emanation, not a party weapon's stored attunement.
- **Ashe / Ground:** May later receive or redirect a release, but Ashe is not required to use Oda's shop.
- **Coatings:** Cannot be applied; item UI must say so before selection/consumption.
- **Apex weapons:** Not valid housing bases initially.
- **Damage triangle:** Pierce/crush/rend remains physical; emanation is a separate defensive axis.
- **Dazzle:** Refreshes rather than stacking miss chance.

## Oda's teaching and Arc

Oda does **not** teach a world-writing focus. Her diary knowledge page teaches an exclusive
**emanation housing schematic**, a research lead/recipe usable after recruitment.

The prior **Arc** proposal is retired because:

- it lacks an independent necessary world-writing purpose;
- its electrical implication conflicts with heat/caustic/light emanation;
- adding a rune to complete a ledger repeats the rejected Reed/Pulp mistake.

## Complexity check

The system adds one equipment property (`attunement`) and reuses weapon slot, reach,
heat/caustic/light, burn/poison/dazzle, Ward, insulation, cooldown skills, Auber's item outputs and
authored recipes. It adds no mana, charge counter, ammunition, freeze/shock, arbitrary weapon
conversion or new world focus.

## Engineering handoff order

1. Prototype one Conduit weapon with one attunement and armour/Ward interaction.
2. Verify persistent weak affliction does not make basic attacks dominate physical weapons.
3. Add the other attunements through the same rule.
4. Add Contact and Projection profiles.
5. Add retuning after item/save behaviour is proven.
6. Add higher tiers from playtest evidence.
