import { createHash } from "node:crypto";
import { mkdir, readFile, readdir, writeFile } from "node:fs/promises";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const wikiRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = resolve(wikiRoot, "..");
const outDir = join(wikiRoot, "generated");

const coreInputs = [
  "Sources/Content/Data/stations.json",
  "Sources/Content/Data/travellers.json",
  "Sources/Content/Data/resources.json",
  "Sources/Content/Data/items.json",
  "Sources/Content/Data/symbols.json",
  "Sources/Content/Data/playability-roadmap.json",
  "docs/current-design-index.md",
  "docs/station-integration-matrix-current.md",
  "docs/home-house-and-village-current.md",
  "GameWiki/config/station-authority-map.json"
];

const sha = value => createHash("sha256").update(value).digest("hex");
const read = path => readFile(join(repoRoot, path), "utf8");
const readJSON = async path => JSON.parse(await read(path));
const stable = value => JSON.stringify(value, null, 2) + "\n";
const slug = value => String(value).toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

async function walk(path) {
  const absolute = join(repoRoot, path);
  const entries = await readdir(absolute, { withFileTypes: true });
  const results = [];
  for (const entry of entries) {
    const child = join(path, entry.name);
    if (entry.isDirectory()) results.push(...await walk(child));
    else results.push(child);
  }
  return results;
}

