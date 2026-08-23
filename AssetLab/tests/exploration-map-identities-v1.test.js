import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { createRequire } from "node:module";
import {
  enumerateMinimapSprites, enumerateSprites, lookupSprite, sha256, sourceIdentities,
} from "../src/exploration-map-identities-v1-kit.js";
import { resourceMinimapCommands } from "../src/resource-kit.js";

const require = createRequire(import.meta.url);
const { loadImage } = require("@napi-rs/canvas");
const root = path.resolve(import.meta.dirname, "..");
const product = path.join(root, "integration", "exploration-map-identities-v1");
const runtime = path.join(product, "runtime");
const manifestFile = path.join(runtime, "manifest.json");
const exporter = path.join(root, "scripts", "export-exploration-map-identities-v1.mjs");

const runExport = () => execFileSync(process.execPath, [exporter], { encoding: "utf8" });
const first = runExport();
const firstManifest = fs.readFileSync(manifestFile);
const firstAssets = fs.readdirSync(path.join(runtime, "assets")).sort().map(file => [file, sha256(fs.readFileSync(path.join(runtime, "assets", file)))]);
const second = runExport();
assert.equal(first, second, "export summary drifted");
assert.deepEqual(fs.readFileSync(manifestFile), firstManifest, "manifest bytes drifted");
assert.deepEqual(fs.readdirSync(path.join(runtime, "assets")).sort().map(file => [file, sha256(fs.readFileSync(path.join(runtime, "assets", file)))]), firstAssets, "runtime assets drifted");

const manifest = JSON.parse(firstManifest);
assert.equal(manifest.schemaVersion, "exploration-map-identities-v1");
assert.equal(manifest.status, "candidate-unapproved");
assert.equal(manifest.integrationReady, false);
assert.equal(manifest.production.noRuntimeGeneration, true);
assert.deepEqual(fs.readdirSync(runtime).sort(), ["assets", "manifest.json"]);

const canonical = structuredClone(manifest);
delete canonical.canonicalBodySHA256;
assert.equal(manifest.canonicalBodySHA256, sha256(Buffer.from(JSON.stringify(canonical))));

const mapSprites = enumerateSprites();
const minimapSprites = enumerateMinimapSprites();
assert.equal(mapSprites.length, 44);
assert.equal(minimapSprites.length, 6);
assert.equal(Object.keys(manifest.assetsByKey).length, 50);
assert.equal(manifest.coverage.runtimePNGs, firstAssets.length);
assert.deepEqual(manifest.production.minimap.categories, ["portal", "page", "cache", "site", "hazard", "resource"]);
assert.equal(manifest.production.minimap.subtypeDisclosure, false);

const acceptedResourceMini = resourceMinimapCommands("quartz", { revealed:true, discovered:true });
assert.deepEqual(acceptedResourceMini, [
  { op:"rect", x:1, y:1, w:2, h:2, color:"#d8bd82" },
  { op:"rect", x:2, y:0, w:1, h:1, color:"#eee5d5" },
]);
const resourceMini = minimapSprites.find(sprite => sprite.identity === "resource");
assert.ok(resourceMini);
const pixel = (x,y) => [...resourceMini.rgba.slice((y * 7 + x) * 4, (y * 7 + x + 1) * 4)];
assert.deepEqual(pixel(3,1), [238,229,213,255]);
assert.deepEqual(pixel(2,2), [216,189,130,255]);
assert.deepEqual(pixel(3,3), [216,189,130,255]);
assert.deepEqual(pixel(4,2), [0,0,0,0]);

const listedFiles = new Set();
for (const [key, row] of Object.entries(manifest.assetsByKey)) {
  assert.match(row.path, /^assets\/[a-f0-9]{64}\.png$/);
  const file = path.join(runtime, row.path);
  assert.ok(fs.existsSync(file), `${key} missing asset`);
  assert.equal(sha256(fs.readFileSync(file)), row.sha256);
  assert.equal(path.basename(row.path, ".png"), row.sha256);
  listedFiles.add(path.basename(row.path));
  const image = await loadImage(file);
  assert.equal(image.width, row.width);
  assert.equal(image.height, row.height);
}
assert.deepEqual([...listedFiles].sort(), fs.readdirSync(path.join(runtime, "assets")).sort());

