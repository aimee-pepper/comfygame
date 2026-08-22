import crypto from "node:crypto";

export const TILE = 16;
export const grounds = Object.freeze(["stone","soil","sand","ice","ash","water","deepWater","rubble","mud","growth","groundcover","chasm"]);
export const directions = Object.freeze(["north","east","south","west"]);
export const visibilities = Object.freeze(["full","fringe","remembered"]);
export const motionBands = Object.freeze(["calm","moving","strong"]);
export const palette = Object.freeze({
  stone:["#353b3c","#596263","#87908d","#b0b6ae"], soil:["#392b20","#60452e","#89633e","#ae8759"],
  sand:["#6f5832","#a4854a","#ceb16d","#e4ce8e"], ice:["#587887","#83a9b5","#b8d5d8","#e5f0e9"],
  ash:["#25262a","#48484c","#747176","#aaa4a2"], water:["#15384a","#245d70","#3f8490","#78b2b4"],
  deepWater:["#071a2a","#102f47","#20536b","#437d8c"], rubble:["#302e2c","#544f49","#817970","#aaa095"],
  mud:["#281d17","#493326","#71523b","#947257"], growth:["#16301d","#2c522d","#50763e","#7f9954"],
  groundcover:["#2c4226","#4e6935","#76904b","#a0ad67"], chasm:["#030409","#0b0d14","#202531","#484d5a"]
});
const hex = value => { const h=value.slice(1); return [parseInt(h.slice(0,2),16),parseInt(h.slice(2,4),16),parseInt(h.slice(4,6),16),255]; };
const hash32=(...parts)=>{let h=2166136261;for(const c of parts.join("|") ){h^=c.charCodeAt(0);h=Math.imul(h,16777619);}return h>>>0;};
export const sha256=bytes=>crypto.createHash("sha256").update(bytes).digest("hex");
export const blank=()=>new Uint8ClampedArray(TILE*TILE*4);
const put=(pixels,x,y,color)=>{if(x<0||x>=16||y<0||y>=16)return;const i=(y*16+x)*4;pixels.set(Array.isArray(color)?color:hex(color),i);};
const read=(pixels,x,y)=>pixels.slice((y*16+x)*4,(y*16+x)*4+4);
const fill=(pixels,color)=>{const c=hex(color);for(let y=0;y<16;y++)for(let x=0;x<16;x++)put(pixels,x,y,c);};

const texture = (pixels,ground,variant,seed) => {
  const p=palette[ground], h=hash32(ground,variant,seed), spots=ground==="chasm"?7:ground==="rubble"?18:ground==="growth"?25:ground==="groundcover"?18:13;
  for(let i=0;i<spots;i++){const q=hash32(h,i),x=q&15,y=(q>>>5)&15,c=p[(q>>>10)%4];put(pixels,x,y,c);if(["water","deepWater","sand","mud"].includes(ground)&&i%4===0)put(pixels,Math.min(15,x+1),y,c);}
  if(ground==="stone") for(let i=1;i<15;i+=5){put(pixels,i,4+(i*3)%9,p[0]);put(pixels,i+1,4+(i*3)%9,p[2]);}
  if(ground==="soil") for(let i=2;i<15;i+=4){put(pixels,i,3+(i*5)%11,p[3]);put(pixels,i+1,3+(i*5)%11,p[0]);}
  if(ground==="sand") for(let y=3;y<15;y+=5)for(let x=(y+variant)%4;x<15;x+=6){put(pixels,x,y,p[3]);put(pixels,x+1,y,p[2]);}
  if(ground==="ice") for(let i=2;i<13;i++){put(pixels,i,15-i,p[i%2?3:0]);if(i%3===0)put(pixels,i,14-i,p[2]);}
  if(ground==="ash") for(let i=1;i<15;i+=3)put(pixels,i,13-(i*2)%9,p[i%2?0:2]);
  if(ground==="rubble") for(const [x,y] of [[1,2],[8,1],[4,8],[11,10]]){put(pixels,x,y,p[3]);put(pixels,x+1,y,p[2]);put(pixels,x,y+1,p[0]);}
  if(ground==="mud") for(const [x,y] of [[2,4],[9,10]])for(let q=0;q<4;q++){put(pixels,x+q,y,p[0]);if(q>0&&q<3)put(pixels,x+q,y+1,p[3]);}
  if(ground==="growth") for(let x=1;x<16;x+=2){const top=2+hash32(h,x)%6;for(let y=top;y<15;y+=3)put(pixels,x+(y%2),y,p[(x+y)%2?2:3]);}
  if(ground==="groundcover") for(let x=1;x<15;x+=3){const y=3+hash32(h,x)%11;put(pixels,x,y,p[3]);put(pixels,x-1,y+1,p[2]);put(pixels,x+1,y+1,p[2]);}
  if(ground==="chasm") for(let y=2;y<15;y+=4)for(let x=2+(y%3);x<14;x+=5)put(pixels,x,y,p[2]);
};

