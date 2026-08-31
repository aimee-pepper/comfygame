+# Asset source organization — Phase 1 migration map

**Base:** `fdcf307d869696b01efbe58f58b81bf815e2424d`  
**Scope:** tracked human-facing visual files currently mixed under `AssetLab/artifacts`; legitimate `RuntimePacks/*/assets/<sha>` blobs are excluded.  
**Disposition:** source mutation blocked by provenance; this is an exact migration receipt, not a runtime catalogue or approval record.

## Exact census

- Tracked files under `AssetLab/artifacts`: 658.
- Pack-local manifests excluded from the visual-file appendix: 11.
- Visual source/review/evidence/derivative paths inventoried below: 647.
- Hash-first filenames under `AssetLab/artifacts`: **0**.
- Copy-suffixed filenames under `AssetLab/artifacts`: **0**.
- Loose mixed review/proof files directly under `AssetLab/artifacts`: **98**.
- Explicit `source/` files: **92**; their manifests identify deterministic integer/procedural proof production, not Aimee-authored or approved editable-source provenance.
- Explicit non-production generated references: **4**; their manifests mark them `productionSource:false` or `referenceProductionSource:false`.

## Phase 1 source-root decision

No bytes qualify for migration to `AssetSources/<Pack-vN>/<stable-id>/<variant>/source/<semantic-name>.<ext>` on this revision.

The source-bearing packs are provenance-blocked:

1. `atmosphere-presentation-v0.1` is a deterministic integer-pixel runtime-composable proof.
2. `writing-page-a1-v0.1` and `writing-page-a2-v0.1` declare `productionSource: deterministic-integer-logical-pixels`.
3. Generated references in `dynamic-terrain-style-v0.2`, `world-arrival-v0.1`, and `writing-parchment-v1` explicitly deny production-source authority.

Moving those files into `AssetSources` would falsely imply editable final-art provenance. No source, runtime, evidence, generator, manifest, documentation reference, or Xcode project entry is changed in Phase 1.

## Staged relocation rules

- **provenance-blocked:** do not move until an Aimee-authored provenance receipt or approved generated-source receipt names the exact bytes, stable ID, editable-source role, and consumer.
- **evidence-relocation-queued:** after an evidence-root authority is approved, move into a semantic pack/stable-ID/variant evidence path and update every producer/reference listed below atomically.
- **authority-review-required:** classify the file as editable source, generated derivative, runtime derivative, or review-only evidence before assigning a destination.
- **keep-runtime:** remain outside the human editable-source root.

For every eventual move: record pre/post SHA-256 equality, update the exact pack-local manifest and producer/reference, run its generator `--check`, and preserve stable runtime identity. Hash filenames remain allowed only for content-addressed runtime blobs behind semantic pack-local manifest keys.

## Path-by-path inventory

Every tracked non-manifest file under `AssetLab/artifacts` appears exactly once below. Each heading provides its semantic pack/family, variant bucket, provenance class, exact known owner/generator/reference set, and relocation disposition. The filename supplies the existing stable identity and explicit variant; no new identity is inferred.

### app-launch-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/launch-app.js`, `docs/app-launch-loading-current.md`, `docs/asset-questions-decisions.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/app-launch-proof-v0.1.png`
- `AssetLab/artifacts/app-launch-proof-v0.2.png`

### atmosphere-presentation-v0.1 · contact

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/atmosphere-presentation-v0.1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/atmosphere-presentation-v0.1/contact/elevation-contact-shade-matrix-800pct.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/contact/elevation-contact-shade-matrix-grayscale-800pct.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/contact/motion-band-matrix.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/contact/native-family-contact-sheet-400pct.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/contact/phone-proof-matrix-grayscale.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/contact/phone-proof-matrix.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/contact/visibility-disclosure-matrix.png`

### atmosphere-presentation-v0.1 · evidence

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/atmosphere-presentation-v0.1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/ash-heavy-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/ash-heavy-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/ash-light-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/ash-light-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/clear-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/clear-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/fog-heavy-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/fog-heavy-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/miasma-heavy-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/miasma-heavy-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/miasma-light-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/miasma-light-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/mist-light-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/mist-light-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/mist-snow-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/mist-snow-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/mixed-heavy-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/mixed-heavy-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/mixed-light-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/mixed-light-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/motion-calm-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/motion-moving-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/motion-strong-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/rain-heavy-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/rain-heavy-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/rain-light-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/rain-light-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/smoke-heavy-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/smoke-heavy-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/smoke-light-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/smoke-light-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/smoke-rain-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/smoke-rain-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/smoke-trace-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/smoke-trace-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/snow-heavy-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/snow-heavy-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/snow-light-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/snow-light-grayscale-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/visibility-boundaries-368x800.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/evidence/visibility-boundaries-remote-mutation-368x800.png`

### atmosphere-presentation-v0.1 · source

