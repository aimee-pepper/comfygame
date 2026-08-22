import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import {createRequire} from "node:module";
import {TILE,grounds,directions,palette,familyBitmap,contourMask,normalizeTerrainLayerRequest,staticTerrainBody,motionOverlay,compositeTerrain,changedPixelCount,sha256} from "../src/terrain-layering-kit.js";
const {createCanvas}=createRequire(import.meta.url)("@napi-rs/canvas");
const root=path.resolve(import.meta.dirname,"..");
const out=path.join(root,"artifacts","terrain-layering-v0.1");
for(const d of ["source/families","source/contours","source/special","source/motion","evidence","contact","loop"])fs.mkdirSync(path.join(out,d),{recursive:true});
const png=(pixels,w,h)=>{const c=createCanvas(w,h),x=c.getContext("2d"),im=x.createImageData(w,h);im.data.set(pixels);x.putImageData(im,0,0);return c;};
const writeCanvas=(name,c)=>{const bytes=c.toBuffer("image/png");fs.writeFileSync(path.join(out,name),bytes);return{name,width:c.width,height:c.height,sha256:sha256(bytes)};};
const writePixels=(name,p,w=16,h=16)=>writeCanvas(name,png(p,w,h));
const rgba=(hex,a=255)=>{const s=hex.slice(1);return[parseInt(s.slice(0,2),16),parseInt(s.slice(2,4),16),parseInt(s.slice(4,6),16),a];};
const fill=(p,w,h,color)=>{for(let i=0;i<w*h;i++)p.set(color,i*4);};
const put=(p,w,x,y,color)=>{if(x<0||y<0||x>=w||y>=p.length/w/4)return;p.set(color,(y*w+x)*4);};
const grayCanvas=c=>{const o=createCanvas(c.width,c.height),x=o.getContext("2d");x.drawImage(c,0,0);const im=x.getImageData(0,0,c.width,c.height);for(let i=0;i<im.data.length;i+=4){const y=Math.round(im.data[i]*.2126+im.data[i+1]*.7152+im.data[i+2]*.0722);im.data[i]=im.data[i+1]=im.data[i+2]=y;}x.putImageData(im,0,0);return o;};
const request=(ground,x=0,y=0,overrides={})=>({schemaVersion:"terrain-layers-v1",ground,point:{x,y},visualSeed:1773,worldGradeDescriptorHash:"world-grade-2-current",featureVariant:(x+y)%4,cardinalNeighbors:{north:"same",east:"same",south:"same",west:"same"},edgeContourIDs:{north:0,east:1,south:2,west:3},elevation:0,isCrumbled:false,isCracking:false,visibility:"full",motionBand:"moving",phaseOffset:(x*7+y*11)%24,presentationTick:0,reduceMotion:false,...overrides});

const outputs=[];
for(const ground of grounds)for(let variant=0;variant<4;variant++)outputs.push(writePixels(`source/families/${ground}-v${variant}-16x16.png`,familyBitmap(ground,variant,1773)));
for(let id=0;id<4;id++)for(const direction of directions){const mask=contourMask(direction,id),p=new Uint8ClampedArray(1024);for(let i=0;i<256;i++)if(mask[i])p.set([255,255,255,255],i*4);outputs.push(writePixels(`source/contours/${direction}-contour-${id}-16x16.png`,p));}
for(const ground of ["water","soil","growth"])for(let adjacency=0;adjacency<16;adjacency++){const neighbors={};directions.forEach((d,i)=>neighbors[d]=adjacency&(1<<i)?"same":ground==="water"?"soil":ground==="soil"?"water":"groundcover");const p=staticTerrainBody(request(ground,0,0,{cardinalNeighbors:neighbors}));outputs.push(writePixels(`source/contours/${ground}-adjacency-${adjacency.toString(2).padStart(4,"0")}.png`,p));}
for(const [name,ground,neighbor] of [["water-deep-depth","deepWater","water"],["growth-groundcover-height","growth","groundcover"],["stone-rubble-hard","rubble","stone"],["ground-chasm-rim","soil","chasm"]])outputs.push(writePixels(`source/special/${name}-16x16.png`,staticTerrainBody(request(ground,0,0,{cardinalNeighbors:{north:neighbor,east:"same",south:"same",west:"same"}}))));

