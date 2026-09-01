import { content } from '@/lib/content';

type ResourceHost = {
  resourceID: string;
  description: string;
};

const conditionCopy: Record<string, string> = {
  illumination: 'Illumination describes the brightest and darkest parts of the world cycle, the light present, and whether it changes. It affects visibility, day and night, plant metabolism, and the senses useful to local creatures.',
  thermal: 'Thermal describes temperature and how far it swings. Cold can freeze surface water into passable ice; extreme heat can favour sand, ash, and heat-shaped life. A hot world is not automatically molten.',
  hydrology: 'Hydrology describes how much water exists, its form, and how widely it spreads. Standing water forms connected basins, flowing water forms channels, frozen water forms ice fields, and airborne water changes the atmosphere without painting lakes on the ground.',
  substrate: 'Substrate describes what the world is physically made of and what it may hold. Hard, ductile, and volatile forms influence Stone, Soil, Sand, Rubble, and Ash regions and where mineral deposits can honestly occur.',
  relief: 'Relief describes elevation, broken ground, and openness. It shapes slopes, sightlines, chokepoints, and Chasms. Elevation is separate from ground material: Stone, Soil, or Sand can all sit high or low.',
  vitality: 'Vitality describes how much life a world can support, how clustered it is, and how deep its food web can grow. It shapes Flora productivity and the creature ecology supported by that producer base.',
  atmosphere: 'Atmosphere describes the density, movement, and clarity of the air. It shapes wind, haze, and which forms of life and sensory evidence are useful. A named source can have its own disclosed consequence; Atmosphere alone does not predict an unseen field.',
  cycle: 'Cycle describes how long repeating changes take and how reliably they return. Bookbinder worlds advance when you take actions; Cycle never turns real waiting or a wall-clock timer into gameplay progress.',
};

export const worldConditions = content.pressureTargets.map((target) => ({
  ...target,
  slug: target.id,
  detail: conditionCopy[target.id] ?? target.blurb,
}));

const terrainVisuals = new Map(content.terrain.map((terrain) => [terrain.name, terrain.assetURL]));

export const terrainProfiles = [
  { id: 'stone', slug: 'stone', name: 'Stone', movement: 'Passable hard ground.', sight: 'Open sight.', host: 'Common host for mineral seams.', resourceIDs: ['rubble', 'ore', 'copper', 'silver', 'gold', 'quartz'] },
  { id: 'soil', slug: 'soil', name: 'Soil', movement: 'Passable earth.', sight: 'Open sight unless another revealed feature says otherwise.', host: 'Wet low banks can host Clay or Salt and can support Flora.', resourceIDs: ['clay', 'salt'] },
  { id: 'sand', slug: 'sand', name: 'Sand', movement: 'Passable loose ground.', sight: 'Open sight.', host: 'Wet low margins can host Salt.', resourceIDs: ['salt'] },
  { id: 'ice', slug: 'ice', name: 'Ice', movement: 'Passable frozen water.', sight: 'Open sight.', host: 'Ice is not Snow and is not a harvestable deposit.', resourceIDs: [] },
  { id: 'ash', slug: 'ash', name: 'Ash', movement: 'Passable volatile ground.', sight: 'Open sight.', host: 'Can host Mercury and volcanic minerals such as Obsidian or Sulfur.', resourceIDs: ['mercury', 'obsidian', 'sulfur'] },
  { id: 'water', slug: 'shallow-water', name: 'Shallow Water', movement: 'Passable liquid water.', sight: 'Open sight.', host: 'Shapes wet margins and shore habitat; it is not a mineral node.', resourceIDs: [] },
  { id: 'deepWater', slug: 'deep-water', name: 'Deep Water', movement: 'Impassable depth.', sight: 'Open sight.', host: 'Supports aquatic habitat but cannot be crossed as ordinary ground.', resourceIDs: [] },
  { id: 'rubble', slug: 'rubble', name: 'Rubble', movement: 'Passable broken hard ground.', sight: 'Blocks sight.', host: 'Common host for mineral seams.', resourceIDs: ['rubble', 'ore', 'copper', 'silver', 'gold', 'quartz'] },
  { id: 'mud', slug: 'mud', name: 'Mud', movement: 'Passable wet ground that takes an extra world turn to enter.', sight: 'Does not itself block sight.', host: 'Marks liquid-water margins.', resourceIDs: [] },
  { id: 'growth', slug: 'tall-growth', name: 'Tall Growth', movement: 'Passable Flora that takes an extra world turn to enter.', sight: 'Blocks sight.', host: 'May carry a Flora harvest; inspect the exact revealed plant for its practical yield.', resourceIDs: ['timber', 'fibre', 'pulp', 'resin', 'toxin', 'spore', 'reagent'] },
  { id: 'groundcover', slug: 'ground-cover', name: 'Ground Cover', movement: 'Passable low Flora with ordinary entry cost.', sight: 'Open sight.', host: 'May carry a Flora harvest; inspect the exact revealed plant for its practical yield.', resourceIDs: ['timber', 'fibre', 'pulp', 'resin', 'toxin', 'spore', 'reagent'] },
  { id: 'chasm', slug: 'chasm', name: 'Chasm', movement: 'Impassable absence of ground.', sight: 'Open across the missing ground where the current map permits it.', host: 'Nearby hard ground can host Adamant, Obsidian, Sulfur, or Rift-glass.', resourceIDs: ['adamant', 'obsidian', 'sulfur', 'rift_glass'] },
].map((terrain) => ({ ...terrain, assetURL: terrainVisuals.get(terrain.id) ?? null }));

