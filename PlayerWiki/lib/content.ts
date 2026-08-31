import rawContent from '@/data/player-content.json';

export interface Resource {
  id: string;
  slug: string;
  name: string;
  summary: string;
  drivenBy: string;
  requires: string[];
  favours: string[];
  tradeBand: string;
  isRealityCurrency: boolean;
  currentUses: string[];
  assetURL: string | null;
}

export interface Item {
  id: string;
  slug: string;
  name: string;
  type: string;
  category: string;
  summary: string;
  rarity: string;
  gear: Record<string, unknown> | null;
  consumable: Record<string, unknown> | null;
  tradingPostDisposition: string;
  recyclerDisposition: string;
  assetURL: string | null;
}

export interface Traveller {
  id: string;
  slug: string;
  name: string;
  calling: string;
  summary: string;
  authoredOrder: number;
  storyArrivalBand: number;
  campaignPhase: string;
  pageCount: number;
  clueCount: number;
  station: {
    id: string;
    slug: string;
    name: string;
    zone: string;
    destinationKind: string;
  } | null;
  teaching: {
    pageID: string;
    kind: string;
    field: string;
    stableID: string;
  } | null;
  hints: string[];
  diaryPages: Array<{ kind: string; prose: string; reward: string | null }>;
}

export interface Station {
  id: string;
  slug: string;
  name: string;
  blurb: string;
  zone: string;
  lifecycle: string;
  keeper: string | null;
  keeperID: string | null;
  unlockedAtStart: boolean;
  startingTier: number;
  catalogueMaxTier: number;
  buildCost: Array<{
    id?: string;
    resourceID?: string;
    resource?: string;
    quantity?: number;
    amount?: number;
  }>;
  buildBlurb: string | null;
}

export interface Term {
  id: string;
  slug: string;
  name: string;
  summary: string;
  domain: string;
  aliases: string[];
}

interface PlayerContent {
  schemaVersion: number;
  resources: Resource[];
  items: Item[];
  travellers: Traveller[];
  stations: Station[];
  terminology: Term[];
  terrain: Array<{ name: string; assetURL: string }>;
  writingAssetURL: string | null;
}

export const content = rawContent as PlayerContent;
export const equipment = content.items.filter((item) => item.gear);
export const consumables = content.items.filter((item) => item.consumable);
export const curios = content.items.filter(
  (item) => !item.gear && !item.consumable,
);

export function humanize(value: unknown) {
  if (value === null || value === undefined || value === '') return '—';
  return String(value)
    .replaceAll(/([a-z])([A-Z])/g, '$1 $2')
    .replaceAll(/[_-]/g, ' ')
    .replace(/^./, (letter) => letter.toUpperCase());
}

export function gearValue(item: Item, field: string) {
  return humanize(item.gear?.[field]);
}

export function consumableValue(item: Item, field: string) {
  return humanize(item.consumable?.[field]);
}

export function itemProperties(item: Item) {
  if (!item.gear) return [];
  return Object.entries(item.gear)
    .filter(([key]) => !['slot', 'tier', 'damage', 'reach'].includes(key))
    .map(([key, value]) => `${humanize(key)}: ${humanize(value)}`);
}

export function buildCost(station: Station) {
  if (!station.buildCost?.length)
    return station.unlockedAtStart
      ? 'Available at the start'
      : 'No construction cost listed';
  return station.buildCost
    .map(
      (cost) =>
        `${cost.quantity ?? cost.amount ?? '?'} ${humanize(cost.id ?? cost.resource ?? cost.resourceID)}`,
    )
    .join(', ');
}

export function stationUsesResource(station: Station, resourceID: string) {
  return station.buildCost.filter(
    (cost) => (cost.id ?? cost.resource ?? cost.resourceID) === resourceID,
  );
}