function titleOf(markdown, fallback) {
  return markdown.match(/^#\s+(.+)$/m)?.[1]?.trim() ?? fallback;
}

function statusOf(markdown) {
  return markdown.match(/^\*\*Status:\*\*\s*(.+)$/m)?.[1]?.trim() ?? "unlabelled";
}

function linkedCurrentAuthorities(index) {
  return [...index.matchAll(/`([^`]*-current\.md)`/g)]
    .map(match => `docs/${match[1]}`)
    .filter((value, index, all) => all.indexOf(value) === index)
    .sort();
}

function provenance(sourcePaths, stableID, disposition, hashes, aggregateHash) {
  return {
    sourcePaths,
    stableID: stableID ?? null,
    disposition,
    generatedAtSourceHash: aggregateHash,
    sourceHashes: Object.fromEntries(sourcePaths.map(path => [path, hashes[path]]).filter(([, hash]) => hash))
  };
}

function costParts(cost) {
  if (!cost) return [];
  return [
    ...(cost.essence ? [{ id: "essence", quantity: cost.essence }] : []),
    ...Object.entries(cost.resources ?? {}).map(([id, quantity]) => ({ id, quantity }))
  ];
}

function stationLifecycle(station) {
  if (station.id === "library") return "existing room, later keeper";
  if (station.id === "firepit") return "opening infrastructure, later upgrade";
  if (station.builtBy) return "found then built";
  return "opening infrastructure";
}

const indexText = await read("docs/current-design-index.md");
const linkedAuthorities = linkedCurrentAuthorities(indexText);
const allDocs = await walk("docs");
const historyPaths = allDocs
  .filter(path => /(^docs\/archive\/|^docs\/decisions-session-)/.test(path) && path.endsWith(".md"))
  .sort();
const authorityPaths = [...new Set([
  "docs/current-design-index.md",
  "docs/station-integration-matrix-current.md",
  "docs/home-house-and-village-current.md",
  ...linkedAuthorities
])].sort();
const allInputs = [...new Set([...coreInputs, ...authorityPaths, ...historyPaths])].sort();

const contents = {};
const hashes = {};
for (const path of allInputs) {
  contents[path] = await read(path);
  hashes[path] = sha(contents[path]);
}
const aggregateHash = sha(allInputs.map(path => `${path}\0${hashes[path]}`).join("\n"));

const stationsJSON = JSON.parse(contents["Sources/Content/Data/stations.json"]);
const travellersJSON = JSON.parse(contents["Sources/Content/Data/travellers.json"]);
const resourcesJSON = JSON.parse(contents["Sources/Content/Data/resources.json"]);
const itemsJSON = JSON.parse(contents["Sources/Content/Data/items.json"]);
const symbolsJSON = JSON.parse(contents["Sources/Content/Data/symbols.json"]);
const roadmapJSON = JSON.parse(contents["Sources/Content/Data/playability-roadmap.json"]);
const stationMap = JSON.parse(contents["GameWiki/config/station-authority-map.json"]);

const travellersByID = Object.fromEntries(travellersJSON.travellers.map(item => [item.id, item]));
const stationSources = stationMap.sources;
const stations = stationsJSON.stations.map(station => {
  const keeperID = stationMap.keepers[station.id] ?? station.builtBy ?? null;
  const keeper = keeperID ? travellersByID[keeperID]?.name ?? keeperID : null;
  const disposition = stationMap.dispositions[station.id] ?? stationsJSON._authority.defaultDisposition;
  const zoneAuthority = stationMap.zones[station.id] ?? null;
  const upgradeAuthority = stationMap.upgradeAuthority[station.id] ?? { status: "unaudited", sourcePaths: [] };
  return {
    type: "station",
    id: station.id,
    slug: slug(station.id),
    name: station.name,
    blurb: station.blurb,
    route: station.route,
    destinationKind: stationMap.destinationKinds[station.id],
    zone: zoneAuthority?.label ?? "District not yet assigned",
    zoneDisposition: zoneAuthority ? disposition : "provisional",
    zoneSourcePaths: zoneAuthority?.sourcePaths ?? [],
    lifecycle: stationLifecycle(station),
    keeper,
    keeperID,
    unlockedAtStart: station.unlockedAtStart,
    startingTier: station.startingTier,
    catalogueMaxTier: station.maxTier,
    buildCost: costParts(station.buildCost),
    buildBlurb: station.buildBlurb ?? null,
    disposition,
    upgradeAuthorityStatus: upgradeAuthority.status,
    upgradeAuthoritySourcePaths: upgradeAuthority.sourcePaths,
    upgradeNote: upgradeAuthority.status === "unaudited" ? "Upgrade track not yet mapped in wiki." : upgradeAuthority.status === "partial" ? "A named current authority describes part of this track; the wiki does not claim a complete upgrade model." : upgradeAuthority.status === "none" ? "No upgrade track applies under the named current authority." : "A named current authority describes this upgrade track.",
    sprites: { built: null, improved: null },
    provenance: provenance(stationSources, station.id, disposition, hashes, aggregateHash)
  };
});

function normalize(collection, type, sourcePath, disposition) {
  return collection.map(item => ({
    type,
    id: item.id,
    slug: slug(item.id),
    name: item.name ?? item.title ?? item.id,
    summary: item.blurb ?? item.calling ?? item.detail ?? "",
    status: item.status ?? disposition,
    disposition: item.status ?? disposition,
    provenance: provenance([sourcePath], item.id, item.status ?? disposition, hashes, aggregateHash)
  }));
}

const travellers = normalize(travellersJSON.travellers, "traveller", "Sources/Content/Data/travellers.json", travellersJSON._authority.defaultDisposition);
const resources = normalize(resourcesJSON.resources, "resource", "Sources/Content/Data/resources.json", resourcesJSON._authority.defaultDisposition);
const items = normalize(itemsJSON.items, "item", "Sources/Content/Data/items.json", itemsJSON._authority.defaultDisposition);
const symbols = normalize(symbolsJSON.symbols, "rune", "Sources/Content/Data/symbols.json", symbolsJSON._authority.defaultDisposition);
const roadmap = normalize(roadmapJSON.items, "roadmap", "Sources/Content/Data/playability-roadmap.json", "operational");
for (const [index, item] of roadmap.entries()) roadmap[index].workstream = roadmapJSON.items[index].workstream;

const authorities = await Promise.all(authorityPaths.map(async path => ({
  path,
  title: titleOf(contents[path], path.split("/").at(-1)),
  status: statusOf(contents[path]),
  hash: hashes[path],
  current: path.endsWith("-current.md") || path === "docs/current-design-index.md",
  provenance: provenance([path], null, statusOf(contents[path]), hashes, aggregateHash)
})));
const history = historyPaths.map(path => ({
  path,
  title: titleOf(contents[path], path.split("/").at(-1)),
  hash: hashes[path],
  disposition: "history",
  provenance: provenance([path], null, "history", hashes, aggregateHash)
}));

const routes = [
  "overview", "core-loop", "world-writing", "exploration", "combat", "people",
  "village-buildings", "resources-crafting", "items", "roadmap", "history", "asset-gallery",
  ...stations.map(station => `station/${station.slug}`)
];
const search = [...stations, ...travellers, ...resources, ...items, ...symbols, ...roadmap].map(entity => ({
  type: entity.type,
  id: entity.id,
  name: entity.name,
  summary: entity.blurb ?? entity.summary ?? "",
  route: entity.type === "station" ? `station/${entity.slug}` : entity.type === "roadmap" ? "roadmap" : entity.type === "traveller" ? "people" : entity.type === "item" ? "items" : entity.type === "resource" ? "resources-crafting" : entity.type === "rune" ? "world-writing" : "overview",
  disposition: entity.disposition,
  provenance: entity.provenance
}));

const wikiData = {
  schemaVersion: 1,
  generatedAtSourceHash: aggregateHash,
  routes,
  counts: { stations: stations.length, travellers: travellers.length, resources: resources.length, items: items.length, runes: symbols.length, roadmap: roadmap.length },
  stations, travellers, resources, items, symbols, roadmap, authorities, history, search,
  assetGallery: {
    acceptedAssets: [],
    reviewEvidence: [],
    note: "No committed asset has been registered for this wiki slice. Rejected or uncommitted House/Library work is intentionally absent."
  }
};
const manifest = {
  schemaVersion: 1,
  aggregateSourceHash: aggregateHash,
  inputs: Object.fromEntries(allInputs.map(path => [path, hashes[path]])),
  outputs: {}
};

await mkdir(outDir, { recursive: true });
const dataText = stable(wikiData);
const registryText = stable({ schemaVersion: 1, generatedAtSourceHash: aggregateHash, current: authorities, history });
manifest.outputs["generated/wiki-data.json"] = sha(dataText);
manifest.outputs["generated/source-registry.json"] = sha(registryText);
const manifestText = stable(manifest);
await writeFile(join(outDir, "wiki-data.json"), dataText);
await writeFile(join(outDir, "source-registry.json"), registryText);
await writeFile(join(outDir, "manifest.json"), manifestText);

console.log(`Generated ${stations.length} stations and ${search.length} searchable facts from ${allInputs.length} authoritative inputs.`);
