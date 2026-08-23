import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const WIDTH = 16;
export const HEIGHT = 19;
export const PIVOT = Object.freeze({ x: 8, y: 18 });
export const sha256 = bytes => crypto.createHash("sha256").update(bytes).digest("hex");

const here = path.dirname(fileURLToPath(import.meta.url));
export const assetLabRoot = path.resolve(here, "..");
export const cataloguePath = path.join(assetLabRoot, "..", "Sources", "Content", "Data", "items.json");
export const catalogueSHA256 = sha256(fs.readFileSync(cataloguePath));
const catalogue = JSON.parse(fs.readFileSync(cataloguePath, "utf8")).items;

export const exactCatalogueObjectIDs = Object.freeze([
  "essence_crystal", "heat_core", "caustic_core", "light_core", "conduit_fixture",
  "curio_humming_shard", "curio_bound_knot",
  "salve_lesser", "salve", "salve_greater", "draught_clearing", "draught_quenching",
  "antidote_broad", "stonebark_tonic", "venom", "firebrand", "briar_oil", "flashsalt",
  "solvent", "lure", "scent_mask", "stillwater", "waystone", "torch", "farsight_draught",
  "cache_key", "anchor_frame",
]);

export const objectRecords = Object.freeze(exactCatalogueObjectIDs.map(id => {
  const item = catalogue.find(row => row.id === id);
  if (!item) throw new Error(`missing-current-catalogue-object:${id}`);
  if (!["treasure", "curio", "consumable", "key"].includes(item.kind)) throw new Error(`invalid-object-kind:${id}`);
  return Object.freeze({ id, name: item.name, kind: item.kind, identifiedState: item.kind === "curio" ? "known-or-unknown" : "known-only" });
}));

const K = "#141518";
const sprite = (id, kind, palette, rows) => Object.freeze({ id, kind, palette: Object.freeze({ k: K, ...palette }), rows: Object.freeze(rows) });

