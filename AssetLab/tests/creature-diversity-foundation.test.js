import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { defaults, normalizeDescriptor, presets, creatureCommands, hash } from "../src/generator.js";

const artifactRoot = fileURLToPath(new URL("../artifacts/", import.meta.url));
const report = JSON.parse(readFileSync(`${artifactRoot}creature-diversity-foundation-v0.1.json`));
const png = readFileSync(`${artifactRoot}${report.artifact.file}`);

assert.equal(report.schemaVersion, 5);
assert.equal(report.integrationReady, false);
assert.equal(report.fixtureCount, 2);
assert.equal(createHash("sha256").update(png).digest("hex"), report.artifact.sha256);
assert.equal(png.readUInt32BE(16), report.artifact.pixelWidth);
assert.equal(png.readUInt32BE(20), report.artifact.pixelHeight);

const expected = [
  ["fennec-like", "Dune long-ear", "quadruped", "longEars", "limbed"],
  ["winged-serpent", "Membrane sky serpent", "serpentine", "crest", "membrane"]
];
for (const [id, preset, bodyPlan, cranialFeature, appendageType] of expected) {
  const fixture = report.fixtures.find((candidate) => candidate.id === id);
  const descriptor = normalizeDescriptor({...defaults, logicalID: id, traits: presets[preset]});
  assert.equal(fixture.bodyPlan, bodyPlan);
  assert.equal(fixture.cranialFeature, cranialFeature);
  assert.equal(fixture.appendageType, appendageType);
  assert.equal(fixture.worldCommandHash, hash(creatureCommands(descriptor, "world")));
  assert.equal(fixture.fightCommandHash, hash(creatureCommands(descriptor, "fight")));
}

assert.notEqual(report.fixtures[0].worldCommandHash, report.fixtures[1].worldCommandHash);
assert.notEqual(report.fixtures[0].fightCommandHash, report.fixtures[1].fightCommandHash);
assert.ok(report.constraints.includes("cranial feature does not imply a sensor mechanic"));
console.log("Asset Lab creature diversity foundation artifact tests passed.");
