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
  "docs/asset-system-proposal.md",
  "docs/current-design-index.md",
  "docs/station-integration-matrix-current.md",
  "docs/home-house-and-village-current.md",
  "docs/home-village-library-asset-packet-current.md",
  "docs/village-progression-and-asset-matrix-current.md"
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

const cleanMarkdown = value => String(value).replace(/\*\*/g, "").replace(/`/g, "").trim();

function markdownTableAfter(markdown, heading) {
  const start = markdown.indexOf(heading);
  if (start < 0) throw new Error(`Missing matrix heading: ${heading}`);
  const lines = markdown.slice(start + heading.length).split("\n");
  const rows = [];
  let inTable = false;
  for (const line of lines) {
    if (!line.startsWith("|")) {
      if (inTable) break;
      continue;
    }
    inTable = true;
    const cells = line.split("|").slice(1, -1).map(cleanMarkdown);
    if (cells.every(cell => /^-+$/.test(cell)) || cells[0] === "Stable ID" || cells[0] === "Stable purchase ID" || cells[0] === "Destination" || cells[0] === "Form") continue;
    rows.push(cells);
  }
  return rows;
}

function destinationKind(raw) {
  const normalized = raw.toLowerCase().replace(/[–—]/g, "-").trim();
  const kinds = {
    "village building": "villageBuilding",
    "house room": "houseRoom",
    "house interface": "houseInterface",
    "house-yard feature": "houseYardFeature",
    "library shelf": "libraryShelf",
    "progression surface": "progressionSurface",
    "removed compatibility": "removedCompatibility"
  };
  if (!kinds[normalized]) throw new Error(`Unknown canonical destination kind: ${raw}`);
  return kinds[normalized];
}

function parseCanonicalDestinations(markdown) {
  return markdownTableAfter(markdown, "### Canonical destination register").map(([stableID, playerName, kind, exactPlace, keeperAuthority]) => ({
    id: stableID,
    playerName,
    destinationKind: destinationKind(kind),
    exactPlace,
    keeperAuthority
  }));
}

function parseBuildingForms(markdown, destination) {
  const sections = [...markdown.matchAll(/^####\s+(.+)$/gm)].map((match, index, all) => ({
    heading: cleanMarkdown(match[1]),
    body: markdown.slice(match.index + match[0].length, all[index + 1]?.index ?? markdown.length)
  }));
  const candidateNames = [destination.playerName.split("/")[0].trim(), destination.playerName.split("→")[0].trim()];
  const section = sections.find(item => candidateNames.some(name => item.heading.toLowerCase().startsWith(name.toLowerCase())));
  if (!section) throw new Error(`Missing building form section for ${destination.id}`);
  const purpose = cleanMarkdown(section.body.match(/^\*\*Purpose:\*\*\s*([\s\S]*?)(?=\n\n\| Form)/m)?.[1] ?? "").replace(/\s+/g, " ");
  const forms = markdownTableAfter(section.body, "| Form | Player capability | Required physical change |").map(([form, capability, visualReferent]) => {
    const match = form.match(/^(Built|Improved|Mastered) · Tier ([012])(?: — (.+))?$/);
    if (!match) throw new Error(`Invalid form row for ${destination.id}: ${form}`);
    const explicitTuning = /\b(recommended|tuning)\b/i.test(capability);
    return {
      state: match[1].toLowerCase(),
      tier: Number(match[2]),
      name: cleanMarkdown(match[3] ?? match[1]),
      capability: cleanMarkdown(capability),
      visualReferent: cleanMarkdown(visualReferent),
      authorityLabels: explicitTuning ? ["authored", "playtest tuning"] : ["authored"]
    };
  });
  if (forms.length !== 3) throw new Error(`Expected three forms for ${destination.id}; found ${forms.length}`);
  return { purpose, forms };
}

function parseVisualKeys(markdown) {
  return Object.fromEntries(markdownTableAfter(markdown, "### Per-building visual key").map(([stableID, foundation, builtKey, materials, protectedFeatures, exclusions]) => [stableID, {
    foundation, builtKey, materials, protectedFeatures, exclusions
  }]));
}

function parseNonBuildingProgression(markdown) {
  return Object.fromEntries(markdownTableAfter(markdown, "## 4. Non-building destination progression").map(([name, authority]) => [name.toLowerCase(), authority]));
}

function parseConstellationProposal(markdown) {
  const permissions = Object.fromEntries(markdownTableAfter(markdown, "### Recommended Constellation shape").map(([cluster, name, cost, permission]) => [name, { cluster, cost, permission }]));
  return markdownTableAfter(markdown, "### Stable purchase contract and graph layout").map(([id, name, blocker]) => ({
    id,
    name,
    blocker,
    cluster: permissions[name]?.cluster ?? "Centre",
    cost: permissions[name]?.cost ?? "current authored cost",
    permission: permissions[name]?.permission ?? "+1 Gambit rule capacity; not part of either trio",
    status: id === "existing stable ID" ? "implemented" : "proposed / review-gated"
  }));
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
  "docs/village-progression-and-asset-matrix-current.md",
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
const matrixPath = "docs/village-progression-and-asset-matrix-current.md";
const matrixText = contents[matrixPath];
const destinationRegister = parseCanonicalDestinations(matrixText);
const destinationsByID = Object.fromEntries(destinationRegister.map(destination => [destination.id, destination]));
const visualKeysByID = parseVisualKeys(matrixText);
const nonBuildingProgression = parseNonBuildingProgression(matrixText);
const constellationProposal = parseConstellationProposal(matrixText);
const assetProposalText = contents["docs/asset-system-proposal.md"];
const tradingPostCandidateRejected = /Trading Post Tier-0 v0\.1 disposition[\s\S]{0,300}Rejected as the production pixel gate/i.test(assetProposalText);
const tradingPostCandidateAccepted = /Trading Post Tier-0 v0\.3 disposition[\s\S]{0,300}Accepted as the production visual style gate/i.test(assetProposalText);

const travellersByID = Object.fromEntries(travellersJSON.travellers.map(item => [item.id, item]));
const catalogueIDs = stationsJSON.stations.map(station => station.id).sort();
const registerIDs = destinationRegister.map(destination => destination.id).sort();
if (JSON.stringify(catalogueIDs) !== JSON.stringify(registerIDs)) throw new Error("Canonical destination register does not exactly cover stations.json");
const villageBuildingIDs = destinationRegister.filter(destination => destination.destinationKind === "villageBuilding").map(destination => destination.id).sort();
if (villageBuildingIDs.length !== 17) throw new Error(`Expected 17 canonical village buildings; found ${villageBuildingIDs.length}`);
if (JSON.stringify(villageBuildingIDs) !== JSON.stringify(Object.keys(visualKeysByID).sort())) throw new Error("Per-building visual-key table does not exactly cover the 17 village buildings");

const stationSources = ["Sources/Content/Data/stations.json", matrixPath, "docs/station-integration-matrix-current.md", "docs/home-house-and-village-current.md"];
const stations = stationsJSON.stations.map(station => {
  const destination = destinationsByID[station.id];
  const keeperID = station.builtBy ?? null;
  const keeper = keeperID ? travellersByID[keeperID]?.name ?? keeperID : null;
  const disposition = destination.destinationKind === "removedCompatibility" ? "removed" : /review-gated/i.test(destination.keeperAuthority) ? "provisional" : stationsJSON._authority.defaultDisposition;
  const buildingAuthority = destination.destinationKind === "villageBuilding" ? parseBuildingForms(matrixText, destination) : null;
  const progressionNote = nonBuildingProgression[destination.playerName.toLowerCase()] ?? null;
  const upgradeAuthorityStatus = buildingAuthority ? "authored" : destination.destinationKind === "progressionSurface" ? "partial" : "none";
  return {
    type: "station",
    id: station.id,
    slug: slug(station.id),
    name: station.name,
    blurb: station.blurb,
    route: station.route,
    destinationKind: destination.destinationKind,
    zone: destination.exactPlace,
    zoneDisposition: disposition,
    zoneSourcePaths: [matrixPath],
    lifecycle: stationLifecycle(station),
    keeper,
    keeperID,
    keeperAuthority: destination.keeperAuthority,
    unlockedAtStart: station.unlockedAtStart,
    startingTier: station.startingTier,
    catalogueMaxTier: station.maxTier,
    buildCost: costParts(station.buildCost),
    buildBlurb: station.buildBlurb ?? null,
    disposition,
    upgradeAuthorityStatus,
    upgradeAuthoritySourcePaths: upgradeAuthorityStatus === "none" ? [matrixPath] : [matrixPath, ...(destination.destinationKind === "progressionSurface" ? ["docs/workshop-constellation-role-audit-current.md"] : [])],
    upgradeNote: buildingAuthority ? "Canonical Built, Improved and Mastered forms are authored in the village matrix; explicitly marked numbers remain playtest tuning." : destination.destinationKind === "progressionSurface" ? "The proposed 3+3 mastery-star expansion is review-gated and not implemented; preserve the current route meanwhile." : "No village-building upgrade track applies to this destination kind.",
    progressionNote,
    purpose: buildingAuthority?.purpose ?? null,
    forms: buildingAuthority?.forms ?? [],
    visualKey: visualKeysByID[station.id] ?? null,
    constellationProposal: station.id === "constellation" ? constellationProposal : [],
    assetSlots: buildingAuthority ? ["foundation", "built", "improved", "mastered", "attention"].map(state => ({
      key: `${station.id}.${state}`,
      state,
      status: station.id === "trading_post" && state === "built" && tradingPostCandidateAccepted
        ? "Game Design accepted candidate / native integration not yet accepted"
        : station.id === "trading_post" && state === "built" && tradingPostCandidateRejected
          ? "candidate rejected / no accepted built sprite"
          : "reserved",
      assetPath: null
    })) : [],
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
    slots: stations.filter(station => station.destinationKind === "villageBuilding").flatMap(station => station.assetSlots),
    note: "No accepted building pixels are registered. Rejected and uncommitted candidates are not displayed; stable building/state slots remain reserved for reviewed assets."
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
