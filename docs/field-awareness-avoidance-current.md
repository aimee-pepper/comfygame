# Field Awareness and Encounter Avoidance — Current Direction

**Status:** awareness/Shadow/Lure foundation committed at `5731aa9`, regression-green and present in
Aimee's installed `a77c9dd` phone checkpoint. Scent Mask is source-complete through domain/provider
`7772df0`, player UI `5e5aa14`, focused fixture `2ced55a` and release-content checkpoint `543ddfe`;
exact durations/costs remain reversible DEBUG values and physical-phone acceptance remains pending.
Prompted by Aimee's playtest request for skills/items that reduce animal aggression, help avoid
encounters and make a party harder to notice.

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
becomes pursuing; if the party leaves every contributing radius, it returns to unaware. For an
ordinary roaming creature, direct adjacency, party attack or an explicitly loud disturbance bypasses
alert and wakes the creature immediately; adjacency does not itself begin combat. `isAwake` may
remain as a compatibility projection during migration, but two
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
  Multiple owners do not stack the same node. Its owner also gains the combat-side ambush-opening
  evasion defined in `combat-node-viability-current.md`, so later Shadowed does not erase this point.
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

`scent-mask-first-slice-current.md` now owns the exact reversible first-slice recipe and transaction:
one Reagent plus one selected ordinary-or-better typed animal world resource, zero Essence, 12 world
turns, no use/refresh while already active. The sensory semantics below remain authoritative.

A real playtest need now justifies replacing the held, incoherent Traveller's Token slot rather than
preserving an arbitrary catalogue count.

- Field consumable; applies **Masked scent** to the active party for a reversible starting value of
  12 world turns.
- During the effect, ordinary animals cannot progress from unaware to pursuing solely through scent;
  they enter alert/hesitation first. Direct sight at their adjusted sight radius, adjacency, attack,
  harvest disturbance or an already-alert follow-up may still wake them.
- It has no effect on hostile flora, constructs/guardians, apexes or already active combat.
- HUD shows remaining world turns and the next-step preview names when scent masking matters.
- First-slice recipe: one Reagent plus one selected animal world resource (`MaterialSample` internally)
  at grade 25 or greater,
  with **zero refined Essence**, following the settled mundane-preparation boundary in
  `consumable-economy-field-kit-current.md`. All current butchered animal kinds qualify; flora kinds
  do not. Exact duration/floor remain reversible telemetry values.

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

- Once legitimately revealed/discovered, apexes remain unmistakably marked, stationary, opt-in
  challenges. They do not bypass fog under `minimap-disclosure-current.md`, and avoidance neither
  reveals, hides nor despawns them. Adjacency is safe; deliberate occupied-tile entry starts combat.
- Sessile hostile flora follows its trigger geometry; scent has no meaning for it. For current active
  defence, adjacency and Look are safe and entering its occupied tile starts combat.
- Guardians and authored hostile sites obey their own warning/consent rules.
- Predation/ecology still runs; party concealment changes only noticing the party, not whether
  animals perceive one another.
- No effect reduces spawn rates after world generation. A world remains ecologically truthful.
- Auto-path interrupts when a creature becomes alert, not only when combat begins, so the player can
  respond to the earned warning.

## Interaction matrix

| Effect/action | Unaware movement notice | Existing alert next action | Direct adjacency/contact | Attend / patient presence |
|---|---|---|---|---|
| **Quiet Step** | Once per creature, converts pursuit to one visible alert turn | Does not extend it | No protection | May make the ordinary alert readable, but never adds a trust turn by itself |
| **Low Profile** | Reduces ordinary notice radius by 1; owner gains +6 evasion during ordinary foe-only ambush-opening actions | Alert clears if the party genuinely leaves the resulting radius | Minimum radius 1 remains | Progress uses the same post-modifier awareness plus the disclosed distance-2 floor |
| **Shadowed** | Sets the stronger party radius reduction of 2 rather than stacking another copy | Same as Low Profile | Minimum radius 1 remains | Same as Low Profile |
| **Scent Mask** | Converts chemo-dependent pursuit to one alert opportunity per continuous contact | Does not extend it | No protection | If masking removes the animal's only awareness of the party, patience neither progresses nor resets |
| **Lure** | Deliberately wakes/draws one disclosed eligible creature | May advance it by the authored lure effect | Never protects | Resets patience for that animal and cannot substitute for trust |
| **Attend** | Does not reduce notice or aggression | Allowed while unaware/alert, rejected while pursuing | Adjacent target is invalid | Reveals/saves one deterministic trust condition |

This matrix is deliberately asymmetric. Avoidance, observation and taming share one awareness state,
but no node/item earns trust merely by making contact easier, and no trust progress grants field
concealment against other creatures.

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

### Implemented foundation evidence — installed 10 Aug 2026

- persisted `unaware` / `alert` / `pursuing` authority with tolerant legacy `isAwake` migration;
- stable semantic alert reasons and persisted one-use Quiet Step hesitation;
- active-party-only Low Profile/Shadowed radius reduction, nonstacking and adjacency-safe;
- alert breaks crypsis and renders a redundant orange dashed outline/warning mark;
- Lure considers only legitimately visible eligible roaming creatures; no target consumes no item
  and no turn, including the hidden-nearer/visible-farther disclosure fixture;
- focused and broad regression suite passed **837/837** after excluding no design-owned awareness
  fixtures.

This evidence does not claim Scent Mask accepted. Its exact recipe, timed party effect, sensory
comparison and player UI are source-complete in `7772df0` and `5e5aa14`; the 368×800 sensory,
nonstacking, relaunch and protected-return physical-phone matrix remains pending.

### Playability scheduling disposition — 10 Aug 2026

Do not interrupt OutcomeID → Trading Post → Vance for Scent Mask. The installed Shadow foundation
already gives Aimee a progression route for avoiding ordinary contact and is the correct first live
test. After Vance, add one DEBUG test setup that grants Quiet Step/Low Profile/Shadowed and stages a
visible creature at each awareness boundary; use that evidence before setting Scent Mask's recipe or
duration. If the skills create readable route choices but leave early unskilled parties with no
preparation option, Scent Mask becomes the next Apothecary slice. If awareness itself is unclear,
fix its field feedback before adding an item that depends on it.
