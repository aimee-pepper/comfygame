import assert from 'node:assert/strict';
import { access, readFile } from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = relative => readFile(path.join(root, relative), 'utf8');

test('World Writing teaches the authored player order', async () => {
  const source = await read('app/systems/world-writing/page.tsx');
  const titles = ['Choose a hand', 'Choose ink', 'Place and connect', 'Review and Bind'];
  const positions = titles.map(title => source.indexOf(title));
  assert.ok(positions.every(position => position >= 0));
  assert.deepEqual([...positions].sort((a, b) => a - b), positions);
});

test('player reference indexes are tables linked to individual pages', async () => {
  for (const relative of ['app/resources/page.tsx', 'app/equipment/page.tsx', 'app/people/page.tsx', 'app/places/page.tsx']) {
    const source = await read(relative);
    assert.match(source, /<table>/);
    assert.match(source, /<Link/);
  }
  for (const relative of ['app/resources/[slug]/page.tsx', 'app/equipment/[slug]/page.tsx', 'app/people/[slug]/page.tsx', 'app/places/[slug]/page.tsx']) {
    await access(path.join(root, relative));
  }
});

test('player navigation excludes internal wiki architecture', async () => {
  const source = `${await read('components/site-frame.tsx')}\n${await read('app/page.tsx')}\n${await read('app/people/page.tsx')}`;
  for (const forbidden of ['Visual Assets', 'Decisions / History', 'Roadmap', 'Stable ID', 'Source path', 'Provenance']) {
    assert.equal(source.includes(forbidden), false, forbidden);
  }
});

test('sanitized player snapshot has useful implemented coverage and inline visuals', async () => {
  const content = JSON.parse(await read('data/player-content.json'));
  assert.equal(content.resources.length, 23);
  assert.equal(content.items.length, 103);
  assert.equal(content.travellers.length, 8);
  assert.equal(content.stations.length, 22);
  assert.ok(content.resources.some(entry => entry.assetURL));
  assert.ok(content.items.some(entry => entry.assetURL));
  assert.ok(content.terrain.length > 0);
  assert.ok(content.writingAssetURL);
  await access(path.join(root, 'public', content.writingAssetURL));
});

test('PlayerWiki remains a separate application from the internal GameWiki', async () => {
  const readme = await read('README.md');
  assert.match(readme, /separate from `GameWiki`/);
  assert.match(readme, /player-facing/);
});
