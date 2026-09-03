import assert from 'node:assert/strict';
import { access, readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = (relative) => readFile(path.join(root, relative), 'utf8');

test('Aimee Reference publishes the audited parallax World Splash inventory and three organized Game Design plan routes', async () => {
  const [home, references, splashAssets, preparation, route, source] = await Promise.all([
    read('app/page.tsx'),
    read('app/references/page.tsx'),
    read('app/references/world-splash-assets/page.tsx'),
    read('scripts/prepare-pages.mjs'),
    read('app/references/[slug]/page.tsx'),
    read('lib/design-references.ts'),
  ]);
  assert.match(home, /Aimee Reference/);
  assert.match(home, /World Splash Asset Inventory/);
  assert.match(home, /Resource, crafting, and world plans/);
  assert.match(home, /references\/world-splash-assets/);
  assert.match(references, /references\/world-splash-assets/);
  assert.match(preparation, /world-splash-five-layer-inventory-v1\.html/);
  assert.match(preparation, /references\/world-splash-assets\.html/);
  assert.doesNotMatch(preparation, /world-splash-five-layer-inventory-v1-app\.js/);
  assert.match(splashAssets, /five-layer parallax/);
  assert.match(splashAssets, /temporary proof of concept/);
  assert.match(splashAssets, /Audit conclusion: the recovered list is not enough/);
  assert.match(splashAssets, /Complete painter-facing inventory/);
  assert.match(splashAssets, /Landscape arrangement kit/);
  assert.match(splashAssets, /Ground-material kit/);
  assert.match(splashAssets, /Flora, tree, and canopy kit/);
  assert.doesNotMatch(splashAssets, /phone-review|Copy receipt|Download/);
  for (const file of [
    'resource-crafting-world-ecology-cohesive-plan-v1.md',
    'resource-crafting-world-overhaul-structure-v1.md',
    'resource-crafting-world-implementation-roadmap-v1.md',
  ]) {
    assert.match(source, new RegExp(file.replace('.', '\\.')));
    await access(path.resolve(root, '../docs', file));
  }
  for (const slug of [
    'resource-crafting-world-ecology-plan',
    'resource-crafting-world-overhaul',
    'resource-crafting-world-roadmap',
  ]) assert.match(source, new RegExp(slug));
  assert.match(references, /\/references\/\$\{reference\.slug\}/);
  assert.match(route, /ReactMarkdown/);
  assert.match(route, /remarkGfm/);
  assert.match(route, /markdown-reference/);
  assert.match(route, /reference\.systemLinks/);
  assert.match(route, /Open the system you need/);
  assert.match(source, /systemLinks/);
  assert.doesNotMatch(preparation, /resource-crafting-world-ecology-cohesive-plan-v1\.md/);
  await access(path.resolve(root, '../AssetLab/world-splash-five-layer-inventory-v1.html'));
  await access(path.resolve(root, '../AssetLab/src/world-splash-five-layer-inventory-v1.js'));
});

test('crafting overview separates the current property model from the intended physical system', async () => {
  const [page, overview, status, resources, loot, craftingGuide, inventory, equipment, world, progression, bestiary] = await Promise.all([
    read('app/crafting/page.tsx'),
    read('lib/crafting-overview.ts'),
    read('lib/player-guide-status.ts'),
    read('app/resources/page.tsx'),
    read('app/loot/page.tsx'),
    read('app/systems/crafting/page.tsx'),
    read('app/systems/inventory-custody/page.tsx'),
    read('app/systems/equipment-materials/page.tsx'),
    read('app/world/page.tsx'),
    read('app/resources/progression/page.tsx'),
    read('app/bestiary/page.tsx'),
  ]);
  for (const term of ['Hardness', 'Density', 'Insulation', 'Flexibility', 'Lustre', 'Reactivity'])
    assert.match(overview, new RegExp(term));
  const hierarchy = overview.slice(overview.indexOf('export const materialIdentityHierarchy'), overview.indexOf('export const inventoryViews'));
  let priorLevel = -1;
  for (const level of ['Broad category', 'Type', 'Subtype', 'Quality', 'Species-specific item']) {
    const nextLevel = hierarchy.indexOf(`['${level}'`);
    assert.ok(nextLevel > priorLevel, `${level} must follow the prior material identity level`);
    priorLevel = nextLevel;
  }
  for (const quality of ['Poor', 'Common', 'Rare', 'Exceptional'])
    assert.match(status, new RegExp(`'${quality}'`));
  assert.doesNotMatch(status.slice(status.indexOf('export const qualityBands'), status.indexOf('export const worldMaterialFamilies')), /Peerless/);
  assert.match(page, /Rules shared by crafting systems/);
  assert.match(page, /Every system now has its own page/);
  assert.doesNotMatch(page, /All current recipes by station/);
  assert.match(craftingGuide, /The properties stay; recipe eligibility changes/);
  assert.match(craftingGuide, /numerical properties and uses them to calculate concrete finished-item statistics/);
  assert.match(inventory, /default material stack is subtype plus quality/);
  assert.match(equipment, /Intended material stats/);
  assert.match(world, /Current generator and intended ecology/);
  assert.match(progression, /Current progression and intended expansion/);
  assert.match(bestiary, /Creature materials inherit real anatomy/);
  assert.match(overview, /Because unusually low traits can raise this grade/);
  assert.match(overview, /Trading Post supplier samples instead synthesize property ranges/);
  assert.match(overview, /the world itself is not rejected/);
  assert.match(resources, /Intended material identity/);
  assert.match(resources, /Loot, return, and custody/);
  assert.match(loot, /Open Resources at Loot, return, and custody/);
});

test('locked coating and starter-rune rules remain separate from the current build', async () => {
  const [overview, consumables, item, writing, gettingStarted] = await Promise.all([
    read('lib/crafting-overview.ts'),
    read('app/consumables/page.tsx'),
    read('app/items/[slug]/page.tsx'),
    read('app/systems/world-writing/page.tsx'),
    read('app/getting-started/page.tsx'),
  ]);
  assert.match(overview, /lasts for exactly one world excursion/);
  assert.match(overview, /begins with no known runes/);
  assert.match(overview, /Illumination and Sun guaranteed on a safe unavoidable path/);
  assert.match(overview, /Existing campaigns keep every known rune and owned World Page/);
  assert.match(consumables, /Locked intended rule/);
  assert.match(item, /Current and intended coating duration/);
  assert.match(writing, /Locked intended opening/);
  assert.match(gettingStarted, /If the introduction is interrupted/);
});

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
  assert.match(
    writing,
    /Copper supplies Cyan, Ichor Magenta, Sulfur Yellow, and Obsidian Depth/,
  );
  assert.match(writing, /12-application vial/);
  assert.match(writing, /changes a Focus’s authored colour, not its meaning/);
  assert.match(writing, /\/crafting\/writing-ink/);
  assert.match(writing, /\/resources/);
});