- Provenance class: deterministic/procedural proof source
- Relocation disposition: **provenance-blocked**
- Exact known owner/generator/reference: `AssetLab/artifacts/atmosphere-presentation-v0.1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/airborneAsh-dense-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/airborneAsh-heavy-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/airborneAsh-light-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/airborneAsh-trace-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/contact-shade-equal-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/contact-shade-one-step-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/contact-shade-two-step-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/miasma-dense-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/miasma-heavy-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/miasma-light-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/miasma-trace-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/mist-dense-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/mist-heavy-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/mist-light-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/mist-trace-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/mixedRainSnow-dense-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/mixedRainSnow-heavy-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/mixedRainSnow-light-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/mixedRainSnow-trace-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/rain-dense-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/rain-heavy-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/rain-light-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/rain-trace-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/smoke-dense-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/smoke-heavy-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/smoke-light-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/smoke-trace-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/snow-dense-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/snow-heavy-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/snow-light-logical-16x16.png`
- `AssetLab/artifacts/atmosphere-presentation-v0.1/source/snow-trace-logical-16x16.png`

### authored-color-vocabulary-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/scripts/export-authored-color-vocabulary-proof.mjs`, `docs/asset-questions-decisions.md`, `docs/asset-system-proposal.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/authored-color-vocabulary-proof-v0.1-color.png`
- `AssetLab/artifacts/authored-color-vocabulary-proof-v0.1-grayscale.png`
- `AssetLab/artifacts/authored-color-vocabulary-proof-v0.1.json`

### authored-color-writing-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: **none recorded; provenance blocker**
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/authored-color-writing-proof-v0.1.json`
- `AssetLab/artifacts/authored-color-writing-proof-v0.1.png`

### blacksmith-pointed-blade-checkpoint-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/equipment-app.js`, `docs/asset-questions-decisions.md`, `docs/asset-system-proposal.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/blacksmith-pointed-blade-checkpoint-proof-v0.1.png`

### campaign-bookplate-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/campaign-app.js`, `docs/asset-system-proposal.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/campaign-bookplate-proof-v0.1.png`
- `AssetLab/artifacts/campaign-bookplate-proof-v0.2.png`

### catalogue-item-identity-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/equipment-app.js`, `docs/asset-questions-decisions.md`, `docs/asset-system-proposal.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/catalogue-item-identity-proof-v0.1.png`
- `AssetLab/artifacts/catalogue-item-identity-proof-v0.2.png`

### catalogue-tier2-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/scripts/export-tier2-proof.mjs`, `AssetLab/src/equipment-app.js`, `docs/asset-questions-decisions.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/catalogue-tier2-proof-v0.1.json`
- `AssetLab/artifacts/catalogue-tier2-proof-v0.1.png`

### catalogue-tier3-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/scripts/export-tier3-proof.mjs`, `docs/asset-questions-decisions.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/catalogue-tier3-proof-v0.1.json`
- `AssetLab/artifacts/catalogue-tier3-proof-v0.1.png`

### character-identity-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/integration/named-character-placeholders-v1/manifest.json`, `AssetLab/scripts/export-named-character-placeholder-pack.mjs`, `AssetLab/src/characters-app.js`, `docs/asset-questions-decisions.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/character-identity-proof-v0.1.png`
- `AssetLab/artifacts/character-identity-proof-v0.2.png`
- `AssetLab/artifacts/character-identity-proof-v0.3.png`
- `AssetLab/artifacts/character-identity-proof-v0.4.png`

### combat-node-placeholder-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/scripts/export-combat-node-placeholder-proof.mjs`, `docs/asset-system-proposal.md`, `docs/combat-node-glyph-vocabulary-current.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/combat-node-placeholder-proof-v0.1.json`
- `AssetLab/artifacts/combat-node-placeholder-proof-v0.1.png`

### combat-tree · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/artifacts/combat-tree-true-graph-proof-v0.3.json`, `AssetLab/scripts/audit-combat-v2-routes.mjs`, `AssetLab/tests/combat-tree-v2-route-audit.test.js`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/combat-tree-v2-route-audit.json`

### combat-tree-accessibility-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: **none recorded; provenance blocker**
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/combat-tree-accessibility-proof.html`

### combat-tree-functional-layout-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/scripts/export-combat-functional-layout-proof.mjs`, `AssetLab/tests/combat-tree-functional-layout-proof.test.js`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/combat-tree-functional-layout-proof-v0.4-large-text.png`
- `AssetLab/artifacts/combat-tree-functional-layout-proof-v0.4.json`
- `AssetLab/artifacts/combat-tree-functional-layout-proof-v0.4.png`

### combat-tree-graph-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/combat-tree-true-graph-proof-v0.3.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/combat-tree-graph-proof-v0.1.json`
- `AssetLab/artifacts/combat-tree-graph-proof-v0.1.png`
- `AssetLab/artifacts/combat-tree-graph-proof-v0.2-large-text.png`
- `AssetLab/artifacts/combat-tree-graph-proof-v0.2.json`
- `AssetLab/artifacts/combat-tree-graph-proof-v0.2.png`
- `AssetLab/artifacts/combat-tree-graph-proof.html`

### combat-tree-true-graph-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/scripts/export-combat-v03-accessibility.mjs`, `AssetLab/scripts/export-combat-v03-proof.mjs`, `docs/asset-system-proposal.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/combat-tree-true-graph-proof-v0.3-large-text.png`
- `AssetLab/artifacts/combat-tree-true-graph-proof-v0.3.json`
- `AssetLab/artifacts/combat-tree-true-graph-proof-v0.3.png`
- `AssetLab/artifacts/combat-tree-true-graph-proof.html`

### combat-ui-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `docs/asset-system-proposal.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/combat-ui-proof-v0.1.png`

