import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { createRequire } from "node:module";
import {
  HEIGHT, MINIMAP_SIZE, PIVOT, SOURCE_ALPHA_THRESHOLD, SOURCE_SIZE, WIDTH, acceptedManifest, bakeCatalogueMapSprite,
  blockedPlaceholderFamilies, catalogueGear, lookupCatalogueSprite, minimapItemSprite, sha256,
} from "../src/exploration-loose-items-v1-kit.js";

const require = createRequire(import.meta.url);
const { createCanvas, loadImage } = require("@napi-rs/canvas");
const root = path.resolve(import.meta.dirname, "..");
const product = path.join(root, "integration", "exploration-loose-items-v1");
const runtime = path.join(product, "runtime");
const manifestFile = path.join(runtime, "manifest.json");
const exporter = path.join(root, "scripts", "export-exploration-loose-items-v1.mjs");

const runExport = () => execFileSync(process.execPath, [exporter], { encoding: "utf8" });
const first = runExport();
const firstManifest = fs.readFileSync(manifestFile);
const firstAssets = fs.readdirSync(path.join(runtime, "assets")).sort().map(file => [file, sha256(fs.readFileSync(path.join(runtime, "assets", file)))]);
const second = runExport();
assert.equal(first, second, "export summary drifted");
assert.deepEqual(fs.readFileSync(manifestFile), firstManifest, "manifest bytes drifted");
assert.deepEqual(fs.readdirSync(path.join(runtime, "assets")).sort().map(file => [file, sha256(fs.readFileSync(path.join(runtime, "assets", file)))]), firstAssets, "runtime assets drifted");

const manifest = JSON.parse(firstManifest);
assert.equal(manifest.schemaVersion, "exploration-loose-items-v1");
assert.equal(manifest.status, "candidate-unapproved");
assert.equal(manifest.integrationReady, false);
assert.deepEqual(fs.readdirSync(runtime).sort(), ["assets", "manifest.json"]);
assert.equal(manifest.acceptedSource.packID, "mob-gear-sprites-v1");
assert.equal(manifest.acceptedSource.canonicalBodySHA256, acceptedManifest.canonicalBodySHA256);
assert.equal(manifest.acceptedSource.integrationReady, true);
assert.deepEqual(manifest.blockedPlaceholderFamilies, blockedPlaceholderFamilies);
assert.equal(manifest.production.adaptation.runtimeGeneration, false);
assert.equal(manifest.production.adaptation.interpolation, false);
assert.equal(manifest.production.adaptation.blendedPixels, false);
assert.equal(manifest.production.adaptation.sourceAlphaThreshold, SOURCE_ALPHA_THRESHOLD);

const canonical = structuredClone(manifest);
delete canonical.canonicalBodySHA256;
assert.equal(manifest.canonicalBodySHA256, sha256(Buffer.from(JSON.stringify(canonical))));

assert.equal(catalogueGear.length, 75);
assert.equal(new Set(catalogueGear.map(row => row.catalogueID)).size, 75);
assert.deepEqual(manifest.requestABI.catalogueIDs, catalogueGear.map(row => row.catalogueID));
assert.equal(manifest.coverage.acceptedCatalogueIDs, 75);
assert.equal(manifest.coverage.mapStableKeys, 75);
assert.equal(manifest.coverage.minimapStableKeys, 1);
assert.equal(manifest.coverage.stableKeys, 76);
assert.equal(Object.keys(manifest.assetsByKey).length, 76);

async function rgbaFor(file, width, height) {
  const image = await loadImage(file);
  assert.equal(image.width, width);
  assert.equal(image.height, height);
  const canvas = createCanvas(width, height);
  const context = canvas.getContext("2d");
  context.imageSmoothingEnabled = false;
  context.drawImage(image, 0, 0);
  return new Uint8ClampedArray(context.getImageData(0, 0, width, height).data);
}