test('World Writing resource-pursuit Pages keep opening, mid-reach, and late recipes ordered and uncertain', async () => {
  const writing = await read('app/systems/world-writing/page.tsx');
  const recipes = await read('lib/world-writing-recipes.ts');
  const ids = [
    'starter_stone_hollow',
    'wild_gilded_caverns',
    'world_recipe_high_vent_v1',
  ];
  for (const id of ids) assert.match(recipes, new RegExp(id));
  const titles = ['Stone Hollow', 'Gilded Caverns', 'High Vent'];
  const positions = titles.map((title) => recipes.indexOf(title));
  assert.deepEqual(
    [...positions].sort((left, right) => left - right),
    positions,
  );
  assert.match(recipes, /not promise a deposit, route, map shape/);
  assert.match(recipes, /not promised/);
  assert.match(recipes, /not an owned World Page or automatic Template/);
  assert.match(recipes, /Fountain pen/);
  assert.match(writing, /Three resource-pursuit Pages/);
  assert.match(
    writing,
    /never guarantees a particular terrain, resource, route, or safe approach/,
  );
  for (const id of ids) assert.doesNotMatch(writing, new RegExp(id));
});

test('Apothecary first-use journey keeps Nessa, construction, Lesser Salve, inference, and cost boundaries distinct', async () => {
  const [service, place, crafting, journey] = await Promise.all(
    [
      'app/services/[slug]/page.tsx',
      'app/places/[slug]/page.tsx',
      'app/crafting/[slug]/page.tsx',
      'lib/apothecary-first-use.ts',
    ].map(read),
  );
  for (const stableID of [
    'apothecary',
    'nessa',
    'lesser-salve',
    'salve_lesser',
  ])
    assert.match(journey, new RegExp(stableID));
  assert.match(journey, /85 Essence · 16 Clay · 6 Quartz · 12 Reagent/);
  assert.match(journey, /1 flexible material at 25\+ · 1 Resin · 0 Essence/);
  assert.match(
    journey,
    /Construction teaches Lesser Salve but spends no recipe material and creates no item/,
  );
  assert.match(journey, /Needs 1 flexible material at 25\+ and 1 Resin/);
  assert.match(journey, /does not reveal Scent Mask, Stillwater, Waystone/);
  assert.match(
    journey,
    /Writing ink and vial preparation remain at the Scriptorium/,
  );
  assert.match(journey, /Stillwater adds 6 Essence/);
  assert.match(journey, /Waystone adds 12 Essence and 1 Mote/);
  for (const source of [service, place, crafting])
    assert.match(source, /apothecaryFirstUse/);
  assert.match(service, /First remedy: Nessa to Lesser Salve/);
  assert.match(await read('lib/services.ts'), /slug: 'apothecary'/);
  await access(path.join(root, 'app/services/[slug]/page.tsx'));
  assert.match(place, /Build it with Nessa/);
  assert.match(crafting, /Lesser Salve is the first known preparation/);
});