### constellation-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/artifacts/constellation-proof-v0.1.json`, `AssetLab/scripts/export-constellation-proof.mjs`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/constellation-proof-v0.1.json`
- `AssetLab/artifacts/constellation-proof-v0.1.png`

### consumable-field-kit-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/artifacts/consumable-field-kit-proof-v0.1.json`, `AssetLab/integration/catalogue-consumables-placeholder-v1/manifest.json`, `AssetLab/scripts/export-consumable-field-kit-proof.mjs`, `AssetLab/scripts/export-consumable-identity-placeholder-pack.mjs`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/consumable-field-kit-proof-v0.1.json`
- `AssetLab/artifacts/consumable-field-kit-proof-v0.1.png`

### creature-diversity-foundation · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/artifacts/creature-diversity-foundation-v0.1.json`, `AssetLab/scripts/export-creature-diversity-foundation.mjs`, `AssetLab/tests/creature-diversity-foundation.test.js`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/creature-diversity-foundation-v0.1.json`
- `AssetLab/artifacts/creature-diversity-foundation-v0.1.png`

### debug-bug-reporter-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/reporter-app.js`, `docs/asset-questions-decisions.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/debug-bug-reporter-proof-v0.1.png`
- `AssetLab/artifacts/debug-bug-reporter-proof-v0.2.png`
- `AssetLab/artifacts/debug-bug-reporter-proof-v0.3.png`

### dynamic-terrain-style-v0.2 · evidence

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/dynamic-terrain-style-v0.2/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/ash-stone-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/ash-stone-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/ash-stone-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/ash-stone-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/chasm-stone-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/chasm-stone-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/chasm-stone-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/chasm-stone-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-identical-a-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-identical-a-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-identical-a-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-identical-a-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-identical-a-phone-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-opposed-cool-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-opposed-cool-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-opposed-cool-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-opposed-cool-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-opposed-cool-phone-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-opposed-warm-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-opposed-warm-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-opposed-warm-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-opposed-warm-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-growth-opposed-warm-phone-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-identical-a-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-identical-a-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-identical-a-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-identical-a-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-identical-a-phone-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-opposed-cool-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-opposed-cool-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-opposed-cool-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-opposed-cool-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-opposed-cool-phone-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-opposed-warm-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-opposed-warm-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-opposed-warm-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-opposed-warm-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-soil-opposed-warm-phone-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-identical-a-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-identical-a-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-identical-a-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-identical-a-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-identical-a-phone-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-opposed-cool-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-opposed-cool-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-opposed-cool-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-opposed-cool-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-opposed-cool-phone-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-opposed-warm-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-opposed-warm-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-opposed-warm-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-opposed-warm-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/deposit-snow-ash-both-stone-opposed-warm-phone-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/groundcover-growth-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/groundcover-growth-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/groundcover-growth-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/groundcover-growth-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/ice-water-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/ice-water-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/ice-water-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/ice-water-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/mud-soil-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/mud-soil-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/mud-soil-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/mud-soil-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/phone-identical-a-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/phone-identical-a-grayscale-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/phone-motion-0-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/phone-motion-1-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/phone-motion-2-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/phone-motion-3-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/phone-opposed-cool-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/phone-opposed-cool-grayscale-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/phone-opposed-warm-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/phone-opposed-warm-grayscale-368x800.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/rubble-stone-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/rubble-stone-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/rubble-stone-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/rubble-stone-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-ash-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-ash-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-ash-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-ash-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-chasm-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-chasm-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-chasm-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-chasm-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-deepWater-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-deepWater-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-deepWater-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-deepWater-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-groundcover-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-groundcover-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-groundcover-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-groundcover-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-growth-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-growth-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-growth-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-growth-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-ice-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-ice-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-ice-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-ice-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-mud-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-mud-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-mud-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-mud-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-rubble-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-rubble-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-rubble-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-rubble-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-sand-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-sand-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-sand-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-sand-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-soil-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-soil-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-soil-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-soil-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-stone-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-stone-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-stone-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-stone-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-water-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-water-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-water-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/same-water-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/sand-soil-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/sand-soil-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/sand-soil-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/sand-soil-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/semantic-role-mask-sheet.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/snow-over-all-identical-a-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/snow-over-all-identical-a-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/snow-over-all-identical-a-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/snow-over-all-identical-a-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/snow-over-all-opposed-cool-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/snow-over-all-opposed-cool-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/snow-over-all-opposed-cool-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/snow-over-all-opposed-cool-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/snow-over-all-opposed-warm-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/snow-over-all-opposed-warm-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/snow-over-all-opposed-warm-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/snow-over-all-opposed-warm-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/source-macro-sheet-350pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/source-macro-sheet-grayscale-350pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/stone-soil-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/stone-soil-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/stone-soil-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/stone-soil-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/t-cross-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/t-cross-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/t-cross-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/t-cross-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/turning-shoreline-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/turning-shoreline-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/turning-shoreline-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/turning-shoreline-native.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/water-deep-2x.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/water-deep-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/water-deep-grayscale-400pct.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/evidence/water-deep-native.png`

### dynamic-terrain-style-v0.2 · production

- Provenance class: functional/candidate visual derivative
- Relocation disposition: **authority-review-required**
- Exact known owner/generator/reference: `AssetLab/artifacts/dynamic-terrain-style-v0.2/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/macro/ash-semantic-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/macro/chasm-semantic-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/macro/deepWater-semantic-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/macro/groundcover-semantic-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/macro/growth-semantic-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/macro/ice-semantic-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/macro/mud-semantic-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/macro/rubble-semantic-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/macro/sand-semantic-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/macro/snow-cover-semantic-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/macro/soil-semantic-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/macro/stone-semantic-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/macro/water-semantic-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/deepWater-phase-0-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/deepWater-phase-1-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/deepWater-phase-2-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/deepWater-phase-3-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/groundcover-phase-0-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/groundcover-phase-1-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/groundcover-phase-2-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/groundcover-phase-3-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/growth-phase-0-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/growth-phase-1-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/growth-phase-2-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/growth-phase-3-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/water-phase-0-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/water-phase-1-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/water-phase-2-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/motion/water-phase-3-16x16.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/ash-body-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/ash-bodyDark-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/ash-bodyLight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/ash-deepShadow-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/ash-highlight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/chasm-body-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/chasm-bodyDark-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/chasm-bodyLight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/chasm-deepShadow-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/chasm-highlight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/deepWater-body-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/deepWater-bodyDark-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/deepWater-bodyLight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/deepWater-deepShadow-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/deepWater-highlight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/groundcover-body-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/groundcover-bodyDark-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/groundcover-bodyLight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/groundcover-deepShadow-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/groundcover-highlight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/growth-body-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/growth-bodyDark-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/growth-bodyLight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/growth-deepShadow-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/growth-highlight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/ice-body-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/ice-bodyDark-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/ice-bodyLight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/ice-deepShadow-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/ice-highlight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/mud-body-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/mud-bodyDark-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/mud-bodyLight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/mud-deepShadow-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/mud-highlight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/rubble-body-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/rubble-bodyDark-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/rubble-bodyLight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/rubble-deepShadow-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/rubble-highlight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/sand-body-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/sand-bodyDark-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/sand-bodyLight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/sand-deepShadow-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/sand-highlight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/snow-body-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/snow-bodyDark-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/snow-bodyLight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/snow-deepShadow-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/snow-highlight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/soil-body-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/soil-bodyDark-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/soil-bodyLight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/soil-deepShadow-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/soil-highlight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/stone-body-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/stone-bodyDark-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/stone-bodyLight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/stone-deepShadow-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/stone-highlight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/water-body-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/water-bodyDark-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/water-bodyLight-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/water-deepShadow-mask-64x64.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/production/roles/water-highlight-mask-64x64.png`

### dynamic-terrain-style-v0.2 · reference

- Provenance class: non-production reference
- Relocation disposition: **provenance-blocked**
- Exact known owner/generator/reference: `AssetLab/artifacts/dynamic-terrain-style-v0.2/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/dynamic-terrain-style-v0.2/reference/accepted-generated-source.png`
- `AssetLab/artifacts/dynamic-terrain-style-v0.2/reference/expansion-generated-source.png`

### economy-five-identity-bridge-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/bridge-app.js`, `docs/asset-system-proposal.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/economy-five-identity-bridge-proof-v0.1.png`
- `AssetLab/artifacts/economy-five-identity-bridge-proof-v0.2.png`
- `AssetLab/artifacts/economy-five-identity-bridge-proof-v0.3.png`

