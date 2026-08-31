import { copyFile, mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const playerWikiRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
);
const repositoryRoot = path.resolve(playerWikiRoot, '..');
const sourceDataPath = path.join(
  repositoryRoot,
  'GameWiki',
  'generated',
  'wiki-data.json',
);
const outputDataPath = path.join(playerWikiRoot, 'data', 'player-content.json');
const publicAssetRoot = path.join(playerWikiRoot, 'public', 'game-assets');

const source = JSON.parse(await readFile(sourceDataPath, 'utf8'));
const travellerSource = JSON.parse(
  await readFile(
    path.join(repositoryRoot, 'Sources', 'Content', 'Data', 'travellers.json'),
    'utf8',
  ),
);
const namedCharacterPack = JSON.parse(
  await readFile(
    path.join(
      repositoryRoot,
      'AssetLab',
      'integration',
      'named-character-placeholders-v1',
      'manifest.json',
    ),
    'utf8',
  ),
);
const townBuildingRegistry = await readFile(
  path.join(
    repositoryRoot,
    'Sources',
    'VisualRuntime',
    'TownBuildingVisualRegistry.generated.swift',
  ),
  'utf8',
);
const townBuildingAssetByStationID = new Map(
  [...townBuildingRegistry.matchAll(/^\s*"([a-z_]+)": "([a-z0-9-]+)"/gm)].map(
    ([, stationID, assetName]) => [stationID, assetName],
  ),
);
const family = (id) =>
  source.visualAssets.families.find((entry) => entry.id === id);
const runtimeAsset = (familyID, semanticKey) =>
  family(familyID)?.assets.find(
    (asset) => asset.role === 'runtime' && asset.semanticKey === semanticKey,
  );

const safeFileName = (value) =>
  `${String(value).replaceAll(/[^a-zA-Z0-9_-]/g, '-')}.png`;

await mkdir(path.dirname(outputDataPath), { recursive: true });
await mkdir(path.join(publicAssetRoot, 'resources'), { recursive: true });
await mkdir(path.join(publicAssetRoot, 'items'), { recursive: true });
await mkdir(path.join(publicAssetRoot, 'terrain'), { recursive: true });
await mkdir(path.join(publicAssetRoot, 'writing'), { recursive: true });
await mkdir(path.join(publicAssetRoot, 'people'), { recursive: true });
await mkdir(path.join(publicAssetRoot, 'places'), { recursive: true });
await mkdir(path.join(publicAssetRoot, 'exploration'), { recursive: true });

async function publishAsset(asset, directory, fileName) {
  if (!asset?.sourcePath) return null;
  const sourcePath = path.join(repositoryRoot, asset.sourcePath);
  const destinationPath = path.join(publicAssetRoot, directory, fileName);
  await copyFile(sourcePath, destinationPath);
  return `/game-assets/${directory}/${fileName}`;
}

async function publishTravellerCameo(travellerID, slug) {
  const asset = namedCharacterPack.assets.find(
    (entry) =>
      entry.key?.travellerID === travellerID &&
      entry.key?.profile === 'compactCameo' &&
      !entry.key?.facing,
  );
  if (
    !asset ||
    asset.width !== 16 ||
    asset.height !== 16 ||
    !Array.isArray(asset.commands) ||
    asset.commands.some(
      (command) =>
        command.op !== 'rect' ||
        !Number.isInteger(command.x) ||
        !Number.isInteger(command.y) ||
        !Number.isInteger(command.w) ||
        !Number.isInteger(command.h) ||
        command.x < 0 ||
        command.y < 0 ||
        command.w < 1 ||
        command.h < 1 ||
        command.x + command.w > 16 ||
        command.y + command.h > 16 ||
        !/^#[0-9a-f]{6}$/i.test(command.color),
    )
  ) {
    return null;
  }
  const body = asset.commands
    .map(
      (command) =>
        `<rect x="${command.x}" y="${command.y}" width="${command.w}" height="${command.h}" fill="${command.color}"/>`,
    )
    .join('');
  const destination = `${slug}-cameo.svg`;
  await writeFile(
    path.join(publicAssetRoot, 'people', destination),
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" shape-rendering="crispEdges">${body}</svg>\n`,
    'utf8',
  );
  return `/game-assets/people/${destination}`;
}