for (const identity of sourceIdentities) {
  const states = identity.searchable ? ["unlooted", "looted"] : ["ordinary"];
  for (const state of states) {
    const rows = mapSprites.filter(sprite => sprite.identity === identity.id && sprite.state === state);
    assert.equal(rows.length, identity.frames, `${identity.id}/${state} frame coverage`);
    assert.equal(new Set(rows.map(row => sha256(Buffer.from(row.rgba)))).size, identity.frames, `${identity.id}/${state} animation frames must be distinct`);
    rows.forEach(row => {
      assert.equal(row.width, 16);
      assert.equal(row.height, 19);
      assert.deepEqual(row.pivot, { x: 8, y: 18 });
      assert.ok([...row.rgba].some((value, index) => index % 4 === 3 && value === 255), `${row.key} must be visible`);
      for (let index = 3; index < row.rgba.length; index += 4) assert.ok(row.rgba[index] === 0 || row.rgba[index] === 255, `${row.key} alpha must be binary`);
    });
  }
  if (identity.searchable) {
    assert.notEqual(manifest.assetsByKey[`${identity.id}/unlooted/frame-0`].rgbaSHA256, manifest.assetsByKey[`${identity.id}/looted/frame-0`].rgbaSHA256, `${identity.id} looted state must be visible`);
  }
}

const request = (identity, state, visibility, presentationTick = 0, reduceMotion = false) => ({ identity, state, visibility, presentationTick, reduceMotion });
assert.equal(lookupSprite(manifest, request("the_tear", "unlooted", "full", 2))?.frame, 2);
assert.equal(lookupSprite(manifest, request("entry_portal", "ordinary", "full", 2))?.frame, 2);
assert.equal(lookupSprite(manifest, request("entry_portal", "ordinary", "remembered", 2))?.frame, 0);
assert.equal(lookupSprite(manifest, request("the_tear", "unlooted", "remembered", 2))?.frame, 0);
assert.equal(lookupSprite(manifest, request("the_tear", "unlooted", "full", 2, true))?.frame, 0);
assert.equal(lookupSprite(manifest, request("the_tear", "unlooted", "hidden", 2)), null);
assert.equal(lookupSprite(manifest, request("unknown", "ordinary", "full")), null);
assert.equal(lookupSprite(manifest, request("natural_anchor", "looted", "full")), null);
assert.equal(lookupSprite(manifest, request("locked_cache", "unlooted", "full")), null);
assert.equal(lookupSprite(manifest, { ...request("hazard", "ordinary", "full"), extra: true }), null);
assert.equal(lookupSprite(manifest, request("hazard", "ordinary", "full", Number.MAX_SAFE_INTEGER + 1)), null);

assert.deepEqual(manifest.layerContract, ["terrain", "southWall", "siteOrHazard", "party", "selectionAndInteraction", "alerts"]);
assert.ok(manifest.animationContract.forbiddenImplications.includes("spread"));
assert.ok(manifest.animationContract.forbiddenImplications.includes("depletion"));
assert.equal(manifest.visibilityContract.hidden, "no lookup and no draw");

for (const row of Object.values(manifest.sourceReferences)) {
  assert.equal(row.productionSource, false);
  const file = path.join(product, row.path.replace("source-generated/", "source-generated/"));
  assert.equal(sha256(fs.readFileSync(file)), row.sha256);
}

const expectedEvidence = [
  "production-sprites-native-400pct", "production-sprites-native-400pct-grayscale",
  "ambient-animation-strips-800pct", "ambient-animation-strips-800pct-grayscale",
  "applied-map-full-368x800", "applied-map-full-grayscale-368x800",
  "applied-map-remembered-368x800", "applied-map-remembered-grayscale-368x800",
  "applied-map-hidden-368x800", "applied-map-hidden-grayscale-368x800",
  "minimap-category-sprites-native-1600pct", "minimap-category-sprites-native-1600pct-grayscale",
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

const html = fs.readFileSync(path.join(root, "exploration-map-identities-v1.html"), "utf8");
assert.ok(html.includes("candidate-unapproved"));
assert.ok(html.includes("applied-map-full-368x800.png"));
assert.ok(!/Accessibility|VoiceOver|Dynamic Type|XXXL/i.test(html));

console.log(`exploration map identities v1: ${mapSprites.length} map keys + ${minimapSprites.length} minimap keys; deterministic export passed`);
