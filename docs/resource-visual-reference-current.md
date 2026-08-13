# Resource visual reference — current

**Status:** Resource v0.6 visual authority for AssetLab.  
**Camera:** straight top-down map cue; inventory uses the same family identity.  
**Core rule:** world substrate may grade, but identity-bearing material color remains canonical and
static. The neutral sheen is clipped to revealed remaining resource pixels and never substitutes for
recognizable form.

## Reference basis

- Native copper is characteristically copper-red and may occur as nuggets, sheets or branching masses;
  the cue therefore uses a dendritic branch rather than a recolored generic stone:
  https://geology.com/minerals/copper.shtml
- Native silver often occurs with quartz and as vein/cavity filling; it uses a pale branching wire/vein:
  https://geology.com/minerals/silver.shtml
- Native gold occurs mainly as metal/alloys and is visually distinct from brittle pyrite; it uses
  separated compact nuggets with invariant gold color:
  https://pubs.usgs.gov/publication/cir612 and https://www.usgs.gov/faqs/what-fools-gold
- Obsidian is volcanic glass, commonly black, with occasional reflective sheen; it uses a dark fan of
  sharp glassy blades rather than a crystal recolor: https://geology.com/rocks/obsidian.shtml
- Mercury is a liquid metal at ordinary temperature. Per Aimee's settled art direction it is an
  irregular liquid-silver puddle with separated bead/specular pixels, not cinnabar ore:
  https://www.usgs.gov/centers/national-minerals-information-center/mercury-statistics-and-information
- Fungal reproductive structures produce and disperse spores; the Spore cue uses separated airborne
  dots/puffs rather than another leaf or bottle: https://www.kew.org/read-and-watch/the-wonderful-world-of-fungi

The fictional families use established game semantics rather than fake geology. Adamant is a dense
teal faceted core; Rift-glass is separated unstable blades; Raw Essence remains the accepted wildDrop;
Mote remains inventory-only.

## Family grammar

| Family | Dominant readable form | Canonical material cue |
|---|---|---|
| Rubble | angular heap of mismatched broken blocks | pale chipped faces |
| Clay | smooth layered rounded mound | warm clay-orange body |
| Iron Ore (`ore`) | heavy jagged rock with rusty inclusions | rust-brown pockets |
| Copper | branching/dendritic native-metal mass | copper-red branches |
| Silver | thin branching wire/vein | pale metallic wire |
| Gold | separated compact nuggets | invariant gold yellow |
| Quartz | central prism with smaller side prisms | pale violet-white facets |
| Obsidian | fan of sharp conchoidal glass blades | near-black violet glass |
| Salt | three cubic crystals with corner highlights | chalk-white cubes |
| Sulfur | low cluster of pointed crystals | invariant sulfur yellow |
| Mercury | low irregular puddle plus detached bead | liquid-silver highlight |
| Adamant | dense hollow/faceted core | invariant teal core |
| Fibre | parallel gathered strands with cross tie | pale fibrous strands |
| Timber | horizontal cut log with end ring | brown log/end grain |
| Pulp | torn, soft stacked sheets/wad | pale pressed fibre mass |
| Resin | hanging tear merging into sticky pool | invariant amber exudate |
| Toxin | thorned/contained natural pod | host-safe contrasting core |
| Spore | separated puff bodies and dispersed dots | pale spore points |
| Reagent | gathered herb sprig with leaves | plant-derived leaf accents |
| Ichor | viscous pool with a trailing drip | invariant dark magenta fluid |
| Rift-glass | two separated unstable glass blades | cyan fracture faces |
| Raw Essence | accepted wildDrop body only | pale-violet essence core |
| Mote | inventory-only framed reality point | gold frame and white axis |

## World color and animation

At least two occupied identity pixels—and usually substantially more—must retain their canonical
material color across every world substrate. The resource's host rock or exact flora may use the
world grade. Whole-resource recoloring is forbidden because it would make Gold stop reading as gold
and collapse the catalogue back into same-shaped local terrain.

Sheen remains `resource-sheen-1.1.0`: one shared 360 ms map clock, eight ticks with four quiet ticks,
stable public tile phase, and Reduce Motion frame zero. It is applied after static color and changes
only pixels inside the canonical resource/cue mask. Hidden, undiscovered, exhausted and minimap forms
never animate.
