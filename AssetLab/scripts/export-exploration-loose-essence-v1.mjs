import { createHash } from "node:crypto";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { createRequire } from "node:module";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const require = createRequire("/Users/aimeepepper/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/package.json");
const sharp = require("sharp");

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const packRoot = join(root, "AssetLab/integration/exploration-loose-essence-v1");
const finalRoot = join(packRoot, "final");
const runtimeRoot = join(packRoot, "runtime");
const runtimeAssets = join(runtimeRoot, "assets");
const evidenceRoot = join(packRoot, "evidence");

const width = 16;
const height = 19;
const transparent = [0, 0, 0, 0];
const roles = Object.freeze({
  d: [2, 2, 2, 255],
  s: [9, 51, 106, 255],
  b: [21, 98, 164, 255],
  B: [50, 137, 201, 255],
  l: [91, 167, 220, 255],
  p: [154, 213, 241, 255],
  h: [223, 244, 250, 255],
  x: [162, 242, 250, 255],
  g: [69, 70, 69, 255],
});

// Authored logical pixels. The central body is a suspended Raw Essence concentration, not the
// separate quartz-lattice Essence Crystal. Only the small, premade energy points change by frame.
const body = Object.freeze([
  [4, [[7, "p"], [8, "h"]]],
  [5, [[6, "B"], [7, "p"], [8, "h"], [9, "l"]]],
  [6, [[5, "b"], [6, "B"], [7, "l"], [8, "h"], [9, "p"], [10, "b"]]],
  [7, [[4, "d"], [5, "b"], [6, "B"], [7, "l"], [8, "p"], [9, "B"], [10, "b"], [11, "d"]]],
  [8, [[4, "d"], [5, "b"], [6, "B"], [7, "h"], [8, "h"], [9, "l"], [10, "b"], [11, "d"]]],
  [9, [[4, "d"], [5, "b"], [6, "B"], [7, "l"], [8, "B"], [9, "B"], [10, "b"], [11, "d"]]],
  [10, [[5, "d"], [6, "b"], [7, "B"], [8, "B"], [9, "b"], [10, "d"]]],
  [11, [[6, "d"], [7, "b"], [8, "b"], [9, "d"]]],
  [12, [[7, "d"], [8, "d"]]],
  [16, [[5, "g"], [6, "d"], [7, "d"], [8, "d"], [9, "d"], [10, "g"]]],
  [17, [[6, "g"], [7, "g"], [8, "g"], [9, "g"]]],
]);

const frameAccents = Object.freeze([
  [[2, 7, "h"], [3, 7, "x"], [13, 9, "l"], [3, 12, "b"]],
  [[3, 6, "l"], [12, 8, "h"], [13, 8, "x"], [13, 12, "b"]],
  [[2, 9, "h"], [3, 9, "x"], [12, 6, "l"], [13, 10, "h"]],
  [[3, 8, "l"], [13, 7, "h"], [12, 12, "l"], [13, 12, "x"]],
]);

function sha(buffer) {
  return createHash("sha256").update(buffer).digest("hex");
}

function frameRGBA(index) {
  const rgba = Buffer.alloc(width * height * 4);
  const set = (x, y, role) => {
    const color = roles[role];
    if (!color || x < 0 || x >= width || y < 0 || y >= height) throw new Error(`bad-pixel:${x},${y},${role}`);
    const offset = (y * width + x) * 4;
    rgba.set(color, offset);
  };
  for (const [y, pixels] of body) for (const [x, role] of pixels) set(x, y, role);
  for (const [x, y, role] of frameAccents[index]) set(x, y, role);
  // One authored internal light step advances with the premade ambient frame.
  const internal = [[8, 9], [8, 8], [7, 8], [7, 9]][index];
  set(internal[0], internal[1], index % 2 === 0 ? "p" : "x");
  return rgba;
}

async function pngFromRGBA(rgba, w = width, h = height) {
  return sharp(rgba, { raw: { width: w, height: h, channels: 4 } })
    .png({ compressionLevel: 9, adaptiveFiltering: false, palette: false })
    .toBuffer();
}

async function writeExact(path, buffer) {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, buffer);
}