test('player reference directories provide a quick index, an at-a-glance layer, and full-entry links', async () => {
  const directoryPages = [
    'app/actions/page.tsx',
    'app/bestiary/page.tsx',
    'app/consumables/page.tsx',
    'app/crafting/page.tsx',
    'app/curios/page.tsx',
    'app/equipment/page.tsx',
    'app/flora/page.tsx',
    'app/people/page.tsx',
    'app/places/page.tsx',
    'app/research/page.tsx',
    'app/resources/page.tsx',
    'app/services/page.tsx',
    'app/sites/page.tsx',
    'app/statuses/page.tsx',
    'app/systems/village-construction/page.tsx',
    'app/techniques/page.tsx',
    'app/terrain/page.tsx',
    'app/village/page.tsx',
    'app/world/page.tsx',
  ];
  for (const relative of directoryPages) {
    const source = await read(relative);
    assert.match(source, /DirectoryIndex/, `${relative} must expose a quick index`);
    assert.match(source, /DirectoryDetailsIntro/, `${relative} must label its medium-detail layer`);
    const intro = source.indexOf('<PageIntro');
    const index = source.indexOf('<DirectoryIndex');
    const details = source.indexOf('<DirectoryDetailsIntro');
    assert.ok(intro >= 0 && index > intro && details > index, `${relative} must order its introduction, quick index, and medium-detail layer consistently`);
  }
  const directory = await read('components/directory-navigation.tsx');
  assert.match(directory, /Choose an icon or name for the full entry/);
  assert.match(directory, /Compare at a glance/);
  assert.match(directory, /href="#at-a-glance"/);
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

test('wiki formatting standard makes detail pages complete while category pages stay progressively disclosed', async () => {
  const readme = await read('README.md');
  for (const phrase of [
    'brief introduction',
    'compact icon-and-name index',
    'medium-detail comparison',
    'rules shared by the whole category',
    'complete canonical record',
    'Any fact summarized in an index or comparison must also appear',
    'without returning to its directory',
  ]) assert.match(readme, new RegExp(phrase));

  const completeDetailContracts = {
    'app/actions/[slug]/page.tsx': ['Surface', 'Available when', 'Committed change', 'Cost', 'What the result keeps', 'When it cannot complete'],
    'app/bestiary/[slug]/page.tsx': ['Combat profile', 'Health', 'Attack', 'Notice range', 'World conditions required', 'World conditions that help', 'Encounter and companionship'],
    'app/buildings/[slug]/page.tsx': ['Access and foundation', 'Village area', 'Current route', 'When usable', 'Exact construction', 'Actions and services', 'Results and research', 'Related materials and next steps'],
    'app/crafting/[slug]/page.tsx': ['Current station and approved direction', 'Access and readiness', 'Current recipes and requirements', 'Material choices', 'Commit and result', 'Results and their use'],
    'app/equipment/[slug]/page.tsx': ['Current equipment facts', 'Eligibility', 'Material and reforge facts', 'ItemCraftingRoutes', 'Custody and swapping', 'Trading and recycling'],
    'app/items/[slug]/page.tsx': ['Current use', 'Field Kit and carrying', 'Identification and knowledge', 'Use and custody', 'ItemCraftingRoutes', 'Trading', 'Recycler'],
    'app/people/[slug]/page.tsx': ['Campaign order', 'Meeting context', 'Diary reward', 'After meeting', 'Book pages beyond location hints', 'location-hint stages'],
    'app/research/[slug]/page.tsx': ['Current node details', 'Earlier upgrades', 'Other requirements', 'Base cost', 'Result', 'Study and retain'],
    'app/resources/[slug]/page.tsx': ['How to obtain it', 'Trade', 'Primary pressure', 'Required conditions', 'Conditions that help', 'Current service and research uses', 'Craft recipes', 'Building recipes'],
    'app/services/[slug]/page.tsx': ['Use it for', 'Typical flow', 'Choose the current entry', 'What happens after you confirm', 'Worth remembering'],
    'app/sites/[slug]/page.tsx': ['Current world association', 'Placement', 'Search', 'Conditions', 'Disclosed result after completion', 'Look and depletion'],
    'app/statuses/[slug]/page.tsx': ['Current rule', 'Source', 'Effect', 'Duration', 'Where it applies', 'Clear or prevent', 'Keep the boundary clear'],
    'app/techniques/[slug]/page.tsx': ['Current use', 'Source or grant', 'Who can use it', 'Trigger', 'Target', 'Exact current result', 'Costs, cooldowns, and limits'],
    'app/terrain/[slug]/page.tsx': ['Movement', 'Sight', 'Resource relationship', 'Related current resources'],
    'app/flora/[slug]/page.tsx': ['Current output', 'Inspect before acting'],
    'app/world/conditions/[slug]/page.tsx': ['What it shapes', 'In a bound world'],
  };
  for (const [relative, requiredFacts] of Object.entries(completeDetailContracts)) {
    const source = await read(relative);
    for (const fact of requiredFacts) assert.match(source, new RegExp(fact), `${relative} must retain ${fact}`);
  }
});

test('Bestiary publishes stable named encounter profiles without claiming save discovery or individual trust', async () => {
  await access(path.join(root, 'app/bestiary/[slug]/page.tsx'));
  const index = await read('app/bestiary/page.tsx');
  const detail = await read('app/bestiary/[slug]/page.tsx');
  const snapshot = JSON.parse(await read('data/player-content.json'));
  assert.equal(snapshot.creatures.length, 3);
  assert.match(index, /never marks a creature as discovered for your own save/);
  assert.match(
    index,
    /does not promise that a named encounter profile is tameable/,
  );
  assert.match(
    detail,
    /does not promise companionship or disclose any individual’s trust state/,
  );
  assert.match(
    detail,
    /No separate fixed status or drop is published for this profile/,
  );
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
  assert.match(
    directory,
    /never promises an undiscovered site in a particular world/,
  );
  assert.match(
    detail,
    /does not reveal whether it was rolled into an undiscovered world/,
  );
  assert.match(
    detail,
    /remains unavailable rather than silently awarding a replacement result/,
  );
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
  const sources = await Promise.all(
    [
      'lib/wiki-navigation.ts',
      'app/search/page.tsx',
      'app/glossary/page.tsx',
      'app/systems/page.tsx',
      'app/resources/progression/page.tsx',
      'app/resources/page.tsx',
      'app/resources/[slug]/page.tsx',
      'app/crafting/page.tsx',
      'app/crafting/[slug]/page.tsx',
    ].map(read),
  );
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
  ])
    await access(path.join(root, relative));
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
  assert.match(
    world,
    /rather than one guaranteed tile, plant, deposit, site, or animal/,
  );
  assert.match(flora, /never predicts an unseen plant/);
});

test('item details link published recipes and resources without guessing absent acquisition routes', async () => {
  const routes = await read('components/item-crafting-routes.tsx');
  const itemDetail = await read('app/items/[slug]/page.tsx');
  const equipmentDetail = await read('app/equipment/[slug]/page.tsx');
  const craftingGuide = await read('app/systems/crafting/page.tsx');
  assert.match(routes, /Current acquisition/);
  assert.match(
    routes,
    /No current station preparation or construction recipe is published/,
  );
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
  for (const stableID of [
    'affliction-burn',
    'affliction-poison',
    'affliction-dazzle',
    'affliction-bleed',
    'world-flora-poison',
    'world-scent-mask',
    'guard-stonebark',
  ])
    assert.match(reference, new RegExp(stableID));
  assert.match(
    reference,
    /Combat Poison is distinct from poison left by chemical flora/,
  );
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
  const sources = await Promise.all(
    [
      'lib/wiki-navigation.ts',
      'app/search/page.tsx',
      'app/glossary/page.tsx',
      'app/systems/combat/page.tsx',
      'app/systems/party-preparation/page.tsx',
      'app/equipment/page.tsx',
      'app/equipment/[slug]/page.tsx',
      'app/systems/field-supplies/page.tsx',
      'app/systems/combat-techniques-gambits/page.tsx',
    ].map(read),
  );
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
  for (const stableID of [
    'writing-bind-world',
    'world-move',
    'world-search-site',
    'combat-attack',
    'custody-transfer',
    'research-study',
    'companion-attend',
  ])
    assert.match(reference, new RegExp(stableID));
  assert.match(reference, /craftingSystems\.map/);
  assert.match(reference, /serviceGuides\.map/);
  assert.match(directory, /Action reference/);
  assert.match(directory, /Current station transaction/);
  assert.match(detail, /Available when/);
  assert.match(detail, /When it cannot complete/);
});

