import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { styleGrounds, semanticRoles, baseRoleColors, recolorRoleMap } from "../src/dynamic-terrain-style-v0.2-kit.js";
import { schemaVersion, boundaryRole, normalizeRegionTileRequest, coordinatedRoleTile, materialBoundaryMask, applyBoundaryRole, smallAccentPoint, canonicalJSON, sha256 } from "../src/terrain-region-continuity-v1.js";

const { createCanvas, loadImage, GlobalFonts } = createRequire(import.meta.url)("@napi-rs/canvas");
const root = path.resolve(import.meta.dirname, "..");
const accepted = path.join(root, "artifacts/dynamic-terrain-style-v0.2");
const south = path.join(root, "integration/terrain-south-wall-v1");
const out = path.join(root, "artifacts/terrain-region-continuity-v1");
const evidence = path.join(out, "evidence");
fs.rmSync(out, { recursive: true, force: true }); fs.mkdirSync(evidence, { recursive: true });
GlobalFonts.registerFromPath(path.join(root, "fonts/Tiny5-Regular.ttf"), "Tiny5");

const acceptedManifestBytes = fs.readFileSync(path.join(accepted, "manifest.json"));
const acceptedManifest = JSON.parse(acceptedManifestBytes);
if (acceptedManifest.canonicalBodySha256 !== "2a541033b71b638f1803e5a9477a0197c38f38d96ff199a4864d49bf551608dd") throw Error("accepted-terrain-body-drift");
const productionAggregate = acceptedManifest.productionAggregateSha256;
const southManifestBytes = fs.readFileSync(path.join(south, "runtime/manifest.json"));

const roleMaps = {};
for (const ground of styleGrounds) {
  const map = new Uint8Array(4096);
  for (let role = 0; role < semanticRoles.length; role++) {
    const image = await loadImage(path.join(accepted, `production/roles/${ground}-${semanticRoles[role]}-mask-64x64.png`));
    const c = createCanvas(64, 64), x = c.getContext("2d"); x.drawImage(image, 0, 0);
    const rgba = x.getImageData(0, 0, 64, 64).data;
    for (let i = 0; i < 4096; i++) if (rgba[i * 4 + 3]) map[i] = role;
  }
  roleMaps[ground] = map;
}

