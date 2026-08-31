import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { assertUniqueVisualRoutes, extractPNGReferences, partitionVisualRecords, publicVisualRecord, visualRecordIdentity, visualVariant } from "./visual-assets.mjs";

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
const appSource = await readFile(join(root, "public/app.js"), "utf8");
const stationsAuthority = JSON.parse(await readFile(resolve(root, "../Sources/Content/Data/stations.json"), "utf8"));
const itemsAuthority = JSON.parse(await readFile(resolve(root, "../Sources/Content/Data/items.json"), "utf8"));
const resourcesAuthority = JSON.parse(await readFile(resolve(root, "../Sources/Content/Data/resources.json"), "utf8"));
const travellersAuthority = JSON.parse(await readFile(resolve(root, "../Sources/Content/Data/travellers.json"), "utf8"));
const terminologyAuthority = JSON.parse(await readFile(resolve(root, "../docs/canonical-game-terminology.json"), "utf8"));
const roadmapAuthority = JSON.parse(await readFile(resolve(root, "../Sources/Content/Data/playability-roadmap.json"), "utf8"));
const terrainContinuityManifest = JSON.parse(await readFile(resolve(root, "../AssetLab/artifacts/terrain-region-continuity-v1/manifest.json"), "utf8"));
const writingParchmentManifest = JSON.parse(await readFile(resolve(root, "../AssetLab/artifacts/writing-parchment-v1/manifest.json"), "utf8"));
const worldMaterialCorrectionManifest = JSON.parse(await readFile(resolve(root, "../AssetLab/integration/world-material-pixel-correction-v1/manifest.json"), "utf8"));
const topLevelRoutes = ["overview", "core-loop", "world-writing", "exploration", "combat", "people", "village-buildings", "resources-crafting", "catalogue", "roadmap", "history", "asset-gallery"];
assert(topLevelRoutes.length === 12 && topLevelRoutes.every(route => data.routes.includes(route)), "all 12 top-level routes must remain registered");
for (const renderer of ["overview", "coreLoop", "worldWriting", "exploration", "combat", "people", "village", "resources", "catalogue", "roadmap", "history", "assets"]) {
  assert(appSource.includes(`function ${renderer}(`), `top-level route lacks dedicated renderer: ${renderer}`);
}
for (const type of ["station", "traveller", "resource", "creatureMaterial", "gear", "consumable", "curio", "treasure", "key", "rune", "roadmap", "terminology"]) {
  assert(data.search.some(item => item.type === type), `search lacks ${type}`);
  const example = data.search.find(item => item.type === type);
  const query = example.name.toLowerCase();
  assert(data.search.some(item => item.searchText.includes(query)), `search cannot find representative ${type}`);
}
const itemCounts = Object.fromEntries(["gear", "consumable", "curio", "treasure", "key"].map(kind => [kind, data.items.filter(item => item.category === kind).length]));
const authorityItemCounts = Object.fromEntries(["gear", "consumable", "curio", "treasure", "key"].map(kind => [kind, itemsAuthority.items.filter(item => item.kind === kind).length]));
assert(JSON.stringify(itemCounts) === JSON.stringify(authorityItemCounts), "live items must partition exactly by the current authored kinds");
assert(data.items.length === itemsAuthority.items.length && new Set(data.items.map(item => item.id)).size === itemsAuthority.items.length, "item catalogue coverage must be exact and unique");
const gearSlots = Object.fromEntries(["weapon", "offhand", "head", "armor", "hands", "feet", "tool", "keepsake"].map(slot => [slot, data.items.filter(item => item.gear?.slot === slot).length]));
assert(JSON.stringify(gearSlots) === JSON.stringify({ weapon: 34, offhand: 6, head: 6, armor: 6, hands: 5, feet: 5, tool: 5, keepsake: 8 }), "gear slots must match the exact live catalogue");
assert(data.items.filter(item => item.gear?.slot === "weapon").every(item => item.gear.damage && item.gear.reach), "every weapon detail must expose damage and reach");
assert(data.items.every(item => item.summary && data.routes.includes(`item/${item.slug}`)), "every item needs a nonempty explanation and stable detail route");
for (const copy of ["Sold by the Trading Post", "Accepted by the Recycler", "No value is currently defined."]) {
  assert(appSource.includes(copy), `item detail lacks canonical player copy: ${copy}`);
}
for (const leak of ["None authored in items.json", "sellable", "recyclable"]) {
  assert(!appSource.includes(`\`${leak}`) && !appSource.includes(`\"${leak}\"`), `item detail exposes implementation copy: ${leak}`);
}
assert(data.resources.length === 23 && data.resources.length === resourcesAuthority.resources.length && new Set(data.resources.map(item => item.id)).size === 23, "all 23 resource IDs must be accounted for exactly once");
assert(data.resources.every(item => ["worldResource", "currencyEssence"].includes(item.category) && ["World resource", "Currency & Essence"].includes(item.domain) && item.summary && item.currentUses.length && data.routes.includes(`resource/${item.slug}`)), "every resource needs one domain, explanation, uses and stable detail route");
assert(data.resources.filter(item => item.category === "worldResource").length + data.resources.filter(item => item.category === "currencyEssence").length === 23, "resource domains must form an exact partition");
assert(data.creatureMaterials.every(item => item.status === "current design / not yet live"), "Creature Materials must retain their current non-live design disposition");
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
const lexemeCounts = Object.fromEntries(["target", "source", "qualifier", "compound"].map(kind => [kind, data.symbols.filter(item => item.category === kind).length]));
assert(data.symbols.length + data.withheldVocabulary.count === 108, "World Writing must account for all 108 canonical lexemes without emitting hidden identities");
assert(JSON.stringify(lexemeCounts) === JSON.stringify({ target: 8, source: 15, qualifier: 17, compound: 12 }), "World Writing must emit only always-visible and starter vocabulary");
assert(data.withheldVocabulary.count === 56 && JSON.stringify(data.withheldVocabulary.byPlayerKind) === JSON.stringify({ Focus: 47, Compound: 9 }), "hidden vocabulary must be represented only by anonymous aggregate counts");
assert(data.symbols.every(item => item.stableID && item.summary && item.writability && item.disclosure && data.routes.includes(`lexeme/${item.slug}`)), "every lexeme needs typed facts, disclosure state and a stable detail route");
assert(data.symbols.filter(item => ["source", "compound"].includes(item.category)).every(item => item.writability === `Writable after this ${item.playerKind} is learned`), "learned Focus and Compound writability must use canonical player kinds");
assert(data.symbols.every(item => !/campaign owns this|\bsource\b|\bqualifier\b/i.test(item.writability)), "lexeme writability must not expose internal ownership or player-kind names");
assert(data.symbols.every(item => ["Found in a world", "Learned through an Upgrade", "Learned from diary writing", "Known at the start", "Always available vocabulary"].includes(item.acquisition)), "lexeme acquisition must use the closed player-copy mapping");
assert(data.symbols.every(item => ["starter", "always"].includes(item.internalAcquisition)), "undisclosed acquisition kinds must never enter generated vocabulary records");
assert(data.routes.filter(route => route.startsWith("lexeme/")).length === data.symbols.length, "World Writing must register routes only for disclosed lexemes");
assert(data.search.filter(item => item.type === "rune").length === data.symbols.length, "World Writing must search only disclosed lexemes");
assert(data.search.filter(item => item.type === "rune").every(item => item.route.startsWith("lexeme/") && ["Subject", "Focus", "Modifier", "Compound"].includes(item.category)), "Sigil search must open exact player-kind lexeme routes");
const resourceByID = Object.fromEntries(data.resources.map(item => [item.id, item]));
assert(resourceByID.ore.summary === "Mostly shaped by Substrate pressure.", "resource detail must lead with a plain pressure explanation");
assert(resourceByID.ore.favours.includes("Hard Substrate helps at 25/100 or more."), "resource form minimum must be explained plainly");
assert(resourceByID.silver.favours.includes("Valuable Substrate helps when present."), "resource tag presence must be explained plainly");
assert(resourceByID.quartz.favours.includes("Atmospheric clarity helps at 70/100 or more."), "resource aspect minimum must be explained plainly");
assert(resourceByID.clay.favours.includes("Available water helps at 30/100 or more."), "resource available minimum must be explained plainly");
assert(resourceByID.clay.favours.includes("Hard Substrate helps at 25/100 or less."), "resource maximum must be explained plainly");
assert(resourceByID.obsidian.favours.some(value => value.startsWith("Geothermal heat")), "geothermal tag needs a closed plain subject");
assert(resourceByID.salt.favours.some(value => value.startsWith("Briny water")) && resourceByID.salt.favours.some(value => value.startsWith("Water salinity")), "brine and salinity need closed water subjects");
assert(resourceByID.toxin.favours.some(value => value.startsWith("Toxic air")), "atmosphere toxicity needs a closed plain subject");
assert(resourceByID.adamant.favours.some(value => value.startsWith("Unstable ground")), "unstable-ground tag needs a closed plain subject");
assert(resourceByID.ichor.favours.some(value => value.startsWith("Sourceless light")), "sourceless illumination needs a closed plain subject");
assert(resourceByID.fiber.favours.some(value => value.includes("trophic depth")), "camel-case resource aspects must split into words");
assert(resourceByID.rift_glass.favours.some(value => value.startsWith("Irregular World cycle")), "arrhythmic cycle needs a closed plain subject");
assert(data.resources.every(item => ["World resource", "Currency & Essence"].includes(item.domain) && item.tradeBand[0] === item.tradeBand[0].toUpperCase()), "resource domains and trade bands must be readable display values");
assert(data.resources.some(item => item.currentUses.includes("No current Village construction recipe uses this resource.")), "unused resources need a plain Village construction explanation");
assert(data.resources.some(item => item.currentUses.includes("Used to construct the Blacksmith.")), "construction uses must read as plain player-facing sentences");
assert(data.resources.some(item => item.currentUses.includes("Used to construct the Armoury.")), "leading The in a building name must be sentence-cased");
assert(data.resources.every(item => !item.currentUses.some(value => /Used to construct (?:the The|The)\b/.test(value))), "construction-use formatter left a mid-sentence capital article");
assert(data.resources.every(item => !item.summary.includes("Driven by") && !item.currentUses.some(value => value.includes("stations.json"))), "resource detail must not lead with raw generator grammar or source filenames");
assert(data.roadmap.every(item => item.summary && item.gate && data.routes.includes(`roadmap/${item.slug}`)), "every roadmap receipt needs explanation, gate and detail route");
const authorityPrimaries = roadmapAuthority.items.filter(item => item.isPrimary).map(item => item.id).sort();
const generatedPrimaries = data.roadmap.filter(item => item.isPrimary).map(item => item.id).sort();
assert(JSON.stringify(generatedPrimaries) === JSON.stringify(authorityPrimaries), "roadmap primary IDs must derive from current data");
assert(authorityPrimaries.length === 1, "current roadmap authority must declare exactly one primary");
assert(data.terminology.length === terminologyAuthority.terms.length, "every terminology authority entry must have one generated concept");
assert(new Set(data.terminology.map(term => term.id)).size === terminologyAuthority.terms.length, "terminology concept IDs must be unique");
assert(data.terminology.every(term => data.routes.filter(route => route === `terminology/${term.slug}`).length === 1), "every terminology concept needs exactly one detail route");
for (const authorityTerm of terminologyAuthority.terms) {
  const term = data.terminology.find(candidate => candidate.id === authorityTerm.concept);
  assert(term?.name === authorityTerm.canonical, `canonical terminology title mismatch: ${authorityTerm.concept}`);
  for (const alias of authorityTerm.retire) {
    const matches = data.search.filter(item => item.searchText.includes(alias.toLowerCase()) && item.route === `terminology/${term.slug}`);
    assert(matches.length === 1 && matches[0].name === authorityTerm.canonical && matches[0].category === "Terminology", `retired alias must invisibly route to canonical concept: ${authorityTerm.concept}/${alias}`);
  }
}
assert(!data.terminology.some(term => term.aliases.some(alias => alias === term.name)), "retired aliases may not become canonical titles");
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
assert(data.assetGallery.acceptedAssets.length === 0 && data.assetGallery.reviewEvidence.length === 0, "building candidates or review evidence entered native asset collections");
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
assert(data.visualAssets.families.length === 27 && data.visualAssets.summary.familyCount === 27, "Visual Assets must account for every unique AssetLab manifest family");
assert(new Set(data.visualAssets.families.map(family => family.id)).size === data.visualAssets.families.length, "visual family IDs must remain unique");
assert(data.visualAssets.families.every(family => data.routes.includes(`asset-family/${family.slug}`)), "every visual family needs a semantic detail route");
assert(data.visualAssets.families.every(family => data.search.some(item => item.type === "visualAssetFamily" && item.id === family.id && item.route === `asset-family/${family.slug}`)), "every visual family must be searchable by semantic identity");
assert(data.visualAssets.families.every(family => family.manifestPaths.length && (family.assets.length || family.blockers.length)), "every visual family must render manifested records or state an explicit blocker");
assert(data.visualAssets.families.flatMap(family => family.assets).every(asset => ["source", "runtime", "reference", "evidence"].includes(asset.role)), "visual records must preserve source/runtime/reference/evidence ownership");
assert(data.visualAssets.families.flatMap(family => family.assets).filter(asset => asset.previewURL).every(asset => !/[0-9a-f]{64}/.test(asset.previewURL)), "wiki preview navigation must never expose hash filenames");
const visualRecords = data.visualAssets.families.flatMap(family => family.assets);
assert(visualRecords.every(asset => data.routes.filter(route => route === asset.route).length === 1), "every disclosed visual record needs exactly one registered route");
assert(new Set(visualRecords.map(asset => asset.route)).size === visualRecords.length, "visual record routes must be globally collision-free");
assert(visualRecords.every(asset => asset.route === visualRecordIdentity({ familyID: asset.route.split("/")[1], role: asset.role, semanticKey: asset.semanticKey, variant: asset.variant }).route), "visual routes must derive only from family, role, semantic key and explicit variant");
assert(visualRecords.every(asset => !/--\d+(?:\/|$)/.test(asset.route) && !/[0-9a-f]{64}/.test(`${asset.route} ${asset.sourceRoute} ${asset.previewURL ?? ""}`)), "semantic navigation must never use order suffixes or hash names");
assert(data.search.filter(item => item.type === "visualAssetRecord").length === visualRecords.length, "every disclosed visual record must have an individual search entry");
const terrainContinuityFamily = data.visualAssets.families.find(family => family.id === "terrain-region-continuity-v1");
const expectedTerrainEvidencePaths = terrainContinuityManifest.outputs.map(output => `AssetLab/artifacts/terrain-region-continuity-v1/${output.name}`);
const terrainEvidenceRecords = terrainContinuityFamily.assets.filter(asset => expectedTerrainEvidencePaths.includes(asset.sourcePath));
assert(terrainEvidenceRecords.length === 43 && terrainEvidenceRecords.every(asset => asset.role === "evidence" && asset.integrity === "verified"), "terrain continuity must expose all 43 pack-declared output records as verified evidence");
const writingParchmentFamily = data.visualAssets.families.find(family => family.id === "writing-parchment-v1");
const expectedWritingEvidencePaths = writingParchmentManifest.evidence.map(file => `AssetLab/artifacts/writing-parchment-v1/evidence/${file}`);
const expectedWritingReferencePath = `AssetLab/artifacts/writing-parchment-v1/${writingParchmentManifest.productionSource.reference}`;
assert(expectedWritingEvidencePaths.every(path => writingParchmentFamily.assets.some(asset => asset.sourcePath === path && asset.role === "evidence")), "Writing Parchment must expose all nine pack-declared review files as evidence");
assert(writingParchmentFamily.assets.some(asset => asset.sourcePath === expectedWritingReferencePath && asset.role === "reference"), "Writing Parchment must expose its generated comparison raster as a reference, never a source or approval");
const worldMaterialFamily = data.visualAssets.families.find(family => family.id === "world-material-pixel-correction-v1");
const expectedWorldMaterialEvidencePaths = Object.values(worldMaterialCorrectionManifest.evidence).map(entry => `AssetLab/artifacts/world-material-pixel-correction-v1/${entry.file}`);
assert(expectedWorldMaterialEvidencePaths.every(path => worldMaterialFamily.assets.some(asset => asset.sourcePath === path && asset.role === "evidence" && asset.integrity === "verified")), "World Material must resolve its three explicitly declared phone proofs through the documented family evidence base");
const disclosedPackPaths = new Set([...expectedTerrainEvidencePaths, ...expectedWritingEvidencePaths, expectedWritingReferencePath, ...expectedWorldMaterialEvidencePaths]);
const preexistingCrossFamilyPaths = expectedTerrainEvidencePaths.filter(path => data.visualAssets.families.some(family => family.id !== "terrain-region-continuity-v1" && family.assets.some(asset => asset.sourcePath === path)));
assert(disclosedPackPaths.size === 56 && preexistingCrossFamilyPaths.length === 1 && disclosedPackPaths.size - preexistingCrossFamilyPaths.length === 55, "the wiki-only closure must add links for the exact 55 previously unlinked disclosed files without crawling loose proofs");
assert(visualRecords.every(asset => !asset.sourcePath?.startsWith("AssetEvidence/") && !asset.sourcePath?.startsWith("AssetSources/")), "withheld AssetEvidence and unapproved AssetSources must remain absent from wiki records");
assert(data.search.filter(item => item.type === "visualAssetRecord").every(item => !/[0-9a-f]{64}/.test(`${item.route} ${item.name} ${item.searchText}`)), "visual record search must exclude blob/hash paths");
const rawReorderManifest = outputs => ({ outputs });
const rawReorderEntries = [
  { id: "alpha", state: "known", asset: { file: "assets/alpha.png" } },
  { id: "beta", state: "selected", asset: { file: "assets/beta.png" } }
];
const routesFromRawManifest = manifest => extractPNGReferences(manifest).map(record => visualRecordIdentity({ familyID: "reorder-probe", ...record }).route).sort();
const forwardRawRoutes = routesFromRawManifest(rawReorderManifest(rawReorderEntries));
const reversedRawRoutes = routesFromRawManifest(rawReorderManifest([...rawReorderEntries].reverse()));
assert(JSON.stringify(forwardRawRoutes) === JSON.stringify(reversedRawRoutes), "visual routes must remain invariant when the raw manifest array is reordered before extraction");
assert(forwardRawRoutes.every(route => !/outputs-\d+/.test(route)), "manifest ordinals must never become route or variant authority");
assert(visualVariant({}, ["outputs", "27"]) === "default", "an array index must not synthesize a visual variant");
assertUniqueVisualRoutes(forwardRawRoutes.map(route => ({ route, semanticKey: route })));
let collisionRejected = false;
try { assertUniqueVisualRoutes([{ route: "asset-record/a/runtime/b/default", semanticKey: "first" }, { route: "asset-record/a/runtime/b/default", semanticKey: "second" }]); } catch { collisionRejected = true; }
assert(collisionRejected, "semantic route collisions must fail instead of acquiring order suffixes");
const hiddenSentinel = {
  semanticKey: "NEVER_REVEAL_SIGIL_SENTINEL",
  context: "lookups/marks/mark/source/never-reveal-sigil-sentinel",
  sourcePath: "secret/NEVER_REVEAL_PATH.png",
  description: "NEVER_REVEAL_DESCRIPTION",
  bytes: "NEVER_REVEAL_BYTES",
  disclosed: false
};
const sentinelPartition = partitionVisualRecords([hiddenSentinel]);
assert(sentinelPartition.disclosed.length === 0 && sentinelPartition.withheldCounts["gameplay-disclosure"] === 1, "hidden visual sentinels must fail closed before emission");
const sentinelSurfaces = {
  json: sentinelPartition.disclosed.map(publicVisualRecord),
  previewURLs: sentinelPartition.disclosed.map(record => record.previewURL),
  altText: sentinelPartition.disclosed.map(record => `${record.semanticKey} · ${record.variant}`),
  search: sentinelPartition.disclosed.map(record => `${record.semanticKey} ${record.sourceRoute}`)
};
const sentinelPublicJSON = JSON.stringify(sentinelSurfaces);
for (const sentinel of [hiddenSentinel.semanticKey, hiddenSentinel.sourcePath, hiddenSentinel.description, hiddenSentinel.bytes]) assert(!sentinelPublicJSON.includes(sentinel), `hidden sentinel leaked into generated JSON, preview URLs, alt text, or search: ${sentinel}`);
const realVocabularyTileManifest = {
  lookups: {
    vocabularyTiles: {
      "tile/compound/blight/brush/known": {
        kind: "compound", id: "blight", hand: "brush", state: "known",
        asset: { file: "assets/NEVER_REVEAL_BLIGHT_BYTES.png", sha256: "NEVER_REVEAL_BLIGHT_HASH" }
      }
    }
  }
};
const realVocabularyRecords = extractPNGReferences(realVocabularyTileManifest);
assert(realVocabularyRecords.length === 1 && realVocabularyRecords[0].context.includes("lookups/vocabularyTiles/tile/compound/blight"), "disclosure test must traverse the real vocabularyTiles manifest shape");
const hiddenVocabularyPartition = partitionVisualRecords(realVocabularyRecords, new Set(["compound:blight"]));
assert(hiddenVocabularyPartition.disclosed.length === 0 && hiddenVocabularyPartition.withheldCounts["gameplay-disclosure"] === 1, "research-owned vocabulary tile must be withheld before path resolution");
const writingVisualFamily = data.visualAssets.families.find(family => family.id === "writing-desk-production-pack-v1");
const writingVisualSurfaces = JSON.stringify({
  records: writingVisualFamily.assets.map(publicVisualRecord),
  search: data.search.filter(item => item.type === "visualAssetRecord" && item.route.includes("writing-desk-production-pack-v1"))
});
assert(!/blight/i.test(writingVisualSurfaces) && !writingVisualSurfaces.includes("NEVER_REVEAL_BLIGHT"), "hidden Blight vocabulary must not reach generated records, routes, previews, alt sources, or search");
assert(appSource.includes("data-asset-query") && appSource.includes("data-asset-role") && appSource.includes("Show more"), "large visual families need record search, grouping and pagination");
assert(appSource.includes("function assetRecordDetail(") && appSource.includes("Semantic source route") && appSource.includes("Integrity metadata"), "record detail must lead with semantic identity and collapse physical integrity metadata");
assert(data.visualAssets.families.reduce((sum, family) => sum + family.runtimeMirrorPaths.length, 0) === 6, "all six RuntimePacks mirrors must remain associated with their semantic families");
for (const id of ["catalogue-consumables-placeholder-v1", "named-character-placeholders-v1"]) {
  const family = data.visualAssets.families.find(candidate => candidate.id === id);
  assert(family?.classification === "functional-placeholder" && family.blockers.length, `${id} must remain visibly blocked placeholder material`);
}
const mapSlice = data.visualAssets.families.find(family => family.id === "map-slice-v1");
assert(mapSlice?.authorityConflict?.status === "unresolved", "map-slice divergent manifests must remain a visible unresolved authority conflict");
assert(JSON.stringify(mapSlice.authorityConflict.manifests.map(manifest => manifest.outputCount).sort((left, right) => left - right)) === JSON.stringify([195, 198]), "map-slice conflict must retain its exact 195/198 output split");
assert(mapSlice.assets.length === 0 && mapSlice.withheldCounts["authority-conflict"] > 0, "conflicted map-slice records must fail closed while preserving anonymous withheld count");
assert(data.visualAssets.families.every(family => family.approvalReceipts.every(receipt => receipt.path && receipt.status)), "approval receipts must remain explicit path-backed records");
assert(data.visualAssets.families.flatMap(family => family.approvalReceipts).every(receipt => !/(unapproved|not.*approved)/i.test(receipt.status)), "candidate and unapproved receipts must never appear as approvals");
assert(data.currentTruth.writing.status === "readyToTest", "Writing must remain source-integrated and pending ordinary-phone acceptance");
assert(data.currentTruth.writing.isPrimary === false, "Writing phone acceptance must not block the active canonical terminology work");
assert(data.currentTruth.writing.acceptanceGate.includes("Install every verified phone-ready update promptly in place") && data.currentTruth.writing.acceptanceGate.includes("do not auto-launch"), "Writing must retain the corrected default phone-install/no-auto-launch authority");
assert(data.currentTruth.writing.e5ToE7Status === "not started", "Writing E5-E7 must not be silently promoted");
assert(data.currentTruth.writing.parchment.nativeSourceIntegrated === true, "accepted Writing parchment must remain hash-pinned in native source and bundle");
assert(data.currentTruth.writing.parchment.artifactIntegrationReady === false, "the standalone parchment candidate manifest must retain its own non-integration-ready receipt");
assert(data.currentTruth.writing.markArtStatus.includes("temporary") && data.currentTruth.writing.markArtStatus.includes("not accepted"), "temporary Writing mark art must not be presented as final sigil design");
assert(data.currentTruth.terrain.borderCorrection.status === "complete", "the closed Terrain border correction must remain complete");
assert(data.currentTruth.terrain.layeredPresentation.status === "readyToTest" && data.currentTruth.terrain.layeredPresentation.nativeStatus.includes("source-integrated and installed") && data.currentTruth.terrain.layeredPresentation.nativeStatus.includes("366f5ccf") && data.currentTruth.terrain.layeredPresentation.nativeStatus.includes("integrationReady:false") && data.currentTruth.terrain.layeredPresentation.nativeStatus.includes("fail-safe"), "layered Terrain must report installed native truth, pending visual acceptance and retained fallback");
assert(data.currentTruth.terrain.atmosphere.status === "queued" && data.currentTruth.terrain.atmosphere.nativeStatus.includes("native integration is queued"), "accepted Atmosphere candidate must not be claimed native");
assert(data.currentTruth.writing.provenance.sourcePaths.every(path => data.currentTruth.writing.provenance.sourceHashes[path]), "Writing current-truth provenance must hash every registered source");
assert(data.currentTruth.terrain.provenance.sourcePaths.every(path => data.currentTruth.terrain.provenance.sourceHashes[path]), "Terrain current-truth provenance must hash every registered source");
for (const item of data.search) {
  assert(item.provenance.generatedAtSourceHash === data.generatedAtSourceHash, `fact hash missing: ${item.type}/${item.id}`);
  assert(item.provenance.sourcePaths.length, `fact source missing: ${item.type}/${item.id}`);
}
for (const route of ["overview", "core-loop", "world-writing", "exploration", "combat", "people", "terminology", "village-buildings", "resources-crafting", "catalogue", "catalogue/gear", "catalogue/consumables", "catalogue/curios", "catalogue/treasures", "catalogue/keys", "roadmap", "history", "asset-gallery"]) {
  assert(data.routes.includes(route), `required route missing: ${route}`);
}
assert(!appSource.includes("function authorityPage") && !appSource.includes("authorityPage("), "required routes must not retain the generic authority fallback");
for (const renderer of ["worldWriting", "coreLoop", "exploration", "combat", "roadmapDetail", "lexemeDetail"]) {
  assert(appSource.includes(`function ${renderer}(`), `missing dedicated renderer: ${renderer}`);
}
const { resetRouteScroll } = await import("../public/route-scroll.js");
const scrollCalls = [];
resetRouteScroll({ scrollTo: options => scrollCalls.push(["window", options]) }, { scrollTo: options => scrollCalls.push(["content", options]) });
assert(scrollCalls.length === 2 && scrollCalls.every(([, options]) => options.top === 0 && options.left === 0 && options.behavior === "instant"), "phone route transitions must reset window and content scroll to the route top");
console.log(`Wiki tests passed: ${data.routes.length} routes, ${data.search.length} searchable facts, ${data.stations.length} station pages.`);
