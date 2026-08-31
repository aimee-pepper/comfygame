# AssetEvidence authority audit V1

**Base:** `5e1ee40c8666db0b636b82c49552621361614fe5`  
**Scope:** the 98 files that were loose directly under `AssetLab/artifacts` before this change.  
**Method:** source text, manifests, generators, tests, and documentation only; no image was opened.  
**Authority:** classification records evidence role only. It does not approve art, gameplay, runtime
use, source authorship, or final-art acceptance.

## Exact classification totals

| Classification | Files | Meaning |
|---|---:|---|
| `review-evidence` | 17 | A review rendering with a named documentary/proof role; no acceptance implied. |
| `reference` | 37 | Superseded, historical, placeholder-only, or preserved comparison evidence. |
| `candidate-output` | 27 | Current candidate/proof output named by existing documentation; never runtime/final art. |
| `generated-test-artifact` | 13 | Machine-produced JSON/fixture/report with a closed producer or test. |
| `still-blocked` | 4 | Missing producer/provenance or conflicting authority prevents semantic relocation. |
| **Total** | **98** | |

### Generated test artifacts

`authored-color-vocabulary-proof-v0.1.json`, `catalogue-tier2-proof-v0.1.json`,
`catalogue-tier3-proof-v0.1.json`, `combat-node-placeholder-proof-v0.1.json`,
`combat-tree-functional-layout-proof-v0.4.json`, `combat-tree-true-graph-proof-v0.3.json`,
`combat-tree-v2-route-audit.json`, `constellation-proof-v0.1.json`,
`consumable-field-kit-proof-v0.1.json`, `creature-diversity-foundation-v0.1.json`,
`research-graph-proof-v0.1.json`, `world-grade-2-proof-v0.2.json`, and
`world-history-proof-v0.1.json`.

### Still blocked

- `combat-tree-accessibility-proof.html`: no producer or authoritative reference is recorded.
- `mixed-ink-mixer-proof-v0.1.json` and `.png`: the files self-label a proposal, but no producer or
  repository authority establishes their path or current status.
- `flora-overhead-proof-v0.2.png`: two divergent map-slice manifests claim the surrounding authority;
  relocation would choose a winner before that conflict is resolved.

### References

`app-launch-proof-v0.1.png`, both `authored-color-writing-proof-v0.1` files,
`campaign-bookplate-proof-v0.1.png`, `catalogue-item-identity-proof-v0.1.png`,
`character-identity-proof-v0.1.png` through `v0.3.png`, the combat-node placeholder PNG,
all three combat-tree functional-layout renders, every `combat-tree-graph-proof` v0.1/v0.2/HTML
file, `debug-bug-reporter` v0.1/v0.2, `economy-five-identity-bridge` v0.1/v0.2,
`equipment-grid-bridge` v0.1, `full-cast-descriptor` v0.1, `map-top-down-character` v0.1/v0.2,
`place-identity-adaptation` v0.1 through v0.3, `provisional-noll-identity` v0.1,
`splash-lifecycle` v0.1/v0.2, `tile-content-collision` v0.1, `trading-post-vance` v0.1,
and every `world-grade-2-proof-v0.1` file.

### Candidate outputs

`app-launch-proof-v0.2.png`, `blacksmith-pointed-blade-checkpoint-proof-v0.1.png`,
`campaign-bookplate-proof-v0.2.png`, `catalogue-item-identity-proof-v0.2.png`,
`character-identity-proof-v0.4.png`, the ordinary and HTML true-graph v0.3 proofs,
`debug-bug-reporter-proof-v0.3.png`, `economy-five-identity-bridge-proof-v0.3.png`,
`economy-stations-proof-v0.1.png`, `equipment-grid-bridge-proof-v0.2.png`,
`equipment-six-across-proof-v0.3.png`, `full-cast-descriptor-proof-v0.2.png`,
`map-top-down-character-proof-v0.3.png`, `map-top-down-full-cast-proof-v0.1.png`,
`multi-species-map-proof-v0.1.jpg`, `place-identity-adaptation-proof-v0.4.png`,
`provisional-noll-identity-proof-v0.2.png`, the ordinary research-graph v0.1 PNG,
`splash-lifecycle-proof-v0.3.png`, `terrain-lifted-extrusion-proof-v0.1.png`,
`tile-content-collision-proof-v0.2.png`, `trading-post-vance-proof-v0.2.png`, and the four
non-JSON `world-grade-2-proof-v0.2` outputs.

### Review evidence

The two authored-colour-vocabulary PNGs; catalogue-tier2 and tier3 PNGs; combat UI PNG;
true-graph v0.3 large-text PNG; constellation, consumable Field Kit, and creature-diversity PNGs;
research-graph large-text PNG; all six resource-node PNGs; and world-history PNG.

## Four ambiguity resolutions

1. **Combat tree:** metadata with a named exporter/test is a generated test artifact; current visual
   proposals are candidate outputs; superseded graph/layout boards are references; the unowned
   accessibility HTML remains blocked.
2. **Provisional characters:** the named-character manifest explicitly calls the pack a functional
   placeholder. Current v0.4/full-cast/map/Noll proofs are candidate outputs only; earlier revisions
   are references. None is production character art.
3. **Historical accessibility:** `large-text` outputs with a named producer are historical review
   evidence or references. Their names do not authorize new accessibility work. The unowned HTML is
   blocked.
4. **Metadata versus render:** JSON with `evidenceRole`, `integrationReady:false`, and a closed
   producer/test is a generated test artifact. Its paired raster is separately review evidence or a
   candidate output. One never promotes the other.

## Phase-one relocation receipt

Exactly one file had closed authority, version, producer, test, and semantic role:

| Before | After | SHA-256 | Classification |
|---|---|---|---|
| `AssetLab/artifacts/combat-tree-v2-route-audit.json` | `AssetEvidence/combat-tree/v2/route-audit/review/combat-tree-v2-route-audit.json` | `6d9b0fb3e6ee10fc805d08d7a5b48d0239a3efe62b3c25c62b8d117135c8d31b` | `generated-test-artifact` |

The move is byte-identical. The producer, focused test, and true-graph metadata reference now name
the semantic path. The other 97 files remain in place. Their classifications above are an audit,
not relocation or acceptance authority.

