import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { arrivalSceneCommands, cropCommands } from "../src/world-arrival-kit.js";
import {
  COMMAND_KEYS, COMMAND_SCOPES, canonicalJSON, canonicalSHA256, corpusCommands,
  renderCorpusCommands, sha256, validateCorpusCommand
} from "../src/world-arrival-command-corpus.js";

const root = path.resolve(import.meta.dirname, "..");
const script = path.join(root, "scripts/export-world-arrival-command-corpus.mjs");
const output = path.join(root, "integration/world-arrival-command-corpus-v1");
const corpusPath = path.join(output, "corpus.json");
const run = () => execFileSync(process.execPath, [script], { stdio: "inherit" });
const fileSHA = file => crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");

run();
const first = fs.readFileSync(corpusPath), corpus = JSON.parse(first);
run();
assert.deepEqual(fs.readFileSync(corpusPath), first, "corpus export must be byte deterministic");
assert.equal(corpus.integrationReady, false);
assert.deepEqual(corpus.canvas, { width: 160, height: 100 });
assert.equal(corpus.pins.compositorSHA256, "5352cafa83ad6982aaaceafd24db66b5db002d5b5f1f6ceaf375b7cea738b882");
assert.equal(corpus.pins.acceptedManifestSHA256, "f041c81a41c45ac88dada40b0c173ab63c6e93c2984f232a23be67892df4a65b");
assert.equal(corpus.pins.compositorCommit, "9b60e8516f08806d40c38ed2a4307746c13d1c8c");
assert.equal(corpus.pins.latestReceiptCommit, "72b840d3e1de2b8c32aebfc0e876d61c69448a92");
assert.equal(corpus.canonicalBodySHA256, canonicalSHA256(Object.fromEntries(Object.entries(corpus).filter(([key]) => key !== "canonicalBodySHA256"))));

assert.equal(corpus.coverage.caseCount, corpus.cases.length);
assert.equal(corpus.coverage.acceptedFixtureCount, 7);
assert.deepEqual(corpus.coverage.seedMatrix.seeds, [...Array(32).keys()]);
assert.deepEqual(corpus.coverage.seedMatrix.materialWidths, [1, 2, 3, 4]);
assert.deepEqual(corpus.coverage.seedMatrix.stonePathJitters, [-1, 0, 1, 2]);
assert.equal(corpus.coverage.seedMatrix.seededPlacementSignatures, 32);
assert.equal(corpus.coverage.seedMatrix.maxCommandCount, Math.max(...corpus.cases.map(row => row.arrivalSceneCommands.length)));
assert.ok(corpus.coverage.seedMatrix.maxCases.every(id => id.startsWith("seed-matrix/")));

const byID = new Map(corpus.cases.map(row => [row.id, row]));
for (const id of ["starter_open_meadow", "starter_rainwashed_shore", "starter_stone_hollow", "near_flora", "ash_open_color", "longest_copy", "visible_site_candidate"]) assert.ok(byID.has(`accepted/${id}`));
for (const record of corpus.cases) {
  assert.equal(record.sceneReceiptVersion, 2, record.id);
  assert.equal(record.inputReceiptSHA256, canonicalSHA256({ version: 2, payload: record.receipt }), record.id);
  assert.equal(record.inputPayloadSHA256, canonicalSHA256(record.receipt), record.id);
  assert.equal(record.commandListSHA256, canonicalSHA256(record.arrivalSceneCommands), record.id);
  assert.equal(record.renderedRGBA8SHA256, sha256(renderCorpusCommands(record.arrivalSceneCommands)), record.id);
  assert.equal(record.arrivalSceneCommands.length, arrivalSceneCommands(record.receipt).length, record.id);
  record.arrivalSceneCommands.forEach((command, index) => {
    assert.deepEqual(Object.keys(command), COMMAND_KEYS, `${record.id}:${index} exact ABI key order`);
    assert.deepEqual(validateCorpusCommand(command, index), [], `${record.id}:${index}`);
  });
}

const sample = byID.get("accepted/starter_open_meadow").arrivalSceneCommands[0];
for (const mutation of [
  { ...sample, op: "line-v1" }, { ...sample, scope: "part" }, { ...sample, x: 1.5 },
  { ...sample, width: 0 }, { ...sample, x: 159, width: 2 }, { ...sample, rgba: [0, 0, 0, 256] },
  { ...sample, sourceOrder: 99 }, { ...sample, extra: true }
]) assert.ok(validateCorpusCommand(mutation, 0).length > 0);
assert.throws(() => renderCorpusCommands([{ ...sample, scope: "mapTerrain" }]), /invalid-arrival-corpus-command/);
assert.ok(corpus.cases.every(record => record.arrivalSceneCommands.every(command => COMMAND_SCOPES.includes(command.scope))));
assert.ok(corpus.cases.every(record => record.arrivalSceneCommands.every(command => !["part", "hidden", "mapTerrain", "mapVisibility", "mapFlora"].includes(command.scope))));

const reorderedReceipt = Object.fromEntries(Object.entries(byID.get("accepted/starter_open_meadow").receipt).reverse());
assert.equal(canonicalSHA256({version:2,payload:reorderedReceipt}), byID.get("accepted/starter_open_meadow").inputReceiptSHA256);
assert.deepEqual(corpusCommands(reorderedReceipt), byID.get("accepted/starter_open_meadow").arrivalSceneCommands);
const reorderedCommand = Object.fromEntries(Object.entries(sample).reverse());
assert.equal(canonicalJSON(reorderedCommand), canonicalJSON(sample));