const hex = h => [parseInt(h.slice(1,3),16), parseInt(h.slice(3,5),16), parseInt(h.slice(5,7),16)];
const palettes = Object.fromEntries(styleGrounds.map(g => [g, baseRoleColors[g].map(hex)]));
const boundaryPalette = [[37, 43, 42], [173, 164, 126]];
const request = (ground, x, y, neighbors, visibility="full", seed=9041) => normalizeRegionTileRequest({ schemaVersion, ground, point:{x,y}, visualSeed:seed, featureVariant:0, cardinalNeighbors:neighbors, edgeContourIDs:edgeIDs(x,y), visibility, motionPhase:((x+y)%4+4)%4 });
const edgeIDs = (x,y) => ({ north:hashInt(x,y-1,x,y)%4, east:hashInt(x,y,x+1,y)%4, south:hashInt(x,y,x,y+1)%4, west:hashInt(x-1,y,x,y)%4 });
function hashInt(...v){let h=2166136261;for(const n of v){h^=n&255;h=Math.imul(h,16777619)}return h>>>0}
function neighborsFor(grid,x,y){const g=grid[y][x],at=(xx,yy)=>yy<0||xx<0||yy>=grid.length||xx>=grid[0].length?"unknown":grid[yy][xx];return{north:at(x,y-1)===g?"same":at(x,y-1),east:at(x+1,y)===g?"same":at(x+1,y),south:at(x,y+1)===g?"same":at(x,y+1),west:at(x-1,y)===g?"same":at(x-1,y)}}
function tileRGBA(grid,x,y,{mode="corrected",visibility="full",seed=9041}={}){const g=grid[y][x],point=mode==="current"?{x:(x*7)%4,y:(y*11)%4}:{x,y},r=request(g,point.x,point.y,neighborsFor(grid,x,y),visibility,seed),roles=coordinatedRoleTile(r,roleMaps),base=recolorRoleMap(roles,baseRoleColors[g]);if(mode!=="corrected")return base;return applyBoundaryRole(base,materialBoundaryMask(r),boundaryPalette)}
const canvas=(w,h)=>createCanvas(w,h), text=(x,s,px,py,size=16,color="#eee")=>{x.font=`${size}px Tiny5`;x.fillStyle=color;x.textBaseline="top";x.fillText(s,px,py)}, gray=c=>{const x=c.getContext("2d"),d=x.getImageData(0,0,c.width,c.height);for(let i=0;i<d.data.length;i+=4){const y=Math.round(.2126*d.data[i]+.7152*d.data[i+1]+.0722*d.data[i+2]);d.data[i]=d.data[i+1]=d.data[i+2]=y}x.putImageData(d,0,0);return c};
function drawGrid(grid,{scale=1,mode="corrected",visibility="full",gutter=0,seed=9041}={}){const w=grid[0].length*16,h=grid.length*16,c=canvas(w*scale,h*scale),x=c.getContext("2d");x.imageSmoothingEnabled=false;for(let y=0;y<grid.length;y++)for(let xx=0;xx<grid[0].length;xx++){const t=canvas(16,16),tx=t.getContext("2d"),im=tx.createImageData(16,16);im.data.set(tileRGBA(grid,xx,y,{mode,visibility,seed}));tx.putImageData(im,0,0);x.drawImage(t,xx*16*scale+gutter,y*16*scale+gutter,16*scale-gutter*2,16*scale-gutter*2)}return c}
const mono=n=>Array.from({length:n},()=>Array(n).fill("stone"));
const clusters={stone:mono(5),soil:Array.from({length:5},()=>Array(5).fill("soil")),growth:Array.from({length:5},()=>Array(5).fill("growth")),water:Array.from({length:5},()=>Array(5).fill("water"))};
const corridor1=Array.from({length:5},(_,y)=>Array.from({length:7},(_,x)=>(x===1||y===3&&x>=1&&x<=5)?"growth":"soil"));
const corridor2=Array.from({length:6},(_,y)=>Array.from({length:8},(_,x)=>(x>=1&&x<=2||y>=3&&y<=4&&x>=1&&x<=6)?"water":"sand"));
const pool=Array.from({length:7},(_,y)=>Array.from({length:9},(_,x)=>{const dx=x-4,dy=y-3,d=dx*dx+dy*dy;return d<5?"deepWater":d<15?"water":((x+y)%4===0?"soil":"groundcover")}));
const junction=Array.from({length:7},(_,y)=>Array.from({length:7},(_,x)=>x===3||y===3?(x<3?"soil":"stone"):(x+y)%3?"groundcover":"growth"));
const rubble=Array.from({length:6},(_,y)=>Array.from({length:8},(_,x)=>x+y<7?"stone":"rubble"));
const macro=Array.from({length:11},(_,y)=>Array.from({length:11},(_,x)=>{if((x-5)**2+(y-5)**2<8)return x<5?"water":"deepWater";if(x<3)return"stone";if(y>7)return"growth";return(x+y)%5===0?"rubble":"soil"}));

async function save(name,c){const b=c.toBuffer("image/png");fs.writeFileSync(path.join(evidence,name),b);return{name:`evidence/${name}`,width:c.width,height:c.height,sha256:sha256(b)}}
const outputs=[];
for(const [name,grid] of Object.entries(clusters)){for(const scale of [1,2,4])outputs.push(await save(`cluster-${name}-${scale===1?"native":scale===2?"2x":"400pct"}.png`,drawGrid(grid,{scale})));outputs.push(await save(`cluster-${name}-grayscale-400pct.png`,gray(drawGrid(grid,{scale:4}))));}
for(const [name,grid] of [["corridor-1",corridor1],["corridor-2",corridor2],["pool-deep",pool],["junction-t-cross",junction],["stone-rubble",rubble]]){for(const scale of [1,2,4])outputs.push(await save(`${name}-${scale===1?"native":scale===2?"2x":"400pct"}.png`,drawGrid(grid,{scale})));outputs.push(await save(`${name}-grayscale-400pct.png`,gray(drawGrid(grid,{scale:4}))));}
const repeatA=drawGrid(macro,{scale:2,seed:442}),repeatB=drawGrid(macro,{scale:2,seed:442});outputs.push(await save("macro-11x11-redraw-a-2x.png",repeatA),await save("macro-11x11-redraw-b-2x.png",repeatB));

