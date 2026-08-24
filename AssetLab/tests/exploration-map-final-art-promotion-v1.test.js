import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const receiptPath = path.join(root,
  "AssetLab/integration/exploration-map-final-art-promotion-v1/promotion-receipt.json");
const receipt = JSON.parse(fs.readFileSync(receiptPath));
const sha256 = bytes => crypto.createHash("sha256").update(bytes).digest("hex");

assert.equal(receipt.schemaVersion, "exploration-map-final-art-promotion-v1");
assert.equal(receipt.status, "aimee-approved-for-native-integration");
assert.equal(receipt.integrationReady, true);
assert.equal(receipt.approvalAuthority, "Aimee");
assert.deepEqual(receipt.sourceCommits, [
  "d3dce437a3c33dae3316d13de7625d5dc9fe9c8f",
  "33aac2dc9254ecbd4d3e256ee4efdd390d56482d",
  "bfd49d52bb3814c708161c4fe0256631dfadcb95",
]);
assert.equal(receipt.promotionPolicy.additiveReceiptOnly, true);
assert.equal(receipt.promotionPolicy.candidateManifestsRemainImmutableProvenance, true);
assert.equal(receipt.promotionPolicy.assetBytesChanged, false);
assert.equal(receipt.promotionPolicy.runtimeImageGeneration, false);
assert.deepEqual(receipt.coverage, {
  approvedStableKeys: 154,
  runtimePNGs: 141,
  catalogueIDs: 102,
  exactSites: 9,
  minimapCategories: 7,
});

const expected = {
  "exploration-map-identities-v1": {
    body: "f28a55db110b92b9b0e82b8faca28392322551aac0fd8caa588ee3b283127c67",
    aggregate: "32ada00ca207d6eac6d8eee1de4917cfb6da03cc968d218a0b2b3b4ff197e990",
    count: 50,
  },
  "exploration-loose-items-v1": {
    body: "6491f2954f2a4593a5d8f1e566410ec7acd9300627e6a7dcd780d6a9b18764c2",
    aggregate: "475680934cd1318ec9ad3789def022c77bf139412329462d576084c4774786b5",
    count: 76,
  },
  "exploration-catalogue-objects-v1": {
    body: "b3478c3dcf6d6e43fbdfdf5c6e90bc877fdbd287231c03516eccd0df1e2beeaf",
    aggregate: "9731e732f698580965faf8ecf9bdc0494b21d68746b4b19ec0f432cf4c6ad70a",
    count: 28,
  },
};
const allKeys = [];
for (const [id, pin] of Object.entries(expected)) {
  const pack = receipt.packs[id];
  const manifestBytes = fs.readFileSync(path.join(root, pack.sourceManifestPath));
  const manifest = JSON.parse(manifestBytes);
  assert.equal(pack.sourceManifestSHA256, sha256(manifestBytes));
  assert.equal(pack.sourceCanonicalBodySHA256, pin.body);
  assert.equal(pack.runtimeAssetAggregateSHA256, pin.aggregate);
  assert.equal(pack.stableKeyCount, pin.count);
  assert.deepEqual(pack.approvedStableKeys, Object.keys(manifest.assetsByKey).sort());
  assert.equal(manifest.status, "candidate-unapproved", "source provenance stays immutable");
  assert.equal(manifest.integrationReady, false, "promotion authority stays additive");
  const runtime = path.dirname(path.join(root, pack.sourceManifestPath));
  for (const key of pack.approvedStableKeys) {
    const asset = manifest.assetsByKey[key];
    assert.equal(sha256(fs.readFileSync(path.join(runtime, asset.path))), asset.sha256,
      `${id}:${key} bytes drifted`);
  }
  allKeys.push(...pack.approvedStableKeys.map(key => `${id}:${key}`));
}
assert.equal(new Set(allKeys).size, 154);

assert.deepEqual(receipt.nativeConsumption.mapCanvas, [16, 19]);
assert.deepEqual(receipt.nativeConsumption.mapPivot, [8, 18]);
assert.deepEqual(receipt.nativeConsumption.minimapCanvas, [7, 7]);
assert.equal(receipt.nativeConsumption.visibility.hidden, "no lookup and no draw");
assert.deepEqual(receipt.nativeConsumption.minimapDisclosure.keys, [
  "minimap/portal/ordinary", "minimap/page/ordinary", "minimap/site/ordinary",
  "minimap/resource/ordinary", "minimap/item", "minimap/cache/ordinary",
  "minimap/hazard/ordinary",
]);
assert.deepEqual(receipt.blockedVisibleFamilies.map(row => row.family), [
  "named-travellers", "ordinary-and-apex-creatures", "Binder", "Quill",
]);
assert.ok(receipt.blockedVisibleFamilies.every(row => row.policy === "blocked-no-lookup"));

const canonical = structuredClone(receipt);
delete canonical.canonicalBodySHA256;
assert.equal(receipt.canonicalBodySHA256, sha256(Buffer.from(JSON.stringify(canonical))));
console.log("exploration map promotion: 154 exact stable keys / 141 unchanged PNGs approved; 4 final-art families remain blocked");