function svgLabel(text, w, h, fill = "#eee5d5", size = 18) {
  const safe = text.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
  return Buffer.from(`<svg width="${w}" height="${h}" xmlns="http://www.w3.org/2000/svg"><text x="0" y="${size}" font-family="Menlo, monospace" font-size="${size}" fill="${fill}">${safe}</text></svg>`);
}

async function scaled(buffer, scale) {
  return sharp(buffer).resize(width * scale, height * scale, { kernel: "nearest" }).png().toBuffer();
}

async function checkerTile(w, h, light = false) {
  const a = light ? [235, 231, 221, 255] : [27, 31, 32, 255];
  const b = light ? [217, 211, 198, 255] : [35, 41, 41, 255];
  const rgba = Buffer.alloc(w * h * 4);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    rgba.set(((x >> 3) + (y >> 3)) % 2 ? a : b, (y * w + x) * 4);
  }
  return { rgba, info: { raw: { width: w, height: h, channels: 4 } } };
}

async function mapEvidence(frameBuffer, mode) {
  const phoneW = 368;
  const phoneH = 800;
  const sceneX = 40;
  const sceneY = 150;
  const scale = 2;
  const cols = 9;
  const rows = 11;
  const tileSide = 16;
  const mapW = cols * tileSide;
  const mapH = rows * tileSide + 3;
  const soil = await sharp(join(root, "AssetLab/integration/map-slice-v1/terrain-soil-15.png"))
    .ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const stone = await sharp(join(root, "AssetLab/integration/map-slice-v1/terrain-stone-15.png"))
    .ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const map = Buffer.alloc(mapW * mapH * 4);
  const blitRaw = (source, sw, sh, dx, dy) => {
    for (let y = 0; y < sh; y++) for (let x = 0; x < sw; x++) {
      const si = (y * sw + x) * 4;
      const di = ((dy + y) * mapW + dx + x) * 4;
      const alpha = source[si + 3];
      if (!alpha) continue;
      map[di] = source[si]; map[di + 1] = source[si + 1]; map[di + 2] = source[si + 2]; map[di + 3] = alpha;
    }
  };
  for (let y = 0; y < rows; y++) for (let x = 0; x < cols; x++) {
    const source = (x + y) % 5 === 0 ? stone.data : soil.data;
    blitRaw(source, 16, 16, x * 16, y * 16 + 3);
  }
  const spriteRaw = await sharp(frameBuffer).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  blitRaw(spriteRaw.data, 16, 19, 4 * 16, 5 * 16);
  let mapPng = await sharp(map, { raw: { width: mapW, height: mapH, channels: 4 } })
    .resize(mapW * scale, mapH * scale, { kernel: "nearest" }).png().toBuffer();
  if (mode === "grayscale") mapPng = await sharp(mapPng).grayscale().png().toBuffer();
  const dark = mode !== "light";
  const bg = dark ? "#101516" : "#eee8dc";
  const panel = dark ? "#182020" : "#f8f3e8";
  const text = dark ? "#eee5d5" : "#211e1b";
  const muted = dark ? "#aeb8b2" : "#6f675e";
  const phone = sharp({ create: { width: phoneW, height: phoneH, channels: 4, background: bg } });
  const comps = [
    { input: Buffer.from(`<svg width="328" height="${mapH * scale + 24}" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="${panel}" stroke="${dark ? "#566b65" : "#82796d"}" stroke-width="2"/></svg>`), left: 20, top: sceneY - 12 },
    { input: mapPng, left: sceneX, top: sceneY },
    { input: svgLabel("WORLD", 180, 32, muted, 15), left: 22, top: 32 },
    { input: svgLabel("Loose Raw Essence", 320, 40, text, 24), left: 22, top: 62 },
    { input: svgLabel("A loose concentration rests on the terrain.", 340, 30, muted, 12), left: 22, top: 105 },
    { input: Buffer.from(`<svg width="328" height="54" xmlns="http://www.w3.org/2000/svg"><rect x="1" y="1" width="326" height="52" fill="${dark ? "#26302e" : "#d8ccb7"}" stroke="${dark ? "#d8bd82" : "#6d5938"}" stroke-width="2"/><text x="164" y="34" text-anchor="middle" font-family="Menlo,monospace" font-size="17" fill="${text}">Use Tile</text></svg>`), left: 20, top: 724 },
  ];
  return phone.composite(comps).png().toBuffer();
}

