import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { createRequire } from "node:module";

const { createCanvas } = createRequire(import.meta.url)("@napi-rs/canvas");
const root = path.resolve(import.meta.dirname, "..");
const artifact = path.join(root, "artifacts", "atmosphere-presentation-v0.1");
for (const folder of ["source", "evidence", "contact"]) fs.mkdirSync(path.join(artifact, folder), { recursive: true });

export const TILE = 16;
export const MAP_TILES = 15;
export const MAP_SIZE = TILE * MAP_TILES;
export const PHASE_SEED = 0x4a71c2d3;
export const families = Object.freeze({
  smoke: { palette: [[64, 61, 58], [104, 98, 90], [146, 137, 124]], layer: "suspended" },
  airborneAsh: { palette: [[67, 72, 78], [116, 122, 128], [174, 176, 176]], layer: "particulate" },
  mist: { palette: [[91, 111, 116], [137, 155, 157], [190, 201, 198]], layer: "suspended" },
  miasma: { palette: [[66, 61, 70], [105, 92, 112], [151, 133, 151]], layer: "suspended" },
  rain: { palette: [[84, 129, 151], [134, 174, 191], [192, 216, 221]], layer: "precipitation" },
  snow: { palette: [[126, 143, 151], [184, 196, 199], [232, 234, 226]], layer: "precipitation" },
  mixedRainSnow: { palette: [[91, 132, 149], [181, 193, 195], [232, 229, 214]], layer: "precipitation" }
});
export const densityBands = Object.freeze({ trace: 18, light: 36, heavy: 64, dense: 88 });
export const motionBands = Object.freeze({ calm: 0, moving: 1, strong: 2 });

const sha = bytes => crypto.createHash("sha256").update(bytes).digest("hex");
const hash = (...values) => {
  let value = PHASE_SEED >>> 0;
  for (const part of values.join(":`")) value = Math.imul(value ^ part.charCodeAt(0), 16777619) >>> 0;
  return value;
};
const write = (file, canvas) => {
  const bytes = canvas.toBuffer("image/png");
  fs.writeFileSync(path.join(artifact, file), bytes);
  return { file, width: canvas.width, height: canvas.height, sha256: sha(bytes) };
};
const rgba = (rgb, alpha) => `rgba(${rgb[0]},${rgb[1]},${rgb[2]},${alpha / 255})`;
const rect = (context, color, x, y, width, height) => { context.fillStyle = color; context.fillRect(x, y, width, height); };

function densitySpec(density) {
  const value = densityBands[density] ?? Number(density);
  if (!Number.isFinite(value) || value < 0 || value > 100) throw new Error(`invalid density ${density}`);
  return { value, count: Math.round(5 + value * 0.28), alpha: Math.round(34 + value * 1.25) };
}

