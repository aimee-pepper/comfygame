import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { catalogueItemIconCommands } from "../src/item-kit.js";
import { allPreparationIDs } from "../src/consumable-field-kit-proof.js";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "../..");
const outputDirectory = path.resolve(here, "../integration/catalogue-consumables-placeholder-v1");
const itemCataloguePath = path.join(root, "Sources/Content/Data/items.json");
const itemCatalogueBytes = fs.readFileSync(itemCataloguePath);
const items = JSON.parse(itemCatalogueBytes).items;
const liveIDs = items.map(item => item.id);
const supported = [...allPreparationIDs];
const supportedSet = new Set(supported);

function canonical(value) {
  if (Array.isArray(value)) return `[${value.map(canonical).join(",")}]`;
  if (value && typeof value === "object") return `{${Object.keys(value).filter(key => value[key] !== undefined).sort().map(key => `${JSON.stringify(key)}:${canonical(value[key])}`).join(",")}}`;
  return JSON.stringify(value);
}
const sha256 = value => crypto.createHash("sha256").update(value).digest("hex");
function decodedRGBA(commands, width = 32, height = 32) {
  const bytes = Buffer.alloc(width * height * 4);
  for (const command of commands) {
    const match = /^#([0-9a-f]{6})$/i.exec(command.color);
    if (!match) throw new Error(`unsupported-color:${command.color}`);
    const value = Number.parseInt(match[1], 16), rgba = [value >> 16, (value >> 8) & 255, value & 255, 255];
    for (let y = command.y; y < command.y + command.h; y++) for (let x = command.x; x < command.x + command.w; x++) {
      const offset = (y * width + x) * 4;
      bytes[offset] = rgba[0]; bytes[offset + 1] = rgba[1]; bytes[offset + 2] = rgba[2]; bytes[offset + 3] = rgba[3];
    }
  }
  return bytes;
}

if (liveIDs.length !== 78 || new Set(liveIDs).size !== liveIDs.length) throw new Error("live-catalogue-not-exact-78");
if (supported.length !== 17 || new Set(supported).size !== supported.length) throw new Error("consumable-slice-not-exact-17");
for (const id of supported) if (!liveIDs.includes(id)) throw new Error(`unknown-consumable:${id}`);

const assets = supported.map(catalogueID => {
  const commands = catalogueItemIconCommands(catalogueID);
  return {
    key: { catalogueID, identified: true },
    width: 32,
    height: 32,
    commands,
    commandSHA256: sha256(canonical(commands)),
    decodedRGBASHA256: sha256(decodedRGBA(commands)),
  };
});

const manifest = {
  schemaVersion: 1,
  packID: "catalogue-consumables-placeholder-v1",
  pipelineVersion: "catalogue-consumables-functional-placeholder-1.0.0",
  evidenceRole: "functionalPlaceholderConformancePack",
  integrationReady: true,
  finalArt: false,
  replacementAuthority: "Aimee immutable catalogue-items-v1 pack",
  sourceCatalogue: "Sources/Content/Data/items.json",
  sourceCatalogueSHA256: sha256(itemCatalogueBytes),
  sourceVisualProof: "AssetLab/artifacts/consumable-field-kit-proof-v0.1.png",
  sourceVisualProofSHA256: sha256(fs.readFileSync(path.join(root, "AssetLab/artifacts/consumable-field-kit-proof-v0.1.png"))),
  canvas: { width: 32, height: 32 },
  identityKey: ["catalogueID", "identified"],
  supportedIdentifiedCatalogueIDs: supported,
  explicitlyUnsupportedCatalogueIDs: liveIDs.filter(id => !supportedSet.has(id)),
  unidentifiedBehavior: "variant absent; native retains disclosure-neutral fallback",
  nativeGeneratorRequirement: "convert each #RRGGBB rectangle to immutable RGBA PixelCommand; registry must preserve all hashes and exact 78-ID asset-or-unsupported partition",
  exclusions: [
    "no map profile; any future placed-world item asset must be top-down",
    "no character, resource, terrain, flora, station, weapon or final item art",
    "no world-color or visual-novelty input; world similarity continues to follow resolved statistical similarity",
  ],
  invariants: [
    "same catalogueID commands in Storehouse, loot, equipment, Trading Post, Recycler and Field Kit",
    "rarity, stats, quantity, price, location and array order never alter identity commands",
    "unknown or unsupported IDs fail closed to the native fallback",
    "placeholder pixels are not final handmade item art",
  ],
  assets,
  canonicalManifestSHA256: "",
};
manifest.canonicalManifestSHA256 = sha256(canonical({ ...manifest, canonicalManifestSHA256: undefined }));
fs.mkdirSync(outputDirectory, { recursive: true });
fs.writeFileSync(path.join(outputDirectory, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`);
console.log(manifest.canonicalManifestSHA256);
