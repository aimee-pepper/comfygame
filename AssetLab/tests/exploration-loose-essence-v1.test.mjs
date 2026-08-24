import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { createRequire } from "node:module";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import {
  looseEssenceConsumerContract,
  resolveLooseEssenceStableKey,
} from "../src/exploration-loose-essence-v1.js";

const require = createRequire("/Users/aimeepepper/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/package.json");
const sharp = require("sharp");
const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const pack = join(root, "AssetLab/integration/exploration-loose-essence-v1");
const manifestBytes = await readFile(join(pack, "runtime/manifest.json"));
const manifest = JSON.parse(manifestBytes);
const sha = bytes => createHash("sha256").update(bytes).digest("hex");

assert.equal(manifest.schemaVersion, "exploration-loose-essence-v1");
assert.equal(manifest.status, "candidate-unapproved");
assert.equal(manifest.integrationReady, false);
assert.equal(manifest.resourceID, "essence_raw");
assert.deepEqual(manifest.canvas, { width: 16, height: 19, pivot: [8, 18], tileSurface: [16, 16] });
assert.equal(manifest.runtimeGeneratedPixels, false);
assert.match(manifest.selection.full, /premade frame/);
assert.match(manifest.selection.disclosedNonFull, /frame 0/);
assert.match(manifest.selection.undisclosed, /no request/);
assert.equal(manifest.selection.temporalSelector, "presentationTick is the sole temporal selector");
assert.equal(Object.keys(manifest.assetsByKey).length, 4);
assert.deepEqual(Object.keys(manifest.assetsByKey), [0, 1, 2, 3].map(i => `loose_essence/ordinary/frame-${i}`));

const rawDrop = amount => ({ kind: "wildDrop", resourceID: "essence_raw", amount });
const resolveKey = overrides => resolveLooseEssenceStableKey({
  content: rawDrop(1),
  visibility: "full",
  previouslyRevealed: true,
  presentationTick: 0,
  ...overrides,
});

// Exact positive Raw Essence wildDrop matrix and amount isolation.
assert.equal(resolveKey({}), "loose_essence/ordinary/frame-0");
assert.equal(resolveKey({ content: rawDrop(1), presentationTick: 7 }), "loose_essence/ordinary/frame-3");
assert.equal(resolveKey({ content: rawDrop(999), presentationTick: 7 }), "loose_essence/ordinary/frame-3");
assert.equal(resolveKey({ content: rawDrop(0) }), null);
assert.equal(resolveKey({ content: rawDrop(-1) }), null);
assert.equal(resolveKey({ content: { kind: "resourceNode", resourceID: "essence_raw", amount: 1 } }), null);
assert.equal(resolveKey({ content: { kind: "wildDrop", resourceID: "mote", amount: 1 } }), null);
assert.equal(resolveKey({ content: { kind: "wildDrop", resourceID: "ore", amount: 1 } }), null);
assert.equal(resolveKey({ content: { kind: "item", catalogueID: "essence_crystal", amount: 1 } }), null);

// Full uses only presentationTick modulo four. Previously disclosed non-full is static frame zero;
// undisclosed fringe/hidden fails closed.
for (let tick = 0; tick < 12; tick++) {
  assert.equal(resolveKey({ presentationTick: tick }), `loose_essence/ordinary/frame-${tick % 4}`);
}
assert.equal(resolveKey({ presentationTick: Number.MAX_SAFE_INTEGER + 1 }), null);
assert.equal(resolveKey({ presentationTick: -1 }), null);
assert.equal(resolveKey({ visibility: "fringe", previouslyRevealed: true, presentationTick: 3 }), "loose_essence/ordinary/frame-0");
assert.equal(resolveKey({ visibility: "hidden", previouslyRevealed: true, presentationTick: 3 }), "loose_essence/ordinary/frame-0");
assert.equal(resolveKey({ visibility: "fringe", previouslyRevealed: false }), null);
assert.equal(resolveKey({ visibility: "hidden", previouslyRevealed: false }), null);
assert.equal(resolveKey({ visibility: "remembered", previouslyRevealed: true }), null);