export function familyTile(familyID, density = "light", motion = "calm", phase = 0, tileX = 0, tileY = 0, ground = "soil") {
  const family = families[familyID];
  if (!family) throw new Error(`unknown family ${familyID}`);
  const spec = densitySpec(density), speed = motionBands[motion];
  if (speed === undefined) throw new Error(`unknown motion ${motion}`);
  const canvas = createCanvas(TILE, TILE), c = canvas.getContext("2d");
  c.imageSmoothingEnabled = false;
  const drift = phase * speed;
  const mark = (index, width = 1, height = 1, paletteIndex = 1, alpha = spec.alpha) => {
    const h = hash(familyID, tileX, tileY, index);
    const x = ((h & 15) + drift * (familyID === "rain" || familyID === "mixedRainSnow" ? 1 : 2)) % 16;
    const y = (((h >>> 8) & 15) + drift * (familyID === "snow" ? 1 : 0)) % 16;
    for (let py = 0; py < height; py++) for (let px = 0; px < width; px++)
      rect(c, rgba(family.palette[paletteIndex], alpha), (x + px) % 16, (y + py) % 16, 1, 1);
  };
  if (familyID === "smoke") {
    // Smoke is assembled from staggered, rising fragments. Avoid long horizontal
    // strokes: at phone scale those read as a screen texture instead of a plume.
    const plumes = Math.max(1, Math.round(spec.count / 7));
    for (let i = 0; i < plumes; i++) {
      const seed = hash(familyID, tileX, tileY, i);
      const baseX = ((seed & 15) + drift * 2) % 16;
      const baseY = (seed >>> 8) & 15;
      const direction = seed & 1 ? 1 : -1;
      const pixels = [
        [0, 3], [1, 3], [2, 3],
        [direction, 2], [direction + 1, 2],
        [direction, 1], [direction * 2, 1],
        [direction * 2, 0]
      ];
      for (let p = 0; p < pixels.length; p++) {
        const [px, py] = pixels[p];
        rect(c, rgba(family.palette[(i + (p > 4 ? 1 : 0)) % 3], spec.alpha - (p > 5 ? 20 : 0)), (baseX + px + 16) % 16, (baseY + py) % 16, 1, 1);
      }
      // A detached curl keeps the silhouette porous rather than dash-like.
      rect(c, rgba(family.palette[(i + 2) % 3], spec.alpha - 26), (baseX - direction + 16) % 16, (baseY + 1) % 16, 1, 1);
    }
  } else if (familyID === "airborneAsh") {
    for (let i = 0; i < spec.count; i++) { mark(i, i % 4 === 0 ? 2 : 1, 1, i % 3, spec.alpha); if (i % 5 === 0) mark(i + 90, 1, 2, 0, spec.alpha - 12); }
  } else if (familyID === "mist") {
    // Fog is a bank of uneven wisps with pockets between them. Tile position is
    // part of the seed so neighbouring cells vary instead of forming scanlines.
    const regionalVariation = hash(familyID, Math.floor(tileX / 2), Math.floor(tileY / 2), "bank") % 5;
    const wisps = Math.max(0, Math.round(spec.count / 8) + regionalVariation - 3);
    const thickness = spec.value < 30 ? 1 : spec.value < 55 ? 2 : spec.value < 80 ? 3 : 4;
    for (let i = 0; i < wisps; i++) {
      const seed = hash(familyID, tileX, tileY, i);
      const x = ((seed & 15) + drift * 2) % 16;
      const y = ((seed >>> 8) & 15);
      const length = 3 + thickness + ((seed >>> 16) % 5);
      const alpha = spec.alpha - 24 - (i % 2) * 10;
      // Heavy fog gains body rather than more lines: tapered stacked rows with
      // dithered shoulders and small air pockets retain terrain readability.
      for (let py = 0; py < thickness; py++) {
        const edgeInset = py === 0 || py === thickness - 1 ? 1 : 0;
        const rowLength = Math.max(2, length - edgeInset - ((seed >>> (20 + py)) & 1));
        const rowX = x + edgeInset + (py > 1 && ((seed >>> 25) & 1) ? 1 : 0);
        for (let px = 0; px < rowLength; px++) {
          const shoulder = py === 0 || py === thickness - 1 || px === 0 || px === rowLength - 1;
          if (shoulder && ((px + py + (seed & 3)) % 3 === 0)) continue;
          if (thickness >= 3 && !shoulder && ((px * 3 + py + (seed >>> 5)) % 13 === 0)) continue;
          rect(c, rgba(family.palette[(i + (shoulder ? 1 : 0)) % 3], alpha - (shoulder ? 15 : 0)), (rowX + px) % 16, (y + py) % 16, 1, 1);
        }
      }
      rect(c, rgba(family.palette[(i + 2) % 3], alpha - 18), (x + length + 2) % 16, (y + thickness + (i % 2)) % 16, thickness >= 3 ? 2 : 1, 1);
    }
  } else if (familyID === "miasma") {
    const curls = Math.max(1, Math.round(spec.count / 8));
    for (let i = 0; i < curls; i++) { mark(i, 5, 1, 0, spec.alpha); mark(i + 40, 1, 4, 1, spec.alpha - 8); mark(i + 80, 3, 1, 2, spec.alpha - 20); }
  } else if (familyID === "rain" || familyID === "mixedRainSnow") {
    for (let i = 0; i < spec.count; i++) { mark(i, 1, 3, i % 2, spec.alpha + 20); if (ground === "water" && i % 8 === 0) { const h = hash(i, tileX, tileY); rect(c, rgba(family.palette[2], spec.alpha - 10), h % 13, (h >>> 8) % 15, 4, 1); } }
    if (familyID === "mixedRainSnow") for (let i = 0; i < Math.ceil(spec.count / 3); i++) { mark(i + 300, i % 3 === 0 ? 2 : 1, i % 3 === 0 ? 1 : 2, 2, spec.alpha + 8); }
  } else if (familyID === "snow") {
    for (let i = 0; i < spec.count; i++) { mark(i, i % 5 === 0 ? 2 : 1, i % 5 === 0 ? 2 : 1, i % 3, spec.alpha + 12); }
  }
  return canvas;
}

