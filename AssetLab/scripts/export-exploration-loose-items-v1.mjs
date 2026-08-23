import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createCanvas, ImageData, loadImage } from "@napi-rs/canvas";
import {
  HEIGHT, MINIMAP_SIZE, PIVOT, SOURCE_ALPHA_THRESHOLD, SOURCE_SIZE, WIDTH, acceptedManifest, acceptedManifestPath,
  bakeCatalogueMapSprite, blockedPlaceholderFamilies, catalogueGear, minimapItemSprite, sha256,
} from "../src/exploration-loose-items-v1-kit.js";

const here = path.dirname(fileURLToPath(import.meta.url));
const assetLab = path.resolve(here, "..");
const product = path.join(assetLab, "integration", "exploration-loose-items-v1");
const runtime = path.join(product, "runtime");
const assetsDirectory = path.join(runtime, "assets");
const evidenceDirectory = path.join(product, "evidence");
const terrainPath = path.join(assetLab, "artifacts", "terrain-region-continuity-v1", "evidence", "macro-11x11-redraw-a-2x.png");

fs.rmSync(product, { recursive: true, force: true });
fs.mkdirSync(assetsDirectory, { recursive: true });
fs.mkdirSync(evidenceDirectory, { recursive: true });

function canvasOfRGBA(rgba, width, height) {
  const canvas = createCanvas(width, height);
  canvas.getContext("2d").putImageData(new ImageData(new Uint8ClampedArray(rgba), width, height), 0, 0);
  return canvas;
}

function pngOfRGBA(rgba, width, height) {
  return canvasOfRGBA(rgba, width, height).toBuffer("image/png");
}

async function decodedRGBA(file) {
  const image = await loadImage(file);
  if (image.width !== SOURCE_SIZE || image.height !== SOURCE_SIZE) throw new Error(`source-dimensions:${file}`);
  const canvas = createCanvas(SOURCE_SIZE, SOURCE_SIZE);
  const context = canvas.getContext("2d");
  context.imageSmoothingEnabled = false;
  context.drawImage(image, 0, 0);
  return new Uint8ClampedArray(context.getImageData(0, 0, SOURCE_SIZE, SOURCE_SIZE).data);
}

function scale(source, factor) {
  const canvas = createCanvas(source.width * factor, source.height * factor);
  const context = canvas.getContext("2d");
  context.imageSmoothingEnabled = false;
  context.drawImage(source, 0, 0, canvas.width, canvas.height);
  return canvas;
}

function grayscale(source) {
  const canvas = createCanvas(source.width, source.height);
  const context = canvas.getContext("2d");
  context.drawImage(source, 0, 0);
  const image = context.getImageData(0, 0, canvas.width, canvas.height);
  for (let i = 0; i < image.data.length; i += 4) {
    const value = Math.round(0.2126 * image.data[i] + 0.7152 * image.data[i + 1] + 0.0722 * image.data[i + 2]);
    image.data[i] = value;
    image.data[i + 1] = value;
    image.data[i + 2] = value;
  }
  context.putImageData(image, 0, 0);
  return canvas;
}

function text(context, value, x, y, size = 15, color = "#eadab4", weight = "normal") {
  context.fillStyle = color;
  context.font = `${weight} ${size}px sans-serif`;
  context.fillText(value, x, y);
}

const sourceRecords = [];
const sprites = [];
for (const row of catalogueGear) {
  const sourceFile = fs.readFileSync(row.sourcePath);
  if (sha256(sourceFile) !== row.sourceSHA256) throw new Error(`accepted-source-file-drift:${row.catalogueID}`);
  const sourceRGBA = await decodedRGBA(row.sourcePath);
  const sprite = bakeCatalogueMapSprite(row, sourceRGBA);
  sourceRecords.push({ ...row, sourceRGBA });
  sprites.push(sprite);
}

