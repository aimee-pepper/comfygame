import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import {createRequire} from "node:module";
import {
  committedHarvestGroup, miningFeedbackContract, motionContract, motionSample, proofFixtures,
} from "../src/resource-mining-feedback-v1.js";

const {createCanvas, loadImage, GlobalFonts} = createRequire(import.meta.url)("@napi-rs/canvas");
const root = path.resolve(import.meta.dirname, "..");
const outputRoot = path.join(root, "artifacts/resource-mining-feedback-v1");
const evidenceRoot = path.join(outputRoot, "evidence");
const sourcePackRoot = path.join(root, "integration/resource-sprites-v1");
const sourceManifestPath = path.join(sourcePackRoot, "manifest.json");
const terrainPath = path.join(root, "artifacts/dynamic-terrain-style-v0.2/evidence/phone-opposed-cool-368x800.png");
const hashBytes = bytes => crypto.createHash("sha256").update(bytes).digest("hex");
const hashFile = file => hashBytes(fs.readFileSync(file));

fs.rmSync(outputRoot, {recursive:true, force:true});
fs.mkdirSync(evidenceRoot, {recursive:true});
GlobalFonts.registerFromPath(path.join(root, "fonts/Jersey10-Regular.ttf"), "Jersey 10");
GlobalFonts.registerFromPath(path.join(root, "fonts/Tiny5-Regular.ttf"), "Tiny5");

const sourceManifest = JSON.parse(fs.readFileSync(sourceManifestPath, "utf8"));
const sourceFieldAssets = Object.fromEntries(sourceManifest.resources.map(resource => {
  const field = resource.profiles.field, file = path.join(sourcePackRoot, field.path);
  if (hashFile(file) !== field.fileSHA256) throw new Error(`field-source-drift:${resource.id}`);
  return [resource.id, {
    name: resource.name, path: `integration/resource-sprites-v1/${field.path}`,
    width: field.width, height: field.height, pngSHA256: field.fileSHA256,
    rgbaSHA256: field.decodedRGBASHA256,
  }];
}));
const exactIDs = new Set(Object.keys(sourceFieldAssets));
const icons = new Map(await Promise.all(Object.entries(sourceFieldAssets).map(async ([id, row]) => [id, await loadImage(path.join(root, row.path))])));
const terrain = await loadImage(terrainPath);

const palette = {deep:"#0b1415", top:"#111d1e", panel:"#172726", line:"#526761", ink:"#f4ecd7", muted:"#b7c4be", gold:"#e4c46e", teal:"#6db0a0", danger:"#db7767"};
const names = Object.fromEntries(Object.entries(sourceFieldAssets).map(([id,row])=>[id,row.name]));
function rect(ctx, color, x, y, width, height, alpha=1) {ctx.globalAlpha=alpha;ctx.fillStyle=color;ctx.fillRect(x,y,width,height);ctx.globalAlpha=1;}
function stroke(ctx, color, x, y, width, height, line=1) {ctx.strokeStyle=color;ctx.lineWidth=line;ctx.strokeRect(x+line/2,y+line/2,width-line,height-line);}
function text(ctx, value, x, y, font="15px Tiny5", color=palette.ink, align="left") {ctx.font=font;ctx.fillStyle=color;ctx.textBaseline="top";ctx.textAlign=align;ctx.fillText(value,x,y);ctx.textAlign="left";}
function countEntries(fixture) {return Object.entries(fixture.counts).filter(([id])=>icons.has(id));}
function toolbarDestination(index) {return {x:18+index*82, y:537};}

