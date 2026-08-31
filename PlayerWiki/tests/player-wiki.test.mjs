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

test('player reference indexes are tables linked to individual pages', async () => {
  for (const relative of [
    'app/resources/page.tsx',
    'app/equipment/page.tsx',
    'app/people/page.tsx',
    'app/places/page.tsx',
  ]) {
    const source = await read(relative);
    assert.match(source, /<table>/);
    assert.match(source, /<Link/);
  }
  for (const relative of [
    'app/resources/[slug]/page.tsx',
    'app/equipment/[slug]/page.tsx',
    'app/people/[slug]/page.tsx',
    'app/places/[slug]/page.tsx',
  ]) {
    await access(path.join(root, relative));
  }
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
  assert.equal(content.stations.length, 22);
  assert.ok(content.resources.some((entry) => entry.assetURL));
  assert.ok(content.items.some((entry) => entry.assetURL));
  assert.ok(content.terrain.length > 0);
  assert.ok(content.writingAssetURL);
  await access(path.join(root, 'public', content.writingAssetURL));
  assert.deepEqual(content.writingVisuals.map((visual) => visual.id), ['tool', 'mark', 'link']);
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
  const resourceDetail = await read('app/resources/[slug]/page.tsx');
  assert.match(resourceDetail, /Craft recipes/);
  assert.match(resourceDetail, /Building recipes/);
  const craftingIndex = await read('app/crafting/page.tsx');
  const craftingDetail = await read('app/crafting/[slug]/page.tsx');
  assert.match(craftingIndex, /PixelImage/);
  assert.match(craftingDetail, /recipe-ingredient/);
  assert.match(craftingDetail, /Result image/);
  assert.match(craftingDetail, /crafting-station/);
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
  assert.match(personPage, /PixelImage/);
  assert.match(personPage, /character cameo/);
  assert.match(personPage, /Hints for finding them/);
  assert.match(personPage, /Diary pages/);
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
});
