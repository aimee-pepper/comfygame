import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const WIDTH = 16;
export const HEIGHT = 19;
export const SOURCE_SIZE = 32;
export const PIVOT = Object.freeze({ x: 8, y: 18 });
export const MINIMAP_SIZE = 7;
export const SOURCE_ALPHA_THRESHOLD = 128;

const here = path.dirname(fileURLToPath(import.meta.url));
export const assetLabRoot = path.resolve(here, "..");
export const acceptedPackRoot = path.join(assetLabRoot, "integration", "mob-gear-sprites-v1");
export const acceptedManifestPath = path.join(acceptedPackRoot, "manifest.json");
export const acceptedManifest = JSON.parse(fs.readFileSync(acceptedManifestPath, "utf8"));

if (acceptedManifest.packID !== "mob-gear-sprites-v1"
    || acceptedManifest.integrationReady !== true
    || acceptedManifest.canonicalBodySHA256 !== "ee65afce662d74615ed3c602a7654650ab6e317df1e3d43b612820a6ede40fc9") {
  throw new Error("accepted-mob-gear-source-pin-mismatch");
}

export const catalogueGear = Object.freeze(acceptedManifest.profiles.catalogueGear.sprites.map(row => Object.freeze({
  catalogueID: row.id,
  visualFamilyID: row.visualFamilyID,
  materialProfileID: row.materialProfileID ?? null,
  sourcePath: path.join(acceptedPackRoot, "catalogue-gear", row.file),
  sourceRelativePath: `AssetLab/integration/mob-gear-sprites-v1/catalogue-gear/${row.file}`,
  sourceSHA256: row.sha256,
})));

export const blockedPlaceholderFamilies = Object.freeze([
  Object.freeze({ packID: "catalogue-consumables-placeholder-v1", reason: "source manifest finalArt:false" }),
  Object.freeze({ packID: "named-character-placeholders-v1", reason: "source manifest finalArt:false" }),
  Object.freeze({ packID: "creature placeholder renderer", reason: "no accepted final trait-renderer sprites" }),
]);

export const sha256 = bytes => crypto.createHash("sha256").update(bytes).digest("hex");

function pixel(bytes, width, x, y) {
  const offset = (y * width + x) * 4;
  return [bytes[offset], bytes[offset + 1], bytes[offset + 2], bytes[offset + 3]];
}

function chooseSourcePixel(sourceRGBA, outX, outY) {
  const candidates = [];
  for (let dy = 0; dy < 2; dy += 1) {
    for (let dx = 0; dx < 2; dx += 1) {
      const sourceX = outX * 2 + dx;
      const sourceY = outY * 2 + dy;
      const rgba = pixel(sourceRGBA, SOURCE_SIZE, sourceX, sourceY);
      if (rgba[3] >= SOURCE_ALPHA_THRESHOLD) candidates.push({ sourceX, sourceY, rgba });
    }
  }
  if (candidates.length === 0) return null;

  const frequencies = new Map();
  candidates.forEach(candidate => {
    const key = candidate.rgba.join(",");
    frequencies.set(key, (frequencies.get(key) ?? 0) + 1);
  });
  const preferredOrder = [[1, 1], [0, 1], [1, 0], [0, 0]];
  candidates.sort((a, b) => {
    const count = frequencies.get(b.rgba.join(",")) - frequencies.get(a.rgba.join(","));
    if (count !== 0) return count;
    const aPosition = preferredOrder.findIndex(([x, y]) => x === a.sourceX % 2 && y === a.sourceY % 2);
    const bPosition = preferredOrder.findIndex(([x, y]) => x === b.sourceX % 2 && y === b.sourceY % 2);
    return aPosition - bPosition;
  });
  return candidates[0];
}

function opaqueBounds(bytes, width, height) {
  let minX = width;
  let minY = height;
  let maxX = -1;
  let maxY = -1;
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      if (bytes[(y * width + x) * 4 + 3] === 0) continue;
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x);
      maxY = Math.max(maxY, y);
    }
  }
  if (maxX < 0) throw new Error("empty-loose-item-source");
  return { minX, minY, maxX, maxY, width: maxX - minX + 1, height: maxY - minY + 1 };
}

