import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { createCanvas, loadImage } from "@napi-rs/canvas";
import {
  HEIGHT, PIVOT, WIDTH, authoredObjectSprite, authoredSprites, catalogueSHA256,
  exactCatalogueObjectIDs, lookupObjectSprite, objectRecords, sha256,
} from "../src/exploration-catalogue-objects-v1-kit.js";

const root = path.resolve(import.meta.dirname, "..");
const product = path.join(root, "integration", "exploration-catalogue-objects-v1");
const runtime = path.join(product, "runtime");
const manifestFile = path.join(runtime, "manifest.json");
const exporter = path.join(root, "scripts", "export-exploration-catalogue-objects-v1.mjs");

const runExport = () => execFileSync(process.execPath, [exporter], { encoding: "utf8" });
const firstSummary = runExport();
const firstManifestBytes = fs.readFileSync(manifestFile);
const firstRuntimeFiles = fs.readdirSync(path.join(runtime, "assets")).sort()
  .map(file => [file, sha256(fs.readFileSync(path.join(runtime, "assets", file)))]);
const firstEvidence = fs.readdirSync(path.join(product, "evidence")).sort()
  .map(file => [file, sha256(fs.readFileSync(path.join(product, "evidence", file)))]);
const secondSummary = runExport();
assert.equal(secondSummary, firstSummary, "export summary drifted");
assert.deepEqual(fs.readFileSync(manifestFile), firstManifestBytes, "manifest bytes drifted");
assert.deepEqual(fs.readdirSync(path.join(runtime, "assets")).sort()
  .map(file => [file, sha256(fs.readFileSync(path.join(runtime, "assets", file)))]), firstRuntimeFiles, "runtime assets drifted");
assert.deepEqual(fs.readdirSync(path.join(product, "evidence")).sort()
  .map(file => [file, sha256(fs.readFileSync(path.join(product, "evidence", file)))]), firstEvidence, "evidence drifted");

const manifest = JSON.parse(firstManifestBytes);
assert.equal(manifest.schemaVersion, "exploration-catalogue-objects-v1");
assert.equal(manifest.status, "candidate-unapproved");
assert.equal(manifest.integrationReady, false);
assert.deepEqual(fs.readdirSync(runtime).sort(), ["assets", "manifest.json"]);
assert.equal(manifest.sourceAuthority.catalogueSHA256, catalogueSHA256);
assert.deepEqual(manifest.sourceAuthority.exactStableIDs, exactCatalogueObjectIDs);
assert.equal(manifest.production.runtimeGeneration, false);
assert.equal(manifest.animationContract.classification, "static");
assert.equal(manifest.animationContract.framesPerIdentity, 1);
assert.equal(manifest.coverage.catalogueIDs, 27);
assert.equal(manifest.coverage.identifiedAssets, 27);
assert.equal(manifest.coverage.unknownDisclosureAssets, 1);
assert.equal(manifest.coverage.treasures, 5);
assert.equal(manifest.coverage.curios, 2);
assert.equal(manifest.coverage.consumables, 18);
assert.equal(manifest.coverage.keys, 2);
assert.equal(manifest.coverage.stableKeys, 28);
assert.equal(Object.keys(manifest.assetsByKey).length, 28);
assert.equal(new Set(exactCatalogueObjectIDs).size, 27);
assert.deepEqual(authoredSprites.map(row => row.id), exactCatalogueObjectIDs);
assert.deepEqual(objectRecords.map(row => row.id), exactCatalogueObjectIDs);

const canonical = structuredClone(manifest);
delete canonical.canonicalBodySHA256;
assert.equal(manifest.canonicalBodySHA256, sha256(Buffer.from(JSON.stringify(canonical))));

async function rgbaFor(file, width, height) {
  const image = await loadImage(file);
  assert.deepEqual([image.width, image.height], [width, height]);
  const canvas = createCanvas(width, height);
  const context = canvas.getContext("2d");
  context.imageSmoothingEnabled = false;
  context.drawImage(image, 0, 0);
  return new Uint8ClampedArray(context.getImageData(0, 0, width, height).data);
}

