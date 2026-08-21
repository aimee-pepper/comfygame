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
const itemsAuthority = JSON.parse(await readFile(resolve(root, "../Sources/Content/Data/items.json"), "utf8"));
const resourcesAuthority = JSON.parse(await readFile(resolve(root, "../Sources/Content/Data/resources.json"), "utf8"));
const travellersAuthority = JSON.parse(await readFile(resolve(root, "../Sources/Content/Data/travellers.json"), "utf8"));
for (const type of ["station", "traveller", "resource", "creatureMaterial", "gear", "consumable", "curio", "treasure", "key", "rune", "roadmap"]) {
  assert(data.search.some(item => item.type === type), `search lacks ${type}`);
  const example = data.search.find(item => item.type === type);
  const query = example.name.toLowerCase();
  assert(data.search.some(item => `${item.name} ${item.id} ${item.summary} ${item.type}`.toLowerCase().includes(query)), `search cannot find representative ${type}`);
}
const itemCounts = Object.fromEntries(["gear", "consumable", "curio", "treasure", "key"].map(kind => [kind, data.items.filter(item => item.category === kind).length]));
assert(JSON.stringify(itemCounts) === JSON.stringify({ gear: 75, consumable: 18, curio: 2, treasure: 5, key: 2 }), "all 102 live items must partition exactly by kind");
assert(data.items.length === itemsAuthority.items.length && new Set(data.items.map(item => item.id)).size === 102, "item catalogue coverage must be exact and unique");
const gearSlots = Object.fromEntries(["weapon", "offhand", "head", "armor", "hands", "feet", "tool", "keepsake"].map(slot => [slot, data.items.filter(item => item.gear?.slot === slot).length]));
assert(JSON.stringify(gearSlots) === JSON.stringify({ weapon: 34, offhand: 6, head: 6, armor: 6, hands: 5, feet: 5, tool: 5, keepsake: 8 }), "gear slots must match the exact live catalogue");
assert(data.items.filter(item => item.gear?.slot === "weapon").every(item => item.gear.damage && item.gear.reach), "every weapon detail must expose damage and reach");
assert(data.items.every(item => item.summary && data.routes.includes(`item/${item.slug}`)), "every item needs a nonempty explanation and stable detail route");
assert(data.resources.length === 23 && data.resources.length === resourcesAuthority.resources.length && new Set(data.resources.map(item => item.id)).size === 23, "all 23 resource IDs must be accounted for exactly once");
assert(data.resources.every(item => ["worldResource", "currencyEssence"].includes(item.domain) && item.summary && item.currentUses.length && data.routes.includes(`resource/${item.slug}`)), "every resource needs one domain, explanation, uses and stable detail route");
assert(data.resources.filter(item => item.domain === "worldResource").length + data.resources.filter(item => item.domain === "currencyEssence").length === 23, "resource domains must form an exact partition");
assert(data.creatureMaterials.some(item => item.status === "live legacy material model") && data.creatureMaterials.some(item => item.status === "current design / not yet live"), "live and designed creature-material families must remain visibly separate");
const designedCreatureFamilies = data.creatureMaterials.filter(item => item.disposition === "proposed").map(item => item.familyID).sort();
assert(JSON.stringify(designedCreatureFamilies) === JSON.stringify(["bone", "chitin", "claw", "down", "fang", "feather", "fin", "hide", "horn", "ichor", "oil", "pelt", "plate", "quill", "scale", "shell", "tusk", "venom"]), "designed Creature Materials must be the exact 18-family ComponentProfile register");
assert(!designedCreatureFamilies.includes("table") && !designedCreatureFamilies.includes("families"), "Markdown table labels leaked into Creature Materials");
assert(data.creatureMaterials.every(item => item.summary && data.routes.includes(`creature-material/${item.slug}`)), "every Creature Material needs a nonempty explanation and stable detail route");
assert(data.search.filter(item => item.type === "creatureMaterial").every(item => item.route.startsWith("creature-material/") && item.category === "creatureMaterial"), "Creature Material search routes must remain exact");
assert(data.search.filter(item => ["gear", "consumable", "curio", "treasure", "key"].includes(item.type)).every(item => item.route.startsWith("item/") && item.category === item.type), "item search routes and categories must be exact");
assert(data.search.filter(item => item.type === "resource").every(item => item.route.startsWith("resource/") && ["worldResource", "currencyEssence"].includes(item.category)), "resource search routes and domains must be exact");
assert(data.travellers.length === 29 && new Set(data.travellers.map(person => person.id)).size === 29, "People must exactly cover the 29 live traveller identities");
assert(JSON.stringify(data.travellers.map(person => person.id).sort()) === JSON.stringify(travellersAuthority.travellers.map(person => person.id).sort()), "People IDs must exactly match travellers.json");
assert(data.travellers.map(person => person.authoredOrder).join(",") === Array.from({ length: 29 }, (_, index) => index + 1).join(","), "People index must follow exact authored campaign order");
assert(data.travellers.every(person => person.calling && person.authoredOrder && person.campaignPhase && person.pageCount > 0 && data.routes.includes(`person/${person.slug}`)), "every traveller needs role, order, phase, diary coverage and a stable detail route");
assert(data.travellers.every(person => ["live", "authored-not-live", "held"].includes(person.meetingStatus)), "meeting status must use an explicit implementation disposition");
assert(data.travellers.filter(person => person.meetingStatus === "live").length === travellersAuthority.travellers.filter(person => person.meeting).length, "live meeting status must derive exactly from travellers.json");
assert(data.travellers.every(person => person.recruitmentStatus && person.visualStatus && person.provenance.sourcePaths.length >= 5), "People detail status/provenance must be complete");
assert(data.search.filter(item => item.type === "traveller").every(item => item.route.startsWith("person/") && item.category === "traveller"), "traveller search must open exact person detail routes");
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
assert(data.assetGallery.slots.length === 86, "asset gallery must reserve 17×5 building/state slots plus the manifested Binder House root");
assert(data.assetGallery.slots.find(slot => slot.key === "trading_post.built")?.status === "Game Design accepted candidate / native integration not yet accepted", "Trading Post v0.3 must be distinguished from packaged/native/live art");
assert(data.assetGallery.slots.find(slot => slot.key === "trading_post.built")?.assetPath === null, "Trading Post acceptance must not invent a packaged asset path");
for (const id of ["recycler", "blacksmith", "storehouse", "firepit"]) {
  const slot = data.assetGallery.slots.find(candidate => candidate.key === `${id}.built`);
  assert(slot?.status === "Game Design accepted candidate / native integration not yet accepted", `${id}.built must preserve the checkpoint-2 candidate/native distinction`);
  assert(slot?.assetPath === null, `${id}.built must not invent a packaged asset path`);
}
const acceptedContinuityKeys = [
  "trading_post.foundation", "trading_post.improved", "trading_post.mastered", "trading_post.attention",
  "firepit.foundation", "firepit.improved", "firepit.mastered", "firepit.attention"
];
for (const key of acceptedContinuityKeys) {
  const slot = data.assetGallery.slots.find(candidate => candidate.key === key);
  assert(slot?.status === "Game Design accepted candidate / native integration not yet accepted", `${key} must preserve the checkpoint-3 candidate/native distinction`);
  assert(slot?.assetPath === null, `${key} must not invent a packaged asset path`);
}
const binderHouseRoot = data.assetGallery.slots.find(slot => slot.key === "binder_house.root");
assert(binderHouseRoot?.status === "Game Design accepted candidate / native integration not yet accepted", "Binder House root must preserve the candidate/native distinction");
assert(binderHouseRoot?.assetPath === null, "Binder House root must not invent a packaged asset path");
assert(!data.assetGallery.slots.some(slot => slot.key.startsWith("binder_house.") && slot.key !== "binder_house.root"), "Binder House must not invent independent state or attention asset IDs");
assert(data.assetGallery.slots.filter(slot => slot.status === "Game Design accepted candidate / native integration not yet accepted").length === 14, "only the five Built candidates, eight checkpoint-3 states and Binder House root may be candidate-accepted");
assert(data.assetGallery.slots.every(slot => slot.assetPath === null), "no unaccepted art path may enter a stable slot");
for (const item of data.search) {
  assert(item.provenance.generatedAtSourceHash === data.generatedAtSourceHash, `fact hash missing: ${item.type}/${item.id}`);
  assert(item.provenance.sourcePaths.length, `fact source missing: ${item.type}/${item.id}`);
}
for (const route of ["overview", "core-loop", "world-writing", "exploration", "combat", "people", "village-buildings", "resources-crafting", "catalogue", "catalogue/gear", "catalogue/consumables", "catalogue/curios", "catalogue/treasures", "catalogue/keys", "roadmap", "history", "asset-gallery"]) {
  assert(data.routes.includes(route), `required route missing: ${route}`);
}
const { resetRouteScroll } = await import("../public/route-scroll.js");
const scrollCalls = [];
resetRouteScroll({ scrollTo: options => scrollCalls.push(["window", options]) }, { scrollTo: options => scrollCalls.push(["content", options]) });
assert(scrollCalls.length === 2 && scrollCalls.every(([, options]) => options.top === 0 && options.left === 0 && options.behavior === "instant"), "phone route transitions must reset window and content scroll to the route top");
console.log(`Wiki tests passed: ${data.routes.length} routes, ${data.search.length} searchable facts, ${data.stations.length} station pages.`);
