# Loose Raw Essence exploration sprite v1

**Status:** Aimee visual-approved and Game Design functional-approved for native integration. The immutable
candidate manifest remains `integrationReady:false` provenance; additive `promotion-receipt.json` is the
exact `integrationReady:true` authority. Every approved PNG and visual-evidence byte remains unchanged.

This packet replaces only the generic/symbolic World presentation of
`TileContent.wildDrop(resource: Resources.essenceRaw, amount: positive)` with a final premade Raw Essence
identity. It does not change pickup rules, amount, narration, minimap disclosure, spendable Essence,
`essence_crystal`, Mote or resource-node behavior.

## Canonical visual audit

The accepted Raw Essence family is blue-white, luminous and droplet/energy-shaped:

- inventory `32×32`: `AssetLab/integration/resource-sprites-v1/inventory/essence_raw.png`, SHA-256
  `9e0f7dacd5f65065de6b164e6bbf494ca55011f394595fc3b8928f6d0f82ab82`;
- current map profile `16×16`: `AssetLab/integration/resource-sprites-v1/map/essence_raw.png`, SHA-256
  `56948c0ec6c0699a26d8889cd857e7da058581536c9e447ff9e259f1341ec20d`;
- compact field identity `8×8`: `AssetLab/integration/resource-sprites-v1/field/essence_raw.png`, SHA-256
  `7fe5b9aacca35c57f57a7e9ac00a4f948476d1f5d225b31504fc7871a8bd6927`.

The separate `essence_crystal` catalogue treasure is a purple quartz lattice at
`AssetLab/integration/exploration-catalogue-objects-v1/runtime/assets/478f94342cdee30d8e20be97e89c83e0cd0e3cb597cd6059fbee70334c45f93d.png`.
It is a negative identity reference and is not reused.

Image generation supplied one non-production source sketch only:
`source/imagegen-reference-nonproduction.png`, SHA-256
`4bdb12dc55f21b67196864ac955ff5082b88e228dda99524214e5d0734fc5b45`.
The shipping candidates are separately authored logical-pixel matrices. Their every opaque color is an
exact color already present in the accepted Raw Essence inventory or map profiles; the source sketch is not
shipped or sampled at runtime.

## Final premade assets

- canvas `16×19`, transparent RGBA, binary alpha;
- bottom pivot `(8,18)` over the existing `16×16` terrain surface;
- four complete premade frames at `final/loose-essence-frame-0.png` through `frame-3.png`;
- runtime keys `loose_essence/ordinary/frame-0...3`;
- full visibility uses `presentationTick` modulo four on the existing shared display clock;
- previously revealed current non-full terrain (fringe or hidden) requests exact frame 0 only;
- never-revealed fringe or hidden performs no request and draws nothing;
- no recolor, runtime pixel generation, per-object timer, amount-dependent art or gameplay state change.

The ambient frames retain one suspended concentration while only a few energy points and an internal light
step move. They do not imply pickup, depletion, yield amount, spreading or a second resource.

## Native lookup seam

Resolve only the exact positive Raw Essence loose-drop case. Mount the selected complete `16×19` PNG in the
same bottom-pivot stationary-content socket used by the promoted exploration packs:

1. terrain and south wall;
2. stationary Loose Raw Essence;
3. party;
4. selection and interaction;
5. alerts and HUD.

No minimap identity is introduced. The current disclosure contract for Raw Essence remains unchanged.
Missing/corrupt keys fail closed to no new sprite rather than substituting `essence_crystal`, Mote, another
resource or a symbol.

## Review evidence

- `evidence/loose-essence-contact-sheet.png` — native, 400%, dark/light/grayscale and applied map proof;
- `evidence/loose-essence-dark-368x800.png`;
- `evidence/loose-essence-light-368x800.png`;
- `evidence/loose-essence-grayscale-368x800.png`.

The generated manifest at `runtime/manifest.json` pins every final file/RGBA hash, source reference,
visibility/frame rule, layer order and native-consumer request.

The pure conformance resolver at `AssetLab/src/exploration-loose-essence-v1.js` pins positive Raw Essence
wild-drop identity, current disclosure, frame selection and fail-closed exclusions. `presentationTick` is the
sole temporal selector. Point, coordinate, map seed, run identity/index and every private or stable phase
offset are forbidden selection inputs; positive amount controls eligibility only and never frame choice.

The promotion receipt pins candidate body
`85326602bd995e1192b967bf23047dd485c117a807865c94200ef80e9c3214e3`, manifest file SHA-256
`58daa8282f5f4312bbbece64325aadd343e4551f0792999680e3ebaf9550fb6e`, unchanged production aggregate
`ece8fe5e3f573e1de1b0a4fd4aeb92d91886ec486cddad8594a918079ab47b9b`, resolver SHA-256
`4703f2f7aaa7becdc3dc9499fffae3161adf04f2f611fc23f5c639e94610d673`, and focused-test SHA-256
`fd138936181409319e7a3d6ba90451a3c1b8dce15d1a3902d7add278d8d060ec`.

## Deterministic checks

```sh
NODE_PATH=/Users/aimeepepper/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules \
  /Users/aimeepepper/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
  AssetLab/scripts/export-exploration-loose-essence-v1.mjs

NODE_PATH=/Users/aimeepepper/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules \
  /Users/aimeepepper/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
  AssetLab/tests/exploration-loose-essence-v1.test.mjs
```
