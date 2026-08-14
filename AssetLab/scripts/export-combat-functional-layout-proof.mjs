import { createRequire } from "node:module";
import crypto from "node:crypto";
import fs from "node:fs";
import {
  offensePresentationNodes as nodes,
  offenseTrueGraphByID as byID,
  proofVisualState,
} from "../src/combat-tree-true-graph-kit.js";
import effectCopy from "../../docs/combat-tree-v2-effect-copy.generated.json" with { type: "json" };

const { createCanvas } = createRequire(import.meta.url)("@napi-rs/canvas");
const C = { board: "#121211", paper: "#e7dfca", ink: "#191816", muted: "#746e62", gold: "#af873c", blue: "#52778a", line: "#887d68", blocked: "#b9b09d", owned: "#425d4b" };
const positions = new Map();
const laneX = [70, 184, 298], depthY = { 1: 148, 2: 246, 3: 344, 4: 442, 5: 534 };
for (const node of nodes) {
  const pair = node.role.endsWith("A") ? -27 : node.role.endsWith("B") ? 27 : 0;
  positions.set(node.id, { x: laneX[node.laneIndex] + pair, y: depthY[node.depth] });
}
const selectedID = "combat.offense.precision.finish";

function labelFor(node) {
  const lane = node.laneName.slice(0, 1);
  const role = ({ root: "R", fundamentalA: "F1", fundamentalB: "F2", developmentA: "D1", developmentB: "D2", masteryA: "M1", masteryB: "M2", capstone: "C" })[node.role];
  return `${lane}${role}`;
}
function parentNames(node) { return node.alternativeParents.map(id => byID[id].name); }
function text(c, value, x, y, size = 11, bold = false, align = "left") { c.fillStyle = c.fillStyle || C.ink; c.font = `${bold ? "bold " : ""}${size}px Georgia`; c.textAlign = align; c.fillText(value, x, y); c.textAlign = "left"; }
function wrap(c, value, x, y, width, size = 11, line = 14) { const words = value.split(" "); let row = "", yy = y; c.font = `${size}px Georgia`; for (const word of words) { const next = row ? `${row} ${word}` : word; if (row && c.measureText(next).width > width) { text(c, row, x, yy, size); row = word; yy += line; } else row = next; } if (row) text(c, row, x, yy, size); return yy; }
function stateMark(c, node, state, x, y) {
  c.fillStyle = state === "owned" ? C.owned : state === "selected" ? C.gold : state === "available" ? "#f5efde" : C.blocked;
  c.strokeStyle = C.ink; c.lineWidth = state === "selected" ? 3 : 1.5;
  if (node.role === "capstone") { c.beginPath(); c.moveTo(x, y - 22); c.lineTo(x + 22, y); c.lineTo(x, y + 22); c.lineTo(x - 22, y); c.closePath(); c.fill(); c.stroke(); }
  else { c.fillRect(x - 22, y - 22, 44, 44); c.strokeRect(x - 21.5, y - 21.5, 43, 43); }
  c.fillStyle = state === "owned" ? "#fff" : C.ink;
  const mark = node.grantsTechnique ? "◆" : state === "owned" ? "✓" : state === "blocked" ? "—" : "○";
  text(c, mark, x, y + 5, 14, true, "center");
  c.fillStyle = C.ink; text(c, labelFor(node), x, y + 35, 8, true, "center");
}
function phone(c, ox, grayscale = false) {
  c.save(); c.translate(ox, 42); c.fillStyle = C.paper; c.fillRect(0, 0, 368, 800); c.strokeStyle = C.line; c.strokeRect(.5, .5, 367, 799);
  c.fillStyle = C.ink; text(c, "OFFENSE · ROUTE EXPLORER", 16, 26, 16, true);
  c.fillStyle = C.muted; text(c, "Actor ▾   Fixture ▾   Tree: Offense", 16, 47, 10);
  c.strokeStyle = C.line; c.strokeRect(16, 58, 336, 42); c.fillStyle = C.ink; text(c, "7 points  −  +     A  B     Routes: 79", 28, 84, 11, true);
  for (const node of nodes) for (const parentID of node.alternativeParents) { const a = positions.get(parentID), b = positions.get(node.id), hybrid = byID[parentID].laneID !== node.laneID; c.strokeStyle = hybrid ? (grayscale ? "#444" : C.blue) : C.line; c.setLineDash(hybrid ? [4, 3] : []); c.lineWidth = 1.5; c.beginPath(); c.moveTo(a.x, a.y + 22); c.lineTo(b.x, b.y - 22); c.stroke(); }
  c.setLineDash([]);
  for (const node of nodes) { const p = positions.get(node.id); stateMark(c, node, proofVisualState(node.id), p.x, p.y); }
  c.fillStyle = C.paper; c.fillRect(8, 574, 352, 178); c.strokeStyle = C.line; c.strokeRect(8.5, 574.5, 351, 177);
  c.fillStyle = C.ink; text(c, "Finish · Selected · Technique", 20, 598, 14, true);
  c.fillStyle = C.muted; wrap(c, effectCopy.effectCopyByNode[selectedID], 20, 619, 328, 11, 14);
  text(c, `Parents: ${parentNames(byID[selectedID]).join(" OR ")}`, 20, 665, 10);
  text(c, "Legal next · adds one sandbox point", 20, 682, 10);
  c.fillStyle = C.gold; c.fillRect(20, 696, 126, 44); c.fillStyle = C.ink; text(c, "Add to sandbox", 35, 723, 11, true);
  c.strokeStyle = C.line; c.strokeRect(158, 696, 92, 44); text(c, "Freeze A", 178, 723, 11, true);
  c.strokeRect(260, 696, 88, 44); text(c, "Help", 290, 723, 11, true);
  c.fillStyle = C.muted; text(c, "Solid: own lane · dashed: authored hybrid", 16, 774, 9);
  c.restore();
}

