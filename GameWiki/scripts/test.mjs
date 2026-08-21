import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const dataPath = join(root, "generated/wiki-data.json");
const sha = value => createHash("sha256").update(value).digest("hex");
const assert = (condition, message) => { if (!condition) throw new Error(message); };
const run = script => {
  const result = spawnSync(process.execPath, [join(root, "scripts", script)], { encoding: "utf8" });
  if (result.status !== 0) throw new Error(result.stderr || result.stdout || `${script} failed`);
};

run("check.mjs");
const before = sha(await readFile(dataPath));
run("generate.mjs");
const once = sha(await readFile(dataPath));
run("generate.mjs");
const twice = sha(await readFile(dataPath));
assert(before === once && once === twice, "generation is not deterministic");

const data = JSON.parse(await readFile(dataPath, "utf8"));
const generatorSource = await readFile(join(root, "scripts/generate.mjs"), "utf8");
for (const type of ["station", "traveller", "resource", "item", "rune", "roadmap"]) {
  assert(data.search.some(item => item.type === type), `search lacks ${type}`);
  const example = data.search.find(item => item.type === type);
  const query = example.name.toLowerCase();
  assert(data.search.some(item => `${item.name} ${item.id} ${item.summary} ${item.type}`.toLowerCase().includes(query)), `search cannot find representative ${type}`);
}
for (const station of data.stations) {
  assert(station.id && station.provenance.stableID === station.id, `station provenance missing: ${station.id}`);
  assert(station.provenance.sourcePaths.length >= 3, `station authority sources missing: ${station.id}`);
  assert(["authored", "partial", "unaudited", "none"].includes(station.upgradeAuthorityStatus), `station upgrade status invalid: ${station.id}`);
  assert(data.routes.includes(`station/${station.slug}`), `station route missing: ${station.id}`);
}
const stationByID = Object.fromEntries(data.stations.map(station => [station.id, station]));
assert(stationByID.party.destinationKind === "houseInterface", "Party must be a House interface, not a building");
assert(stationByID.bestiary.destinationKind === "libraryShelf", "Bestiary must be a Library shelf, not a building");
assert(stationByID.workshop.destinationKind === "removedCompatibility", "Workshop must remain a removed compatibility route");
for (const station of data.stations.filter(station => station.lifecycle === "found then built")) {
  assert(station.destinationKind === "villageBuilding", `found-then-built destination must be a village building: ${station.id}`);
}
for (const id of ["tannery", "survey_post", "anchorage"]) {
  assert(stationByID[id].zone === "District not yet assigned", `legacy homeSection inferred geography for ${id}`);
  assert(stationByID[id].zoneDisposition === "provisional", `unassigned geography must remain provisional for ${id}`);
}
assert(!generatorSource.includes("defaultZone("), "legacy defaultZone geography inference returned");
assert(!generatorSource.includes("station.homeSection"), "homeSection must not assign wiki geography");
assert(new Set(data.stations.map(station => station.upgradeAuthorityStatus)).size > 1, "upgrade authority is still a blanket status");
assert(data.stations.some(station => station.upgradeAuthorityStatus === "unaudited" && station.upgradeNote === "Upgrade track not yet mapped in wiki."), "unaudited wiki mapping state is missing");
assert(data.stations.every(station => !station.upgradeNote.toLowerCase().includes("authority incomplete")), "wiki mapping gaps must not claim game authority is incomplete");
for (const item of data.search) {
  assert(item.provenance.generatedAtSourceHash === data.generatedAtSourceHash, `fact hash missing: ${item.type}/${item.id}`);
  assert(item.provenance.sourcePaths.length, `fact source missing: ${item.type}/${item.id}`);
}
for (const route of ["overview", "core-loop", "world-writing", "exploration", "combat", "people", "village-buildings", "resources-crafting", "items", "roadmap", "history", "asset-gallery"]) {
  assert(data.routes.includes(route), `required route missing: ${route}`);
}
assert(data.assetGallery.acceptedAssets.length === 0, "unapproved art entered the gallery");
console.log(`Wiki tests passed: ${data.routes.length} routes, ${data.search.length} searchable facts, ${data.stations.length} station pages.`);
