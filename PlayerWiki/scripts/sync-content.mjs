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

async function publishAsset(asset, directory, fileName) {
  if (!asset?.sourcePath) return null;
  const sourcePath = path.join(repositoryRoot, asset.sourcePath);
  const destinationPath = path.join(publicAssetRoot, directory, fileName);
  await copyFile(sourcePath, destinationPath);
  return `/game-assets/${directory}/${fileName}`;
}

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

const travellers = source.travellers
  .filter((traveller) => traveller.meetingStatus === 'live')
  .map((traveller) => {
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
    return {
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
    };
  });

const stations = source.stations
  .filter(
    (station) =>
      station.disposition === 'settled' &&
      station.lifecycle !== 'removedCompatibility',
  )
  .map((station) => ({
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
};

await writeFile(
  outputDataPath,
  `${JSON.stringify(playerContent, null, 2)}\n`,
  'utf8',
);
console.log(
  `Synced ${resources.length} resources, ${items.length} items, ${travellers.length} live people and ${stations.length} current places.`,
);
