import { craftingSystems } from '@/lib/crafting';
import { serviceGuides } from '@/lib/services';

export type ActionLink = { label: string; href: string };

export type ActionReference = {
  id: string;
  slug: string;
  name: string;
  group: 'Writing' | 'World' | 'Combat' | 'Preparation and storage' | 'Research and Village' | 'Companions' | 'Services' | 'Crafting stations';
  surface: string;
  availability: string;
  change: string;
  cost: string;
  persistence: string;
  unavailable: string;
  related: ActionLink[];
};

const coreActions: ActionReference[] = [
  {
    id: 'writing-place-mark', slug: 'place-mark', name: 'Place a mark', group: 'Writing', surface: 'Writing Desk · Page grid',
    availability: 'Choose an available hand and ink, then select an open position on the Page.',
    change: 'Places the selected mark on that Page. Until it is connected, the mark remains a separate part of the draft.',
    cost: 'The Page shows any ink this mark will use.', persistence: 'The mark remains on the draft until you move or remove it.',
    unavailable: 'An illegal position or unavailable hand or ink does not place a substitute mark.', related: [{ label: 'World Writing', href: '/systems/world-writing' }, { label: 'Writing reference', href: '/systems/world-writing' }],
  },
  {
    id: 'writing-connect-mark', slug: 'connect-marks', name: 'Connect marks', group: 'Writing', surface: 'Writing Desk · Page grid',
    availability: 'Select two marks that the Writing Desk allows to connect.',
    change: 'Connects the selected marks into the displayed request; it does not silently alter either mark’s meaning.',
    cost: 'Connecting marks has no separate cost beyond the Page and ink already shown.', persistence: 'The connection remains on the draft until you edit it.',
    unavailable: 'Marks that cannot attach remain separate; a failed connection does not Bind a world.', related: [{ label: 'World Writing', href: '/systems/world-writing' }],
  },
  {
    id: 'writing-bind-world', slug: 'bind-world', name: 'Bind a world', group: 'Writing', surface: 'Writing Desk · review and Bind rail',
    availability: 'Review a complete draft with its Pages, connections, and required preparation.',
    change: 'Creates the world described by the reviewed Page and begins the journey to it.',
    cost: 'The review names any ink, Page, or material that Binding will use.', persistence: 'A successful Bind creates a new written world; Cancel leaves the draft available to edit.',
    unavailable: 'An incomplete draft, or one that changed after its preview, does not start a world or consume a hidden ingredient.', related: [{ label: 'World Writing', href: '/systems/world-writing' }, { label: 'Journey', href: '/journey' }],
  },
  {
    id: 'world-enter', slug: 'enter-world', name: 'Enter a world', group: 'World', surface: 'Arrival · Enter face',
    availability: 'A newly bound world must be ready at its arrival screen.',
    change: 'Moves the party into the world shown on the arrival page, at its entry portal.', cost: 'Entering the world has no separate currency cost.',
    persistence: 'Entering makes that world your active expedition.',
    unavailable: 'If the arrival is missing or has changed, the game will not send you into a different world.', related: [{ label: 'Exploration', href: '/systems/exploration' }, { label: 'Journey', href: '/journey' }],
  },
  {
    id: 'world-move', slug: 'move', name: 'Move', group: 'World', surface: 'World · directional controls',
    availability: 'Choose a direction the World controls currently allow.',
    change: 'Moves the party one tile in that direction.', cost: 'The destination shows how many world turns it takes to enter and any visible effects that apply.',
    persistence: 'A successful step saves the party’s new position and world turn.',
    unavailable: 'A blocked direction leaves the party in place.', related: [{ label: 'Exploration', href: '/systems/exploration' }, { label: 'Terrain', href: '/terrain' }, { label: 'Flora', href: '/flora' }],
  },
  {
    id: 'world-look', slug: 'look', name: 'Look', group: 'World', surface: 'World · Look control and adjacent tile detail',
    availability: 'Arm Look and choose a revealed adjacent tile.',
    change: 'Shows the visible ground, feature, movement cost, and entry warning without moving the party.', cost: 'Look does not spend a world turn.',
    persistence: 'It changes the inspected detail, not the party position.',
    unavailable: 'An unrevealed or non-adjacent tile does not invent a site, plant, or danger fact.', related: [{ label: 'Sites and hazards', href: '/sites' }, { label: 'Conditions and effects', href: '/statuses' }],
  },
  {
    id: 'world-use-tile', slug: 'use-tile', name: 'Use Tile', group: 'World', surface: 'World · Use Tile control',
    availability: 'Stand on a tile with an available action, such as a discovered site.',
    change: 'Opens the action offered by that tile.', cost: 'The details show any world-turn, item, or resource cost before you confirm.',
    persistence: 'The world or your belongings change only after the action succeeds.',
    unavailable: 'An ordinary, changed, guarded, or depleted tile remains unavailable rather than performing a different action.', related: [{ label: 'Exploration', href: '/systems/exploration' }, { label: 'Site directory', href: '/sites' }],
  },
  {
    id: 'world-search-site', slug: 'search-site', name: 'Search a site', group: 'World', surface: 'World · Use Tile site detail',
    availability: 'Stand on a discovered, unguarded, unlooted site with search turns remaining.',
    change: 'Spends one search turn. The final turn depletes the site and awards the contents shown.', cost: 'One world turn per Search.',
    persistence: 'The world keeps the site’s remaining search turns and whether it has been depleted.',
    unavailable: 'An encounter, guardian, changed tile, or depleted site does not consume a turn or award a substitute result.', related: [{ label: 'Sites and hazards', href: '/sites' }],
  },
  {
    id: 'world-return-home', slug: 'return-home', name: 'Return home', group: 'World', surface: 'World · Return control',
    availability: 'Use Return when it appears during the active expedition.',
    change: 'Leaves the expedition and opens the return review.', cost: 'The review shows what came home and what was lost. Returning has no hidden extra cost.',
    persistence: 'Finishing the return review saves its result before Home resumes.',
    unavailable: 'Cancelling leaves the active world unchanged.', related: [{ label: 'Exploration', href: '/systems/exploration' }, { label: 'Journey', href: '/journey' }],
  },
  {
    id: 'combat-attack', slug: 'attack', name: 'Attack', group: 'Combat', surface: 'Encounter · acting party member action bar',
    availability: 'It is that party member’s turn and a living eligible foe can be selected.',
    change: 'Performs the shown direct attack against the chosen foe.', cost: 'Uses the acting person’s combat action for the turn.',
    persistence: 'The encounter saves the resulting health, conditions, and turn.',
    unavailable: 'A changed or invalid target leaves the encounter unchanged rather than striking another foe.', related: [{ label: 'Combat', href: '/systems/combat' }, { label: 'Equipment', href: '/equipment' }],
  },
  {
    id: 'combat-use-technique', slug: 'use-technique', name: 'Use a technique', group: 'Combat', surface: 'Encounter · Techniques palette',
    availability: 'It is the owning actor’s turn and the selected technique is shown Ready with a valid target when needed.',
    change: 'Performs the technique and applies the result shown on its card.', cost: 'The listed cooldown or once-per-encounter limit applies; there is no separate technique currency.',
    persistence: 'The encounter saves the resulting cooldown and any effect shown.',
    unavailable: 'A cooling technique or invalid target stays unavailable and does not substitute another action.', related: [{ label: 'Techniques and Gambits', href: '/techniques' }, { label: 'Combat', href: '/systems/combat' }],
  },
  {
    id: 'combat-use-item', slug: 'use-combat-item', name: 'Use a combat item', group: 'Combat', surface: 'Encounter · Item palette and target confirmation',
    availability: 'You have a suitable carried combat item and an eligible ally or foe to target.',
    change: 'Uses the selected item on the chosen target after you confirm.', cost: 'Consumes one carried item only after the use succeeds.',
    persistence: 'The encounter and Field Kit save the item’s result and new quantity.',
    unavailable: 'A missing item or changed target leaves the item unspent and the encounter unchanged.', related: [{ label: 'Field supplies', href: '/consumables' }, { label: 'Conditions and effects', href: '/statuses' }],
  },
  {
    id: 'combat-withdraw', slug: 'withdraw', name: 'Withdraw', group: 'Combat', surface: 'Encounter · Withdraw confirmation',
    availability: 'Choose Withdraw and review the Stability cost shown.',
    change: 'Leaves the encounter when the withdrawal succeeds.', cost: 'The displayed Stability cost.',
    persistence: 'The expedition saves the encounter as withdrawn.',
    unavailable: 'Cancel leaves the encounter unchanged.', related: [{ label: 'Combat', href: '/systems/combat' }, { label: 'Exploration', href: '/systems/exploration' }],
  },
  {
    id: 'custody-plan-field-kit', slug: 'plan-field-kit', name: 'Plan the Field Kit', group: 'Preparation and storage', surface: 'Storehouse · next Field Kit plan',
    availability: 'Choose identified supplies that fit within the visible capacity and available stock.',
    change: 'Records the shown next-trip supply plan after confirmation.', cost: 'Uses the selected available holdings; the visible bin count is the current capacity.',
    persistence: 'The confirmed plan is used for the next departure.',
    unavailable: 'If the stock has changed or the plan is over capacity, nothing moves until you review it again.', related: [{ label: 'Field supplies', href: '/consumables' }, { label: 'Storehouse', href: '/buildings/storehouse' }],
  },
  {
    id: 'custody-transfer', slug: 'transfer-custody', name: 'Move an item or material', group: 'Preparation and storage', surface: 'Storehouse · selected item, material, or Waiting decision',
    availability: 'Select an item or material and one of the destinations shown for it.',
    change: 'Moves only the chosen item or quantity to that destination, or completes its keep-or-replace decision.', cost: 'Available space and the quantity you choose control what can move.',
    persistence: 'A successful transfer saves the item or material in its new location.',
    unavailable: 'If there is no room, the selection is no longer available, or you cancel, everything stays where it is.', related: [{ label: 'Inventory and storage', href: '/systems/inventory-custody' }, { label: 'Storehouse', href: '/buildings/storehouse' }],
  },
  {
    id: 'equipment-equip', slug: 'equip', name: 'Equip or take off gear', group: 'Preparation and storage', surface: 'Party · Gear detail',
    availability: 'At Home, choose a compatible physical piece that is available for the selected slot.',
    change: 'Equips the chosen piece or removes the one currently worn in that slot.', cost: 'Equipping gear has no separate currency cost.',
    persistence: 'A successful change saves that piece in its new worn or stored location.',
    unavailable: 'Carried, incompatible, or otherwise unavailable gear keeps the current worn piece in place.', related: [{ label: 'Equipment', href: '/equipment' }, { label: 'Party, Gear and Gambits', href: '/systems/party-preparation' }],
  },
  {
    id: 'party-edit-gambit', slug: 'edit-gambit', name: 'Edit a Gambit', group: 'Preparation and storage', surface: 'Party · Gambit editor',
    availability: 'At Home, choose a party member with the displayed owned components and available rule context.',
    change: 'Adds, changes, reorders, enables, or removes only the selected prepared rule.', cost: 'Editing Gambits has no separate currency cost.',
    persistence: 'A completed edit retains the shown rule and priority for later combat.',
    unavailable: 'An unfinished or invalid edit leaves the existing list and priority unchanged.', related: [{ label: 'Techniques and Gambits', href: '/techniques' }, { label: 'Party, Gear and Gambits', href: '/systems/party-preparation' }],
  },
  {
    id: 'research-study', slug: 'study-research', name: 'Study research', group: 'Research and Village', surface: 'Research · selected node detail',
    availability: 'Choose a visible node after completing its earlier upgrades and any listed station, reading, or cost requirements.',
    change: 'Applies that node’s documented result once.', cost: 'The selected node’s displayed Essence and named resource cost.',
    persistence: 'A successful Study permanently keeps the upgrade; you do not buy it again.',
    unavailable: 'Missing requirements or a changed cost take no partial payment and leave Research unchanged.', related: [{ label: 'Research', href: '/research' }],
  },
  {
    id: 'village-build-foundation', slug: 'build-foundation', name: 'Build a foundation', group: 'Research and Village', surface: 'Village · selected building detail',
    availability: 'Choose an available building after meeting every foundation requirement shown.',
    change: 'Builds that Village destination and opens its service or station.', cost: 'The resources and any other requirements shown on the selected foundation.',
    persistence: 'A completed foundation remains available in the Village.',
    unavailable: 'Missing requirements or a changed preview leave the foundation unbuilt and its materials untouched.', related: [{ label: 'Village', href: '/village' }],
  },
  {
    id: 'companion-attend', slug: 'attend-animal', name: 'Attend an animal', group: 'Companions', surface: 'Active world · animal interaction',
    availability: 'Recruit Sabine, build the Menagerie, and choose a visible eligible animal within two tiles but not immediately adjacent.',
    change: 'Shows what that animal needs before it can trust the party.', cost: 'Any required material is shown by that animal’s visible need.',
    persistence: 'Trust progress belongs to the individual animal you attended during that expedition.',
    unavailable: 'A pursuing, harmed, apex, rooted, adjacent, hidden, or distant animal does not accept attention.', related: [{ label: 'Animals and companionship', href: '/systems/animals-companionship' }, { label: 'Bestiary', href: '/bestiary' }],
  },
  {
    id: 'companion-join', slug: 'join-companion', name: 'Join with a companion', group: 'Companions', surface: 'Animal trust result · Join confirmation',
    availability: 'Complete the visible trust requirement for that individual animal.',
    change: 'Adds the animal as a companion in the placement you confirm.', cost: 'A travelling companion uses one party place.',
    persistence: 'A successful join saves the companion and whether it is travelling or resting at Home.',
    unavailable: 'A different animal, incomplete trust, or changed encounter does not create a companion.', related: [{ label: 'Animals and companionship', href: '/systems/animals-companionship' }, { label: 'Party, Gear and Gambits', href: '/systems/party-preparation' }],
  },
];