test('People directory keeps campaign order, meeting context, and current Village relationships together', async () => {
  const directory = await read('app/people/page.tsx');
  assert.match(directory, /Campaign-order people directory/);
  assert.match(directory, /meetingContext/);
  assert.match(directory, /serviceForStation/);
  assert.match(directory, /\/people\/\$\{person.slug\}/);
  assert.match(directory, /diary-pages/);
});

test('Trading directory distinguishes rotating offer pools from durable player routes', async () => {
  await access(path.join(root, 'app/trading/page.tsx'));
  const directory = await read('app/trading/page.tsx');
  const reference = await read('lib/trading-reference.ts');
  const sync = await read('scripts/sync-content.mjs');
  assert.match(directory, /no durable player-facing listing identity/);
  assert.match(directory, /Current resource offer pools/);
  assert.match(directory, /Known consumables that may enter the pool/);
  assert.match(directory, /Ordinary gear that may enter the pool/);
  assert.match(directory, /Cancel, refusal, and stock changes/);
  assert.match(reference, /buyableResourceBands/);
  assert.match(reference, /merchantConsumables/);
  assert.match(reference, /ordinaryMerchantGear/);
  assert.match(sync, /ordinaryMerchantGear/);
  assert.match(sync, /merchantStockAccess/);
});

test('Recycler directory keeps authored salvage profiles separate from current physical previews', async () => {
  await access(path.join(root, 'app/recycling/page.tsx'));
  const directory = await read('app/recycling/page.tsx');
  const reference = await read('lib/recycling-reference.ts');
  const sync = await read('scripts/sync-content.mjs');
  assert.match(directory, /no durable player-facing transaction ID/);
  assert.match(directory, /Standard salvage profiles/);
  assert.match(directory, /Construction-receipt recovery/);
  assert.match(directory, /When a piece stays protected/);
  assert.match(directory, /Confirm only the displayed preview/);
  for (const profile of [
    'forged_edge_v1',
    'headed_tool_v1',
    'long_haft_v1',
    'board_guard_v1',
    'rigid_protection_v1',
    'padded_protection_v1',
    'boots_v1',
    'keepsake_v1',
  ])
    assert.match(reference, new RegExp(profile));
  assert.match(reference, /standardRecyclerGear/);
  assert.match(sync, /salvageProfileID/);
});

test('Recycler first use keeps Noll, the 15-Essence bench, empty state, exact preview, and destructive boundary distinct', async () => {
  const [directory, service, building, journey] = await Promise.all(
    [
      'app/recycling/page.tsx',
      'app/services/[slug]/page.tsx',
      'app/buildings/[slug]/page.tsx',
      'lib/recycler-first-use.ts',
    ].map(read),
  );
  for (const stableID of ['recycler', 'noll'])
    assert.match(journey, new RegExp(stableID));
  assert.match(journey, /15 Essence/);
  assert.match(journey, /No gear to dismantle/);
  assert.match(journey, /Dismantle without recovery/);
  assert.match(journey, /Field Separation Kit remains absent/);
  assert.match(
    journey,
    /stale, invalid, busy, or save-failed recovery keeps the preview open/,
  );
  for (const source of [directory, service, building])
    assert.match(source, /recyclerFirstUse/);
  assert.match(directory, /Noll’s first Recycler/);
  assert.match(service, /First use with Noll/);
  assert.match(building, /Build the Recycler with Noll/);
});

test('Anchorage first anchor keeps Tovin, exact construction, Frame custody, Atlas Seam confirmation, and unpublished work separate', async () => {
  const [service, building, crafting, site, journey] = await Promise.all([
    read('app/services/[slug]/page.tsx'),
    read('app/buildings/[slug]/page.tsx'),
    read('app/crafting/[slug]/page.tsx'),
    read('app/sites/[slug]/page.tsx'),
    read('lib/anchorage-first-anchor.ts'),
  ]);
  assert.match(journey, /travellerID: 'tovin'/);
  assert.match(journey, /stationID: 'anchorage'/);
  assert.match(journey, /frameID: 'anchor_frame'/);
  assert.match(journey, /seamID: 'natural_anchor'/);
  assert.match(journey, /200 Essence · 40 Iron Ore · 20 Quartz · 18 Pulp/);
  assert.match(journey, /60 Essence/);
  assert.match(journey, /Work and Deliveries are not published/);
  assert.match(
    journey,
    /Cancel, a stale quote, a busy control, insufficient Essence, or a failed durable write spends nothing/,
  );
  assert.match(
    journey,
    /does not end the expedition, bank the current haul, reset the world, duplicate a Frame, or create a delivery/,
  );
  assert.match(
    journey,
    /Sustain or Let rest is a later explicit settlement choice/,
  );
  for (const source of [service, building, crafting, site])
    assert.match(source, /anchorageFirstAnchor/);
  assert.match(service, /First held realm: Tovin to Atlas Seam/);
  assert.match(building, /Build the Anchorage with Tovin/);
  assert.match(crafting, /Anchor Frame is a separate carried route/);
  assert.match(site, /Anchor one exact world/);
});

test('Blacksmith first use keeps Halloway, exact foundation, Pointed Blade custody, complete stock, and useful Reforge publication boundary distinct', async () => {
  const [service, building, place, crafting, journey] = await Promise.all([
    read('app/services/[slug]/page.tsx'),
    read('app/buildings/[slug]/page.tsx'),
    read('app/places/[slug]/page.tsx'),
    read('app/crafting/[slug]/page.tsx'),
    read('lib/blacksmith-first-use.ts'),
  ]);
  assert.match(journey, /travellerID: 'halloway'/);
  assert.match(journey, /stationID: 'blacksmith'/);
  assert.match(journey, /schematicID: 'pointed_blade'/);
  assert.match(journey, /30 Essence · 12 Iron Ore · 6 Fibre/);
  assert.match(
    journey,
    /Iron enough for the work, fibre enough to bind the frame/,
  );
  assert.doesNotMatch(journey, /stone and iron/i);
  assert.match(journey, /World or Creature Material/);
  assert.match(journey, /two exact property-30\+ materials and 8 Essence/);
  assert.match(journey, /does not promise a paid Reforge success/);
  assert.match(journey, /Same-name gear is never substituted/);
  for (const source of [service, building, place, crafting])
    assert.match(source, /blacksmithFirstUse/);
  assert.match(service, /Third opening find: Halloway to Pointed Blade/);
  assert.match(building, /Build the Blacksmith with Halloway/);
  assert.match(place, /Build it with Halloway/);
  assert.match(crafting, /Pointed Blade is the first live maker family/);
  for (const source of [building, place])
    assert.doesNotMatch(source, /stone and the iron/);
});

