import { content, type Station } from '@/lib/content';
import { craftingSystems, recipesFor } from '@/lib/crafting';
import { serviceForStation } from '@/lib/services';

const playerDescriptions: Record<string, string> = {
  writing_desk: 'Write Pages, review the worlds they may create, and Bind when you are ready to travel.',
  storehouse: 'Store resources, materials, and items brought home from expeditions, identify curios, and prepare the next Field Kit.',
  party: 'Choose the travelling party, equip each person, and arrange their Gambits before an expedition.',
  essence_spring: 'Refine Raw Essence into spendable Essence, improve return rewards, and unlearn combat techniques.',
  library: 'Read recovered books, notes, known writing symbols, creature records, and the history of visited worlds.',
  trading_post: 'Buy from Vance’s changing stock and sell eligible identified goods and materials.',
  recycler: 'Dismantle eligible gear after reviewing exactly which materials it will return.',
  blacksmith: 'Make metal weapons with Halloway and, once Reforge is complete, improve one chosen piece of gear.',
  tannery: 'Use flexible animal and plant materials for armour, clothing, and carrying upgrades.',
  bowyer: 'Make bows and other long-reaching weapons from suitable shafts, fibres, and bindings.',
  armoury: 'Make and rebuild protective equipment from materials chosen for the job.',
  weaponsmith: 'Make advanced weapons whose materials support their reach, motion, and impact.',
  scriptorium: 'Learn compact writing methods and prepare the inks used to shape bound worlds.',
  firepit: 'Spend time with people at the Cottage and manage the relationships you have built.',
  bestiary: 'Review the creatures you have encountered and compare known examples of each kind.',
  survey_post: 'Learn and improve field instruments that reveal more about the world around your party.',
  apothecary: 'Prepare remedies and field supplies from materials gathered in generated worlds.',
  reliquary: 'Review discovered sites, their history, and what your party has learned from them.',
  wayfarers_table: 'Improve packing and field knowledge so expeditions can recognise and bring home more natural resources.',
  distillery: 'Distil gathered materials directly into Heat, Caustic, or Light Cores. Some intended Core uses are still planned.',
  channelworks: 'Turn a Heat Core into a stored Heat Conduit Fixture. Caustic and Light equipment are planned.',
  anchorage: 'Anchor a generated world so it remains available to revisit through the Atlas.',
  menagerie: 'Planned: care for eligible animals, build trust, and choose companions for the travelling party.',
};

const playerBuildDescriptions: Record<string, string> = {
  trading_post: 'Build Vance a sturdy trading table and ledger space for buying, selling, and changing stock.',
  recycler: 'Build Noll a sorting bench where eligible gear can be dismantled without losing track of its recoverable materials.',
  blacksmith: 'Build Halloway a sheltered forge with the iron and fibre needed to begin work.',
  tannery: 'Build Corrin a clean workroom with beams, fibre, and salt for preparing flexible materials.',
  bowyer: 'Build Fen a workshop for straight shafts, patient fibre work, and resin-bound weapons.',
  armoury: 'Build Bracken a workshop for fitting iron, clay, copper, and other defensive materials into protective gear.',
  weaponsmith: 'Build Maud a workshop for testing advanced weapons with carefully measured metalwork.',
  scriptorium: 'Build Isolde a well-lit writing room with a steady worktable.',
  survey_post: 'Build Mara a level, wind-sheltered post with a clear view of the horizon.',
  apothecary: 'Build Nessa a clean room with heat-safe vessels and shelves for gathered ingredients. Completion teaches Lesser Salve.',
  reliquary: 'Build Edren shelves and broad tables for studying recovered site records and fragments.',
  wayfarers_table: 'Build Sela a shared table for field guides, samples, and careful packing; it is a workspace, not a shop.',
  distillery: 'Build Auber clear measuring vessels and storage for distilled residues and completed Cores.',
  channelworks: 'Build Oda a contained workbench for fitting active Cores into combat equipment safely.',
  anchorage: 'Build Tovin a quiet Atlas room and a strong frame for keeping an anchored world reachable.',
};

export const villageBuildings = [...content.stations, ...content.scheduledStations].map((building) => ({
  ...building,
  blurb: playerDescriptions[building.id] ?? building.blurb,
  buildBlurb: playerBuildDescriptions[building.id] ?? building.buildBlurb,
}));

export function buildingForSlug(slug: string) {
  return villageBuildings.find((building) => building.slug === slug);
}

export function buildingStatus(building: Station) {
  return building.status === 'implemented' ? 'Available now' : 'Planned';
}

export function villageLocation(location: string) {
  return location.replace(/^Binder House\b/, 'The Cottage');
}

export function systemsForBuilding(building: Station) {
  return craftingSystems.filter((system) => system.stationID === building.id);
}

export function buildingActions(building: Station) {
  const service = serviceForStation(building.id);
  const systems = systemsForBuilding(building);
  const recipes = systems.flatMap((system) => recipesFor(system.slug));
  return { service, systems, recipes };
}