async function publishTownVisual(sourcePath, destination) {
  await copyFile(
    path.join(repositoryRoot, sourcePath),
    path.join(publicAssetRoot, 'places', destination),
  );
  return `/game-assets/places/${destination}`;
}

const startingTownAssetURL = await publishTownVisual(
  'AssetLab/integration/starting-town-home-v1/town-starting-home-v1-phone-v2.png',
  'starting-town-home.png',
);
const districtAssetURL = await publishTownVisual(
  'Sources/Content/TownVisuals/town-empty-v1.png',
  'town-district.png',
);

const resources = [];
for (const resource of source.resources) {
  const asset = runtimeAsset(
    'resource-sprites-v1',
    `resources/profiles/inventory/${resource.id}`,
  );
  resources.push({
    id: resource.id,
    slug: resource.slug,
    name: resource.name,
    summary: resource.summary,
    drivenBy: resource.drivenBy,
    requires: resource.requires,
    favours: resource.favours,
    tradeBand: resource.tradeBand,
    isRealityCurrency: resource.isRealityCurrency,
    currentUses: resource.currentUses,
    assetURL: await publishAsset(asset, 'resources', safeFileName(resource.id)),
  });
}

const items = [];
for (const item of source.items) {
  const asset =
    runtimeAsset('exploration-loose-items-v1', `catalogue-item/${item.id}`) ??
    runtimeAsset(
      'exploration-catalogue-objects-v1',
      `catalogue-item/${item.id}/identified`,
    );
  items.push({
    id: item.id,
    slug: item.slug,
    name: item.name,
    type: item.type,
    category: item.category,
    summary: item.summary,
    rarity: item.rarity,
    gear: item.gear,
    consumable: item.consumable,
    tradingPostDisposition: item.tradingPostDisposition,
    recyclerDisposition: item.recyclerDisposition,
    assetURL: await publishAsset(asset, 'items', safeFileName(item.id)),
  });
}

const travellers = [];
for (const traveller of source.travellers.filter(
  (entry) => entry.meetingStatus === 'live',
)) {
    const authoredTraveller = travellerSource.travellers.find(
      (entry) => entry.id === traveller.id,
    );
    const rewardFor = (page) => {
      if (page.teachesFocus) return `Teaches Focus: ${page.teachesFocus}`;
      if (page.teachesGambit) return `Teaches Gambit: ${page.teachesGambit}`;
      if (page.teachesPattern) return `Teaches pattern: ${page.teachesPattern}`;
      if (page.teachesSchematic)
        return `Teaches schematic: ${page.teachesSchematic}`;
      if (page.researchNode) return `Research lead: ${page.researchNode}`;
      return null;
    };
    travellers.push({
      id: traveller.id,
      slug: traveller.slug,
      name: traveller.name,
      calling: traveller.calling,
      summary: traveller.summary,
      authoredOrder: traveller.authoredOrder,
      storyArrivalBand: traveller.storyArrivalBand,
      campaignPhase: traveller.campaignPhase,
      station: traveller.station,
      pageCount: traveller.pageCount,
      clueCount: traveller.clueCount,
      teaching: traveller.teaching,
      hints: authoredTraveller?.signature?.map((entry) => entry.passage) ?? [],
      diaryPages: travellerSource.pages
        .filter((page) => page.diary === traveller.id)
        .map((page) => ({
          kind: page.kind,
          prose: page.prose,
          reward: rewardFor(page),
        })),
      assetURL: await publishTravellerCameo(traveller.id, traveller.slug),
    });
}