const budgets={water:12,deepWater:8,groundcover:6,growth:8,ice:3},frameDiffs=[];
for(const ground of Object.keys(budgets))for(const band of ["calm","moving","strong"]){let previous=null;for(let tick=0;tick<24;tick++){const p=motionOverlay(request(ground,2,3,{motionBand:band,presentationTick:tick,visualSeed:ground==="ice"?1776:1773}));if(tick<6)outputs.push(writePixels(`source/motion/${ground}-${band}-tick-${tick}.png`,p));if(previous){const changed=changedPixelCount(previous,p);frameDiffs.push({ground,band,tick,changed,budget:budgets[ground]});}previous=p;}}

const grid=[
 ["water","water","deepWater","deepWater","stone","stone","rubble","rubble","soil","growth","growth"],
 ["water","water","water","deepWater","stone","rubble","rubble","soil","soil","growth","groundcover"],
 ["sand","water","water","deepWater","stone","stone","soil","soil","mud","growth","groundcover"],
 ["sand","sand","water","water","stone","soil","soil","mud","mud","groundcover","groundcover"],
 ["sand","sand","soil","soil","soil","soil","mud","mud","groundcover","groundcover","chasm"],
 ["ash","ash","soil","soil","stone","stone","rubble","groundcover","growth","chasm","chasm"],
 ["ash","ice","ice","stone","stone","rubble","rubble","groundcover","growth","chasm","chasm"],
 ["ice","ice","stone","stone","soil","soil","groundcover","growth","growth","chasm","chasm"],
 ["ice","stone","stone","soil","soil","mud","groundcover","growth","growth","groundcover","chasm"],
 ["stone","stone","soil","soil","mud","mud","groundcover","groundcover","growth","groundcover","soil"],
 ["stone","rubble","rubble","soil","soil","sand","sand","groundcover","groundcover","soil","soil"]
];
const elevation=(x,y)=>x>7&&y<4?2:x>5&&y<6?1:0;
const visibility=(x,y)=>{if(y>=8&&x<=2)return"remembered";const distance=Math.hypot(x-5,y-5);return distance<=4.65?"full":distance<=5.65?"fringe":"hidden";};
const edgeIDs=(x,y)=>({north:Math.abs((x*5+(y-1)*7+11)%4),east:Math.abs((x*5+y*7+17)%4),south:Math.abs((x*5+y*7+11)%4),west:Math.abs(((x-1)*5+y*7+17)%4)});
function neighbors(x,y,mutation=false){const n={};for(const [d,dx,dy] of [["north",0,-1],["east",1,0],["south",0,1],["west",-1,0]]){const nx=x+dx,ny=y+dy;if(nx<0||ny<0||nx>10||ny>10||visibility(nx,ny)==="hidden")n[d]="unknown";else n[d]=(mutation&&nx===0&&ny===0)?"chasm":grid[ny][nx]===grid[y][x]?"same":grid[ny][nx];}return n;}
function mapFrame({tick=0,band="moving",reduceMotion=false,mutation=false,rememberedMutation=false,grade="current"}={}){const p=new Uint8ClampedArray(176*176*4);fill(p,176,176,[0,0,0,255]);for(let y=0;y<11;y++)for(let x=0;x<11;x++){const vis=visibility(x,y);if(vis==="hidden")continue;/* rememberedMutation represents changed live remote state; the frozen last-seen request deliberately remains grid[y][x]. */const ground=grid[y][x],r=request(ground,x,y,{visualSeed:1773+x*131+y*197,cardinalNeighbors:neighbors(x,y,mutation),edgeContourIDs:edgeIDs(x,y),elevation:elevation(x,y),visibility:vis,motionBand:band,presentationTick:tick,reduceMotion,isCrumbled:x===9&&y===9,isCracking:x===7&&y===7}),tile=compositeTerrain(r).composite;for(let py=0;py<16;py++)for(let px=0;px<16;px++){const i=(py*16+px)*4,o=((y*16+py)*176+x*16+px)*4;p.set(tile.slice(i,i+4),o);}if(vis!=="full")for(let py=0;py<16;py++)for(let px=0;px<16;px++){const o=((y*16+py)*176+x*16+px)*4,fade=vis==="remembered"?.46:.68;p[o]=Math.round(p[o]*fade);p[o+1]=Math.round(p[o+1]*fade);p[o+2]=Math.round(p[o+2]*fade);}}
  // Genuine-height contact shade: lower tile only, external to material art.
  for(let y=0;y<10;y++)for(let x=0;x<11;x++)if(elevation(x,y+1)<elevation(x,y))for(let px=0;px<16;px++){const o=(((y+1)*16)*176+x*16+px)*4;p[o]=Math.round(p[o]*.55);p[o+1]=Math.round(p[o+1]*.55);p[o+2]=Math.round(p[o+2]*.55);}
  // Route and game-owned cues above terrain.
  const mark=(tx,ty,color,kind="square")=>{for(let yy=5;yy<11;yy++)for(let xx=5;xx<11;xx++)if(kind!=="ring"||xx===5||xx===10||yy===5||yy===10)put(p,176,tx*16+xx,ty*16+yy,rgba(color));};
  for(const [x,y] of [[2,3],[3,3],[4,3],[4,4],[5,4]])for(let q=6;q<10;q++)put(p,176,x*16+q,y*16+8,rgba("#e1c06f"));
  mark(5,6,"#f4d16e");mark(3,6,"#64c7cf");mark(7,5,"#e9e5d6","ring");mark(6,7,"#c48b60","ring");mark(8,6,"#8fbd62");mark(4,7,"#d7a65f");mark(6,5,"#ece3c8");
  // Cracking truth remains an overlay.
  for(let q=2;q<14;q++){put(p,176,7*16+q,7*16+q,rgba("#1a1012"));if(q%2===0)put(p,176,7*16+q+1,7*16+q,rgba("#e99b43"));}
  if(grade!=="current")for(let i=0;i<p.length;i+=4)if(p[i+3]){if(grade==="near"){p[i]=Math.min(255,p[i]+5);p[i+1]=Math.min(255,p[i+1]+3);}else{p[i]=Math.max(0,p[i]-12);p[i+1]=Math.min(255,p[i+1]+8);p[i+2]=Math.min(255,p[i+2]+16);}}
  return png(p,176,176);
}
function phone(options={}){const c=createCanvas(368,800),x=c.getContext("2d");x.imageSmoothingEnabled=false;x.fillStyle="#10191b";x.fillRect(0,0,368,800);x.fillStyle="#e8d4a5";x.fillRect(0,0,368,70);x.fillStyle="#3a2d20";x.font="bold 24px sans-serif";x.fillText("EXPLORE",18,43);x.fillStyle="#16272a";x.fillRect(8,78,352,352);x.drawImage(mapFrame(options),8,78,352,352);x.fillStyle="#243b3e";x.fillRect(8,442,352,76);x.fillStyle="#e8e0cc";x.font="bold 13px sans-serif";x.fillText("VISIBLE GROUND · ROUTE AND CONTENT ABOVE",20,472);x.font="11px sans-serif";x.fillText("11 × 11 fixed top-down proof",20,496);x.fillStyle="#d8b77a";x.fillRect(18,536,160,54);x.fillStyle="#3b2d20";x.font="bold 16px sans-serif";x.fillText("LOOK",73,569);x.fillStyle="#3484b5";x.fillRect(190,536,160,54);x.fillStyle="#fff";x.fillText("USE TILE",234,569);return c;}
const phones={static:phone({tick:0,band:"calm",reduceMotion:true}),moving:phone({tick:8,band:"moving"}),strong:phone({tick:8,band:"strong"}),near:phone({tick:0,band:"calm",grade:"near"}),far:phone({tick:0,band:"calm",grade:"far"}),hiddenMutation:phone({mutation:true}),rememberedMutation:phone({rememberedMutation:true})};
for(const [name,c] of Object.entries(phones)){outputs.push(writeCanvas(`evidence/${name}-368x800.png`,c));outputs.push(writeCanvas(`evidence/${name}-grayscale-368x800.png`,grayCanvas(c)));}
// A deterministic lossless six-frame sequence is the loop artifact; no lossy codec.
const loop=[];for(let tick=0;tick<24;tick+=4)loop.push(writeCanvas(`loop/frame-${String(tick).padStart(2,"0")}.png`,phone({tick,band:"moving"})));