const main = createCanvas(776, 850), mc = main.getContext("2d"); mc.imageSmoothingEnabled = false; mc.fillStyle = C.board; mc.fillRect(0, 0, 776, 850); mc.fillStyle = "#d3bd7f"; text(mc, "COMBAT GRAPH · FUNCTIONAL LAYOUT CANDIDATE", 12, 25, 13, true); phone(mc, 10); phone(mc, 398, true); const gray = mc.getImageData(398, 42, 368, 800); for (let i = 0; i < gray.data.length; i += 4) { const y = Math.round(.2126 * gray.data[i] + .7152 * gray.data[i + 1] + .0722 * gray.data[i + 2]); gray.data[i] = gray.data[i + 1] = gray.data[i + 2] = y; } mc.putImageData(gray, 398, 42);
const mainPath = "artifacts/combat-tree-functional-layout-proof-v0.4.png"; fs.writeFileSync(mainPath, main.toBuffer("image/png"));

const large = createCanvas(1864, 850), lc = large.getContext("2d"); lc.fillStyle = C.board; lc.fillRect(0, 0, 1864, 850); lc.fillStyle = "#d3bd7f"; text(lc, "COMBAT GRAPH · LARGE TEXT / VOICEOVER ORDER", 12, 25, 13, true);
for (let depth = 1; depth <= 5; depth++) { const ox = 10 + (depth - 1) * 372; lc.fillStyle = C.paper; lc.fillRect(ox, 40, 368, 800); lc.strokeStyle = C.line; lc.strokeRect(ox + .5, 40.5, 367, 799); lc.fillStyle = C.ink; text(lc, `Offense · Depth ${depth} of 5`, ox + 18, 70, 18, true); text(lc, "Graph scroll position · not a replacement list", ox + 18, 92, 11); let y = 112; for (const node of nodes.filter(n => n.depth === depth)) { lc.strokeStyle = C.line; lc.strokeRect(ox + 18, y, 332, 88); lc.fillStyle = C.ink; text(lc, `${node.laneName}: ${node.name}`, ox + 28, y + 20, 15, true); text(lc, `${proofVisualState(node.id)} · ${node.role}${node.grantsTechnique ? " · technique" : ""}`, ox + 28, y + 41, 12); const req = node.alternativeParents.length ? `Requires ${parentNames(node).join(" OR ")}.` : "No node prerequisite."; wrap(lc, req, ox + 28, y + 62, 310, 12, 15); y += 96; } if (depth === 5) { lc.fillStyle = "#d8cfba"; lc.fillRect(ox + 18, y + 6, 332, 150); lc.fillStyle = C.ink; text(lc, "Selected detail stays edge-clamped", ox + 28, y + 30, 14, true); wrap(lc, "Killing Stroke: connected seven-node route; five Precision nodes including capstone; earliest point 8.", ox + 28, y + 52, 310, 12, 16); } text(lc, `Scroll position ${depth} of 5`, ox + 18, 822, 12, true); }
const largePath = "artifacts/combat-tree-functional-layout-proof-v0.4-large-text.png"; fs.writeFileSync(largePath, large.toBuffer("image/png"));

const sha = path => crypto.createHash("sha256").update(fs.readFileSync(path)).digest("hex");
const report = {
  version: "combat-functional-layout-proof-0.4.0",
  evidenceRole: "assetlabFunctionalLayoutFixture",
  integrationReady: false,
  authority: "docs/combat-tree-v2-authority.json",
  effectCopy: "docs/combat-tree-v2-effect-copy.generated.json",
  temporaryMarksOnly: true,
  pngSHA256: sha(mainPath),
  largeTextPNGSHA256: sha(largePath),
  voiceOverOrder: ["tree and fixture context", "depth", "discipline and node name", "purchase state", "technique or capstone role", "exact effect", "alternative parents or capstone gate", "available action"],
  accessibilityNodes: nodes.map(node => ({
    id: node.id,
    depth: node.depth,
    name: node.name,
    discipline: node.laneName,
    state: proofVisualState(node.id),
    role: node.role,
    grantsTechnique: node.grantsTechnique,
    effect: effectCopy.effectCopyByNode[node.id],
    prerequisites: parentNames(node),
    action: proofVisualState(node.id) === "available" || proofVisualState(node.id) === "selected" ? "Add to sandbox" : null,
  })),
  selectedNode: { id: selectedID, state: "selected", effect: effectCopy.effectCopyByNode[selectedID], parents: parentNames(byID[selectedID]) },
  assertions: ["full fan-and-fork topology remains visible", "sibling alternatives use OR", "hybrid edges remain authored-only", "detail does not cover selected node or edges", "state and role are separate", "no tutorial or handmade glyph claim"]
};
fs.writeFileSync("artifacts/combat-tree-functional-layout-proof-v0.4.json", `${JSON.stringify(report, null, 2)}\n`);
