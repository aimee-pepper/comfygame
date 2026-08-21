import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const { createCanvas, loadImage } = createRequire(import.meta.url)("@napi-rs/canvas");
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const script = path.join(root, "scripts", "export-atmosphere-presentation-kit.mjs");
const artifact = path.join(root, "artifacts", "atmosphere-presentation-v0.1");
execFileSync(process.execPath, [script]);
const api = await import(`${script}?test=${Date.now()}`);
const manifestPath = path.join(artifact, "manifest.json");
const first = fs.readFileSync(manifestPath);
const manifest = JSON.parse(first);

assert.equal(manifest.integrationReady, false);
assert.equal(manifest.exporter.file, "scripts/export-atmosphere-presentation-kit.mjs");
assert.deepEqual(Object.keys(manifest.families), ["smoke", "airborneAsh", "mist", "miasma", "rain", "snow", "mixedRainSnow"]);
assert.deepEqual(manifest.nativeTileSize, { width: 16, height: 16 });
assert.deepEqual(manifest.fixedFixture, { map: "earthlike-15x15", width: 15, height: 15, phone: { width: 368, height: 800 } });
assert.deepEqual(manifest.disclosure.hiddenRGBA, [0, 0, 0, 255]);
for (const forbidden of ["clouds", "lightning", "puddles", "snow-terrain", "generic-tint", "standalone-wind-lines", "weather-gameplay"]) assert.ok(manifest.forbidden.includes(forbidden));

const pixels = canvas => canvas.getContext("2d").getImageData(0, 0, canvas.width, canvas.height).data;
const occupied = canvas => { const data = pixels(canvas); let count = 0; for (let i = 3; i < data.length; i += 4) if (data[i]) count++; return count; };
const alphaMass = canvas => { const data = pixels(canvas); let total = 0; for (let i = 3; i < data.length; i += 4) total += data[i]; return total; };
const grayscaleShape = canvas => { const data = pixels(canvas), set = new Set(); for (let i = 0; i < data.length; i += 4) if (data[i + 3]) set.add(`${i / 4}:${Math.round(.2126 * data[i] + .7152 * data[i + 1] + .0722 * data[i + 2])}`); return [...set].sort().join("|"); };
const longestHorizontalRun = canvas => {
  const data = pixels(canvas); let longest = 0;
  for (let y = 0; y < canvas.height; y++) { let run = 0; for (let x = 0; x < canvas.width; x++) { const alpha = data[(y * canvas.width + x) * 4 + 3]; run = alpha ? run + 1 : 0; longest = Math.max(longest, run); } }
  return longest;
};
for (const familyID of Object.keys(api.families)) {
  const bands = ["trace", "light", "heavy", "dense"].map(density => api.familyTile(familyID, density, "moving", 0, 3, 8));
  const counts = bands.map(occupied);
  assert.ok(counts[0] <= counts[1] && counts[1] <= counts[2] && counts[2] <= counts[3], `${familyID} density must be monotonic`);
  assert.equal(new Set(bands.map(grayscaleShape)).size, 4, `${familyID} bands must differ without hue`);
}
const familyShapes = Object.keys(api.families).map(id => grayscaleShape(api.familyTile(id, "heavy", "moving", 0, 3, 8, "water")));
assert.equal(new Set(familyShapes).size, 7, "families must remain distinct in literal grayscale");
const mistNeighbourCounts = Array.from({ length: 16 }, (_, index) => occupied(api.familyTile("mist", "heavy", "moving", 0, index % 4, Math.floor(index / 4))));
assert.ok(new Set(mistNeighbourCounts).size >= 4, "mist must form irregular neighbouring pockets, not a repeated per-tile texture");
const mistMass = ["trace", "light", "heavy", "dense"].map(density => Array.from({ length: 16 }, (_, index) => alphaMass(api.familyTile("mist", density, "moving", 0, index % 4, Math.floor(index / 4)))).reduce((sum, value) => sum + value, 0));
assert.ok(mistMass[0] < mistMass[1] && mistMass[1] < mistMass[2] && mistMass[2] < mistMass[3], "mist opacity mass must strictly order trace, light, heavy and dense across the field");
assert.ok(mistMass[2] >= mistMass[1] * 1.7, "heavy fog must be unmistakably more spatially massed than light mist");
for (let y = 0; y < 4; y++) for (let x = 0; x < 4; x++) {
  assert.ok(longestHorizontalRun(api.familyTile("mist", "heavy", "moving", 0, x, y)) < 12, "mist wisps must retain gaps instead of scanlines");
  assert.ok(longestHorizontalRun(api.familyTile("smoke", "heavy", "moving", 0, x, y)) <= 4, "smoke must remain plume fragments rather than parallel dashes");
}
const calm = api.familyTile("smoke", "light", "calm", 3, 2, 2), moving = api.familyTile("smoke", "light", "moving", 3, 2, 2), strong = api.familyTile("smoke", "light", "strong", 3, 2, 2);
assert.equal(Buffer.compare(calm.toBuffer("image/png"), moving.toBuffer("image/png")) === 0, false);
assert.equal(Buffer.compare(moving.toBuffer("image/png"), strong.toBuffer("image/png")) === 0, false);
assert.equal(occupied(calm), occupied(moving)); assert.equal(occupied(moving), occupied(strong));

