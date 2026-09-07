# Fixed-camera 3D presentation: a bounded choice prototype

**Unsettled renderer proposal · 4 September 2026.** Aimee is leaning toward real 3D rendering with a fixed orthographic camera and sprites, for atmosphere and Blender authoring. PM requested this acceptance brief. The accepted three-quarter direction remains; no engine selection, renderer replacement or broad terrain production is approved by this document. Keep the current native Nessa journey and phone delivery moving.

## One scene, one decision

Use one frozen patch from an existing generated grid in temporary test state, with a player sprite, one harvestable tree, one resource node, raised land, and local water. Reuse its saved positions, source identities and legal routes. Choose a patch containing those features; do not reroll or alter Aimee’s campaign. Depict only heights and water facts actually available to the adapter. If a required fact is absent, report that bounded dependency rather than manufacturing new saved-world semantics.

Show the patch through a fixed orthographic camera: no rotation, perspective zoom or free camera. Include a shallow visible water bed, the character passing behind the tree or raised face, a simple directional shadow, and one light atmospheric effect. **Proposed demonstration effect:** sparse drifting mist confined to permitted visible ground; it has no weather, root-water, sight-range or turn effect. The effect is illustrative and not a decision about the game’s final atmosphere.

Keep the first shadow demonstration to the character and one disclosed tree or land edge. It tests grounding and disclosure safety; the accepted later shadow coverage for trees, elevated land, bushes, resource nodes and character remains broader, low-priority work.

## Minimum evidence for Aimee’s choice

| Question | Evidence from this same patch |
| --- | --- |
| Is the view readable and appealing? | One short actual-iPhone recording walking past the tree/node, raised edge and water, with the effect visible. Record the actual device and native viewport at default text in its current ordinary appearance. A paired still of the existing view may help compare the same saved patch; no configuration matrix. |
| Does depth behave correctly? | The character passes in front of and behind disclosed objects without flicker or incorrect ordering. Ground contact stays clear. Water stays in its local bed; high land is not submerged by a global water layer. Only the obstructing tree or cliff face fades. |
| Is the game still the same game? | Deliberate movement and one existing legal harvest use the current action path. The renderer neither spends a turn nor owns collision, tools, yields or depletion. Preserve exact source/work state through one reload; the prototype never writes to the user’s campaign. |
| Does it keep secrets? | Put one undisclosed object behind the existing visibility boundary in this scene. Its geometry, shadow, reflection and atmospheric interaction must not disclose its presence. Fade never reveals more ground or live entities, and minimap knowledge does not change from presentation alone. |
| Is it practical to continue? | Engineering gives a brief on-device responsiveness/frame-pacing observation during the same route and names any visible stalls or rendering faults. Show one simple Blender-authored source object reaching the temporary scene through a repeatable import step, with scale, origin and tint/material ownership documented. No export framework or asset library is needed. |

Aimee chooses whether this demonstrated appearance and authoring workflow justify continuing toward a 3D renderer. The receipt should name the exact prototype commit, device, known limitations and remaining implementation cost. A beautiful still alone does not resolve the choice. Failure of one rendering detail calls for a bounded fix or an explicit limitation, not a gameplay rewrite.

## Dependencies and ownership

The current native entry surface is `Sources/Screens/WorldView.swift`. Engineering must name the exact temporary rendering consumer and its read-only scene adapter before Asset is assigned work. That adapter takes saved grid/support/liquid/object facts and the existing visibility projection, then returns user intent through the existing movement and harvest commands. It does not become a second simulation. The physical and information rules in [three-quarter semantics](three-quarter-world-semantics-v1.md) and [solid deposits](early-solid-deposit-interaction-v1.md) remain authoritative; new elevation-edge gameplay remains its separate versioned dependency.

At a safe boundary after the active journey work, Engineering defines the consumer, state/event protocol, geometry units, source/display dimensions, accepted import format and actual-phone route. Only then may Asset own the required literal composition, sprite pivots, materials, shadow treatment and mist timing. Use existing assets or explicitly marked functional placeholders (`finalArt: false`) for the proof. Aimee’s Blender source remains human-authored and editable; this experiment grants no exception to final-art provenance and does not assign a speculative new asset family. Asset’s resource inventory thumbnail work continues independently with its Engineering hookup dependency.

This choice does not add stacked floors, bridge underpasses, physics simulation, off-grid movement, camera rotation, dynamic time-of-day or a day/night system. A fixed demonstration light is not a new lighting mechanic. No current game work is scrapped, no full-world asset conversion is requested, and no standalone Wiki publication is needed for this brief. The later [ordinary3D expedition trial](ordinary-3d-expedition-trial-v1.md) is now explicitly approved. This older prototype remains a separate illustrative study; full3D migration is not selected.

## Later ordinary-trial approval

[Ordinary3D expedition trial](ordinary-3d-expedition-trial-v1.md) now supplies the accepted opt-in scope, entry wording and small trial check. It uses a real unscreened ordinary expedition and a separate saved trial, not this example scene. It follows the safely finished Bowyer checkpoint, before remaining shops; current2D stays available. This is one trial with a quick save/reopen check, not a campaign/progression test.

The ordinary trial entry remains **Settings → Owner Tools → 3D Trials**, with isolated durable test state. Main-campaign gameplay overhaul integration is a separate decision; it does not move the 3D trial into New Game or add a renderer switch.
