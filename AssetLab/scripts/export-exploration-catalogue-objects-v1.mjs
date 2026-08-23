import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createCanvas, ImageData, loadImage } from "@napi-rs/canvas";
import {
  HEIGHT, PIVOT, WIDTH, assetLabRoot, authoredObjectSprite, catalogueSHA256,
  exactCatalogueObjectIDs, objectRecords, sha256,
} from "../src/exploration-catalogue-objects-v1-kit.js";

const here = path.dirname(fileURLToPath(import.meta.url));
const product = path.join(assetLabRoot, "integration", "exploration-catalogue-objects-v1");
const runtime = path.join(product, "runtime");
const assetsDirectory = path.join(runtime, "assets");
const evidenceDirectory = path.join(product, "evidence");
const fixtureDirectory = path.join(assetLabRoot, "fixtures", "exploration-catalogue-objects-v1");
const terrainPath = path.join(assetLabRoot, "artifacts", "terrain-region-continuity-v1", "evidence", "macro-11x11-redraw-a-2x.png");

fs.rmSync(product, { recursive: true, force: true });
fs.mkdirSync(assetsDirectory, { recursive: true });
fs.mkdirSync(evidenceDirectory, { recursive: true });

function canvasOfRGBA(rgba, width, height) {
  const canvas = createCanvas(width, height);
  canvas.getContext("2d").putImageData(new ImageData(new Uint8ClampedArray(rgba), width, height), 0, 0);
  return canvas;
}
function pngOfRGBA(rgba, width, height) { return canvasOfRGBA(rgba, width, height).toBuffer("image/png"); }
function scale(source, factor) {
  const canvas = createCanvas(source.width * factor, source.height * factor);
  const context = canvas.getContext("2d"); context.imageSmoothingEnabled = false;
  context.drawImage(source, 0, 0, canvas.width, canvas.height); return canvas;
}
function grayscale(source) {
  const canvas = createCanvas(source.width, source.height); const context = canvas.getContext("2d");
  context.drawImage(source, 0, 0); const image = context.getImageData(0, 0, canvas.width, canvas.height);
  for (let i = 0; i < image.data.length; i += 4) {
    const value = Math.round(0.2126 * image.data[i] + 0.7152 * image.data[i + 1] + 0.0722 * image.data[i + 2]);
    image.data[i] = value; image.data[i + 1] = value; image.data[i + 2] = value;
  }
  context.putImageData(image, 0, 0); return canvas;
}
function text(context, value, x, y, size = 14, color = "#eadab4", weight = "normal") {
  context.fillStyle = color; context.font = `${weight} ${size}px sans-serif`; context.fillText(value, x, y);
}
function boundsOf(rgba, width, height) {
  let minX = width, minY = height, maxX = -1, maxY = -1;
  for (let y = 0; y < height; y += 1) for (let x = 0; x < width; x += 1) {
    if (rgba[(y * width + x) * 4 + 3] === 0) continue;
    minX = Math.min(minX, x); minY = Math.min(minY, y); maxX = Math.max(maxX, x); maxY = Math.max(maxY, y);
  }
  if (maxX < 0) throw new Error("empty-source");
  return { minX, minY, maxX, maxY, width: maxX - minX + 1, height: maxY - minY + 1 };
}

async function acceptedUnknownCurio() {
  const file = path.join(fixtureDirectory, "pickup-object-unknown-16x16.png");
  const bytes = fs.readFileSync(file);
  if (sha256(bytes) !== "f33ee51acfd51eca425b8221311ff9da53bc0b8e7924348a31398dfb35fc5b80") throw new Error("accepted-unknown-parcel-drift");
  const image = await loadImage(file); if (image.width !== 16 || image.height !== 16) throw new Error("unknown-parcel-dimensions");
  const source = createCanvas(16, 16); source.getContext("2d").drawImage(image, 0, 0);
  const sourceRGBA = new Uint8ClampedArray(source.getContext("2d").getImageData(0, 0, 16, 16).data);
  const sourceBounds = boundsOf(sourceRGBA, 16, 16); const shiftY = 17 - sourceBounds.maxY;
  const rgba = new Uint8ClampedArray(WIDTH * HEIGHT * 4);
  for (let y = 0; y < 16; y += 1) for (let x = 0; x < 16; x += 1) {
    const offset = (y * 16 + x) * 4; if (sourceRGBA[offset + 3] === 0) continue;
    rgba.set(sourceRGBA.slice(offset, offset + 4), ((y + shiftY) * WIDTH + x) * 4);
  }
  return { key:"catalogue-item/unknown-curio", catalogueID:null, identified:false, kind:"curio", width:WIDTH, height:HEIGHT, pivot:{...PIVOT}, bounds:boundsOf(rgba, WIDTH, HEIGHT), rgba };
}