const homeStationIDs = new Set([
  'writing_desk',
  'workshop',
  'storehouse',
  'essence_spring',
  'firepit',
]);
const stations = await Promise.all(source.stations
  .filter(
    (station) =>
      station.disposition === 'settled' &&
      station.lifecycle !== 'removedCompatibility',
  )
  .map(async (station) => {
    const assetName = townBuildingAssetByStationID.get(station.id);
    const assetURL = assetName
      ? await publishTownVisual(
          `Sources/Content/TownVisuals/${assetName}.png`,
          `${station.slug}.png`,
        )
      : null;
    return {
    id: station.id,
    slug: station.slug,
    name: station.name,
    blurb: station.blurb,
    zone: station.zone,
    lifecycle: station.lifecycle,
    keeper: station.keeper,
    keeperID: station.keeperID,
    unlockedAtStart: station.unlockedAtStart,
    startingTier: station.startingTier,
    catalogueMaxTier: station.catalogueMaxTier,
    buildCost: station.buildCost,
    buildBlurb: station.buildBlurb,
      assetURL,
      contextAssetURL: homeStationIDs.has(station.id)
        ? startingTownAssetURL
        : districtAssetURL,
    };
  }));

const terrain = [];
for (const asset of family('terrain-production-pack-v1')?.assets.filter(
  (asset) => asset.role === 'runtime' && asset.semanticKey.includes('/macro/'),
) ?? []) {
  const name =
    asset.semanticKey.match(/macro\/(.+?)-semantic/)?.[1] ?? asset.semanticKey;
  terrain.push({
    name,
    assetURL: await publishAsset(asset, 'terrain', safeFileName(name)),
  });
}

const writingAsset = family('writing-parchment-v1')?.assets.find(
  (asset) => asset.semanticKey === 'runtime/writing.parchment.handmade-v1',
);
const writingAssetURL = await publishAsset(
  writingAsset,
  'writing',
  'writing-parchment.png',
);
const writingVisuals = await Promise.all([
  [
    'tool',
    'Writing tool',
    'A retained Writing Desk tool',
    'parts/tools/brush/asset',
    'writing-tool-brush.png',
  ],
  [
    'mark',
    'Mark',
    'A retained Writing Desk mark',
    'lookups/marks/mark/source/bloom/brush/0/roles/rgba/bloom',
    'writing-mark-bloom.png',
  ],
  [
    'link',
    'Link',
    'A retained Writing Desk link',
    'lookups/links/link/brush/horizontal/asset',
    'writing-link-brush-horizontal.png',
  ],
].map(async ([id, label, alt, semanticKey, fileName]) => ({
  id,
  label,
  alt,
  assetURL: await publishAsset(
    runtimeAsset('writing-desk-production-pack-v1', semanticKey),
    'writing',
    fileName,
  ),
})));

const explorationVisuals = await Promise.all([
  ['entryPortal', 'entry_portal/ordinary/frame-0', 'entry-portal.png'],
  ['unsearchedSite', 'wayfarers_camp/unlooted/frame-0', 'site-unsearched.png'],
  ['searchedSite', 'wayfarers_camp/looted/frame-0', 'site-searched.png'],
].map(async ([name, semanticKey, fileName]) => [
  name,
  await publishAsset(
    runtimeAsset('exploration-map-identities-v1', semanticKey),
    'exploration',
    fileName,
  ),
]));

const playerContent = {
  schemaVersion: 1,
  resources,
  items,
  travellers,
  stations,
  terminology: source.terminology.map((term) => ({
    id: term.id,
    slug: term.slug,
    name: term.name,
    summary: term.summary,
    domain: term.domain,
    aliases: term.aliases,
  })),
  terrain,
  writingAssetURL,
  writingVisuals,
  explorationVisuals: Object.fromEntries(explorationVisuals),
};

await writeFile(
  outputDataPath,
  `${JSON.stringify(playerContent, null, 2)}\n`,
  'utf8',
);
console.log(
  `Synced ${resources.length} resources, ${items.length} items, ${travellers.length} live people and ${stations.length} current places.`,
);
