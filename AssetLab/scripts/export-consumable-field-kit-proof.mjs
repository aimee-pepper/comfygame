import { createRequire } from "node:module";
import fs from "node:fs";
import { allPreparationIDs, preparationFamilies, resolveFieldKit, consumableFieldKitProofVersion } from "../src/consumable-field-kit-proof.js";
import { catalogueItemIconCommands } from "../src/item-kit.js";

const { createCanvas } = createRequire(import.meta.url)("@napi-rs/canvas");
const canvas = createCanvas(1492, 1150);
const c = canvas.getContext("2d");
const items = JSON.parse(fs.readFileSync("../Sources/Content/Data/items.json", "utf8")).items;
const byID = new Map(items.map((item) => [item.id, item]));
const P = { board: "#11110f", paper: "#e8dfc9", panel: "#d7cdb5", ink: "#191816", gold: "#a9853c", purple: "#75598b", muted: "#756d5d" };

function text(value, x, y, size = 13, bold = false, align = "left", color = P.ink) { c.fillStyle = color; c.font = `${bold ? "bold " : ""}${size}px Georgia`; c.textAlign = align; c.fillText(value, x, y); }
function wrap(value, x, y, width, size = 13, line = 18) { const words = value.split(" "); let row = "", n = 0; c.font = `${size}px Georgia`; for (const word of words) { const next = row ? `${row} ${word}` : word; if (c.measureText(next).width > width) { text(row, x, y + n++ * line, size); row = word; } else row = next; } text(row, x, y + n * line, size); }
function icon(itemID, x, y, scale = 1) { for (const command of catalogueItemIconCommands(itemID)) { c.fillStyle = command.color; c.fillRect(x + command.x * scale, y + command.y * scale, command.w * scale, command.h * scale); } }
function phone(x, title, subtitle) { c.fillStyle = P.paper; c.fillRect(x, 40, 368, 800); c.strokeStyle = "#887d68"; c.strokeRect(x + .5, 40.5, 367, 799); text(title, x + 18, 69, 19, true); text(subtitle, x + 18, 94, 11); }
function tile(x, y, id, selected = false, quantity = null, desired = null) { c.fillStyle = "#cfc4aa"; c.fillRect(x, y, 48, 52); if (selected) { c.strokeStyle = P.purple; c.lineWidth = 3; c.strokeRect(x + 1.5, y + 1.5, 45, 49); } icon(id, x + 8, y + 5, 1); if (quantity !== null) { c.fillStyle = P.ink; c.fillRect(x + 30, y + 34, 16, 16); text(`${quantity}`, x + 38, y + 46, 10, true, "center", "#fff"); } if (desired !== null) { c.strokeStyle = P.gold; c.lineWidth = 2; c.beginPath(); c.moveTo(x + 3, y + 45); c.lineTo(x + 3, y + 34); c.lineTo(x + 13, y + 34); c.stroke(); text(`${desired}`, x + 8, y + 44, 9, true, "center"); } }
function sixAcross(x, y, ids, selected, stocks = {}, desired = {}) { ids.forEach((id, index) => tile(x + index % 6 * 54, y + Math.floor(index / 6) * 60, id, id === selected, stocks[id] ?? null, desired[id] ?? null)); }

function apothecary(x, gray = false) {
  phone(x, "APOTHECARY", gray ? "Recipes · literal grayscale" : "Recipes · three physical families");
  const tabs = [["Treatments", 7], ["Coatings", 4], ["Fieldwork", 6]];
  tabs.forEach(([name, count], i) => { const tx = x + 18 + i * 110; c.fillStyle = i === 0 ? P.gold : P.panel; c.fillRect(tx, 112, 102, 76); text(name, tx + 51, 141, 13, true, "center"); text(`${count} recipes`, tx + 51, 165, 11, false, "center"); });
  text("Treatments", x + 18, 222, 15, true);
  const fixtureStock = Object.fromEntries(allPreparationIDs.map((id, i) => [id, i % 4]));
  fixtureStock.salve_lesser = 2;
  sixAcross(x + 20, 238, preparationFamilies.treatments.slice(0, 6), "salve_lesser", fixtureStock);
  c.fillStyle = P.panel; c.fillRect(x + 18, 320, 332, 358);
  icon("salve_lesser", x + 34, 340, 1.25);
  text("Lesser Salve", x + 88, 365, 18, true);
  text("Owned 2 · prepare 2", x + 88, 392, 14, true);
  wrap(byID.get("salve_lesser").blurb, x + 34, 430, 300, 14, 21);
  text("World resources", x + 34, 503, 13, true);
  text("Exact ingredients · rules preview", x + 34, 526, 12);
  text("Refined Essence 0", x + 34, 555, 14, true);
  text("Destination Storehouse", x + 34, 580, 13);
  c.fillStyle = P.purple; c.fillRect(x + 34, 610, 300, 44); text("Prepare 2", x + 184, 638, 14, true, "center", "#fff");
  text("Preparation does not alter Field Kit.", x + 34, 700, 11);
  if (gray) { const image = c.getImageData(x, 40, 368, 800); for (let i = 0; i < image.data.length; i += 4) { const value = Math.round(.2126 * image.data[i] + .7152 * image.data[i + 1] + .0722 * image.data[i + 2]); image.data[i] = image.data[i + 1] = image.data[i + 2] = value; } c.putImageData(image, x, 40); }
}

