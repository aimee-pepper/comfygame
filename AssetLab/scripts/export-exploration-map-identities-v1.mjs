import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import {
  HEIGHT, MINIMAP_SIZE, PIVOT, WIDTH, enumerateMinimapSprites, enumerateSprites,
  sha256, sourceIdentities,
} from "../src/exploration-map-identities-v1-kit.js";

const require = createRequire(import.meta.url);
const { createCanvas, loadImage } = require("@napi-rs/canvas");
const root = path.resolve(import.meta.dirname, "..");
const productRoot = path.join(root, "integration", "exploration-map-identities-v1");
const runtimeRoot = path.join(productRoot, "runtime");
const assetRoot = path.join(runtimeRoot, "assets");
const evidenceRoot = path.join(productRoot, "evidence");
const sourceRoot = path.join(productRoot, "source-generated");

fs.rmSync(runtimeRoot, { recursive: true, force: true });
fs.rmSync(evidenceRoot, { recursive: true, force: true });
fs.mkdirSync(assetRoot, { recursive: true });
fs.mkdirSync(evidenceRoot, { recursive: true });

const canvasOf = (rgba, width, height) => {
  const canvas = createCanvas(width, height);
  const context = canvas.getContext("2d");
  const image = context.createImageData(width, height);
  image.data.set(rgba);
  context.putImageData(image, 0, 0);
  return canvas;
};

const scale = (canvas, factor) => {
  const output = createCanvas(canvas.width * factor, canvas.height * factor);
  const context = output.getContext("2d");
  context.imageSmoothingEnabled = false;
  context.drawImage(canvas, 0, 0, output.width, output.height);
  return output;
};

const grayscale = canvas => {
  const output = createCanvas(canvas.width, canvas.height);
  const context = output.getContext("2d");
  context.drawImage(canvas, 0, 0);
  const image = context.getImageData(0, 0, output.width, output.height);
  for (let index = 0; index < image.data.length; index += 4) {
    const value = Math.round(image.data[index] * 0.2126 + image.data[index + 1] * 0.7152 + image.data[index + 2] * 0.0722);
    image.data[index] = value;
    image.data[index + 1] = value;
    image.data[index + 2] = value;
  }
  context.putImageData(image, 0, 0);
  return output;
};

const writePNG = (file, canvas) => {
  const buffer = canvas.toBuffer("image/png");
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, buffer);
  return { sha256: sha256(buffer), width: canvas.width, height: canvas.height };
};

const sprites = [...enumerateSprites(), ...enumerateMinimapSprites()];
const assetsByKey = {};
const uniqueAssets = new Map();
for (const sprite of sprites) {
  const canvas = canvasOf(sprite.rgba, sprite.width, sprite.height);
  const png = canvas.toBuffer("image/png");
  const pngSHA256 = sha256(png);
  const file = `assets/${pngSHA256}.png`;
  if (!uniqueAssets.has(pngSHA256)) {
    fs.writeFileSync(path.join(runtimeRoot, file), png);
    uniqueAssets.set(pngSHA256, file);
  }
  assetsByKey[sprite.key] = {
    path: file,
    sha256: pngSHA256,
    rgbaSHA256: sha256(Buffer.from(sprite.rgba)),
    width: sprite.width,
    height: sprite.height,
    pivot: sprite.pivot,
    identity: sprite.identity,
    kind: sprite.kind,
    state: sprite.state,
    frame: sprite.frame,
    frameCount: sprite.frameCount,
    animation: sprite.animation,
  };
}

const sourceFiles = fs.readdirSync(sourceRoot).filter(file => file.endsWith(".png")).sort();
const sourceReferences = Object.fromEntries(sourceFiles.map(file => [file.replace(".png", ""), {
  path: `source-generated/${file}`,
  sha256: sha256(fs.readFileSync(path.join(sourceRoot, file))),
  productionSource: false,
  purpose: "built-in image-generation composition reference; manually normalized logical sprite is the runtime authority",
}]));