const assetsByKey = {};
const uniqueAssets = new Map();
function addAsset(sprite, extra = {}) {
  const png = pngOfRGBA(sprite.rgba, sprite.width, sprite.height);
  const fileSHA256 = sha256(png);
  const rgbaSHA256 = sha256(Buffer.from(sprite.rgba));
  const file = `${fileSHA256}.png`;
  if (!uniqueAssets.has(file)) {
    uniqueAssets.set(file, png);
    fs.writeFileSync(path.join(assetsDirectory, file), png);
  }
  assetsByKey[sprite.key] = {
    path: `assets/${file}`,
    width: sprite.width,
    height: sprite.height,
    pivot: sprite.pivot ? [sprite.pivot.x, sprite.pivot.y] : null,
    bounds: sprite.bounds ?? null,
    sha256: fileSHA256,
    rgbaSHA256,
    ...extra,
  };
}
sprites.forEach(sprite => addAsset(sprite, {
  catalogueID: sprite.catalogueID,
  visualFamilyID: sprite.visualFamilyID,
  materialProfileID: sprite.materialProfileID,
  sourcePath: sprite.sourceRelativePath,
  sourceSHA256: sprite.sourceSHA256,
  adaptation: "offline-source-exact-2x2-compaction-and-bottom-anchor",
}));
const minimap = minimapItemSprite();
addAsset(minimap, { category: "item", adaptation: "authored-premade-generic-minimap-category" });

const evidence = {};
function evidencePNG(key, canvas) {
  const buffer = canvas.toBuffer("image/png");
  const file = `${key}.png`;
  fs.writeFileSync(path.join(evidenceDirectory, file), buffer);
  evidence[key] = { path: `evidence/${file}`, sha256: sha256(buffer), width: canvas.width, height: canvas.height };
}

function sourceToMapSheet() {
  const columns = 5;
  const cardWidth = 300;
  const cardHeight = 178;
  const rows = Math.ceil(sprites.length / columns);
  const canvas = createCanvas(columns * cardWidth, 70 + rows * cardHeight);
  const context = canvas.getContext("2d");
  context.fillStyle = "#0e1618";
  context.fillRect(0, 0, canvas.width, canvas.height);
  text(context, "ACCEPTED 32PX CATALOGUE ART → FINAL PREMADE 16×19 MAP PROFILE", 20, 31, 22, "#efe3c4", "bold");
  text(context, "No interpolation · every logical RGB comes from its accepted 2×2 source cell · bottom anchor (8,18)", 20, 55, 13, "#b7c7bf");
  sprites.forEach((sprite, index) => {
    const source = sourceRecords[index];
    const x = (index % columns) * cardWidth + 12;
    const y = 70 + Math.floor(index / columns) * cardHeight;
    context.fillStyle = index % 2 ? "#152225" : "#18272a";
    context.fillRect(x, y, cardWidth - 20, cardHeight - 8);
    text(context, sprite.catalogueID, x + 10, y + 20, 13, "#eadab4", "bold");
    text(context, sprite.visualFamilyID, x + 10, y + 38, 11, "#94aaa2");
    const sourceCanvas = canvasOfRGBA(source.sourceRGBA, SOURCE_SIZE, SOURCE_SIZE);
    const mapCanvas = canvasOfRGBA(sprite.rgba, WIDTH, HEIGHT);
    context.imageSmoothingEnabled = false;
    context.drawImage(sourceCanvas, x + 10, y + 52, 64, 64);
    context.drawImage(mapCanvas, x + 90, y + 52);
    context.drawImage(mapCanvas, x + 130, y + 42, WIDTH * 8, HEIGHT * 8);
    text(context, "32px source ×2", x + 10, y + 131, 10, "#94aaa2");
    text(context, "native", x + 84, y + 131, 10, "#94aaa2");
  });
  return canvas;
}
const comparison = sourceToMapSheet();
evidencePNG("accepted-source-to-map-native-800pct", comparison);
evidencePNG("accepted-source-to-map-native-800pct-grayscale", grayscale(comparison));

const terrain = await loadImage(terrainPath);
const phonePositions = [
  [1,1],[3,1],[5,1],[7,1],[9,1],
  [2,3],[4,3],[6,3],[8,3],[1,5],
  [3,5],[5,5],[7,5],[9,5],[5,8],
];

