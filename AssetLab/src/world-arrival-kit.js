import { splashCommands, splashProofWorld, emptySplashDisclosure } from "./splash-kit.js";

export const ARRIVAL_SIZE = Object.freeze({ width: 160, height: 100 });
export const receiptKeys = Object.freeze([
  "receiptID", "worldSeed", "sourcePage", "dominantGround", "waterRelationship",
  "materialDescriptor", "illumination", "suspendedAtmosphere", "precipitation", "flora", "causalVisualFacts",
  "entryDisclosure", "description", "firstMapCropReceipt"
]);
const groundIDs = ["stone", "soil", "sand", "ice", "ash", "rubble", "mud", "growth", "groundcover"];
const waterIDs = ["none", "pools", "channels", "shelves", "islands"];
const lightBands = ["trueDark", "dim", "ordinary", "bright", "blazing"];
const sourceClasses = ["sourceless", "cyclic", "constant"];
const suspendedMedia = ["none", "smoke", "airborneAsh", "mist", "miasma"];
const precipitationMedia = ["none", "rain", "snow", "mixedRainSnow"];
const densityBands = ["none", "trace", "light", "heavy", "dense"];
const precipitationBands = ["none", "trace", "light", "heavy"];
const motionBands = ["calm", "moving", "strong"];
const habits = ["solitary", "clustered", "spreading", "mixed"];
const visibility = ["full", "fringe", "remembered", "hidden"];
const cropGroundIDs = [...groundIDs, "water", "deepWater", "chasm"];
const hasExactKeys = (value, keys) => value && typeof value === "object" && !Array.isArray(value)
  && Object.keys(value).sort().join("|") === [...keys].sort().join("|");
const finiteRGB = value => Array.isArray(value) && value.length === 3
  && value.every(channel => Number.isInteger(channel) && channel >= 0 && channel <= 255);

