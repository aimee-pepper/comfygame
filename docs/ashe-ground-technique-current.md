# Current Design — Ashe's Ground Technique

**Status:** reversible combat-balance decision. The technique's protective identity is current;
potency, duration and cooldown are playtest values.

## Player-facing rule

> **Ground** — Prepare to receive the next emanation harm that would strike anyone else in the party.
> Redirect it to Ashe and halve its damage. Any affliction it carries is attempted against Ashe.

Working values:

- lasts **2 rounds** or until triggered;
- catches **one** emanation-damage event;
- **4-round cooldown**;
- may be used without selecting an ally;
- does nothing to pierce, crush or rend harm.

## Resolution order

1. An emanation event selects a party target other than Ashe.
2. Ground consumes itself and changes the target to Ashe.
3. Apply Ground's 50% reduction.
4. Apply Ashe's ordinary emanation resistance/insulation.
5. Deal the remaining armour-bypassing damage to Ashe.
6. Attempt the event's burn, poison or dazzle against Ashe through ordinary guard/resistance rules.

If Ashe was already the original target, Ground does not trigger; their ordinary resistance applies.
If Ashe is incapacitated, Ground expires and cannot redirect harm. It cannot chain with another
interception to bounce damage repeatedly.

## Why this shape

- It makes Ashe protective without duplicating Bryn's general attack-drawing role.
- It answers the armour-bypassing harm Ashe specifically understands.
- The player actively consents to the bodily cost; Ashe is not a passive party appliance.
- One event is legible and bounded. A whole round of redirected area damage could erase Ashe without
  the player understanding the accumulated promise.
- It uses existing damage, resistance, affliction and cooldown concepts rather than adding a charge,
  mana or emanation meter.

## Relationship to adjacent tools

- **Ward:** reduces anticipated incoming harm; does not change who receives it.
- **Snuff:** stops a foe's continuing emanation source.
- **Draw Off:** changes a foe's ordinary target pressure broadly.
- **Stonebark:** may prevent the redirected affliction on Ashe, but not its damage.
- **Ground:** protects another person from exactly one emanation event by receiving it bodily.

Ground is part of Ashe's starting kit, not their exclusive diary teaching. Their diary still teaches
**Foe: emanating**, which makes automation against emanating foes possible.

## Debug/playtest controls

- damage multiplier (working `0.5`);
- duration (working `2` rounds);
- cooldown (working `4` rounds);
- whether an affliction accompanies redirected harm (current: yes).