const evidence = {};
function evidencePNG(name, canvas) {
  evidence[name] = { path: `evidence/${name}.png`, ...writePNG(path.join(evidenceRoot, `${name}.png`), canvas) };
}

const sourceSheet = createCanvas(1200, 2160);
{
  const context = sourceSheet.getContext("2d");
  context.fillStyle = "#101719";
  context.fillRect(0, 0, sourceSheet.width, sourceSheet.height);
  context.fillStyle = "#f1e5c7";
  context.font = "bold 24px sans-serif";
  context.fillText("EXPLORATION IDENTITIES · GENERATED SOURCE REFERENCES", 24, 38);
  context.fillStyle = "#b8c6bd";
  context.font = "14px sans-serif";
  context.fillText("NON-RUNTIME SOURCE · final authority is the manually cleaned 16×19 sheet", 24, 62);
  const order = sourceIdentities.map(row => row.id);
  for (let index = 0; index < order.length; index += 1) {
    const id = order[index];
    const image = await loadImage(path.join(sourceRoot, `${id}.png`));
    const x = 24 + (index % 5) * 232;
    const y = 88 + Math.floor(index / 5) * 520;
    context.fillStyle = "#172226";
    context.fillRect(x, y, 216, 470);
    context.imageSmoothingEnabled = false;
    const ratio = Math.min(200 / image.width, 405 / image.height);
    const width = Math.round(image.width * ratio);
    const height = Math.round(image.height * ratio);
    context.drawImage(image, x + Math.floor((216 - width) / 2), y + 12, width, height);
    context.fillStyle = "#eadab4";
    context.font = "bold 14px sans-serif";
    context.fillText(id, x + 8, y + 448);
  }
}
evidencePNG("generated-source-contact-sheet", sourceSheet);

const productionSheet = createCanvas(1280, 1920);
{
  const context = productionSheet.getContext("2d");
  context.fillStyle = "#101719";
  context.fillRect(0, 0, productionSheet.width, productionSheet.height);
  context.fillStyle = "#f1e5c7";
  context.font = "bold 24px sans-serif";
  context.fillText("FINAL LOGICAL MAP SPRITES · NATIVE + TRUE 400%", 24, 38);
  context.fillStyle = "#b8c6bd";
  context.font = "14px sans-serif";
  context.fillText("16×19 RGBA · bottom anchor (8,18) · unlooted/looted and every premade frame", 24, 62);
  sourceIdentities.forEach((identity, rowIndex) => {
    const y = 86 + rowIndex * 112;
    context.fillStyle = rowIndex % 2 ? "#131e21" : "#172326";
    context.fillRect(16, y - 12, 1248, 104);
    context.fillStyle = "#eadab4";
    context.font = "bold 15px sans-serif";
    context.fillText(identity.title, 28, y + 12);
    context.fillStyle = "#aebdb5";
    context.font = "12px sans-serif";
    context.fillText(`${identity.animation} · ${identity.frames} frame${identity.frames === 1 ? "" : "s"}`, 28, y + 32);
    const states = identity.searchable ? ["unlooted", "looted"] : ["ordinary"];
    let x = 230;
    for (const state of states) {
      context.fillStyle = "#cad4c8";
      context.font = "12px sans-serif";
      context.fillText(state, x, y - 1);
      for (let frame = 0; frame < identity.frames; frame += 1) {
        const sprite = sprites.find(item => item.key === `${identity.id}/${state}/frame-${frame}`);
        const native = canvasOf(sprite.rgba, WIDTH, HEIGHT);
        context.imageSmoothingEnabled = false;
        context.drawImage(native, x, y + 8);
        context.drawImage(scale(native, 4), x + 24, y + 4);
        x += 104;
      }
      x += 24;
    }
  });
}
evidencePNG("production-sprites-native-400pct", productionSheet);
evidencePNG("production-sprites-native-400pct-grayscale", grayscale(productionSheet));

