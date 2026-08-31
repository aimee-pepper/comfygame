import { cp, mkdir, readFile, rm } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = resolve(root, "..");
const dist = join(root, "dist");
await rm(dist, { recursive: true, force: true });
await mkdir(dist, { recursive: true });
await cp(join(root, "public"), dist, { recursive: true });
await cp(join(root, "generated"), join(dist, "generated"), { recursive: true });
const data = JSON.parse(await readFile(join(root, "generated/wiki-data.json"), "utf8"));
let visualCount = 0;
for (const family of data.visualAssets?.families ?? []) {
  for (const asset of family.assets ?? []) {
    if (!asset.previewURL || !asset.sourcePath) continue;
    const destination = join(dist, asset.previewURL);
    await mkdir(dirname(destination), { recursive: true });
    await cp(join(repoRoot, asset.sourcePath), destination);
    visualCount += 1;
  }
}
console.log(`Built local wiki at ${dist} with ${visualCount} manifested visual records`);