const sprites = exactCatalogueObjectIDs.map(authoredObjectSprite);
const unknownCurio = await acceptedUnknownCurio();
const allSprites = [...sprites, unknownCurio];
const assetsByKey = {}; const uniqueAssets = new Map();
function addAsset(sprite, extra = {}) {
  const png = pngOfRGBA(sprite.rgba, sprite.width, sprite.height); const fileSHA256 = sha256(png);
  const rgbaSHA256 = sha256(Buffer.from(sprite.rgba)); const file = `${fileSHA256}.png`;
  if (!uniqueAssets.has(file)) { uniqueAssets.set(file, png); fs.writeFileSync(path.join(assetsDirectory, file), png); }
  assetsByKey[sprite.key] = { path:`assets/${file}`, width:sprite.width, height:sprite.height,
    pivot:[sprite.pivot.x, sprite.pivot.y], bounds:sprite.bounds, sha256:fileSHA256, rgbaSHA256, ...extra };
}
sprites.forEach(sprite => addAsset(sprite, { catalogueID:sprite.catalogueID, identified:true, kind:sprite.kind, animation:"static", authoring:"manual-logical-pixel-translation-from-generated-reference" }));
addAsset(unknownCurio, { catalogueID:null, identified:false, kind:"curio", animation:"static", authoring:"byte-preserved-accepted-opaque-unknown-parcel" });

const evidence = {};
function evidencePNG(key, canvas) {
  const buffer = canvas.toBuffer("image/png"); const file = `${key}.png`;
  fs.writeFileSync(path.join(evidenceDirectory, file), buffer);
  evidence[key] = { path:`evidence/${file}`, sha256:sha256(buffer), width:canvas.width, height:canvas.height };
}

function spriteSheet() {
  const columns = 3, cardWidth = 360, cardHeight = 245, rows = Math.ceil(allSprites.length / columns);
  const canvas = createCanvas(columns * cardWidth, 82 + rows * cardHeight); const context = canvas.getContext("2d");
  context.fillStyle = "#0e1618"; context.fillRect(0, 0, canvas.width, canvas.height);
  text(context, "FINAL PREMADE CATALOGUE OBJECTS · NATIVE + TRUE 800%", 20, 32, 23, "#efe3c4", "bold");
  text(context, "27 exact current IDs + accepted disclosure-neutral curio parcel · 16×19 · bottom anchor (8,18)", 20, 59, 13, "#b7c7bf");
  allSprites.forEach((sprite, index) => {
    const x = (index % columns) * cardWidth + 12, y = 82 + Math.floor(index / columns) * cardHeight;
    context.fillStyle = index % 2 ? "#152225" : "#18272a"; context.fillRect(x, y, cardWidth - 20, cardHeight - 10);
    const record = objectRecords.find(row => row.id === sprite.catalogueID);
    text(context, record?.name ?? "Unknown curio", x + 12, y + 24, 15, "#eadab4", "bold");
    text(context, sprite.key, x + 12, y + 44, 10, "#91a49d");
    const native = canvasOfRGBA(sprite.rgba, WIDTH, HEIGHT); context.imageSmoothingEnabled = false;
    context.drawImage(native, x + 16, y + 72); context.drawImage(native, x + 70, y + 60, WIDTH * 8, HEIGHT * 8);
    text(context, "native", x + 12, y + 218, 10, "#aebeb7"); text(context, "true 800%", x + 70, y + 218, 10, "#aebeb7");
  });
  return canvas;
}
const sheet = spriteSheet(); evidencePNG("production-objects-native-800pct", sheet); evidencePNG("production-objects-native-800pct-grayscale", grayscale(sheet));

