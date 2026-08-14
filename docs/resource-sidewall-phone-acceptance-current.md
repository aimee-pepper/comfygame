# Resource v0.6 and sidewall phone acceptance — current script

**Status:** immediate device-check script; design evidence only, no implementation expansion.  
**Build floor:** `b709e7c` or later containing the exact Resource v0.6 integration.  
**Owner:** Aimee plays; Engineering records build/device evidence; Design interprets readability.

## Purpose

This checkpoint answers two narrow questions before the bug reporter begins:

1. Can Aimee distinguish resources quickly enough during ordinary exploration without reading every
   label?
2. Do terrain height and material boundaries look like top-down ground, without false vertical walls?

It does not judge the later six-across Storehouse Resources layout, rebalance node frequency/yield,
or reopen resource identities already frozen in v0.6.

## Fast pass — one ordinary expedition

Use the installed build and an ordinary generated world. Do not tune a special beautiful seed.

1. Confirm the DEBUG build/commit is `b709e7c` or later.
2. Find at least three visible resource nodes or drops. Before opening text, name what each silhouette
   appears to be; then compare with its actual identity.
3. View one remaining node while stationary for several seconds:
   - a restrained staggered sheen may appear;
   - the whole node must not blink, pulse or recolour;
   - Reduce Motion must leave a stable recognizable body.
4. Harvest one resource to exhaustion:
   - the resource cue disappears or changes to its truthful exhausted state;
   - host flora/terrain remains the same place rather than vanishing with the resource;
   - no sheen remains on an exhausted source.
5. Move across at least one ground-material boundary at equal elevation. It must not create a wall,
   ledge or dark vertical band merely because colour/material changed.
6. Move beside one genuine raised tile or terrace if present. A restrained material-matched southern
   riser may show height, but it must still read as a top-down lifted surface rather than a side-view
   block.
7. Check the lowest visible map row and southern edge. No tile sidewall may be clipped into a false
   bottom border or cover content on the row below.
8. Check every lifted/elevation overhang against adjacent tiles and the outer map edge. Transparent
   padding must composite over the game-owned terrain/fog field; no white/system-background strip
   may appear between tiles or beneath a 16×19 lifted sprite.
9. Check the minimap. It remains symbolic and disclosure-gated; resource-specific bodies and sheen do
   not leak onto unrevealed or minimap tiles.

## Coverage pass — DEBUG fixture, not required for every play session

The acceptance build should also provide captured evidence for representative families:

- metal: Copper or Silver plus Gold;
- crystal/mineral: Quartz or Salt plus Obsidian/Rift-glass;
- fluid/soft: Mercury, Resin or Ichor;
- organic: Fibre/Timber plus Spore/Reagent;
- exceptions: Raw Essence on the world; Mote absent from world bodies;
- flora-linked harvest: one cue composed over the actual plant rather than replacing it.

Review at native colour, grayscale and Reduce Motion. The full automated contract still requires all
world-capable resource bodies to remain pairwise distinct; the phone sample asks whether those formal
differences survive real tile scale and neighbouring terrain.

## Pass/fail language

Record each observation as:

- **Pass:** recognizable before text and visually owned by the correct tile/material.
- **Ambiguous:** visible but confused with a named other resource or terrain feature.
- **Hidden:** too weak to locate during ordinary exploration.
- **False disclosure:** visible through fog/minimap or after exhaustion.
- **False sidewall:** material/border looks vertically raised without a real elevation change.
- **Height unreadable:** a real elevation change is indistinguishable from flat ground.

A single false disclosure or repeated false sidewall fails the checkpoint. One ambiguous family routes
that exact pair back for contrast adjustment; it does not authorize a broad resource-art rewrite.

## Evidence to retain

- exact commit and device model;
- one uncropped full-world screenshot showing ordinary resource/terrain context;
- one close native-scale screenshot of the ambiguous/pass pair if relevant;
- Reduce Motion on/off result;
- the named resource pairs Aimee confused, if any;
- whether the sidewall report occurs at equal elevation, genuine elevation, or the southern map edge.

This script is acceptance evidence, not a live scheduler. After it passes, subsequent priorities come
only from `Sources/Content/Data/playability-roadmap.json`; do not preserve the old reporter/resource
ordering here as a second queue.