### economy-stations-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/places-app.js`, `docs/asset-questions-decisions.md`, `docs/asset-system-proposal.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/economy-stations-proof-v0.1.png`

### equipment-grid-bridge-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `docs/asset-questions-decisions.md`, `docs/asset-system-proposal.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/equipment-grid-bridge-proof-v0.1.png`
- `AssetLab/artifacts/equipment-grid-bridge-proof-v0.2.png`

### equipment-six-across-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/equipment-app.js`, `docs/asset-questions-decisions.md`, `docs/asset-system-proposal.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/equipment-six-across-proof-v0.3.png`

### flora-overhead-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/integration/map-slice-v1/manifest 3.json`, `AssetLab/integration/map-slice-v1/manifest.json`, `AssetLab/scripts/export-map-slice.mjs`, `AssetLab/src/world-app.js`, `docs/asset-questions-decisions.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/flora-overhead-proof-v0.2.png`

### full-cast-descriptor-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/integration/named-character-placeholders-v1/manifest.json`, `AssetLab/scripts/export-named-character-placeholder-pack.mjs`, `AssetLab/src/full-cast-app.js`, `docs/asset-questions-decisions.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/full-cast-descriptor-proof-v0.1.png`
- `AssetLab/artifacts/full-cast-descriptor-proof-v0.2.png`

### map-top-down-character-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/map-character-proof-app.js`, `docs/asset-questions-decisions.md`, `docs/asset-system-proposal.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/map-top-down-character-proof-v0.1.png`
- `AssetLab/artifacts/map-top-down-character-proof-v0.2.png`
- `AssetLab/artifacts/map-top-down-character-proof-v0.3.png`

### map-top-down-full-cast-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/integration/named-character-placeholders-v1/manifest.json`, `AssetLab/scripts/export-named-character-placeholder-pack.mjs`, `AssetLab/src/map-full-cast-app.js`, `docs/asset-questions-decisions.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/map-top-down-full-cast-proof-v0.1.png`

