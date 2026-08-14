import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  characterCommands,
  mapFacings,
  namedCharacterCatalogue,
  provisionalNollDescriptor,
} from "../src/character-kit.js";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "../..");
const outputDirectory = path.resolve(here, "../integration/named-character-placeholders-v1");
const cataloguePath = path.join(root, "Sources/Content/Data/travellers.json");
const catalogueBytes = fs.readFileSync(cataloguePath);
const liveTravellers = JSON.parse(catalogueBytes).travellers;
const liveIDs = liveTravellers.map(person => person.id);
const acceptedDescriptors = new Map(namedCharacterCatalogue.map(person => [person.id, person.descriptor]));
const proofPaths = [
  "AssetLab/artifacts/character-identity-proof-v0.4.png",
  "AssetLab/artifacts/full-cast-descriptor-proof-v0.2.png",
  "AssetLab/artifacts/map-top-down-full-cast-proof-v0.1.png",
  "AssetLab/artifacts/provisional-noll-identity-proof-v0.2.png",
];

function canonical(value) {
  if (Array.isArray(value)) return `[${value.map(canonical).join(",")}]`;
  if (value && typeof value === "object") return `{${Object.keys(value).filter(key => value[key] !== undefined).sort().map(key => `${JSON.stringify(key)}:${canonical(value[key])}`).join(",")}}`;
  return JSON.stringify(value);
}
const sha256 = value => crypto.createHash("sha256").update(value).digest("hex");
function decodedRGBA(commands, width = 16, height = 16) {
  const bytes = Buffer.alloc(width * height * 4);
  for (const command of commands) {
    if (command.op !== "rect") throw new Error(`unsupported-command:${command.op}`);
    const match = /^#([0-9a-f]{6})$/i.exec(command.color);
    if (!match) throw new Error(`unsupported-color:${command.color}`);
    if (![command.x, command.y, command.w, command.h].every(Number.isInteger) || command.w <= 0 || command.h <= 0 || command.x < 0 || command.y < 0 || command.x + command.w > width || command.y + command.h > height) throw new Error("command-out-of-bounds");
    const value = Number.parseInt(match[1], 16), rgba = [value >> 16, (value >> 8) & 255, value & 255, 255];
    for (let y = command.y; y < command.y + command.h; y++) for (let x = command.x; x < command.x + command.w; x++) {
      const offset = (y * width + x) * 4;
      bytes[offset] = rgba[0]; bytes[offset + 1] = rgba[1]; bytes[offset + 2] = rgba[2]; bytes[offset + 3] = rgba[3];
    }
  }
  return bytes;
}
function descriptorFor(id) {
  if (id === "noll") return provisionalNollDescriptor;
  const descriptor = acceptedDescriptors.get(id);
  if (!descriptor) throw new Error(`missing-reviewed-placeholder:${id}`);
  return descriptor;
}
function asset(id, profile, facing = null) {
  const rendererProfile = profile === "compactCameo" ? "world" : "mapTopDown";
  const commands = characterCommands(id === "noll" ? "provisional_noll" : id, {
    profile: rendererProfile,
    descriptor: descriptorFor(id),
    ...(facing ? { facing } : {}),
  });
  return {
    key: { travellerID: id, profile, ...(facing ? { facing } : {}) },
    width: 16,
    height: 16,
    commands,
    commandSHA256: sha256(canonical(commands)),
    decodedRGBASHA256: sha256(decodedRGBA(commands)),
  };
}

if (liveIDs.length !== 29 || new Set(liveIDs).size !== 29) throw new Error("live-traveller-catalogue-not-exact-29");
if (namedCharacterCatalogue.length !== 28 || acceptedDescriptors.has("noll")) throw new Error("accepted-character-proof-boundary-drift");
const missing = liveIDs.filter(id => id !== "noll" && !acceptedDescriptors.has(id));
const orphaned = [...acceptedDescriptors.keys()].filter(id => !liveIDs.includes(id));
if (missing.length || orphaned.length || !liveIDs.includes("noll")) throw new Error(`live-proof-join-mismatch:${missing.join(",")}:${orphaned.join(",")}`);

const assets = liveIDs.flatMap(id => [asset(id, "compactCameo"), ...mapFacings.map(facing => asset(id, "mapTopDown", facing))]);
const manifest = {
  schemaVersion: 1,
  packID: "named-character-placeholders-v1",
  pipelineVersion: "named-character-functional-placeholder-1.0.0",
  evidenceRole: "functionalPlaceholderConformancePack",
  integrationReady: true,
  finalArt: false,
  replacementAuthority: "Aimee handmade named-character art pack",
  sourceCatalogue: "Sources/Content/Data/travellers.json",
  sourceCatalogueSHA256: sha256(catalogueBytes),
  sourceVisualProofs: proofPaths.map(file => ({ file, sha256: sha256(fs.readFileSync(path.join(root, file))) })),
  canvas: { width: 16, height: 16 },
  identityKey: ["travellerID", "profile", "facing?"],
  supportedTravellerIDs: liveIDs,
  profiles: {
    compactCameo: {
      camera: "compact-upright",
      consumers: ["Party", "Library People", "Library diary author"],
      sourceRendererProfile: "world",
      note: "explicit pack profile alias; never infer from calling or reuse as map camera",
    },
    mapTopDown: {
      camera: "straight-top-down",
      consumers: ["World map"],
      facings: mapFacings,
      note: "crown-over-upper-back; no face plane; direction is rules-owned",
    },
  },
  descriptorGovernance: {
    acceptedCatalogueIDs: namedCharacterCatalogue.map(person => person.id),
    noll: "Decision 182 stable live identity using the accepted provisional Noll v0.2 placeholder descriptor; still replaceable handmade art",
  },
  nativeGeneratorRequirement: "convert each #RRGGBB rectangle to immutable RGBA PixelCommand; registry must preserve exact stable TravellerID/profile/facing keys and all hashes",
  exclusions: [
    "no final character art and no profession/calling-derived anatomy",
    "no Binder, Quill or generated-person persistence contract",
    "no combat portrait, building/station, weapon, item, sigil or tutorial art",
    "no world novelty optimization; map coloration may only consume the separately resolved bounded world grade",
  ],
  invariants: [
    "the same stable TravellerID resolves across map, Party and Library",
    "Party and Library use the same compactCameo pixels",
    "map always uses mapTopDown and never silently substitutes compactCameo",
    "name, calling, recruitment state, equipment, selection and array order never alter placeholder identity commands",
    "unknown TravellerID, profile or facing fails closed to native fallback",
  ],
  assets,
  canonicalManifestSHA256: "",
};
manifest.canonicalManifestSHA256 = sha256(canonical({ ...manifest, canonicalManifestSHA256: undefined }));
fs.mkdirSync(outputDirectory, { recursive: true });
fs.writeFileSync(path.join(outputDirectory, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`);
console.log(manifest.canonicalManifestSHA256);