export function familyBitmap(ground,variant=0,visualSeed=0){if(!grounds.includes(ground)||!Number.isInteger(variant)||variant<0||variant>3)throw Error("invalid terrain family request");const pixels=blank();fill(pixels,palette[ground][1]);texture(pixels,ground,variant,visualSeed);return pixels;}

export function contourOffsets(id){if(!Number.isInteger(id)||id<0||id>3)throw Error("invalid contour id");return [[0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0],[1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1],[0,0,1,0,1,1,0,0,1,0,1,0,0,1,0,1],[1,1,0,0,1,0,0,1,0,1,0,1,0,0,1,0]][id];}
export function contourMask(direction,id){const mask=new Uint8Array(256),o=contourOffsets(id);for(let i=0;i<16;i++){const depth=1+o[i];if(direction==="north")for(let y=0;y<depth;y++)mask[y*16+i]=1;if(direction==="south")for(let y=16-depth;y<16;y++)mask[y*16+i]=1;if(direction==="west")for(let x=0;x<depth;x++)mask[i*16+x]=1;if(direction==="east")for(let x=16-depth;x<16;x++)mask[i*16+x]=1;}return mask;}

const validateKeys=(object,keys,label)=>{if(!object||typeof object!=="object"||Array.isArray(object)||Object.keys(object).sort().join()!==[...keys].sort().join())throw Error(`invalid ${label} fields`);};
export function normalizeTerrainLayerRequest(raw){
  const keys=["schemaVersion","ground","point","visualSeed","worldGradeDescriptorHash","featureVariant","cardinalNeighbors","edgeContourIDs","elevation","isCrumbled","isCracking","visibility","motionBand","phaseOffset","presentationTick","reduceMotion"];
  validateKeys(raw,keys,"request");validateKeys(raw.point,["x","y"],"point");validateKeys(raw.cardinalNeighbors,directions,"neighbors");validateKeys(raw.edgeContourIDs,directions,"contours");
  if(raw.schemaVersion!=="terrain-layers-v1"||!grounds.includes(raw.ground)||!visibilities.includes(raw.visibility)||!motionBands.includes(raw.motionBand))throw Error("invalid request enum");
  if(!Number.isInteger(raw.point.x)||!Number.isInteger(raw.point.y)||!Number.isInteger(raw.visualSeed)||raw.visualSeed<0||!Number.isInteger(raw.featureVariant)||raw.featureVariant<0||raw.featureVariant>3||!Number.isInteger(raw.elevation)||raw.elevation<0||raw.elevation>2||!Number.isInteger(raw.phaseOffset)||raw.phaseOffset<0||raw.phaseOffset>23||!Number.isInteger(raw.presentationTick)||raw.presentationTick<0||typeof raw.isCrumbled!=="boolean"||typeof raw.isCracking!=="boolean"||typeof raw.reduceMotion!=="boolean"||typeof raw.worldGradeDescriptorHash!=="string"||!raw.worldGradeDescriptorHash)throw Error("invalid request value");
  for(const d of directions){if(!["same","unknown",...grounds].includes(raw.cardinalNeighbors[d])||!Number.isInteger(raw.edgeContourIDs[d])||raw.edgeContourIDs[d]<0||raw.edgeContourIDs[d]>3)throw Error("invalid edge");}
  return Object.freeze(structuredClone(raw));
}

