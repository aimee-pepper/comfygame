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
  acquisition: string;
  tradeStatus: string;
  currentUses: string[];
  consumerAuthority: {
    acquisition: string;
    buildingConsumers: string[];
    recipeConsumers: string[];
    otherConsumers: string[];
  };
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
  assetURL: string | null;
  hints: string[];
  diaryPages: Array<{ kind: string; prose: string; reward: string | null }>;
}

export interface CastDiaryPage {
  sequence: string;
  title: string;
  detail: string | null;
  worldHint: boolean;
}

export interface CastPerson {
  slug: string;
  name: string;
  calling: string;
  order: number;
  meetingContext: string;
  contribution: string;
  roleLabel: 'Service' | 'Role';
  role: string;
  diaryReward: string;
  diaryPageLabel: string;
  diaryPages: CastDiaryPage[];
  assetURL: string | null;
}

export interface Station {
  id: string;
  slug: string;
  name: string;
  blurb: string;
  status: 'implemented' | 'scheduled';
  route: string | null;
  destinationKind: string | null;
  purpose: string | null;
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
  assetURL: string | null;
  contextAssetURL: string | null;
}

export interface Term {
  id: string;
  slug: string;
  name: string;
  summary: string;
  domain: string;
  aliases: string[];
}

export interface ResearchBranch {
  id: string;
  name: string;
  blurb: string;
  order: number;
  stationID: string | null;
}

export interface ResearchNode {
  id: string;
  branch: string;
  name: string;
  blurb: string;
  cost: { essence: number; resources: Record<string, number> };
  requires: string[];
  needsStationTier: number;
  needsInstruments: number;
  needsLifetimeRawRefined: number;
  constructionBundledWith: string | null;
}

export interface PressureTarget {
  id: string;
  name: string;
  blurb: string;
  highLabel: string;
  lowLabel: string;
  order: number;
}

export interface CombatTechnique {
  name: string;
  blurb: string;
  effect: string;
  target: string;
  cooldown: string;
  availability: string;
  trainingRole: string | null;
  trainingDepth: number | null;
}

export interface GambitComponent {
  kind: 'subject' | 'property' | 'comparator' | 'threshold' | 'action';
  name: string;
  blurb: string;
}

export interface Creature {
  id: string;
  slug: string;
  name: string;
  tier: number;
  maxHP: number;
  attack: number;
  sightRadius: number;
  isNocturnal: boolean;
  requires: string[];
  favours: string[];
}

export interface Site {
  id: string;
  slug: string;
  name: string;
  blurb: string;
  category: string;
  conditions: string[];
  placement: string;
  minimumDistanceFromEntry: number | null;
  searchTurns: number;
  yields: Array<{ resourceID: string; quantity: number }>;
  itemIDs: string[];
  teaches: string[];
  guardianID: string | null;
  isNaturalAnchor: boolean;
}

interface PlayerContent {
  schemaVersion: number;
  resources: Resource[];
  items: Item[];
  creatures: Creature[];
  sites: Site[];
  travellers: Traveller[];
  cast: CastPerson[];
  stations: Station[];
  scheduledStations: Station[];
  researchBranches: ResearchBranch[];
  researchNodes: ResearchNode[];
  pressureTargets: PressureTarget[];
  combatTechniques: CombatTechnique[];
  gambitComponents: GambitComponent[];
  terminology: Term[];
  terrain: Array<{ name: string; assetURL: string }>;
  writingAssetURL: string | null;
  writingVisuals: Array<{
    id: string;
    label: string;
    alt: string;
    assetURL: string | null;
  }>;
  explorationVisuals: {
    entryPortal: string | null;
    unsearchedSite: string | null;
    searchedSite: string | null;
  };
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

export function consumableEffect(item: Item) {
  switch (item.consumable?.effect) {
    case 'heal': return 'Restore health';
    case 'clearPoison': return 'Clear poison';
    case 'clearElemental': return 'Clear burning and dazzled';
    case 'clearAnyStatus': return 'Clear one current status';
    case 'preventStatus': return 'Prevent one current status';
    case 'coatPoison': return 'Prepare a poison coating';
    case 'coatBurn': return 'Prepare a burning coating';
    case 'coatBleed': return 'Prepare a bleeding coating';
    case 'coatDazzle': return 'Prepare a dazzling coating';
    case 'identifyCurio': return 'Identify one carried curio';
    case 'lureCreature': return 'Draw the nearest creature';
    case 'maskScent': return 'Mask scent';
    case 'seamlightGuidance': return 'Light Seamlight';
    case 'restoreStability': return 'Restore Stability';
    case 'returnHome': return 'Return home with the haul';
    case 'lightWorld': return 'Raise the party’s vision';
    case 'farsight': return 'Reveal the nearest site';
    default: return humanize(item.consumable?.effect);
  }
}

export function consumableTarget(item: Item) {
  switch (item.consumable?.effect) {
    case 'heal': return 'One party member';
    case 'coatPoison':
    case 'coatBurn':
    case 'coatBleed':
    case 'coatDazzle': return 'One party member’s current weapon';
    case 'identifyCurio': return 'One carried unidentified curio';
    case 'maskScent': return 'The party';
    default: return 'No separate target';
  }
}

export function consumableDuration(item: Item) {
  return item.consumable?.beneficialScalingField === 'timedDuration'
    ? `${humanize(item.consumable.potency)} turns`
    : 'No duration listed';
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