for (const row of corpus.scopeDiffPairs) {
  assert.ok(row.changedScopes.every(scope => row.allowedScopes.includes(scope)), row.id);
  if (["resource-band", "title-only"].includes(row.id)) assert.deepEqual(row.changedScopes, []);
}
assert.equal(byID.get("scope-counterfactual/resource-band").arrivalSceneCommands.some(command => command.scope === "resource"), false);
assert.deepEqual(byID.get("scope-counterfactual/resource-band").arrivalSceneCommands, byID.get("accepted/starter_open_meadow").arrivalSceneCommands);
assert.deepEqual(byID.get("scope-counterfactual/title-only").arrivalSceneCommands, byID.get("accepted/starter_open_meadow").arrivalSceneCommands);

const completeA = { hiddenSite: "vault", hiddenCreature: "unknown", resource: "ore" }, completeB = { hiddenSite: "tear", hiddenCreature: "other", resource: "gold" };
assert.notDeepEqual(completeA, completeB);
assert.deepEqual(corpusCommands(byID.get("accepted/starter_open_meadow").receipt), corpusCommands(structuredClone(byID.get("accepted/starter_open_meadow").receipt)));
const exactHidden=byID.get("accepted/starter_open_meadow").receipt.firstMapCropReceipt.cells.filter(cell=>cell.visibility==="hidden");assert.ok(exactHidden.length>0);assert.ok(exactHidden.every(cell=>Object.keys(cell).sort().join("|")==="visibility|x|y"));const hiddenStone=structuredClone(byID.get("accepted/starter_open_meadow").receipt),hiddenDeepWater=structuredClone(hiddenStone);assert.deepEqual(hiddenStone,hiddenDeepWater,"hidden stone vs hidden deep-water complete-state inputs sanitize to the same exact v2 payload because neither terrain value may enter it");
const forbiddenHiddenTerrain=structuredClone(hiddenStone),hiddenIndex=forbiddenHiddenTerrain.firstMapCropReceipt.cells.findIndex(cell=>cell.visibility==="hidden");forbiddenHiddenTerrain.firstMapCropReceipt.cells[hiddenIndex]={...forbiddenHiddenTerrain.firstMapCropReceipt.cells[hiddenIndex],ground:"deepWater",elevation:9,floraStableID:"secret"};assert.throws(()=>corpusCommands(forbiddenHiddenTerrain),/invalid-world-arrival-receipt/);
assert.ok(cropCommands(byID.get("accepted/starter_open_meadow").receipt).some(command => command.scope === "mapTerrain"), "map crop remains separate continuity evidence");

const familyValues = family => corpus.cases.filter(row => row.metadata.family === family).map(row => row.metadata);
assert.deepEqual(new Set(familyValues("dominant-ground").map(row => row.ground)), new Set(["stone", "soil", "sand", "ice", "ash", "rubble", "mud", "growth", "groundcover"]));
assert.deepEqual(new Set(familyValues("water-relationship").map(row => row.relationship)), new Set(["none", "pools", "channels", "shelves", "islands"]));
assert.deepEqual(new Set(familyValues("illumination").map(row => row.band)), new Set(["trueDark", "dim", "ordinary", "bright", "blazing"]));
assert.deepEqual(new Set(familyValues("illumination").map(row => row.sourceClass)), new Set(["sourceless", "cyclic", "constant"]));
assert.deepEqual(new Set(familyValues("suspended").map(row => row.medium)), new Set(["none", "smoke", "airborneAsh", "mist", "miasma"]));
assert.deepEqual(new Set(familyValues("suspended").map(row => row.density)), new Set(["none", "trace", "light", "heavy", "dense"]));
assert.deepEqual(new Set(familyValues("suspended").map(row => row.motion)), new Set(["calm", "moving", "strong"]));
assert.deepEqual(new Set(familyValues("precipitation").map(row => row.medium)), new Set(["none", "rain", "snow", "mixedRainSnow"]));
assert.deepEqual(new Set(familyValues("precipitation").map(row => row.intensity)), new Set(["none", "trace", "light", "heavy"]));
assert.deepEqual(new Set(familyValues("precipitation").map(row => row.motion)), new Set(["calm", "moving", "strong"]));
assert.deepEqual(new Set(familyValues("flora-boundary").map(row => row.count)), new Set([0, 1, 2, 3, 4]));
assert.deepEqual(new Set(familyValues("flora-boundary").flatMap(row => row.habits)), new Set(["solitary", "clustered", "spreading", "mixed"]));
assert.deepEqual(new Set(familyValues("entry-disclosure").map(row => row.disclosed)), new Set([false, true]));

assert.equal(fileSHA(path.join(output, "corpus.json")), fileSHA(corpusPath));
assert.ok(fs.readFileSync(path.join(output, "sample-report.md"), "utf8").includes("Ordered command sample"));
console.log(`World Arrival command corpus passed · ${corpus.cases.length} cases · ${corpus.coverage.seedMatrix.maxCommandCount} max commands`);