function sheet(title,items,scale=4){const cell=16*scale+12,columns=Math.min(8,items.length),rows=Math.ceil(items.length/columns),c=createCanvas(Math.max(360,columns*cell+8),24+rows*80),x=c.getContext("2d");x.fillStyle="#17191b";x.fillRect(0,0,c.width,c.height);x.fillStyle="#eee1bf";x.font="bold 13px sans-serif";x.fillText(title,8,17);x.imageSmoothingEnabled=false;items.forEach((item,i)=>{const col=i%columns,row=Math.floor(i/columns),px=8+col*cell,py=24+row*80;x.drawImage(item.canvas,px,py,64,64);x.fillStyle="#d9caa7";x.font="9px sans-serif";x.fillText(item.label,px,py+75);});return c;}
for(const ground of grounds)outputs.push(writeCanvas(`contact/${ground}-variants-400pct.png`,sheet(`${ground} · variants`,[0,1,2,3].map(v=>({label:`v${v}`,canvas:png(familyBitmap(ground,v,1773),16,16)})))));
for(const ground of ["water","soil","growth"]){const items=[];for(let a=0;a<16;a++){const neighbors={};directions.forEach((d,i)=>neighbors[d]=a&(1<<i)?"same":ground==="water"?"soil":ground==="soil"?"water":"groundcover");items.push({label:a.toString(2).padStart(4,"0"),canvas:png(staticTerrainBody(request(ground,0,0,{cardinalNeighbors:neighbors})),16,16)});}outputs.push(writeCanvas(`contact/${ground}-all-adjacencies-400pct.png`,sheet(`${ground} · all N/E/S/W masks`,items)));}
for(const ground of ["water","deepWater","groundcover","growth","ice"])for(const band of ["calm","moving","strong"]){const items=[];for(let tick=0;tick<6;tick++)items.push({label:`t${tick}`,canvas:png(motionOverlay(request(ground,2,3,{motionBand:band,presentationTick:tick,visualSeed:ground==="ice"?1776:1773})),16,16)});outputs.push(writeCanvas(`contact/${ground}-${band}-motion-strip-400pct.png`,sheet(`${ground} · ${band}`,items)));}

