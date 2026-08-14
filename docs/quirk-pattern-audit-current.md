# Quirks — paired-tradeoff pattern, not a second world layer

**Status:** settled current boundary. Paired tradeoffs remain a system-wide principle; the separately
rolled Quirk catalogue and veto/reroll affordance are retired.
**Updated:** 9 Aug 2026

## Audit result

The old Terrain/Biome/Bounty/Quirk slot taxonomy is already a compatibility fossil. Current pages
write linked targets, focuses and qualifiers, and unwritten targets resolve from the world seed.
There is therefore no honest empty “Quirk slot” for a second random modifier deck to fill.

What remains valuable is the settled design rule behind the old name: a striking world request
should carry both opportunity and consequence. The current pressure system already produces those
pairings:

- unusual composition increases greed, loot and instability through the ordinary book rules;
- light, water, ground and ecology affect navigation, visibility, resources and supported life;
- Danger runes are explicit player bargains with visible hazards and an authored Stability trade;
- contradictions create observable world consequences rather than an unrelated modifier card.

This is enough systemic texture. Adding an independent quirk roll would charge or reward the same
world twice and make it harder to understand which words caused what.

## Current identities

### Dim Sky

Dim Sky remains a starter learned compound: **great Cloud attached to Illumination**. Its current
direct play cost is `visionDelta = -1`. Its lower light also changes flora support, creature sensory
allocations and the day/night cast through the resolved pressure model. Those derived consequences
are the correct way to deliver its nocturnal identity.

The compound still carries `enemyTierDelta = +1` and a legacy authored creature-table weight. The
authored creature table is now dead beside generated species, and the flat tier increase is a
parallel hostility rule rather than a consequence of dimness. Recommended migration:

1. preserve great Cloud, reduced visibility and every pressure-derived ecological consequence;
2. remove the legacy creature-table modifier when its compatibility path is deleted;
3. retire the flat tier bump once tests confirm generated-world danger remains honest;
4. update the blurb if the world-longevity claim is not visibly supported by current stability
   projection for representative Dim Sky pages.

The last two items are not authorized silently. DRQ-099 now covers the coherent six-compound
comparison in `compound-hostility-fossil-audit-current.md`; do not remove only Dim Sky's tier and
leave the same parallel rule hidden on five peers.

### Gilded Veins

Gilded Veins is a starter **Substrate compound**, not a member of a Quirk class: great Gold plus
faint Crystal. Its wealth and instability should emerge from resolved composition and greed. Its
legacy yield, creature-table and tier fields belong to the same compatibility cleanup, not to a new
quirk catalogue.

### Danger runes

Storm, Blight, Swarm, Predation, Miasma, Tremor and Peace stay distinct. Their explicit Stability
trade is legitimate because the player is choosing a named bargain; it does not restate the normal
material value of a pressure contribution. Do not relabel them as quirks.

## Recommendation: retire veto/reroll

Do not build the older PoE-style veto/reroll affordance.

The player already controls a world by writing some targets and deliberately leaving others
unwritten. Once bound, the unwritten result is part of that world's identity rather than a bad
modifier to cycle for currency. If random worlds prove too punishing, use the existing honest safety
valves—pre-bind ranges where knowledge permits, portal/Waystone return, partial-failure recovery and
debug-tunable opening safety—rather than an opaque reroll economy.

A future named **world condition** is still possible, but it must be a derived/tagged description of
resolved facts with a real consumer. It must not be an independently rolled modifier deck.

## Verification and cleanup boundary

1. Dim Sky always reduces world vision by exactly one before party and torch bonuses.
2. Its resolved light affects supported flora and creature traits without a hand-authored species.
3. Removing legacy creature weights cannot change generated cast identity.
4. Compare all six ordinary flat tier compounds with and without their bump before coherent
   retirement; do not hide a meaningful difficulty drop behind cleanup wording.
5. Gilded Veins wealth and stability projection remain explained by composition/greed after legacy
   fields are removed.
6. Old saves containing the `quirk` slot continue to load as their stable compound IDs.
7. No UI promises a separate Quirk category, veto or reroll.
