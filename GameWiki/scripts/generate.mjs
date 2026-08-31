import { createHash } from "node:crypto";
import { mkdir, readFile, readdir, writeFile } from "node:fs/promises";
import { basename, dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { assertUniqueVisualRoutes, partitionVisualRecords, visualRecordIdentity, visualVariant } from "./visual-assets.mjs";

const wikiRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = resolve(wikiRoot, "..");
const outDir = join(wikiRoot, "generated");

const coreInputs = [
  "Sources/Content/Data/stations.json",
  "Sources/Content/Data/travellers.json",
  "Sources/Content/Data/resources.json",
  "Sources/Content/Data/items.json",
  "Sources/Content/Data/symbols.json",
  "Sources/Content/Data/pressure_targets.json",
  "Sources/Content/Data/pressure_sources.json",
  "Sources/Content/Data/qualifiers.json",
  "Sources/Content/Data/playability-roadmap.json",
  "docs/canonical-game-terminology.json",
  "Sources/Model/Materials.swift",
  "Sources/Screens/PageGridView.swift",
  "Sources/Screens/WritingDeskView.swift",
  "Sources/VisualRuntime/WritingDeskProductionPack.swift",
  "Sources/VisualAdapters/NamedCharacterVisualAdapter.swift",
  "Bookbinder.xcodeproj/project.pbxproj",
  "AssetLab/artifacts/writing-parchment-v1/manifest.json",
  "docs/authored-text-audit-current.md",
  "docs/diary-teaching-registry-implementation-audit-current.md",
  "docs/roster-progression-current.md",
  "docs/crafting-components-and-schematics-current.md",
  "docs/asset-system-proposal.md",
  "docs/current-design-index.md",
  "docs/station-integration-matrix-current.md",
  "docs/home-house-and-village-current.md",
  "docs/home-village-library-asset-packet-current.md",
  "docs/creature-ecology-and-materials-overhaul-current.md",
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

const unique = values => [...new Set(values)].sort();

function familyIDFromManifestPath(path) {
  const parts = path.split("/");
  const rootIndex = parts.findIndex(part => part === "artifacts" || part === "integration");
  if (rootIndex >= 0 && parts[rootIndex + 1]) return parts[rootIndex + 1];
  const runtimeIndex = parts.indexOf("RuntimePacks");
  if (runtimeIndex >= 0 && parts[runtimeIndex + 1]) return parts[runtimeIndex + 1];
  return basename(dirname(path));
}

function pngReferences(value, trail = [], records = [], inheritedDisclosed = true, inheritedSemanticIdentity = null) {
  if (Array.isArray(value)) {
    value.forEach((item, index) => pngReferences(item, [...trail, String(index)], records, inheritedDisclosed, inheritedSemanticIdentity));
    return records;
  }
  if (!value || typeof value !== "object") return records;

  const explicitlyHidden = value.identified === false || value.hidden === true || value.disclosed === false
    || value.visibility === "hidden" || value.disclosure === false || value.disclosure === "hidden";
  const disclosed = inheritedDisclosed && !explicitlyHidden;
  const ownSemanticIdentity = value.stableKey ?? value.key ?? value.id ?? inheritedSemanticIdentity;

  const pathCandidates = [
    [value.path, null],
    [value.file, null],
    [value.assetPath, null],
    [value.sourcePath, "source"],
    [value.referencePath, "reference"],
    [value.evidencePath, "evidence"]
  ].filter(([candidate]) => typeof candidate === "string" && /\.png$/i.test(candidate));
  for (const [rawPath, forcedRole] of new Map(pathCandidates.map(candidate => [`${candidate[0]}\0${candidate[1]}`, candidate])).values()) {
    const assetsByKeyIndex = trail.indexOf("assetsByKey");
    const inferredSemanticKey = trail.filter(part => !/^\d+$/.test(part)).join("/");
    const fileSemanticKey = basename(rawPath, ".png");
    const explicitSemanticKey = value.stableKey ?? value.key ?? value.id ?? (assetsByKeyIndex >= 0 ? trail[assetsByKeyIndex + 1] : null) ?? inheritedSemanticIdentity;
    const semanticKey = explicitSemanticKey != null
      ? (inferredSemanticKey && !inferredSemanticKey.endsWith(String(explicitSemanticKey)) ? `${inferredSemanticKey}/${explicitSemanticKey}` : explicitSemanticKey)
      : (/^\d+$/.test(trail.at(-1) ?? "") && !/^[0-9a-f]{32,}$/i.test(fileSemanticKey) ? fileSemanticKey : inferredSemanticKey || "opaque-asset");
    const context = trail.join("/").toLowerCase();
    const contextTokens = trail.map(token => String(token).toLowerCase());
    const role = forcedRole ?? (contextTokens.some(token => /^(source-?references?|references?)$/.test(token)) ? "reference"
      : contextTokens.some(token => /^(evidence|proofs?|contact-?sheets?|review-?evidence)$/.test(token)) ? "evidence"
      : /^(source|sources|editable-?sources?)$/.test(contextTokens[0] ?? "") ? "source"
      : "runtime");
    records.push({
      semanticKey: String(semanticKey),
      rawPath,
      role,
      variant: visualVariant(value, trail),
      disclosed,
      integrityIndexOnly: /^(assets|files|images|pngs)\/\d+$/i.test(trail.join("/")) && explicitSemanticKey == null,
      context: trail.join("/"),
      declaredSHA256: forcedRole === "source"
        ? value.sourceSHA256 ?? value.sourceFileSHA256 ?? null
        : value.fileSHA256 ?? value.sha256 ?? value.pngSHA256 ?? null,
      decodedRGBASHA256: value.decodedRGBASHA256 ?? value.rgbaSHA256 ?? value.pixelSHA256 ?? null,
      width: value.width ?? value.pixelWidth ?? null,
      height: value.height ?? value.pixelHeight ?? null
    });
  }
  for (const [key, child] of Object.entries(value)) pngReferences(child, [...trail, key], records, disclosed, ownSemanticIdentity);
  return records;
}

const packPNGCache = new Map();

async function packPNGPaths(manifestPath) {
  const manifestDirectory = dirname(manifestPath);
  const packDirectory = manifestDirectory.endsWith("/runtime") ? dirname(manifestDirectory) : manifestDirectory;
  if (!packPNGCache.has(packDirectory)) {
    packPNGCache.set(packDirectory, (await walk(packDirectory)).filter(path => /\.png$/i.test(path)).sort());
  }
  return packPNGCache.get(packDirectory);
}

async function resolveAssetPath(manifestPath, rawPath, context = "") {
  const normalized = rawPath.replaceAll("\\", "/");
  const manifestDirectory = dirname(manifestPath);
  const candidates = normalized.startsWith("AssetLab/") || normalized.startsWith("RuntimePacks/")
    ? [normalized]
    : unique([
        join(manifestDirectory, normalized),
        manifestDirectory.endsWith("/runtime") ? join(dirname(manifestDirectory), normalized) : null,
        normalized
      ].filter(Boolean).map(candidate => candidate.replaceAll("\\", "/")));
  for (const candidate of candidates) {
    try {
      await readFile(join(repoRoot, candidate));
      return candidate;
    } catch {}
  }
  const packPNGs = await packPNGPaths(manifestPath);
  const profileDirectory = context.startsWith("profiles/mobDropInventory/") ? "mob-drops"
    : context.startsWith("profiles/gearInventory/") ? "gear-families"
    : context.startsWith("profiles/catalogueGear/") ? "catalogue-gear"
    : null;
  if (profileDirectory) {
    const profileMatch = packPNGs.find(path => path.endsWith(`/${profileDirectory}/${normalized}`));
    if (profileMatch) return profileMatch;
  }
  const suffixMatches = packPNGs.filter(path => path.endsWith(`/${normalized}`));
  if (suffixMatches.length === 1) return suffixMatches[0];
  const basenameMatches = packPNGs.filter(path => basename(path) === basename(normalized));
  if (basenameMatches.length === 1) return basenameMatches[0];
  return null;
}

function visualClassification(path, manifests) {
  const statuses = manifests.map(manifest => String(manifest.status ?? manifest.evidenceRole ?? "")).join(" ").toLowerCase();
  if (manifests.some(manifest => manifest.evidenceRole === "functionalPlaceholderConformancePack" || manifest.finalArt === false)) return "functional-placeholder";
  if (/frozen/.test(statuses)) return "frozen-legacy";
  if (path.startsWith("AssetLab/artifacts/")) return "review-only";
  if (/candidate|unapproved|visual-review/.test(statuses) || manifests.some(manifest => manifest.integrationReady === false)) return "candidate";
  if (manifests.some(manifest => manifest.integrationReady === true)) return "runtime-integrated";
  return "unresolved";
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
const assetLabManifestPaths = unique([
  ...(await walk("AssetLab/artifacts")).filter(path => /\/manifest(?: \d+)?\.json$/.test(path)),
  ...(await walk("AssetLab/integration")).filter(path => /\/manifest(?: \d+)?\.json$/.test(path))
]);
const runtimePackManifestPaths = (await walk("RuntimePacks")).filter(path => /\/manifest\.json$/.test(path)).sort();
const assetReceiptPaths = unique([
  ...(await walk("AssetLab/artifacts")).filter(path => /\/(?:promotion|review|source|deterministic)-receipt\.json$/.test(path)),
  ...(await walk("AssetLab/integration")).filter(path => /\/(?:promotion|review|source|deterministic)-receipt\.json$/.test(path))
]);
const visualAuthorityPaths = unique([...assetLabManifestPaths, ...runtimePackManifestPaths, ...assetReceiptPaths]);
const allInputs = unique([...coreInputs, ...authorityPaths, ...historyPaths, ...visualAuthorityPaths]);

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
const targetsJSON = JSON.parse(contents["Sources/Content/Data/pressure_targets.json"]);
const sourcesJSON = JSON.parse(contents["Sources/Content/Data/pressure_sources.json"]);
const qualifiersJSON = JSON.parse(contents["Sources/Content/Data/qualifiers.json"]);
const roadmapJSON = JSON.parse(contents["Sources/Content/Data/playability-roadmap.json"]);
const terminologyAuthority = JSON.parse(contents["docs/canonical-game-terminology.json"]);
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
const openingIdentitySetAccepted = /Opening Built\/Tier-0 identity set v0\.1 disposition[\s\S]{0,300}Accepted by Game Design/i.test(assetProposalText);
const openingStateContinuityAccepted = /Opening state-continuity v0\.1 disposition[\s\S]{0,300}Accepted by Game Design/i.test(assetProposalText);
const binderHouseCandidateAccepted = /Binder House v0\.1 disposition[\s\S]{0,300}Accepted by Game Design/i.test(assetProposalText);
const acceptedBuiltCandidateIDs = new Set([
  ...(tradingPostCandidateAccepted ? ["trading_post"] : []),
  ...(openingIdentitySetAccepted ? ["recycler", "blacksmith", "storehouse", "firepit"] : [])
]);
const acceptedStateCandidateKeys = new Set(openingStateContinuityAccepted ? [
  "trading_post.foundation", "trading_post.improved", "trading_post.mastered", "trading_post.attention",
  "firepit.foundation", "firepit.improved", "firepit.mastered", "firepit.attention"
] : []);
const binderHouseRootSlot = binderHouseCandidateAccepted ? [{
  key: "binder_house.root",
  state: "root",
  status: "Game Design accepted candidate / native integration not yet accepted",
  assetPath: null
}] : [];

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
      status: (state === "built" && acceptedBuiltCandidateIDs.has(station.id)) || acceptedStateCandidateKeys.has(`${station.id}.${state}`)
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

const pressureNames = {
  atmosphere: "Atmosphere", cycle: "World cycle", hydrology: "Hydrology",
  illumination: "Illumination", relief: "Relief", substrate: "Substrate",
  thermal: "Thermal", vitality: "Growth"
};

function titleWords(value) {
  return String(value).replace(/[-_]/g, " ").replace(/\b\w/g, letter => letter.toUpperCase());
}

function resourceConditionSubject(condition) {
  const exact = {
    "thermal|tag|geothermal": "Geothermal heat",
    "hydrology|tag|brine": "Briny water",
    "atmosphere|tag|toxic": "Toxic air",
    "substrate|tag|unstable-ground": "Unstable ground",
    "illumination|tag|sourceless": "Sourceless light",
    "hydrology|aspect|salinity": "Water salinity",
    "cycle|tag|arrhythmic": "Irregular World cycle"
  }[`${condition.target}|${condition.measure}|${condition.key ?? ""}`];
  if (exact) return exact;
  const target = pressureNames[condition.target] ?? titleWords(condition.target);
  if (condition.measure === "peak") return `${target} pressure`;
  if (condition.measure === "form") return `${titleWords(condition.key)} ${target}`;
  if (condition.measure === "tag") return `${titleWords(condition.key)} ${target}`;
  if (condition.measure === "aspect") return condition.target === "atmosphere"
    ? `Atmospheric ${condition.key}`
    : `${target} ${titleWords(condition.key).toLowerCase().replace("trophicdepth", "trophic depth")}`;
  if (condition.measure === "available") return condition.target === "hydrology" ? "Available water" : `Available ${target}`;
  if (condition.measure === "produced") return `${target} production`;
  throw new Error(`Unsupported resource condition measure: ${condition.measure}`);
}

function resourceConditionText(condition, relationship) {
  const subject = resourceConditionSubject(condition);
  if (condition.measure === "tag" && condition.minimum === 1 && condition.maximum == null) {
    return relationship === "requires" ? `${subject} must be present.` : `${subject} helps when present.`;
  }
  const minimum = condition.minimum;
  const maximum = condition.maximum;
  if (minimum != null && maximum != null) {
    return relationship === "requires"
      ? `${subject} must stay between ${minimum}/100 and ${maximum}/100.`
      : `${subject} helps between ${minimum}/100 and ${maximum}/100.`;
  }
  if (minimum != null) {
    return relationship === "requires"
      ? `${subject} must reach at least ${minimum}/100.`
      : `${subject} helps at ${minimum}/100 or more.`;
  }
  if (maximum != null) {
    return relationship === "requires"
      ? `${subject} must stay at ${maximum}/100 or less.`
      : `${subject} helps at ${maximum}/100 or less.`;
  }
  throw new Error(`Resource condition has no supported bound: ${JSON.stringify(condition)}`);
}

function itemRecord(item) {
  const sourcePath = "Sources/Content/Data/items.json";
  return {
    type: item.kind,
    category: item.kind,
    id: item.id,
    slug: slug(item.id),
    name: item.name,
    summary: item.blurb,
    rarity: item.rarity,
    icon: item.icon,
    gear: item.gear ?? null,
    consumable: item.consumable ?? null,
    tradingPostDisposition: item.tradingPostDisposition,
    recyclerDisposition: item.recyclerDisposition,
    disposition: itemsJSON._authority.defaultDisposition,
    provenance: provenance([sourcePath], item.id, itemsJSON._authority.defaultDisposition, hashes, aggregateHash)
  };
}

const constructionUses = Object.fromEntries(resourcesJSON.resources.map(resource => [resource.id, []]));
for (const station of stationsJSON.stations) {
  for (const id of Object.keys(station.buildCost?.resources ?? {})) {
    if (constructionUses[id]) {
      const sentenceName = /^The\s/.test(station.name)
        ? `the ${station.name.slice(4)}`
        : `the ${station.name}`;
      constructionUses[id].push(`Used to construct ${sentenceName}.`);
    }
  }
}

function resourceRecord(resource) {
  const sourcePath = "Sources/Content/Data/resources.json";
  const domain = resource.isRealityCurrency || ["essence_raw", "mote"].includes(resource.id)
    ? "currencyEssence" : "worldResource";
  const requires = (resource.requires ?? []).map(condition => resourceConditionText(condition, "requires"));
  const favours = (resource.favours ?? []).map(condition => resourceConditionText(condition, "favours"));
  const drivenBy = pressureNames[resource.drivenBy] ?? titleWords(resource.drivenBy);
  const pressure = `Mostly shaped by ${drivenBy} pressure.`;
  const uses = constructionUses[resource.id]?.length ? constructionUses[resource.id] : ["No current Village construction recipe uses this resource."];
  return {
    type: "resource",
    category: domain,
    domain: domain === "worldResource" ? "World resource" : "Currency & Essence",
    id: resource.id,
    slug: slug(resource.id),
    name: resource.name,
    summary: pressure,
    drivenBy: `${drivenBy} pressure`,
    requires,
    favours,
    internalGenerationConditions: { drivenBy: resource.drivenBy, requires: resource.requires ?? [], favours: resource.favours ?? [] },
    tradeBand: titleWords(resource.tradeBand),
    isRealityCurrency: resource.isRealityCurrency,
    currentUses: uses,
    disposition: resourcesJSON._authority.defaultDisposition,
    provenance: provenance([sourcePath], resource.id, resourcesJSON._authority.defaultDisposition, hashes, aggregateHash)
  };
}

function materialFamilies() {
  const materialPath = "Sources/Model/Materials.swift";
  const ecologyPath = "docs/creature-ecology-and-materials-overhaul-current.md";
  const componentPath = "docs/crafting-components-and-schematics-current.md";
  const enumBody = contents[materialPath].match(/enum MaterialKind[\s\S]*?\{([\s\S]*?)\n\s*var isAnimalWorldResource/)?.[1] ?? "";
  const live = [...enumBody.matchAll(/\bcase\s+([^\n/]+)/g)].flatMap(match => match[1].split(",").map(value => value.trim())).filter(Boolean);
  const animalLive = live.filter(id => !["timber", "fibre", "pulp", "toxin", "reagent"].includes(id));
  const designed = markdownTableAfter(contents[componentPath], "## 5. Complete ComponentProfile table — Creature domain")
    .filter(([stableFamily]) => /^creature\.[a-z_]+$/.test(stableFamily));
  return [
    ...animalLive.map(id => ({
      type: "creatureMaterial",
      id: `live:${id}`,
      slug: `live-${slug(id)}`,
      familyID: id,
      name: id.replace(/_/g, " "),
      summary: "Currently implemented transitional MaterialKind harvested from creature remains; it is not the final anatomy-derived family model.",
      legalRoles: "Current live consumers remain governed by Swift rules.",
      contribution: "Legacy property-bearing material unit.",
      restriction: "Transitional live model; do not infer a final ComponentProfile.",
      visualTreatment: "No final family-specific visual authority.",
      status: "live legacy material model",
      disposition: "live",
      provenance: provenance([materialPath, ecologyPath], id, "live legacy material model", hashes, aggregateHash)
    })),
    ...designed.map(([stableFamily, legalRoles, contribution, restriction, visualTreatment]) => {
      const familyID = stableFamily.replace(/^creature\./, "");
      return {
        type: "creatureMaterial",
        id: `designed:${familyID}`,
        slug: `designed-${slug(familyID)}`,
        familyID,
        name: familyID.replace(/_/g, " "),
        summary: `${contribution}; ${restriction}`,
        legalRoles,
        contribution,
        restriction,
        visualTreatment,
        status: "current design / not yet live",
        disposition: "proposed",
        provenance: provenance([componentPath, ecologyPath], familyID, "current design / not yet live", hashes, aggregateHash)
      };
    })
  ];
}

const travellerPagesByID = Object.groupBy(travellersJSON.pages, page => page.diary);
const keeperStationByID = Object.fromEntries(stations.filter(station => station.keeperID).map(station => [station.keeperID, station]));
const teachingFields = ["teachesFocus", "teachesGambit", "teachesPattern", "teachesSchematic"];
const travellerSources = [
  "Sources/Content/Data/travellers.json",
  "Sources/Content/Data/stations.json",
  "Sources/VisualAdapters/NamedCharacterVisualAdapter.swift",
  "docs/authored-text-audit-current.md",
  "docs/diary-teaching-registry-implementation-audit-current.md",
  "docs/roster-progression-current.md"
];
const travellers = travellersJSON.travellers.map(person => {
  const pages = travellerPagesByID[person.id] ?? [];
  const clues = pages.filter(page => page.kind === "locationClue");
  const teachingPage = pages.find(page => teachingFields.some(field => page[field]));
  const teachingField = teachingFields.find(field => teachingPage?.[field]);
  const station = keeperStationByID[person.id] ?? null;
  const meetingStatus = person.meeting ? "live" : "authored-not-live";
  return {
    type: "traveller",
    id: person.id,
    slug: slug(person.id),
    name: person.name,
    calling: person.calling,
    summary: person.blurb,
    authoredOrder: person.authoredOrder,
    storyArrivalBand: person.storyArrivalBand,
    campaignPhase: person.campaignPhase,
    worldwork: person.worldwork,
    station: station ? { id: station.id, slug: station.slug, name: station.name, zone: station.zone, destinationKind: station.destinationKind } : null,
    pageCount: pages.length,
    clueCount: clues.length,
    teaching: teachingPage ? { pageID: teachingPage.id, kind: teachingPage.kind, field: teachingField, stableID: teachingPage[teachingField] } : null,
    meetingStatus,
    meetingQuestionCount: person.meeting?.questions?.length ?? 0,
    recruitmentStatus: "live traveller catalogue / recruitable identity",
    visualStatus: "live fixed identity adapter with explicit fallback",
    disposition: travellersJSON._authority.defaultDisposition,
    provenance: provenance(travellerSources, person.id, travellersJSON._authority.defaultDisposition, hashes, aggregateHash)
  };
}).sort((left, right) => left.authoredOrder - right.authoredOrder);
const resources = resourcesJSON.resources.map(resourceRecord);
const items = itemsJSON.items.map(itemRecord);
const creatureMaterials = materialFamilies();
function lexemeRecord(kind, item, sourcePath, disposition) {
  const playerKinds = { target: "Subject", source: "Focus", qualifier: "Modifier", compound: "Compound" };
  const alwaysWritable = kind === "target" || kind === "qualifier";
  const acquisitionKey = item.acquisition ?? (alwaysWritable ? "always" : null);
  const acquisitionNames = {
    worldDrop: "Found in a world", research: "Learned through an Upgrade",
    diary: "Learned from diary writing", starter: "Known at the start",
    always: "Always available vocabulary"
  };
  const acquisition = acquisitionNames[acquisitionKey];
  if (!acquisition) throw new Error(`Unsupported lexeme acquisition: ${acquisitionKey}`);
  const targetName = id => targetsJSON.targets.find(target => target.id === id)?.name ?? "Unknown Subject";
  const sourceName = id => sourcesJSON.sources.find(source => source.id === id)?.name ?? "Unknown Focus";
  const expansion = kind === "compound"
    ? (item.expandsTo ?? []).map(part => `${titleWords(part.intensity)} ${sourceName(part.source)} → ${targetName(part.target)}`)
    : kind === "source"
      ? (item.contributions ?? []).map(part => `${targetName(part.target)} — ${titleWords(part.character)}`)
      : [];
  return {
    type: "rune",
    category: kind,
    playerKind: playerKinds[kind],
    id: `${kind}:${item.id}`,
    stableID: item.id,
    slug: `${kind}-${slug(item.id)}`,
    name: item.name,
    summary: item.blurb ?? (kind === "qualifier" ? `Changes the ${item.ladder} ladder.` : "Authored writing vocabulary."),
    acquisition,
    internalAcquisition: acquisitionKey,
    essenceCost: item.essenceCost ?? null,
    ladder: item.ladder ?? null,
    attachesTo: (item.attachesTo ?? []).map(targetName),
    expansion,
    writability: alwaysWritable ? `Writable whenever the Writing Desk is available` : `Writable after this ${playerKinds[kind]} is learned`,
    disclosure: alwaysWritable ? "Its name and meaning are always visible." : "Seen but not learned Sigils appear as ??. Learn it to reveal its name and meaning.",
    disposition,
    provenance: provenance([sourcePath], item.id, disposition, hashes, aggregateHash)
  };
}

const allSymbols = [
  ...targetsJSON.targets.map(item => lexemeRecord("target", item, "Sources/Content/Data/pressure_targets.json", targetsJSON._authority.defaultDisposition)),
  ...sourcesJSON.sources.map(item => lexemeRecord("source", item, "Sources/Content/Data/pressure_sources.json", sourcesJSON._authority.defaultDisposition)),
  ...qualifiersJSON.qualifiers.map(item => lexemeRecord("qualifier", item, "Sources/Content/Data/qualifiers.json", qualifiersJSON._authority?.defaultDisposition ?? "live")),
  ...symbolsJSON.symbols.map(item => lexemeRecord("compound", item, "Sources/Content/Data/symbols.json", symbolsJSON._authority.defaultDisposition))
];
const symbols = allSymbols.filter(symbol => ["always", "starter"].includes(symbol.internalAcquisition));
const withheldVocabulary = {
  count: allSymbols.length - symbols.length,
  byPlayerKind: Object.fromEntries(Object.entries(Object.groupBy(allSymbols.filter(symbol => !symbols.includes(symbol)), symbol => symbol.playerKind)).map(([kind, entries]) => [kind, entries.length]))
};
const hiddenLexemeIDs = new Set(allSymbols.filter(symbol => !symbols.includes(symbol)).map(symbol => `${symbol.category}:${symbol.stableID}`));
const roadmap = normalize(roadmapJSON.items, "roadmap", "Sources/Content/Data/playability-roadmap.json", "operational");
const roadmapTitleOverrides = {
  "rune-dictionary": "Known and unknown Sigil Dictionary",
  "world-screen-presentation": "World screen phone composition record",
  "combat-tree-v2": "True combat trees and complete Skill consumers",
  "return-receipt-authority": "One trustworthy Expedition record",
  "writing-causal-presentation": "Page-first Writing and truthful World preview"
};
for (const [index, item] of roadmap.entries()) {
  item.name = roadmapTitleOverrides[item.id] ?? item.name;
  item.workstream = roadmapJSON.items[index].workstream;
  item.band = roadmapJSON.items[index].band ?? "unbanded";
  item.gate = roadmapJSON.items[index].gate ?? "No separate acceptance gate recorded.";
  item.owner = roadmapJSON.items[index].owner ?? roadmapJSON.items[index].workstream;
  item.isPrimary = Boolean(roadmapJSON.items[index].isPrimary);
  item.detail = roadmapJSON.items[index].detail ?? item.summary;
}

function requiredRoadmapItem(id) {
  const item = roadmap.find(candidate => candidate.id === id);
  if (!item) throw new Error(`Missing required roadmap truth: ${id}`);
  return item;
}

const writingRoadmap = requiredRoadmapItem("writing-causal-presentation");
const terrainCorrectionRoadmap = requiredRoadmapItem("terrain");
const terrainLayeringRoadmap = requiredRoadmapItem("terrain-layering-animation");
const atmosphereRoadmap = requiredRoadmapItem("atmospheric-world-presentation");
const parchmentManifestPath = "AssetLab/artifacts/writing-parchment-v1/manifest.json";
const parchmentManifest = JSON.parse(contents[parchmentManifestPath]);
const writingSourcePaths = [
  "Sources/Content/Data/playability-roadmap.json",
  "docs/writing-desk-b1-implementation-packet-current.md",
  "Sources/Screens/PageGridView.swift",
  "Sources/Screens/WritingDeskView.swift",
  "Sources/VisualRuntime/WritingDeskProductionPack.swift",
  "Bookbinder.xcodeproj/project.pbxproj",
  parchmentManifestPath
];
const parchmentStableKey = parchmentManifest.runtime?.stableKey;
const parchmentFilename = parchmentManifest.runtime?.path?.split("/").at(-1);
const nativeParchmentSourceIntegrated = Boolean(
  parchmentStableKey
  && parchmentFilename
  && contents["Sources/VisualRuntime/WritingDeskProductionPack.swift"].includes(`static let parchmentStableKey = "${parchmentStableKey}"`)
  && contents["Sources/VisualRuntime/WritingDeskProductionPack.swift"].includes(`static let parchmentFilename = "${parchmentFilename}"`)
  && contents["Sources/Screens/PageGridView.swift"].includes("WritingDeskProductionPack.productionParchmentData()")
  && contents["Bookbinder.xcodeproj/project.pbxproj"].includes(`${parchmentFilename} in Resources`)
);
if (!nativeParchmentSourceIntegrated) throw new Error("Writing parchment manifest, loader, view and native resource bundle no longer agree");
if (!contents["Sources/Screens/WritingDeskView.swift"].includes("WritingDeskNativeVocabularyLabel")) {
  throw new Error("Writing vocabulary no longer exposes a native player-readable label seam");
}

const currentTruth = {
  writing: {
    status: writingRoadmap.status,
    statusLabel: "source-integrated / ordinary-phone visual acceptance pending / nonblocking",
    isPrimary: writingRoadmap.isPrimary,
    roadmapID: writingRoadmap.id,
    summary: writingRoadmap.summary,
    acceptanceGate: writingRoadmap.gate,
    e5ToE7Status: "not started",
    markArtStatus: "temporary semantic-keyed integration scaffolding; final sigil design is not accepted",
    vocabularyLabelStatus: "native player-readable text is reserved separately from scaffold glyph pixels",
    parchment: {
      stableKey: parchmentStableKey,
      assetPath: parchmentManifest.runtime.path,
      pngSHA256: parchmentManifest.runtime.pngSHA256,
      manifestStatus: parchmentManifest.status,
      artifactIntegrationReady: parchmentManifest.integrationReady,
      nativeSourceIntegrated: nativeParchmentSourceIntegrated,
      status: "hash-pinned native source integration / ordinary-phone acceptance pending"
    },
    provenance: provenance(writingSourcePaths, writingRoadmap.id, writingRoadmap.status, hashes, aggregateHash)
  },
  terrain: {
    borderCorrection: {
      status: terrainCorrectionRoadmap.status,
      summary: terrainCorrectionRoadmap.summary
    },
    layeredPresentation: {
      status: terrainLayeringRoadmap.status,
      summary: terrainLayeringRoadmap.summary,
      nativeStatus: terrainLayeringRoadmap.detail
    },
    atmosphere: {
      status: atmosphereRoadmap.status,
      summary: atmosphereRoadmap.summary,
      nativeStatus: "visually accepted frozen-ready Asset candidate; native integration is queued"
    },
    provenance: provenance([
      "Sources/Content/Data/playability-roadmap.json",
      "docs/terrain-layering-and-motion-asset-packet-current.md",
      "docs/atmospheric-world-presentation-current.md"
    ], terrainLayeringRoadmap.id, terrainLayeringRoadmap.status, hashes, aggregateHash)
  }
};

const terminologySourcePath = "docs/canonical-game-terminology.json";
const terminology = terminologyAuthority.terms.map(term => {
  for (const key of ["concept", "canonical", "domain", "explanation", "whereItAppears"]) {
    if (!String(term[key] ?? "").trim()) throw new Error(`Terminology entry ${term.concept ?? "unknown"} lacks ${key}`);
  }
  if (!Array.isArray(term.retire) || !term.retire.length) throw new Error(`Terminology entry ${term.concept} lacks retired aliases`);
  const aliases = [...new Set(term.retire.map(value => String(value).trim()).filter(Boolean))];
  const exactSearchTerms = [...new Set([term.canonical, ...aliases].map(value => value.toLowerCase().replace(/\s+/g, " ").trim()))];
  return ({
  type: "terminology",
  category: "Terminology",
  id: term.concept,
  slug: slug(term.concept),
  name: term.canonical,
  summary: term.explanation,
  domain: term.domain,
  whereItAppears: term.whereItAppears,
  aliases,
  exactSearchTerms,
  searchText: [term.canonical, term.concept, ...term.retire].join(" ").toLowerCase(),
  disposition: terminologyAuthority.status,
  provenance: provenance([terminologySourcePath], term.concept, terminologyAuthority.status, hashes, aggregateHash)
  });
});

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

const manifestRecords = assetLabManifestPaths.map(path => ({
  path,
  fileSHA256: hashes[path],
  familyID: familyIDFromManifestPath(path),
  manifest: JSON.parse(contents[path])
}));
const runtimeManifestRecords = runtimePackManifestPaths.map(path => ({
  path,
  fileSHA256: hashes[path],
  manifest: JSON.parse(contents[path])
}));
const receiptRecords = assetReceiptPaths.map(path => ({
  path,
  fileSHA256: hashes[path],
  receipt: JSON.parse(contents[path])
}));
const manifestGroups = Object.groupBy(manifestRecords, record => record.familyID);
const visualAssetFamilies = [];

for (const familyID of Object.keys(manifestGroups).sort()) {
  const records = manifestGroups[familyID];
  const manifests = records.map(record => record.manifest);
  const classification = visualClassification(records[0].path, manifests);
  const runtimeMirrors = runtimeManifestRecords.filter(runtime => records.some(record => record.fileSHA256 === runtime.fileSHA256));
  const receipts = receiptRecords.filter(record => {
    if (record.path.includes(`/${familyID}/`)) return true;
    return Boolean(record.receipt.packs?.[familyID]);
  });
  const approvalReceipts = receipts.filter(record => {
    const status = String(record.receipt.status ?? "").toLowerCase();
    return /approved/.test(status) && !/(unapproved|not.*approved)/.test(status);
  });
  const evidenceReceipts = receipts.filter(record => !approvalReceipts.includes(record));
  const rawAssets = records.flatMap(record => pngReferences(record.manifest).map(asset => ({ ...asset, manifestPath: record.path })));
  const assets = [];
  const assetsByRoute = new Map();
  const contextPriority = context => context.startsWith("lookups/") || context.startsWith("parts/") || context.includes("assetsByKey/") ? 0
    : context.startsWith("profiles/") ? 1
    : context.startsWith("assets/") ? 3
    : 2;
  const distinctManifestHashes = unique(records.map(record => record.fileSHA256));
  const authorityConflict = distinctManifestHashes.length > 1 ? {
    status: "unresolved",
    manifests: records.map(record => ({
      path: record.path,
      fileSHA256: record.fileSHA256,
      canonicalManifestSHA256: record.manifest.canonicalManifestSha256 ?? record.manifest.canonicalManifestSHA256 ?? null,
      outputCount: Array.isArray(record.manifest.outputs) ? record.manifest.outputs.length : null
    }))
  } : null;
  const disclosure = partitionVisualRecords(rawAssets, hiddenLexemeIDs, authorityConflict ? "authority-conflict" : null);
  const withheldCounts = disclosure.withheldCounts;
  for (const rawAsset of disclosure.disclosed.sort((left, right) => `${contextPriority(left.context)}\0${left.semanticKey}\0${left.rawPath}`.localeCompare(`${contextPriority(right.context)}\0${right.semanticKey}\0${right.rawPath}`))) {
    const resolvedPath = await resolveAssetPath(rawAsset.manifestPath, rawAsset.rawPath, rawAsset.context);
    let actualSHA256 = null;
    if (resolvedPath) actualSHA256 = sha(await readFile(join(repoRoot, resolvedPath)));
    let role = rawAsset.role;
    if (records[0].path.startsWith("AssetLab/artifacts/") && role === "runtime" && !/^runtime\//i.test(rawAsset.context)) role = "evidence";
    const identity = visualRecordIdentity({ familyID, role, semanticKey: rawAsset.semanticKey, variant: rawAsset.variant });
    const asset = {
      semanticKey: rawAsset.semanticKey,
      role,
      variant: rawAsset.variant,
      sourcePath: resolvedPath,
      declaredSHA256: rawAsset.declaredSHA256,
      actualSHA256,
      decodedRGBASHA256: rawAsset.decodedRGBASHA256,
      width: rawAsset.width,
      height: rawAsset.height,
      integrity: !resolvedPath ? "missing"
        : rawAsset.declaredSHA256 && rawAsset.declaredSHA256 !== actualSHA256 ? "hash-mismatch"
        : rawAsset.declaredSHA256 ? "verified" : "unverified",
      route: identity.route,
      sourceRoute: identity.sourceRoute,
      previewURL: resolvedPath ? identity.previewURL : null
    };
    const existing = assetsByRoute.get(asset.route);
    if (existing) {
      if (existing.sourcePath === asset.sourcePath && existing.actualSHA256 === asset.actualSHA256) continue;
      throw new Error(`Visual route collision: ${asset.route} (${existing.sourcePath ?? existing.semanticKey} and ${asset.sourcePath ?? asset.semanticKey})`);
    }
    assets.push(asset);
    assetsByRoute.set(asset.route, asset);
  }
  assertUniqueVisualRoutes(assets);
  const blockers = [];
  if (authorityConflict) blockers.push("multiple divergent manifests claim this family");
  if (assets.some(asset => asset.integrity === "missing")) blockers.push("one or more manifest image paths are missing");
  if (assets.some(asset => asset.integrity === "hash-mismatch")) blockers.push("one or more encoded image hashes do not match");
  if (classification === "functional-placeholder") blockers.push("functional placeholder; final art is not represented");
  if (classification === "frozen-legacy") blockers.push("frozen legacy or conformance boundary");
  if (classification === "review-only") blockers.push("review evidence is not production art");
  if (classification === "candidate") blockers.push("candidate is not approved by classification alone");
  if (classification === "unresolved") blockers.push("manifest does not establish a safe visual disposition");
  if (!assets.length) blockers.push("manifest exposes no directly renderable PNG path");
  visualAssetFamilies.push({
    id: familyID,
    slug: slug(familyID),
    name: familyID.replace(/-v\d+(?:\.\d+)?$/i, "").replaceAll("-", " ").replace(/\b\w/g, character => character.toUpperCase()),
    classification,
    status: unique(manifests.map(manifest => String(manifest.status ?? manifest.evidenceRole ?? (manifest.integrationReady === true ? "integrationReady:true" : manifest.integrationReady === false ? "integrationReady:false" : "unlabelled")))),
    manifestPaths: records.map(record => record.path),
    runtimeMirrorPaths: runtimeMirrors.map(record => record.path),
    sourcePaths: unique(assets.filter(asset => asset.role === "source").map(asset => asset.sourcePath).filter(Boolean)),
    runtimePaths: unique(assets.filter(asset => asset.role === "runtime").map(asset => asset.sourcePath).filter(Boolean)),
    referencePaths: unique(assets.filter(asset => asset.role === "reference").map(asset => asset.sourcePath).filter(Boolean)),
    evidencePaths: unique([
      ...assets.filter(asset => asset.role === "evidence").map(asset => asset.sourcePath).filter(Boolean),
      ...evidenceReceipts.map(record => record.path)
    ]),
    approvalReceipts: approvalReceipts.map(record => ({
      path: record.path,
      fileSHA256: record.fileSHA256,
      status: record.receipt.status ?? "unlabelled",
      authority: record.receipt.approvalAuthority ?? record.receipt.approvals ?? null,
      date: record.receipt.approvalDate ?? null
    })),
    authorityConflict,
    withheldCounts,
    blockers: unique(blockers),
    assets
  });
}

const visualAssetSummary = {
  familyCount: visualAssetFamilies.length,
  renderedAssetCount: visualAssetFamilies.reduce((sum, family) => sum + family.assets.filter(asset => asset.previewURL).length, 0),
  blockedFamilyCount: visualAssetFamilies.filter(family => family.blockers.length).length,
  classifications: Object.fromEntries(Object.entries(Object.groupBy(visualAssetFamilies, family => family.classification)).map(([key, families]) => [key, families.length]))
};

const routes = [
  "overview", "core-loop", "world-writing", "exploration", "combat", "people", "terminology",
  "village-buildings", "resources-crafting", "catalogue", "catalogue/gear", "catalogue/consumables",
  "catalogue/curios", "catalogue/treasures", "catalogue/keys", "roadmap", "history", "asset-gallery",
  ...stations.map(station => `station/${station.slug}`), ...travellers.map(person => `person/${person.slug}`),
  ...items.map(item => `item/${item.slug}`), ...resources.map(resource => `resource/${resource.slug}`),
  ...creatureMaterials.map(material => `creature-material/${material.slug}`),
  ...symbols.map(symbol => `lexeme/${symbol.slug}`), ...roadmap.map(item => `roadmap/${item.slug}`),
  ...terminology.map(term => `terminology/${term.slug}`),
  ...visualAssetFamilies.map(family => `asset-family/${family.slug}`),
  ...visualAssetFamilies.flatMap(family => family.assets.map(asset => asset.route))
];
const visualAssetSearch = visualAssetFamilies.map(family => ({
  type: "visualAssetFamily",
  id: family.id,
  name: family.name,
  summary: `${family.classification}; ${family.assets.length} manifested visual records`,
  category: "Visual assets",
  route: `asset-family/${family.slug}`,
  searchText: [family.name, family.id, family.classification, ...family.assets.map(asset => asset.semanticKey)].join(" ").toLowerCase(),
  exactSearchTerms: [family.name, family.id].map(value => value.toLowerCase()),
  disposition: family.blockers.length ? "blocked or review-gated" : family.status.join(" · "),
  provenance: provenance(family.manifestPaths, family.id, family.classification, hashes, aggregateHash)
}));
const visualRecordSearch = visualAssetFamilies.flatMap(family => family.assets.map(asset => ({
  type: "visualAssetRecord",
  id: asset.sourceRoute,
  name: asset.semanticKey,
  summary: `${family.name} · ${asset.role} · ${asset.variant}`,
  category: "Visual asset record",
  route: asset.route,
  searchText: [asset.semanticKey, family.name, family.id, asset.role, asset.variant, asset.sourceRoute].join(" ").toLowerCase(),
  exactSearchTerms: [asset.semanticKey, asset.sourceRoute].map(value => value.toLowerCase()),
  disposition: family.blockers.length ? "blocked or review-gated" : family.status.join(" · "),
  provenance: provenance(family.manifestPaths, asset.sourceRoute, family.classification, hashes, aggregateHash)
})));
const search = [...stations, ...travellers, ...resources, ...creatureMaterials, ...items, ...symbols, ...roadmap, ...terminology].map(entity => ({
  type: entity.type,
  id: entity.id,
  name: entity.name,
  summary: entity.blurb ?? entity.summary ?? "",
  category: entity.playerKind ?? entity.category ?? entity.type,
  route: entity.type === "station" ? `station/${entity.slug}` : entity.type === "roadmap" ? `roadmap/${entity.slug}` : entity.type === "traveller" ? `person/${entity.slug}` : ["gear", "consumable", "curio", "treasure", "key"].includes(entity.type) ? `item/${entity.slug}` : entity.type === "resource" ? `resource/${entity.slug}` : entity.type === "creatureMaterial" ? `creature-material/${entity.slug}` : entity.type === "rune" ? `lexeme/${entity.slug}` : entity.type === "terminology" ? `terminology/${entity.slug}` : "overview",
  searchText: entity.searchText ?? [entity.name, entity.id, entity.blurb ?? entity.summary ?? ""].join(" ").toLowerCase(),
  exactSearchTerms: entity.exactSearchTerms ?? [entity.name].map(value => String(value).toLowerCase()),
  disposition: entity.disposition,
  provenance: entity.provenance
})).concat(visualAssetSearch, visualRecordSearch);

const wikiData = {
  schemaVersion: 1,
  generatedAtSourceHash: aggregateHash,
  routes,
  counts: { stations: stations.length, travellers: travellers.length, resources: resources.length, items: items.length, runes: symbols.length, roadmap: roadmap.length },
  stations, travellers, resources, creatureMaterials, items, symbols, withheldVocabulary, roadmap, terminology, authorities, history, search, currentTruth,
  visualAssets: {
    summary: visualAssetSummary,
    families: visualAssetFamilies
  },
  assetGallery: {
    acceptedAssets: [],
    reviewEvidence: [],
    slots: [...stations.filter(station => station.destinationKind === "villageBuilding").flatMap(station => station.assetSlots), ...binderHouseRootSlot],
    note: "This gallery currently inventories Home/Village building-state slots only. No building candidate is claimed as a native asset. Writing parchment and queued Terrain presentation have separate current-truth receipts below."
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
