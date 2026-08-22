import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const sha256 = value => crypto.createHash("sha256").update(value).digest("hex");
const read = relative => fs.readFileSync(path.join(repoRoot, relative));

const pins = [
  ["0eb2720e", "AssetLab/artifacts/writing-page-a1-v0.1/manifest.json",
    "6a8eff7e038f7789a1839ab7c5537f1847163bd1f4d311cecdc46e983793801d",
    "89ae14e9f0ecfdee5e35ced08df0f9d9ba76e224fc4908be271f50c1bd01a627"],
  ["d0b1359c", "AssetLab/artifacts/writing-page-a2-v0.1/manifest.json",
    "9e7c00c5fda50eeb0c7ecc7ccbe3538a962987e6fbc797d9b5af1abc0af6e1bf",
    "19f45f8188fd99a9308ac2b3d29adfde070a5971eb103ea86a8310e754821b90"],
  ["7db995f9", "AssetLab/artifacts/writing-desk-a3-v0.1/manifest.json",
    "0ccac5d60e31f439ddee2954416b036cd723322c6e2b4c106ffc8f619b6c89eb",
    "54340469ed3f0fe308532470c8cc38716f38581cb3d7f0cb544836c8b7536c8c"],
];

for (const [commit, relative, manifestHash, bodyHash] of pins) {
  const bytes = read(relative);
  const value = JSON.parse(bytes);
  assert.equal(sha256(bytes), manifestHash, `${commit} manifest drift`);
  assert.equal(value.canonicalBodySha256, bodyHash, `${commit} body drift`);
  assert.equal(value.integrationReady, false, `${commit} must remain authoring-only`);
}

for (const [, relative] of pins.slice(0, 2)) {
  const value = JSON.parse(read(relative));
  for (const output of value.outputs.filter(entry => entry.file.startsWith("source/"))) {
    const source = path.join(path.dirname(relative), output.file);
    assert.equal(sha256(read(source)), output.sha256, `${source} drift`);
  }
}

for (const forbidden of [
  "AssetLab/artifacts/writing-page-a1-v0.1/contact",
  "AssetLab/artifacts/writing-page-a1-v0.1/evidence",
  "AssetLab/artifacts/writing-page-a2-v0.1/contact",
  "AssetLab/artifacts/writing-page-a2-v0.1/evidence",
  "AssetLab/artifacts/writing-desk-a3-v0.1/contact",
  "AssetLab/artifacts/writing-desk-a3-v0.1/evidence",
]) {
  assert.equal(fs.existsSync(path.join(repoRoot, forbidden)), false,
    `${forbidden} is review evidence and must not be packaged`);
}

for (const source of [
  "AssetLab/src/writing-page-a1-kit.js",
  "AssetLab/src/writing-page-a2-kit.js",
  "AssetLab/src/writing-desk-a3-kit.js",
]) {
  assert.equal(fs.existsSync(path.join(repoRoot, source)), true, `missing ${source}`);
}

console.log("Writing Desk authoring dependencies pinned; exhaustive runtime pack remains pending.");