function phonePage(pageIndex) {
  const pageSprites = sprites.slice(pageIndex * 15, pageIndex * 15 + 15);
  const canvas = createCanvas(368, 800);
  const context = canvas.getContext("2d");
  context.fillStyle = "#0e1618";
  context.fillRect(0, 0, 368, 800);
  text(context, `LOOSE CATALOGUE ITEMS · ${pageIndex + 1}/5`, 12, 28, 17, "#efe3c4", "bold");
  text(context, "exact accepted catalogue identity on the 11×11 terrain consumer", 12, 49, 11, "#aebeb7");
  context.imageSmoothingEnabled = false;
  context.drawImage(terrain, 8, 70, 352, 352);
  pageSprites.forEach((sprite, index) => {
    const [tileX, tileY] = phonePositions[index];
    const source = canvasOfRGBA(sprite.rgba, WIDTH, HEIGHT);
    context.drawImage(source, 8 + tileX * 32, 70 + tileY * 32 - 6, 32, 38);
  });
  context.strokeStyle = "#5a6a65";
  context.strokeRect(7.5, 69.5, 353, 353);
  context.fillStyle = "#172528";
  context.fillRect(8, 438, 352, 342);
  text(context, "VISIBLE IDENTITIES", 20, 465, 14, "#eadab4", "bold");
  pageSprites.forEach((sprite, index) => {
    const column = index % 2;
    const row = Math.floor(index / 2);
    text(context, sprite.catalogueID, 20 + column * 174, 492 + row * 31, 10, "#c5d1cb");
    text(context, sprite.visualFamilyID, 20 + column * 174, 504 + row * 31, 8, "#82968f");
  });
  text(context, "Remembered: same static sprite · Hidden: no item draw", 20, 764, 10, "#aebeb7");
  return canvas;
}
for (let page = 0; page < 5; page += 1) {
  const phone = phonePage(page);
  evidencePNG(`applied-map-catalogue-${page + 1}-368x800`, phone);
  evidencePNG(`applied-map-catalogue-${page + 1}-grayscale-368x800`, grayscale(phone));
}

function visibilitySheet() {
  const canvas = createCanvas(960, 420);
  const context = canvas.getContext("2d");
  context.fillStyle = "#0e1618";
  context.fillRect(0, 0, canvas.width, canvas.height);
  text(context, "STATIC VISIBILITY CONTRACT", 20, 32, 22, "#efe3c4", "bold");
  const representative = sprites.find(sprite => sprite.catalogueID === "ironwork_blade");
  const mapCanvas = canvasOfRGBA(representative.rgba, WIDTH, HEIGHT);
  ["FULL", "REMEMBERED", "HIDDEN"].forEach((label, index) => {
    const x = 20 + index * 310;
    context.fillStyle = "#172528";
    context.fillRect(x, 60, 290, 320);
    text(context, label, x + 14, 88, 15, "#eadab4", "bold");
    if (label !== "HIDDEN") context.drawImage(mapCanvas, x + 75, 112, WIDTH * 8, HEIGHT * 8);
    else text(context, "NO LOOKUP / NO DRAW", x + 46, 222, 14, "#c49090", "bold");
    text(context, label === "REMEMBERED" ? "same static premade bytes" : label === "FULL" ? "same static premade bytes" : "identity undisclosed", x + 14, 360, 11, "#9fb0a9");
  });
  return canvas;
}
const visibility = visibilitySheet();
evidencePNG("visibility-full-remembered-hidden-800pct", visibility);
evidencePNG("visibility-full-remembered-hidden-800pct-grayscale", grayscale(visibility));

function minimapSheet() {
  const canvas = createCanvas(600, 260);
  const context = canvas.getContext("2d");
  context.fillStyle = "#0e1618";
  context.fillRect(0, 0, canvas.width, canvas.height);
  text(context, "GENERIC MINIMAP ITEM CATEGORY", 20, 32, 22, "#efe3c4", "bold");
  text(context, "One disclosed category; catalogue identity remains on the full map only.", 20, 55, 12, "#b7c7bf");
  const native = canvasOfRGBA(minimap.rgba, MINIMAP_SIZE, MINIMAP_SIZE);
  context.drawImage(native, 24, 94);
  context.drawImage(scale(native, 16), 88, 82);
  text(context, "native", 20, 218, 11, "#aebeb7");
  text(context, "true 1600%", 88, 218, 11, "#aebeb7");
  text(context, "hidden = no marker", 310, 142, 15, "#c49090", "bold");
  return canvas;
}
const minimapEvidence = minimapSheet();
evidencePNG("minimap-item-native-1600pct", minimapEvidence);
evidencePNG("minimap-item-native-1600pct-grayscale", grayscale(minimapEvidence));

