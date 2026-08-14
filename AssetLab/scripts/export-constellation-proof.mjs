import { createRequire } from "node:module";
import fs from "node:fs";
import {
  constellationNode,
  constellationState,
  constellationProofVersion,
  constellationRealityExplanation,
} from "../src/constellation-proof-kit.js";

const { createCanvas } = createRequire(import.meta.url)("@napi-rs/canvas");
const canvas = createCanvas(1492, 940);
const c = canvas.getContext("2d");
const paper = "#e7dfca";
const ink = "#191816";
const purple = "#725989";
const gold = "#af873c";

function text(value, x, y, size = 13, bold = false, align = "left") {
  c.fillStyle = ink;
  c.font = `${bold ? "bold " : ""}${size}px Georgia`;
  c.textAlign = align;
  c.fillText(value, x, y);
}

function wrap(value, x, y, width, size = 13, lineHeight = 19) {
  const words = value.split(" ");
  let row = "";
  let line = 0;
  c.font = `${size}px Georgia`;
  for (const word of words) {
    const next = row ? `${row} ${word}` : word;
    if (c.measureText(next).width > width) {
      text(row, x, y + line++ * lineHeight, size);
      row = word;
    } else {
      row = next;
    }
  }
  text(row, x, y + line * lineHeight, size);
}

function star(x, y, radius, fill, lineWidth = 3) {
  c.fillStyle = fill;
  c.strokeStyle = ink;
  c.lineWidth = lineWidth;
  c.beginPath();
  for (let i = 0; i < 10; i += 1) {
    const angle = -Math.PI / 2 + i * Math.PI / 5;
    const r = i % 2 ? radius * 0.45 : radius;
    const px = x + Math.cos(angle) * r;
    const py = y + Math.sin(angle) * r;
    if (i) c.lineTo(px, py);
    else c.moveTo(px, py);
  }
  c.closePath();
  c.fill();
  c.stroke();
}

function boughtMark(x, y, radius) {
  c.strokeStyle = "#fff";
  c.lineWidth = Math.max(2, radius / 8);
  c.lineCap = "round";
  c.beginPath();
  c.moveTo(x - radius * 0.38, y);
  c.lineTo(x - radius * 0.08, y + radius * 0.3);
  c.lineTo(x + radius * 0.45, y - radius * 0.35);
  c.stroke();
  c.lineCap = "butt";
}

function phone(ox, { rank, motes, label, large = false }) {
  const presentation = constellationState({ rank, motes });
  c.fillStyle = paper;
  c.fillRect(ox, 40, 368, 800);
  c.strokeStyle = "#887d68";
  c.strokeRect(ox + 0.5, 40.5, 367, 799);

  text("CONSTELLATION", ox + 18, 70, large ? 20 : 19, true);
  star(ox + 278, 65, 7, gold, 1.5);
  text(`Motes ${motes}`, ox + 350, 70, large ? 15 : 13, true, "right");
  text(label, ox + 18, 96, large ? 13 : 11);

  star(
    ox + 184,
    large ? 225 : 238,
    32,
    presentation.state === "bought"
      ? purple
      : presentation.state === "affordable"
        ? gold
        : "#b8b09f",
  );
  if (presentation.state === "bought") boughtMark(ox + 184, large ? 225 : 238, 32);
  text(constellationNode.name, ox + 184, large ? 288 : 300, large ? 20 : 17, true, "center");
  text(`${presentation.state} · rank ${presentation.rank}`, ox + 184, large ? 316 : 323, large ? 16 : 13, true, "center");

  const detailY = large ? 342 : 365;
  const detailHeight = large ? 386 : 300;
  c.fillStyle = "#d8cfba";
  c.fillRect(ox + 18, detailY, 332, detailHeight);
  text(constellationNode.name, ox + 34, detailY + 32, large ? 19 : 16, true);
  wrap(
    constellationNode.effect,
    ox + 34,
    detailY + 65,
    300,
    large ? 17 : 13,
    large ? 25 : 19,
  );
  text(`Rank ${presentation.rank}`, ox + 34, detailY + (large ? 174 : 135), large ? 16 : 13, true);
  text(`Cost ${constellationNode.costs[0]} Motes`, ox + 34, detailY + (large ? 204 : 159), large ? 16 : 13, true);
  text(
    presentation.state === "shortfall"
      ? `Needs ${presentation.missing} more Motes`
      : presentation.state === "bought"
        ? "Fixed in place"
        : "Ready to fix in place",
    ox + 34,
    detailY + (large ? 238 : 185),
    large ? 16 : 13,
    true,
  );
  if (presentation.action) {
    const buttonY = detailY + (large ? 264 : 205);
    c.fillStyle = purple;
    c.fillRect(ox + 34, buttonY, 300, 44);
    c.fillStyle = "#fff";
    c.font = `bold ${large ? 16 : 14}px Georgia`;
    c.textAlign = "center";
    c.fillText(presentation.action, ox + 184, buttonY + 28);
  }
  wrap(
    constellationRealityExplanation,
    ox + 34,
    detailY + (large ? 348 : 275),
    296,
    large ? 14 : 11,
    large ? 20 : 16,
  );
}

c.fillStyle = "#121211";
c.fillRect(0, 0, 1492, 850);
c.fillStyle = "#d3bd7f";
c.font = "bold 13px Georgia";
c.fillText(constellationProofVersion, 12, 25);

phone(10, { rank: 0, motes: 4, label: "Affordable · color" });
phone(382, { rank: 0, motes: 1, label: "Shortfall · literal grayscale" });
phone(754, { rank: 1, motes: 2, label: "Bought · color" });
phone(1126, { rank: 0, motes: 3, label: "Accessibility Large Text", large: true });

const grayscalePhone = c.getImageData(382, 40, 368, 800);
for (let i = 0; i < grayscalePhone.data.length; i += 4) {
  const value = Math.round(
    0.2126 * grayscalePhone.data[i]
      + 0.7152 * grayscalePhone.data[i + 1]
      + 0.0722 * grayscalePhone.data[i + 2],
  );
  grayscalePhone.data[i] = value;
  grayscalePhone.data[i + 1] = value;
  grayscalePhone.data[i + 2] = value;
}
c.putImageData(grayscalePhone, 382, 40);

c.fillStyle = "#d3bd7f";
c.font = "bold 12px Georgia";
c.textAlign = "left";
c.fillText("REDUNDANT NODE STATES · SAME-SCALE LITERAL GRAYSCALE", 18, 870);
const stateStrip = [
  ["Affordable", "#a4a4a4", false],
  ["Shortfall", "#d0d0d0", false],
  ["Bought", "#777777", true],
];
for (let i = 0; i < stateStrip.length; i += 1) {
  const [label, fill, bought] = stateStrip[i];
  const x = 310 + i * 290;
  star(x, 896, 24, fill, 2);
  if (bought) boughtMark(x, 896, 24);
  c.fillStyle = "#eee9df";
  c.font = "bold 15px Georgia";
  c.textAlign = "left";
  c.fillText(label, x + 42, 902);
}

fs.writeFileSync("artifacts/constellation-proof-v0.1.png", canvas.toBuffer("image/png"));
