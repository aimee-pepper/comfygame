# Tavern and random companions — current design

**Status:** Current structure with playtest-placeholder spawn and visitor numbers.  
**Owners:** Orsa owns the Tavern; generated companions own no station.

## Critical capacity correction

The party limit is five combatants including the Binder. It is **not** a total roster limit.
All named travellers are recruitable, and companions may be assigned Home or to anchored realms;
therefore the persistent roster must not be capped at five.

The Firepit/Tavern shows assignment and availability. The Party screen edits combat configuration.
Neither implies that only five people may live at base. If a later home-capacity system is desired,
it must never strand a found named traveller or reverse recruitment.

## Random companions

Random companions are people encountered incidentally in authored worlds. They are available from
the opening, before a named-traveller hunt is complete.

They have:

- a generated stable identity, name/pronouns, short voice set and visual descriptor;
- normal character stats, level, shared combat trees and one coherent authored starting lean;
- a visible Worldwork value using the ordinary companion system;
- one recruitment want;
- no diary, signature, exclusive teaching, station ownership or private combat tree.

Once generated, a person is a persistent individual. The same unmet person may recur in later worlds
or visit the Tavern; the game does not silently reroll their name, build or want. Recruitment is
permanent under the finality pillar.

## World appearance

Worlds may generate at most one new random-companion encounter in v1. The chance is additive and
capped, with debug-exposed placeholder inputs:

- 4% base;
- +8 percentage points if the world contains at least one site;
- +0–8 points across the world's greed band;
- +0–8 points across produced-life abundance;
- hard cap 20%.

Sites, greed and life raise likelihood but are never requirements. This preserves accidental early
meetings and prevents a single “recruitment world” recipe. A generated companion occupies a safe,
reachable tile near a site when possible and otherwise an interior traversable tile.

## Wants

A random companion asks for exactly one legible, finite thing. The want is rolled only from options
the save can currently satisfy or deliberately pursue:

| Want | Completion |
|---|---|
| **World resources** | Give a stated quantity of a known ordinary resource |
| **Material sample** | Give one sample meeting a visible kind/property/grade threshold |
| **Knowledge** | Show a known focus, identified curio family or completed diary |
| **Place** | Return after visiting a stated known site family or reachable condition |
| **Creature record** | Show an existing Bestiary species record, never capture a creature |
| **Passage** | Some opening companions simply want safe passage home |

Generated wants do not require a particular unrecruited person, an undiscovered exclusive diary
focus, an unknown named place, a unique/apex item or a world condition the current hand cannot write.
No random want consumes a one-off narrative object. The reward is recruitment itself; do not add a
relationship meter or bargaining minigame.

If fulfilled in-world, the person joins on return. If not, meeting them records their identity and
want and makes them eligible to recur or visit the Tavern.

## Firepit → Tavern

The Firepit exists from the start and holds the player's recruited community. Recruiting Orsa
upgrades that same station into the Tavern; no second base door is created.

On each resolved expedition, the Tavern refreshes up to three visitor seats from:

1. previously met, unmet random companions;
2. previously encountered but unresolved visitors, if later non-companion visitors are added;
3. authored cast visitors only when their current narrative state explicitly permits it.

Named diary travellers never become random recruits at the Tavern. Their signature hunt remains the
price of recruitment, and once genuinely found they join without an additional want.

At the Tavern the player may:

- review a visitor's identity, build and exact want;
- satisfy material, resource, knowledge or record wants immediately;
- receive a qualitative rumour or whereabouts clue already valid for that visitor;
- invite an eligible met person to remain in the visitor pool;
- rest through the existing rest system.

Visitors refresh on expedition resolution, never wall-clock time. An unresolved met person remains
in the global met pool even when not currently seated; missing a visit never loses them. Orsa's
upgrades may improve visitor-seat count, recurrence weighting, clue clarity and rest, but never sell
people or guarantee named-traveller placement.

## Complexity boundaries

- No social currency, affection meter, relationship simulation or hospitality minigame.
- No procedural diaries or exclusive teachings.
- No permadeath, expiration or irreversible refusal.
- Generated dialogue is short and template-driven; authored travellers retain the narrative focus.
- Party composition remains five including the Binder; roster and assignment capacity are separate.

## Implementation invariants

1. `maximumPartySize` must never gate persistent recruitment or roster reconciliation.
2. Generated identity, want and build are saved at first encounter.
3. Visitor rotation cannot erase a met person or advance while idle.
4. Want validation runs at generation and after content migrations; an invalid old want receives a
   comparable reachable replacement without changing the person.
5. Bulk inventory actions protect items reserved for an active want unless the player explicitly
   unlocks them.