### mixed-ink-mixer-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: **none recorded; provenance blocker**
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/mixed-ink-mixer-proof-v0.1.json`
- `AssetLab/artifacts/mixed-ink-mixer-proof-v0.1.png`

### multi-species-map-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `docs/asset-questions-decisions.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/multi-species-map-proof-v0.1.jpg`

### place-identity-adaptation-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/places-app.js`, `docs/asset-questions-decisions.md`, `docs/home-village-library-asset-packet-current.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/place-identity-adaptation-proof-v0.1.png`
- `AssetLab/artifacts/place-identity-adaptation-proof-v0.2.png`
- `AssetLab/artifacts/place-identity-adaptation-proof-v0.3.png`
- `AssetLab/artifacts/place-identity-adaptation-proof-v0.4.png`

### provisional-noll-identity-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/integration/named-character-placeholders-v1/manifest.json`, `AssetLab/scripts/export-named-character-placeholder-pack.mjs`, `AssetLab/src/noll-app.js`, `docs/asset-questions-decisions.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/provisional-noll-identity-proof-v0.1.png`
- `AssetLab/artifacts/provisional-noll-identity-proof-v0.2.png`

### research-graph-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/scripts/export-research-graph-accessibility.mjs`, `AssetLab/scripts/export-research-graph-proof.mjs`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/research-graph-proof-v0.1-large-text.png`
- `AssetLab/artifacts/research-graph-proof-v0.1.json`
- `AssetLab/artifacts/research-graph-proof-v0.1.png`

### resource-mining-feedback-v1 · evidence

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/resource-mining-feedback-v1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/resource-mining-feedback-v1/evidence/m01-end-368x800.png`
- `AssetLab/artifacts/resource-mining-feedback-v1/evidence/m01-mid-368x800.png`
- `AssetLab/artifacts/resource-mining-feedback-v1/evidence/m01-start-368x800.png`
- `AssetLab/artifacts/resource-mining-feedback-v1/evidence/m02-multi-output-368x800.png`
- `AssetLab/artifacts/resource-mining-feedback-v1/evidence/m05-refusal-368x800.png`
- `AssetLab/artifacts/resource-mining-feedback-v1/evidence/m08-interruption-368x800.png`
- `AssetLab/artifacts/resource-mining-feedback-v1/evidence/m09-relaunch-368x800.png`
- `AssetLab/artifacts/resource-mining-feedback-v1/evidence/m10-missing-identity-368x800.png`

### resource-mining-feedback-v1 · review-contact-sheet.png

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/resource-mining-feedback-v1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/resource-mining-feedback-v1/review-contact-sheet.png`

### resource-node-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/resources-app.js`, `docs/asset-questions-decisions.md`, `docs/asset-system-proposal.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/resource-node-proof-v0.1.png`
- `AssetLab/artifacts/resource-node-proof-v0.2.png`
- `AssetLab/artifacts/resource-node-proof-v0.3.png`
- `AssetLab/artifacts/resource-node-proof-v0.4.png`
- `AssetLab/artifacts/resource-node-proof-v0.5.png`
- `AssetLab/artifacts/resource-node-proof-v0.6.png`

### splash-lifecycle-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/splashes-app.js`, `docs/asset-questions-decisions.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/splash-lifecycle-proof-v0.1.png`
- `AssetLab/artifacts/splash-lifecycle-proof-v0.2.png`
- `AssetLab/artifacts/splash-lifecycle-proof-v0.3.png`

### terrain-lifted-extrusion-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/world-app.js`, `docs/asset-questions-decisions.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/terrain-lifted-extrusion-proof-v0.1.png`

### terrain-region-continuity-v1 · evidence

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/terrain-region-continuity-v1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-growth-2x.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-growth-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-growth-grayscale-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-growth-native.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-soil-2x.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-soil-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-soil-grayscale-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-soil-native.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-stone-2x.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-stone-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-stone-grayscale-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-stone-native.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-water-2x.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-water-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-water-grayscale-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/cluster-water-native.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/corridor-1-2x.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/corridor-1-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/corridor-1-grayscale-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/corridor-1-native.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/corridor-2-2x.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/corridor-2-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/corridor-2-grayscale-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/corridor-2-native.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/equal-height-vs-south-wall-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/equal-height-vs-south-wall-grayscale-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/junction-t-cross-2x.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/junction-t-cross-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/junction-t-cross-grayscale-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/junction-t-cross-native.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/macro-11x11-redraw-a-2x.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/macro-11x11-redraw-b-2x.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/phone-old-current-corrected-368x800.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/phone-old-current-corrected-grayscale-368x800.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/phone-visibility-368x800.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/pool-deep-2x.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/pool-deep-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/pool-deep-grayscale-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/pool-deep-native.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/stone-rubble-2x.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/stone-rubble-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/stone-rubble-grayscale-400pct.png`
- `AssetLab/artifacts/terrain-region-continuity-v1/evidence/stone-rubble-native.png`

### terrain-region-continuity-v1 · native-adapter-conformance.json

- Provenance class: review metadata/evidence
- Relocation disposition: **authority-review-required**
- Exact known owner/generator/reference: `AssetLab/artifacts/terrain-region-continuity-v1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/terrain-region-continuity-v1/native-adapter-conformance.json`

### terrain-region-continuity-v1 · review-contact-sheet.png

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/terrain-region-continuity-v1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/terrain-region-continuity-v1/review-contact-sheet.png`