test('Survey Post first-reading journey keeps Mara, permanent capabilities, loadout, Survey, and withheld paid improvement distinct', async () => {
  const [service, building, place, crafting, journey, services] =
    await Promise.all(
      [
        'app/services/[slug]/page.tsx',
        'app/buildings/[slug]/page.tsx',
        'app/places/[slug]/page.tsx',
        'app/crafting/[slug]/page.tsx',
        'lib/survey-post-first-use.ts',
        'lib/services.ts',
      ].map(read),
    );
  for (const stableID of [
    'survey_post',
    'mara',
    'instruments',
    'sunglass',
    'level',
    'thermoscope',
    'hygrometer',
    'loupe',
    'vivometer',
    'barometer',
    'chronometer',
  ])
    assert.match(journey, new RegExp(stableID));
  assert.match(journey, /50 Essence · 10 Timber · 8 Iron Ore · 2 Quartz/);
  assert.match(journey, /permanent Reality capabilities/);
  assert.match(
    journey,
    /not Storehouse stacks, Field Kit supply entries, equipment, or output-bin objects/,
  );
  assert.match(journey, /advances one ordinary turn/);
  assert.match(
    journey,
    /no coordinate, resource, site, traveller, fog reveal, or map completion/,
  );
  assert.match(
    journey,
    /full Storehouse or Waiting pile cannot block studying or improving one/,
  );
  assert.match(journey, /Crude → Good is playable now/);
  for (const source of [service, building, place, crafting])
    assert.match(source, /surveyPostFirstUse/);
  assert.match(services, /slug: 'survey-post'/);
  assert.match(service, /First reading: Mara to Survey/);
  assert.match(building, /Build the Survey Post with Mara/);
  assert.match(place, /Completion opens research, not a tool bin/);
  assert.match(crafting, /Good and Fine precision are playable now/);
  assert.match(crafting, /publishedRecipes = recipes/);
  assert.match(await read('lib/crafting.ts'), /name: 'Good instrument'/);
});

test('economy references are reachable from current player tasks without claiming rotating transactions are permanent', async () => {
  const sources = await Promise.all(
    [
      'app/systems/economy-exchange/page.tsx',
      'app/resources/[slug]/page.tsx',
      'app/items/[slug]/page.tsx',
      'app/equipment/[slug]/page.tsx',
      'app/systems/crafting/page.tsx',
      'app/resources/progression/page.tsx',
      'app/village/page.tsx',
      'app/services/page.tsx',
      'app/services/[slug]/page.tsx',
      'app/buildings/[slug]/page.tsx',
      'app/search/page.tsx',
      'app/glossary/page.tsx',
      'lib/wiki-navigation.ts',
    ].map(read),
  );
  for (const source of sources) assert.match(source, /\/trading|\/recycling/);
  assert.match(sources[0], /Trading offer reference/);
  assert.match(sources[10], /Economy references/);
  assert.match(sources[12], /label: 'Trading'/);
});

test('complete people records are discoverable through player-facing Library, site, glossary, search, and navigation routes', async () => {
  const [search, glossary, knowledge, service, place, sites, frame] =
    await Promise.all(
      [
        'app/search/page.tsx',
        'app/glossary/page.tsx',
        'app/systems/knowledge-records/page.tsx',
        'app/services/[slug]/page.tsx',
        'app/places/[slug]/page.tsx',
        'app/sites/page.tsx',
        'lib/wiki-navigation.ts',
      ].map(read),
    );
  assert.match(search, /People and records/);
  assert.match(search, /Authored book page/);
  assert.match(search, /Spoiler-marked location hint/);
  assert.match(search, /page\.prose/);
  assert.match(search, /location-hints/);
  assert.match(glossary, /People and records/);
  assert.match(knowledge, /complete current authored book record/);
  assert.match(service, /guide\.slug === 'library'/);
  assert.match(place, /place\.id === 'library'/);
  assert.match(sites, /People’s location records/);
  assert.match(frame, /label: 'People'/);
});

test('action reference is discoverable from player navigation and the affected current system guides', async () => {
  const sources = await Promise.all(
    [
      'lib/wiki-navigation.ts',
      'app/search/page.tsx',
      'app/glossary/page.tsx',
      'app/getting-started/page.tsx',
      'app/journey/page.tsx',
      'app/systems/world-writing/page.tsx',
      'app/systems/exploration/page.tsx',
      'app/systems/combat/page.tsx',
      'app/systems/inventory-custody/page.tsx',
      'app/systems/research/page.tsx',
      'app/systems/animals-companionship/page.tsx',
    ].map(read),
  );
  for (const source of sources) assert.match(source, /\/actions/);
  assert.match(sources[1], /label: 'Actions'/);
  assert.match(sources[2], /Action reference/);
  assert.match(sources[3], /Action reference/);
});

