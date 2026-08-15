# Bookbinder Asset Lab

An isolated pixel-art authoring prototype plus one read-only live gameplay tool. Asset proofs do
not import or modify the game. The World Generator Tester compiles a local command-line bridge from
the game's real Swift generation sources so its maps and spawn counts cannot drift from production.

## Run

```bash
cd AssetLab
npm run serve
```

Open `http://127.0.0.1:4173`.

- Creature Lab: `http://127.0.0.1:4173/index.html`
- World Lab: `http://127.0.0.1:4173/world.html`
- Live World Generator Tester: `http://127.0.0.1:4173/world-generator-tester.html`
- Golden Review: `http://127.0.0.1:4173/regression.html`
- Combat Proof: `http://127.0.0.1:4173/combat.html`
- Combat UI Proof: `http://127.0.0.1:4173/combat-ui.html`
- Sprite Region Studio: `http://127.0.0.1:4173/sprite-regions.html`

## Test

```bash
cd AssetLab
npm test
npm run regression
```

The first live-world generation builds a cached Swift bridge and can take roughly 20 seconds.
Later generations reuse it and are fast. The cache is ignored by Git and automatically rebuilds
when any included game-generation source changes.

## Phase-0 capabilities

- deterministic creature identity descriptors using the game's full trait vocabulary;
- synchronized 16×16 world and 48×48 fight profiles;
- clearly labelled trait/seed locks, randomization, and seed rerolling;
- eight body topologies: quadruped, biped, serpentine, segmented, radial, piscine, winged,
  and amorphous;
- distinct covering, appendage, armament, pattern, sensory, defence, toxicity, and emanation
  treatments;
- compatibility warnings for visually incoherent combinations;
- a deterministic 24-creature population contact sheet for spotting sameness;
- curated ecological anatomy presets;
- a plain-language derived anatomy summary;
- pin-and-compare fight-view candidates;
- contact-sheet PNG export;
- separate species and specimen seeds;
- ecosystem-diversity and species-consistency population modes;
- linked CMY and sensory allocations that always total 100;
- true translucent material rendering from opacity;
- automatic native-canvas bounds fitting with live diagnostics;
- decoded-pixel hashes for world and fight previews;
- versioned export manifests with pivots and output metadata;
- JSON Schemas for identity descriptors, render requests, and manifests;
- local workspace persistence for locks and pinned comparisons;
- three terrain tiles and a flora tile derived from the same palette;
- native-size and integer-scale preview;
- JSON fixture import/export;
- individual PNG export;
- stable descriptor and command hashes;
- no external packages, network requests, or game-code coupling.

This remains a visual-grammar proof rather than game integration. Engineering owns any eventual
adapter. Source-art editing, animation, architecture, and splash composition remain later asset
milestones.

## World Lab proof

- dedicated flora descriptors using stature, tissue allocation, defence, habit, colour, finish,
  and metabolism;
- stable flora species pixels—placement changes do not mutate species identity;
- 16 adjacency masks for the first water/shore terrain family;
- separate fog/reveal, elevation, and cracking inputs;
- a native 9×9 top-down phone-map proof;
- disclosure-neutral symbolic minimap rendering;
- flora world and detail/hostile-fight profiles;
- separate neutral-detail and triggered hostile-flora poses;
- habit-driven spreading, clustered, and solitary patch topology;
- ordinary and deep-water distinction;
- all 12 live ground types with exact passable/slow/sight/overgrown rule facts;
- seven flora identity-region presets with distinct native silhouettes;
- literally empty unrevealed fog;
- redundant shape grammar for elevation and cracking;
- route and party overlays shared by map and minimap;
- growth-class minimap tiles rather than per-plant/resource-like dots;
- true grayscale native-map readability proof;
- deterministic native PNG and JSON fixture export.
- passability-derived route fixture with portal, discovered-site, and party symbol collisions;
- last-pass crack warnings that cannot be hidden beneath flora or decoration;
- schema-checked export boundaries and a versioned 36-output golden hash baseline;
- browser-visible golden review sheet with JSON and PNG evidence export.
- schema-described static combat fixtures with full version tuple, decoded-pixel hash, and manifest export.