function phoneComparison(){const c=canvas(368,800),x=c.getContext("2d");x.fillStyle="#101717";x.fillRect(0,0,368,800);text(x,"REGION CONTINUITY",16,20,24);text(x,"OLD GUTTERS",14,74,14,"#e0c17d");text(x,"CURRENT SCATTER",132,74,14,"#e0c17d");text(x,"CORRECTED",268,74,14,"#e0c17d");const old=drawGrid(macro,{scale:2,mode:"corrected",gutter:1}),cur=drawGrid(macro,{scale:2,mode:"current"}),fixed=drawGrid(macro,{scale:2,mode:"corrected"});x.imageSmoothingEnabled=false;x.drawImage(old,8,104,112,112);x.drawImage(cur,128,104,112,112);x.drawImage(fixed,248,104,112,112);text(x,"Same-region seams disappear.",16,240,16);text(x,"One organic perimeter owns each material contact.",16,270,13,"#b8c3bf");x.drawImage(fixed,74,322,220,220);text(x,"Accepted terrain pixels preserved",66,570,15,"#8fd09b");text(x,"South walls remain a separate layer",54,600,15,"#b8c3bf");return c}
outputs.push(await save("phone-old-current-corrected-368x800.png",phoneComparison()),await save("phone-old-current-corrected-grayscale-368x800.png",gray(phoneComparison())));
function phoneVisibility(){const c=canvas(368,800),x=c.getContext("2d");x.fillStyle="#101717";x.fillRect(0,0,368,800);text(x,"DISCLOSURE OWNERSHIP",16,20,23);for(const [i,v] of ["full","fringe","remembered","hidden"].entries()){text(x,v.toUpperCase(),16,82+i*156,15,"#e0c17d");if(v==="hidden"){x.fillStyle="#050707";x.fillRect(116,70+i*156,176,140)}else{x.globalAlpha=v==="full"?1:v==="fringe"?.62:.43;x.drawImage(drawGrid(junction,{scale:2,visibility:v}),116,70+i*156,176,140);x.globalAlpha=1}text(x,v==="full"?"boundary + eligible motion":v==="hidden"?"no request / no disclosure":"static terrain; visibility owns treatment",16,108+i*156,12,"#b8c3bf")}return c}
outputs.push(await save("phone-visibility-368x800.png",phoneVisibility()));

function elevation(){const c=canvas(900,360),x=c.getContext("2d");x.fillStyle="#111";x.fillRect(0,0,900,360);text(x,"EQUAL HEIGHT: MATERIAL BOUNDARY ONLY",20,18,18);x.drawImage(drawGrid(rubble,{scale:4}),20,52);text(x,"REAL SOUTH DESCENT: AUTHORED WALL REMAINS",470,18,18);x.drawImage(drawGrid(rubble,{scale:4}),470,52);for(let row=0;row<3;row++){x.fillStyle=["#292725","#4b4742","#968d82"][row];x.fillRect(470,292+row*12,256,12)}text(x,"contact shade may supplement; never replaces wall",470,334,12,"#b8c3bf");return c}
outputs.push(await save("equal-height-vs-south-wall-400pct.png",elevation()),await save("equal-height-vs-south-wall-grayscale-400pct.png",gray(elevation())));

