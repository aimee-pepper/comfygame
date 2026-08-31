import assert from 'node:assert/strict';
import { access, readFile } from 'node:fs/promises';
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
    'World mineral node · Extraction rank 0',
  );
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
    'refinery',
    'writing-ink',
  ]) {
    assert.match(crafting, new RegExp(`slug: '${system}'`));
  }
  const resourceIndex = await read('app/resources/page.tsx');
  assert.match(resourceIndex, /Crafts used in/);
  assert.match(resourceIndex, /Building material\?/);
  assert.match(resourceIndex, /How obtained/);
  assert.match(resourceIndex, /Trade status/);
  const resourceDetail = await read('app/resources/[slug]/page.tsx');
  assert.match(resourceDetail, /Craft recipes/);
  assert.match(resourceDetail, /Building recipes/);
  assert.match(resourceDetail, /How to obtain it/);
  assert.match(resourceDetail, /Other current consumers/);
  assert.match(resourceDetail, /Exact resource use/);
  const craftingIndex = await read('app/crafting/page.tsx');
  const craftingDetail = await read('app/crafting/[slug]/page.tsx');
  assert.match(craftingIndex, /PixelImage/);
  assert.match(craftingIndex, /All current recipes by station/);
  assert.match(craftingIndex, /Exact ingredients and costs/);
  assert.match(craftingIndex, /Primary use/);
  assert.match(craftingIndex, /resultHref/);
  assert.match(craftingDetail, /recipe-ingredient/);
  assert.match(craftingDetail, /Result image/);
  assert.match(craftingDetail, /crafting-station/);
  assert.match(craftingDetail, /Access and readiness/);
  assert.match(craftingDetail, /Material choices/);
  assert.match(craftingDetail, /Commit and result/);
  assert.match(craftingDetail, /serviceForStation/);
  assert.match(crafting, /materialChoice/);
  assert.match(crafting, /commitResult/);
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

test('every live person includes every authored diary page and every authored location hint', async () => {
  const content = JSON.parse(await read('data/player-content.json'));
  const authored = JSON.parse(
    await read('../Sources/Content/Data/travellers.json'),
  );
  for (const person of content.travellers) {
    const authoredPerson = authored.travellers.find(
      (entry) => entry.id === person.id,
    );
    const pages = authored.pages.filter((page) => page.diary === person.id);
    assert.ok(authoredPerson, person.id);
    assert.deepEqual(
      person.hints,
      authoredPerson.signature.map((entry) => entry.passage),
      `${person.id} hints`,
    );
    assert.equal(
      person.diaryPages.length,
      pages.length,
      `${person.id} diary pages`,
    );
    assert.deepEqual(
      person.diaryPages.map((page) => page.prose),
      pages.map((page) => page.prose),
      `${person.id} diary prose`,
    );
  }
  const personPage = await read('app/people/[slug]/page.tsx');
  const peopleDirectory = await read('app/people/page.tsx');
  assert.match(personPage, /PixelImage/);
  assert.match(personPage, /character cameo/);
  assert.match(personPage, /Hints for finding them/);
  assert.match(personPage, /Diary pages/);
  assert.match(personPage, /person-record-navigation/);
  assert.match(personPage, /#location-hints/);
  assert.match(personPage, /#diary-pages/);
  assert.match(personPage, /Diary page \{index \+ 1\} of/);
  assert.match(peopleDirectory, /people-directory/);
  assert.match(peopleDirectory, /#location-hints/);
  assert.match(peopleDirectory, /#diary-pages/);
  for (const person of content.travellers) {
    assert.ok(person.assetURL, `${person.name} cameo URL`);
    assert.match(person.assetURL, /^\/game-assets\/people\/.+-cameo\.svg$/);
    const cameo = await read(`public${person.assetURL}`);
    assert.match(cameo, /viewBox="0 0 16 16"/);
    assert.match(cameo, /shape-rendering="crispEdges"/);
  }
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
  assert.match(bestiary, /No individual creature record is currently published/);
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

test('systems hub groups every current player guide into useful routes', async () => {
  const hub = await read('app/systems/page.tsx');
  await access(path.join(root, 'app/systems/page.tsx'));
  for (const label of [
    'Journey and worlds',
    'Combat and preparation',
    'Crafting and materials',
    'Village services',
    'Reference',
  ]) assert.match(hub, new RegExp(label));
  for (const href of ['/getting-started', '/systems/world-writing', '/systems/exploration', '/systems/combat', '/services', '/resources', '/glossary']) assert.match(hub, new RegExp(href.replaceAll('/', '\\/')));
  assert.match(hub, /PixelImage/);
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
  assert.match(frame, /\['\/systems', 'Systems overview'\]/);
  assert.match(frame, /href="\/systems">Systems<\/Link>/);
  assert.match(frame, /<p>Prepare<\/p>/);
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
  const systems = await read('app/systems/page.tsx');
  const frame = await read('components/site-frame.tsx');
  assert.match(journey, /Write, review, and Bind/);
  assert.match(journey, /Enter and explore the generated world/);
  assert.match(journey, /Current Village construction/);
  assert.match(journey, /Services, crafting, and Research/);
  assert.match(journey, /does not prescribe a future building or Research order/);
  assert.match(journey, /constructionCost/);
  assert.match(journey, /\/systems\/world-writing/);
  assert.match(journey, /\/systems\/exploration/);
  assert.match(journey, /\/systems\/research/);
  assert.match(systems, /Your current journey/);
  assert.match(frame, /\/journey/);
  assert.equal(journey.includes('Stage 0'), false);
  assert.equal(journey.includes('Stage 1'), false);
  assert.equal(journey.includes('Aimee decision'), false);
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
  assert.match(research, /\/places\/workshop/);
  assert.match(sync, /researchSource/);
  assert.match(sync, /researchBranches/);
  assert.match(sync, /researchNodes/);
  assert.equal(research.includes('Stage 0'), false);
  assert.equal(research.includes('Aimee decision'), false);
});