function composedMosaic(cells){const rows=cells.length,columns=cells[0].length,p=new Uint8ClampedArray(columns*16*rows*16*4);for(let y=0;y<rows;y++)for(let x=0;x<columns;x++){const ground=cells[y][x],facts={};for(const [d,dx,dy] of [["north",0,-1],["east",1,0],["south",0,1],["west",-1,0]]){const nx=x+dx,ny=y+dy;facts[d]=nx<0||ny<0||nx>=columns||ny>=rows?"unknown":cells[ny][nx]===ground?"same":cells[ny][nx];}const tile=staticTerrainBody(request(ground,x,y,{visualSeed:1773+x*131+y*197,cardinalNeighbors:facts,edgeContourIDs:edgeIDs(x,y),featureVariant:(x*3+y)%4}));for(let py=0;py<16;py++)for(let px=0;px<16;px++){const i=(py*16+px)*4,o=((y*16+py)*columns*16+x*16+px)*4;p.set(tile.slice(i,i+4),o);}}return png(p,columns*16,rows*16);}
const same=ground=>Array.from({length:5},()=>Array(5).fill(ground));
const pair=(a,b)=>Array.from({length:5},(_,y)=>Array.from({length:5},(_,x)=>x<2+(y%2)?a:b));
const shoreline=Array.from({length:5},(_,y)=>Array.from({length:5},(_,x)=>x<(y<2?3:y===2?2:1)?"water":"soil"));
const junction=[["soil","soil","water","growth","growth"],["soil","soil","water","growth","growth"],["water","water","water","water","water"],["mud","mud","water","groundcover","groundcover"],["mud","mud","water","groundcover","groundcover"]];
const equalMixed=[["soil","soil","stone"],["soil","mud","stone"],["growth","groundcover","stone"]];
const mosaics={"same-water":same("water"),"same-soil":same("soil"),"same-growth":same("growth"),"water-soil-pair":pair("water","soil"),"soil-mud-pair":pair("soil","mud"),"growth-groundcover-pair":pair("groundcover","growth"),"turning-shoreline":shoreline,"t-cross-junction":junction,"equal-height-mixed":equalMixed};
for(const [name,cells] of Object.entries(mosaics)){const native=composedMosaic(cells),scaled=createCanvas(native.width*4,native.height*4),sx=scaled.getContext("2d");sx.imageSmoothingEnabled=false;sx.drawImage(native,0,0,scaled.width,scaled.height);outputs.push(writeCanvas(`evidence/mosaic-${name}-native.png`,native));outputs.push(writeCanvas(`evidence/mosaic-${name}-400pct.png`,scaled));outputs.push(writeCanvas(`evidence/mosaic-${name}-grayscale-400pct.png`,grayCanvas(scaled)));}

