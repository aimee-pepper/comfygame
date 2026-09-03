import { craftingSystems } from '@/lib/crafting';
import { serviceGuides } from '@/lib/services';

export type ActionLink = { label: string; href: string };

export type ActionReference = {
  id: string;
  slug: string;
  name: string;
  group: 'Writing' | 'World' | 'Combat' | 'Preparation and custody' | 'Research and Village' | 'Companions' | 'Current service' | 'Current station transaction';
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
    id: 'writing-place-mark', slug: 'place-mark', name: 'Place a mark', group: 'Writing', surface: 'Writing Desk · current Page grid',
    availability: 'Choose a current hand and ink, then select a legal Page position.',
    change: 'Places the selected authored mark on that Page; an unconnected mark remains its own incomplete request.',
    cost: 'The visible ink and Page state show the current cost.', persistence: 'The Page keeps the placed mark for the current draft until you change it.',
    unavailable: 'An illegal position or unavailable hand or ink does not place a substitute mark.', related: [{ label: 'World Writing', href: '/systems/world-writing' }, { label: 'Writing reference', href: '/systems/world-writing' }],
  },
  {
    id: 'writing-connect-mark', slug: 'connect-marks', name: 'Connect marks', group: 'Writing', surface: 'Writing Desk · current Page grid',
    availability: 'Select marks that the current Writing Desk allows to attach.',
    change: 'Connects the selected marks into the displayed request; it does not silently alter either mark’s meaning.',
    cost: 'No separate connection currency is published beyond the selected Page and ink state.', persistence: 'The current draft retains the shown connection until edited.',
    unavailable: 'Marks that cannot attach remain separate; a failed connection does not Bind a world.', related: [{ label: 'World Writing', href: '/systems/world-writing' }],
  },
  {
    id: 'writing-bind-world', slug: 'bind-world', name: 'Bind a world', group: 'Writing', surface: 'Writing Desk · review and Bind rail',
    availability: 'Review a complete current draft with its displayed Pages, connections, and required preparation.',
    change: 'Commits the shown Writing result and begins the current expedition route.',
    cost: 'The review names any current preparation or material use before Bind.', persistence: 'A completed Bind creates the current written-world run; Cancel leaves the draft available to edit.',
    unavailable: 'An incomplete or stale draft does not start a different world or consume an unshown input.', related: [{ label: 'World Writing', href: '/systems/world-writing' }, { label: 'Journey', href: '/journey' }],
  },
  {
    id: 'world-enter', slug: 'enter-world', name: 'Enter a world', group: 'World', surface: 'Arrival · Enter face',
    availability: 'A bound current world must be ready at its arrival screen.',
    change: 'Moves the party into that exact world at its entry portal.', cost: 'No separate entry currency is published.',
    persistence: 'The current run becomes the active expedition after the mounted result completes.',
    unavailable: 'A missing or stale arrival result does not enter another world.', related: [{ label: 'Exploration', href: '/systems/exploration' }, { label: 'Journey', href: '/journey' }],
  },
  {
    id: 'world-move', slug: 'move', name: 'Move', group: 'World', surface: 'World · directional controls',
    availability: 'Choose one currently legal direction on the mounted World controls.',
    change: 'Attempts one step and advances the world only when that exact movement is accepted.', cost: 'The destination’s visible movement cost and current world-turn effects apply.',
    persistence: 'A completed movement updates the active expedition position and current turn state.',
    unavailable: 'A blocked direction leaves the party in place; it does not move through a different face.', related: [{ label: 'Exploration', href: '/systems/exploration' }, { label: 'Terrain', href: '/terrain' }, { label: 'Flora', href: '/flora' }],
  },
  {
    id: 'world-look', slug: 'look', name: 'Look', group: 'World', surface: 'World · Look control and adjacent tile detail',
    availability: 'Arm Look and choose a revealed adjacent tile.',
    change: 'Shows the current tile’s disclosed ground, feature, movement, and entry information without moving the party.', cost: 'Look does not spend a world turn.',
    persistence: 'It changes the inspected detail, not the party position.',
    unavailable: 'An unrevealed or non-adjacent tile does not invent a site, plant, or danger fact.', related: [{ label: 'Sites and hazards', href: '/sites' }, { label: 'Conditions and effects', href: '/statuses' }],
  },
  {
    id: 'world-use-tile', slug: 'use-tile', name: 'Use Tile', group: 'World', surface: 'World · Use Tile control',
    availability: 'Stand on a tile with a current applicable action, such as a discovered site.',
    change: 'Opens or commits the exact action offered by that tile.', cost: 'The opened detail shows its turn, item, or resource cost before commit.',
    persistence: 'Only the completed tile action changes the active world or its holdings.',
    unavailable: 'An ordinary, changed, guarded, or depleted tile remains unavailable rather than performing a different action.', related: [{ label: 'Exploration', href: '/systems/exploration' }, { label: 'Site directory', href: '/sites' }],
  },
  {
    id: 'world-search-site', slug: 'search-site', name: 'Search a site', group: 'World', surface: 'World · Use Tile site detail',
    availability: 'Stand on a discovered, unguarded, unlooted site with search turns remaining.',
    change: 'Spends one search turn. The final current turn depletes the site and awards its disclosed contents.', cost: 'One world turn per Search.',
    persistence: 'The active world keeps the current search counter and depleted state.',
    unavailable: 'An encounter, guardian, changed tile, or depleted site does not consume a turn or award a substitute result.', related: [{ label: 'Sites and hazards', href: '/sites' }],
  },
  {
    id: 'world-return-home', slug: 'return-home', name: 'Return home', group: 'World', surface: 'World · Return control',
    availability: 'Use the current Return action when it is shown for the active expedition.',
    change: 'Leaves the current expedition through its mounted return and review flow.', cost: 'The current review names any retained or lost holdings; no separate unshown return cost is published.',
    persistence: 'The completed return uses the current expedition result before Home resumes.',
    unavailable: 'Cancel or an unavailable Return leaves the active world in its current state.', related: [{ label: 'Exploration', href: '/systems/exploration' }, { label: 'Journey', href: '/journey' }],
  },
  {
    id: 'combat-attack', slug: 'attack', name: 'Attack', group: 'Combat', surface: 'Encounter · acting party member action bar',
    availability: 'It is that party member’s turn and a living eligible foe can be selected.',
    change: 'Commits the shown direct attack against the confirmed foe.', cost: 'Uses the acting member’s current combat action.',
    persistence: 'The current encounter records its resulting health, status, and turn state.',
    unavailable: 'A changed or invalid target leaves the encounter unchanged rather than striking another foe.', related: [{ label: 'Combat', href: '/systems/combat' }, { label: 'Equipment', href: '/equipment' }],
  },
  {
    id: 'combat-use-technique', slug: 'use-technique', name: 'Use a technique', group: 'Combat', surface: 'Encounter · Techniques palette',
    availability: 'It is the owning actor’s turn and the selected technique is shown Ready with a valid target when needed.',
    change: 'Commits the exact technique result on its card.', cost: 'The listed cooldown or once-per-encounter limit applies; there is no separate technique currency.',
    persistence: 'The current encounter retains the resulting cooldown and any shown effect.',
    unavailable: 'A cooling technique or invalid target stays unavailable and does not substitute another action.', related: [{ label: 'Techniques and Gambits', href: '/techniques' }, { label: 'Combat', href: '/systems/combat' }],
  },
  {
    id: 'combat-use-item', slug: 'use-combat-item', name: 'Use a combat item', group: 'Combat', surface: 'Encounter · Item palette and target confirmation',
    availability: 'An eligible carried combat item and its exact legal ally or foe target are present.',
    change: 'Uses the selected item only after the shown target and confirmation complete.', cost: 'Consumes one carried item only on the committed use.',
    persistence: 'The encounter and active Field Kit retain the committed item result.',
    unavailable: 'A missing item or changed target leaves the item unspent and the encounter unchanged.', related: [{ label: 'Field supplies', href: '/consumables' }, { label: 'Conditions and effects', href: '/statuses' }],
  },
  {
    id: 'combat-withdraw', slug: 'withdraw', name: 'Withdraw', group: 'Combat', surface: 'Encounter · Withdraw confirmation',
    availability: 'Use the current Withdraw face and review its displayed Stability cost.',
    change: 'Completes the mounted withdrawal result from the current encounter.', cost: 'The displayed Stability cost.',
    persistence: 'The completed result updates the active expedition’s current encounter outcome.',
    unavailable: 'Cancel leaves the encounter in its current state.', related: [{ label: 'Combat', href: '/systems/combat' }, { label: 'Exploration', href: '/systems/exploration' }],
  },
  {
    id: 'custody-plan-field-kit', slug: 'plan-field-kit', name: 'Plan the Field Kit', group: 'Preparation and custody', surface: 'Storehouse · next Field Kit plan',
    availability: 'Choose eligible identified supplies with the visible capacity and stock.',
    change: 'Records the shown next-trip supply plan after confirmation.', cost: 'Uses the selected available holdings; the visible bin count is the current capacity.',
    persistence: 'The confirmed plan is used for the next departure.',
    unavailable: 'Changed stock or an over-capacity plan remains uncommitted.', related: [{ label: 'Field supplies', href: '/consumables' }, { label: 'Storehouse', href: '/buildings/storehouse' }],
  },
  {
    id: 'custody-transfer', slug: 'transfer-custody', name: 'Transfer custody', group: 'Preparation and custody', surface: 'Storehouse · selected item, material, or Waiting decision',
    availability: 'Select the exact shown holding and a current legal destination.',
    change: 'Moves only the confirmed holding to the displayed destination, or resolves its keep-or-replace decision.', cost: 'The current capacity and selected quantity control the transaction.',
    persistence: 'A completed transfer retains the holding at its new displayed location.',
    unavailable: 'No room, an unavailable selection, or Cancel leaves current holdings where they are.', related: [{ label: 'Inventory and custody', href: '/systems/inventory-custody' }, { label: 'Storehouse', href: '/buildings/storehouse' }],
  },
  {
    id: 'equipment-equip', slug: 'equip', name: 'Equip or take off gear', group: 'Preparation and custody', surface: 'Party · Gear detail',
    availability: 'At Home, choose a compatible physical piece that is available for the selected slot.',
    change: 'Equips the confirmed piece or removes the current one from that slot.', cost: 'No separate currency is published.',
    persistence: 'A completed change retains the shown piece and slot ownership for later preparation.',
    unavailable: 'Carried, incompatible, or otherwise unavailable gear keeps the current worn piece in place.', related: [{ label: 'Equipment', href: '/equipment' }, { label: 'Party, Gear and Gambits', href: '/systems/party-preparation' }],
  },
  {
    id: 'party-edit-gambit', slug: 'edit-gambit', name: 'Edit a Gambit', group: 'Preparation and custody', surface: 'Party · Gambit editor',
    availability: 'At Home, choose a party member with the displayed owned components and available rule context.',
    change: 'Adds, changes, reorders, enables, or removes only the selected prepared rule.', cost: 'No separate currency is published.',
    persistence: 'A completed edit retains the shown rule and priority for later combat.',
    unavailable: 'An unfinished or invalid edit leaves the existing list and priority unchanged.', related: [{ label: 'Techniques and Gambits', href: '/techniques' }, { label: 'Party, Gear and Gambits', href: '/systems/party-preparation' }],
  },
  {
    id: 'research-study', slug: 'study-research', name: 'Study research', group: 'Research and Village', surface: 'Research · selected node detail',
    availability: 'Choose a visible node after its listed earlier upgrades, station, readings, and current cost are ready.',
    change: 'Applies that node’s documented result once.', cost: 'The selected node’s displayed Essence and named resource cost.',
    persistence: 'A completed Study keeps the upgrade; it is not a repeating purchase.',
    unavailable: 'Missing requirements or a changed cost take no partial payment and leave Research unchanged.', related: [{ label: 'Research', href: '/research' }],
  },
  {
    id: 'village-build-foundation', slug: 'build-foundation', name: 'Build a foundation', group: 'Research and Village', surface: 'Village · selected building detail',
    availability: 'Choose a current building whose exact foundation requirements are ready.',
    change: 'Builds that current destination and opens its service or station route.', cost: 'The selected foundation’s displayed resources and other current requirements.',
    persistence: 'A completed foundation remains a current Village destination.',
    unavailable: 'Missing requirements or a changed quote leave the foundation unbuilt and inputs intact.', related: [{ label: 'Village', href: '/village' }],
  },
  {
    id: 'companion-attend', slug: 'attend-animal', name: 'Attend an animal', group: 'Companions', surface: 'Active world · animal interaction',
    availability: 'Recruit Sabine, build the Menagerie, and choose a visible eligible animal within two tiles but not immediately adjacent.',
    change: 'Creates the visible need for that exact animal’s trust route.', cost: 'Uses the current interaction; any required material sample is shown by that animal’s visible need.',
    persistence: 'Progress belongs to the exact attended animal and current expedition context.',
    unavailable: 'A pursuing, harmed, apex, rooted, adjacent, hidden, or distant animal does not accept attention.', related: [{ label: 'Animals and companionship', href: '/systems/animals-companionship' }, { label: 'Bestiary', href: '/bestiary' }],
  },
  {
    id: 'companion-join', slug: 'join-companion', name: 'Join with a companion', group: 'Companions', surface: 'Animal trust result · Join confirmation',
    availability: 'That exact animal’s visible trust requirement must be complete.',
    change: 'Adds the confirmed companion through the current placement result.', cost: 'Uses one current party place when the companion travels.',
    persistence: 'A completed join retains the companion and current placement result.',
    unavailable: 'A different animal, incomplete trust, or changed current encounter does not create a companion.', related: [{ label: 'Animals and companionship', href: '/systems/animals-companionship' }, { label: 'Party, Gear and Gambits', href: '/systems/party-preparation' }],
  },
];

