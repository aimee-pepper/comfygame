import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { acceptedTownLayer, paginateTownStations, townBuildingPrompt, townLayerFileName, validateTownBuildingManifest, validateTownLayerPNG } from "../src/town-building-generator.js";

const here = path.dirname(fileURLToPath(import.meta.url));
const assetRoot = path.resolve(here, "..");
const repoRoot = path.resolve(assetRoot, "..");
const manifest = validateTownBuildingManifest(JSON.parse(fs.readFileSync(path.join(assetRoot, "town/town-building-generator-v1.json"), "utf8")));
const stations = JSON.parse(fs.readFileSync(path.join(repoRoot, "Sources/Content/Data/stations.json"), "utf8")).stations;

assert.equal(manifest.integrationReady, true);
for (const record of [manifest.backdrop, manifest.startingBackdrop]) {
  const bytes = fs.readFileSync(path.join(assetRoot, "town", record.path));
  assert.equal(crypto.createHash("sha256").update(bytes).digest("hex"), record.sha256);
  const nativeBytes = fs.readFileSync(path.join(repoRoot, "Sources/Content/TownVisuals", record.path));
  assert.equal(crypto.createHash("sha256").update(nativeBytes).digest("hex"), record.sha256);
}
for (const record of Object.values(manifest.acceptedLayers)) {
  const bytes = fs.readFileSync(path.join(repoRoot, "Sources/Content/TownVisuals", record.file));
  assert.equal(crypto.createHash("sha256").update(bytes).digest("hex"), record.sha256);
}
assert.deepEqual(manifest.plots.map((plot) => plot.id), ["upperLeft", "upperRight", "lowerLeft", "lowerRight"]);
assert.deepEqual(manifest.startingBackdrop.hotspots, ["workshop", "study", "party", "storehouse", "essenceSpring", "firepit"]);
const pages = paginateTownStations(stations);
assert.deepEqual(pages.flat().map((station) => station.id), stations.map((station) => station.id));
assert.ok(pages.every((page) => page.length > 0 && page.length <= 4));
for (const station of stations) {
  const prompt = townBuildingPrompt(manifest, station, "upperLeft");
  assert.match(prompt, new RegExp(station.name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
  assert.match(prompt, /#ff00ff/);
  assert.match(prompt, /center: x 0\.24, y 0\.49/);
  assert.match(prompt, /displayed width 0\.34/);
}
assert.equal(acceptedTownLayer(manifest, "workshop").file, "building-workshop-v1.png");
assert.equal(acceptedTownLayer(manifest, "constellation").file, "building-constellation-v1.png");
assert.equal(acceptedTownLayer(manifest, "bestiary").file, "building-bestiary-v1.png");
assert.equal(acceptedTownLayer(manifest, "apothecary").file, "building-apothecary-v1.png");
assert.equal(acceptedTownLayer(manifest, "survey_post").file, "building-survey-post-v1.png");
assert.equal(acceptedTownLayer(manifest, "reliquary").file, "building-reliquary-v1.png");
assert.equal(acceptedTownLayer(manifest, "scriptorium").file, "building-scriptorium-v1.png");
assert.equal(townLayerFileName("survey_post"), "building-survey-post-v1.png");
const apothecaryBytes = fs.readFileSync(path.join(repoRoot, "Sources/Content/TownVisuals/building-apothecary-v1.png"));
assert.deepEqual(validateTownLayerPNG(apothecaryBytes), { width: 627, height: 627, bitDepth: 8, colorType: 6 });
assert.equal(acceptedTownLayer(manifest, "blacksmith"), null);
assert.ok(Object.isFrozen(manifest.acceptedLayers.workshop));
assert.throws(() => townBuildingPrompt(manifest, stations[0], "invented"), /unknown plot/);
assert.throws(() => paginateTownStations([{ id: "same" }, { id: "same" }]), /unique/);
assert.throws(() => townLayerFileName("Bad ID"), /snake case/);
assert.throws(() => validateTownLayerPNG(new Uint8Array([1, 2, 3])), /PNG bytes/);
assert.throws(() => validateTownBuildingManifest({ ...structuredClone(manifest), acceptedLayers: { workshop: { file: "x.png", sha256: "bad" } } }), /SHA-256/);
assert.throws(() => validateTownBuildingManifest({ ...structuredClone(manifest), promptStyle: { ...manifest.promptStyle, extra: "drift" } }), /unexpected fields/);

console.log("town-building-generator: ok");