test('place details expose only their current construction, service, and station actions', async () => {
  const reference = await read('lib/action-reference.ts');
  const detail = await read('app/places/[slug]/page.tsx');
  assert.match(reference, /actionsForStation/);
  assert.match(detail, /Current actions here/);
  assert.match(detail, /actionsForStation\(place.id\)/);
  assert.match(detail, /build-foundation/);
  assert.match(detail, /Action reference/);
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
    assert.ok(
      resource.consumerAuthority.acquisition,
      `${resource.id} acquisition`,
    );
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
  assert.match(craftingIndex, /Rules shared by crafting systems/);
  assert.match(craftingIndex, /Preparations and processing/);
  assert.match(craftingIndex, /Weapons, clothing, and protection/);
  assert.match(craftingIndex, /Expedition tools and worldwork/);
  assert.match(craftingIndex, /Open the complete/);
  assert.doesNotMatch(craftingIndex, /All current recipes by station/);
  assert.doesNotMatch(craftingIndex, /Complete current-to-intended recipe comparison/);
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
  assert.match(crafting, /id: 'fitted-polearm'/);
  assert.match(crafting, /id: 'caustic-core'/);
  assert.match(crafting, /id: 'light-core'/);
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
  ])
    assert.doesNotMatch(source, /places\/workshop|Workshop and Research/);
});

test('public loot, resources, and crafting guides separate implemented truth from intended changes', async () => {
  const [home, frame, loot, resources, resourceDetail, crafting, craftingDetail, guide, status, truthPair] = await Promise.all([
    read('app/page.tsx'),
    read('components/site-frame.tsx'),
    read('app/loot/page.tsx'),
    read('app/resources/page.tsx'),
    read('app/resources/[slug]/page.tsx'),
    read('app/crafting/page.tsx'),
    read('app/crafting/[slug]/page.tsx'),
    read('app/guide-status/page.tsx'),
    read('lib/player-guide-status.ts'),
    read('components/truth-pair.tsx'),
  ]);
  assert.match(home, /Aimee Reference/);
  assert.match(frame, /Aimee Reference/);
  for (const source of [resources, resourceDetail, crafting, craftingDetail, guide]) {
    assert.match(source, /TruthPair/);
  }
  assert.doesNotMatch(frame, /href="\/loot"/);
  assert.match(loot, /Open Resources at Loot, return, and custody/);
  assert.match(resources, /lootPaths/);
  assert.match(status, /Playable now/);
  assert.match(truthPair, /Implemented now/);
  assert.match(truthPair, /Intended implementation/);
  assert.match(status, /worldMaterialFamilies/);
  assert.match(status, /creatureMaterialFamilies/);
  assert.match(status, /Poor/);
  assert.match(status, /Exceptional/);
  assert.match(status, /same subtype and quality share a default stack/);
  assert.match(status, /another grade is never silently/);
  assert.match(status, /Waystone’s hard body/);
});

test('sidebar and article are independent desktop scroll regions with a single mobile flow', async () => {
  const [frame, styles] = await Promise.all([
    read('components/site-frame.tsx'),
    read('app/globals.css'),
  ]);
  assert.match(frame, /site-shell-with-sidebar/);
  assert.match(frame, /wiki-content-column/);
  assert.match(styles, /\.site-shell-with-sidebar\s*{[^}]*height: 100dvh;[^}]*overflow: hidden;/s);
  assert.match(styles, /\.wiki-sidebar\s*{[^}]*overflow-y: auto;/s);
  assert.match(styles, /\.wiki-content-column\s*{[^}]*overflow-y: auto;/s);
  assert.match(styles, /@media \(max-width: 860px\)[\s\S]*\.site-shell-with-sidebar\s*{[^}]*height: auto;[^}]*overflow: visible;/);
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

test('full cast pages publish complete exact book text with a clear location-hint boundary', async () => {
  const content = JSON.parse(await read('data/player-content.json'));
  const castGuide = await read('../docs/player-wiki-full-cast-current.md');
  const sync = await read('scripts/sync-content.mjs');
  const travellerSource = JSON.parse(
    await read('../Sources/Content/Data/travellers.json'),
  );
  assert.equal(content.cast.length, 29);
  assert.deepEqual(
    content.cast.map((person) => person.order),
    Array.from({ length: 29 }, (_, index) => index + 1),
  );
  for (const name of [
    'Vance',
    'Noll',
    'Mara',
    'Oda',
    'Auber',
    'Ashe',
    'Tovin',
    'Perren',
    'Nine',
  ]) {
    assert.match(castGuide, new RegExp(`\\| \\d+ \\| ${name},`));
    assert.ok(
      content.cast.find((person) => person.name === name),
      name,
    );
  }
  for (const person of content.cast) {
    assert.ok(person.meetingContext, `${person.name} meeting context`);
    assert.ok(person.role, `${person.name} service or role`);
    assert.ok(person.diaryReward, `${person.name} diary reward`);
    assert.ok(person.diaryPages.length, `${person.name} diary sequence`);
    for (const page of person.diaryPages) {
      assert.ok(page.sequence && page.title, `${person.name} diary title`);
      assert.ok(page.sourceID, `${person.name} ${page.sequence} source id`);
      assert.ok(
        page.prose,
        `${person.name} ${page.sequence} exact authored prose`,
      );
    }
    const traveller = travellerSource.travellers.find(
      (entry) => entry.name === person.name,
    );
    for (const sourcePage of travellerSource.pages.filter(
      (page) => page.diary === traveller.id,
    )) {
      const published = person.diaryPages.find(
        (page) => page.sourceID === sourcePage.id,
      );
      assert.equal(
        published?.prose,
        sourcePage.prose,
        `${person.name} retains ${sourcePage.id}`,
      );
    }
    assert.ok(person.assetURL, `${person.name} cameo URL`);
    assert.match(person.assetURL, /^\/game-assets\/people\/.+-cameo\.svg$/);
    const cameo = await read(`public${person.assetURL}`);
    assert.match(cameo, /viewBox="0 0 16 16"/);
    assert.match(cameo, /shape-rendering="crispEdges"/);
  }
  assert.match(sync, /player-wiki-full-cast-current\.md/);
  assert.match(sync, /castRows\.length !== 29/);
  assert.match(sync, /auber_word_grimmond/);
  const sabine = content.cast.find((person) => person.name === 'Sabine');
  const grimmond = content.cast.find((person) => person.name === 'Grimmond');
  assert.equal(sabine.diaryPages.length, 10);
  assert.equal(grimmond.diaryPages.length, 11);
  assert.equal(grimmond.diaryPages[9].sourceID, 'auber_word_grimmond');
  assert.equal(
    grimmond.diaryPages[10].sourceID,
    'grimmond_account_empty_support',
  );
  const personPage = await read('app/people/[slug]/page.tsx');
  const peopleDirectory = await read('app/people/page.tsx');
  assert.match(personPage, /PixelImage/);
  assert.match(personPage, /character cameo/);
  assert.match(personPage, /content\.cast/);
  assert.match(personPage, /Spoiler boundary/);
  assert.match(personPage, /location-hints/);
  assert.match(personPage, /Book pages beyond location hints/);
  assert.match(personPage, /page\.prose/);
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
  const navigation = await read('lib/wiki-navigation.ts');
  const search = await read('app/search/page.tsx');
  assert.match(bestiary, /Individual records/);
  assert.match(
    bestiary,
    /does not promise that a named encounter profile is tameable or reveal a specimen’s current trust state/,
  );
  assert.match(bestiary, /\/systems\/combat/);
  assert.match(bestiary, /\/systems\/exploration/);
  assert.match(bestiary, /PixelImage/);
  assert.match(navigation, /\/bestiary/);
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
  assert.match(glossary, /Village and facilities/);
  assert.match(glossary, /Crafting, resources and progression/);
  assert.match(glossary, /\/systems\/world-writing/);
  assert.match(glossary, /\/services\/party-and-gear/);
  assert.match(glossary, /glossary-group-heading/);
});