export function contactShade({ lowerElevation, neighbourElevation, light = "ordinary", remembered = false }) {
  const canvas = createCanvas(TILE, TILE), c = canvas.getContext("2d");
  const difference = neighbourElevation - lowerElevation;
  if (difference <= 0 || light === "pitchBlack") return canvas;
  const alpha = remembered ? 72 : light === "dim" ? 54 : 92;
  rect(c, `rgba(35,29,24,${alpha / 255})`, 0, 0, TILE, 1);
  if (difference >= 2) for (let x = 0; x < TILE; x += 2) rect(c, `rgba(35,29,24,${Math.round(alpha * .55) / 255})`, x, 1, 1, 1);
  return canvas;
}

const groundPalette = {
  soil: [94, 76, 54], grass: [68, 104, 62], stone: [105, 103, 96], water: [48, 104, 129], sand: [151, 132, 83]
};
function groundAt(x, y) {
  if (x < 3 || (x < 5 && y < 7)) return "water";
  if (x > 11 && y < 5) return "stone";
  if (y > 10) return "grass";
  if (x > 9 && y > 6) return "sand";
  return "soil";
}
function drawTerrainTile(c, x, y) {
  const ground = groundAt(x, y), p = groundPalette[ground], fleck = hash(x, y) % 11;
  rect(c, `rgb(${p.join(",")})`, x * TILE, y * TILE, TILE, TILE);
  rect(c, `rgba(255,255,255,.10)`, x * TILE + 2 + fleck % 9, y * TILE + 3 + fleck % 7, 2, 1);
}
function visibilityAt(x, y) {
  const dx = x - 7, dy = y - 7, distance = Math.sqrt(dx * dx + dy * dy);
  if (distance <= 4.5) return "full";
  if (distance <= 6) return "fringe";
  if (x <= 3 && y >= 8) return "remembered";
  return "hidden";
}
function drawContents(c, visibility, mutation = false) {
  const objects = [
    { x: 7, y: 7, color: "#f0d26c", kind: "player" },
    { x: 5, y: 6, color: "#70d0d4", kind: "resource" },
    { x: 9, y: 5, color: "#d59868", kind: "site" },
    { x: 9, y: 9, color: "#e8e4d5", kind: "creature" },
    // The live remote value may mutate, but the rendered last-seen snapshot remains frozen.
    { x: 2, y: 11, color: "#70d0d4", liveColor: mutation ? "#c84b4b" : "#70d0d4", kind: "remembered-resource" }
  ];
  for (const object of objects) {
    const state = visibility(object.x, object.y);
    if (state !== "full" && object.kind !== "remembered-resource") continue;
    const x = object.x * TILE + 5, y = object.y * TILE + 5;
    if (object.kind === "site") { c.strokeStyle = object.color; c.lineWidth = 2; c.strokeRect(x, y, 6, 6); }
    else if (object.kind === "creature") { c.fillStyle = object.color; c.beginPath(); c.moveTo(x + 3, y); c.lineTo(x + 7, y + 7); c.lineTo(x, y + 7); c.closePath(); c.fill(); }
    else rect(c, object.color, x, y, 7, 7);
  }
}

