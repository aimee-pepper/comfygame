import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import { REFINED_FAMILIES } from "../src/creature-material-family-refinement-v1-kit.js";

const { createCanvas, loadImage } = createRequire(import.meta.url)("@napi-rs/canvas");
const assetLab = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const repo = path.resolve(assetLab, "..");
const sha = bytes => crypto.createHash("sha256").update(bytes).digest("hex");
const json = relative => JSON.parse(fs.readFileSync(path.join(repo, relative)));
const manifest = json("AssetLab/integration/world-material-pixel-correction-v1/manifest.json");
const pack = json("AssetLab/integration/mob-gear-sprites-v1/manifest.json");

assert.equal(manifest.provenance.parentCommit,
  "3aa44270a7930a2af52a3551200cc3060b988f81");
assert.equal(manifest.provenance.sourceCheckpoint,
  "b3a33170314998c76909f8a2f2aeeb5d038882e8");
assert.equal(manifest.integrationReady, false);
assert.deepEqual(manifest.families, [...REFINED_FAMILIES]);
assert.equal(pack.profiles.mobDropInventory.sprites.length, 23);
assert.deepEqual(pack.coverage.refinedMaterialKinds, [...REFINED_FAMILIES]);

const rgbaHashes = new Set();
const alphaMasks = new Set();
for (const row of pack.profiles.mobDropInventory.sprites) {
  const file = path.join(assetLab, "integration", "mob-gear-sprites-v1", "mob-drops", row.file);
  const bytes = fs.readFileSync(file);
  assert.equal(sha(bytes), row.sha256, row.id);
  const image = await loadImage(bytes);
  assert.deepEqual([image.width, image.height], [32, 32], row.id);
  const canvas = createCanvas(32, 32);
  const context = canvas.getContext("2d");
  context.drawImage(image, 0, 0);
  const data = context.getImageData(0, 0, 32, 32).data;
  const rgbaHash = sha(Buffer.from(data));
  const alphaMask = [];
  for (let offset = 3; offset < data.length; offset += 4) if (data[offset]) alphaMask.push(offset);
  const maskHash = sha(Buffer.from(alphaMask.join(",")));
  assert.ok(!rgbaHashes.has(rgbaHash), `RGBA collision: ${row.id}`);
  assert.ok(!alphaMasks.has(maskHash), `silhouette collision: ${row.id}`);
  rgbaHashes.add(rgbaHash);
  alphaMasks.add(maskHash);
}
assert.equal(rgbaHashes.size, 23);
assert.equal(alphaMasks.size, 23);

for (const id of REFINED_FAMILIES) {
  const packRow = pack.profiles.mobDropInventory.sprites.find(row => row.id === id);
  assert.equal(packRow.sha256, manifest.sourceRecords[id].sha256, id);
}
for (const [id, expected] of Object.entries(manifest.preservedExistingMaterialHashes)) {
  const packRow = pack.profiles.mobDropInventory.sprites.find(row => row.id === id);
  assert.equal(packRow.sha256, expected, `preserved byte drift: ${id}`);
}

for (const row of Object.values(manifest.evidence)) {
  const image = await loadImage(path.join(assetLab, "artifacts", "world-material-pixel-correction-v1", row.file));
  assert.deepEqual([image.width, image.height], [368, 800]);
}

execFileSync("python3", [path.join(assetLab, "scripts", "export-mob-gear-sprite-pack.py"), "--check"]);
execFileSync("python3", [path.join(assetLab, "scripts", "generate-mob-gear-native.py"), "--check"]);
execFileSync(process.execPath,
  [path.join(assetLab, "scripts", "export-world-material-pixel-correction-v1.mjs"), "--check"],
  { env: process.env });
console.log("World material pixel correction v1: 23 exact identities, seven no-fallback keys, evidence PASS");