### tile-content-collision-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/world-app.js`, `docs/asset-questions-decisions.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/tile-content-collision-proof-v0.1.png`
- `AssetLab/artifacts/tile-content-collision-proof-v0.2.png`

### trading-post-vance-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/src/trading-app.js`, `docs/asset-questions-decisions.md`, `docs/asset-system-proposal.md`, `docs/trading-post-vance-asset-handoff-current.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/trading-post-vance-proof-v0.1.png`
- `AssetLab/artifacts/trading-post-vance-proof-v0.2.png`

### traveller-adjacent-speech-v1 · evidence

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/traveller-adjacent-speech-v1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/traveller-adjacent-speech-v1/evidence/t01-mara-enter-368x800.png`
- `AssetLab/artifacts/traveller-adjacent-speech-v1/evidence/t01-mara-hold-368x800.png`
- `AssetLab/artifacts/traveller-adjacent-speech-v1/evidence/t01-mara-hold-grayscale-368x800.png`
- `AssetLab/artifacts/traveller-adjacent-speech-v1/evidence/t05-nondisclosed-368x800.png`
- `AssetLab/artifacts/traveller-adjacent-speech-v1/evidence/t06-same-tile-meeting-368x800.png`
- `AssetLab/artifacts/traveller-adjacent-speech-v1/evidence/t07-fifo-east-368x800.png`
- `AssetLab/artifacts/traveller-adjacent-speech-v1/evidence/t07-fifo-north-368x800.png`
- `AssetLab/artifacts/traveller-adjacent-speech-v1/evidence/t08-cleared-368x800.png`
- `AssetLab/artifacts/traveller-adjacent-speech-v1/evidence/t13-oda-wrap-368x800.png`
- `AssetLab/artifacts/traveller-adjacent-speech-v1/evidence/t13-tovin-wrap-368x800.png`

### traveller-adjacent-speech-v1 · review-contact-sheet.png

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/traveller-adjacent-speech-v1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/traveller-adjacent-speech-v1/review-contact-sheet.png`

### traveller-adjacent-speech-v1 · sprites

- Provenance class: functional/candidate visual derivative
- Relocation disposition: **authority-review-required**
- Exact known owner/generator/reference: `AssetLab/artifacts/traveller-adjacent-speech-v1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/traveller-adjacent-speech-v1/sprites/binder-map.png`
- `AssetLab/artifacts/traveller-adjacent-speech-v1/sprites/mara-map.png`
- `AssetLab/artifacts/traveller-adjacent-speech-v1/sprites/noll-map.png`
- `AssetLab/artifacts/traveller-adjacent-speech-v1/sprites/oda-map.png`
- `AssetLab/artifacts/traveller-adjacent-speech-v1/sprites/tovin-map.png`

### world-arrival-v0.1 · evidence

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/world-arrival-v0.1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/world-arrival-v0.1/evidence/ash_open_color-first-map-crop-90x90.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/disclosure-ash-phone-matrix-grayscale.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/disclosure-ash-phone-matrix.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/longest_copy-first-map-crop-90x90.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/near-far-phone-matrix-grayscale.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/near-far-phone-matrix.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/near_flora-first-map-crop-90x90.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/pixel-parts-native-and-400pct.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/runtime-parts-contact-sheet-400pct.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/runtime-parts-contact-sheet-native.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/starter-phone-continuity-matrix-grayscale.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/starter-phone-continuity-matrix.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/starter_open_meadow-first-map-crop-90x90.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/starter_rainwashed_shore-first-map-crop-90x90.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/starter_stone_hollow-first-map-crop-90x90.png`
- `AssetLab/artifacts/world-arrival-v0.1/evidence/visible_site_candidate-first-map-crop-90x90.png`

### world-arrival-v0.1 · parts

- Provenance class: functional/candidate visual derivative
- Relocation disposition: **authority-review-required**
- Exact known owner/generator/reference: `AssetLab/artifacts/world-arrival-v0.1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/world-arrival-v0.1/parts/broken-stone-shelf-400pct.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/broken-stone-shelf-native.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/entryMark-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/flora-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/frame-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/ground-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/illumination-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/material-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/organic-pool-bank-400pct.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/organic-pool-bank-native.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/precipitation-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/rock-cluster-400pct.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/rock-cluster-native.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/succulent-crown-400pct.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/succulent-crown-native.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/suspended-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/parts/water-logical-160x100.png`

### world-arrival-v0.1 · phones

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/world-arrival-v0.1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/world-arrival-v0.1/phones/ash_open_color-368x800.png`
- `AssetLab/artifacts/world-arrival-v0.1/phones/ash_open_color-grayscale-368x800.png`
- `AssetLab/artifacts/world-arrival-v0.1/phones/longest_copy-368x800.png`
- `AssetLab/artifacts/world-arrival-v0.1/phones/longest_copy-grayscale-368x800.png`
- `AssetLab/artifacts/world-arrival-v0.1/phones/near_flora-368x800.png`
- `AssetLab/artifacts/world-arrival-v0.1/phones/near_flora-grayscale-368x800.png`
- `AssetLab/artifacts/world-arrival-v0.1/phones/starter_open_meadow-368x800.png`
- `AssetLab/artifacts/world-arrival-v0.1/phones/starter_open_meadow-grayscale-368x800.png`
- `AssetLab/artifacts/world-arrival-v0.1/phones/starter_rainwashed_shore-368x800.png`
- `AssetLab/artifacts/world-arrival-v0.1/phones/starter_rainwashed_shore-grayscale-368x800.png`
- `AssetLab/artifacts/world-arrival-v0.1/phones/starter_stone_hollow-368x800.png`
- `AssetLab/artifacts/world-arrival-v0.1/phones/starter_stone_hollow-grayscale-368x800.png`
- `AssetLab/artifacts/world-arrival-v0.1/phones/visible_site_candidate-368x800.png`
- `AssetLab/artifacts/world-arrival-v0.1/phones/visible_site_candidate-grayscale-368x800.png`