export function mapFrame({ familyID = null, density = "light", motion = "calm", phase = 0, precipitationID = null, mutation = false, revealAll = false } = {}) {
  const canvas = createCanvas(MAP_SIZE, MAP_SIZE), c = canvas.getContext("2d");
  rect(c, "#000", 0, 0, MAP_SIZE, MAP_SIZE);
  for (let y = 0; y < MAP_TILES; y++) for (let x = 0; x < MAP_TILES; x++) {
    const state = revealAll ? "full" : visibilityAt(x, y);
    if (state !== "hidden") drawTerrainTile(c, x, y);
    if (state === "full" || state === "fringe") {
      c.save(); c.beginPath(); c.rect(x * TILE, y * TILE, TILE, TILE); c.clip();
      c.globalAlpha = state === "fringe" ? .45 : 1;
      if (familyID) c.drawImage(familyTile(familyID, density, motion, phase, x, y, groundAt(x, y)), x * TILE, y * TILE);
      if (precipitationID) c.drawImage(familyTile(precipitationID, density, motion, phase, x, y, groundAt(x, y)), x * TILE, y * TILE);
      c.restore();
    }
  }
  drawContents(c, revealAll ? () => "full" : visibilityAt, mutation);
  if (!revealAll) for (let y = 0; y < MAP_TILES; y++) for (let x = 0; x < MAP_TILES; x++) {
    const state = visibilityAt(x, y);
    if (state === "remembered") rect(c, "rgba(32,34,35,.60)", x * TILE, y * TILE, TILE, TILE);
    if (state === "hidden") rect(c, "#000", x * TILE, y * TILE, TILE, TILE);
  }
  return canvas;
}

function phone(options = {}) {
  const canvas = createCanvas(368, 800), c = canvas.getContext("2d");
  rect(c, "#12191b", 0, 0, 368, 800); rect(c, "#20383a", 0, 0, 368, 84);
  c.fillStyle = "#eee1bd"; c.font = "bold 18px sans-serif"; c.fillText("EXPLORE", 18, 36);
  c.font = "11px sans-serif"; c.fillText("STABILITY 78%", 18, 60); c.fillText("12 TURNS", 286, 60);
  const frame = mapFrame(options); c.imageSmoothingEnabled = false; c.drawImage(frame, 64, 104, MAP_SIZE, MAP_SIZE);
  rect(c, "#1a2b2e", 18, 362, 332, 86); c.strokeStyle = "#6f908c"; c.strokeRect(18.5, 362.5, 331, 85);
  c.fillStyle = "#e9dfc7"; c.font = "12px sans-serif"; c.fillText("AT THIS PLACE · VISIBLE", 34, 386); c.font = "bold 17px sans-serif"; c.fillText("Forest track", 34, 412);
  c.font = "11px sans-serif"; c.fillText("Terrain and field identity remain legible", 34, 432);
  rect(c, "#243c40", 18, 466, 332, 54); c.fillStyle = "#e9dfc7"; c.font = "11px sans-serif"; c.fillText("FIELD KIT 4/6   ·   TURN 24", 34, 498);
  rect(c, "#21383b", 18, 538, 150, 126); rect(c, "#17272a", 184, 538, 166, 126);
  c.fillStyle = "#e9dfc7"; c.font = "bold 14px sans-serif"; c.fillText("MOVE", 68, 564); c.fillText("MINIMAP", 234, 564);
  for (const [x, y, glyph] of [[81, 582, "↑"], [53, 610, "←"], [81, 610, "↓"], [109, 610, "→"]]) { rect(c, "#d4b274", x - 13, y - 15, 26, 26); c.fillStyle = "#2b251e"; c.fillText(glyph, x - 5, y + 3); }
  for (let y = 0; y < 4; y++) for (let x = 0; x < 4; x++) rect(c, (x + y) % 3 ? "#496b63" : "#192322", 218 + x * 18, 580 + y * 18, 16, 16);
  rect(c, "#d4b274", 18, 686, 158, 72); rect(c, "#3182b5", 192, 686, 158, 72);
  c.fillStyle = "#211c18"; c.font = "bold 16px sans-serif"; c.fillText("LOOK", 73, 728); c.fillStyle = "white"; c.fillText("INTERACT", 235, 728);
  return canvas;
}
function grayscale(source) {
  const canvas = createCanvas(source.width, source.height), c = canvas.getContext("2d"); c.drawImage(source, 0, 0);
  const image = c.getImageData(0, 0, canvas.width, canvas.height);
  for (let i = 0; i < image.data.length; i += 4) { const value = Math.round(.2126 * image.data[i] + .7152 * image.data[i + 1] + .0722 * image.data[i + 2]); image.data[i] = image.data[i + 1] = image.data[i + 2] = value; }
  c.putImageData(image, 0, 0); return canvas;
}