const serviceActions: ActionReference[] = serviceGuides.map((service) => ({
  id: `service-${service.stationID}`, slug: `use-${service.slug}`, name: `Use ${service.name}`, group: 'Services',
  surface: `${service.name} · selected entry`, availability: service.selection, change: service.result,
  cost: 'Review the selected entry’s quantity, price, capacity, and any other requirement before confirming.',
  persistence: 'The record, item, placement, or stored materials change only after confirmation succeeds.',
  unavailable: 'A changed selection, unavailable item, or Cancel leaves everything unchanged.', related: service.relatedGuides,
}));

const stationActions: ActionReference[] = craftingSystems.map((system) => ({
  id: `station-${system.stationID}`, slug: `use-${system.slug}`, name: system.name, group: 'Crafting stations',
  surface: `${system.station} · selected recipe or preparation`, availability: system.access.join(' '), change: system.commitResult,
  cost: 'The preview lists the selected materials, counted resources, Essence, Motes, and any storage requirement.',
  persistence: 'Only a successful confirmation saves the shown item, upgrade, fixture, or other result.',
  unavailable: 'If a requirement is missing, a material is unsuitable, the preview has changed, there is no room, or you cancel, nothing is spent.', related: [{ label: system.name, href: `/crafting/${system.slug}` }, { label: 'Crafting systems', href: '/crafting' }, { label: 'Resources', href: '/resources' }],
}));

export const actionReferences = [...coreActions, ...serviceActions, ...stationActions];
export const actionForSlug = (slug: string) => actionReferences.find((action) => action.slug === slug);
export const actionsForStation = (stationID: string) => actionReferences.filter((action) => action.id === `service-${stationID}` || action.id === `station-${stationID}`);