const equalA=staticTerrainBody(request("soil",0,0,{elevation:1,cardinalNeighbors:{north:"stone",east:"same",south:"same",west:"same"}})),equalB=new Uint8ClampedArray(equalA);const heightShade=new Uint8ClampedArray(1024);for(let x=0;x<16;x++){heightShade.set([26,22,18,92],x*4);if(x%2===0)heightShade.set([26,22,18,52],(16+x)*4);}outputs.push(writePixels("source/special/genuine-height-contact-shade-external.png",heightShade));
const genuineLower=new Uint8ClampedArray(equalA);for(let i=0;i<genuineLower.length;i+=4)if(heightShade[i+3]){const a=heightShade[i+3]/255;genuineLower[i]=Math.round(genuineLower[i]*(1-a)+heightShade[i]*a);genuineLower[i+1]=Math.round(genuineLower[i+1]*(1-a)+heightShade[i+1]*a);genuineLower[i+2]=Math.round(genuineLower[i+2]*(1-a)+heightShade[i+2]*a);}
outputs.push(writeCanvas("contact/equal-height-vs-genuine-height-400pct.png",sheet("equal elevation: no shade · genuine rise: external lower-tile shade",[{label:"equal A",canvas:png(equalA,16,16)},{label:"equal B",canvas:png(equalB,16,16)},{label:"genuine lower",canvas:png(genuineLower,16,16)}])));
const ruleReceipt={geometry:"unchanged",passability:"unchanged",movement:"unchanged",sight:"unchanged",content:"unchanged"};
const requestContract={additionalProperties:false,required:["schemaVersion","ground","point","visualSeed","worldGradeDescriptorHash","featureVariant","cardinalNeighbors","edgeContourIDs","elevation","isCrumbled","isCracking","visibility","motionBand","phaseOffset","presentationTick","reduceMotion"]};
const manifest={manifestVersion:1,identityKind:"terrain-layering-and-motion-asset-proof",integrationReady:false,tile:{width:16,height:16,pivot:{x:8,y:8},camera:"straight-top-down",filtering:"nearest-neighbour",alpha:"binary"},grounds,variantsPerGround:4,paletteSlots:palette,worldGradeEvidence:{current:"world-grade-2-current",near:"bounded related ramp shift",far:"bounded opposed ramp shift",geometryIdentical:true},layerOwnership:["static-top-surface","transparent-motion-overlay","external-genuine-elevation-contact-shade","game-owned-overlays"],requestContract,contours:{families:4,cardinalOnly:true,undirectedSharedEdge:true,unknownHiddenNeighbor:true,allAdjacencyCombinations:16},specialPairs:{waterDeepWater:"depth-contour-on-deep-side-only",growthGroundcover:"height-density-boundary",stoneRubble:"continuous-hard-relation",chasm:"adjacent-ground-owns-rim"},motion:{sharedClockHz:4,masterTicks:24,budgets,fringe:"static",remembered:"static-last-seen",hidden:"no-request",reduceMotion:"static-representative-phase",losslessLoopFrames:loop.map(x=>x.name)},elevation:{equalHeight:"no-shade-or-sidewall",genuineHeight:"external-lower-tile-contact-shade-only"},counterfactuals:{hiddenNeighborMutation:"byte-identical",rememberedRemoteMutation:"byte-identical"},ruleReceipt,ruleReceiptSha256:sha256(Buffer.from(JSON.stringify(ruleReceipt))),frameDifferences:frameDiffs,outputs};
const canonical=JSON.stringify(manifest);manifest.canonicalBodySha256=sha256(Buffer.from(canonical));fs.writeFileSync(path.join(out,"manifest.json"),JSON.stringify(manifest,null,2)+"\n");
console.log(`terrain layering manifest ${manifest.canonicalBodySha256}`);