const source = {}, sourceRows = [];
for (const familyID of Object.keys(families)) {
  source[familyID] = {};
  for (const density of ["trace", "light", "heavy", "dense"]) {
    const canvas = familyTile(familyID, density, "moving", 0, 4, 7, "water");
    source[familyID][density] = write(`source/${familyID}-${density}-logical-16x16.png`, canvas);
    sourceRows.push({ familyID, density, canvas });
  }
}
const shades = {
  equal: write("source/contact-shade-equal-logical-16x16.png", contactShade({ lowerElevation: 1, neighbourElevation: 1 })),
  oneStep: write("source/contact-shade-one-step-logical-16x16.png", contactShade({ lowerElevation: 1, neighbourElevation: 2 })),
  twoStep: write("source/contact-shade-two-step-logical-16x16.png", contactShade({ lowerElevation: 0, neighbourElevation: 2 }))
};
const matrix = [
  ["clear", {}], ["smoke-trace", { familyID: "smoke", density: "trace" }], ["smoke-light", { familyID: "smoke", density: "light" }], ["smoke-heavy", { familyID: "smoke", density: "heavy" }],
  ["ash-light", { familyID: "airborneAsh", density: "light" }], ["ash-heavy", { familyID: "airborneAsh", density: "heavy" }], ["mist-light", { familyID: "mist", density: "light" }], ["fog-heavy", { familyID: "mist", density: "heavy" }],
  ["miasma-light", { familyID: "miasma", density: "light" }], ["miasma-heavy", { familyID: "miasma", density: "heavy" }], ["rain-light", { familyID: "rain", density: "light" }], ["rain-heavy", { familyID: "rain", density: "heavy" }],
  ["snow-light", { familyID: "snow", density: "light" }], ["snow-heavy", { familyID: "snow", density: "heavy" }], ["mixed-light", { familyID: "mixedRainSnow", density: "light" }], ["mixed-heavy", { familyID: "mixedRainSnow", density: "heavy" }],
  ["smoke-rain", { familyID: "smoke", precipitationID: "rain", density: "heavy" }], ["mist-snow", { familyID: "mist", precipitationID: "snow", density: "heavy" }]
];
const evidence = {};
for (const [id, options] of matrix) { const rendered = phone(options); evidence[id] = { color: write(`evidence/${id}-368x800.png`, rendered), grayscale: write(`evidence/${id}-grayscale-368x800.png`, grayscale(rendered)) }; }
for (const motion of Object.keys(motionBands)) evidence[`motion-${motion}`] = { color: write(`evidence/motion-${motion}-368x800.png`, phone({ familyID: "smoke", density: "light", motion, phase: 2 })) };
const boundaryA = phone({ familyID: "mist", density: "heavy", mutation: false });
const boundaryB = phone({ familyID: "mist", density: "heavy", mutation: true });
evidence.visibility = { ordinary: write("evidence/visibility-boundaries-368x800.png", boundaryA), remoteMutation: write("evidence/visibility-boundaries-remote-mutation-368x800.png", boundaryB) };