test('creature and site directories are discoverable from shared navigation and reciprocal player guides', async () => {
  const navigation = await read('lib/wiki-navigation.ts');
  const systems = await read('app/systems/page.tsx');
  const glossary = await read('app/glossary/page.tsx');
  const exploration = await read('app/systems/exploration/page.tsx');
  const animals = await read('app/systems/animals-companionship/page.tsx');
  const records = await read('app/systems/knowledge-records/page.tsx');
  const resource = await read('app/resources/[slug]/page.tsx');
  for (const source of [
    navigation,
    systems,
    glossary,
    exploration,
    animals,
    records,
    resource,
  ]) {
    assert.match(source, /\/bestiary|\/sites/);
  }
  assert.match(systems, /Browse the Wiki by subject/);
  assert.match(navigation, /Site directory/);
  assert.match(records, /without marking one as discovered/);
});

test('systems hub groups every current player guide into useful routes', async () => {
  const hub = await read('app/systems/page.tsx');
  const navigation = await read('lib/system-guides.ts');
  await access(path.join(root, 'app/systems/page.tsx'));
  for (const label of [
    'Worlds and exploration',
    'Characters and combat',
    'Village and facilities',
    'Crafting and items',
    'Knowledge and records',
  ])
    assert.match(navigation, new RegExp(label));
  for (const href of [
    '/getting-started',
    '/systems/world-writing',
    '/systems/exploration',
    '/systems/combat',
    '/systems/village-construction',
    '/systems/knowledge-records',
  ])
    assert.match(navigation, new RegExp(href.replaceAll('/', '\\/')));
  assert.match(hub, /systemGuideCategories/);
  assert.match(hub, /PixelImage/);
});

test('shared guide navigation assigns every published system route to one player category', async () => {
  const navigation = await read('lib/system-guides.ts');
  const hub = await read('app/systems/page.tsx');
  const sidebar = await read('lib/wiki-navigation.ts');
  const search = await read('app/search/page.tsx');
  const glossary = await read('app/glossary/page.tsx');
  const routes = (
    await readdir(path.join(root, 'app', 'systems'), { withFileTypes: true })
  )
    .filter((entry) => entry.isDirectory())
    .map((entry) => `/systems/${entry.name}`)
    .sort();
  const registered = [...navigation.matchAll(/href: '(\/systems\/[^']+)'/g)]
    .map((match) => match[1])
    .sort();
  assert.deepEqual(registered, routes);
  assert.equal(new Set(registered).size, registered.length);
  assert.match(hub, /systemGuideCategories/);
  assert.match(sidebar, /Worlds and exploration/);
  assert.match(sidebar, /Village and facilities/);
  assert.match(sidebar, /Crafting and items/);
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
  assert.match(
    combat,
    /first enabled rule whose condition is true has priority/,
  );
  assert.match(combat, /current expedition review/);
  assert.match(combat, /\/systems\/field-supplies/);
});

test('combat techniques and Gambits enumerate only current grants and owned rule parts', async () => {
  await access(
    path.join(root, 'app/systems/combat-techniques-gambits/page.tsx'),
  );
  const guide = await read('app/systems/combat-techniques-gambits/page.tsx');
  const content = JSON.parse(await read('data/player-content.json'));
  assert.equal(content.combatTechniques.length, 25);
  assert.equal(
    content.combatTechniques.some((entry) => entry.name === 'Rout'),
    false,
  );
  assert.equal(
    content.combatTechniques.some((entry) => entry.name === 'Steady'),
    false,
  );
  assert.equal(
    content.combatTechniques.some((entry) => entry.name === 'Blur'),
    true,
  );
  assert.equal(content.gambitComponents.length, 27);
  assert.deepEqual(
    [...new Set(content.gambitComponents.map((entry) => entry.kind))].sort(),
    ['action', 'comparator', 'property', 'subject', 'threshold'],
  );
  assert.match(guide, /one Combat Point/);
  assert.match(guide, /no separate technique currency/);
  assert.match(guide, /The first enabled rule that fits is the one that fires/);
  assert.match(guide, /only their owned components/);
  assert.match(
    await read('lib/system-guides.ts'),
    /\/systems\/combat-techniques-gambits/,
  );
  assert.match(
    await read('lib/wiki-navigation.ts'),
    /\/systems\/combat-techniques-gambits/,
  );
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
  assert.match(guide, /content\.stations\.map/);
  assert.match(guide, /Follow the building, service, crafting, or Research link for deeper facts/);
  assert.equal(guide.includes('Stage 0'), false);
  assert.equal(guide.includes('Aimee decision'), false);
  assert.match(
    await read('lib/system-guides.ts'),
    /\/systems\/village-construction/,
  );
  assert.match(
    await read('lib/wiki-navigation.ts'),
    /\/systems\/village-construction/,
  );
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
  const navigation = await read('lib/wiki-navigation.ts');
  assert.match(frame, /wikiNavigationSections/);
  assert.match(frame, /primaryWikiLinks/);
  assert.match(navigation, /label: 'Game systems'/);
  assert.match(navigation, /label: 'Aimee Reference'/);
  for (const href of [
    '/getting-started',
    '/systems',
    '/services',
    '/crafting',
    '/resources',
    '/people',
  ]) {
    assert.match(navigation, new RegExp(href.replaceAll('/', '\\/')));
  }
});

