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

## First-prototype contract

The existing `DistilledCore` receipt is the source of attunement and potency. Construction transfers
that receipt into a new optional Channelworks profile on the weapon; it must not overload
`DamageKind`, `frozenReactivity`, a coating slot or a catalogue-name check. The profile persists:

- housing family/reach;
- heat, caustic or light attunement;
- core potency and provenance receipt;
- construction tier and any later mutually exclusive containment choice;
- profile/recipe version.

Old gear decodes with no Channelworks profile and remains physical. A Channelworks weapon has no
physical triangle kind for its ordinary attack and cannot silently fall back to poison via the
generic reactive-weapon rule.

For a reversible first comparison, derive the actor's normal pre-matchup attack, then use these
DEBUG-visible profiles:

| Housing | Raw multiplier | Status strength | Reach |
|---|---:|---:|---|
| Contact | 0.80 | 0.22 × core potency | Close |
| Conduit | 0.70 | 0.18 × core potency | Mid |
| Projection | 0.60 | 0.14 × core potency | Far |

Round raw damage and status strength only at the final integer boundary, with minimum 1 on a
successful legal hit. These are **playtest coefficients**, not settled identity. Heat and Caustic
turn strength into weak burn/poison damage under the existing status duration rules; Light applies
Dazzle with no invented damage-over-time. Reapplication follows the existing replace/weaker-refresh
policy.

The attack enters combat as `Harm.emanation(attunement)`: skip ordinary armour and physical matchup,
then apply the existing exact attunement Ward and relevant insulation/resistance. “Armour bypass”
does not mean true damage. Accuracy, Dazzle miss, target legality, reach, Ground redirection, defeat,
logging and saved combat RNG remain on the shared attack path.

Construction and retuning use preview-then-atomic commit. A failed stale commit consumes neither
core, materials nor Essence. Retuning replaces the saved core receipt and returns no old core; this
prevents reversible conversion from becoming free catalyst/sample duplication. The damaged Heat
Conduit fixture is explicitly non-salvageable until restored.

### One-time restoration versus repeatable construction

The initial fixture is restored by the **building transaction itself**. The Channelworks screen must
not then label its Heat-core conversion button as though that same restoration is still pending.

- Persist a durable `odaFixtureRestored`-equivalent receipt when construction grants the authored
  recipe-version-0 Heat Conduit. Item location is not the receipt: the fixture may later be equipped,
  stored, sold, recycled or lost.
- On tolerant load reconciliation, an unlocked Channelworks with no receipt adopts an exact existing
  Oda-authored recipe-version-0 fixture if one exists; otherwise it grants that one fixture and marks
  the receipt. It never grants a second copy merely because the original moved or left inventory.
- The screen first confirms **Oda's restored conduit** and where it currently is when known. Its
  separate repeatable verb is **Build another conduit**, consuming one player-made Heat core.
- With no Heat core, explain that repeatable cores come from Auber's Distillery. Do not imply the
  already-restored authored fixture is missing or ask the player to build it again.

This distinction keeps Oda useful before Auber while making Auber the source of expansion rather
than retroactively charging for Oda's first usable weapon.

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
**emanation housing schematic**, a recipe-family unlock usable after recruitment. It opens the later
Contact and Projection housing recipes. It does not gate the station, Oda's restored starter Heat
Conduit or the repeatable basic Conduit route; learning it grants no weapon, core or recipe output.

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

## Required first-slice fixtures

1. The same base attack produces different but ordered Contact > Conduit > Projection raw output.
2. All three housings bypass ordinary armour, but matching Ward and insulation/resistance still
   reduce them; physical matchup never changes their result.
3. Heat/Caustic/Light produce only Burn/Poison/Dazzle and never generic reactive poison, freeze,
   shock or a physical damage kind.
4. Coating selection rejects the weapon before consuming a coating.
5. Ground redirection and force-quit resume preserve the exact attunement, target and combat RNG.
6. Old gear/save fixtures decode without a Channelworks profile; constructed and retuned receipts
   round-trip with provenance intact.
7. Inventory-full, missing-core and stale-preview failures are atomic.
8. Fresh construction, unlocked legacy migration, fixture moved/equipped/sold and repeated relaunch
   prove exactly one authored restoration receipt; only the separately labelled repeatable action
   consumes a Heat core.