const serviceActions: ActionReference[] = serviceGuides.map((service) => ({
  id: `service-${service.stationID}`, slug: `use-${service.slug}`, name: `Use ${service.name}`, group: 'Current service',
  surface: `${service.name} · selected entry`, availability: service.selection, change: service.result,
  cost: 'Review the current selected entry for its shown quantity, price, capacity, or other requirement before confirming.',
  persistence: 'Only the confirmed current service result changes the shown record, holding, placement, or reserve.',
  unavailable: 'A changed selection, unavailable holding, or Cancel leaves the current state unchanged.', related: service.relatedGuides,
}));

const stationActions: ActionReference[] = craftingSystems.map((system) => ({
  id: `station-${system.stationID}`, slug: `use-${system.slug}`, name: system.name, group: 'Current station transaction',
  surface: `${system.station} · selected recipe or transaction detail`, availability: system.access.join(' '), change: system.commitResult,
  cost: 'The visible recipe or transaction preview names its exact selected samples, scalar resources, Essence, Motes, or custody requirement.',
  persistence: 'Only the committed transaction retains its shown item, upgrade, fixture, or other result.',
  unavailable: 'A missing requirement, invalid selected input, stale preview, unavailable output room, or Cancel leaves current inputs and state unchanged.', related: [{ label: system.name, href: `/crafting/${system.slug}` }, { label: 'Crafting systems', href: '/crafting' }, { label: 'Resources', href: '/resources' }],
}));

export const actionReferences = [...coreActions, ...serviceActions, ...stationActions];
export const actionForSlug = (slug: string) => actionReferences.find((action) => action.slug === slug);
export const actionsForStation = (stationID: string) => actionReferences.filter((action) => action.id === `service-${stationID}` || action.id === `station-${stationID}`);
