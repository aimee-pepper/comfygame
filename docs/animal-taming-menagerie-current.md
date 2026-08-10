# Animal taming and the Menagerie — current design

**Status:** implementation-facing first slice. Trust thresholds and the split between patience and
offering are playtest values. Combat after taming is governed by
`animal-companion-combat-current.md`.

## Design conclusion

Animals are not captured and taming is not a percentage roll. Sabine teaches the player to **attend
to one creature, recognize one reachable want, satisfy it, and receive an explicit choice from the
animal**. Success is deterministic once the visible condition is met.

This preserves the settled “companion through a want” direction without giving animals human
dialogue, a friendship meter or a stack of gifts to grind.

## Unlock and eligibility

- Recruiting Sabine and building the **Menagerie** unlocks the field **Attend** action account-wide.
  Sabine does not have to occupy a party slot for every tame.
- Attend costs one world turn and may target one visible, non-hostile animal within ordinary
  interaction range.
- Apexes, sessile hazards/flora, summoned entities, narrative occupants and already-tamed animals
  are never eligible.
- An animal the party attacked this expedition will not accept attention until a later visit. This
  is expedition state, not a permanent hidden grudge.
- Taming preserves the individual specimen's trait vector, species/world identity and appearance;
  it never creates a generic catalogue pet.

## One visible want

Attend reveals exactly one **trust condition** in behavioral prose and a compact progress line. The
condition is generated deterministically from the individual and realm, then saved. It cannot reroll
on relaunch, retreat or revisit.

The first slice uses only two condition families:

### Patient presence — universal fallback

> It keeps checking whether you are still there. Stay in sight without crowding or harming it.

- End **two world turns** inside its awareness but not adjacent to it.
- Attacking, initiating combat with, using Lure on or moving adjacent to that animal resets current
  progress; merely defending against another creature does not.
- The two-turn value is debug-tunable.

### Useful offering — only when demonstrably reachable

> It returns to the loose fibres caught along the stone. Something flexible would hold here.

- Offer one ordinary world resource meeting one visible property threshold, such as flexibility,
  insulation, hardness or reactivity.
- The generator may choose this family only if a qualifying renewable source has already been
  discovered in the current realm or the party presently carries a qualifying sample. It may not
  demand an undiscovered item, a unique reward, Gold, essence, equipment, an apex trophy or a
  carcass-only part.
- The resource is consumed only on final confirmation. The preview names the exact selected sample
  and defaults to the weakest qualifying one.

Property choice follows an observable behavior/site need, not a claim about the animal's emotions:
flexible/insulating stock for a resting place, hard stock for scraping/weighting, or reactive stock
for scent-marking. If no honest local explanation and reachable sample exist, use Patient presence.

Do not add more want families until these two prove too repetitive. Protection quests, escort paths,
feeding ecology and sparring all require systems the current creature model does not reliably
express.

## Acceptance and return

When the condition completes, the animal approaches and **Join us** becomes available. Acceptance is
not another roll.

- Confirming removes that individual from the wild map and records it immediately as a tamed animal
  travelling with the expedition.
- It does not join combat or consume a party slot until configured at the Menagerie.
- It reaches the Menagerie on any expedition resolution, including collapse or party defeat. Taming
  is a Reality-level completion and cannot be lost with the haul.
- If the player leaves without confirming, completed trust remains on that saved anchored realm but
  an unanchored world's ordinary loss rules still apply. The UI warns before departure.
- Multiple individuals of one species may be tamed because their jittered traits and histories are
  real differences. No collection bonus rewards duplicates.

## The Menagerie

The Menagerie is a place of care, observation and assignment—not a shop and not a breeding screen.
It shows every tamed animal with:

- derived name, originating realm/species and individual visual distinctions;
- the behavioral trust condition and taming history;
- known trait observations, with unknown detail remaining honest until observed;
- derived combat kit and expected role;
- current posting: Party, Menagerie or one anchored realm;
- ordinary gambit editor when the animal is eligible for party use.

There is no hard Menagerie capacity in the first slice. The five-member party limit and the effort
of finding distinct animals already create selection. If a long campaign produces an unusable list,
solve it with search/grouping and optional release—not an arbitrary kennel tax.

### Release

Release is optional, explicit and irreversible. It requires a named confirmation, never grants
resources and is unavailable while the animal is in the party or posted to a realm. Released animals
remain in the Reality bestiary/history as former companions; they are not deleted from the record or
converted into loot.

## Posting

- Party use follows the ordinary five-member cap; an animal is never a free sixth combatant.
- Menagerie posting is the safe idle state.
- Anchored-realm posting uses ordinary visible Worldwork contribution derived from the animal's
  traits only after that posting is implemented. Until then, keep the option hidden rather than
  giving every animal a generic worker value.
- Dormancy returns posted animals safely to the Menagerie.

## Complexity boundary

The first slice has no capture chance, repeated affection gifts, hunger, obedience, happiness,
breeding, eggs, fusion, mutation, permanent death, injury care timer, animal equipment, species
rarity tier or Sabine-in-party requirement. Lure moves wild creatures but never substitutes for
their trust condition.

## Debug and fixtures

Expose trust turns, offering thresholds and eligibility overrides in the debug menu. Required
fixtures:

1. Patient presence completes deterministically and resets only from named violations.
2. Offering is never generated without a known reachable qualifying source/sample.
3. Taming survives collapse and does not enter the active party automatically.
4. Reopening the same anchored realm cannot reroll the animal's condition.
5. Apexes and previously attacked animals reject Attend for the correct visible reason.
6. Party cap, dormancy and save migration cannot delete a tamed animal.