const listedRuntimeFiles = new Set();
for (const row of catalogueGear) {
  const sourceFile = path.join(path.dirname(root), row.sourceRelativePath);
  assert.equal(sha256(fs.readFileSync(sourceFile)), row.sourceSHA256, `${row.catalogueID} accepted source drift`);
  const sourceRGBA = await rgbaFor(sourceFile, SOURCE_SIZE, SOURCE_SIZE);
  const expected = bakeCatalogueMapSprite(row, sourceRGBA);
  const manifestRow = manifest.assetsByKey[expected.key];
  assert.ok(manifestRow, `${expected.key} missing`);
  assert.equal(manifestRow.catalogueID, row.catalogueID);
  assert.equal(manifestRow.visualFamilyID, row.visualFamilyID);
  assert.equal(manifestRow.sourceSHA256, row.sourceSHA256);
  assert.deepEqual(manifestRow.pivot, [PIVOT.x, PIVOT.y]);
  assert.equal(manifestRow.width, WIDTH);
  assert.equal(manifestRow.height, HEIGHT);
  assert.equal(manifestRow.bounds.maxY, 17, `${row.catalogueID} must be bottom anchored without using pivot row`);
  const runtimeFile = path.join(runtime, manifestRow.path);
  listedRuntimeFiles.add(path.basename(runtimeFile));
  assert.equal(sha256(fs.readFileSync(runtimeFile)), manifestRow.sha256);
  const actualRGBA = await rgbaFor(runtimeFile, WIDTH, HEIGHT);
  assert.deepEqual(actualRGBA, expected.rgba, `${row.catalogueID} runtime PNG differs from baked logical pixels`);
  assert.equal(sha256(Buffer.from(actualRGBA)), manifestRow.rgbaSHA256);
  for (let index = 3; index < actualRGBA.length; index += 4) assert.ok(actualRGBA[index] === 0 || actualRGBA[index] === 255, `${row.catalogueID} alpha must be binary`);

  for (const point of expected.provenance) {
    const sourceOffset = (point.sourceY * SOURCE_SIZE + point.sourceX) * 4;
    const finalOffset = (point.y * WIDTH + point.x) * 4;
    assert.deepEqual([...actualRGBA.slice(finalOffset, finalOffset + 3)], [...sourceRGBA.slice(sourceOffset, sourceOffset + 3)], `${row.catalogueID} introduced a non-source RGB`);
    assert.ok(sourceRGBA[sourceOffset + 3] >= SOURCE_ALPHA_THRESHOLD, `${row.catalogueID} promoted a source matte pixel`);
  }
}

const mini = minimapItemSprite();
const miniRow = manifest.assetsByKey[mini.key];
assert.ok(miniRow);
listedRuntimeFiles.add(path.basename(miniRow.path));
assert.deepEqual(await rgbaFor(path.join(runtime, miniRow.path), MINIMAP_SIZE, MINIMAP_SIZE), mini.rgba);
assert.deepEqual([...listedRuntimeFiles].sort(), fs.readdirSync(path.join(runtime, "assets")).sort());
assert.equal(manifest.coverage.runtimePNGs, listedRuntimeFiles.size);

const request = (catalogueID, visibility) => ({ catalogueID, visibility });
const full = lookupCatalogueSprite(manifest, request("ironwork_blade", "full"));
const remembered = lookupCatalogueSprite(manifest, request("ironwork_blade", "remembered"));
assert.deepEqual(full, remembered);
assert.equal(lookupCatalogueSprite(manifest, request("ironwork_blade", "hidden")), null);
assert.equal(lookupCatalogueSprite(manifest, request("salve", "full")), null, "placeholder-backed consumable must not resolve");
assert.equal(lookupCatalogueSprite(manifest, request("unknown", "full")), null);
assert.equal(lookupCatalogueSprite(manifest, { ...request("ironwork_blade", "full"), extra: true }), null);

const expectedEvidence = [
  "accepted-source-to-map-native-800pct", "accepted-source-to-map-native-800pct-grayscale",
  "visibility-full-remembered-hidden-800pct", "visibility-full-remembered-hidden-800pct-grayscale",
  "minimap-item-native-1600pct", "minimap-item-native-1600pct-grayscale",
  ...Array.from({ length: 5 }, (_, index) => `applied-map-catalogue-${index + 1}-368x800`),
  ...Array.from({ length: 5 }, (_, index) => `applied-map-catalogue-${index + 1}-grayscale-368x800`),
];
for (const key of expectedEvidence) {
  const row = manifest.evidence[key];
  assert.ok(row, `missing evidence ${key}`);
  const file = path.join(product, row.path);
  assert.equal(sha256(fs.readFileSync(file)), row.sha256);
  const image = await loadImage(file);
  assert.equal(image.width, row.width);
  assert.equal(image.height, row.height);
  if (key.includes("368x800")) assert.deepEqual([row.width, row.height], [368, 800]);
}

const html = fs.readFileSync(path.join(root, "exploration-loose-items-v1.html"), "utf8");
assert.ok(html.includes("candidate-unapproved"));
assert.ok(html.includes("applied-map-catalogue-5-368x800.png"));
assert.ok(html.includes("tool-nav"));
assert.ok(!/Accessibility|VoiceOver|Dynamic Type|XXXL/i.test(html));

console.log(`exploration loose items v1: 75 exact catalogue IDs, ${manifest.coverage.runtimePNGs} content-addressed PNGs; deterministic export passed`);