### world-arrival-v0.1 · references

- Provenance class: non-production reference
- Relocation disposition: **provenance-blocked**
- Exact known owner/generator/reference: `AssetLab/artifacts/world-arrival-v0.1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/world-arrival-v0.1/references/composition-reference-v0.2.png`

### world-arrival-v0.1 · scenes

- Provenance class: functional/candidate visual derivative
- Relocation disposition: **authority-review-required**
- Exact known owner/generator/reference: `AssetLab/artifacts/world-arrival-v0.1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/world-arrival-v0.1/scenes/ash_open_color-grayscale-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/scenes/ash_open_color-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/scenes/longest_copy-grayscale-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/scenes/longest_copy-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/scenes/near_flora-grayscale-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/scenes/near_flora-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/scenes/starter_open_meadow-grayscale-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/scenes/starter_open_meadow-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/scenes/starter_rainwashed_shore-grayscale-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/scenes/starter_rainwashed_shore-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/scenes/starter_stone_hollow-grayscale-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/scenes/starter_stone_hollow-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/scenes/visible_site_candidate-grayscale-logical-160x100.png`
- `AssetLab/artifacts/world-arrival-v0.1/scenes/visible_site_candidate-logical-160x100.png`

### world-field-feedback-visual-v1 · evidence

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/world-field-feedback-visual-v1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/world-field-feedback-visual-v1/evidence/world-feedback-context-only-368x800.png`
- `AssetLab/artifacts/world-field-feedback-visual-v1/evidence/world-feedback-dark-368x800.png`
- `AssetLab/artifacts/world-field-feedback-visual-v1/evidence/world-feedback-grayscale-368x800.png`
- `AssetLab/artifacts/world-field-feedback-visual-v1/evidence/world-feedback-light-368x800.png`

### world-field-feedback-visual-v1 · review-contact-sheet.png

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/world-field-feedback-visual-v1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/world-field-feedback-visual-v1/review-contact-sheet.png`

### world-grade-2-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/scripts/export-world-grade-v2-keyed.mjs`, `AssetLab/scripts/export-world-grade-v2-proof.mjs`, `docs/asset-system-proposal.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/world-grade-2-proof-v0.1-color.png`
- `AssetLab/artifacts/world-grade-2-proof-v0.1-grayscale.png`
- `AssetLab/artifacts/world-grade-2-proof-v0.1-light-sequence.png`
- `AssetLab/artifacts/world-grade-2-proof-v0.1.json`
- `AssetLab/artifacts/world-grade-2-proof-v0.2-color.png`
- `AssetLab/artifacts/world-grade-2-proof-v0.2-grayscale.png`
- `AssetLab/artifacts/world-grade-2-proof-v0.2-keyed.png`
- `AssetLab/artifacts/world-grade-2-proof-v0.2-light-sequence.png`
- `AssetLab/artifacts/world-grade-2-proof-v0.2.json`

### world-history-proof · loose-review

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/references: `AssetLab/artifacts/world-history-proof-v0.1.json`, `AssetLab/scripts/export-world-history-proof.mjs`, `docs/asset-system-proposal.md`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/world-history-proof-v0.1.json`
- `AssetLab/artifacts/world-history-proof-v0.1.png`

### world-material-pixel-correction-v1 · world-carried-materials-dark-368x800.png

- Provenance class: review metadata/evidence
- Relocation disposition: **authority-review-required**
- Exact known owner/generator/references: **none recorded; provenance blocker**
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/world-material-pixel-correction-v1/world-carried-materials-dark-368x800.png`

### world-material-pixel-correction-v1 · world-carried-materials-grayscale-368x800.png

- Provenance class: review metadata/evidence
- Relocation disposition: **authority-review-required**
- Exact known owner/generator/references: **none recorded; provenance blocker**
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/world-material-pixel-correction-v1/world-carried-materials-grayscale-368x800.png`

### world-material-pixel-correction-v1 · world-carried-materials-light-368x800.png

- Provenance class: review metadata/evidence
- Relocation disposition: **authority-review-required**
- Exact known owner/generator/references: **none recorded; provenance blocker**
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/world-material-pixel-correction-v1/world-carried-materials-light-368x800.png`

### writing-page-a1-v0.1 · source

