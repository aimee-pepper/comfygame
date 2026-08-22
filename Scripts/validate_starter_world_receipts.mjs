#!/usr/bin/env node

// Re-run the three frozen starter pages through the live Worldgen bridge. This keeps a generator
// change from silently turning a curated opening page into a different or newly lethal world.

import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { generateLiveWorld } from "../AssetLab/src/live-worldgen-bridge.js";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const authority = JSON.parse(await readFile(join(root, "docs/world-pages-authority.json"), "utf8"));
const starters = authority.definitions.filter(row => row.disposition === "starterUnique");

function rowsToObject(rows) {
  return Object.fromEntries(rows.map(row => [row.id, row.quantity]));
}

function reachableCounts(world) {
  const passable = new Set(world.cells
    .filter(cell => cell.ground !== "deepWater" && cell.ground !== "chasm")
    .map(cell => `${cell.x},${cell.y}`));
  const start = `${world.entry.x},${world.entry.y}`;
  const reached = new Set(passable.has(start) ? [start] : []);
  const queue = reached.size ? [world.entry] : [];
  for (let index = 0; index < queue.length; index += 1) {
    const point = queue[index];
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const next = { x: point.x + dx, y: point.y + dy };
      const key = `${next.x},${next.y}`;
      if (passable.has(key) && !reached.has(key)) {
        reached.add(key);
        queue.push(next);
      }
    }
  }
  return { passableTiles: passable.size, reachablePassableTiles: reached.size };
}

function summarize(world) {
  return {
    profile: "ordinary",
    terrain: rowsToObject(world.terrain),
    flora: rowsToObject(world.flora),
    ordinaryCreatureCount: world.mobs.reduce((sum, row) => sum + row.quantity, 0),
    apexCount: world.apexes.reduce((sum, row) => sum + row.quantity, 0),
    hostileFloraCount: world.hostileFlora.reduce((sum, row) => sum + row.quantity, 0),
    writingCount: world.writings.reduce((sum, row) => sum + row.quantity, 0),
    rawEssenceObtainable: world.diagnostics.rawEssenceObtainable,
    projectedCollapseTurn: world.diagnostics.projectedCollapseTurn,
    ...reachableCounts(world),
  };
}

assert.equal(starters.length, 3, "exactly three starter pages must be validated");
for (const starter of starters) {
  const world = await generateLiveWorld({
    seed: starter.seed,
    symbols: starter.symbols.map(mark => mark.id),
    scale: starter.validationReceipt.profile,
  });
  assert.deepEqual(summarize(world), starter.validationReceipt,
    `${starter.id} no longer matches its frozen current-generator receipt`);
}

console.log(`Starter World Page receipts valid: ${starters.map(row => `${row.title}#${row.seed}`).join(", ")}.`);
