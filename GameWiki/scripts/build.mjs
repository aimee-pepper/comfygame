import { cp, mkdir, rm } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const dist = join(root, "dist");
await rm(dist, { recursive: true, force: true });
await mkdir(dist, { recursive: true });
await cp(join(root, "public"), dist, { recursive: true });
await cp(join(root, "generated"), join(dist, "generated"), { recursive: true });
console.log(`Built local wiki at ${dist}`);