test('wiki navigation uses a standard subject hierarchy without a duplicate reference dump', async () => {
  const navigation = await read('lib/wiki-navigation.ts');
  const frame = await read('components/site-frame.tsx');
  const systems = await read('lib/system-guides.ts');
  const village = await read('app/village/page.tsx');
  const places = await read('app/places/page.tsx');
  const services = await read('app/services/page.tsx');
  const sidebar = navigation.slice(navigation.indexOf('export const wikiNavigationSections'));
  const sidebarHrefs = [...sidebar.matchAll(/href: '([^']+)'/g)].map((match) => match[1]);

  assert.equal(new Set(sidebarHrefs).size, sidebarHrefs.length);
  for (const label of [
    'Start here',
    'Worlds and exploration',
    'Characters and combat',
    'Village and facilities',
    'Crafting and items',
    'Knowledge and records',
    'Quick reference',
    'Aimee Reference',
  ]) assert.match(sidebar, new RegExp(`label: '${label}'`));

  const villageSection = sidebar.slice(
    sidebar.indexOf("label: 'Village and facilities'"),
    sidebar.indexOf("label: 'Crafting and items'"),
  );
  for (const href of ['/village', '/places', '/services', '/systems/village-construction'])
    assert.match(villageSection, new RegExp(href.replaceAll('/', '\\/')));

  const aimeeSection = sidebar.slice(sidebar.lastIndexOf("label: 'Aimee Reference'"));
  assert.deepEqual(
    [...aimeeSection.matchAll(/href: '([^']+)'/g)].map((match) => match[1]),
    ['/references'],
  );
  assert.doesNotMatch(frame, /prepareLinks|referenceLinks|<p>Reference<\/p>/);
  assert.doesNotMatch(systems, /Village, crafting and records/);
  assert.match(village, /Rules and related Village guides/);
  assert.match(village, /Compare Village buildings/);
  assert.match(places, /label: 'Village', href: '\/village'/);
  assert.match(services, /label: 'Village', href: '\/village'/);
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
  assert.match(
    journey,
    /does not prescribe a future building or Research order/,
  );
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
  assert.deepEqual(
    content.pressureTargets.map((target) => target.id),
    [
      'illumination',
      'thermal',
      'hydrology',
      'substrate',
      'relief',
      'vitality',
      'atmosphere',
      'cycle',
    ],
  );
});

test('Party preparation documents the current party limit, gear slots, Gambits, and retained outcomes', async () => {
  await access(path.join(root, 'app/systems/party-preparation/page.tsx'));
  const party = await read('app/systems/party-preparation/page.tsx');
  const systems = await read('lib/system-guides.ts');
  const frame = systems;
  assert.match(party, /five-person party/);
  assert.match(party, /up to four recruited companions/);
  assert.match(
    party,
    /Weapon', 'Off-hand', 'Head', 'Body', 'Hands', 'Feet', 'Tool', 'Keepsake/,
  );
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
  assert.match(
    animals,
    /Interpose, Harrier, Slip Away, Warning Display, or Commit/,
  );
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
  for (const slot of [
    'Weapon',
    'Off-hand',
    'Head',
    'Body',
    'Hands',
    'Feet',
    'Tool',
    'Keepsake',
  ])
    assert.match(guide, new RegExp(slot));
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
  assert.match(
    guide,
    /current Look copy keeps contact, chemical poison, and active encounter as distinct profiles/,
  );
  assert.match(guide, /content\.sites/);
  assert.match(guide, /disclosedResult/);
  assert.match(guide, /on completion it becomes depleted/);
  assert.match(
    guide,
    /do not promise that an undiscovered site is present in every world/,
  );
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
  for (const label of ['Stored', 'Waiting', 'Carried', 'Worn'])
    assert.match(guide, new RegExp(`<h3>${label}</h3>`));
  assert.match(guide, /not silently discarded/);
  assert.match(guide, /worn by another person is marked/);
  assert.match(guide, /Instruments are listed separately from supplies/);
  assert.match(guide, /Previewing changes nothing/);
  assert.match(guide, /price, stock, funds, capacity, or identity changes/);
  assert.match(
    guide,
    /changed item, target, turn, or world state leaves the shown use uncommitted/,
  );
  assert.match(guide, /\/services\/storehouse/);
  assert.match(guide, /\/services\/trading-post/);
  assert.match(guide, /\/services\/recycler/);
  assert.match(systems, /\/systems\/inventory-custody/);
  assert.match(frame, /\/systems\/inventory-custody/);
});

test('shared frame keeps phone search compact and offers persistent light and dark reading themes', async () => {
  const frame = await read('components/site-frame.tsx');
  const theme = await read('components/theme-toggle.tsx');
  const layout = await read('app/layout.tsx');
  const styles = await read('app/globals.css');

  assert.match(frame, /className="brand-tools"/);
  assert.match(frame, /className="wiki-search-submit"/);
  assert.match(frame, /className="mobile-navigation"/);
  assert.match(frame, /Browse the wiki/);
  assert.match(theme, /bookbinder-wiki-theme/);
  assert.match(theme, /prefers-color-scheme: dark/);
  assert.match(theme, /document\.documentElement\.dataset\.theme/);
  assert.match(layout, /colorScheme: 'light dark'/);
  assert.match(styles, /:root\[data-theme='dark'\]/);
  assert.match(styles, /\.wiki-search \{[\s\S]*?flex: none;/);
  assert.match(styles, /\.sidebar-guide-group \{\s*display: contents;/);
});