// Every row below is deliberately authored at logical resolution. These are offline source pixels,
// not recipes available to the runtime. Shared letters are local palette roles only.
export const authoredSprites = Object.freeze([
  sprite("essence_crystal", "treasure", { d:"#50376d", b:"#8c62b0", l:"#c79be0", h:"#fff1ff", m:"#82786f" }, [
    "....h....", "...hlh...", "..hlblh..", ".hldbldh.", "hldbbbdlh", "..dbbbd..", ".mddddd m.".replaceAll(" ",""), "mmlkklmm", ".mmkkmm.", "..mmmm..",
  ]),
  sprite("heat_core", "treasure", { d:"#4b2a1d", b:"#b64a17", l:"#ff8b16", h:"#ffd96a", m:"#696762" }, [
    "..mmmmm..", ".mmkkkmm.", "mmkdddkmm", "mkdbbbdkm", "mkblhlbkm", "mkblhlbkm", "mkdbbbdkm", "mmkdddkmm", ".mmkkkmm.", "..mmmmm..",
  ]),
  sprite("caustic_core", "treasure", { d:"#24431d", b:"#3b8e25", l:"#78d52c", h:"#e5ff70", m:"#5e6560" }, [
    ".....l....", "...mmm.l..", "l.mkkkm...", "..kdddk...", ".kdbbbdk..", "kblhhlbk..", ".kdbbbdk.l", "..kdddk...", "...kkk....", "..m...m...",
  ]),
  sprite("light_core", "treasure", { d:"#7e570c", b:"#d99b12", l:"#ffd33f", h:"#fffbd0", m:"#c7b783" }, [
    ".....h.....", "..h..m..h..", "...mkkkm...", "..mkdddkm..", ".mkdbbbdkm.", "hkdblhlbdkh", ".mkdbbbdkm.", "..mkdddkm..", "...mkkkm...", "..h..m..h..", ".....h.....",
  ]),
  sprite("conduit_fixture", "treasure", { d:"#56301d", b:"#a85d25", l:"#e0953c", h:"#ffd585", a:"#ff7018" }, [
    "....kk....", "...kllk...", "..klddlk..", ".kldaadlk.", "kllabballk", "kddabba ddk".replaceAll(" ",""), "kbbkkkkbbk", ".kkk..kkk.", "..kk..kk..",
  ]),
  sprite("curio_humming_shard", "curio", { d:"#4f2e70", b:"#7b45a3", l:"#c36beb", h:"#f2c9ff", a:"#d780ff" }, [
    "......h..", ".....hl..", "....hlb.a", "...hlbd..", "..hlbdd.a", ".hlbdd...", "hlbdd....", ".kddd...a", "..kkk....",
  ]),
  sprite("curio_bound_knot", "curio", { d:"#5b4c3b", b:"#a58a64", l:"#d7c18e", h:"#f0e2b8", a:"#34302d" }, [
    ".kllk.kllk.", "klbbkklbbkl", "kbaakkkabk", "klaakkkalk", ".kkadddakk.", ".kkdbbbdkk.", "klaakkkalk", "kbaakkkabk", "klbbkklbbkl", ".kllk.kllk.",
  ]),
  sprite("salve_lesser", "consumable", { d:"#315a22", b:"#548d2c", l:"#8cc54a", h:"#e1ef9b", c:"#6e4928" }, [
    "..kcck..", "..kcck..", ".kkllkk.", ".kdbbdk.", ".kbhlbk.", ".kdbbdk.", ".kbbbbk.", ".kddddk.", "..kkkk..",
  ]),
  sprite("salve", "consumable", { d:"#285421", b:"#347f2e", l:"#72b654", h:"#d9e8a0", c:"#d1bb88" }, [
    "..kcck..", ".kccc ck.".replaceAll(" ",""), "kkllllkk", "kdbbbbdk", "kbhllhbk", "kbbbbbbk", "kdbbbbdk", ".kddddk.", "..kkkk..",
  ]),
  sprite("salve_greater", "consumable", { d:"#1c4822", b:"#2f7134", l:"#66a84a", h:"#cfe68f", g:"#d89f24" }, [
    "...kk...", "..kllk..", ".kkllkk.", "kkdbbdkk", "kdbbbbdk", "kblhhlbk", "kgbbbbgk", "kggkkggk", "kdbbbbdk", ".kddddk.", "..kkkk..",
  ]),
  sprite("draught_clearing", "consumable", { d:"#28727a", b:"#35aeb2", l:"#8adddf", h:"#e5ffff", c:"#5e6f71", a:"#438846" }, [
    "...kk...", "..khhk..", "..kllk..", "..kbbk..", ".kdbbdk.", "kdbabb dk".replaceAll(" ",""), "kbalhabk", "kbbbbbbk", ".kddddk.", "..kkkk..",
  ]),
  sprite("draught_quenching", "consumable", { d:"#3a6d8a", b:"#61a8c7", l:"#a9d9e8", h:"#f2ffff", c:"#637681" }, [
    "..kkkk..", ".khllhk.", ".kcccc k.".replaceAll(" ",""), "kkdbbdkk", "kdbbbbdk", "kblhhlbk", "kbbbbbbk", ".kddddk.", "..kkkk..",
  ]),
  sprite("antidote_broad", "consumable", { d:"#4b2b69", b:"#74439a", l:"#b46bd2", h:"#ebc9fa", c:"#88612f" }, [
    "...kk...", "..kcck..", "..kcck..", ".kllllk.", ".kdbbdk.", "kdbbbbdk", "kbkbbkbk", "kbbkkbbk", "kdbbbbdk", ".kddddk.", "..kkkk..",
  ]),
  sprite("stonebark_tonic", "consumable", { d:"#49321e", b:"#74502d", l:"#aa7b45", h:"#dfbd74", a:"#60913a" }, [
    "..kllk..", "..kbbk..", ".kkbbkk.", ".kdbbdk.", "kdbbbbdk", "kbaaaabk", "kba l abk".replaceAll(" ",""), "kdbbbbdk", ".kddddk.", "..kkkk..",
  ]),
  sprite("venom", "consumable", { d:"#3f245d", b:"#67378d", l:"#a75bc9", h:"#e4b4f2", c:"#bbb1c5" }, [
    "...h...", "..hlh..", "..klk..", ".kkbkk.", ".kdbdk.", ".kbbbk.", ".kblbk.", ".kdbdk.", "..kkk..",
  ]),
  sprite("firebrand", "consumable", { d:"#6c2419", b:"#b9361c", l:"#ef641d", h:"#ffd249", c:"#d9bd7d" }, [
    "...h...", "..hlh..", "..lbl..", "..kbk..", ".kkckk.", ".kdbdk.", ".kblbk.", ".kbbbk.", ".kdddk.", "..kkk..",
  ]),
  sprite("briar_oil", "consumable", { d:"#3c5523", b:"#65843b", l:"#9cb85e", h:"#e6d47b", c:"#9c672d", a:"#283d20" }, [
    "...kcck...", "...kcck...", "..kkllkk..", ".akdbbdka.", "akbbllbbka", ".akbbbbka.", "akdbbbbdka", ".akddddka.", "..kkkkkk..",
  ]),
  sprite("flashsalt", "consumable", { d:"#725a28", b:"#b78c3f", l:"#e6c56e", h:"#fff2ad", c:"#d7c28d" }, [
    "..kkkkk..", ".kccccck.", ".kdbbbdk.", ".kb h bk.".replaceAll(" ",""), "kbhhh hbk".replaceAll(" ",""), ".kb h bk.".replaceAll(" ",""), ".kdbbbdk.", ".kddddk.", "..kkkkk..",
  ]),
  sprite("solvent", "consumable", { d:"#32657b", b:"#5faac2", l:"#a4e2ec", h:"#efffff", c:"#535861", a:"#242a33" }, [
    "..kcck..", "..kcck..", "..kllk..", "..kbbk..", "..kbbk..", "..kbak..", "..kbbk..", "..kaak..", "..kddk..", "..kkkk..",
  ]),
  sprite("lure", "consumable", { d:"#5c4530", b:"#9a7447", l:"#d1ae72", h:"#efdfb4", r:"#a64035", m:"#77756f" }, [
    "..kllk..", ".kbbbbk.", ".kbhhbk.", ".kbbbbk.", "rkdbbdkr", "r.kddk.r", "r..kk..r", "....mm..", "....kmm.", ".....kk.",
  ]),
  sprite("scent_mask", "consumable", { d:"#4f4828", b:"#797044", l:"#b5a86b", h:"#e7db9e", c:"#6b4a2d", v:"#e4d2a2" }, [
    "...kcck...", "...kcck...", "..kkllkk..", ".kdbbbbdk.", "vkbbbbbbkv", ".vkbhhbkv.", "vkbbbbbbkv", ".kdbbbbdk.", "..kddddk..", "...kkkk...",
  ]),
  sprite("stillwater", "consumable", { d:"#2f5875", b:"#4d8eb5", l:"#93cde0", h:"#e4f7f7", c:"#7d5b36" }, [
    "...kcck...", "...kcck...", "..kkllkk..", ".kdbbbbdk.", "kbbbbbbbbk", "kllllllllk", "kbbbbbbbbk", "kdbbbbbbdk", ".kddddddk.", "..kkkkkk..",
  ]),
  sprite("waystone", "consumable", { d:"#474747", b:"#6f706d", l:"#aaa99e", h:"#e7d789", a:"#76529b" }, [
    "....h....", "..h.k.h..", ".hk.k.kh.", "h.klll k.h".replaceAll(" ",""), "..kdbdk..", "..kbaik..".replace("i","l"), "..kdbdk..", ".kkdddkk.", "kkkdddkkk", "..kkkkk..",
  ]),
  sprite("torch", "consumable", { d:"#5b2b1b", b:"#a23c1d", l:"#f06b1b", h:"#ffd54a", c:"#704627" }, [
    "...h...", "..hlh..", ".hlllh.", ".lbbbl.", "..kbk..", "..kck..", "..kck..", "..kck..", "..kck..", "..kkk..",
  ]),
  sprite("farsight_draught", "consumable", { d:"#493061", b:"#724a92", l:"#a978c0", h:"#e4c2ee", c:"#886132", e:"#89dcea" }, [
    "...kcck...", "...kcck...", "..kkllkk..", ".kdbbbbdk.", "kbbbeebbbk", "kbbehhebbk", "kbbbeebbbk", ".kdbbbbdk.", "..kddddk..", "...kkkk...",
  ]),
  sprite("cache_key", "key", { d:"#63421e", b:"#9b682e", l:"#d59b4e", h:"#f3cc77" }, [
    "..kkkk...", ".kllllk..", "klbddblk.", "klbkkblk.", ".kllllk..", "...kbk...", "...kbkkkk", "...kblbbk", "...kkkkkk",
  ]),
  sprite("anchor_frame", "key", { d:"#343a3b", b:"#596365", l:"#8f9a95", h:"#e8ddb1" }, [
    "kkk...kkk", "kllk.kllk", "klkkkkklk", ".kkhhhkk.", "..khhhk..", "..khhhk..", ".kkhhhkk.", "klkkkkklk", "kllk.kllk", "kkk...kkk",
  ]),
]);

