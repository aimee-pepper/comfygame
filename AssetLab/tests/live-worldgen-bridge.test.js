import assert from "node:assert/strict";
import { bridgeSources, generateLiveWorld, liveSymbolCatalogue } from "../src/live-worldgen-bridge.js";

const sources = await bridgeSources();
assert.ok(sources.some(path => path.endsWith("Sources/Rules/Worldgen.swift")));
assert.equal(sources.some(path => path.includes("GameActions")), false,
  "the website bridge must not pull mutable campaign actions into generation");

const catalogue = await liveSymbolCatalogue();
assert.ok(catalogue.length > 10);
assert.ok(catalogue.every(symbol => symbol.id && symbol.name));

const request = { seed: 42, symbols: [], scale: "minute" };
const first = await generateLiveWorld(request);
const repeat = await generateLiveWorld(request);
assert.deepEqual(first, repeat, "the same live book and seed must produce the same snapshot");
assert.equal(first.width, 12);
assert.equal(first.height, 12);
assert.equal(first.cells.length, 144);
assert.equal(first.cells.every(cell => typeof cell.ground === "string"), true);
assert.equal(first.resources.every(row => row.placements > 0 && row.quantity > 0), true);
assert.equal(first.flora.reduce((sum, row) => sum + row.quantity, 0),
  first.cells.filter(cell => cell.floraID !== undefined).length);
assert.equal(first.markers.length, first.diagnostics.creatureInstancesPlaced);
assert.equal(first.splash, undefined,
  "splash stays absent until the generated entry-shot pipeline exists");

console.log("Live World Generator website bridge tests passed.");