async function buildEvidence(framePNGs) {
  const contactW = 1120;
  const contactH = 900;
  const base = sharp({ create: { width: contactW, height: contactH, channels: 4, background: "#101516" } });
  const composites = [
    { input: svgLabel("LOOSE RAW ESSENCE · PREMADE 16×19 MAP SPRITE", 1000, 42, "#eee5d5", 24), left: 34, top: 24 },
    { input: svgLabel("full visibility: shared display clock selects exact frame · remembered: frame 0 · hidden: no request", 1020, 30, "#aeb8b2", 14), left: 34, top: 62 },
    { input: svgLabel("NATIVE", 160, 30, "#d8bd82", 16), left: 34, top: 116 },
    { input: svgLabel("400%", 160, 30, "#d8bd82", 16), left: 34, top: 220 },
  ];
  for (let i = 0; i < framePNGs.length; i++) {
    const x = 150 + i * 220;
    const nativeBg = await checkerTile(64, 76);
    const native = await sharp(nativeBg.rgba, nativeBg.info).composite([{ input: framePNGs[i], left: 24, top: 28 }]).png().toBuffer();
    const four = await scaled(framePNGs[i], 4);
    const fourBg = await checkerTile(128, 152);
    const fourPanel = await sharp(fourBg.rgba, fourBg.info).composite([{ input: four, left: 32, top: 38 }]).png().toBuffer();
    composites.push({ input: native, left: x, top: 100 });
    composites.push({ input: svgLabel(`frame ${i}`, 160, 24, "#eee5d5", 13), left: x, top: 180 });
    composites.push({ input: fourPanel, left: x, top: 214 });
  }
  const dark = await mapEvidence(framePNGs[1], "dark");
  const light = await mapEvidence(framePNGs[1], "light");
  const gray = await mapEvidence(framePNGs[0], "grayscale");
  composites.push({ input: await sharp(dark).resize(230, 500, { fit: "fill", kernel: "nearest" }).png().toBuffer(), left: 40, top: 390 });
  composites.push({ input: await sharp(light).resize(230, 500, { fit: "fill", kernel: "nearest" }).png().toBuffer(), left: 300, top: 390 });
  composites.push({ input: await sharp(gray).resize(230, 500, { fit: "fill", kernel: "nearest" }).png().toBuffer(), left: 560, top: 390 });
  composites.push({ input: svgLabel("dark", 90, 24, "#d8bd82", 14), left: 40, top: 365 });
  composites.push({ input: svgLabel("light", 90, 24, "#d8bd82", 14), left: 300, top: 365 });
  composites.push({ input: svgLabel("literal grayscale", 180, 24, "#d8bd82", 14), left: 560, top: 365 });
  const contact = await base.composite(composites).png().toBuffer();
  await writeExact(join(evidenceRoot, "loose-essence-contact-sheet.png"), contact);
  await writeExact(join(evidenceRoot, "loose-essence-dark-368x800.png"), dark);
  await writeExact(join(evidenceRoot, "loose-essence-light-368x800.png"), light);
  await writeExact(join(evidenceRoot, "loose-essence-grayscale-368x800.png"), gray);
}