- Provenance class: deterministic/procedural proof source
- Relocation disposition: **provenance-blocked**
- Exact known owner/generator/reference: `AssetLab/artifacts/writing-page-a1-v0.1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/writing-page-a1-v0.1/source/disclosure/writing.unread-marker-9x7.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/hands/writing.hand.brush.archipelago-81x27.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/hands/writing.hand.brush.caverns-81x27.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/hands/writing.hand.brush.plains-81x27.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/hands/writing.hand.brush.verdant-81x27.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/hands/writing.hand.charcoal.archipelago-81x54.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/hands/writing.hand.charcoal.caverns-81x54.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/hands/writing.hand.charcoal.plains-81x54.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/hands/writing.hand.charcoal.verdant-81x54.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/hands/writing.hand.fountain.archipelago-27x27.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/hands/writing.hand.fountain.caverns-27x27.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/hands/writing.hand.fountain.plains-27x27.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/hands/writing.hand.fountain.verdant-27x27.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/page/writing.page.blank-172x172.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/states/writing.state.connectSource-81x27.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/states/writing.state.connectTarget-81x27.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/states/writing.state.disconnect-81x27.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/states/writing.state.illegal-81x27.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/states/writing.state.legal-81x27.png`
- `AssetLab/artifacts/writing-page-a1-v0.1/source/states/writing.state.selected-81x27.png`

### writing-page-a2-v0.1 · source

- Provenance class: deterministic/procedural proof source
- Relocation disposition: **provenance-blocked**
- Exact known owner/generator/reference: `AssetLab/artifacts/writing-page-a2-v0.1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/collected.ordinary.blank-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/collected.ordinary.dense-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/collected.ordinary.partial-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/collected.selected.blank-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/collected.selected.dense-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/collected.selected.partial-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/collected.unavailable.blank-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/collected.unavailable.dense-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/collected.unavailable.partial-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/template.ordinary.blank-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/template.ordinary.dense-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/template.ordinary.partial-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/template.selected.blank-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/template.selected.dense-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/template.selected.partial-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/template.unavailable.blank-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/template.unavailable.dense-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/cards/template.unavailable.partial-82x88.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/popover/body-2-rows-82x48.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/popover/body-3-rows-82x70.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/popover/body-4-rows-82x92.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/popover/pointer-aboveLeft-5x3.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/popover/pointer-aboveRight-5x3.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/popover/pointer-belowLeft-5x3.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/popover/pointer-belowRight-5x3.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tiles/vocabulary.plains.brush.known-52x29.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tiles/vocabulary.plains.brush.unavailable-52x29.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tiles/vocabulary.plains.brush.unknown-52x29.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tiles/vocabulary.plains.fountain.known-52x29.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tiles/vocabulary.plains.fountain.selected-52x29.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tiles/vocabulary.plains.fountain.unavailable-52x29.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tiles/vocabulary.plains.fountain.unknown-52x29.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tools/tool-part-brush-20x18.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tools/tool-part-charcoal-20x18.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tools/tool-part-fountain-20x18.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tools/tool-strip-0-charcoal-ash-172x22.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tools/tool-strip-1-brush-ash-172x22.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tools/tool-strip-2-fountain-ash-172x22.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tools/tool-strip-3-brush-cool-172x22.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tools/tool-strip-4-brush-violet-172x22.png`
- `AssetLab/artifacts/writing-page-a2-v0.1/source/tools/tool-strip-5-brush-green-172x22.png`

### writing-parchment-v1 · evidence

- Provenance class: review evidence
- Relocation disposition: **evidence-relocation-queued**
- Exact known owner/generator/reference: `AssetLab/artifacts/writing-parchment-v1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/writing-parchment-v1/evidence/parchment-2x-344x344.png`
- `AssetLab/artifacts/writing-parchment-v1/evidence/parchment-400pct-688x688.png`
- `AssetLab/artifacts/writing-parchment-v1/evidence/parchment-dark-empty-writing-desk-368x800.png`
- `AssetLab/artifacts/writing-parchment-v1/evidence/parchment-dark-ink-state-writing-desk-368x800.png`
- `AssetLab/artifacts/writing-parchment-v1/evidence/parchment-empty-writing-desk-368x800.png`
- `AssetLab/artifacts/writing-parchment-v1/evidence/parchment-grayscale-2x-344x344.png`
- `AssetLab/artifacts/writing-parchment-v1/evidence/parchment-native-172x172.png`
- `AssetLab/artifacts/writing-parchment-v1/evidence/parchment-phone-368x800.png`
- `AssetLab/artifacts/writing-parchment-v1/evidence/parchment-phone-grayscale-368x800.png`

### writing-parchment-v1 · reference

- Provenance class: non-production reference
- Relocation disposition: **provenance-blocked**
- Exact known owner/generator/reference: `AssetLab/artifacts/writing-parchment-v1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/writing-parchment-v1/reference/generated-parchment-reference.png`

### writing-parchment-v1 · runtime

- Provenance class: runtime derivative
- Relocation disposition: **keep-runtime**
- Exact known owner/generator/reference: `AssetLab/artifacts/writing-parchment-v1/manifest.json`
- Stable ID / variant source: existing semantic filename and containing bucket.

- `AssetLab/artifacts/writing-parchment-v1/runtime/writing.parchment.handmade-v1-172x172.png`

## Remaining queue

1. Obtain exact Aimee-authored or approved generated-source receipts for any intended editable source.
2. Assign the 98 loose proof files to explicit pack-local evidence owners before moving them.
3. Classify candidate `production/`, `parts/`, `scenes/`, and `sprites/` derivatives before assigning a human source destination.
4. Perform one pack-bounded byte-preserving move at a time; never combine it with runtime blobs, terrain, Lantern, schema, or GameWiki work.