const animatedIdentities = sourceIdentities.filter(identity => identity.frames > 1);
const animationSheet = createCanvas(1200, 1400);
{
  const context = animationSheet.getContext("2d");
  context.fillStyle = "#101719";
  context.fillRect(0, 0, animationSheet.width, animationSheet.height);
  context.fillStyle = "#f1e5c7";
  context.font = "bold 24px sans-serif";
  context.fillText("PREMADE AMBIENT FRAME STRIPS · TRUE 800%", 24, 38);
  context.fillStyle = "#b8c6bd";
  context.font = "14px sans-serif";
  context.fillText("Silhouette and identity persist; only presentation pixels move. Remembered/reduce-motion select frame 0.", 24, 62);
  animatedIdentities.forEach((identity, index) => {
    const y = 90 + index * 160;
    context.fillStyle = index % 2 ? "#131e21" : "#172326";
    context.fillRect(16, y - 12, 1168, 152);
    context.fillStyle = "#eadab4";
    context.font = "bold 15px sans-serif";
    context.fillText(identity.title, 28, y + 16);
    context.fillStyle = "#aebdb5";
    context.font = "12px sans-serif";
    context.fillText(identity.animation, 28, y + 38);
    for (let frame = 0; frame < identity.frames; frame += 1) {
      const state = identity.searchable ? "unlooted" : "ordinary";
      const sprite = sprites.find(item => item.key === `${identity.id}/${state}/frame-${frame}`);
      context.imageSmoothingEnabled = false;
      context.drawImage(scale(canvasOf(sprite.rgba, WIDTH, HEIGHT), 8), 245 + frame * 220, y - 4);
      context.fillStyle = "#d1ddcf";
      context.fillText(`frame ${frame}`, 245 + frame * 220, y + 144);
    }
  });
}
evidencePNG("ambient-animation-strips-800pct", animationSheet);
evidencePNG("ambient-animation-strips-800pct-grayscale", grayscale(animationSheet));

const terrainReference = path.join(root, "artifacts", "terrain-region-continuity-v1", "evidence", "macro-11x11-redraw-a-2x.png");
const terrainImage = await loadImage(terrainReference);
const tilePlacements = [
  ["entry_portal", "ordinary", 0, 5], ["exit_portal", "ordinary", 10, 5], ["locked_cache", "ordinary", 4, 7],
  ["loose_world_page", "ordinary", 6, 2], ["diary_page", "ordinary", 8, 3], ["found_writing", "ordinary", 4, 6],
  ["hazard", "ordinary", 1, 1], ["wayfarers_camp", "unlooted", 4, 1], ["binders_workshop", "unlooted", 7, 1],
  ["glacial_vault", "unlooted", 9, 2], ["spent_emanation_housing", "looted", 2, 4], ["crystal_cavern", "unlooted", 5, 4],
  ["geyser_basin", "unlooted", 8, 5], ["brood_warren", "looted", 2, 8], ["the_tear", "unlooted", 6, 8],
  ["natural_anchor", "ordinary", 9, 8],
];

function drawSelection(context, x, y) {
  context.strokeStyle = "#f1d476";
  context.lineWidth = 2;
  context.strokeRect(x + 1, y + 1, 30, 30);
}