// Forbidden metadata cannot participate in a legal key or introduce a private phase.
const isolatedKey = resolveKey({
  content: rawDrop(27),
  presentationTick: 10,
  point: { x: 97, y: -41 },
  mapSeed: 9_007_199_254_740_991,
  worldRunID: "different-run",
  runIndex: 811,
  phase: 3,
  phaseOffset: 3,
  stablePhase: 3,
});
assert.equal(isolatedKey, "loose_essence/ordinary/frame-2");
assert.equal(manifest.nativeHandoff.temporalSelection, "frame = presentationTick modulo 4; no coordinate, seed, run or phase offset participates");
assert.deepEqual(looseEssenceConsumerContract.layerOrder, manifest.layerOrder);
assert.equal(looseEssenceConsumerContract.minimapKey, null);
assert.equal(manifest.nativeHandoff.minimapKey, null);
assert.equal(looseEssenceConsumerContract.recolor, false);
assert.equal(manifest.nativeHandoff.recolor, false);
assert.equal(looseEssenceConsumerContract.gameplayMutation, false);
assert.equal(manifest.nativeHandoff.gameplayMutation, false);

const canonicalSourcePaths = [
  "AssetLab/integration/resource-sprites-v1/inventory/essence_raw.png",
  "AssetLab/integration/resource-sprites-v1/map/essence_raw.png",
];
const canonicalColors = new Set();
for (const path of canonicalSourcePaths) {
  const { data } = await sharp(join(root, path)).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  for (let offset = 0; offset < data.length; offset += 4) {
    if (data[offset + 3]) canonicalColors.add([...data.subarray(offset, offset + 4)].join(","));
  }
}

const rgbaFrames = [];
const fileFrames = [];
for (const [key, asset] of Object.entries(manifest.assetsByKey)) {
  assert.equal(asset.width, 16, key);
  assert.equal(asset.height, 19, key);
  assert.deepEqual(asset.pivot, [8, 18], key);
  assert.equal(asset.resourceID, "essence_raw", key);
  const runtimeBytes = await readFile(join(pack, "runtime", asset.path));
  const sourceBytes = await readFile(join(pack, asset.sourcePath));
  assert.equal(Buffer.compare(runtimeBytes, sourceBytes), 0, `${key}:runtime-source-byte-identity`);
  assert.equal(sha(runtimeBytes), asset.fileSHA256, `${key}:file-sha`);
  const { data, info } = await sharp(runtimeBytes).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  assert.equal(info.width, 16); assert.equal(info.height, 19); assert.equal(info.channels, 4);
  assert.equal(sha(data), asset.decodedRGBASHA256, `${key}:rgba-sha`);
  let occupied = 0;
  let minX = 16, minY = 19, maxX = -1, maxY = -1;
  for (let offset = 0; offset < data.length; offset += 4) {
    const alpha = data[offset + 3];
    assert.ok(alpha === 0 || alpha === 255, `${key}:binary-alpha`);
    if (!alpha) continue;
    occupied++;
    const pixel = offset / 4;
    const x = pixel % 16;
    const y = Math.floor(pixel / 16);
    minX = Math.min(minX, x); maxX = Math.max(maxX, x);
    minY = Math.min(minY, y); maxY = Math.max(maxY, y);
    assert.ok(canonicalColors.has([...data.subarray(offset, offset + 4)].join(",")), `${key}:noncanonical-color@${x},${y}`);
  }
  assert.ok(occupied >= 60 && occupied <= 90, `${key}:occupied-pixel-band`);
  assert.ok(minX >= 2 && maxX <= 13 && minY >= 4 && maxY <= 17, `${key}:socket-safe-bounds`);
  rgbaFrames.push(data);
  fileFrames.push(runtimeBytes);
}

assert.equal(new Set(rgbaFrames.map(sha)).size, 4, "all full-visible premade frames must be distinct");
const changed = [];
for (let i = 1; i < rgbaFrames.length; i++) {
  let count = 0;
  for (let offset = 0; offset < rgbaFrames[0].length; offset += 4) {
    if (Buffer.compare(rgbaFrames[0].subarray(offset, offset + 4), rgbaFrames[i].subarray(offset, offset + 4))) count++;
  }
  changed.push(count);
}
assert.ok(changed.every(count => count >= 5 && count <= 12), `ambient diff must stay restrained: ${changed}`);
assert.equal(sha(Buffer.concat(fileFrames)), manifest.productionAggregateSHA256);

for (const source of Object.values(manifest.sourceReferences)) {
  assert.equal(sha(await readFile(join(root, source.path))), source.sha256, source.path);
}
for (const evidence of Object.values(manifest.evidence)) {
  assert.equal(sha(await readFile(join(pack, evidence.path))), evidence.sha256, evidence.path);
}

console.log(`exploration-loose-essence-v1 PASS · semantic matrix + pixels · body ${manifest.canonicalBodySHA256} · production ${manifest.productionAggregateSHA256}`);
