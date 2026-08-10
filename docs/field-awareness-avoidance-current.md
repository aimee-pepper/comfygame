# Field Awareness and Encounter Avoidance — Current Direction

**Status:** awareness/Shadow/Lure foundation implemented locally and green at 837 tests on 9 Aug
2026; signed phone build succeeded, but device installation and git checkpoint remain pending because
the approval service reached its usage limit. Scent Mask remains design-ready, not implemented;
exact durations/costs are reversible DEBUG values. Prompted by Aimee's playtest request for skills/
items that reduce animal aggression, help avoid encounters and make a party harder to notice.

## Core rule

Avoidance changes readable field awareness before contact. It does not silently delete an encounter
after the player steps onto it, roll an unexplained “nothing happened” chance, or make apexes vanish.

Every roaming creature has visible states:

1. **unaware** — follows ordinary movement/ecology;
2. **alert** — has noticed a sign but has not committed to pursuit; show a redundant icon/outline and
   the tile/party that drew its attention when known;
3. **pursuing/awake** — ordinary current aggression and encounter rules.

Implement this as a tolerant persisted awareness state on `WorldEnemy`. Old `isAwake == true`
migrates to pursuing; old `false` migrates to unaware. Alert records the world turn and reason that
created it. If the party remains within an effective notice radius on the next world action, alert
becomes pursuing; if the party leaves every contributing radius, it returns to unaware. Direct
adjacency/contact, party attack or an explicitly loud disturbance bypasses alert and wakes the
creature immediately. `isAwake` may remain as a compatibility projection during migration, but two
independent sources of truth are not allowed.

Detection radius remains game-owned. Target/path preview may show whether the next committed step
enters a known creature's notice radius, modified by current party effects. Hidden creatures do not
leak through this preview.

## Existing Shadow branch becomes truthful

The live Shadow branch already promises the requested playstyle. Wire its existing nodes into the
field system before inventing another skill tree:

- **Quiet Step:** replace the opaque legacy `encounterChance -0.25` meaning with deterministic first
  hesitation. The first time an unaware ordinary roaming creature would wake solely from this
  party's movement, it becomes alert for one world turn instead. Moving away can avoid pursuit;
  moving closer/remaining exposed lets it wake normally. Track once per creature/party contact, not
  a reroll every step.
- **Low Profile:** if at least one active traveller owns it, ordinary notice radius is reduced by 1.
  Multiple owners do not stack the same node.
- **Shadowed:** if at least one active traveller owns it, the active party reduces ordinary notice
  radius by another 1. Multiple owners do not stack the same node. Clamp to the honest minimum
  established by concealment rules; adjacency/contact is never ignored.
- **Conceal, Opportunist, Ambush, Vanish and Unseen** retain their combat meanings. Vanish's free
  Unbind is the post-contact escape route; do not duplicate it as universal field immunity.

Only active travel-party skills apply. A skilled person left at Home or assigned to a realm provides
no field concealment.

Quiet Step likewise applies once per party and does not gain extra hesitation turns from multiple
owners. Persist each creature's one-use hesitation flag in the active world so save/relaunch and
stepping away cannot refresh it.

## Item access

### Scent Mask — recommended Apothecary addition

A real playtest need now justifies replacing the held, incoherent Traveller's Token slot rather than
preserving an arbitrary catalogue count.

- Field consumable; applies **Masked scent** to the active party for a reversible starting value of
  12 world turns.
- During the effect, ordinary animals cannot progress from unaware to pursuing solely through scent;
  they enter alert/hesitation first. Direct sight at their adjusted sight radius, adjacency, attack,
  harvest disturbance or an already-alert follow-up may still wake them.
- It has no effect on hostile flora, constructs/guardians, apexes or already active combat.
- HUD shows remaining world turns and the next-step preview names when scent masking matters.
- Working recipe direction: one Reagent plus one animal-associated world resource and modest essence;
  exact resource/grade/cost waits for economy simulation so the item is reachable before it is moot.

This is a preparation choice, not a universal “no encounters” potion.

