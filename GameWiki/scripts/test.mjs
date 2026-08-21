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
const stationsAuthority = JSON.parse(await readFile(resolve(root, "../Sources/Content/Data/stations.json"), "utf8"));
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
assert(JSON.stringify(Object.keys(stationByID).sort()) === JSON.stringify(stationsAuthority.stations.map(station => station.id).sort()), "canonical register must exactly cover stations.json");
assert(stationByID.party.destinationKind === "houseInterface", "Party must be a House interface, not a building");
assert(stationByID.bestiary.destinationKind === "libraryShelf", "Bestiary must be a Library shelf, not a building");
assert(stationByID.workshop.destinationKind === "removedCompatibility", "Workshop must remain a removed compatibility route");
const buildings = data.stations.filter(station => station.destinationKind === "villageBuilding");
assert(buildings.length === 17, `expected 17 canonical village buildings; found ${buildings.length}`);
assert(buildings.every(station => station.forms.length === 3), "every village building must expose exactly three canonical forms");
assert(buildings.flatMap(station => station.forms).length === 51, "canonical form coverage must be 17×3");
assert(buildings.every(station => station.forms.map(form => form.state).join(",") === "built,improved,mastered"), "building form order must remain Built/Improved/Mastered");
assert(buildings.every(station => station.visualKey && station.assetSlots.length === 5), "every village building needs a visual key and five stable state slots");
assert(buildings.every(station => station.upgradeAuthorityStatus === "authored"), "canonical building tracks must be mapped as authored");
assert(buildings.every(station => station.zone && station.zone !== "District not yet assigned"), "every canonical village building must have an explicit district");
assert(stationByID.tannery.zone === "Makers' Row" && stationByID.survey_post.zone === "Commons" && stationByID.anchorage.zone === "Commons", "canonical districts must replace legacy homeSection guesses");
assert(stationByID.wayfarers_table.forms[1].name === "Sample Ledger" && !stationByID.wayfarers_table.forms.some(form => /satchel expansion/i.test(form.capability)), "Wayfarer's Table must not regain rejected satchel/departure ownership");
assert(stationByID.tannery.forms[1].capability.includes("advanced Satchel, deepened"), "Tannery Tier 1 must own the single advanced Satchel project");
assert(stationByID.recycler.forms[2].capability.startsWith("70% recovery") && stationByID.recycler.forms[2].capability.includes("rules remain exactly the same") && !/may prioritize/i.test(stationByID.recycler.forms[2].capability), "Recycler Tier 2 must not invent a priority mode");
assert(["Atlas", "Work", "People", "settlement", "Deliveries"].every(term => stationByID.anchorage.forms[0].capability.includes(term)), "Anchorage Tier 0 must retain its complete current surface");
assert(stationByID.firepit.forms[2].capability.includes("settled three-seat limit remains"), "Tavern Mastered must not invent a fourth seat");
assert(stationByID.reliquary.forms[1].capability.includes("never reads the already-rolled presence"), "Reliquary projection must not leak remote rolled sites");
assert(stationByID.apothecary.forms[0].capability.includes("Lesser Salve") && stationByID.apothecary.forms[1].name === "Concentration Bench" && stationByID.apothecary.forms[2].capability.includes("Waystone"), "Apothecary tiers must expose the exact current preparation bands");
assert(stationByID.apothecary.forms.every(form => /known|current common\/uncommon/.test(form.capability)), "Apothecary tier must not claim to teach recipes");
assert(!generatorSource.includes("defaultZone("), "legacy defaultZone geography inference returned");
assert(!generatorSource.includes("station.homeSection"), "homeSection must not assign wiki geography");
assert(!generatorSource.includes("station-authority-map.json"), "canonical destination facts must not be duplicated in a hand-maintained config");
assert(new Set(data.stations.map(station => station.upgradeAuthorityStatus)).size > 1, "upgrade authority must distinguish buildings from non-buildings");
assert(data.stations.every(station => !station.upgradeNote.toLowerCase().includes("authority incomplete")), "wiki mapping gaps must not claim game authority is incomplete");
assert(stationByID.constellation.upgradeAuthorityStatus === "partial" && stationByID.constellation.constellationProposal.length === 7, "Constellation must expose six proposed mastery stars plus implemented Long Instruction");
assert(stationByID.constellation.constellationProposal.filter(star => star.status === "proposed / review-gated").length === 6, "Constellation mastery expansion must remain explicitly unimplemented");
assert(stationByID.constellation.constellationProposal.find(star => star.name === "The Long Instruction")?.status === "implemented", "Long Instruction must remain the implemented star");
assert(data.assetGallery.acceptedAssets.length === 0 && data.assetGallery.reviewEvidence.length === 0, "rejected or uncommitted pixels entered the gallery");
assert(data.assetGallery.slots.length === 85, "asset gallery must reserve 17×5 stable building/state slots");
assert(data.assetGallery.slots.find(slot => slot.key === "trading_post.built")?.status === "Game Design accepted candidate / native integration not yet accepted", "Trading Post v0.3 must be distinguished from packaged/native/live art");
assert(data.assetGallery.slots.find(slot => slot.key === "trading_post.built")?.assetPath === null, "Trading Post acceptance must not invent a packaged asset path");
assert(data.assetGallery.slots.every(slot => slot.assetPath === null), "no unaccepted art path may enter a stable slot");
for (const item of data.search) {
  assert(item.provenance.generatedAtSourceHash === data.generatedAtSourceHash, `fact hash missing: ${item.type}/${item.id}`);
  assert(item.provenance.sourcePaths.length, `fact source missing: ${item.type}/${item.id}`);
}
for (const route of ["overview", "core-loop", "world-writing", "exploration", "combat", "people", "village-buildings", "resources-crafting", "items", "roadmap", "history", "asset-gallery"]) {
  assert(data.routes.includes(route), `required route missing: ${route}`);
}
console.log(`Wiki tests passed: ${data.routes.length} routes, ${data.search.length} searchable facts, ${data.stations.length} station pages.`);
