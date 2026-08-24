import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const pack = join(root, "AssetLab/integration/exploration-loose-essence-v1");
const sha = bytes => createHash("sha256").update(bytes).digest("hex");

const manifestBytes = await readFile(join(pack, "runtime/manifest.json"));
const manifest = JSON.parse(manifestBytes);
const promotion = JSON.parse(await readFile(join(pack, "promotion-receipt.json")));
const resolverBytes = await readFile(join(root, "AssetLab/src/exploration-loose-essence-v1.js"));
const focusedTestBytes = await readFile(join(root, "AssetLab/tests/exploration-loose-essence-v1.test.mjs"));

assert.equal(promotion.schemaVersion, "exploration-loose-essence-promotion-v1");
assert.equal(promotion.integrationReady, true);
assert.equal(promotion.approvalAuthority.assetVisual, "Aimee");
assert.equal(promotion.approvalAuthority.gameDesignFunctional, "Game Design Lead");
assert.equal(promotion.promotionPolicy.additiveReceiptOnly, true);
assert.equal(promotion.promotionPolicy.candidateManifestRemainsImmutableProvenance, true);
assert.equal(promotion.promotionPolicy.approvedArtBytesChanged, false);
assert.equal(manifest.integrationReady, false, "candidate manifest remains immutable provenance");
assert.equal(promotion.candidatePins.canonicalBodySHA256, manifest.canonicalBodySHA256);
assert.equal(promotion.candidatePins.manifestFileSHA256, sha(manifestBytes));
assert.equal(promotion.candidatePins.productionAggregateSHA256, manifest.productionAggregateSHA256);
assert.equal(promotion.candidatePins.resolverFileSHA256, sha(resolverBytes));
assert.equal(promotion.candidatePins.focusedTestFileSHA256, sha(focusedTestBytes));
assert.deepEqual(promotion.approvedStableKeys, Object.keys(manifest.assetsByKey));
assert.equal(promotion.nativeConsumption.temporalSelector, "presentationTick only");
assert.equal(promotion.nativeConsumption.minimapKey, null);
assert.equal(promotion.nativeConsumption.recolor, false);
assert.equal(promotion.nativeConsumption.gameplayMutation, false);
assert.deepEqual(promotion.nativeConsumption.layerOrder, manifest.layerOrder);

console.log(`exploration-loose-essence-promotion-v1 PASS · candidate ${manifest.canonicalBodySHA256}`);
