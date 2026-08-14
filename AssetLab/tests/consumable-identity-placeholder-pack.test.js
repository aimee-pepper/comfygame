import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { catalogueItemIconCommands } from "../src/item-kit.js";
import { allPreparationIDs } from "../src/consumable-field-kit-proof.js";

const here = path.dirname(fileURLToPath(import.meta.url));
const assetLab = path.resolve(here, "..");
const root = path.resolve(assetLab, "..");
execFileSync(process.execPath, [path.join(assetLab, "scripts/export-consumable-identity-placeholder-pack.mjs")], { cwd: assetLab });
const manifest = JSON.parse(fs.readFileSync(path.join(assetLab, "integration/catalogue-consumables-placeholder-v1/manifest.json"), "utf8"));
const items = JSON.parse(fs.readFileSync(path.join(root, "Sources/Content/Data/items.json"), "utf8")).items;
const liveIDs = items.map(item => item.id);
const canonical = value => Array.isArray(value) ? `[${value.map(canonical).join(",")}]` : value && typeof value === "object" ? `{${Object.keys(value).filter(key => value[key] !== undefined).sort().map(key => `${JSON.stringify(key)}:${canonical(value[key])}`).join(",")}}` : JSON.stringify(value);
const sha = value => crypto.createHash("sha256").update(value).digest("hex");
function decodedRGBA(commands, width = 32, height = 32) {
  const bytes = Buffer.alloc(width * height * 4);
  for (const command of commands) {
    const value = Number.parseInt(command.color.slice(1), 16), rgba = [value >> 16, (value >> 8) & 255, value & 255, 255];
    for (let y = command.y; y < command.y + command.h; y++) for (let x = command.x; x < command.x + command.w; x++) {
      const offset = (y * width + x) * 4;
      bytes.set(rgba, offset);
    }
  }
  return bytes;
}

assert.equal(manifest.integrationReady, true);
assert.equal(manifest.finalArt, false);
assert.equal(manifest.evidenceRole, "functionalPlaceholderConformancePack");
assert.equal(manifest.sourceCatalogueSHA256, sha(fs.readFileSync(path.join(root, manifest.sourceCatalogue))));
assert.equal(manifest.sourceVisualProofSHA256, sha(fs.readFileSync(path.join(root, manifest.sourceVisualProof))));
assert.equal(manifest.assets.length, 17);
assert.deepEqual(manifest.supportedIdentifiedCatalogueIDs, allPreparationIDs);
assert.equal(manifest.explicitlyUnsupportedCatalogueIDs.length, 61);
assert.deepEqual(new Set([...manifest.supportedIdentifiedCatalogueIDs, ...manifest.explicitlyUnsupportedCatalogueIDs]), new Set(liveIDs));
assert.equal(new Set(manifest.assets.map(entry => JSON.stringify(entry.key))).size, 17);
assert.equal(manifest.canonicalManifestSHA256, sha(canonical({ ...manifest, canonicalManifestSHA256: undefined })));

for (const entry of manifest.assets) {
  const expected = catalogueItemIconCommands(entry.key.catalogueID);
  assert.equal(entry.key.identified, true);
  assert.deepEqual(entry.commands, expected);
  assert.equal(entry.commandSHA256, sha(canonical(expected)));
  assert.equal(entry.decodedRGBASHA256, sha(decodedRGBA(expected)));
}

assert.equal(new Set(manifest.assets.map(entry => entry.decodedRGBASHA256)).size, 17,
  "all consumable placeholder rasters remain distinct");
console.log("consumable identity placeholder pack: ok");
