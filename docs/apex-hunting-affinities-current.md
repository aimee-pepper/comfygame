# Current Design — Apex Hunting Affinities

**Status:** Implementation-facing authored affinities with tunable bonus strength. They bias which
wild weapon belongs to an apex/world; they never guarantee an apex or a particular drop.

## Shared rule

- The existing risk/value draw still decides whether an apex appears.
- Encounter difficulty resolves independently under `encounter-scaling-playtest-current.md`.
  Affinity matches never alter apex level, HP, offence, action slots, creature traits or nearby
  ordinary foes.
- If an apex or locked-cache bonus awards a wild weapon, each satisfied affinity condition adds one
  `characterBonus` weight to that weapon.
- Conditions are independent bonuses, not an all-or-nothing signature. Deliberate writing can strongly
  favour a weapon while surprise remains possible elsewhere.
- Pre-bind projection does not name an apex or weapon. After encountering a weapon, high analysis may
  describe its known environmental lean without showing exact odds.
- A matching world does not disclose an undiscovered apex through the main map or minimap; the
  explore-first default in `minimap-disclosure-current.md` has no affinity exception.
- Save-compatible item ID `rimed_edge` continues to mean player-facing **Barbed Edge**.

## Affinity table

| Weapon | Favoured conditions | World logic |
|---|---|---|
| **Two-Natured Blade** | Any opposed pressure >=18; second bonus if two or more targets are opposed >=12 | It belongs to genuinely competing answers, not merely varied scenery |
| **Long Fang** | Relief openness >=72; Vitality dispersion <=38 | Long pursuit between separated living stands produces reach without a conventional haft |
| **Ranked Spear** | Relief openness >=55; Vitality peak >=68 | Visible lines through a crowded field make “through and onward” distinct from solitary distance |
| **Barbed Edge** | Vitality tag `defended-flora`; fallback at Vitality peak >=62 and Relief openness <=42 | Barbs belong to crowded contact-defence, not retired cold/freeze fiction |
| **Living Hook** | Vitality produced >=45; Vitality trophic depth >=48 | Surplus growth and deep exchange support a weapon that continues changing through use |
| **Quiet Knife** | Illumination peak <=25; Atmosphere motion <=22 | Darkness conceals approach and still air preserves the absence of a report |
| **Bloodletter** | Vitality trophic depth >=58; Thermal floor >=35 | Sustained predation in a warm living system makes wounds ecologically consequential |
| **Warded Haft** | Substrate hard form >=58; Relief verticality >=32 | Load-bearing hard ground under directional strain supports held impact defence |

## Distinction checks

- Long Fang and Ranked Spear share openness but have opposed second conditions: separated life for
  pursuit versus abundant life for a line continuing through another body.
- Barbed Edge receives no cold bonus. Its internal ID must not leak the retired name.
- Living Hook and Bloodletter both use deep Vitality, but one requires producer renewal and the other
  pairs predation with sustained warmth.
- Two-Natured Blade reads actual opposed magnitude; tags or prose alone do not qualify it.
- Warded Haft's affinity does not decide its ward type; current content remains authored against crush.

## Tuning and fixtures

1. Expose `characterBonus` in the debug menu.
2. Generate one deliberate fixture per weapon and verify it has the largest individual share without certainty.
3. Neutral, blank and extreme-risk fixtures must leave every weapon at nonzero chance.
4. Track empirical distributions separately for apex wins, ordinary-creature lottery and caches.
5. A weapon affinity never makes an apex more likely; appearance remains on risk/value.
