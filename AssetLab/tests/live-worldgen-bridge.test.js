import assert from "node:assert/strict";
import { bridgeSources, generateLiveWorld, liveSymbolCatalogue } from "../src/live-worldgen-bridge.js";

const sources = await bridgeSources();
assert.ok(sources.some(path => path.endsWith("Sources/Rules/Worldgen.swift")));
assert.equal(sources.some(path => path.includes("GameActions")), false,
  "the website bridge must not pull mutable campaign actions into generation");

const catalogue = await liveSymbolCatalogue();
assert.ok(catalogue.length > 10);
assert.ok(catalogue.every(symbol => symbol.id && symbol.name));

const request = { seed: 42, symbols: [], scale: "ordinary" };
const first = await generateLiveWorld(request);
const repeat = await generateLiveWorld(request);
assert.deepEqual(first, repeat, "the same live book and seed must produce the same snapshot");
assert.equal(first.width, 18);
assert.equal(first.height, 18);
assert.equal(first.cells.length, 324);
assert.equal(first.cells.every(cell => typeof cell.ground === "string"), true);
assert.equal(first.cells.every(cell => typeof cell.isRevealed === "boolean"), true);
assert.ok(first.cells.some(cell => cell.isRevealed), "bridge must expose the rules-owned entry reveal crop");
assert.equal(first.worldVisualReceipt.descriptorHash,
  first.worldVisualReceipt.descriptor.canonicalDescriptorSHA256);
assert.ok(Number.isFinite(first.entryEnvironment.illuminationPeak));
assert.ok(Number.isFinite(first.entryEnvironment.illuminationFloor));
assert.equal(first.entryEnvironment.suspendedMedium,
  first.worldVisualReceipt.descriptor.atmosphere.medium);
assert.equal(first.entryEnvironment.suspendedDensity,
  first.worldVisualReceipt.descriptor.atmosphere.density);
assert.equal(first.entryEnvironment.precipitation, "none",
  "suspended atmosphere and precipitation must remain separate bridge channels");
assert.equal(first.floraVisuals.length, first.diagnostics.floraSpeciesCount);
assert.ok(first.floraVisuals.every(row => row.stableID && Number.isInteger(row.formID)
  && Number.isFinite(row.stature) && row.habit && row.resolvedColor.length === 3
  && Number.isInteger(row.placements) && row.placements > 0));
assert.equal(first.resources.every(row => row.placements > 0 && row.quantity > 0), true);
assert.equal(first.flora.reduce((sum, row) => sum + row.quantity, 0),
  first.cells.filter(cell => cell.floraID !== undefined).length);
assert.equal(first.diagnostics.creatureSpeciesCount, 6);
assert.equal(first.generatedCast.length, 6);
assert.equal(new Set(first.generatedCast.filter(row => row.placements > 0).map(row => row.name)).size, 5);
assert.equal(first.generatedCast.reduce((sum, row) => sum + row.placements, 0), 9);
assert.equal(first.mobs.length, 5);
assert.equal(first.mobs.reduce((sum, row) => sum + row.quantity, 0), 9);
assert.equal(first.apexes.reduce((sum, row) => sum + row.quantity, 0), 0);
assert.equal(first.hostileFlora.reduce((sum, row) => sum + row.quantity, 0), 0);
assert.equal(first.markers.filter(marker => marker.kind === "mob").length, 9);
assert.equal(first.markers.length,
  first.mobs.reduce((sum, row) => sum + row.quantity, 0)
  + first.apexes.reduce((sum, row) => sum + row.quantity, 0)
  + first.hostileFlora.reduce((sum, row) => sum + row.quantity, 0));
const apexWorld = await generateLiveWorld({ seed: 12, symbols: [], scale: "ordinary" });
assert.equal(apexWorld.apexes.reduce((sum, row) => sum + row.quantity, 0), 1);
assert.equal(apexWorld.mobs.some(row => row.id === "Apex"), false,
  "apexes must not be collapsed into ordinary mob rows");
const activeFloraWorld = await generateLiveWorld({ seed: 13, symbols: [], scale: "ordinary" });
assert.equal(activeFloraWorld.hostileFlora.reduce((sum, row) => sum + row.quantity, 0), 2);
assert.equal(activeFloraWorld.mobs.some(row => row.id === "Hostile flora"), false,
  "active flora must not be collapsed into ordinary mob rows");
assert.equal(first.splash, undefined,
  "splash stays absent until the generated entry-shot pipeline exists");

console.log("Live World Generator website bridge tests passed.");