const atlas = createCanvas(4 * 128, 7 * 104), ac = atlas.getContext("2d"); rect(ac, "#171717", 0, 0, atlas.width, atlas.height); ac.imageSmoothingEnabled = false;
sourceRows.forEach((row, index) => { const column = index % 4, line = Math.floor(index / 4), x = column * 128, y = line * 104; ac.fillStyle = "#e8dfca"; ac.font = "11px sans-serif"; ac.fillText(`${row.familyID} · ${row.density}`, x + 8, y + 16); ac.drawImage(row.canvas, x + 32, y + 28, 64, 64); });
const contactSheet = write("contact/native-family-contact-sheet-400pct.png", atlas);
const proofCellWidth = 456, proofCellHeight = 850, proofSheet = createCanvas(3 * proofCellWidth, 6 * proofCellHeight), pc = proofSheet.getContext("2d"); rect(pc, "#181716", 0, 0, proofSheet.width, proofSheet.height);
for (let i = 0; i < matrix.length; i++) { const x = (i % 3) * proofCellWidth, y = Math.floor(i / 3) * proofCellHeight; pc.fillStyle = "#e8dfca"; pc.font = "bold 15px sans-serif"; pc.fillText(matrix[i][0].replaceAll("-", " · "), x + 44, y + 24); pc.drawImage(phone(matrix[i][1]), x + 44, y + 40); }
const proofMatrix = write("contact/phone-proof-matrix.png", proofSheet);
const grayscaleProofSheet = createCanvas(proofSheet.width, proofSheet.height), gpc = grayscaleProofSheet.getContext("2d"); rect(gpc, "#181716", 0, 0, grayscaleProofSheet.width, grayscaleProofSheet.height);
for (let i = 0; i < matrix.length; i++) { const x = (i % 3) * proofCellWidth, y = Math.floor(i / 3) * proofCellHeight; gpc.fillStyle = "#e8dfca"; gpc.font = "bold 15px sans-serif"; gpc.fillText(`${matrix[i][0].replaceAll("-", " · ")} · literal grayscale`, x + 44, y + 24); gpc.drawImage(grayscale(phone(matrix[i][1])), x + 44, y + 40); }
const grayscaleProofMatrix = write("contact/phone-proof-matrix-grayscale.png", grayscaleProofSheet);
const motionSheet = createCanvas(3 * proofCellWidth, proofCellHeight), mc = motionSheet.getContext("2d"); rect(mc, "#181716", 0, 0, motionSheet.width, motionSheet.height);
Object.keys(motionBands).forEach((motion, index) => { const x = index * proofCellWidth; mc.fillStyle = "#e8dfca"; mc.font = "bold 15px sans-serif"; mc.fillText(`same smoke · light · phase 2 · ${motion}`, x + 44, 24); mc.drawImage(phone({ familyID: "smoke", density: "light", motion, phase: 2 }), x + 44, 40); });
const motionMatrix = write("contact/motion-band-matrix.png", motionSheet);
function shadePanel(label, lower, neighbour, leftColor, rightColor) { const panel = createCanvas(152, 160), c = panel.getContext("2d"); rect(c, "#181716", 0, 0, 152, 160); c.fillStyle = "#e8dfca"; c.font = "11px sans-serif"; c.fillText(label, 8, 16); const tile = createCanvas(16, 16), tc = tile.getContext("2d"); rect(tc, leftColor, 0, 0, 16, 16); tc.drawImage(contactShade({ lowerElevation: lower, neighbourElevation: neighbour }), 0, 0); c.imageSmoothingEnabled = false; c.drawImage(tile, 12, 28, 128, 128); rect(c, rightColor, 76, 28, 64, 128); return panel; }
const shadeMatrixCanvas = createCanvas(4 * 152, 160), sc = shadeMatrixCanvas.getContext("2d");
[
  shadePanel("equal height · same material", 1, 1, "#6a624f", "#6a624f"),
  shadePanel("equal height · different material", 1, 1, "#6a624f", "#466b59"),
  shadePanel("genuine height · one step", 1, 2, "#6a624f", "#7d786d"),
  shadePanel("genuine height · two steps", 0, 2, "#6a624f", "#8a8478")
].forEach((panel, index) => sc.drawImage(panel, index * 152, 0));
const contactShadeMatrix = write("contact/elevation-contact-shade-matrix-800pct.png", shadeMatrixCanvas);
const contactShadeGrayscaleMatrix = write("contact/elevation-contact-shade-matrix-grayscale-800pct.png", grayscale(shadeMatrixCanvas));
const visibilitySheet = createCanvas(2 * proofCellWidth, proofCellHeight), vc = visibilitySheet.getContext("2d"); rect(vc, "#181716", 0, 0, visibilitySheet.width, visibilitySheet.height);
[["full / fringe / remembered / hidden", boundaryA], ["remote mutation · last-seen unchanged", boundaryB]].forEach(([label, image], index) => { const x = index * proofCellWidth; vc.fillStyle = "#e8dfca"; vc.font = "bold 15px sans-serif"; vc.fillText(label, x + 44, 24); vc.drawImage(image, x + 44, 40); });
const visibilityMatrix = write("contact/visibility-disclosure-matrix.png", visibilitySheet);