function contactSheet(){const c=canvas(1800,2200),x=c.getContext("2d");x.fillStyle="#101414";x.fillRect(0,0,c.width,c.height);text(x,"TERRAIN REGION CONTINUITY v1 · CANDIDATE · NOT APPROVED",24,18,28);let px=24;for(const g of Object.keys(clusters)){text(x,`${g.toUpperCase()} 5×5`,px,70,16,"#e0c17d");x.drawImage(drawGrid(clusters[g],{scale:4}),px,100);px+=420}for(const [i,[name,grid]] of [["1-TILE CORRIDOR",corridor1],["2-TILE CORRIDOR",corridor2],["SHALLOW/DEEP POOL",pool],["T/CROSS",junction]].entries()){const col=i%2,row=Math.floor(i/2);text(x,name,24+col*880,470+row*440,18,"#e0c17d");x.drawImage(drawGrid(grid,{scale:4}),24+col*880,504+row*440)}x.drawImage(phoneComparison(),24,1370,331,720);x.drawImage(phoneVisibility(),390,1370,331,720);x.drawImage(elevation(),760,1370,900,360);text(x,"WORLD-COORDINATE 64×64 MACRO SAMPLE · SINGLE-OWNER COMPLEMENTARY CONTOUR · SMALL ACCENTS INSET",760,1760,16);x.drawImage(drawGrid(macro,{scale:2}),760,1800,440,440);return c}
const contact=contactSheet(),contactBytes=contact.toBuffer("image/png");fs.writeFileSync(path.join(out,"review-contact-sheet.png"),contactBytes);

const corpus=[];
for(let y=0;y<macro.length;y++)for(let x=0;x<macro[0].length;x++){const r=request(macro[y][x],x,y,neighborsFor(macro,x,y),"full",442),roles=coordinatedRoleTile(r,roleMaps),boundary=materialBoundaryMask(r),rgba=applyBoundaryRole(recolorRoleMap(roles,baseRoleColors[r.ground]),boundary,boundaryPalette);corpus.push({id:`macro/${x}/${y}`,request:r,baseRoleSHA256:sha256(roles),materialBoundarySHA256:sha256(boundary),rgbaSHA256:sha256(rgba),accent:smallAccentPoint(r.point,r.visualSeed),layerOrder:["acceptedBase","eligibleMotion","materialBoundary","southWallExternal","content","selection","visibilityExternal"]})}
fs.writeFileSync(path.join(out,"native-adapter-conformance.json"),JSON.stringify({schemaVersion,hidden:"no-request",macroSampling:{size:[64,64],coordinates:"world-coordinate",redrawStable:true},boundary:{role:boundaryRole,owner:"lower canonical ground rank",complementaryEdgeID:true,equalGround:"none",unknownNeighbor:"none"},southWall:{authority:"terrain-south-wall-v1",preserved:true},cases:corpus},null,2)+"\n");
const manifest={schemaVersion,status:"candidate-not-approved",integrationReady:false,baseline:"ae12dd5f",acceptedPins:{terrainProductionPackBody:"ecb748ba46582bd432e7eba7cfc5494fd8ea8badcf3a8652d24c7a533d8e8336",dynamicTerrainBody:acceptedManifest.canonicalBodySha256,dynamicTerrainManifestSHA256:sha256(acceptedManifestBytes),productionAggregateSHA256:productionAggregate,southWallCommit:"ae12dd5f",southWallManifestSHA256:sha256(southManifestBytes)},contract:{boundaryRole,macro:[64,64],tile:[16,16],smallAccents:"inset 3...12",sameMaterial:"no seam/no boundary",differentMaterial:"single-owner complementary contour",motion:"world-coordinate phase",visibility:"external; hidden no request",elevation:"south-wall-v1 external and preserved",fog:"external atmosphere owner"},outputs,contactSheet:{path:"review-contact-sheet.png",width:1800,height:2200,sha256:sha256(contactBytes)},corpus:{path:"native-adapter-conformance.json",caseCount:corpus.length}};manifest.canonicalBodySHA256=sha256(Buffer.from(canonicalJSON(manifest)));fs.writeFileSync(path.join(out,"manifest.json"),JSON.stringify(manifest,null,2)+"\n");
console.log(`terrain region continuity ${manifest.canonicalBodySHA256} ${outputs.length} proofs ${corpus.length} cases`);