For the live four-channel sensory model, “scent-only” means **chemical sensing (`chemo`) is the
deciding channel at the current distance**. Preserve the existing combined detection calculation:
compute its ordinary radius once with all channels and once with the chemo contribution removed. If
the party is inside the first radius but outside the second, Masked scent earns the alert turn. If
vision, mechano or thermo still places the party inside the second radius, the item does not block
waking. This avoids inventing a new smell stat or changing baseline creature detection merely to
support the item; DEBUG names the contributing channels rather than translating all nonvisual sense
into “scent.”

The current native calculation is additive, not “take the best sense.” Keep that grammar exactly:

`all = vision × nightFactor + mechano + chemo + thermo`

`withoutChemo = vision × nightFactor + mechano + thermo`

Each sum is divided by the existing pressure scale, multiplied by the existing default radius,
rounded once, then receives the same openness bonus and field-skill radius modifiers. Do **not**
renormalize the remaining channels after removing chemo; doing so would make Scent Mask strengthen
other senses. Clamp both final radii to adjacency minimum 1. The mask matters when
`distance <= allRadius && distance > withoutChemoRadius`.

Masked scent and Quiet Step do not stack into two consecutive alert turns on one approach. Evaluate
the mask first so using the prepared item does not silently consume a permanent skill's one-use
hesitation. Record that this creature received masked-scent grace during the current continuous
contact. Leaving its full all-channel radius clears that contact record, allowing another masked
approach while the timed effect remains; Quiet Step's per-creature used flag never clears during the
world. An alert creature that remains in range on the following action pursues even if the mask is
still active—the item creates a readable chance to disengage, not indefinite scent immunity.

### Existing Lure

Keep Lure as the risky opposite tool: it wakes/draws one ordinary roaming creature, allowing the
player to deliberately move its route or arrange an encounter. Its eventual targeting UI must make
the affected visible creature and destination/party draw explicit. It does not affect apexes or
hostile flora and cannot target an undiscovered creature.

## Boundaries

- Apexes remain visible, stationary, opt-in challenges. Avoidance neither hides nor despawns them.
- Sessile hostile flora follows its trigger geometry; scent has no meaning for it.
- Guardians and authored hostile sites obey their own warning/consent rules.
- Predation/ecology still runs; party concealment changes only noticing the party, not whether
  animals perceive one another.
- No effect reduces spawn rates after world generation. A world remains ecologically truthful.
- Auto-path interrupts when a creature becomes alert, not only when combat begins, so the player can
  respond to the earned warning.

## DEBUG and verification

Show creature awareness state, base radius, each modifier/source, sensing channel, hesitation used,
mask duration and why the latest transition occurred. Toggle visualization is development-only.

Fixtures cover:

1. Quiet Step causes one deterministic alert turn and cannot be farmed by stepping in/out forever.
2. Low Profile/Shadowed stack and clamp; inactive/home owners do not contribute.
3. Scent Mask blocks scent-only wake but not direct sight/contact/attack or already-awake pursuit.
4. Flora, guardians and apexes are unaffected.
5. Auto-path stops on alert and preserves the player's next decision.
6. Same save and action sequence reproduces awareness transitions after relaunch.
7. Concealment never reveals a hidden creature's position through the preview.
8. Debug Reset restores current coefficients without rewriting the campaign.
9. Old `isAwake` saves migrate exactly to unaware/pursuing and never gain a fresh hesitation for an
   already-pursuing creature.
10. Removing chemo never renormalizes or increases another channel; mask and Quiet Step do not grant
    two consecutive alert turns in one continuous approach.

### Implemented foundation evidence — 9 Aug 2026

- persisted `unaware` / `alert` / `pursuing` authority with tolerant legacy `isAwake` migration;
- stable semantic alert reasons and persisted one-use Quiet Step hesitation;
- active-party-only Low Profile/Shadowed radius reduction, nonstacking and adjacency-safe;
- alert breaks crypsis and renders a redundant orange dashed outline/warning mark;
- Lure considers only legitimately visible eligible roaming creatures; no target consumes no item
  and no turn, including the hidden-nearer/visible-farther disclosure fixture;
- focused and broad regression suite passed **837/837** after excluding no design-owned awareness
  fixtures.

This evidence does not claim Scent Mask complete. Its `.maskedScent` state seam exists, but recipe,
timed party effect, sensory comparison, HUD and device play remain a later coherent slice. The local
checkpoint must be installed/committed/pushed by Engineering when approval capacity returns; design
documentation is not a substitute for that release evidence.