async function main() {
  await rm(finalRoot, { recursive: true, force: true });
  await rm(runtimeRoot, { recursive: true, force: true });
  await rm(evidenceRoot, { recursive: true, force: true });
  await mkdir(finalRoot, { recursive: true });
  await mkdir(runtimeAssets, { recursive: true });
  await mkdir(evidenceRoot, { recursive: true });

  const framePNGs = [];
  const assetsByKey = {};
  for (let index = 0; index < 4; index++) {
    const rgba = frameRGBA(index);
    const png = await pngFromRGBA(rgba);
    const fileSHA256 = sha(png);
    const rgbaSHA256 = sha(rgba);
    const stableKey = `loose_essence/ordinary/frame-${index}`;
    const finalPath = `final/loose-essence-frame-${index}.png`;
    const runtimePath = `assets/${fileSHA256}.png`;
    await writeExact(join(packRoot, finalPath), png);
    await writeExact(join(runtimeRoot, runtimePath), png);
    framePNGs.push(png);
    assetsByKey[stableKey] = {
      path: runtimePath,
      sourcePath: finalPath,
      width,
      height,
      pivot: [8, 18],
      fileSHA256,
      decodedRGBASHA256: rgbaSHA256,
      frame: index,
      resourceID: "essence_raw",
      animation: "premade-ambient-energy",
    };
  }

  await buildEvidence(framePNGs);
  const sourcePaths = {
    rawEssenceInventory: "AssetLab/integration/resource-sprites-v1/inventory/essence_raw.png",
    rawEssenceMap: "AssetLab/integration/resource-sprites-v1/map/essence_raw.png",
    rawEssenceField: "AssetLab/integration/resource-sprites-v1/field/essence_raw.png",
    essenceCrystalNegativeReference: "AssetLab/integration/exploration-catalogue-objects-v1/runtime/assets/478f94342cdee30d8e20be97e89c83e0cd0e3cb597cd6059fbee70334c45f93d.png",
    imagegenSourceReference: "AssetLab/integration/exploration-loose-essence-v1/source/imagegen-reference-nonproduction.png",
  };
  const sourceReferences = {};
  for (const [name, relative] of Object.entries(sourcePaths)) {
    const bytes = await readFile(join(root, relative));
    sourceReferences[name] = { path: relative, sha256: sha(bytes), productionSource: name !== "imagegenSourceReference" };
  }
  const productionAggregate = sha(Buffer.concat(framePNGs));
  const evidence = {};
  for (const file of ["loose-essence-contact-sheet.png", "loose-essence-dark-368x800.png", "loose-essence-light-368x800.png", "loose-essence-grayscale-368x800.png"]) {
    const bytes = await readFile(join(evidenceRoot, file));
    evidence[file] = { path: `evidence/${file}`, sha256: sha(bytes) };
  }
  const body = {
    schemaVersion: "exploration-loose-essence-v1",
    status: "candidate-unapproved",
    integrationReady: false,
    resourceID: "essence_raw",
    stableIdentity: "loose_essence",
    assetType: "final-premade-logical-pixel-art-candidate",
    runtimeGeneratedPixels: false,
    canvas: { width, height, pivot: [8, 18], tileSurface: [16, 16] },
    selection: {
      full: "presentationTick modulo 4 selects an exact premade frame",
      disclosedNonFull: "previously revealed fringe or hidden selects frame 0",
      undisclosed: "never-revealed fringe or hidden performs no request and draws nothing",
      temporalSelector: "presentationTick is the sole temporal selector",
      sharedClockOnly: true,
      gameplayStateMutation: false,
    },
    layerOrder: ["terrain-and-south-wall", "stationary-loose-essence", "party", "selection-and-interaction", "alerts-and-HUD"],
    semanticIdentity: {
      owns: "loose Raw Essence wildDrop only",
      excludes: ["spendable Essence", "Essence Crystal", "Mote", "resource node", "depletion state", "pickup transition"],
      recolor: "none; preserve established Raw Essence blue/luminous palette",
    },
    assetsByKey,
    sourceReferences,
    evidence,
    productionAggregateSHA256: productionAggregate,
    nativeHandoff: {
      request: "TileContent.wildDrop(resource: Resources.essenceRaw, amount: positive)",
      stableKeyPrefix: "loose_essence/ordinary/",
      mapSocket: "16x19 bottom-pivot (8,18)",
      stateInputs: ["visibility", "presentationTick"],
      forbiddenInputs: [
        "amount beyond positive eligibility",
        "point or any coordinate",
        "mapSeed",
        "worldRunID or runIndex",
        "phaseOffset or per-tile stable phase",
        "player inventory",
        "spendable Essence",
        "Essence Crystal state",
      ],
      temporalSelection: "frame = presentationTick modulo 4; no coordinate, seed, run or phase offset participates",
      minimapKey: null,
      recolor: false,
      gameplayMutation: false,
    },
  };
  const canonicalBodySHA256 = sha(Buffer.from(JSON.stringify(body)));
  const manifest = { ...body, canonicalBodySHA256 };
  await writeExact(join(runtimeRoot, "manifest.json"), Buffer.from(`${JSON.stringify(manifest, null, 2)}\n`));
  console.log(JSON.stringify({ canonicalBodySHA256, productionAggregateSHA256: productionAggregate, assets: Object.keys(assetsByKey).length, evidence }, null, 2));
}

await main();
