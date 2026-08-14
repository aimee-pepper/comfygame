import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../integration/starting-town-home-v1/", import.meta.url));
const manifestBytes = readFileSync(`${root}starting-town-home-v1.json`);
const manifest = JSON.parse(manifestBytes);
const png = readFileSync(`${root}town-starting-home-v1.png`);

assert.deepEqual(Object.keys(manifest).sort(),
  ["assetName", "hotspots", "pixelHeight", "pixelWidth", "schemaVersion", "sha256"].sort());
assert.equal(manifest.schemaVersion, 1);
assert.equal(manifest.assetName, "town-starting-home-v1");
assert.equal(manifest.pixelWidth, 1122);
assert.equal(manifest.pixelHeight, 1402);
assert.equal(createHash("sha256").update(png).digest("hex"), manifest.sha256);
assert.deepEqual([...png.subarray(0, 8)], [137, 80, 78, 71, 13, 10, 26, 10]);
assert.equal(png.readUInt32BE(16), manifest.pixelWidth);
assert.equal(png.readUInt32BE(20), manifest.pixelHeight);

assert.deepEqual(manifest.hotspots.map(({ id }) => id),
  ["writingDesk", "workshop", "storehouse", "essenceSpring", "firepit"]);
assert.deepEqual(manifest.hotspots.map(({ route }) => route),
  ["writingDesk", "workshop", "storehouse", "essenceSpring", "firepit"]);
assert.equal(new Set(manifest.hotspots.map(({ id }) => id)).size, 5);
assert.ok(!manifest.hotspots.some(({ route }) => route === "party" || route === "library"));

for (const hotspot of manifest.hotspots) {
  assert.deepEqual(Object.keys(hotspot).sort(),
    ["height", "id", "label", "route", "width", "x", "y"].sort());
  assert.ok(hotspot.width > 0 && hotspot.height > 0);
  assert.ok(hotspot.x >= 0 && hotspot.y >= 0);
  assert.ok(hotspot.x + hotspot.width <= 1 && hotspot.y + hotspot.height <= 1);
}

const phone = { width: 344, height: 344 * manifest.pixelHeight / manifest.pixelWidth };
const rects = manifest.hotspots.map((hotspot) => ({
  id: hotspot.id,
  x: phone.width * hotspot.x,
  y: phone.height * hotspot.y,
  width: Math.max(54, phone.width * hotspot.width),
  height: Math.max(44, phone.height * hotspot.height),
}));
for (let a = 0; a < rects.length; a += 1) {
  for (let b = a + 1; b < rects.length; b += 1) {
    const first = rects[a], second = rects[b];
    const overlaps = first.x < second.x + second.width && first.x + first.width > second.x &&
      first.y < second.y + second.height && first.y + first.height > second.y;
    assert.equal(overlaps, false, `${first.id} overlaps ${second.id} at ordinary-phone size`);
  }
}

console.log("starting town Home v1 fixture tests passed");