export function validateWorldArrivalReceipt(receipt) {
  const issues = [];
  if (!hasExactKeys(receipt, receiptKeys)) return ["invalid-receipt-fields"];
  if (typeof receipt.receiptID !== "string" || !receipt.receiptID) issues.push("invalid-receipt-id");
  if (!/^\d+$/.test(receipt.worldSeed)) issues.push("invalid-world-seed");
  const pageKeys = ["id", "title", "marks"];
  if (!hasExactKeys(receipt.sourcePage, pageKeys) || typeof receipt.sourcePage.id !== "string"
      || typeof receipt.sourcePage.title !== "string" || !Array.isArray(receipt.sourcePage.marks)
      || receipt.sourcePage.marks.some(mark => !hasExactKeys(mark, ["x", "y", "cells"])
        || !Number.isInteger(mark.x) || !Number.isInteger(mark.y) || mark.x < 0 || mark.x > 5 || mark.y < 0 || mark.y > 5
        || !Array.isArray(mark.cells) || !mark.cells.length || mark.cells.some(cell=>!Array.isArray(cell)||cell.length!==2||!cell.every(Number.isInteger)
          || mark.x+cell[0]<0||mark.x+cell[0]>5||mark.y+cell[1]<0||mark.y+cell[1]>5))) issues.push("invalid-source-page");
  if (!groundIDs.includes(receipt.dominantGround)) issues.push("unknown-ground");
  if (!waterIDs.includes(receipt.waterRelationship)) issues.push("unknown-water-relationship");
  if (!hasExactKeys(receipt.materialDescriptor, ["identity", "paletteFamilyID", "transform", "resolvedColor"])
      || typeof receipt.materialDescriptor.identity !== "string"
      || typeof receipt.materialDescriptor.paletteFamilyID !== "string"
      || !hasExactKeys(receipt.materialDescriptor.transform, ["hue", "saturation", "value"])
      || !Object.values(receipt.materialDescriptor.transform).every(Number.isFinite)
      || !(receipt.materialDescriptor.resolvedColor === null || finiteRGB(receipt.materialDescriptor.resolvedColor))) issues.push("invalid-material-descriptor");
  if (!hasExactKeys(receipt.illumination, ["band", "sourceClass"])
      || !lightBands.includes(receipt.illumination.band) || !sourceClasses.includes(receipt.illumination.sourceClass)) issues.push("invalid-illumination");
  if (!hasExactKeys(receipt.suspendedAtmosphere, ["medium", "density", "motion"])
      || !suspendedMedia.includes(receipt.suspendedAtmosphere?.medium)
      || !densityBands.includes(receipt.suspendedAtmosphere?.density)
      || !motionBands.includes(receipt.suspendedAtmosphere?.motion)
      || (receipt.suspendedAtmosphere?.medium === "none") !== (receipt.suspendedAtmosphere?.density === "none")) issues.push("invalid-suspended-atmosphere");
  if (!hasExactKeys(receipt.precipitation, ["medium", "intensity", "motion"])
      || !precipitationMedia.includes(receipt.precipitation?.medium)
      || !precipitationBands.includes(receipt.precipitation?.intensity)
      || !motionBands.includes(receipt.precipitation?.motion)
      || (receipt.precipitation?.medium === "none") !== (receipt.precipitation?.intensity === "none")) issues.push("invalid-precipitation");
  if (!Array.isArray(receipt.flora) || receipt.flora.length > 4 || receipt.flora.some(row =>
    !hasExactKeys(row, ["stableID", "formID", "coverage", "habit", "color"])
    || typeof row.stableID !== "string" || !Number.isInteger(row.formID)
    || !["sparse", "present", "abundant"].includes(row.coverage)
    || !habits.includes(row.habit) || !finiteRGB(row.color))) issues.push("invalid-flora");
  if (!Array.isArray(receipt.causalVisualFacts) || receipt.causalVisualFacts.some(row =>
    !hasExactKeys(row, ["markID", "visibleScope", "contributionKind", "resultBand", "withoutAuthoredBand"])
    || typeof row.markID !== "string" || !["ground", "water", "flora", "resource", "light", "atmosphere"].includes(row.visibleScope)
    || !["none", "increased", "reduced", "reshaped"].includes(row.contributionKind)
    || typeof row.resultBand !== "string" || !row.resultBand
    || typeof row.withoutAuthoredBand !== "string" || !row.withoutAuthoredBand
    || (row.visibleScope === "resource" && (!["absent", "present"].includes(row.resultBand)
      || !["absent", "present"].includes(row.withoutAuthoredBand))))) issues.push("invalid-causal-visual-facts");
  if (!(receipt.entryDisclosure === null || (hasExactKeys(receipt.entryDisclosure, ["siteProfile", "status"])
      && typeof receipt.entryDisclosure.siteProfile === "string" && receipt.entryDisclosure.status === "entryVisible"))) issues.push("invalid-entry-disclosure");
  const words = typeof receipt.description === "string" ? receipt.description.trim().split(/\s+/).length : 0;
  if (words < 18 || words > 55 || (receipt.description.match(/[.!?](?:\s|$)/g) ?? []).length !== 2) issues.push("invalid-description");
  if (!hasExactKeys(receipt.firstMapCropReceipt, ["width", "height", "cells"])
      || receipt.firstMapCropReceipt.width !== 9 || receipt.firstMapCropReceipt.height !== 9
      || !Array.isArray(receipt.firstMapCropReceipt.cells) || receipt.firstMapCropReceipt.cells.length !== 81
      || receipt.firstMapCropReceipt.cells.some(cell => {
        if (!cell || !visibility.includes(cell.visibility) || !Number.isInteger(cell.x) || !Number.isInteger(cell.y)
            || cell.x < 0 || cell.x >= 9 || cell.y < 0 || cell.y >= 9) return true;
        if (cell.visibility === "hidden") return !hasExactKeys(cell, ["x", "y", "visibility"]);
        return !hasExactKeys(cell, ["x", "y", "ground", "elevation", "floraStableID", "visibility"])
          || !cropGroundIDs.includes(cell.ground) || !Number.isInteger(cell.elevation)
          || !(cell.floraStableID === null || (cell.visibility === "full" && typeof cell.floraStableID === "string"));
      }) || new Set(receipt.firstMapCropReceipt.cells.map(cell => `${cell.x},${cell.y}`)).size !== 81) issues.push("invalid-map-crop");
  return issues;
}