function drawPhone({fixtureKey, progress=0, presentation="active"}) {
  const fixture = proofFixtures[fixtureKey], canvas = createCanvas(368,800), ctx = canvas.getContext("2d");
  ctx.imageSmoothingEnabled=false; rect(ctx,palette.deep,0,0,368,800);
  rect(ctx,palette.top,0,0,368,64); text(ctx,"Explore",14,13,"36px Jersey 10"); text(ctx,"Stability 73%",354,23,"15px Tiny5",palette.ink,"right");
  ctx.drawImage(terrain,8,72,352,352,0,64,368,368);
  rect(ctx,"#081010",0,64,368,368,.1); stroke(ctx,"#263c38",0,64,368,368,2);
  stroke(ctx,"#f0d477",168,282,32,32,2); rect(ctx,"#091312",154,318,60,23,.9); stroke(ctx,"#71867e",154,318,60,23,1); text(ctx,"Use Tile",184,323,"15px Tiny5",palette.ink,"center");
  rect(ctx,palette.panel,0,432,368,78,.96); stroke(ctx,palette.line,0,432,368,78,1); text(ctx,"AT THIS PLACE",13,440,"15px Tiny5",palette.teal); text(ctx,fixtureKey==="M02"?"Timber stand":"Mineral seam",13,463,"25px Jersey 10");
  const sourceNarration = fixture.batch?.orderedNarrations?.[0] ?? "";
  if(sourceNarration) text(ctx,sourceNarration,354,476,"13px system-ui",presentation==="refused"?palette.danger:palette.muted,"right");
  rect(ctx,"#0e1819",0,510,368,54); stroke(ctx,"#40504c",0,510,368,54,1);
  const entries = countEntries(fixture);
  entries.forEach(([id,amount], index)=>{
    const destination=toolbarDestination(index), icon=icons.get(id);ctx.drawImage(icon,destination.x-4,destination.y-4,8,8);text(ctx,String(amount),destination.x+9,destination.y-8,"14px ui-monospace",palette.ink);
  });
  rect(ctx,"#13201f",0,564,368,106); for(const [label,x,active] of [["Look",16,false],["Use Tile",138,true],["Field Kit",260,false]]){rect(ctx,active?"#36584c":"#172523",x,594,92,44);stroke(ctx,"#60736d",x,594,92,44,1);text(ctx,label,x+46,607,"16px Tiny5",palette.ink,"center")}
  rect(ctx,"#0b1314",0,670,368,130); text(ctx,"Health 12 / 12",14,690,"15px Tiny5",palette.muted); text(ctx,fixture.batch?`turn ${fixture.batch.turnAfter}`:"turn 13",354,690,"15px Tiny5",palette.muted,"right");

  const group = fixture.batch ? committedHarvestGroup(fixture.batch, exactIDs) : null;
  if (presentation==="active" && group?.subjects.length && progress<1) {
    group.subjects.forEach((subject,index)=>{
      const targetIndex=entries.findIndex(([id])=>id===subject.resourceID); if(targetIndex<0)return;
      const sample=motionSample({source:{x:184,y:298},destination:toolbarDestination(targetIndex),groupProgress:progress,subjectIndex:index,subjectCount:group.subjects.length});
      const icon=icons.get(subject.resourceID), side=8*sample.scale;ctx.globalAlpha=sample.opacity;ctx.drawImage(icon,Math.round(sample.x-side/2),Math.round(sample.y-side/2),side,side);ctx.globalAlpha=1;
      const label=`×${subject.amount}`, labelWidth=ctx.measureText(label).width+10;rect(ctx,"#091110",Math.round(sample.x+9),Math.round(sample.y-10),labelWidth,23,.94);stroke(ctx,"#ccb666",Math.round(sample.x+9),Math.round(sample.y-10),labelWidth,23,1);text(ctx,label,Math.round(sample.x+14),Math.round(sample.y-7),"16px Tiny5","#fff6d6");
    });
  }
  if (presentation==="active" && group?.subjects.length && progress>=1) {
    group.subjects.forEach(subject=>{const targetIndex=entries.findIndex(([id])=>id===subject.resourceID);if(targetIndex>=0){const p=toolbarDestination(targetIndex);stroke(ctx,"#f4d36c",p.x-7,p.y-7,14,14,1)}});
  }
  text(ctx,`${fixtureKey} · ${fixture.label}`,13,761,"15px Tiny5",palette.gold);
  return canvas;
}