const terrain = await loadImage(terrainPath);
const positions = [[1,1],[3,1],[5,1],[7,1],[9,1],[2,3],[4,3],[6,3],[8,3]];
function phonePage(page) {
  const pageSprites = sprites.slice(page * 9, page * 9 + 9); const canvas = createCanvas(368, 800); const context = canvas.getContext("2d");
  context.fillStyle = "#0e1618"; context.fillRect(0, 0, 368, 800);
  text(context, `CATALOGUE OBJECTS · ${page + 1}/3`, 12, 28, 17, "#efe3c4", "bold");
  text(context, "exact premade 16×19 identity on accepted 11×11 terrain", 12, 49, 11, "#aebeb7");
  context.imageSmoothingEnabled = false; context.drawImage(terrain, 8, 70, 352, 352);
  pageSprites.forEach((sprite, index) => { const [tileX,tileY] = positions[index]; const native = canvasOfRGBA(sprite.rgba, WIDTH, HEIGHT); context.drawImage(native, 8 + tileX * 32, 70 + tileY * 32 - 6, 32, 38); });
  context.strokeStyle = "#5a6a65"; context.strokeRect(7.5,69.5,353,353);
  context.fillStyle = "#172528"; context.fillRect(8,438,352,342); text(context,"VISIBLE IDENTITIES",20,465,14,"#eadab4","bold");
  pageSprites.forEach((sprite,index)=>{const record=objectRecords.find(row=>row.id===sprite.catalogueID);const column=index%2,row=Math.floor(index/2);text(context,record.name,20+column*174,492+row*47,11,"#c5d1cb","bold");text(context,sprite.catalogueID,20+column*174,508+row*47,9,"#82968f");text(context,record.kind,20+column*174,522+row*47,9,"#aebeb7");});
  text(context,"Static loose objects · no implied use/opening/depletion",20,766,10,"#aebeb7"); return canvas;
}
for(let page=0;page<3;page+=1){const phone=phonePage(page);evidencePNG(`applied-map-objects-${page+1}-368x800`,phone);evidencePNG(`applied-map-objects-${page+1}-grayscale-368x800`,grayscale(phone));}

function disclosureSheet(){
  const canvas=createCanvas(1040,450),context=canvas.getContext("2d");context.fillStyle="#0e1618";context.fillRect(0,0,canvas.width,canvas.height);
  text(context,"IDENTIFIED / UNIDENTIFIED / VISIBILITY",20,34,23,"#efe3c4","bold");
  const samples=[sprites.find(s=>s.catalogueID==="curio_humming_shard"),sprites.find(s=>s.catalogueID==="curio_bound_knot"),unknownCurio,null];
  const labels=["HUMMING SHARD · KNOWN","BOUND KNOT · KNOWN","UNKNOWN CURIO · OPAQUE","HIDDEN · NO LOOKUP"];
  samples.forEach((sprite,index)=>{const x=20+index*250;context.fillStyle="#172528";context.fillRect(x,68,230,330);text(context,labels[index],x+12,94,12,index===3?"#d69a9a":"#eadab4","bold");if(sprite){const native=canvasOfRGBA(sprite.rgba,WIDTH,HEIGHT);context.imageSmoothingEnabled=false;context.drawImage(native,x+48,124,WIDTH*8,HEIGHT*8);}else text(context,"NO DRAW",x+75,220,16,"#d69a9a","bold");text(context,index<3?"full = remembered bytes":"identity undisclosed",x+12,382,10,"#aebeb7");});
  return canvas;
}
const disclosure=disclosureSheet();evidencePNG("curio-disclosure-and-visibility-800pct",disclosure);evidencePNG("curio-disclosure-and-visibility-800pct-grayscale",grayscale(disclosure));

