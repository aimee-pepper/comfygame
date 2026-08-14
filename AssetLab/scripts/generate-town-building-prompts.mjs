import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { townBuildingPrompt, validateTownBuildingManifest } from "../src/town-building-generator.js";

const here = path.dirname(fileURLToPath(import.meta.url));
const assetRoot = path.resolve(here, "..");
const repoRoot = path.resolve(assetRoot, "..");
const manifest = validateTownBuildingManifest(JSON.parse(fs.readFileSync(path.join(assetRoot, "town/town-building-generator-v1.json"), "utf8")));
const catalogue = JSON.parse(fs.readFileSync(path.join(repoRoot, "Sources/Content/Data/stations.json"), "utf8"));
const args = Object.fromEntries(process.argv.slice(2).map((arg) => {
  const [key, ...rest] = arg.replace(/^--/, "").split("=");
  return [key, rest.join("=")];
}));
const station = catalogue.stations.find((candidate) => candidate.id === args.station);
if (!station) throw new Error(`unknown station: ${args.station ?? "(missing --station)"}`);
const plot = args.plot ?? "upperLeft";
process.stdout.write(`${townBuildingPrompt(manifest, station, plot)}\n`);