function phone(visibility, grayscaleMode = false) {
  const canvas = createCanvas(368, 800);
  const context = canvas.getContext("2d");
  context.fillStyle = "#0e1618";
  context.fillRect(0, 0, 368, 800);
  context.fillStyle = "#efe3c4";
  context.font = "bold 18px sans-serif";
  context.fillText(`WORLD · ${visibility.toUpperCase()} CONTENT`, 12, 30);
  context.fillStyle = "#aebdb5";
  context.font = "12px sans-serif";
  context.fillText("premade map identities over accepted terrain", 12, 50);
  context.imageSmoothingEnabled = false;
  context.drawImage(terrainImage, 8, 70);
  if (visibility === "remembered") {
    context.fillStyle = "rgba(19,28,31,0.30)";
    context.fillRect(8, 70, 352, 352);
  }
  if (visibility === "hidden") {
    context.fillStyle = "#070b0c";
    context.fillRect(8, 70, 352, 352);
  } else {
    for (const [identity, state, tileX, tileY] of tilePlacements) {
      const definition = sourceIdentities.find(row => row.id === identity);
      const frame = visibility === "full" ? 1 % definition.frames : 0;
      const sprite = sprites.find(item => item.key === `${identity}/${state}/frame-${frame}`);
      context.drawImage(scale(canvasOf(sprite.rgba, WIDTH, HEIGHT), 2), 8 + tileX * 32, 70 + tileY * 32 - 6);
    }
    drawSelection(context, 8 + 6 * 32, 70 + 8 * 32);
    context.fillStyle = "#d96d47";
    context.beginPath();
    context.arc(8 + 5.5 * 32, 70 + 6.5 * 32, 11, 0, Math.PI * 2);
    context.fill();
    context.fillStyle = "#f2d982";
    context.fillRect(8 + 5.5 * 32 - 3, 70 + 6.5 * 32 - 3, 6, 6);
  }
  context.fillStyle = "#172326";
  context.fillRect(8, 438, 352, 330);
  context.strokeStyle = "#53625e";
  context.strokeRect(8, 438, 352, 330);
  context.fillStyle = "#f1e5c7";
  context.font = "bold 15px sans-serif";
  context.fillText(visibility === "hidden" ? "HIDDEN — NO IDENTITY DRAW" : "MAP IDENTITY CENSUS", 20, 466);
  context.fillStyle = "#b8c6bd";
  context.font = "12px sans-serif";
  if (visibility === "hidden") {
    context.fillText("Terrain and content remain undisclosed.", 20, 492);
  } else {
    const labels = sourceIdentities.map(row => row.title);
    labels.forEach((label, index) => context.fillText(label, 20 + (index % 2) * 174, 494 + Math.floor(index / 2) * 30));
    context.fillText(visibility === "full" ? "Ambient frames may advance on the shared clock." : "Static frame 0; no ambient motion in memory.", 20, 738);
    context.fillText("Selection and party identity remain above content art.", 20, 758);
  }
  return grayscaleMode ? grayscale(canvas) : canvas;
}

for (const visibility of ["full", "remembered", "hidden"]) {
  evidencePNG(`applied-map-${visibility}-368x800`, phone(visibility));
  evidencePNG(`applied-map-${visibility}-grayscale-368x800`, phone(visibility, true));
}

const minimapSheet = createCanvas(1440, 420);
{
  const context = minimapSheet.getContext("2d");
  context.fillStyle = "#101719";
  context.fillRect(0, 0, minimapSheet.width, minimapSheet.height);
  context.fillStyle = "#f1e5c7";
  context.font = "bold 22px sans-serif";
  context.fillText("CURRENT MINIMAP DISCLOSURE · SIX GENERIC CATEGORIES", 20, 34);
  context.fillStyle = "#b8c6bd";
  context.font = "13px sans-serif";
  context.fillText("Portal · page · cache · site · hazard · resource. No subtype disclosure; hidden remains empty.", 20, 58);
  enumerateMinimapSprites().forEach((sprite, index) => {
    const native = canvasOf(sprite.rgba, MINIMAP_SIZE, MINIMAP_SIZE);
    const x = 24 + index * 232;
    context.fillStyle = "#223034";
    context.fillRect(x, 92, 216, 250);
    context.imageSmoothingEnabled = false;
    context.drawImage(native, x + 16, 110);
    context.drawImage(scale(native, 16), x + 74, 104);
    context.fillStyle = "#eadab4";
    context.font = "bold 15px sans-serif";
    context.fillText(sprite.identity, x + 16, 322);
  });
}
evidencePNG("minimap-category-sprites-native-1600pct", minimapSheet);
evidencePNG("minimap-category-sprites-native-1600pct-grayscale", grayscale(minimapSheet));