const manifest = {
  schemaVersion: 1, identity: "world-atmosphere-presentation-assets-0.1", integrationReady: false,
  exporter: { file: "scripts/export-atmosphere-presentation-kit.mjs", sha256: sha(fs.readFileSync(new URL(import.meta.url))) },
  nativeTileSize: { width: 16, height: 16 }, fixedFixture: { map: "earthlike-15x15", width: 15, height: 15, phone: { width: 368, height: 800 } },
  phaseSeed: PHASE_SEED, resolverVersion: "asset-proof-only-no-source-resolution", densityBands, motionBands,
  families: Object.fromEntries(Object.entries(families).map(([id, family]) => [id, { stableID: `atmosphere.${id}.v1`, paletteRamp: family.palette, layer: family.layer, source: source[id], binaryStaticFallback: source[id].light }])),
  contactShade: { stableID: "elevation.contact-shade.v1", lowerSurfaceOnly: true, maxDepth: 2, sources: shades },
  compositionOrder: ["terrain", "genuine-elevation-contact-shade", "static-content", "suspended-medium", "precipitation", "visible-actors-and-cues", "visibility-treatment", "opaque-hidden-mask", "hud"],
  evidence, contactSheet, proofMatrix, grayscaleProofMatrix, motionMatrix, contactShadeMatrix, contactShadeGrayscaleMatrix, visibilityMatrix,
  disclosure: { atmosphereStates: ["current-full", "current-fringe"], rememberedAtmosphere: false, hiddenRGBA: [0, 0, 0, 255], movingEntitiesRemembered: false },
  forbidden: ["clouds", "lightning", "puddles", "snow-terrain", "snowdrifts", "generic-tint", "standalone-wind-lines", "weather-gameplay", "native-gameplay", "terrain-mutation", "layout-mutation"],
  provenance: "Deterministic integer-pixel runtime-composable AssetLab proof; phone images are evidence, not integration authority."
};
fs.writeFileSync(path.join(artifact, "manifest.json"), JSON.stringify(manifest, null, 2) + "\n");
console.log(`atmosphere kit ${sha(fs.readFileSync(path.join(artifact, "manifest.json")))}`);