const stackPriority=Object.freeze({chasm:0,deepWater:1,water:2,stone:3,ice:3,rubble:3,soil:4,sand:4,ash:4,mud:4,groundcover:5,growth:6});
function edgeKind(ground,neighbor){if(neighbor==="same"||neighbor==="unknown"||neighbor===ground)return"none";if((ground==="water"&&neighbor==="deepWater")||(ground==="deepWater"&&neighbor==="water"))return ground==="deepWater"?"depth":"none";if((ground==="growth"&&neighbor==="groundcover")||(ground==="groundcover"&&neighbor==="growth"))return ground==="groundcover"?"height":"none";if((ground==="stone"&&neighbor==="rubble")||(ground==="rubble"&&neighbor==="stone"))return ground==="rubble"?"hard-loose":"none";if(neighbor==="chasm")return"chasm-rim";return stackPriority[neighbor]>stackPriority[ground]?"overlap":"none";}
function paintMask(pixels,mask,color){for(let i=0;i<256;i++)if(mask[i])pixels.set(hex(color),i*4);}
export function staticTerrainBody(request){const r=normalizeTerrainLayerRequest(request),pixels=familyBitmap(r.ground,r.featureVariant,r.visualSeed);if(r.isCrumbled){fill(pixels,"#08090c");for(const [x,y] of [[0,0],[1,0],[14,15],[15,15],[2,1],[13,14]])put(pixels,x,y,palette[r.ground][2]);return pixels;}for(const d of directions){const neighbor=r.cardinalNeighbors[d],kind=edgeKind(r.ground,neighbor);if(kind==="none")continue;const color=kind==="depth"?palette.deepWater[3]:kind==="height"?palette.growth[2]:kind==="chasm-rim"?palette[r.ground][3]:kind==="overlap"?palette[neighbor][2]:palette[r.ground][2];paintMask(pixels,contourMask(d,r.edgeContourIDs[d]),color);}return pixels;}

const frameStep=(ground,band)=>{const b={calm:0,moving:1,strong:2}[band];if(ground==="water")return[4,2,1][b];if(ground==="deepWater")return[6,3,2][b];if(["growth","groundcover"].includes(ground))return b===0?0:[4,2][b-1];return 0;};
export function motionOverlay(request){const r=normalizeTerrainLayerRequest(request),pixels=blank();if(r.visibility!=="full")return pixels;let phase=r.phaseOffset;if(!r.reduceMotion){const step=frameStep(r.ground,r.motionBand);if(step)phase=(phase+Math.floor((r.presentationTick%24)/step))%24;}const p=palette[r.ground];if(r.ground==="water"||r.ground==="deepWater"){const count=r.ground==="water"?4:2;for(let i=0;i<count;i++){const h=hash32(r.visualSeed,r.point.x,r.point.y,i),x=(h+phase+i*3)%15,y=((h>>>8)+i*4)%16;put(pixels,x,y,p[3]);if(i%2===0)put(pixels,x+1,y,p[2]);}}
  if(r.ground==="growth"||r.ground==="groundcover"){const count=r.ground==="growth"?4:3;for(let i=0;i<count;i++){const h=hash32(r.visualSeed,i),x=2+(h%12),y=2+((h>>>8)%12),shift=phase%2;put(pixels,Math.min(15,x+shift),y,p[3]);}}
  if(r.ground==="ice"&&hash32(r.visualSeed,r.point.x,r.point.y)%4===0&&phase%24<2){put(pixels,6,5,p[3]);put(pixels,7,5,p[3]);put(pixels,7,4,p[3]);}
  return pixels;}
export function compositeTerrain(request){const body=staticTerrainBody(request),motion=motionOverlay(request),pixels=new Uint8ClampedArray(body);for(let i=0;i<pixels.length;i+=4)if(motion[i+3])pixels.set(motion.slice(i,i+4),i);return{staticBody:body,motionOverlay:motion,composite:pixels};}
export function changedPixelCount(a,b){let n=0;for(let i=0;i<a.length;i+=4)if(a[i]!==b[i]||a[i+1]!==b[i+1]||a[i+2]!==b[i+2]||a[i+3]!==b[i+3])n++;return n;}
export const pixelAt=read;