function supplies(x, large = false) {
  const stock = { salve_lesser: 1, salve: 3, draught_clearing: 1, venom: 2, torch: 4, waystone: 0 };
  const desired = { salve_lesser: 3, salve: 1, draught_clearing: 1, venom: 1, torch: 0, waystone: 0 };
  const ids = Object.keys(stock);
  const packed = resolveFieldKit({ capacity: 4, stock: Object.entries(stock).map(([itemID, count]) => ({ itemID, count })), entries: Object.entries(desired).map(([itemID, desiredCount], order) => ({ itemID, desiredCount, order })) });
  phone(x, "FIELD KIT", large ? "Supplies · Accessibility Large Text" : "Supplies · saved desired quantities");
  text("Instruments", x + 18, 130, 13); text("Supplies", x + 120, 130, 13, true); c.fillStyle = P.gold; c.fillRect(x + 116, 142, 76, 3);
  sixAcross(x + 20, 170, ids, "salve_lesser", stock, desired);
  text("gold corner = wanted · dark badge = stored", x + 20, 238, 10);
  c.fillStyle = P.panel; c.fillRect(x + 18, 250, 332, large ? 405 : 340);
  icon("salve_lesser", x + 34, 270, 1.25);
  text("Lesser Salve", x + 88, 295, large ? 20 : 18, true);
  text("Stored 1 · wanted 3", x + 34, 340, large ? 17 : 14, true);
  text("Packing shortage: wanted 3, available 1", x + 34, 373, large ? 15 : 12);
  wrap(byID.get("salve_lesser").blurb, x + 34, 412, 300, large ? 16 : 13, large ? 23 : 19);
  c.fillStyle = "#bdb39c"; c.fillRect(x + 34, large ? 500 : 480, 44, 44); text("−", x + 56, large ? 529 : 509, 20, true, "center");
  text("3 desired", x + 184, large ? 528 : 508, large ? 17 : 14, true, "center");
  c.fillStyle = P.purple; c.fillRect(x + 290, large ? 500 : 480, 44, 44); text("+", x + 312, large ? 529 : 509, 20, true, "center", "#fff");
  text(`${packed.selectedBins} selected / ${packed.capacity} bins available`, x + 34, large ? 580 : 555, large ? 15 : 12, true);
  text(`${packed.packedBins} pack · saved order + item ID tie-break`, x + 34, large ? 615 : 578, large ? 14 : 11);
  text("Raise Salve quantity: still 4 bins.", x + 34, large ? 650 : 610, large ? 14 : 11);
  text("Add Torch family: disabled at 4 / 4.", x + 34, large ? 680 : 633, large ? 14 : 11);
  if (large) { text("Shortage does not block departure.", x + 34, 718, 14); text("Packing commits only with Bind/Revisit.", x + 34, 746, 14); }
}

c.fillStyle = P.board; c.fillRect(0, 0, 1492, 850);
text(consumableFieldKitProofVersion, 12, 25, 13, true, "left", "#d3bd7f");
apothecary(10, false);
apothecary(382, true);
supplies(754, false);
supplies(1126, true);

function familyStrip(y, grayscale = false) {
  text(grayscale ? "ALL 17 · LITERAL GRAYSCALE" : "ALL 17 · CANONICAL COLOR", 18, y + 19, 12, true, "left", "#d3bd7f");
  let cursor = 255;
  for (const [family, ids] of Object.entries(preparationFamilies)) {
    text(`${family.toUpperCase()} ${ids.length}`, cursor, y + 19, 11, true, "left", "#eee9df");
    ids.forEach((id, index) => tile(cursor + index * 54, y + 28, id));
    cursor += ids.length * 54 + 24;
  }
  if (grayscale) {
    const image = c.getImageData(0, y, 1492, 84);
    for (let i = 0; i < image.data.length; i += 4) {
      const value = Math.round(.2126 * image.data[i] + .7152 * image.data[i + 1] + .0722 * image.data[i + 2]);
      image.data[i] = image.data[i + 1] = image.data[i + 2] = value;
    }
    c.putImageData(image, 0, y);
  }
}
familyStrip(865, false);
familyStrip(955, true);
text("KEY", 18, 1065, 12, true, "left", "#d3bd7f");
text(preparationFamilies.treatments.map((id) => byID.get(id).name).join(" · "), 78, 1065, 10, false, "left", "#eee9df");
text(preparationFamilies.coatings.map((id) => byID.get(id).name).join(" · "), 78, 1092, 10, false, "left", "#eee9df");
text(preparationFamilies.fieldwork.map((id) => byID.get(id).name).join(" · "), 78, 1119, 10, false, "left", "#eee9df");
fs.writeFileSync("artifacts/consumable-field-kit-proof-v0.1.png", canvas.toBuffer("image/png"));
