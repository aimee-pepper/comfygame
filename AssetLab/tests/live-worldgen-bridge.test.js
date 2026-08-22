import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { readFile } from "node:fs/promises";
import { promisify } from "node:util";
import { bridgeSources, generateLiveWorld, liveSymbolCatalogue } from "../src/live-worldgen-bridge.js";

const sources = await bridgeSources();
assert.ok(sources.some(path => path.endsWith("Sources/Rules/Worldgen.swift")));
assert.equal(sources.some(path => path.includes("GameActions")), false,
  "the website bridge must not pull mutable campaign actions into generation");

const catalogue = await liveSymbolCatalogue();
assert.ok(catalogue.length > 10);
assert.ok(catalogue.every(symbol => symbol.id && symbol.name));
const testerHTML = await readFile(new URL("../world-generator-tester.html", import.meta.url), "utf8");
const testerApp = await readFile(new URL("../src/world-generator-tester-app.js", import.meta.url), "utf8");
for (const label of ["Terrain, Water, Deposits &amp; Resource Hosts", "Resource Hosts"])
  assert.match(testerHTML, new RegExp(label));
for (const label of ["Base material", "Visible ground", "Deep Water cores", "Settled Ash tiles",
  "Start-connected passable terrain", "Deep Water tiles softened for reachability",
  "Internal ID", "Terrain generation failed"])
  assert.match(testerApp, new RegExp(label));
for (const id of ["terrain-diagnostics", "terrain-topology", "water-topology",
  "deposit-topology", "resource-host-table"])
  assert.match(testerHTML, new RegExp(`id="${id}"`));

const request = { seed: 42, symbols: [], scale: "ordinary" };
const first = await generateLiveWorld(request);
const repeat = await generateLiveWorld(request);
assert.deepEqual(first, repeat,
  "two independent bridge processes must emit the same terrain receipt for one book and seed");
const execFileAsync = promisify(execFile);
const bridgeModule = new URL("../src/live-worldgen-bridge.js", import.meta.url).href;
const concurrentScript = `import { generateLiveWorld } from ${JSON.stringify(bridgeModule)};
process.stdout.write(JSON.stringify(await generateLiveWorld(${JSON.stringify(request)})));`;
const concurrent = await Promise.all(Array.from({ length: 8 }, () =>
  execFileAsync(process.execPath, ["--input-type=module", "--eval", concurrentScript], {
    maxBuffer: 25_000_000,
  }).then(({ stdout }) => JSON.parse(stdout))));
assert.equal(concurrent.length, 8);
assert.ok(concurrent.every(result => JSON.stringify(result) === JSON.stringify(first)),
  "parallel bridge cache publication exposed partial JSON or changed deterministic output");
assert.equal(first.width, 18);
assert.equal(first.height, 18);
assert.equal(first.cells.length, 324);
assert.equal(first.cells.every(cell => typeof cell.ground === "string"), true);
assert.equal(first.cells.every(cell => typeof cell.baseGround === "string"
  && typeof cell.snow === "boolean" && typeof cell.settledAsh === "boolean"), true);
assert.equal(first.cells.every(cell => typeof cell.isRevealed === "boolean"), true);
for (const representative of [
  { seed: 7, symbols: ["plains"], scale: "small" },
  { seed: 42, symbols: ["frostbound"], scale: "ordinary" },
  { seed: 91, symbols: ["ashen", "frostbound"], scale: "large" },
]) {
  const a = await generateLiveWorld(representative);
  const b = await generateLiveWorld(representative);
  assert.deepEqual(a, b, `independent-process terrain changed for ${JSON.stringify(representative)}`);
  assert.equal(a.diagnostics.terrainGenerationSucceeded, true);
  assert.ok(a.diagnostics.reachableTerrainFraction >= 0.85);
  assert.ok(Number.isInteger(a.diagnostics.softenedDeepWaterTiles)
    && a.diagnostics.softenedDeepWaterTiles >= 0);
  assert.ok(Number.isInteger(a.diagnostics.filledChasmTiles)
    && a.diagnostics.filledChasmTiles >= 0);
  assert.ok(Number.isInteger(a.diagnostics.isolatedGroundCells)
    && a.diagnostics.isolatedGroundCells >= 0);
  assert.ok(a.diagnostics.baseMaterialComponents.every(row => row.id && row.quantity > 0));
  assert.ok(a.diagnostics.visibleGroundComponents.every(row => row.id && row.quantity > 0));
  assert.ok(a.diagnostics.elevationHistogram.every(row => Number.isInteger(Number(row.id))));
  assert.ok(a.diagnostics.maximumCardinalElevationDelta <= 1);
  assert.equal(a.diagnostics.resourceHostViolations.length, 0);
  assert.equal(a.diagnostics.resourceHosts.length, 23);
  assert.equal(a.diagnostics.resourceHosts.every(row => row.name && row.internalID
    && row.placementKind && row.hostRule && row.violations === 0), true);
  for (const key of ["surfaceWaterTiles", "frozenWaterTiles", "snowTiles", "settledAshTiles"])
    assert.ok(Number.isInteger(a.diagnostics[key]) && a.diagnostics[key] >= 0);
}
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
assert.equal(apexWorld.diagnostics.terrainGenerationSucceeded, true);
assert.ok(apexWorld.diagnostics.reachableTerrainFraction >= 0.85);
assert.equal(apexWorld.diagnostics.softenedDeepWaterTiles, 0);
assert.equal(apexWorld.diagnostics.filledChasmTiles, 0);
const apexEntry = apexWorld.cells.find(cell => cell.x === apexWorld.entry.x && cell.y === apexWorld.entry.y);
assert.notEqual(apexEntry.baseGround, "water", "seed 12 prefers dry entry in its largest component");
const byPoint = new Map(apexWorld.cells.map(cell => [`${cell.x},${cell.y}`, cell]));
const reachable = new Set([`${apexWorld.entry.x},${apexWorld.entry.y}`]), queue = [apexWorld.entry];
while (queue.length) {
  const point = queue.shift();
  for (const [x,y] of [[point.x-1,point.y],[point.x+1,point.y],[point.x,point.y-1],[point.x,point.y+1]]) {
    const key=`${x},${y}`, cell=byPoint.get(key);
    if (cell && !["deepWater","chasm"].includes(cell.ground) && !reachable.has(key)) {
      reachable.add(key); queue.push({x,y});
    }
  }
}
const passable = apexWorld.cells.filter(cell => !["deepWater","chasm"].includes(cell.ground));
assert.equal(reachable.size / passable.length, apexWorld.diagnostics.reachableTerrainFraction);
for (const cell of apexWorld.cells.filter(cell => cell.content !== "empty"))
  assert.ok(reachable.has(`${cell.x},${cell.y}`), `seed 12 stranded ${cell.content}`);
for (const marker of apexWorld.markers)
  assert.ok(reachable.has(`${marker.x},${marker.y}`), `seed 12 stranded ${marker.kind}`);
const rawEssenceHost = apexWorld.diagnostics.resourceHosts.find(row => row.internalID === "essence_raw");
assert.ok(rawEssenceHost.actualPlacements > 0 && rawEssenceHost.eligibleHosts > 0
  && rawEssenceHost.reachableEligibleHosts > 0);
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