const authorityFiles = [
  "../Sources/Model/WorldMap.swift",
  "../Sources/Content/Data/sites.json",
  "../Sources/Screens/WorldView.swift",
  "../Sources/Screens/MinimapView.swift",
  "src/resource-kit.js",
  "integration/resource-sprites-v1/manifest.json",
];
const authorityPins = Object.fromEntries(authorityFiles.map(relative => {
  const absolute = path.resolve(root, relative);
  return [relative.replace("../", ""), sha256(fs.readFileSync(absolute))];
}));

const manifest = {
  schemaVersion: "exploration-map-identities-v1",
  status: "candidate-unapproved",
  integrationReady: false,
  baselineCommit: "14d2582a2470d843f6b1a40798db29e83f440e02",
  authorityPins,
  acceptedTerrainReference: {
    path: "AssetLab/artifacts/terrain-region-continuity-v1/evidence/macro-11x11-redraw-a-2x.png",
    sha256: sha256(fs.readFileSync(terrainReference)),
  },
  production: {
    map: { logicalSize: [WIDTH, HEIGHT], pivot: [PIVOT.x, PIVOT.y], tileConsumer: [16, 16], filtering: "nearest-neighbour", premadeOnly: true },
    minimap: { logicalSize: [MINIMAP_SIZE, MINIMAP_SIZE], categories: ["portal", "page", "cache", "site", "hazard", "resource"], subtypeDisclosure: false, premadeOnly: true },
    runtimeDirectory: "runtime",
    runtimeContents: ["manifest.json", "assets"],
    noRuntimeGeneration: true,
  },
  visibilityContract: {
    full: "lookup persisted identity/state; shared presentation clock may select a premade ambient frame",
    remembered: "lookup persisted identity/state at frame 0 only",
    hidden: "no lookup and no draw",
  },
  layerContract: ["terrain", "southWall", "siteOrHazard", "party", "selectionAndInteraction", "alerts"],
  animationContract: {
    clock: "existing shared presentation clock",
    selection: "presentationTick modulo frameCount for full visibility only",
    reduceMotion: "frame 0",
    forbiddenImplications: ["damage", "searching", "opening", "depletion", "spread", "extinguishing"],
    assetsArePremade: true,
  },
  identities: sourceIdentities.map(row => ({
    ...row,
    states: row.searchable ? ["unlooted", "looted"] : ["ordinary"],
    lootedStateAuthority: row.searchable ? "PlacedSite.isLooted" : null,
  })),
  requestABI: {
    exactKeys: ["identity", "state", "visibility", "presentationTick", "reduceMotion"],
    identity: sourceIdentities.map(row => row.id),
    state: ["ordinary", "unlooted", "looted"],
    visibility: ["full", "remembered", "hidden"],
    failClosed: ["unknownIdentity", "unknownState", "unknownVisibility", "extraField", "unsafePresentationTick", "hidden"],
  },
  assetsByKey,
  sourceReferences,
  evidence,
};
manifest.coverage = {
  mapStableKeys: enumerateSprites().length,
  minimapStableKeys: enumerateMinimapSprites().length,
  stableKeys: Object.keys(assetsByKey).length,
  runtimePNGs: uniqueAssets.size,
  staticIdentityCount: sourceIdentities.filter(row => row.frames === 1).length,
  animatedIdentityCount: animatedIdentities.length,
};
manifest.runtimeAssetAggregateSHA256 = sha256(Buffer.from(Object.entries(assetsByKey).sort(([a], [b]) => a.localeCompare(b)).map(([key, value]) => `${key}:${value.sha256}:${value.rgbaSHA256}`).join("\n")));
manifest.canonicalBodySHA256 = sha256(Buffer.from(JSON.stringify(manifest)));
fs.writeFileSync(path.join(runtimeRoot, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`);

console.log(JSON.stringify({
  body: manifest.canonicalBodySHA256,
  manifestFile: sha256(fs.readFileSync(path.join(runtimeRoot, "manifest.json"))),
  mapStableKeys: manifest.coverage.mapStableKeys,
  minimapStableKeys: manifest.coverage.minimapStableKeys,
  runtimePNGs: manifest.coverage.runtimePNGs,
  runtimeAssetAggregate: manifest.runtimeAssetAggregateSHA256,
}, null, 2));