const listedRuntimeFiles = new Set();
for (const id of exactCatalogueObjectIDs) {
  const expected = authoredObjectSprite(id);
  const row = manifest.assetsByKey[expected.key];
  assert.ok(row, `${expected.key} missing`);
  assert.equal(row.catalogueID, id);
  assert.equal(row.animation, "static");
  assert.deepEqual(row.pivot, [PIVOT.x, PIVOT.y]);
  assert.deepEqual([row.width, row.height], [WIDTH, HEIGHT]);
  assert.equal(row.bounds.maxY, 17, `${id} must bottom-anchor above the pivot row`);
  const file = path.join(runtime, row.path);
  listedRuntimeFiles.add(path.basename(file));
  assert.equal(sha256(fs.readFileSync(file)), row.sha256);
  const actual = await rgbaFor(file, WIDTH, HEIGHT);
  assert.deepEqual(actual, expected.rgba, `${id} runtime PNG differs from authored logical RGBA`);
  assert.equal(sha256(Buffer.from(actual)), row.rgbaSHA256);
  for (let offset = 3; offset < actual.length; offset += 4) assert.ok(actual[offset] === 0 || actual[offset] === 255, `${id} alpha must be binary`);
}

const unknownRow = manifest.assetsByKey["catalogue-item/unknown-curio"];
assert.ok(unknownRow);
listedRuntimeFiles.add(path.basename(unknownRow.path));
assert.equal(unknownRow.sha256, sha256(fs.readFileSync(path.join(runtime, unknownRow.path))));
assert.equal(unknownRow.authoring, "byte-preserved-accepted-opaque-unknown-parcel");
assert.deepEqual([...listedRuntimeFiles].sort(), fs.readdirSync(path.join(runtime, "assets")).sort());
assert.equal(manifest.coverage.runtimePNGs, listedRuntimeFiles.size);

const request = (catalogueID, identified, visibility) => ({ catalogueID, identified, visibility });
for (const id of exactCatalogueObjectIDs) {
  const full = lookupObjectSprite(manifest, request(id, true, "full"));
  const remembered = lookupObjectSprite(manifest, request(id, true, "remembered"));
  assert.ok(full, `${id} full lookup missing`);
  assert.deepEqual(remembered, full, `${id} remembered bytes must equal full`);
  assert.equal(lookupObjectSprite(manifest, request(id, true, "hidden")), null);
}
for (const id of ["curio_humming_shard", "curio_bound_knot"]) {
  assert.deepEqual(lookupObjectSprite(manifest, request(id, false, "full")), unknownRow);
  assert.deepEqual(lookupObjectSprite(manifest, request(id, false, "remembered")), unknownRow);
}
assert.equal(lookupObjectSprite(manifest, request("salve", false, "full")), null);
assert.equal(lookupObjectSprite(manifest, request("unknown", true, "full")), null);
assert.equal(lookupObjectSprite(manifest, request("salve", true, "unknown")), null);
assert.equal(lookupObjectSprite(manifest, { ...request("salve", true, "full"), extra: true }), null);

for (const reference of Object.values(manifest.sourceReferences)) {
  const file = path.join(path.dirname(root), reference.path);
  assert.equal(sha256(fs.readFileSync(file)), reference.sha256);
}
assert.equal(manifest.sourceReferences.treasuresCuriosKeys.productionSource, false);
assert.equal(manifest.sourceReferences.consumablesA.productionSource, false);
assert.equal(manifest.sourceReferences.consumablesB.productionSource, false);
assert.equal(manifest.sourceReferences.unknownCurio.productionSource, true);

const expectedEvidence = [
  "production-objects-native-800pct", "production-objects-native-800pct-grayscale",
  "curio-disclosure-and-visibility-800pct", "curio-disclosure-and-visibility-800pct-grayscale",
  ...Array.from({ length: 3 }, (_, index) => `applied-map-objects-${index + 1}-368x800`),
  ...Array.from({ length: 3 }, (_, index) => `applied-map-objects-${index + 1}-grayscale-368x800`),
];
for (const key of expectedEvidence) {
  const row = manifest.evidence[key];
  assert.ok(row, `missing evidence ${key}`);
  const file = path.join(product, row.path);
  assert.equal(sha256(fs.readFileSync(file)), row.sha256);
  const image = await loadImage(file);
  assert.deepEqual([image.width, image.height], [row.width, row.height]);
  if (key.includes("368x800")) assert.deepEqual([row.width, row.height], [368, 800]);
}

const html = fs.readFileSync(path.join(root, "exploration-catalogue-objects-v1.html"), "utf8");
assert.ok(html.includes("candidate-unapproved"));
assert.ok(html.includes("applied-map-objects-3-368x800.png"));
assert.ok(html.includes("production-objects-native-800pct.png"));
assert.ok(!/Accessibility|VoiceOver|Dynamic Type|XXXL/i.test(html));

console.log(`exploration catalogue objects v1: 27 exact IDs, 28 stable keys, ${manifest.coverage.runtimePNGs} content-addressed PNGs; deterministic export passed`);
