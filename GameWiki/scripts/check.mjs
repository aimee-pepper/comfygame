import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const wikiRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = resolve(wikiRoot, "..");
const sha = value => createHash("sha256").update(value).digest("hex");
const manifest = JSON.parse(await readFile(join(wikiRoot, "generated/manifest.json"), "utf8"));
const failures = [];

for (const [path, expected] of Object.entries(manifest.inputs)) {
  const actual = sha(await readFile(join(repoRoot, path)));
  if (actual !== expected) failures.push(`stale input ${path}`);
}
for (const [path, expected] of Object.entries(manifest.outputs)) {
  const actual = sha(await readFile(join(wikiRoot, path)));
  if (actual !== expected) failures.push(`changed output ${path}`);
}
const data = JSON.parse(await readFile(join(wikiRoot, "generated/wiki-data.json"), "utf8"));
if (data.schemaVersion !== 1 || manifest.schemaVersion !== 1) failures.push("unsupported generated schema");
if (data.generatedAtSourceHash !== manifest.aggregateSourceHash) failures.push("source hash mismatch");

if (failures.length) {
  console.error(failures.join("\n"));
  process.exit(1);
}
console.log(`Fresh: ${Object.keys(manifest.inputs).length} inputs match ${manifest.aggregateSourceHash}.`);