const rect = (x, y, w, h, color, scope) => ({ op: "rect", x, y, w, h, color, scope });
function bitmap(x,y,rows,colors,scope,scale=1){const commands=[];rows.forEach((row,rowIndex)=>{let start=0;while(start<row.length){const key=row[start];let end=start+1;while(end<row.length&&row[end]===key)end++;if(key!==".")commands.push(rect(x+start*scale,y+rowIndex*scale,(end-start)*scale,scale,colors[key],scope));start=end;}});return commands;}
const rockPart=["..aaa...",".abbbba.","abccccba","abccbbba",".abbbba.","..aaa..."];
const succulentPart=["...a...","a..a..a",".aaba..","..aba..",".acbca.","..ccc.."];
const poolPart=["....aaaaaa....","..aabbbbbbaa..",".abccccccccba.","abccccccccccba",".abccccccccba.","..aabbbbbbaa..","....aaaaaa...."];
const shelfPart=["...aaaaaaaa....",".aabbbbbbbbaa..","abccccccccccba.","abcccccccccccba",".abccccccccccba","..aabbbbbbbbba","....aaaaaaaaa."];
const dunePart=["........................aaaa..","....................aaaabbba..","..............aaaaaabbbbbbbba.","........aaaaaabbbbbbbbbbbbbba.","..aaaaaabbbbbbbbbbbbbbbbbbbbba","aabbbbbbbbbbbbbbbbbbbbbbbbbbbb"];
export const arrivalPixelPartIDs=Object.freeze(["rock-cluster","succulent-crown","organic-pool-bank","broken-stone-shelf"]);
export function arrivalPixelPartCommands(id){switch(id){
case "rock-cluster":return{width:8,height:6,commands:bitmap(0,0,rockPart,{a:"#403d38",b:"#77746b",c:"#aaa69a"},"part")};
case "succulent-crown":return{width:7,height:6,commands:bitmap(0,0,succulentPart,{a:"#347a62",b:"#55a882",c:"#273f34"},"part")};
case "organic-pool-bank":return{width:14,height:7,commands:bitmap(0,0,poolPart,{a:"#66543b",b:"#73aab3",c:"#2d6378"},"part")};
case "broken-stone-shelf":return{width:15,height:7,commands:bitmap(0,0,shelfPart,{a:"#45494a",b:"#777b78",c:"#aaa99f"},"part")};
default:throw new Error(`unknown-arrival-pixel-part:${id}`);
}}
const palettes = {
  stone: ["#474a4d", "#777b78", "#a9aaa0"], soil: ["#49392b", "#7f6041", "#b38c5e"],
  sand: ["#67543a", "#ad8c57", "#d2b879"], ice: ["#46636d", "#7ca2a8", "#c4dad7"],
  ash: ["#403a3e", "#73686a", "#b39b90"], rubble: ["#4b4541", "#756b61", "#a79a88"],
  mud: ["#3f352b", "#67513b", "#917450"], growth: ["#284b31", "#47764b", "#73a35d"],
  groundcover: ["#324c31", "#58734a", "#87a466"]
};
const water = ["#173849", "#2d6378", "#5b94a2"];
const hash = value => { let result = 2166136261; for (const char of String(value)) result = Math.imul(result ^ char.charCodeAt(0), 16777619) >>> 0; return result; };
const lifecycleEntry = splashCommands({ transition: "entry", continuity: "transient", world: { ...splashProofWorld }, disclosure: { ...emptySplashDisclosure } });
export const lifecycleFrameCommands = Object.freeze(lifecycleEntry.slice(0, 3).map(Object.freeze));
export const lifecycleEntryMarkCommands = Object.freeze(lifecycleEntry.slice(-2).map(Object.freeze));