const evidenceSpecs = [
  ["m01-start-368x800.png",{fixtureKey:"M01",progress:0}],
  ["m01-mid-368x800.png",{fixtureKey:"M01",progress:.52}],
  ["m01-end-368x800.png",{fixtureKey:"M01",progress:1}],
  ["m02-multi-output-368x800.png",{fixtureKey:"M02",progress:.5}],
  ["m05-refusal-368x800.png",{fixtureKey:"M05",presentation:"refused"}],
  ["m08-interruption-368x800.png",{fixtureKey:"M08",presentation:"interrupted"}],
  ["m09-relaunch-368x800.png",{fixtureKey:"M09",presentation:"relaunch"}],
  ["m10-missing-identity-368x800.png",{fixtureKey:"M10",progress:.5,presentation:"missing"}],
];
const outputs=[]; const rendered=[];
for(const [filename,spec] of evidenceSpecs){const canvas=drawPhone(spec),bytes=canvas.toBuffer("image/png");fs.writeFileSync(path.join(evidenceRoot,filename),bytes);outputs.push({path:`evidence/${filename}`,width:368,height:800,sha256:hashBytes(bytes)});rendered.push([filename,canvas]);}

const sheet=createCanvas(1200,2530),s=sheet.getContext("2d");s.imageSmoothingEnabled=false;rect(s,"#091110",0,0,sheet.width,sheet.height);text(s,"RESOURCE MINING FEEDBACK · ORDINARY 368×800 · CANDIDATE",24,18,"34px Jersey 10");text(s,"Exact accepted 8px toolbar identities · counts committed before frame one · no runtime art generation",24,58,"16px Tiny5",palette.muted);
rendered.forEach(([filename,phone],index)=>{const col=index%3,row=Math.floor(index/3),x=24+col*392,y=96+row*816;s.drawImage(phone,x,y,368,800);text(s,filename.replace("-368x800.png",""),x,y+775,"15px Tiny5",palette.gold)});
const contactBytes=sheet.toBuffer("image/png"),contactPath=path.join(outputRoot,"review-contact-sheet.png");fs.writeFileSync(contactPath,contactBytes);

const coverage = {
  M01:"one primary subject with existing final count plus exact amount",
  M02:"primary then secondary identities in one ordered transaction",
  M03:"repeated exact ResourceID coalesces summed positive amount at first position",
  M04:"depleted final pull produces only its committed reward subject",
  M05:"nothing/spent/refused/stale/busy produces zero subjects",
  M06:"unique accepted batches remain FIFO; duplicate batchID never replays",
  M07:"toolbar count identical at first and final presentation frames",
  M08:"dismiss/expiry advances one committed FIFO group; World-owner exits clear current + queue; neither mutates gameplay or replays",
  M09:"cold relaunch retains committed count and shows no animation",
  M10:"missing exact field identity omits subject without substitute art",
};
const manifest = {
  schemaVersion:"resource-mining-feedback-visual-v1", status:"candidate-not-approved", integrationReady:false,
  sourceAuthority:{revision:"fb762e4682f3c53d41ca12fd64ebb8472ee8d90e",batch:"WorldFieldEventBatchV1",rules:"WorldRules.harvest",action:"GameStore.harvest/finishTurn",consumer:"ResourceFieldMarkerIdentity"},
  sourceIdentityPack:{path:"integration/resource-sprites-v1/manifest.json",sha256:hashFile(sourceManifestPath),packID:sourceManifest.packID,catalogueSHA256:sourceManifest.catalogueSHA256,fieldAssets:sourceFieldAssets},
  acceptedTerrainEvidence:{path:path.relative(root,terrainPath),sha256:hashFile(terrainPath),use:"proof-map-backdrop-only"},
  miningFeedbackContract,motionContract,coverage,
  visual:{ordinaryPhone:[368,800],particleIdentity:"exact accepted field PNG",flightScale:[2,1],amountLabel:"one exact total per distinct resource",multiOutput:"130ms ordered stagger inside one group",largeQuantity:"one particle plus label; never per-unit particles",toolbar:"layout/count/order unchanged"},
  outputs,contactSheet:{path:"review-contact-sheet.png",width:sheet.width,height:sheet.height,sha256:hashBytes(contactBytes)},
  forbidden:["runtime-image-generation","resource-redraw","substitute-resource-art","gameplay-mutation","count-increment","invented-mining-state","native-implementation"],
};
manifest.canonicalBodySHA256=hashBytes(Buffer.from(JSON.stringify(manifest)));
fs.writeFileSync(path.join(outputRoot,"manifest.json"),JSON.stringify(manifest,null,2)+"\n");
console.log(`resource mining feedback ${manifest.canonicalBodySHA256} · ${outputs.length} evidence PNGs · ${Object.keys(sourceFieldAssets).length} exact field identities`);
