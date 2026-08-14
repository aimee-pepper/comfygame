import assert from "node:assert/strict";
import { normalizeCover, resolveComparison, legacyCover } from "../src/world-history-proof-kit.js";
assert.strictEqual(normalizeCover(null), legacyCover);
assert.strictEqual(normalizeCover(undefined), legacyCover);
const cover = normalizeCover({ schemaVersion: 1, worldVisualDescriptorVersion: "world-cover-1", paletteFamilyID: "warmMineral", atmosphereMarkID: "neutralSmoke", ecologyMarkID: "spreading" });
assert.ok(Object.isFrozen(cover));
const a = { id: "world-2", runIndex: 2, semanticRequests: { illumination: "Dim", thermal: "Warm", substrate: "Granite" }, measurements: { thermal: { display: "about 62" } } };
const b = { id: "world-9", runIndex: 9, semanticRequests: { illumination: "Dim", thermal: "Cold", flora: "Bloom" }, measurements: { thermal: { display: "about 35" }, hydrology: { display: "wet band" } } };
const relations = { thermal: "lower" };
const forward = resolveComparison(a, b, relations);
const reverse = resolveComparison(b, a, relations);
assert.deepEqual(forward, reverse);
assert.deepEqual(forward.requests, [
  { key: "flora", earlier: "Not written", later: "Bloom", state: "added" },
  { key: "illumination", earlier: "Dim", later: "Dim", state: "unchanged" },
  { key: "substrate", earlier: "Granite", later: "Not written", state: "removed" },
  { key: "thermal", earlier: "Warm", later: "Cold", state: "changed" },
]);
assert.deepEqual(forward.measurements, [
  { key: "hydrology", earlier: "Not measured in this record", later: "wet band", direction: "unavailable" },
  { key: "thermal", earlier: "about 62", later: "about 35", direction: "lower" },
]);
assert.throws(() => resolveComparison({ ...a, measurements: { thermal: 62 } }, b, relations));
assert.throws(() => resolveComparison({ ...a, semanticRequests: { thermal: null } }, b, relations));
assert.throws(() => resolveComparison({ ...a, semanticRequests: { thermal: ["Warm"] } }, b, relations));
assert.throws(() => resolveComparison({ ...a, semanticRequests: { "": "Warm" } }, b, relations));
assert.throws(() => resolveComparison({ ...a, id: "" }, b, relations));
assert.throws(() => resolveComparison({ ...a, measurements: { "": { display: "62" } } }, b, relations));
assert.throws(() => resolveComparison({ ...a, measurements: { thermal: { display: "62", relationToEarlier: "higher" } } }, b, relations));
assert.throws(() => resolveComparison(a, { ...b, runIndex: a.runIndex }, relations));
assert.throws(() => resolveComparison(a, b, {}));
assert.throws(() => resolveComparison(a, b, { thermal: "lower", hidden: "higher" }));
assert.throws(() => resolveComparison(a, b, { thermal: "lower", hydrology: "higher" }));
assert.throws(() => normalizeCover({ ...cover, schemaVersion: 2 }));
assert.throws(() => normalizeCover({ ...cover, ecologyMarkID: "" }));
assert.throws(() => resolveComparison(a, a, relations));
assert.throws(() => normalizeCover({ ...cover, extra: true }));
console.log("Asset Lab world History proof tests passed.");