export function bakeCatalogueMapSprite(row, sourceRGBA) {
  if (!(sourceRGBA instanceof Uint8ClampedArray) || sourceRGBA.length !== SOURCE_SIZE * SOURCE_SIZE * 4) {
    throw new Error(`invalid-source-rgba:${row.catalogueID}`);
  }
  const compact = new Uint8ClampedArray(WIDTH * WIDTH * 4);
  const selected = [];
  for (let y = 0; y < WIDTH; y += 1) {
    for (let x = 0; x < WIDTH; x += 1) {
      const source = chooseSourcePixel(sourceRGBA, x, y);
      if (!source) continue;
      const offset = (y * WIDTH + x) * 4;
      compact.set([source.rgba[0], source.rgba[1], source.rgba[2], 255], offset);
      selected.push({ compactX: x, compactY: y, sourceX: source.sourceX, sourceY: source.sourceY, rgba: source.rgba.slice(0, 3) });
    }
  }

  const compactBounds = opaqueBounds(compact, WIDTH, WIDTH);
  const shiftX = Math.floor((WIDTH - compactBounds.width) / 2) - compactBounds.minX;
  const shiftY = 17 - compactBounds.maxY;
  const finalRGBA = new Uint8ClampedArray(WIDTH * HEIGHT * 4);
  const provenance = [];
  for (const source of selected) {
    const x = source.compactX + shiftX;
    const y = source.compactY + shiftY;
    if (x < 0 || x >= WIDTH || y < 0 || y >= HEIGHT) throw new Error(`normalization-oob:${row.catalogueID}`);
    finalRGBA.set([...source.rgba, 255], (y * WIDTH + x) * 4);
    provenance.push({ x, y, sourceX: source.sourceX, sourceY: source.sourceY, rgba: source.rgba });
  }
  const bounds = opaqueBounds(finalRGBA, WIDTH, HEIGHT);
  return {
    key: `catalogue-item/${row.catalogueID}`,
    catalogueID: row.catalogueID,
    visualFamilyID: row.visualFamilyID,
    materialProfileID: row.materialProfileID,
    width: WIDTH,
    height: HEIGHT,
    pivot: { ...PIVOT },
    rgba: finalRGBA,
    bounds,
    provenance,
    sourceSHA256: row.sourceSHA256,
    sourceRelativePath: row.sourceRelativePath,
  };
}

const minimapRows = Object.freeze([
  ".......",
  "..ddd..",
  ".dsssd.",
  ".dslsd.",
  ".dsssd.",
  "..ddd..",
  ".......",
]);
const minimapPalette = Object.freeze({ d: [72, 61, 48, 255], s: [183, 133, 69, 255], l: [235, 200, 116, 255] });

export function minimapItemSprite() {
  const rgba = new Uint8ClampedArray(MINIMAP_SIZE * MINIMAP_SIZE * 4);
  minimapRows.forEach((row, y) => [...row].forEach((symbol, x) => {
    if (symbol !== ".") rgba.set(minimapPalette[symbol], (y * MINIMAP_SIZE + x) * 4);
  }));
  return { key: "minimap/item", identity: "item", width: MINIMAP_SIZE, height: MINIMAP_SIZE, rgba };
}

export function lookupCatalogueSprite(manifest, request) {
  if (!request || typeof request !== "object" || Array.isArray(request)) return null;
  if (Object.keys(request).sort().join(",") !== "catalogueID,visibility") return null;
  if (!catalogueGear.some(row => row.catalogueID === request.catalogueID)) return null;
  if (!new Set(["full", "remembered", "hidden"]).has(request.visibility) || request.visibility === "hidden") return null;
  return manifest.assetsByKey[`catalogue-item/${request.catalogueID}`] ?? null;
}
