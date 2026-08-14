import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  townLayerFileName,
  validateTownBuildingManifest,
  validateTownLayerPNG
} from "../src/town-building-generator.js";

const here = path.dirname(fileURLToPath(import.meta.url));
const assetRoot = path.resolve(here, "..");
const repoRoot = path.resolve(assetRoot, "..");
const args = Object.fromEntries(process.argv.slice(2).map((argument) => {
  const [key, ...value] = argument.replace(/^--/, "").split("=");
  return [key, value.length ? value.join("=") : true];
}));

if (typeof args.station !== "string" || typeof args.input !== "string") {
  throw new Error("usage: npm run accept:town-building -- --station=<stable_id> --input=<627px RGBA PNG> [--write]");
}

const cataloguePath = path.join(repoRoot, "Sources/Content/Data/stations.json");
const manifestPath = path.join(assetRoot, "town/town-building-generator-v1.json");
const catalogue = JSON.parse(fs.readFileSync(cataloguePath, "utf8"));
if (!catalogue.stations.some((station) => station.id === args.station)) {
  throw new Error(`unknown station: ${args.station}`);
}

const bytes = fs.readFileSync(path.resolve(args.input));
validateTownLayerPNG(bytes);
const file = townLayerFileName(args.station);
const sha256 = crypto.createHash("sha256").update(bytes).digest("hex");
const manifest = structuredClone(validateTownBuildingManifest(JSON.parse(fs.readFileSync(manifestPath, "utf8"))));
const existing = manifest.acceptedLayers[args.station];
if (existing && (existing.file !== file || existing.sha256 !== sha256)) {
  throw new Error(`${args.station} already has a different accepted layer; remove it only through explicit review`);
}

const result = { stationID: args.station, file, sha256, width: 627, height: 627, colorType: "rgba8" };
if (args.write === true) {
  const destination = path.join(repoRoot, "Sources/Content/TownVisuals", file);
  fs.copyFileSync(path.resolve(args.input), destination);
  manifest.acceptedLayers[args.station] = { file, sha256 };
  fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  result.written = { destination, manifestPath };
} else {
  result.written = false;
}

process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