const sourcePins = Object.fromEntries(catalogueGear.map(row => [row.catalogueID, {
  path: row.sourceRelativePath,
  sha256: row.sourceSHA256,
  visualFamilyID: row.visualFamilyID,
  materialProfileID: row.materialProfileID,
}]));

const manifest = {
  schemaVersion: "exploration-loose-items-v1",
  status: "candidate-unapproved",
  integrationReady: false,
  baselineCommit: "14d2582a2470d843f6b1a40798db29e83f440e02",
  acceptedSource: {
    packID: acceptedManifest.packID,
    canonicalBodySHA256: acceptedManifest.canonicalBodySHA256,
    manifestPath: "AssetLab/integration/mob-gear-sprites-v1/manifest.json",
    manifestSHA256: sha256(fs.readFileSync(acceptedManifestPath)),
    integrationReady: acceptedManifest.integrationReady,
  },
  production: {
    map: { logicalSize: [WIDTH, HEIGHT], pivot: [PIVOT.x, PIVOT.y], tileConsumer: [16, 16], filtering: "nearest-neighbour", premadeOnly: true },
    minimap: { logicalSize: [MINIMAP_SIZE, MINIMAP_SIZE], categories: ["item"], subtypeDisclosure: false, premadeOnly: true },
    adaptation: {
      sourceLogicalSize: [SOURCE_SIZE, SOURCE_SIZE],
      method: "offline-source-exact-2x2-compaction-and-bottom-anchor",
      sourceAlphaThreshold: SOURCE_ALPHA_THRESHOLD,
      interpolation: false,
      blendedPixels: false,
      newRuntimeColors: false,
      runtimeGeneration: false,
    },
    runtimeContents: ["manifest.json", "assets"],
  },
  visibilityContract: {
    full: "exact catalogue sprite",
    remembered: "same exact static catalogue sprite",
    hidden: "no lookup and no draw",
  },
  animationContract: { classification: "static", framesPerIdentity: 1, noRuntimeGeneration: true },
  layerContract: ["terrain", "southWall", "stationaryItem", "party", "selectionAndInteraction", "alerts"],
  requestABI: {
    exactKeys: ["catalogueID", "visibility"],
    catalogueIDs: catalogueGear.map(row => row.catalogueID),
    visibility: ["full", "remembered", "hidden"],
    failClosed: ["unknownCatalogueID", "unknownVisibility", "extraField", "hidden"],
  },
  blockedPlaceholderFamilies,
  sourcePins,
  assetsByKey,
  evidence,
};
manifest.coverage = {
  acceptedCatalogueIDs: catalogueGear.length,
  mapStableKeys: sprites.length,
  minimapStableKeys: 1,
  stableKeys: Object.keys(assetsByKey).length,
  runtimePNGs: uniqueAssets.size,
  visualFamilies: new Set(catalogueGear.map(row => row.visualFamilyID)).size,
};
manifest.runtimeAssetAggregateSHA256 = sha256(Buffer.from(Object.entries(assetsByKey).sort(([a], [b]) => a.localeCompare(b)).map(([key, value]) => `${key}:${value.sha256}:${value.rgbaSHA256}`).join("\n")));
manifest.canonicalBodySHA256 = sha256(Buffer.from(JSON.stringify(manifest)));
fs.writeFileSync(path.join(runtime, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`);

console.log(JSON.stringify({
  body: manifest.canonicalBodySHA256,
  manifestFile: sha256(fs.readFileSync(path.join(runtime, "manifest.json"))),
  acceptedCatalogueIDs: manifest.coverage.acceptedCatalogueIDs,
  stableKeys: manifest.coverage.stableKeys,
  runtimePNGs: manifest.coverage.runtimePNGs,
  runtimeAssetAggregate: manifest.runtimeAssetAggregateSHA256,
}, null, 2));
