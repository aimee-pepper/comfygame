import assert from 'node:assert/strict';
import { access, readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = (relative) => readFile(path.join(root, relative), 'utf8');

test('World Writing teaches the authored player order', async () => {
  const source = await read('app/systems/world-writing/page.tsx');
  const titles = [
    'Choose a hand',
    'Choose ink',
    'Place and connect',
    'Review and Bind',
  ];
  const positions = titles.map((title) => source.indexOf(title));
  assert.ok(positions.every((position) => position >= 0));
  assert.deepEqual(
    [...positions].sort((a, b) => a - b),
    positions,
  );
  assert.match(source, /writing-visual-strip/);
  assert.match(source, /content\.writingVisuals/);
});

test('World Writing reference keeps current vocabulary, connection, compound, and prepared-ink facts player-facing', async () => {
  const writing = await read('app/systems/world-writing/page.tsx');
  assert.match(writing, /eight current Subjects/);
  assert.match(writing, /only Focuses that can attach to it/);
  assert.match(writing, /Connect a readable request/);
  assert.match(writing, /unconnected mark is not treated as the same request/);
  assert.match(writing, /My Runebook/);
  assert.match(writing, /Copper supplies Cyan, Ichor Magenta, Sulfur Yellow, and Obsidian Depth/);
  assert.match(writing, /12-application vial/);
  assert.match(writing, /changes a Focus’s authored colour, not its meaning/);
  assert.match(writing, /\/crafting\/writing-ink/);
  assert.match(writing, /\/resources/);
});

test('player reference indexes link to individual pages', async () => {
  for (const relative of [
    'app/resources/page.tsx',
    'app/equipment/page.tsx',
    'app/places/page.tsx',
  ]) {
    const source = await read(relative);
    assert.match(source, /<table>/);
    assert.match(source, /<Link/);
  }
  const people = await read('app/people/page.tsx');
  assert.match(people, /people-directory/);
  assert.match(people, /<Link/);
  for (const relative of [
    'app/resources/[slug]/page.tsx',
    'app/equipment/[slug]/page.tsx',
    'app/people/[slug]/page.tsx',
    'app/places/[slug]/page.tsx',
  ]) {
    await access(path.join(root, relative));
  }
});

test('Bestiary publishes stable named encounter profiles without claiming save discovery or individual trust', async () => {
  await access(path.join(root, 'app/bestiary/[slug]/page.tsx'));
  const index = await read('app/bestiary/page.tsx');
  const detail = await read('app/bestiary/[slug]/page.tsx');
  const snapshot = JSON.parse(await read('data/player-content.json'));
  assert.equal(snapshot.creatures.length, 3);
  assert.match(index, /never marks a creature as discovered for your own save/);
  assert.match(index, /does not promise that a named encounter profile is tameable/);
  assert.match(detail, /does not promise companionship or disclose any individual’s trust state/);
  assert.match(detail, /No separate fixed status or drop is published for this profile/);
  assert.ok(snapshot.creatures.every((entry) => entry.slug && entry.name));
});

test('site directory keeps current conditions, disclosed results, and depletion separate from world discovery', async () => {
  await access(path.join(root, 'app/sites/page.tsx'));
  await access(path.join(root, 'app/sites/[slug]/page.tsx'));
  const directory = await read('app/sites/page.tsx');
  const detail = await read('app/sites/[slug]/page.tsx');
  const guide = await read('app/systems/sites-hazards/page.tsx');
  const snapshot = JSON.parse(await read('data/player-content.json'));
  assert.equal(snapshot.sites.length, 9);
  assert.match(directory, /never promises an undiscovered site in a particular world/);
  assert.match(detail, /does not reveal whether it was rolled into an undiscovered world/);
  assert.match(detail, /remains unavailable rather than silently awarding a replacement result/);
  assert.match(guide, /Open the full site directory/);
  assert.match(guide, /disclosedResult/);
});

test('Village directory separates live buildings from scheduled entries and gives each a semantic route', async () => {
  await access(path.join(root, 'app/village/page.tsx'));
  await access(path.join(root, 'app/buildings/[slug]/page.tsx'));
  const directory = await read('app/village/page.tsx');
  const detail = await read('app/buildings/[slug]/page.tsx');
  const snapshot = JSON.parse(await read('data/player-content.json'));
  assert.equal(snapshot.stations.length, 22);
  assert.equal(snapshot.scheduledStations.length, 1);
  assert.match(directory, /buildingStatus/);
  assert.match(directory, /Scheduled, not live/);
  assert.match(directory, /No live action or recipe is published/);
  assert.match(detail, /This entry is not a live player route/);
  assert.match(detail, /Exact construction/);
  assert.match(detail, /Related materials and next steps/);
});

test('Village building routes are discoverable from player navigation and material workflows', async () => {
  const sources = await Promise.all([
    'components/site-frame.tsx',
    'app/search/page.tsx',
    'app/glossary/page.tsx',
    'app/systems/page.tsx',
    'app/resources/progression/page.tsx',
    'app/resources/page.tsx',
    'app/resources/[slug]/page.tsx',
    'app/crafting/page.tsx',
    'app/crafting/[slug]/page.tsx',
  ].map(read));
  for (const source of sources) assert.match(source, /\/village|\/buildings\//);
  assert.match(sources[1], /Scheduled building/);
  assert.match(sources[4], /Browse Village buildings/);
  assert.match(sources[5], /\/buildings\/\$\{station\.slug\}/);
  assert.match(sources[7], /Village buildings/);
});

test('world reference publishes current terrain, pressure, resource-host, and harvest facts without promising hidden map results', async () => {
  for (const relative of [
    'app/world/page.tsx',
    'app/world/conditions/[slug]/page.tsx',
    'app/terrain/page.tsx',
    'app/terrain/[slug]/page.tsx',
    'app/flora/page.tsx',
    'app/flora/[slug]/page.tsx',
  ]) await access(path.join(root, relative));
  const reference = await read('lib/world-reference.ts');
  const world = await read('app/world/page.tsx');
  const flora = await read('app/flora/page.tsx');
  const snapshot = JSON.parse(await read('data/player-content.json'));
  assert.equal(snapshot.pressureTargets.length, 8);
  assert.equal(snapshot.terrain.length, 13);
  assert.match(reference, /Shallow Water/);
  assert.match(reference, /Deep Water/);
  assert.match(reference, /Tall Growth/);
  assert.match(reference, /resourceHostingGroups/);
  assert.match(reference, /Rift-glass/);
  assert.match(world, /rather than one guaranteed tile, plant, deposit, site, or animal/);
  assert.match(flora, /never predicts an unseen plant/);
});

test('item details link published recipes and resources without guessing absent acquisition routes', async () => {
  const routes = await read('components/item-crafting-routes.tsx');
  const itemDetail = await read('app/items/[slug]/page.tsx');
  const equipmentDetail = await read('app/equipment/[slug]/page.tsx');
  const craftingGuide = await read('app/systems/crafting/page.tsx');
  assert.match(routes, /Current acquisition/);
  assert.match(routes, /No current station preparation or construction recipe is published/);
  assert.match(routes, /Related resources/);
  assert.match(itemDetail, /ItemCraftingRoutes/);
  assert.match(equipmentDetail, /ItemCraftingRoutes/);
  assert.match(craftingGuide, /Instruments and prepared ink/);
  assert.match(craftingGuide, /writing-ink/);
});

test('Research directory provides stable semantic node routes with complete current node facts', async () => {
  await access(path.join(root, 'app/research/page.tsx'));
  await access(path.join(root, 'app/research/[slug]/page.tsx'));
  const directory = await read('app/research/page.tsx');
  const detail = await read('app/research/[slug]/page.tsx');
  const guide = await read('app/systems/research/page.tsx');
  const helpers = await read('lib/research.ts');
  assert.match(directory, /Research directory/);
  assert.match(directory, /Base cost/);
  assert.match(directory, /Ready when/);
  assert.match(detail, /Current node details/);
  assert.match(detail, /Bundled construction/);
  assert.match(detail, /Study and retain/);
  assert.match(detail, /\/services\/library/);
  assert.match(guide, /Open the Research directory/);
  assert.match(helpers, /researchNodeSlug/);
  assert.match(helpers, /branch\?\.name/);
  assert.match(helpers, /slugify\(node\.name\)/);
});

test('conditions reference separates the four encounter afflictions from current field effects', async () => {
  await access(path.join(root, 'app/statuses/page.tsx'));
  await access(path.join(root, 'app/statuses/[slug]/page.tsx'));
  const reference = await read('lib/status-reference.ts');
  const directory = await read('app/statuses/page.tsx');
  const detail = await read('app/statuses/[slug]/page.tsx');
  for (const stableID of ['affliction-burn', 'affliction-poison', 'affliction-dazzle', 'affliction-bleed', 'world-flora-poison', 'world-scent-mask', 'guard-stonebark']) assert.match(reference, new RegExp(stableID));
  assert.match(reference, /Combat Poison is distinct from poison left by chemical flora/);
  assert.match(reference, /Quench does not clear Bleed/);
  assert.match(reference, /does not hide creatures or affect apexes/);
  assert.match(directory, /Conditions and effects/);
  assert.match(directory, /Encounter afflictions/);
  assert.match(detail, /Keep the boundary clear/);
  assert.match(detail, /\/items\/\$\{item\.slug\}/);
});

test('technique reference gives each current technique and Gambit component a stable player route', async () => {
  await access(path.join(root, 'app/techniques/page.tsx'));
  await access(path.join(root, 'app/techniques/[slug]/page.tsx'));
  const reference = await read('lib/technique-reference.ts');
  const directory = await read('app/techniques/page.tsx');
  const detail = await read('app/techniques/[slug]/page.tsx');
  const snapshot = JSON.parse(await read('data/player-content.json'));
  assert.match(reference, /technique-\$\{slugify\(technique\.name\)\}/);
  assert.match(reference, /gambit-\$\{component\.kind\}/);
  assert.match(reference, /There is no separate technique currency/);
  assert.match(reference, /the next enabled rule can be considered/);
  assert.match(directory, /Techniques and Gambits/);
  assert.match(directory, /Gambit action/);
  assert.match(detail, /Source or grant/);
  assert.match(detail, /Costs, cooldowns, and limits/);
  assert.equal(snapshot.combatTechniques.length, 25);
  assert.equal(snapshot.gambitComponents.length, 27);
});

test('conditions and techniques are discoverable through combat, preparation, equipment, field supplies, search, and glossary', async () => {
  const sources = await Promise.all([
    'components/site-frame.tsx', 'app/search/page.tsx', 'app/glossary/page.tsx',
    'app/systems/combat/page.tsx', 'app/systems/party-preparation/page.tsx',
    'app/equipment/page.tsx', 'app/equipment/[slug]/page.tsx',
    'app/systems/field-supplies/page.tsx', 'app/systems/combat-techniques-gambits/page.tsx',
  ].map(read));
  for (const source of sources) assert.match(source, /\/statuses|\/techniques/);
  assert.match(sources[1], /label: 'Conditions and effects'/);
  assert.match(sources[1], /label: 'Techniques and Gambits'/);
  assert.match(sources[2], /Combat reference shortcuts/);
  assert.match(sources[7], /\/statuses\/scent-mask/);
});

test('action reference keeps current player actions, costs, results, and unavailable states together', async () => {
  await access(path.join(root, 'app/actions/page.tsx'));
  await access(path.join(root, 'app/actions/[slug]/page.tsx'));
  const reference = await read('lib/action-reference.ts');
  const directory = await read('app/actions/page.tsx');
  const detail = await read('app/actions/[slug]/page.tsx');
  for (const stableID of ['writing-bind-world', 'world-move', 'world-search-site', 'combat-attack', 'custody-transfer', 'research-study', 'companion-attend']) assert.match(reference, new RegExp(stableID));
  assert.match(reference, /craftingSystems\.map/);
  assert.match(reference, /serviceGuides\.map/);
  assert.match(directory, /Action reference/);
  assert.match(directory, /Current station transaction/);
  assert.match(detail, /Available when/);
  assert.match(detail, /When it cannot complete/);
});

test('equipment routes retain slot, recipe, frozen-piece and custody guidance', async () => {
  const index = await read('app/equipment/page.tsx');
  const detail = await read('app/equipment/[slug]/page.tsx');
  assert.match(index, /Current combat facts/);
  assert.match(index, /Current recipe route/);
  assert.match(index, /No current recipe published/);
  assert.match(index, /Worn by another person/);
  assert.match(detail, /frozen piece profile/);
  assert.match(detail, /Reforge rank and provenance/);
  assert.match(detail, /same-slot swap/);
  assert.match(detail, /carried in the active world/);
  assert.match(detail, /\/crafting\/blacksmith/);
  assert.match(detail, /\/crafting\/armoury/);
});

test('consumable routes keep current effect, target, preparation, carrying, and committed-use facts together', async () => {
  const index = await read('app/consumables/page.tsx');
  const detail = await read('app/items/[slug]/page.tsx');
  const supplies = await read('app/systems/field-supplies/page.tsx');
  const contentSource = await read('lib/content.ts');
  assert.match(index, /Current recipe route/);
  assert.match(index, /Carry and use/);
  assert.match(index, /Target/);
  assert.match(detail, /Field Kit and carrying/);
  assert.match(detail, /Commit the shown use/);
  assert.match(detail, /\/systems\/field-supplies/);
  assert.match(supplies, /timed effect/);
  assert.match(supplies, /remaining turns/);
  assert.match(contentSource, /function consumableEffect/);
  assert.match(contentSource, /function consumableTarget/);
  assert.match(contentSource, /function consumableDuration/);
});

test('curio routes explain recognition and custody without exposing an unknown result', async () => {
  const index = await read('app/curios/page.tsx');
  const detail = await read('app/items/[slug]/page.tsx');
  assert.match(index, /Keep unknown results unknown/);
  assert.match(index, /study one safely at Home/);
  assert.match(index, /Current route/);
  assert.match(index, /Identified and transferable/);
  assert.match(detail, /Identification and knowledge/);
  assert.match(detail, /identified with Solvent while carried/);
  assert.match(detail, /does not treat this object as recyclable gear/);
  assert.match(detail, /\/systems\/knowledge-records/);
  assert.match(detail, /\/services\/storehouse/);
  assert.match(detail, /\/services\/recycler/);
  assert.match(detail, /\/services\/trading-post/);
});

test('player navigation excludes internal wiki architecture', async () => {
  const source = `${await read('components/site-frame.tsx')}\n${await read('app/page.tsx')}\n${await read('app/people/page.tsx')}`;
  for (const forbidden of [
    'Visual Assets',
    'Decisions / History',
    'Roadmap',
    'Stable ID',
    'Source path',
    'Provenance',
  ]) {
    assert.equal(source.includes(forbidden), false, forbidden);
  }
});

test('sanitized player snapshot has useful implemented coverage and inline visuals', async () => {
  const content = JSON.parse(await read('data/player-content.json'));
  assert.equal(content.resources.length, 23);
  assert.equal(content.items.length, 103);
  assert.equal(content.travellers.length, 8);
  assert.equal(
    content.resources.find((resource) => resource.id === 'rubble')?.acquisition,
    'Rank-0 mineral node; hard Substrate/Relief; staple trade',
  );
  for (const resource of content.resources) {
    assert.ok(resource.consumerAuthority, `${resource.id} consumer authority`);
    assert.ok(resource.consumerAuthority.acquisition, `${resource.id} acquisition`);
    assert.ok(Array.isArray(resource.consumerAuthority.buildingConsumers));
    assert.ok(Array.isArray(resource.consumerAuthority.recipeConsumers));
    assert.ok(Array.isArray(resource.consumerAuthority.otherConsumers));
  }
  assert.equal(
    content.resources.find((resource) => resource.id === 'mote')?.tradeStatus,
    'Reality currency · not traded',
  );
  assert.equal(content.stations.length, 22);
  assert.ok(content.resources.some((entry) => entry.assetURL));
  assert.ok(content.items.some((entry) => entry.assetURL));
  assert.ok(content.terrain.length > 0);
  assert.ok(content.writingAssetURL);
  await access(path.join(root, 'public', content.writingAssetURL));
  assert.deepEqual(
    content.writingVisuals.map((visual) => visual.id),
    ['tool', 'mark', 'link'],
  );
  for (const visual of content.writingVisuals) {
    assert.match(visual.assetURL, /^\/game-assets\/writing\//);
    await access(path.join(root, 'public', visual.assetURL));
  }
});

test('PlayerWiki remains a separate application from the internal GameWiki', async () => {
  const readme = await read('README.md');
  assert.match(readme, /separate from `GameWiki`/);
  assert.match(readme, /player-facing/);
});

test('crafting has a linked system index and complete resource cross-reference surfaces', async () => {
  await access(path.join(root, 'app/crafting/page.tsx'));
  await access(path.join(root, 'app/crafting/[slug]/page.tsx'));
  const crafting = await read('lib/crafting.ts');
  for (const system of [
    'apothecary',
    'blacksmith',
    'tannery',
    'bowyer',
    'weaponsmith',
    'armoury',
    'instruments',
    'distillery',
    'channelworks',
    'anchorage',
    'refinery',
    'writing-ink',
  ]) {
    assert.match(crafting, new RegExp(`slug: '${system}'`));
  }
  const resourceIndex = await read('app/resources/page.tsx');
  assert.match(resourceIndex, /Current recipe and service uses/);
  assert.match(resourceIndex, /consumerAuthority\.recipeConsumers/);
  assert.match(resourceIndex, /consumerAuthority\.otherConsumers/);
  assert.match(resourceIndex, /Building material\?/);
  assert.match(resourceIndex, /How obtained/);
  assert.match(resourceIndex, /Trade status/);
  const resourceDetail = await read('app/resources/[slug]/page.tsx');
  assert.match(resourceDetail, /Craft recipes/);
  assert.match(resourceDetail, /Building recipes/);
  assert.match(resourceDetail, /How to obtain it/);
  assert.match(resourceDetail, /Current service and research uses/);
  assert.match(resourceDetail, /Material role in current recipes/);
  assert.match(resourceDetail, /scalar count never silently replaces it/);
  assert.match(resourceDetail, /Exact resource use/);
  const craftingIndex = await read('app/crafting/page.tsx');
  const craftingDetail = await read('app/crafting/[slug]/page.tsx');
  assert.match(craftingIndex, /PixelImage/);
  assert.match(craftingIndex, /All current recipes by station/);
  assert.match(craftingIndex, /Exact ingredients and costs/);
  assert.match(craftingIndex, /Primary use/);
  assert.match(craftingIndex, /Ready when/);
  assert.match(craftingIndex, /What is available now/);
  assert.match(craftingIndex, /Defined or scheduled is not available now/);
  assert.match(craftingIndex, /crafting-reachability-grid/);
  assert.match(craftingIndex, /resultHref/);
  assert.match(craftingDetail, /recipe-ingredient/);
  assert.match(craftingDetail, /Result image/);
  assert.match(craftingDetail, /crafting-station/);
  assert.match(craftingDetail, /Access and readiness/);
  assert.match(craftingDetail, /Material choices/);
  assert.match(craftingDetail, /Commit and result/);
  assert.match(craftingDetail, /serviceForStation/);
  assert.match(craftingDetail, /recipeReadiness/);
  assert.match(craftingDetail, /Current recipes and requirements/);
  assert.match(craftingDetail, /Results and their use/);
  assert.match(craftingDetail, /definedButNotLiveForSystem/);
  assert.match(crafting, /materialChoice/);
  assert.match(crafting, /commitResult/);
  assert.match(crafting, /stationID/);
  assert.match(crafting, /definedButNotLiveCrafting/);
  assert.match(crafting, /Fitted Polearm/);
  assert.doesNotMatch(crafting, /id: 'fitted-polearm'/);
  assert.doesNotMatch(crafting, /id: 'caustic-core'/);
  assert.doesNotMatch(crafting, /id: 'light-core'/);
  assert.match(crafting, /name: 'Heat Conduit Fixture'/);
  assert.match(crafting, /name: 'Anchor Frame'/);
  const placeDetail = await read('app/places/[slug]/page.tsx');
  assert.match(placeDetail, /Exact inputs/);
  assert.match(placeDetail, /Ready when/);
  assert.match(placeDetail, /Material choices/);
  const craftingGuide = await read('app/systems/crafting/page.tsx');
  assert.match(craftingGuide, /Keep cost forms distinct/);
  assert.match(craftingGuide, /A counted resource cannot replace an exact/);
  const search = await read('app/search/page.tsx');
  assert.match(search, /Current crafting/);
  assert.match(search, /recipeReadiness/);
  const glossary = await read('app/glossary/page.tsx');
  assert.match(glossary, /Current recipe availability/);
  const progression = await read('app/resources/progression/page.tsx');
  assert.match(progression, /Crafting matrix lists only current recipe routes/);
  const equipment = await read('app/equipment/page.tsx');
  assert.match(equipment, /recipeReadiness/);
  assert.match(equipment, /does not have a matching current craft output/);
  for (const source of [
    await read('app/research/page.tsx'),
    await read('app/research/[slug]/page.tsx'),
    await read('app/systems/research/page.tsx'),
  ]) assert.doesNotMatch(source, /places\/workshop|Workshop and Research/);
});

test('places publish only current retained town and building visuals inline', async () => {
  const content = JSON.parse(await read('data/player-content.json'));
  const mappedBuildings = content.stations.filter((place) => place.assetURL);
  assert.equal(mappedBuildings.length, 8);
  for (const place of content.stations) {
    assert.match(place.contextAssetURL, /^\/game-assets\/places\//);
    await access(path.join(root, 'public', place.contextAssetURL));
    if (place.assetURL) await access(path.join(root, 'public', place.assetURL));
  }
  const detail = await read('app/places/[slug]/page.tsx');
  assert.match(detail, /place-visuals/);
  assert.match(detail, /building visual/);
  assert.match(detail, /Exact construction/);
  assert.match(detail, /What this place currently offers/);
  assert.match(detail, /Current crafting at this place/);
  assert.match(detail, /constructionRequirements/);
  assert.match(detail, /recipesFor/);
  assert.match(detail, /town context/);
});

test('exploration guide publishes retained portal and site-state visuals inline', async () => {
  const content = JSON.parse(await read('data/player-content.json'));
  for (const assetURL of Object.values(content.explorationVisuals)) {
    assert.match(assetURL, /^\/game-assets\/exploration\//);
    await access(path.join(root, 'public', assetURL));
  }
  const exploration = await read('app/systems/exploration/page.tsx');
  assert.match(exploration, /exploration-state-strip/);
  assert.match(exploration, /Entry portal/);
  assert.match(exploration, /Searched site/);
  assert.match(exploration, /What your Page can describe/);
  assert.match(exploration, /Field Guide identifies a revealed Flora harvest/);
  assert.match(exploration, /without predicting a hidden map/);
  assert.match(exploration, /Return and defeat/);
  assert.match(exploration, /Continue the same world/);
  assert.match(exploration, /pressureTargets/);
  assert.match(exploration, /writingAssetURL/);
});

test('combat guide uses retained party and equipment visuals as player-reference links', async () => {
  const combatGuide = await read('app/systems/combat/page.tsx');
  assert.match(combatGuide, /PixelImage/);
  assert.match(combatGuide, /\/people\/\$\{traveller\.slug\}/);
  assert.match(combatGuide, /\/equipment\/\$\{weapon\.slug\}/);
  assert.match(combatGuide, /\/equipment\/\$\{guard\.slug\}/);
  assert.match(combatGuide, /slot === 'weapon'/);
  assert.match(combatGuide, /slot === 'armor'/);
});

test('item indexes keep retained thumbnails compact and link each one to its entry', async () => {
  for (const relative of [
    'app/equipment/page.tsx',
    'app/consumables/page.tsx',
    'app/curios/page.tsx',
  ]) {
    const source = await read(relative);
    assert.match(source, /catalogue-summary/);
    assert.match(source, /aria-label=\{`Open \$\{item\.name\}`\}/);
    assert.match(source, /<PixelImage/);
  }
});

test('home and getting-started guide the live route with inline retained visuals', async () => {
  for (const relative of ['app/page.tsx', 'app/getting-started/page.tsx']) {
    const source = await read(relative);
    assert.match(source, /journey-strip/);
    assert.match(source, /content\.writingAssetURL/);
    assert.match(source, /content\.explorationVisuals\.entryPortal/);
    assert.match(source, /PixelImage/);
  }
});

test('crafting guide links retained Village visuals to their place references', async () => {
  const source = await read('app/systems/crafting/page.tsx');
  assert.match(source, /crafting-route-strip/);
  assert.match(source, /PixelImage/);
  assert.match(source, /station\.assetURL/);
  assert.match(source, /\/places\/\$\{station\.slug\}/);
});

test('full cast pages preserve player-facing sequence and withhold unrecovered world-hint details', async () => {
  const content = JSON.parse(await read('data/player-content.json'));
  const castGuide = await read('../docs/player-wiki-full-cast-current.md');
  const sync = await read('scripts/sync-content.mjs');
  assert.equal(content.cast.length, 29);
  assert.deepEqual(content.cast.map((person) => person.order), Array.from({ length: 29 }, (_, index) => index + 1));
  for (const name of ['Vance', 'Noll', 'Mara', 'Oda', 'Auber', 'Ashe', 'Tovin', 'Perren', 'Nine']) {
    assert.match(castGuide, new RegExp(`\\| \\d+ \\| ${name},`));
    assert.ok(content.cast.find((person) => person.name === name), name);
  }
  for (const person of content.cast) {
    assert.ok(person.meetingContext, `${person.name} meeting context`);
    assert.ok(person.role, `${person.name} service or role`);
    assert.ok(person.diaryReward, `${person.name} diary reward`);
    assert.ok(person.diaryPages.length, `${person.name} diary sequence`);
    for (const page of person.diaryPages) {
      assert.ok(page.sequence && page.title, `${person.name} diary title`);
      if (page.worldHint) assert.equal(page.detail, null, `${person.name} ${page.sequence} world hint withheld`);
      else assert.ok(page.detail, `${person.name} ${page.sequence} diary detail`);
    }
    assert.ok(person.assetURL, `${person.name} cameo URL`);
    assert.match(person.assetURL, /^\/game-assets\/people\/.+-cameo\.svg$/);
    const cameo = await read(`public${person.assetURL}`);
    assert.match(cameo, /viewBox="0 0 16 16"/);
    assert.match(cameo, /shape-rendering="crispEdges"/);
  }
  assert.match(sync, /player-wiki-full-cast-current\.md/);
  assert.match(sync, /castRows\.length !== 29/);
  assert.doesNotMatch(JSON.stringify(content.cast), /unusually open land where a load can cross the horizon/);
  const personPage = await read('app/people/[slug]/page.tsx');
  const peopleDirectory = await read('app/people/page.tsx');
  assert.match(personPage, /PixelImage/);
  assert.match(personPage, /character cameo/);
  assert.match(personPage, /content\.cast/);
  assert.match(personPage, /Spoiler boundary/);
  assert.match(personPage, /world hint/);
  assert.match(personPage, /Diary pages/);
  assert.match(personPage, /person-record-navigation/);
  assert.match(personPage, /#meeting/);
  assert.match(personPage, /#diary-pages/);
  assert.match(peopleDirectory, /people-directory/);
  assert.match(peopleDirectory, /content\.cast/);
  assert.match(peopleDirectory, /#meeting/);
  assert.match(peopleDirectory, /#diary-pages/);
});

test('village services have a hub, individual guides and place cross-links', async () => {
  await access(path.join(root, 'app/services/page.tsx'));
  await access(path.join(root, 'app/services/[slug]/page.tsx'));
  const services = await read('lib/services.ts');
  for (const id of [
    'storehouse',
    'trading_post',
    'recycler',
    'library',
    'firepit',
    'party',
    'essence_spring',
    'bestiary',
  ])
    assert.match(services, new RegExp(`stationID: '${id}'`));
  const place = await read('app/places/[slug]/page.tsx');
  assert.match(place, /serviceForStation/);
  assert.match(place, /How to use/);
  const index = await read('app/services/page.tsx');
  const detail = await read('app/services/[slug]/page.tsx');
  assert.match(index, /station\?\.assetURL \?\? station\?\.contextAssetURL/);
  assert.match(index, /PixelImage/);
  assert.match(detail, /station\.assetURL \?\? station\.contextAssetURL/);
  assert.match(detail, /service-visual-note/);
  assert.match(detail, /Choose the current entry/);
  assert.match(detail, /What happens after you confirm/);
  assert.match(detail, /guide\.relatedGuides/);
  assert.match(services, /selection:/);
  assert.match(services, /result:/);
  assert.match(services, /relatedGuides:/);
});

test('resource progression compares every current trade band and consumer family', async () => {
  const page = await read('app/resources/progression/page.tsx');
  for (const band of ['Staple', 'Uncommon', 'Rare', 'Precious', 'Nontradeable'])
    assert.match(page, new RegExp(`'${band}'`));
  assert.match(page, /recipesUsingResource/);
  assert.match(page, /buildingUses/);
  assert.match(page, /implemented game/);
});

test('bestiary navigation preserves undiscovered creature privacy while linking current player guides', async () => {
  const bestiary = await read('app/bestiary/page.tsx');
  const frame = await read('components/site-frame.tsx');
  const search = await read('app/search/page.tsx');
  assert.match(bestiary, /Individual records/);
  assert.match(bestiary, /does not promise that a named encounter profile is tameable or reveal a specimen’s current trust state/);
  assert.match(bestiary, /\/systems\/combat/);
  assert.match(bestiary, /\/systems\/exploration/);
  assert.match(bestiary, /PixelImage/);
  assert.match(frame, /\/bestiary/);
  assert.match(search, /World records/);
});

test('search groups player references and uses retained thumbnails only where available', async () => {
  const search = await read('app/search/page.tsx');
  assert.match(search, /label: 'Resources'/);
  assert.match(search, /label: 'Village services'/);
  assert.match(search, /label: 'Creatures and threats'/);
  assert.match(search, /label: 'Sites'/);
  assert.match(search, /content\.creatures/);
  assert.match(search, /content\.sites/);
  assert.match(search, /serviceGuides/);
  assert.match(search, /const groups = q/);
  assert.match(search, /PixelImage/);
  assert.match(search, /!groups\.length/);
});

test('glossary combines related player domains and points to useful guides', async () => {
  const glossary = await read('app/glossary/page.tsx');
  assert.match(glossary, /Writing a world/);
  assert.match(glossary, /Combat and party/);
  assert.match(glossary, /Village, resources and progression/);
  assert.match(glossary, /\/systems\/world-writing/);
  assert.match(glossary, /\/services\/party-and-gear/);
  assert.match(glossary, /glossary-group-heading/);
});

test('creature and site directories are discoverable from shared navigation and reciprocal player guides', async () => {
  const frame = await read('components/site-frame.tsx');
  const systems = await read('app/systems/page.tsx');
  const glossary = await read('app/glossary/page.tsx');
  const exploration = await read('app/systems/exploration/page.tsx');
  const animals = await read('app/systems/animals-companionship/page.tsx');
  const records = await read('app/systems/knowledge-records/page.tsx');
  const resource = await read('app/resources/[slug]/page.tsx');
  for (const source of [frame, systems, glossary, exploration, animals, records, resource]) {
    assert.match(source, /\/bestiary|\/sites/);
  }
  assert.match(systems, /Field and Village reference directories/);
  assert.match(frame, /Site directory/);
  assert.match(records, /without marking one as discovered/);
});

test('systems hub groups every current player guide into useful routes', async () => {
  const hub = await read('app/systems/page.tsx');
  const navigation = await read('lib/system-guides.ts');
  await access(path.join(root, 'app/systems/page.tsx'));
  for (const label of [
    'Journey and worlds',
    'Combat and preparation',
    'Village, crafting and records',
  ]) assert.match(navigation, new RegExp(label));
  for (const href of ['/getting-started', '/systems/world-writing', '/systems/exploration', '/systems/combat', '/systems/village-construction', '/systems/knowledge-records']) assert.match(navigation, new RegExp(href.replaceAll('/', '\\/')));
  assert.match(hub, /systemGuideCategories/);
  assert.match(hub, /PixelImage/);
});

test('shared guide navigation assigns every published system route to one player category', async () => {
  const navigation = await read('lib/system-guides.ts');
  const hub = await read('app/systems/page.tsx');
  const sidebar = await read('components/site-frame.tsx');
  const search = await read('app/search/page.tsx');
  const glossary = await read('app/glossary/page.tsx');
  const routes = (await readdir(path.join(root, 'app', 'systems'), { withFileTypes: true }))
    .filter((entry) => entry.isDirectory())
    .map((entry) => `/systems/${entry.name}`)
    .sort();
  const registered = [...navigation.matchAll(/href: '(\/systems\/[^']+)'/g)].map((match) => match[1]).sort();
  assert.deepEqual(registered, routes);
  assert.equal(new Set(registered).size, registered.length);
  assert.match(hub, /systemGuideCategories/);
  assert.match(sidebar, /systemGuideCategories/);
  assert.match(search, /systemGuides/);
  assert.match(search, /Player guides/);
  assert.match(glossary, /Player guides by task/);
  for (const route of routes) {
    const page = await read(`app${route}/page.tsx`);
    assert.match(page, /GuideBreadcrumbs/, route);
    assert.match(page, /RelatedGuides/, route);
  }
});

test('combat guide integrates retained party and gear references without a visual gallery', async () => {
  const combat = await read('app/systems/combat/page.tsx');
  assert.match(combat, /combat-reference-strip/);
  assert.match(combat, /PixelImage/);
  assert.match(combat, /\/people\/\$\{traveller\.slug\}/);
  assert.match(combat, /\/equipment\/\$\{weapon\.slug\}/);
  assert.match(combat, /Prepare before an encounter/);
  assert.match(combat, /Attack, Techniques, Item, and Withdraw/);
  assert.match(combat, /second-tap prompt/);
  assert.match(combat, /no separate Defend key/);
  assert.match(combat, /first enabled rule whose condition is true has priority/);
  assert.match(combat, /current expedition review/);
  assert.match(combat, /\/systems\/field-supplies/);
});

test('combat techniques and Gambits enumerate only current grants and owned rule parts', async () => {
  await access(path.join(root, 'app/systems/combat-techniques-gambits/page.tsx'));
  const guide = await read('app/systems/combat-techniques-gambits/page.tsx');
  const content = JSON.parse(await read('data/player-content.json'));
  assert.equal(content.combatTechniques.length, 25);
  assert.equal(content.combatTechniques.some((entry) => entry.name === 'Rout'), false);
  assert.equal(content.combatTechniques.some((entry) => entry.name === 'Steady'), false);
  assert.equal(content.combatTechniques.some((entry) => entry.name === 'Blur'), true);
  assert.equal(content.gambitComponents.length, 27);
  assert.deepEqual([...new Set(content.gambitComponents.map((entry) => entry.kind))].sort(), ['action', 'comparator', 'property', 'subject', 'threshold']);
  assert.match(guide, /one Combat Point/);
  assert.match(guide, /no separate technique currency/);
  assert.match(guide, /The first enabled rule that fits is the one that fires/);
  assert.match(guide, /only their owned components/);
  assert.match(await read('lib/system-guides.ts'), /\/systems\/combat-techniques-gambits/);
  assert.match(await read('components/site-frame.tsx'), /systemGuideCategories/);
});

test('Village construction lists every current destination with its exact foundation and player route', async () => {
  await access(path.join(root, 'app/systems/village-construction/page.tsx'));
  const guide = await read('app/systems/village-construction/page.tsx');
  const content = JSON.parse(await read('data/player-content.json'));
  assert.equal(content.stations.length, 22);
  assert.match(guide, /Every current Village destination/);
  assert.match(guide, /Meet \{station\.keeper\}/);
  assert.match(guide, /buildCost\(station\)/);
  assert.match(guide, /constructionBundledWith === station\.id/);
  assert.match(guide, /Trading Post, Recycler, Blacksmith/);
  assert.match(guide, /No separate recipe list is currently published/);
  assert.equal(guide.includes('Stage 0'), false);
  assert.equal(guide.includes('Aimee decision'), false);
  assert.match(await read('lib/system-guides.ts'), /\/systems\/village-construction/);
  assert.match(await read('components/site-frame.tsx'), /systemGuideCategories/);
});

test('all requested player detail routes have shared breadcrumbs and related guides', async () => {
  for (const relative of [
    'app/systems/world-writing/page.tsx',
    'app/systems/exploration/page.tsx',
    'app/systems/combat/page.tsx',
    'app/systems/crafting/page.tsx',
    'app/services/[slug]/page.tsx',
    'app/crafting/[slug]/page.tsx',
    'app/resources/[slug]/page.tsx',
    'app/equipment/[slug]/page.tsx',
    'app/people/[slug]/page.tsx',
    'app/places/[slug]/page.tsx',
  ]) {
    const source = await read(relative);
    assert.match(source, /GuideBreadcrumbs/);
    assert.match(source, /RelatedGuides/);
  }
  await access(path.join(root, 'components/guide-navigation.tsx'));
});

test('shared navigation exposes the player Systems hub alongside major tasks', async () => {
  const frame = await read('components/site-frame.tsx');
  const navigation = await read('lib/system-guides.ts');
  assert.match(frame, /systemGuideCategories/);
  assert.match(frame, /href="\/systems">Systems<\/Link>/);
  assert.match(frame, /<p>Prepare<\/p>/);
  assert.match(navigation, /\/systems\/world-writing/);
  for (const href of ['/getting-started', '/systems', '/services', '/crafting', '/resources', '/people']) {
    assert.match(frame, new RegExp(href.replaceAll('/', '\\/')));
  }
});

test('home and getting-started guide the live route with inline retained visuals', async () => {
  for (const relative of ['app/page.tsx', 'app/getting-started/page.tsx']) {
    const source = await read(relative);
    assert.match(source, /journey-strip/);
    assert.match(source, /content\.writingAssetURL/);
    assert.match(source, /content\.explorationVisuals\.entryPortal/);
    assert.match(source, /PixelImage/);
  }
});

test('current journey publishes only present Writing, world, Village, and Research routes', async () => {
  await access(path.join(root, 'app/journey/page.tsx'));
  const journey = await read('app/journey/page.tsx');
  const systems = await read('lib/system-guides.ts');
  const frame = systems;
  assert.match(journey, /Write, review, and Bind/);
  assert.match(journey, /Enter and explore the generated world/);
  assert.match(journey, /Current Village construction/);
  assert.match(journey, /Services, crafting, and Research/);
  assert.match(journey, /does not prescribe a future building or Research order/);
  assert.match(journey, /constructionCost/);
  assert.match(journey, /\/systems\/world-writing/);
  assert.match(journey, /\/systems\/exploration/);
  assert.match(journey, /\/systems\/research/);
  assert.match(journey, /Current task checklist/);
  assert.match(journey, /\/resources\/progression/);
  assert.match(journey, /\/research/);
  assert.match(systems, /Your current journey/);
  assert.match(frame, /\/journey/);
  assert.equal(journey.includes('Stage 0'), false);
  assert.equal(journey.includes('Stage 1'), false);
  assert.equal(journey.includes('Aimee decision'), false);
});

test('current progression is a task-oriented implemented-truth reference without proposed gates', async () => {
  await access(path.join(root, 'app/resources/progression/page.tsx'));
  const progression = await read('app/resources/progression/page.tsx');
  const starts = await read('lib/system-guides.ts');
  assert.match(progression, /Current task checklist/);
  assert.match(progression, /Read the next Page before Binding/);
  assert.match(progression, /Use the world to recover what you need now/);
  assert.match(progression, /Choose one current Village improvement/);
  assert.match(progression, /Study a ready Research node/);
  assert.match(progression, /Prepare people, gear, and supplies/);
  assert.match(progression, /does not promise that a particular construction/);
  assert.match(progression, /\/research/);
  assert.match(starts, /\/resources\/progression/);
});

test('Research publishes current branches, node requirements, base costs, and retained study behavior', async () => {
  await access(path.join(root, 'app/systems/research/page.tsx'));
  const content = JSON.parse(await read('data/player-content.json'));
  const research = await read('app/systems/research/page.tsx');
  const sync = await read('scripts/sync-content.mjs');
  assert.equal(content.researchBranches.length, 15);
  assert.equal(content.researchNodes.length, 87);
  assert.match(research, /Current branches and nodes/);
  assert.match(research, /Published base cost/);
  assert.match(research, /Earlier upgrades and other requirements/);
  assert.match(research, /no partial cost is taken/);
  assert.match(research, /\/services\/library/);
  assert.match(research, /current Research screen/);
  assert.doesNotMatch(research, /\/places\/workshop/);
  assert.match(sync, /researchSource/);
  assert.match(sync, /researchBranches/);
  assert.match(sync, /researchNodes/);
  assert.match(sync, /pressureTargetSource/);
  assert.equal(research.includes('Stage 0'), false);
  assert.equal(research.includes('Aimee decision'), false);
});

test('exploration’s current pressure guide is sourced from all implemented targets', async () => {
  const content = JSON.parse(await read('data/player-content.json'));
  assert.equal(content.pressureTargets.length, 8);
  assert.deepEqual(content.pressureTargets.map((target) => target.id), [
    'illumination', 'thermal', 'hydrology', 'substrate', 'relief', 'vitality', 'atmosphere', 'cycle',
  ]);
});

test('Party preparation documents the current party limit, gear slots, Gambits, and retained outcomes', async () => {
  await access(path.join(root, 'app/systems/party-preparation/page.tsx'));
  const party = await read('app/systems/party-preparation/page.tsx');
  const systems = await read('lib/system-guides.ts');
  const frame = systems;
  assert.match(party, /five-person party/);
  assert.match(party, /up to four recruited companions/);
  assert.match(party, /Weapon', 'Off-hand', 'Head', 'Body', 'Hands', 'Feet', 'Tool', 'Keepsake/);
  assert.match(party, /first enabled rule that fits/);
  assert.match(party, /The existing list and its priority stay unchanged/);
  assert.match(party, /\/services\/firepit/);
  assert.match(party, /\/equipment/);
  assert.match(party, /\/systems\/combat/);
  assert.match(systems, /\/systems\/party-preparation/);
  assert.match(frame, /\/systems\/party-preparation/);
});

test('Economy guide keeps current listings, refinement, and recycling player-facing', async () => {
  await access(path.join(root, 'app/systems/economy-exchange/page.tsx'));
  const economy = await read('app/systems/economy-exchange/page.tsx');
  const systems = await read('lib/system-guides.ts');
  const frame = systems;
  assert.match(economy, /current listing/);
  assert.match(economy, /item, quantity, price, and stock/);
  assert.match(economy, /Material sales use that reserve/);
  assert.match(economy, /Raw Essence and spendable Essence are distinct/);
  assert.match(economy, /Current material trade bands/);
  assert.match(economy, /Trade bands describe the current material catalogue/);
  assert.match(economy, /Keep Essence forms distinct/);
  assert.match(economy, /Reality currency and is not traded/);
  assert.match(economy, /Keep the exact holding/);
  assert.match(economy, /\/systems\/inventory-custody/);
  assert.match(economy, /authored material yield/);
  assert.match(economy, /current holdings stay where they are/);
  assert.match(economy, /\/services\/trading-post/);
  assert.match(economy, /\/services\/recycler/);
  assert.match(economy, /\/services\/essence-spring/);
  assert.match(systems, /\/systems\/economy-exchange/);
  assert.match(frame, /\/systems\/economy-exchange/);
});

test('Knowledge guide connects recovered Library, people, Research, and spoiler-safe Bestiary references', async () => {
  await access(path.join(root, 'app/systems/knowledge-records/page.tsx'));
  const knowledge = await read('app/systems/knowledge-records/page.tsx');
  const systems = await read('lib/system-guides.ts');
  const frame = systems;
  assert.match(knowledge, /Current Library collections/);
  assert.match(knowledge, /Diaries/);
  assert.match(knowledge, /People/);
  assert.match(knowledge, /Dictionary/);
  assert.match(knowledge, /Notes and History/);
  assert.match(knowledge, /Research and records/);
  assert.match(knowledge, /without marking one as discovered/);
  assert.match(knowledge, /\/services\/library/);
  assert.match(knowledge, /\/people/);
  assert.match(knowledge, /\/bestiary/);
  assert.match(systems, /\/systems\/knowledge-records/);
  assert.match(frame, /\/systems\/knowledge-records/);
});

test('Field supplies guide documents current preparation, targets, Scent Mask, curios, and retained choices', async () => {
  await access(path.join(root, 'app/systems/field-supplies/page.tsx'));
  const supplies = await read('app/systems/field-supplies/page.tsx');
  const systems = await read('lib/system-guides.ts');
  const frame = systems;
  assert.match(supplies, /Prepare the next Field Kit at home/);
  assert.match(supplies, /visible bin count is the current capacity/);
  assert.match(supplies, /Healing and other direct supplies/);
  assert.match(supplies, /Scent Mask/);
  assert.match(supplies, /12 turns/);
  assert.match(supplies, /Solvent and carried curios/);
  assert.match(supplies, /Trying an unknown curio/);
  assert.match(supplies, /Cancel leaves the curio unused/);
  assert.match(supplies, /does not turn the selection into a completed use/);
  assert.match(supplies, /\/consumables/);
  assert.match(supplies, /\/curios/);
  assert.match(systems, /\/systems\/field-supplies/);
  assert.match(frame, /\/systems\/field-supplies/);
});

test('Animals guide documents current Attend, trust, companion placement, combat, and Bestiary boundaries', async () => {
  await access(path.join(root, 'app/systems/animals-companionship/page.tsx'));
  const animals = await read('app/systems/animals-companionship/page.tsx');
  const systems = await read('lib/system-guides.ts');
  const frame = systems;
  assert.match(animals, /Recruit Sabine and build the Menagerie/);
  assert.match(animals, /within two tiles/);
  assert.match(animals, /not immediately adjacent/);
  assert.match(animals, /patient presence/);
  assert.match(animals, /returns to the Menagerie/);
  assert.match(animals, /Interpose, Harrier, Slip Away, Warning Display, or Commit/);
  assert.match(animals, /do not use human equipment or combat trees/);
  assert.match(animals, /neither reference marks an animal as encountered/);
  assert.match(animals, /\/places\/menagerie/);
  assert.match(animals, /\/bestiary/);
  assert.match(systems, /\/systems\/animals-companionship/);
  assert.match(frame, /\/systems\/animals-companionship/);
});

test('Equipment and material-effects guide keeps current slots, ownership, samples, and reforge routes player-facing', async () => {
  const guide = await read('app/systems/equipment-materials/page.tsx');
  const systems = await read('lib/system-guides.ts');
  const frame = systems;
  await access(path.join(root, 'app/systems/equipment-materials/page.tsx'));
  for (const slot of ['Weapon', 'Off-hand', 'Head', 'Body', 'Hands', 'Feet', 'Tool', 'Keepsake']) assert.match(guide, new RegExp(slot));
  assert.match(guide, /worn by another person/);
  assert.match(guide, /cannot be changed until you return Home/);
  assert.match(guide, /provenance and grade/);
  assert.match(guide, /select one exact eligible stock sample/);
  assert.match(guide, /construction tier remains with that piece/);
  assert.match(guide, /changed piece, stock, or cost/);
  assert.match(guide, /\/crafting\/blacksmith/);
  assert.match(guide, /\/systems\/party-preparation/);
  assert.match(systems, /\/systems\/equipment-materials/);
  assert.match(frame, /\/systems\/equipment-materials/);
});

test('Sites and hazards reference documents only current Look profiles, search states, and disclosed rewards', async () => {
  const guide = await read('app/systems/sites-hazards/page.tsx');
  const systems = await read('lib/system-guides.ts');
  const frame = systems;
  await access(path.join(root, 'app/systems/sites-hazards/page.tsx'));
  assert.match(guide, /Look does not move the party or spend a turn/);
  assert.match(guide, /Visible ordinary growth has no entry harm/);
  assert.match(guide, /Entering will hurt the party/);
  assert.match(guide, /Entering carries a lingering hazard/);
  assert.match(guide, /Entering will start an encounter/);
  assert.match(guide, /renews that poison rather than stacking/);
  assert.match(guide, /current Look copy keeps contact, chemical poison, and active encounter as distinct profiles/);
  assert.match(guide, /content\.sites/);
  assert.match(guide, /disclosedResult/);
  assert.match(guide, /on completion it becomes depleted/);
  assert.match(guide, /do not promise that an undiscovered site is present in every world/);
  assert.match(guide, /\/bestiary/);
  assert.match(guide, /\/sites/);
  assert.match(systems, /\/systems\/sites-hazards/);
  assert.match(frame, /\/systems\/sites-hazards/);
});

test('Inventory and custody guide preserves current locations, selected holdings, and refusal boundaries', async () => {
  const guide = await read('app/systems/inventory-custody/page.tsx');
  const systems = await read('lib/system-guides.ts');
  const frame = systems;
  await access(path.join(root, 'app/systems/inventory-custody/page.tsx'));
  for (const label of ['Stored', 'Waiting', 'Carried', 'Worn']) assert.match(guide, new RegExp(`<h3>${label}</h3>`));
  assert.match(guide, /not silently discarded/);
  assert.match(guide, /worn by another person is marked/);
  assert.match(guide, /Instruments are listed separately from supplies/);
  assert.match(guide, /Previewing changes nothing/);
  assert.match(guide, /price, stock, funds, capacity, or identity changes/);
  assert.match(guide, /changed item, target, turn, or world state leaves the shown use uncommitted/);
  assert.match(guide, /\/services\/storehouse/);
  assert.match(guide, /\/services\/trading-post/);
  assert.match(guide, /\/services\/recycler/);
  assert.match(systems, /\/systems\/inventory-custody/);
  assert.match(frame, /\/systems\/inventory-custody/);
});
