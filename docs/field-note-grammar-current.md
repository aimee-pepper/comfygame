# Field-note grammar — resolved facts without free analysis

**Status:** Checkpoint `8b32b51` is ready for phone variety acceptance; full device/test builds and
focused runtime 4/4 are green. Template weights are playtest values; disclosure boundaries and fact
persistence are current.

## Record shape

A Field note freezes a stable template ID and fact kind, only the qualitative token values used by
that template, exact generated prose, writing position and world/run ID. The Library may later place
earned analysis beside the note, but never rewrites its recovered prose. Old three-line generic
notes remain valid records with no structured fact.

For the first native slice, extend `FoundWritingRecord` with tolerant optional fields rather than
replacing its existing identity:

- `templateID: String?` — one stable ID from this document;
- `fieldFact: FieldNoteFact?` — a tagged, Codable payload containing only the safe tokens actually
  interpolated into the prose;
- `originWorldSeed: UInt64?` — the generating world's frozen seed.

Existing `prose` remains authoritative for display and `position` remains the exact writing host.
Missing structured fields mean a legacy frozen note and must never trigger attempted reconstruction.
The world-history record ID is assigned only when a world is actually recorded on return; generation
must not invent one before that receipt exists.

`FieldNoteFact` is a closed tagged union for `terrain`, `lightAir`, `growth` and `water`. Each case
stores its template-specific qualitative values—never a raw `PressureReadings`, hidden entity ID,
resource table, species identity or numeric threshold. Decode of an unknown future fact kind retains
the saved prose and treats structured detail as unavailable.

## Eligible fact families

Choose only among facts plainly observable at or immediately around the writing host. The page may
describe what an earlier traveller observed there; it may not reveal a remote fact.

| Family | Eligibility | Safe tokens | Never include |
|---|---|---|---|
| **Terrain relation** | Always; prefer two local grounds, elevation change or a rules-relevant edge | cardinal direction, display ground names, rises/falls, slow/clear/blocked/edge relation | resource richness, hidden content, numeric pressure |
| **Light and air** | Qualitative bright/dark, moving/still or changing-light direction exists | bright/dim/dark, still/moving, light changed/held | Cycle period, exact vision, named unseen cause |
| **Growth relation** | Groundcover/tall growth or visible flora patch lies at the host | low/tall, clustered/spread/solitary, stops/crosses a terrain edge | metabolism, tissue percentages, defence type, guaranteed harvest |
| **Water relation** | Local shallow/deep water, ice or mud is visible | stands/flows only when resolved, shallow/deep/ice/mud, safe edge | hidden depth, exact saturation, promised yield |
| **Creature trace** | A saved-cast trace is physically visible at the host | small/large impression, narrow/broad track, solitary/many only when supported | species name, senses, defence, toxicity, apex identity, exact values |

If no specialized relation is eligible, use a terrain fact about the host itself. Field note is
therefore always available without becoming generic filler.

**First native slice:** creature traces have weight zero because the current map persists and
renders no trace dressing. Nearby enemies or the saved cast are not substitutes for a visible host
fact. Renormalize across terrain, light/air, growth and water; enable trace prose only after the map
stores and draws the exact trace the note describes.

## Stable template corpus

Tokens in braces are selected from persisted safe facts. Grammar resolves articles and plurality
before saving prose; the Library never displays raw tokens.

### Terrain

- `field_terrain_boundary_01` — “The {groundA} ends {direction}. I kept to the {groundB}, where each step held.”
- `field_terrain_cost_01` — “The {slowGround} took twice the effort. I went {direction} along the clearer edge.”
- `field_terrain_sight_01` — “Past the {blockingGround}, I could no longer see the mark behind me.”
- `field_terrain_height_01` — “The ground {risesOrFalls} toward the {direction}; the old scratches follow the same line.”
- `field_terrain_edge_01` — “I turned {direction} before the {impassableGround}. The rim continues farther than this page.”
- `field_terrain_single_01` — “I set this down on {groundA}. The same ground continues on every visible side.”

