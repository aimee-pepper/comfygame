# Void as a categorical cap — current design

**Status:** Current mechanical design; replaces purely subtractive Void behavior.  
**Scope:** Void, celestial-light suppression, contradiction accounting and downstream generation.

## Meaning

Void means **no celestial light exists here**. It is the first focus that constrains what other
focuses may successfully contribute rather than merely pushing a subject up or down.

An active Void suppresses every authored focus marked `isCelestialLight`—Sun, Moon, Stars, Aurora,
Eclipse and Ring in the current vocabulary. Suppression removes the whole physical cause, including
its heat and other secondary contributions. A Sun that cannot exist does not warm the world anyway.

Non-celestial light remains possible. Crystal, luminous Fungus, Magma and other ground/body light can
raise illumination inside a Void. The result is a world lit without a sky, not necessarily a world
whose every surface is black.

## Activation and modifiers

Void is active when at least one resolved Void sigil contributes to Illumination and that sigil does
not negate Illumination. It activates regardless of whether Void was bound primarily to Illumination
or Thermal, because it is one physical condition with secondaries.

The cap is categorical at every intensity: Faint Void still says no celestial light. Intensity,
Scale and Count continue to change Void's ordinary negative illumination/thermal contribution and
distribution; they do not turn “no sun” into a percentage of a sun.

- Negating Void → Illumination disables the celestial cap for that Void statement and records the
  contradiction normally.
- Negating Void → Thermal removes its cold secondary but does not restore celestial light.
- If another active Void remains, the cap remains.

## Resolution order

1. Expand compounds and assemble complete sigils.
2. Determine whether an un-negated Illumination-contributing Void is active.
3. If active, remove every `isCelestialLight` sigil from **all** target contributions.
4. Record each removed contribution as opposed/denied force on the targets it would have affected.
5. Resolve remaining positive/negative pressures, including Void's ordinary subtraction.
6. Apply cross-target constraints and derive prose/tags.

Greed still charges what the player demanded, including suppressed celestial sources. Contradiction
also sees the force spent asking for a celestial light in a world that forbids one. This is not double
billing of the same concept: greed prices abundance requested; contradiction prices incompatible
authorship.

## Explicit metadata

Use `isCelestialLight` on focus definitions rather than deriving suppression from the broad
`celestial` tag. Tags serve description and ecology and may later include things, such as Meteor,
whose gameplay should not automatically be erased by a starless sky. The cap list must be inspectable
and content-validated.

## Projection and prose

Before binding, the World pane must show the cap without requiring analysis:

> **Void prevents the Sun from taking hold. Its heat and light will not exist.**

If several celestial causes are suppressed, list their names compactly. Consequence numbers remain
analysis-gated, but categorical incompatibility is visible before commitment under the legibility
pillar.

World prose distinguishes:

- dark Void: no celestial light and little other illumination;
- sourceless/lit Void: no celestial light, but crystal/fungus/magma lights the ground;
- contradicted Void: the writing called for a celestial source that could not exist.

Count-description prose never claims suppressed suns or moons are present.

## System effects

- Celestial count is zero for generation, regardless of the suppressed Count qualifier.
- Suppressed celestial tags do not create day/night niches, solar flora support or solar heat.
- Nonvisual and chemosynthetic ecosystems may remain viable through their existing rules.
- Traveller signatures read final capped values and opposed magnitude. Perren may legitimately use
  the impossible demand as evidence of authored conflict.
- Random fill uses the same resolver; there is no preview-only or player-written-only exception.

## Implementation invariants

1. Void + Overwhelming Sun has zero Sun contribution to both Illumination and Thermal.
2. Void + Crystal may still be lit and gains the appropriate sourceless/non-celestial reading.
3. Void with Illumination negated does not cap Sun; Void with only Thermal negated still does.
4. Two Voids require both Illumination contributions to be negated before the cap disappears.
5. Suppressed sources still affect greed and opposed magnitude, but not final tags/forms/aspects.
6. Save/reload and compound expansion produce identical cap decisions.
