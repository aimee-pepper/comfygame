import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { characterCommands, mapFacings, namedCharacterCatalogue, provisionalNollDescriptor } from "../src/character-kit.js";

const here = path.dirname(fileURLToPath(import.meta.url));
const assetLab = path.resolve(here, "..");
const root = path.resolve(assetLab, "..");
execFileSync(process.execPath, [path.join(assetLab, "scripts/export-named-character-placeholder-pack.mjs")], { cwd: assetLab });
const manifest = JSON.parse(fs.readFileSync(path.join(assetLab, "integration/named-character-placeholders-v1/manifest.json"), "utf8"));
const liveIDs = JSON.parse(fs.readFileSync(path.join(root, "Sources/Content/Data/travellers.json"), "utf8")).travellers.map(person => person.id);
const descriptors = new Map(namedCharacterCatalogue.map(person => [person.id, person.descriptor]));
const canonical = value => Array.isArray(value) ? `[${value.map(canonical).join(",")}]` : value && typeof value === "object" ? `{${Object.keys(value).filter(key => value[key] !== undefined).sort().map(key => `${JSON.stringify(key)}:${canonical(value[key])}`).join(",")}}` : JSON.stringify(value);
const sha = value => crypto.createHash("sha256").update(value).digest("hex");
function rgba(commands) {
  const bytes = Buffer.alloc(16 * 16 * 4);
  for (const command of commands) {
    const value = Number.parseInt(command.color.slice(1), 16), color = [value >> 16, (value >> 8) & 255, value & 255, 255];
    for (let y = command.y; y < command.y + command.h; y++) for (let x = command.x; x < command.x + command.w; x++) bytes.set(color, (y * 16 + x) * 4);
  }
  return bytes;
}
const expectedCommands = key => characterCommands(key.travellerID === "noll" ? "provisional_noll" : key.travellerID, {
  profile: key.profile === "compactCameo" ? "world" : "mapTopDown",
  descriptor: key.travellerID === "noll" ? provisionalNollDescriptor : descriptors.get(key.travellerID),
  ...(key.facing ? { facing: key.facing } : {}),
});

assert.equal(manifest.integrationReady, true);
assert.equal(manifest.finalArt, false);
assert.equal(manifest.evidenceRole, "functionalPlaceholderConformancePack");
assert.deepEqual(manifest.supportedTravellerIDs, liveIDs);
assert.equal(liveIDs.length, 29);
assert.equal(manifest.assets.length, 29 * 5);
assert.equal(manifest.sourceCatalogueSHA256, sha(fs.readFileSync(path.join(root, manifest.sourceCatalogue))));
for (const proof of manifest.sourceVisualProofs) assert.equal(proof.sha256, sha(fs.readFileSync(path.join(root, proof.file))));
assert.deepEqual(manifest.profiles.mapTopDown.facings, mapFacings);
assert.equal(manifest.profiles.compactCameo.sourceRendererProfile, "world");
assert.equal(manifest.canonicalManifestSHA256, sha(canonical({ ...manifest, canonicalManifestSHA256: undefined })));
assert.equal(new Set(manifest.assets.map(entry => JSON.stringify(entry.key))).size, manifest.assets.length);

for (const entry of manifest.assets) {
  const expected = expectedCommands(entry.key);
  assert.deepEqual(entry.commands, expected);
  assert.equal(entry.commandSHA256, sha(canonical(expected)));
  assert.equal(entry.decodedRGBASHA256, sha(rgba(expected)));
}
for (const profile of ["compactCameo", ...mapFacings.map(facing => `mapTopDown:${facing}`)]) {
  const entries = manifest.assets.filter(entry => profile === "compactCameo" ? entry.key.profile === profile : entry.key.profile === "mapTopDown" && entry.key.facing === profile.split(":")[1]);
  assert.equal(entries.length, 29);
  assert.equal(new Set(entries.map(entry => entry.decodedRGBASHA256)).size, 29, `${profile} must retain 29 distinct placeholder rasters`);
}
for (const id of liveIDs) {
  const cameo = manifest.assets.find(entry => entry.key.travellerID === id && entry.key.profile === "compactCameo");
  assert.ok(cameo, `missing compact cameo for ${id}`);
  for (const facing of mapFacings) assert.ok(manifest.assets.find(entry => entry.key.travellerID === id && entry.key.profile === "mapTopDown" && entry.key.facing === facing), `missing ${facing} map sprite for ${id}`);
}
assert.equal(manifest.assets.some(entry => entry.key.travellerID === "unknown"), false);
console.log("named character placeholder pack: ok");
