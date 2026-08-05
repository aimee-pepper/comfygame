# Sites — the fourth layer (v1 draft)

**Companion to the pressure-model drafts.** Sites are things a world *contains*, not things it *is*. Pressures shift distributions; sites are discrete objects placed on the map when conditions are met. Separate system, separate trigger rules. All numbers **[PLACEHOLDER]**.

---

## 0. Correction carried in from the audit

**Greed instability is computed from total world value across all targets**, not from Substrate alone. Vitality produces valuable creatures and flora; Hydrology gates what can live there; Illumination and Thermal shape which traits express and therefore which materials drop. Substrate is the most *obvious* source of value, not the only one.

Implementation: profile everything the generated world actually contains against a baseline and charge instability on the excess — the Mystcraft approach, and self-balancing as the content catalog grows. **[PROPOSAL]** Sites contribute to this too (see §5).

---

## 1. What a site is

A discrete, placed thing with a footprint on the map, its own contents, and usually its own interaction. Distinct from:

- **Pressures** — continuous conditions that bias what spawns
- **Resource nodes** — the ordinary harvestable scatter, already driven by pressures
- **Creatures/flora** — generated populations

Sites are **authored objects with procedural placement**, which makes them the natural home for hand-written content in a procedural world: diary pages, rune knowledge, named landmarks, story beats.

## 2. Trigger rules

A site definition carries:

| Field | Meaning |
|---|---|
| **Conditions** | Pressure ranges that must hold (e.g. Thermal floor < 30 **and** Substrate hard > 60) |
| **Weight** | Base likelihood once conditions hold |
| **Cap** | Max instances per world (most sites: 1) |
| **Exclusions** | Sites that can't co-occur |
| **Placement rule** | Where on the map it may sit (edge, interior, adjacent to water, far from entry) |
| **Contents** | Loot table, pages, knowledge, occupants |
| **Instability contribution** | Some sites are dangerous to have written |

**[PROPOSAL] Conditions are thresholds, not exact matches** — a *range* of worlds can produce a given site. This preserves the "multiple valid answers" property that governs everything else, and means sites are hunted by understanding conditions rather than by memorizing a recipe.

**[PROPOSAL] Rarity comes from condition *narrowness*, not from a rarity tag.** A site requiring three simultaneous uncommon conditions is rare because that world is hard to write — same principle as named places, and same reason it can't be farmed without effort. Consistent with the locked "rare = expensive to author" rule.

## 3. Site categories (first pass)

**Ruins / structures** — the reason this system exists. Provisional split, since the fiction isn't settled:

- **Recent ruins** — from the shattering. Whatever the scattered people left: camps, caches, a diary page, an abandoned working. The primary clue vector, and tied to the search loop.
- **Old ruins** — from the people who came before, who anchored worlds and practiced the Art. Where rune knowledge, compounds, and instrument upgrades plausibly live. Named places are their surviving anchored works, so old ruins and named places are the same civilization at different scales.
- **[OPEN]** Whether there's a third, older layer — something predating both — is undecided. Leaving room for it.

**Natural landmarks** — condition-triggered formations that are worth visiting rather than merely harvesting: a mercury pond field, a crystal cavern, a geyser basin, a frozen forest. These are where *concentrated* value lives, and where the dispersion axis pays off.

**Anchor-points** — if anchoring ends up being performed in-world (open question Q-A), the waystone/wellspring is a site. Listing it here so the system can host it.

**Living sites** — hives, warrens, colonies. Generated from the creature system rather than authored, but placed like sites. The tactical-density counterpart to oasis structure.

**Hazard sites** — rifts, unstable ground, the places a contradictory world tears. Contribute instability rather than value.

## 4. Why this matters for the story layer

Sites are the mechanism that lets **authored content appear in procedural worlds without breaking either**. A diary page isn't a random drop — it's in a ruin, in a world whose conditions the player *wrote*. So:

- Clues are found in places that make sense for the person who left them.
- Writing toward a condition set is writing toward a *kind of place*, which is why deduction from a sensory clue works.
- Old ruins give rune knowledge a home that isn't a shop, and connect the writing system's progression to exploration.

## 5. Sites and instability

**[PROPOSAL]** Two directions, matching the existing model:

- **Greed:** high-value sites (crystal caverns, intact old ruins) add to total world value and therefore to greed instability. Writing toward treasure destabilizes, exactly as writing toward rich substrate does.
- **Contradiction:** hazard sites are *produced by* contradiction rather than contributing to it — a world at war with itself tears, and the tears are placeable objects. That gives contradiction a visible, walkable consequence instead of only a number.

## 6. Open

1. **How many site types ship, and at what authoring cost?** Each needs conditions, contents, and placement rules. Suggest starting with 4–6 and growing.
2. **Do sites persist in anchored/named worlds?** Presumably yes — a ruin you looted stays looted (per the Q12 named-places ruling: unique things stay taken, ordinary resources replenish).
3. **Can the player learn to write *toward* a site deliberately?** The preview panel would need to show site likelihood — probably as silhouettes until first encountered, matching the creature preview rule.
4. **Third, older ruin layer?** Undecided; the fiction may want it.
5. **Do living sites use the same trigger system, or fall out of creature generation?** Leaning: placed by the site system, populated by the creature system.