const sourceReferences = {
  treasuresCuriosKeys:{path:"AssetLab/fixtures/exploration-catalogue-objects-v1/treasures-curios-keys-reference.png",sha256:sha256(fs.readFileSync(path.join(fixtureDirectory,"treasures-curios-keys-reference.png"))),productionSource:false},
  consumablesA:{path:"AssetLab/fixtures/exploration-catalogue-objects-v1/consumables-a-reference.png",sha256:sha256(fs.readFileSync(path.join(fixtureDirectory,"consumables-a-reference.png"))),productionSource:false},
  consumablesB:{path:"AssetLab/fixtures/exploration-catalogue-objects-v1/consumables-b-reference.png",sha256:sha256(fs.readFileSync(path.join(fixtureDirectory,"consumables-b-reference.png"))),productionSource:false},
  unknownCurio:{path:"AssetLab/fixtures/exploration-catalogue-objects-v1/pickup-object-unknown-16x16.png",sha256:"f33ee51acfd51eca425b8221311ff9da53bc0b8e7924348a31398dfb35fc5b80",productionSource:true,acceptedIdentity:"pickup.object.unknown"},
};
const manifest={
  schemaVersion:"exploration-catalogue-objects-v1",status:"candidate-unapproved",integrationReady:false,baselineCommit:"14d2582a2470d843f6b1a40798db29e83f440e02",
  sourceAuthority:{cataloguePath:"Sources/Content/Data/items.json",catalogueSHA256,exactStableIDs:exactCatalogueObjectIDs},sourceReferences,
  production:{map:{logicalSize:[WIDTH,HEIGHT],pivot:[PIVOT.x,PIVOT.y],tileConsumer:[16,16],filtering:"nearest-neighbour",premadeOnly:true},runtimeContents:["manifest.json","assets"],runtimeGeneration:false},
  animationContract:{classification:"static",reason:"loose physical items have no persisted active state and ambient movement would imply use, opening, burning, depletion, or activation",framesPerIdentity:1},
  visibilityContract:{full:"exact identified sprite or accepted opaque unknown parcel",remembered:"same exact static bytes",hidden:"no lookup and no draw"},
  layerContract:["terrain","southWall","stationaryLooseObject","party","selectionAndInteraction","alerts"],
  requestABI:{exactKeys:["catalogueID","identified","visibility"],catalogueIDs:exactCatalogueObjectIDs,identified:[true,false],visibility:["full","remembered","hidden"],unidentifiedAllowedOnlyFor:["curio_humming_shard","curio_bound_knot"],failClosed:["unknownCatalogueID","invalidIdentifiedState","unknownVisibility","extraField","hidden"]},
  inheritedMinimap:{key:"minimap/item",packID:"exploration-loose-items-v1",reason:"current disclosure is category-only; do not duplicate or leak catalogue subtype"},
  blockedFamilies:[{family:"travellers",reason:"named-character source pack finalArt:false"},{family:"creatures-and-apex",reason:"no accepted generic trait-renderer sprites"}],
  assetsByKey,evidence,
};
manifest.coverage={catalogueIDs:exactCatalogueObjectIDs.length,identifiedAssets:sprites.length,unknownDisclosureAssets:1,stableKeys:Object.keys(assetsByKey).length,runtimePNGs:uniqueAssets.size,treasures:objectRecords.filter(r=>r.kind==="treasure").length,curios:objectRecords.filter(r=>r.kind==="curio").length,consumables:objectRecords.filter(r=>r.kind==="consumable").length,keys:objectRecords.filter(r=>r.kind==="key").length};
manifest.runtimeAssetAggregateSHA256=sha256(Buffer.from(Object.entries(assetsByKey).sort(([a],[b])=>a.localeCompare(b)).map(([key,value])=>`${key}:${value.sha256}:${value.rgbaSHA256}`).join("\n")));
manifest.canonicalBodySHA256=sha256(Buffer.from(JSON.stringify(manifest)));
fs.writeFileSync(path.join(runtime,"manifest.json"),`${JSON.stringify(manifest,null,2)}\n`);
console.log(JSON.stringify({body:manifest.canonicalBodySHA256,manifestFile:sha256(fs.readFileSync(path.join(runtime,"manifest.json"))),stableKeys:manifest.coverage.stableKeys,runtimePNGs:manifest.coverage.runtimePNGs,runtimeAssetAggregate:manifest.runtimeAssetAggregateSHA256},null,2));