assert.equal(occupied(api.contactShade({ lowerElevation: 1, neighbourElevation: 1 })), 0);
assert.equal(occupied(api.contactShade({ lowerElevation: 1, neighbourElevation: 2 })), 16);
assert.equal(occupied(api.contactShade({ lowerElevation: 0, neighbourElevation: 2 })), 24);
assert.equal(occupied(api.contactShade({ lowerElevation: 0, neighbourElevation: 2, light: "pitchBlack" })), 0);
assert.deepEqual([manifest.contactShadeMatrix.width, manifest.contactShadeMatrix.height], [608, 160]);
assert.deepEqual([manifest.motionMatrix.width, manifest.motionMatrix.height], [1368, 850]);
assert.deepEqual([manifest.proofMatrix.width, manifest.proofMatrix.height], [1368, 5100]);
assert.deepEqual([manifest.grayscaleProofMatrix.width, manifest.grayscaleProofMatrix.height], [1368, 5100]);
assert.deepEqual([manifest.visibilityMatrix.width, manifest.visibilityMatrix.height], [912, 850]);

const ordinary = api.mapFrame({ familyID: "mist", density: "heavy", mutation: false });
const mutated = api.mapFrame({ familyID: "mist", density: "heavy", mutation: true });
assert.deepEqual(ordinary.toBuffer("image/png"), mutated.toBuffer("image/png"), "remote remembered mutation must not change current pixels");
const ordinaryPixels = pixels(ordinary);
for (let y = 0; y < api.MAP_TILES; y++) for (let x = 0; x < api.MAP_TILES; x++) {
  const dx = x - 7, dy = y - 7, hidden = Math.sqrt(dx * dx + dy * dy) > 6 && !(x <= 3 && y >= 8);
  if (!hidden) continue;
  for (let py = y * 16; py < y * 16 + 16; py++) for (let px = x * 16; px < x * 16 + 16; px++) {
    const i = (py * api.MAP_SIZE + px) * 4; assert.deepEqual([...ordinaryPixels.slice(i, i + 4)], [0, 0, 0, 255]);
  }
}
for (const record of Object.values(manifest.evidence)) for (const proof of Object.values(record)) {
  if (!proof?.file) continue; const image = await loadImage(path.join(artifact, proof.file)); assert.deepEqual([image.width, image.height], [368, 800]);
}
execFileSync(process.execPath, [script]);
assert.deepEqual(fs.readFileSync(manifestPath), first, "repeat export must be byte-identical");
console.log("Atmosphere presentation kit passed.");