Only use “twice the effort” for live two-turn terrain and sight language for live sight-blocking
terrain. Aesthetic texture never invents either rule.

### Light and air

- `field_light_dark_01` — “I counted the next few steps by touch and kept the written side covered.”
- `field_light_bright_01` — “I turned the page face-down. Even the unmarked side held the light.”
- `field_light_change_01` — “The light changed before the ink dried; the ground did not.”
- `field_light_held_01` — “The light held while I wrote. I stopped waiting for it to turn.”
- `field_air_moving_01` — “I weighted three corners. The air found the fourth whichever way I turned.”
- `field_air_still_01` — “The dust on this line had not shifted when I came back.”

These are qualitative witness statements, not claims that the writer measured Cycle or Atmosphere.

### Growth

- `field_growth_boundary_01` — “The {growthHeight} growth stops at the {groundA} as neatly as a cut thread.”
- `field_growth_spread_01` — “The low growth crosses the path in one sheet; footsteps divide it, then it closes again.”
- `field_growth_cluster_01` — “The growth gathers in separate knots. Bare ground remains between them.”
- `field_growth_solitary_01` — “One tall form stands apart here. I could see its outline before its base.”
- `field_growth_form_01` — “The {growthHeight} growth keeps a {habit} shape here. Bare ground shows its edge.”
- `field_growth_sight_01` — “The tall growth swallowed the mark behind me. I made the next one higher.”

Use only relations produced by saved patch/habit and stature. Do not name the species unless the
normal flora-knowledge system independently permits that name at collection.

### Water

- `field_water_shallow_01` — “The shallow water keeps the shape of the ground beneath it.”
- `field_water_deep_01` — “The colour changes past the {direction} edge. I did not test the deeper part.”
- `field_water_ice_01` — “The surface held my weight here; the trapped line beneath it points {direction}.”
- `field_water_mud_01` — “The mud kept every step and charged for each one. Firmer ground lies {direction}.”
- `field_water_boundary_01` — “Water reaches the {groundA} here and leaves its old edge above the new one.”

Do not say water flows unless resolved Hydrology supports flowing; visual wave decoration is not
evidence.

### Creature traces

- `field_trace_small_01` — “Small impressions cross the page site and disappear {direction}.”
- `field_trace_large_01` — “One broad track pressed through the surface here. The edges were still clear.”
- `field_trace_many_01` — “Several tracks use the same narrow line, one laid over another.”
- `field_trace_solitary_01` — “A single trail arrives, circles once, and leaves without joining another.”

Trace prose grants no bestiary sighting and never names the creature. The trace is visible dressing
at collection; do not generate prose about tracks absent from the rendered host.

## Selection

Default family weights within Field note are terrain 35, light/air 20, growth 20, water 15 and trace
10. Remove ineligible families and renormalize; never force a family by fabricating its fact. Prefer
a relation not already represented by another Field note in the same world. A second Field note uses
a different template ID and fact where possible.

In the first native slice trace weight is zero, so renormalize 35/20/20/15. Build every eligible fact
from the chosen host plus its in-bounds cardinal neighbours after terrain and flora placement. Sort
facts by `(family order, templateID, direction, ground IDs)` before seeded weighted selection so
dictionary/set iteration cannot change a world's prose. The first note consumes the ordinary writing
RNG once; a second removes the first template and exact fact before selecting, falling back only when
no distinct truthful option exists. Use the terrain-single template only when all visible cardinal
neighbours actually share the host ground. Light/air is always locally observable and supplies the
final guaranteed family when no truthful terrain relation exists; never claim local uniformity only
to force a terrain result.

## Verification

1. Every generated note's tokens can be recomputed from its saved local/world facts.
2. Slow/sight/impassable prose fires only for the exact live rules.
3. No note names an unrevealed site, resource, traveller, species or apex.
4. Growth prose matches saved stature/habit/patch topology and promises no harvest.
5. Creature traces are visible at the host and never create a bestiary sighting.
6. Prose, template and tokens survive save/load and anchored revisit exactly.
7. Blank/unusual worlds still obtain a truthful local observation without fabricated terrain.