export function arrivalSceneCommands(receipt) {
  const issues = validateWorldArrivalReceipt(receipt);
  if (issues.length) throw new Error(`invalid-world-arrival-receipt:${issues.join(",")}`);
  const p = palettes[receipt.dominantGround], commands = lifecycleFrameCommands.map(command => ({ ...command, scope: "frame" }));
  const seed = hash(receipt.receiptID + receipt.worldSeed);
  const far = { trueDark: "#181a20", dim: "#303746", ordinary: "#71838b", bright: "#9fb5b5", blazing: "#d5c9a4" }[receipt.illumination.band];
  commands.push(rect(10, 10, 140, 34, far, "illumination"));
  if(["shelves","islands"].includes(receipt.waterRelationship)){
    [[10,34,31,10],[41,31,37,13],[78,35,29,9],[107,30,43,14]].forEach(([x,y,w,h],index)=>commands.push(rect(x,y,w,h,index%2?water[0]:"#234b5a","water")));
    [[13,27,1],[48,21,1],[83,26,1],[113,19,1]].forEach(([x,y,scale],index)=>commands.push(...bitmap(x,y,shelfPart,{a:p[0],b:index%2?p[1]:p[0],c:p[1]},"ground",scale)));
    [[18,38,18],[70,34,23],[119,36,17]].forEach(([x,y,w])=>commands.push(rect(x,y,w,1,water[2],"water")));
  }else if(receipt.dominantGround==="stone"){
    [[12,12,2],[35,18,2],[58,11,2],[103,14,2],[129,19,2]].forEach(([x,y,scale])=>commands.push(...bitmap(x,y,rockPart,{a:"#303234",b:p[0],c:p[1]},"ground",scale)));
    [[19,35,19],[61,30,14],[111,34,24]].forEach(([x,y,w])=>commands.push(rect(x,y,w,2,p[0],"ground")));
  }else{
    commands.push(...bitmap(11,25,dunePart,{a:p[0],b:p[1]},"ground",2),...bitmap(80,20,dunePart,{a:p[0],b:p[1]},"ground",2));
    [[17,38,18],[58,34,13],[108,37,26]].forEach(([x,y,w])=>commands.push(rect(x,y,w,1,p[2],"material")));
  }
  const ground = color => rect(10, 42, 140, 48, color, "ground");
  if (["shelves", "islands"].includes(receipt.waterRelationship)) {
    commands.push(ground(water[0]),rect(10,50,140,40,water[1],"water"));
    const shelfColors={a:p[0],b:p[1],c:p[2]};
    [[13,47,2],[65,42,2],[108,51,2],[33,72,2],[93,76,1]].forEach(([x,y,scale])=>commands.push(...bitmap(x,y,shelfPart,shelfColors,"ground",scale)));
    [[12,63,22],[54,57,17],[99,70,24],[120,44,18]].forEach(([x,y,w])=>{commands.push(rect(x,y,w,1,water[2],"water"));commands.push(rect(x+4,y+3,Math.max(3,w-9),1,"#9bc0c4","water"));});
    [[17,53],[58,69],[102,57],[132,78]].forEach(([x,y])=>commands.push(...bitmap(x,y,rockPart,{a:p[0],b:p[1],c:p[2]},"material")));
  } else {
    commands.push(ground(p[1]));
    for(let i=0;i<34;i++){const x=13+((seed+i*41)%134),y=45+(((seed>>>5)+i*23)%42),w=1+((seed>>>((i%8)+1))&3);commands.push(rect(x,y,w,1,i%3?p[2]:p[0],"material"));}
    if (receipt.waterRelationship === "pools") {
      [[20,63,2],[86,70,2],[123,53,1]].forEach(([x,y,scale])=>commands.push(...bitmap(x,y,poolPart,{a:p[0],b:water[2],c:water[1]},"water",scale)));
    }
    if (receipt.waterRelationship === "channels") {
      [[18,55,2],[63,64,2],[105,49,2]].forEach(([x,y,scale])=>commands.push(...bitmap(x,y,poolPart,{a:p[0],b:water[2],c:water[1]},"water",scale)));
      [[43,61,28],[89,69,25]].forEach(([x,y,w])=>commands.push(rect(x,y,w,2,water[1],"water"),rect(x+3,y,w-7,1,water[2],"water")));
    }
    if(receipt.dominantGround==="stone"){
      commands.push(rect(10,10,140,17,"#303234","ground"));
      [[11,17,3],[34,12,2],[52,18,2],[110,15,3],[132,21,2],[12,39,2],[135,43,2],[14,68,2],[136,70,2]].forEach(([x,y,scale])=>commands.push(...bitmap(x,y,rockPart,{a:"#303234",b:p[0],c:p[1]},"ground",scale)));
      const soil=palettes.soil;for(let y=53;y<90;y++){const depth=y-53,half=5+Math.floor(depth*.42),jitter=((seed>>>((y-53)%16))&3)-1;commands.push(rect(80-half+jitter,y,half*2,1,y%5===0?soil[2]:soil[1],"ground"));}
      [[15,55],[31,76],[117,59],[137,78],[102,42]].forEach(([x,y])=>commands.push(...bitmap(x,y,rockPart,{a:p[0],b:p[1],c:p[2]},"material")));
    } else {
      [[17,48],[49,75],[111,62],[136,43]].forEach(([x,y])=>commands.push(...bitmap(x,y,rockPart,{a:p[0],b:p[1],c:p[2]},"material")));
    }
  }
  for (let i = 0; i < 26; i++) {
    const x = 14 + ((seed + i * 37) % 132), y = 46 + (((seed >>> 4) + i * 23) % 40);
    commands.push(rect(x,y,i%5===0?2:1,1,i%3===0?p[2]:p[0],"material"));
  }
  receipt.flora.forEach((flora, speciesIndex) => {
    const count = flora.coverage === "abundant" ? 12 : flora.coverage === "present" ? 8 : 4;
    const color = `rgb(${flora.color.join(",")})`, base = hash(flora.stableID);
    for (let i = 0; i < count; i++) {
      const x = 16 + ((base + i * 29) % 128), y = 60 + (((base >>> 5) + i * 17) % 25);
      const height = 3 + (flora.formID % 4);
      commands.push(...bitmap(x-3,y-height-2,succulentPart,{a:color,b:p[2],c:p[0]},"flora"));
    }
  });
  const suspended = receipt.suspendedAtmosphere;
  if (suspended.medium !== "none") {
    const color = { smoke:"#817a70", airborneAsh:"#a0a2a3", mist:"#aebfc0", miasma:"#947f98" }[suspended.medium];
    const count = { trace:5, light:9, heavy:15, dense:22 }[suspended.density];
    for (let i=0;i<count;i++){const x=14+((seed+i*31)%132),y=20+(((seed>>>7)+i*19)%58);commands.push(rect(x,y,i%3===0?4:2,i%4===0?2:1,color,"suspended"));}
  }
  const precipitation = receipt.precipitation;
  if (precipitation.medium !== "none") {
    const color = precipitation.medium === "rain" ? "#83b3c2" : precipitation.medium === "snow" ? "#dce3dd" : "#bdced1";
    const count = { trace:8, light:14, heavy:24 }[precipitation.intensity];
    for(let i=0;i<count;i++){const x=14+((seed+i*43)%132),y=16+(((seed>>>8)+i*17)%68);commands.push(rect(x,y,1,precipitation.medium==="snow"?1:3,color,"precipitation"));}
  }
  if (receipt.entryDisclosure) commands.push(...bitmap(124,53,["..aaa..",".abbba.","abcccba","abcccba",".abbba.","..aaa.."],{a:"#6c5540",b:"#d0a66d",c:"#efe0b9"},"entryDisclosure",2));
  const entryRune=receipt.sourcePage.marks[0];for(const [dx,dy] of entryRune.cells){const x=77+dx*2,y=77+dy*2;commands.push(rect(x,y,2,1,p[0],"entryMark"),rect(x+(dy%2),y-1,1,1,p[2],"entryMark"));}
  return commands;
}

export function cropCommands(receipt) {
  const issues = validateWorldArrivalReceipt(receipt); if (issues.length) throw new Error(`invalid-world-arrival-receipt:${issues.join(",")}`);
  const commands = [rect(0,0,90,90,"#000","hidden")];
  for (const cell of receipt.firstMapCropReceipt.cells) {
    const x=cell.x*10,y=cell.y*10;
    if(cell.visibility==="hidden") continue;
    const palette=palettes[cell.ground]??(cell.ground==="water"||cell.ground==="deepWater"?water:null);
    if(!palette) throw new Error(`unknown-crop-ground:${cell.ground}`);
    commands.push(rect(x,y,10,10,palette[cell.ground==="deepWater"?0:1],"mapTerrain"));
    if(cell.visibility==="fringe") commands.push(rect(x,y,10,10,"rgba(12,17,18,.48)","mapVisibility"));
    if(cell.floraStableID&&cell.visibility==="full") commands.push(rect(x+4,y+3,3,5,"#6f9b59","mapFlora"));
  }
  return commands;
}