function opaqueBounds(rgba) {
  let minX = WIDTH, minY = HEIGHT, maxX = -1, maxY = -1;
  for (let y = 0; y < HEIGHT; y += 1) for (let x = 0; x < WIDTH; x += 1) {
    if (rgba[(y * WIDTH + x) * 4 + 3] === 0) continue;
    minX = Math.min(minX, x); minY = Math.min(minY, y); maxX = Math.max(maxX, x); maxY = Math.max(maxY, y);
  }
  if (maxX < 0) throw new Error("empty-authored-object");
  return { minX, minY, maxX, maxY, width: maxX - minX + 1, height: maxY - minY + 1 };
}

function rgb(hex) {
  if (!/^#[0-9a-f]{6}$/i.test(hex)) throw new Error(`invalid-palette-color:${hex}`);
  return [1, 3, 5].map(offset => Number.parseInt(hex.slice(offset, offset + 2), 16));
}

export function authoredObjectSprite(id) {
  const source = authoredSprites.find(row => row.id === id);
  if (!source) throw new Error(`unknown-authored-object:${id}`);
  const logicalRows = source.rows.map(row => [...row]);
  const sourceWidth = Math.max(...logicalRows.map(row => row.length));
  const sourceHeight = logicalRows.length;
  if (sourceWidth > WIDTH || sourceHeight > 18) throw new Error(`authored-object-oob:${id}`);
  const originX = Math.floor((WIDTH - sourceWidth) / 2);
  const originY = 17 - sourceHeight + 1;
  const rgba = new Uint8ClampedArray(WIDTH * HEIGHT * 4);
  logicalRows.forEach((row, y) => row.forEach((symbol, x) => {
    if (symbol === ".") return;
    const color = source.palette[symbol];
    if (!color) throw new Error(`unknown-role:${id}:${symbol}`);
    rgba.set([...rgb(color), 255], ((originY + y) * WIDTH + originX + x) * 4);
  }));
  const bounds = opaqueBounds(rgba);
  if (bounds.maxY !== 17) throw new Error(`object-not-bottom-anchored:${id}`);
  return { key:`catalogue-item/${id}/identified`, catalogueID:id, identified:true, kind:source.kind, width:WIDTH, height:HEIGHT, pivot:{...PIVOT}, bounds, rgba };
}

export function lookupObjectSprite(manifest, request) {
  if (!request || typeof request !== "object" || Array.isArray(request)) return null;
  if (Object.keys(request).sort().join(",") !== "catalogueID,identified,visibility") return null;
  const record = objectRecords.find(row => row.id === request.catalogueID);
  if (!record || typeof request.identified !== "boolean" || !["full", "remembered", "hidden"].includes(request.visibility) || request.visibility === "hidden") return null;
  if (!request.identified) {
    if (record.kind !== "curio") return null;
    return manifest.assetsByKey["catalogue-item/unknown-curio"] ?? null;
  }
  return manifest.assetsByKey[`catalogue-item/${request.catalogueID}/identified`] ?? null;
}
