import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "../..");
const markdownPath = path.join(root, "docs/combat-tree-node-copy-current.md");
const authorityPath = path.join(root, "docs/combat-tree-v2-authority.json");
const outputPath = path.join(root, "docs/combat-tree-v2-effect-copy.generated.json");

const markdown = fs.readFileSync(markdownPath, "utf8");
const authorityRaw = fs.readFileSync(authorityPath, "utf8");
const authority = JSON.parse(authorityRaw);
const slug = (name) => name.toLowerCase().replace(/[’']/g, "_")
  .replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, "");

const rows = [...markdown.matchAll(/^\| ([^|]+) \| ([^|]+) \|$/gm)]
  .filter(([, name]) => name !== "Node")
  .map(([, name, effect]) => ({ slug: slug(name), effect: effect.trim() }));
if (rows.length !== 72) throw new Error(`combat-effect-row-count:${rows.length}`);
if (new Set(rows.map((row) => row.slug)).size !== rows.length) {
  throw new Error("duplicate-combat-effect-slug");
}
if (rows.some((row) => !/[.!?]$/.test(row.effect))) {
  throw new Error("combat-effect-copy-missing-terminal-punctuation");
}

const copyBySlug = new Map(rows.map((row) => [row.slug, row.effect]));
const effectCopyByNode = {};
for (const tree of authority.trees) {
  for (const discipline of tree.disciplines) {
    for (const nodeSlug of discipline.nodes) {
      const effect = copyBySlug.get(nodeSlug);
      if (!effect) throw new Error(`missing-combat-effect-copy:${nodeSlug}`);
      effectCopyByNode[`combat.${tree.id}.${discipline.id}.${nodeSlug}`] = effect;
      copyBySlug.delete(nodeSlug);
    }
  }
}
if (copyBySlug.size) throw new Error(`orphan-combat-effect-copy:${[...copyBySlug.keys()].join(",")}`);

const sha256 = (value) => crypto.createHash("sha256").update(value).digest("hex");
const payload = {
  schemaVersion: 1,
  graphVersion: authority.graphVersion,
  sourceMarkdown: "docs/combat-tree-node-copy-current.md",
  sourceMarkdownSHA256: sha256(markdown),
  combatAuthority: "docs/combat-tree-v2-authority.json",
  combatAuthoritySHA256: sha256(authorityRaw),
  effectCopyByNode,
};
const expected = `${JSON.stringify(payload, null, 2)}\n`;

if (process.argv.includes("--write")) {
  fs.writeFileSync(outputPath, expected);
  console.log(`Exported ${path.relative(root, outputPath)} (${Object.keys(effectCopyByNode).length} nodes)`);
} else {
  if (!fs.existsSync(outputPath) || fs.readFileSync(outputPath, "utf8") !== expected) {
    throw new Error("stale-combat-v2-effect-copy-run-npm-run-generate:combat-copy");
  }
  console.log("Combat v2 Effect-copy artifact is current.");
}