export const floraHarvestProfiles = [
  { slug: 'chemosynthetic', name: 'Chemosynthetic Flora', resultID: 'reagent', summary: 'The exact generated plant yields Reagent.' },
  { slug: 'chemically-productive', name: 'Chemically productive Flora', resultID: 'toxin', summary: 'The exact generated plant yields Toxin.' },
  { slug: 'fungal', name: 'Fungal Flora', resultID: 'spore', summary: 'The exact generated plant yields Spore.' },
  { slug: 'tall-woody', name: 'Tall woody Flora', resultID: 'timber', summary: 'The exact generated plant yields Timber.' },
  { slug: 'short-woody-or-fibrous', name: 'Short woody or fibrous Flora', resultID: 'fiber', summary: 'The exact generated plant yields Fibre.' },
  { slug: 'fleshy', name: 'Fleshy Flora', resultID: 'pulp', summary: 'The exact generated plant yields Pulp.' },
  { slug: 'defended-photosynthetic-woody', name: 'Defended photosynthetic woody Flora', resultID: 'resin', summary: 'The exact generated plant can add Resin beside its primary woody harvest.' },
];

export function conditionForSlug(slug: string) {
  return worldConditions.find((condition) => condition.slug === slug) ?? null;
}

export function terrainForSlug(slug: string) {
  return terrainProfiles.find((terrain) => terrain.slug === slug) ?? null;
}

export function floraForSlug(slug: string) {
  return floraHarvestProfiles.find((flora) => flora.slug === slug) ?? null;
}

export function resourcesFor(ids: string[]) {
  return ids.map((id) => content.resources.find((resource) => resource.id === id)).filter((resource): resource is (typeof content.resources)[number] => Boolean(resource));
}

export const resourceHostingGroups: Array<{ name: string; summary: string; resources: ResourceHost[] }> = [
  { name: 'Hard-ground minerals', summary: 'Hard mineral seams occur in Stone or Rubble. Mercury can also occur in Ash.', resources: [{ resourceID: 'rubble', description: 'Stone or Rubble seam.' }, { resourceID: 'ore', description: 'Stone or Rubble seam.' }, { resourceID: 'copper', description: 'Stone or Rubble seam.' }, { resourceID: 'silver', description: 'Stone or Rubble seam.' }, { resourceID: 'gold', description: 'Stone or Rubble seam.' }, { resourceID: 'quartz', description: 'Stone or Rubble seam.' }, { resourceID: 'mercury', description: 'Ash, Stone, or Rubble seam.' }] },
  { name: 'Wet-margin materials', summary: 'These terrain relationships do not guarantee a reward from every pond or shore.', resources: [{ resourceID: 'clay', description: 'Low Soil beside liquid Water, Deep Water, or Mud.' }, { resourceID: 'salt', description: 'Low Soil or Sand beside liquid Water, Deep Water, or Mud.' }] },
  { name: 'Volatile and broken-ground minerals', summary: 'A valid reachable host still controls the final placement.', resources: [{ resourceID: 'obsidian', description: 'Ash, or hard ground beside Ash or a Chasm.' }, { resourceID: 'sulfur', description: 'Ash, or hard ground beside Ash or a Chasm.' }, { resourceID: 'adamant', description: 'Elevated hard ground or a hard Chasm margin.' }, { resourceID: 'rift_glass', description: 'Passable Stone, Rubble, or Ash beside a Chasm.' }] },
];
