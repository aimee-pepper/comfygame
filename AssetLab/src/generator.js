export const defaults = Object.freeze({
  schemaVersion: 4,
  kind: "creature",
  logicalID: "phase0-creature",
  speciesSeed: 1847,
  specimenSeed: 1,
  traits: {
    topology: "quadruped",
    size: 58,
    build: 48,
    boneDensity: 46,
    ornament: 22,
    coveringHardness: 42,
    coveringLength: 38,
    coveringCoverage: 68,
    appendageCount: 4,
    appendageType: "limbed",
    pierce: 38,
    crush: 12,
    rend: 20,
    reach: "mid",
    delivery: "single",
    cyan: 32,
    magenta: 26,
    yellow: 42,
    colorDepth: 48,
    patterning: 28,
    opacity: 82,
    shine: 14,
    schiller: 4,
    vision: 46,
    mechano: 22,
    chemo: 20,
    thermo: 12,
    emanationStrength: 0,
    emanationKind: "light",
    emanationLight: 70,
    emanationHeat: 15,
    emanationCaustic: 15,
    defence: "armour",
    toxic: false
  }
});

const range = (key, label, group, min = 0, max = 100, step = 1) => ({ key, label, group, min, max, step });
const choice = (key, label, group, options) => ({ key, label, group, options });
export const traitDefinitions = [
  choice("topology", "Body topology", "Body", ["quadruped", "biped", "serpentine", "segmented", "radial", "piscine", "winged", "amorphous"]),
  range("size", "Size", "Body", 10, 100),
  range("build", "Build · sinuous → bulky", "Body"),
  range("boneDensity", "Bone density", "Body"),
  range("ornament", "Ornament", "Body"),
  range("coveringHardness", "Covering hardness", "Covering"),
  range("coveringLength", "Covering length", "Covering"),
  range("coveringCoverage", "Covering coverage", "Covering"),
  range("appendageCount", "Appendage count", "Appendages", 0, 8, 1),
  choice("appendageType", "Appendage type", "Appendages", ["limbed", "finned", "feathered", "membrane", "none"]),
  range("pierce", "Pierce", "Armament"),
  range("crush", "Crush", "Armament"),
  range("rend", "Rend", "Armament"),
  choice("reach", "Reach", "Armament", ["close", "mid", "far"]),
  choice("delivery", "Delivery", "Armament", ["single", "multi", "area"]),
  range("cyan", "Cyan", "Coloration"),
  range("magenta", "Magenta", "Coloration"),
  range("yellow", "Yellow", "Coloration"),
  range("colorDepth", "Depth", "Coloration"),
  range("patterning", "Patterning", "Coloration"),
  range("opacity", "Opacity", "Finish"),
  range("shine", "Shine", "Finish"),
  range("schiller", "Schiller", "Finish"),
  range("vision", "Vision", "Senses"),
  range("mechano", "Mechanical sense", "Senses"),
  range("chemo", "Chemical sense", "Senses"),
  range("thermo", "Thermal sense", "Senses"),
  range("emanationStrength", "Emanation strength", "Emanation"),
  range("emanationLight", "Light allocation", "Emanation"),
  range("emanationHeat", "Heat allocation", "Emanation"),
  range("emanationCaustic", "Caustic allocation", "Emanation"),
  choice("defence", "Defence branch", "Defence", ["none", "armour", "speed", "crypsis", "aposematism"]),
  choice("toxic", "Toxic", "Defence", [false, true])
];

export const presets = Object.freeze({
  "Cold plated grazer": { topology:"quadruped",size:78,build:72,boneDensity:76,ornament:8,coveringHardness:88,coveringLength:62,coveringCoverage:92,appendageCount:4,appendageType:"limbed",pierce:12,crush:48,rend:4,reach:"close",delivery:"single",cyan:48,magenta:24,yellow:28,colorDepth:55,patterning:18,opacity:96,shine:12,schiller:2,vision:42,mechano:24,chemo:22,thermo:12,emanationStrength:0,emanationKind:"heat",defence:"armour",toxic:false },
  "Lightless cave serpent": { topology:"serpentine",size:64,build:18,boneDensity:30,ornament:5,coveringHardness:20,coveringLength:8,coveringCoverage:42,appendageCount:0,appendageType:"none",pierce:72,crush:5,rend:38,reach:"mid",delivery:"single",cyan:42,magenta:30,yellow:28,colorDepth:14,patterning:44,opacity:72,shine:32,schiller:10,vision:4,mechano:56,chemo:30,thermo:10,emanationStrength:24,emanationKind:"light",defence:"crypsis",toxic:true },
  "Sun-glass flier": { topology:"winged",size:38,build:30,boneDensity:16,ornament:86,coveringHardness:28,coveringLength:74,coveringCoverage:82,appendageCount:4,appendageType:"feathered",pierce:44,crush:2,rend:20,reach:"mid",delivery:"multi",cyan:18,magenta:48,yellow:72,colorDepth:82,patterning:66,opacity:76,shine:52,schiller:78,vision:82,mechano:8,chemo:6,thermo:4,emanationStrength:42,emanationKind:"light",defence:"speed",toxic:false },
  "Mineral hive crawler": { topology:"segmented",size:52,build:58,boneDensity:84,ornament:20,coveringHardness:94,coveringLength:5,coveringCoverage:96,appendageCount:8,appendageType:"limbed",pierce:54,crush:42,rend:32,reach:"close",delivery:"multi",cyan:30,magenta:28,yellow:42,colorDepth:64,patterning:35,opacity:100,shine:46,schiller:12,vision:24,mechano:32,chemo:36,thermo:8,emanationStrength:0,emanationKind:"caustic",defence:"armour",toxic:false },
  "Caustic bloom": { topology:"radial",size:70,build:62,boneDensity:12,ornament:68,coveringHardness:14,coveringLength:45,coveringCoverage:56,appendageCount:8,appendageType:"membrane",pierce:18,crush:4,rend:62,reach:"far",delivery:"area",cyan:66,magenta:12,yellow:22,colorDepth:74,patterning:72,opacity:58,shine:22,schiller:28,vision:8,mechano:18,chemo:64,thermo:10,emanationStrength:76,emanationKind:"caustic",defence:"aposematism",toxic:true }
});

export function cloneDescriptor(value = defaults) { return JSON.parse(JSON.stringify(value)); }
export function safeFilePart(value,fallback="asset") { const cleaned=String(value??"").normalize("NFKD").replace(/[\u0300-\u036f]/g,"").replace(/[^a-zA-Z0-9._-]+/g,"-").replace(/^[._-]+|[._-]+$/g,"").slice(0,64);return cleaned||fallback; }

export function normalizeDescriptor(input) {
  const d = cloneDescriptor(defaults);
  if (!input || typeof input !== "object") return d;
  d.schemaVersion = 4;
  d.kind = "creature";
  d.logicalID = typeof input.logicalID === "string" ? input.logicalID.slice(0, 80) : d.logicalID;
  // v2 used one `seed`. It becomes the species seed; specimen variation starts at 1.
  d.speciesSeed = clampInteger(input.speciesSeed ?? input.seed, 0, 0xffffffff, d.speciesSeed);
  d.specimenSeed = clampInteger(input.specimenSeed, 0, 0xffffffff, d.specimenSeed);
  for (const def of traitDefinitions) {
    const value = input.traits?.[def.key];
    if (def.options) d.traits[def.key] = def.options.includes(value) ? value : d.traits[def.key];
    else d.traits[def.key] = clampInteger(value, def.min, def.max, d.traits[def.key]);
  }
  if(input.traits && !["emanationLight","emanationHeat","emanationCaustic"].some(key=>Number.isFinite(Number(input.traits[key])))){
    const kind=["light","heat","caustic"].includes(input.traits.emanationKind)?input.traits.emanationKind:"light";
    Object.assign(d.traits,kind==="heat"?{emanationLight:15,emanationHeat:70,emanationCaustic:15}:kind==="caustic"?{emanationLight:15,emanationHeat:15,emanationCaustic:70}:{emanationLight:70,emanationHeat:15,emanationCaustic:15});
  }
  normalizeAllocation(d.traits, ["cyan", "magenta", "yellow"]);
  normalizeAllocation(d.traits, ["vision", "mechano", "chemo", "thermo"]);
  normalizeAllocation(d.traits, ["emanationLight", "emanationHeat", "emanationCaustic"]);
  d.traits.emanationKind=["light","heat","caustic"].reduce((best,key)=>d.traits[`emanation${key[0].toUpperCase()}${key.slice(1)}`]>d.traits[`emanation${best[0].toUpperCase()}${best.slice(1)}`]?key:best,"light");
  return d;
}

function normalizeAllocation(traits, keys) {
  const total=keys.reduce((sum,key)=>sum+Math.max(0,Number(traits[key])||0),0);
  if(total===100)return;
  if(total<=0){const share=Math.floor(100/keys.length);keys.forEach(key=>traits[key]=share);traits[keys[0]]+=100-share*keys.length;return;}
  let used=0;
  keys.forEach((key,index)=>{const value=index===keys.length-1?100-used:Math.round(Math.max(0,traits[key])/total*100);traits[key]=value;used+=value;});
}

export function rebalanceAllocation(traits, changedKey, keys, requested) {
  const value=Math.max(0,Math.min(100,Math.round(Number(requested)||0))), others=keys.filter(key=>key!==changedKey), oldTotal=others.reduce((sum,key)=>sum+Math.max(0,traits[key]),0), remaining=100-value;
  traits[changedKey]=value;
  if(oldTotal<=0){const share=Math.floor(remaining/others.length);let used=0;others.forEach((key,index)=>{traits[key]=index===others.length-1?remaining-used:share;used+=traits[key];});return;}
  let used=0;others.forEach((key,index)=>{const next=index===others.length-1?remaining-used:Math.round(Math.max(0,traits[key])/oldTotal*remaining);traits[key]=next;used+=next;});
}

function clampInteger(value, min, max, fallback) {
  const number = Number(value);
  return Number.isFinite(number) ? Math.max(min, Math.min(max, Math.round(number))) : fallback;
}

export function rng(seed) {
  let state = (Number(seed) >>> 0) || 0x6d2b79f5;
  return () => {
    state += 0x6d2b79f5;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function canonicalJSON(value) {
  if (Array.isArray(value)) return `[${value.map(canonicalJSON).join(",")}]`;
  if (value && typeof value === "object") return `{${Object.keys(value).sort().map(key => `${JSON.stringify(key)}:${canonicalJSON(value[key])}`).join(",")}}`;
  return JSON.stringify(value);
}

export function hash(value) {
  const string = typeof value === "string" ? value : canonicalJSON(value);
  let h = 0x811c9dc5;
  for (let i = 0; i < string.length; i++) { h ^= string.charCodeAt(i); h = Math.imul(h, 0x01000193); }
  return (h >>> 0).toString(16).padStart(8, "0");
}

const rect = (x, y, w, h, color) => ({ op: "rect", x: Math.round(x), y: Math.round(y), w: Math.max(1, Math.round(w)), h: Math.max(1, Math.round(h)), color });
function pixelLine(x0, y0, x1, y1, thickness, color) {
  x0 = Math.round(x0); y0 = Math.round(y0); x1 = Math.round(x1); y1 = Math.round(y1);
  const commands = [], dx = Math.abs(x1 - x0), sx = x0 < x1 ? 1 : -1, dy = -Math.abs(y1 - y0), sy = y0 < y1 ? 1 : -1;
  let error = dx + dy;
  while (true) {
    commands.push(rect(x0, y0, thickness, thickness, color));
    if (x0 === x1 && y0 === y1) break;
    const twice = 2 * error;
    if (twice >= dy) { error += dy; x0 += sx; }
    if (twice <= dx) { error += dx; y0 += sy; }
  }
  return commands;
}

export function paletteFor(raw) {
  const d = normalizeDescriptor(raw), t = d.traits;
  const total = Math.max(1, t.cyan + t.magenta + t.yellow);
  // A narrow seeded drift gives specimens stable individual coloration without changing the
  // species' authored CMY identity.
  const hue = (((t.magenta / total) * 330 + (t.yellow / total) * 65 + (t.cyan / total) * 190) + (d.speciesSeed % 7) - 3) % 360;
  const saturation = 22 + t.colorDepth * .55;
  const lightness = 36 + t.opacity * .12;
  const aposematic = t.defence === "aposematism";
  const toxicHue = t.toxic ? 112 : hue + 155;
  return {
    outline: hsl(hue, saturation * .45, 9 + t.shine * .05),
    shadow: hsl(hue + 8, saturation * .75, lightness - 17),
    body: alpha(hsl(hue, saturation, lightness), 24 + t.opacity * .76),
    light: alpha(hsl(hue + t.schiller * .7, saturation + 8, lightness + 19), 45 + t.opacity * .55),
    accent: hsl(aposematic ? hue + 180 : toxicHue, aposematic ? 88 : 58, aposematic ? 61 : 48),
    sense: hsl(188, 74, 67),
    glow: hsl(t.emanationKind === "heat" ? 20 : t.emanationKind === "caustic" ? 105 : 185, 88, 70)
  };
}
function hsl(h, s, l) { return `hsl(${Math.round((h + 360) % 360)} ${Math.round(Math.min(100, s))}% ${Math.round(Math.min(92, Math.max(4, l)))}%)`; }

export function creatureCommands(raw, profile) {
  const d = normalizeDescriptor(raw), random = rng(d.speciesSeed ^ d.specimenSeed ^ (profile === "world" ? 0x771d : 0xf19a)), p = paletteFor(d);
  const commands=profile === "world" ? worldCreature(d, p, random) : fightCreature(d, p, random);
  addSpecimenMark(commands,d,p,profile);
  return fitCommands(commands,profile==="world"?16:48,profile==="world"?16:48,1);
}

function addSpecimenMark(commands,d,p,profile){
  const random=rng(d.specimenSeed^0x51ec1),size=profile==="world"?1:2,x=profile==="world"?5+Math.floor(random()*6):15+Math.floor(random()*12),y=profile==="world"?7+Math.floor(random()*3):22+Math.floor(random()*7);
  commands.push(rect(x,y,size,size,random()>.5?p.accent:p.shadow));
}

export function commandBounds(commands){
  if(!commands.length)return {minX:0,minY:0,maxX:0,maxY:0,width:0,height:0};
  const minX=Math.min(...commands.map(c=>c.x)),minY=Math.min(...commands.map(c=>c.y)),maxX=Math.max(...commands.map(c=>c.x+c.w)),maxY=Math.max(...commands.map(c=>c.y+c.h));
  return {minX,minY,maxX,maxY,width:maxX-minX,height:maxY-minY};
}
export function fitCommands(commands,width,height,padding=0){
  const bounds=commandBounds(commands),availableW=width-padding*2,availableH=height-padding*2;
  if(bounds.width>availableW||bounds.height>availableH)return commands.map(c=>({...c,x:Math.max(padding,Math.min(width-padding-c.w,c.x)),y:Math.max(padding,Math.min(height-padding-c.h,c.y))}));
  const dx=bounds.minX<padding?padding-bounds.minX:bounds.maxX>width-padding?width-padding-bounds.maxX:0;
  const dy=bounds.minY<padding?padding-bounds.minY:bounds.maxY>height-padding?height-padding-bounds.maxY:0;
  return commands.map(c=>({...c,x:c.x+dx,y:c.y+dy}));
}

function worldCreature(d, p, random) {
  const c = [], t = d.traits, cx = 8, cy = 8;
  if (t.emanationStrength > 25) c.push(rect(3, 3, 10, 10, alpha(p.glow, 32 + t.emanationStrength * .35)));
  switch (t.topology) {
  case "serpentine":
    c.push(...pixelLine(4, 11, 7, 6, 2, p.outline), ...pixelLine(7, 6, 12, 8, 2, p.body));
    c.push(rect(11, 7, 3, 3, p.outline), rect(12, 8, 1, 1, p.light)); break;
  case "segmented":
    for (let i = 0; i < 4; i++) c.push(rect(3 + i * 3, 6 + (i % 2), 4, 5, p.outline), rect(4 + i * 3, 7 + (i % 2), 2, 3, i % 2 ? p.shadow : p.body)); break;
  case "radial":
    c.push(rect(5, 5, 7, 7, p.outline), rect(6, 6, 5, 5, p.body));
    for (const [x, y] of [[2,7],[12,7],[7,2],[7,12],[3,3],[11,3],[3,11],[11,11]]) c.push(...pixelLine(cx, cy, x, y, 1, p.accent)); break;
  case "piscine":
    c.push(rect(4, 5, 8, 7, p.outline), rect(5, 6, 7, 5, p.body), ...pixelLine(4, 8, 1, 5, 1, p.accent), ...pixelLine(4, 8, 1, 11, 1, p.accent)); break;
  case "winged":
    c.push(rect(6, 5, 5, 7, p.outline), rect(7, 6, 3, 5, p.body), ...pixelLine(7, 7, 2, 3, 1, p.accent), ...pixelLine(10, 7, 14, 3, 1, p.accent)); break;
  case "amorphous":
    c.push(rect(4, 7, 9, 5, p.outline), rect(5, 5, 6, 7, p.body), rect(7, 4, 3, 2, p.light)); break;
  case "biped":
    c.push(rect(5, 4, 7, 7, p.outline), rect(6, 5, 5, 5, p.body), ...pixelLine(7, 10, 5, 14, 1, p.shadow), ...pixelLine(10, 10, 12, 14, 1, p.shadow)); break;
  default:
    { const w=7+Math.round(t.size/35),h=4+Math.round(t.build/45),x=8-Math.floor(w/2),y=8-Math.floor(h/2);c.push(rect(x-1,y-1,w+2,h+2,p.outline),rect(x,y,w,h,p.body)); }
  }
  decorateWorld(c, d, p, random);
  return c;
}

function decorateWorld(c, d, p, random) {
  const t = d.traits;
  if (["quadruped", "segmented"].includes(t.topology) && t.appendageType === "limbed") {
    const legs = Math.min(4, t.appendageCount);
    for (let i = 0; i < legs; i++) c.push(rect(4 + i * 2, 11, 1, 3, p.shadow));
  }
  if (t.coveringHardness > 55) for (let x = 5; x <= 11; x += 2) c.push(rect(x, 5, 1, 1, p.light));
  if (t.coveringLength > 60) for (let x = 4; x <= 12; x += 2) c.push(rect(x, 4 + Math.round(random()), 1, 2, p.light));
  if (t.boneDensity > 58) c.push(rect(6, 9, 5, 1, p.light));
  if (t.ornament > 45) c.push(...pixelLine(7,5,6,2,1,p.accent),...pixelLine(9,5,10,2,1,p.accent));
  addWorldAppendageType(c,t,p);
  addPattern(c, t, p, 5, 7, 6, 3, 1);
  const arm = dominantArmament(t);
  if (arm.value > 30) {
    if (arm.kind === "pierce") c.push(...pixelLine(12, 8, 15, 7, 1, p.accent));
    if (arm.kind === "crush") c.push(rect(12, 7, 3, 3, p.accent));
    if (arm.kind === "rend") c.push(rect(12, 8, 1, 3, p.accent), rect(14, 8, 1, 3, p.accent));
  }
  addSense(c, t, p, 11, 7, 1);
}

function addWorldAppendageType(c,t,p) {
  if(t.appendageType==="finned")c.push(...pixelLine(6,7,4,4,1,p.accent),...pixelLine(9,8,11,12,1,p.accent));
  if(t.appendageType==="feathered")c.push(...pixelLine(6,7,2,3,1,p.light),...pixelLine(10,7,14,3,1,p.light));
  if(t.appendageType==="membrane")c.push(rect(2,4,4,2,p.accent),rect(11,4,4,2,p.accent));
}

function fightCreature(d, p, random) {
  const c = [], t = d.traits;
  if (t.emanationStrength > 15) c.push(rect(5, 5, 39, 38, alpha(p.glow, 20 + t.emanationStrength * .4)));
  const sizeScale = .78 + t.size / 210, bulk = .72 + t.build / 160;
  switch (t.topology) {
  case "serpentine": drawSerpentine(c, t, p, sizeScale); break;
  case "segmented": drawSegmented(c, t, p, sizeScale); break;
  case "radial": drawRadial(c, t, p, sizeScale); break;
  case "piscine": drawPiscine(c, t, p, sizeScale); break;
  case "winged": drawWinged(c, t, p, sizeScale); break;
  case "amorphous": drawAmorphous(c, t, p, sizeScale); break;
  case "biped": drawBiped(c, t, p, sizeScale, bulk); break;
  default: drawQuadruped(c, t, p, sizeScale, bulk);
  }
  addFightSurface(c, d, p, random);
  return c;
}

function drawQuadruped(c, t, p, s, bulk) {
  const w = Math.round(18 * s * bulk), h = Math.round(10 * s), x = 20 - Math.floor(w / 2), y = 25 - Math.floor(h / 2);
  c.push(rect(x - 2,y,w + 4,h,p.outline), rect(x,y - 2,w - 2,h + 3,p.outline), rect(x,y,w,h,p.body), rect(x+2,y+1,w-4,3,p.light));
  const legCount = Math.max(2, Math.min(6, t.appendageCount));
  for (let i=0;i<legCount;i++) { const lx=x+2+Math.floor(i*(w-5)/Math.max(1,legCount-1)); c.push(...pixelLine(lx,y+h-1,lx+(i%2?2:-1),39,2,p.outline)); }
  drawHead(c,t,p,x+w-1,y+1,s);
}
function drawBiped(c,t,p,s,bulk) {
  const w=Math.round(12*s*bulk),h=Math.round(16*s),x=22-Math.floor(w/2),y=21-Math.floor(h/2);
  c.push(rect(x-2,y,w+4,h,p.outline),rect(x,y,w,h,p.body),rect(x+2,y+1,w-4,3,p.light));
  c.push(...pixelLine(x+3,y+h-1,x,41,2,p.outline),...pixelLine(x+w-4,y+h-1,x+w,41,2,p.outline));
  drawHead(c,t,p,x+w-1,y-2,s);
}
function drawSerpentine(c,t,p,s) {
  const thick=2+Math.round(t.build/35), points=[[7,37],[13,32],[11,25],[20,20],[29,25],[36,19]];
  for(let i=0;i<points.length-1;i++) c.push(...pixelLine(...points[i],...points[i+1],thick,p.outline));
  for(let i=1;i<points.length-1;i++) c.push(rect(points[i][0]+1,points[i][1]+1,Math.max(1,thick-2),Math.max(1,thick-2),p.body));
  drawHead(c,t,p,35,15,s);
}
function drawSegmented(c,t,p,s) {
  const count=4+Math.round(t.appendageCount/2), segment=Math.round(5*s);
  for(let i=0;i<count;i++){const x=5+i*(segment-1),y=24+(i%2?2:0);c.push(rect(x,y,segment+2,segment+4,p.outline),rect(x+1,y+1,segment,segment+2,i%2?p.shadow:p.body));if(t.appendageType==="limbed")c.push(...pixelLine(x+2,y+segment+3,x,39,1,p.outline));}
  drawHead(c,t,p,5+count*(segment-1)-2,22,s);
}
function drawRadial(c,t,p,s) {
  const r=Math.round(8*s),cx=23,cy=25;c.push(rect(cx-r,cy-r,r*2,r*2,p.outline),rect(cx-r+2,cy-r+2,r*2-4,r*2-4,p.body));
  const arms=Math.max(4,t.appendageCount);for(let i=0;i<arms;i++){const a=i/arms*Math.PI*2;c.push(...pixelLine(cx,cy,Math.round(cx+Math.cos(a)*17),Math.round(cy+Math.sin(a)*17),2,p.accent));}
}
function drawPiscine(c,t,p,s) {
  const w=Math.round(21*s),h=Math.round(12*s),x=20-Math.floor(w/2),y=26-Math.floor(h/2);c.push(rect(x,y,w,h,p.outline),rect(x+2,y+2,w-3,h-4,p.body));
  c.push(...pixelLine(x,y+h/2,x-7,y-5,2,p.accent),...pixelLine(x,y+h/2,x-7,y+h+5,2,p.accent));drawHead(c,t,p,x+w-2,y+2,s);
}
function drawWinged(c,t,p,s) {
  const x=19,y=20,w=Math.round(12*s),h=Math.round(14*s);c.push(rect(x,y,w,h,p.outline),rect(x+2,y+2,w-4,h-3,p.body));
  const wingColor=t.appendageType==="feathered"?p.light:p.accent;c.push(...pixelLine(x+2,y+5,4,8,3,wingColor),...pixelLine(x+w-2,y+5,43,8,3,wingColor));drawHead(c,t,p,x+w-1,y-2,s);
}
function drawAmorphous(c,t,p,s) {
  const w=Math.round(20*s),h=Math.round(14*s),x=22-Math.floor(w/2),y=34-h;c.push(rect(x-2,y+4,w+4,h-4,p.outline),rect(x,y,w,h,p.body),rect(x+4,y-3,w-9,5,p.light));
  for(let i=0;i<3;i++)c.push(rect(x+2+i*6,y+h-1,3,4+(i%2),p.shadow));
}
function drawHead(c,t,p,x,y,s) {
  const head=5+Math.round(t.size/30);c.push(rect(x,y,head+2,head+2,p.outline),rect(x+1,y+1,head,head,p.body));addSense(c,t,p,x+head-1,y+2,2);drawArmament(c,t,p,x+head+1,y+head-1);
}
function drawArmament(c,t,p,x,y) {
  const arm=dominantArmament(t), reach=t.reach==="far"?10:t.reach==="mid"?6:3;
  if(arm.value<18)return;
  if(arm.kind==="pierce")c.push(...pixelLine(x,y,x+reach,y-2,2,p.accent));
  if(arm.kind==="crush")c.push(rect(x,y-2,reach-1,5,p.outline),rect(x+reach-3,y-3,5,7,p.accent));
  if(arm.kind==="rend"){const claws=t.delivery==="multi"?3:2;for(let i=0;i<claws;i++)c.push(...pixelLine(x,y+i*3,x+reach,y+i*2,1,p.accent));}
  if(t.delivery==="area")c.push(rect(x+reach-1,y-5,3,11,alpha(p.accent,115)));
}
function dominantArmament(t) { const values=[{kind:"pierce",value:t.pierce},{kind:"crush",value:t.crush},{kind:"rend",value:t.rend}]; return values.sort((a,b)=>b.value-a.value)[0]; }
function addFightSurface(c,d,p,random) {
  const t=d.traits, bounds={x:12,y:17,w:18,h:12};
  if(t.coveringHardness>25){const plates=1+Math.round(t.coveringCoverage/20);for(let i=0;i<plates;i++)c.push(rect(bounds.x+i*3,bounds.y+(i%2),2+(t.coveringHardness>70?1:0),2,p.light));}
  if(t.coveringLength>25){const tufts=1+Math.round(t.coveringCoverage/18);for(let i=0;i<tufts;i++){const x=bounds.x+i*3;c.push(...pixelLine(x,bounds.y,x-1,bounds.y-1-Math.round(t.coveringLength/25)-Math.round(random()),1,p.light));}}
  if(t.boneDensity>20){const bands=1+Math.round(t.boneDensity/28);for(let i=0;i<bands;i++)c.push(rect(bounds.x+i*5,bounds.y+bounds.h-2,3,2,p.shadow));}
  addPattern(c,t,p,bounds.x,bounds.y+4,bounds.w,bounds.h-5,2);
  if(t.ornament>35){const count=1+Math.round(t.ornament/25);for(let i=0;i<count;i++)c.push(...pixelLine(16+i*4,15,15+i*4,10-(i%2)*2,2,p.accent));}
  // Defence branches may shape authored traits, but do not receive a private mechanical badge.
  if(t.defence==="aposematism")for(let i=0;i<4;i++)c.push(rect(13+i*5,22,2,8,p.accent));
  addFightAppendageType(c,t,p);
}
function addFightAppendageType(c,t,p){
  const amount=Math.max(1,Math.round(t.appendageCount/2));
  if(t.appendageType==="finned")for(let i=0;i<amount;i++)c.push(...pixelLine(14+i*4,27,12+i*4,20-(i%2)*2,2,p.accent));
  if(t.appendageType==="feathered")for(let i=0;i<amount;i++)c.push(...pixelLine(15+i*3,25,8+i*3,15-(i%2)*2,2,p.light));
  if(t.appendageType==="membrane")for(let i=0;i<Math.min(3,amount);i++)c.push(rect(9+i*8,15+i,8,3,p.accent));
}
function addPattern(c,t,p,x,y,w,h,unit) {
  if(t.patterning<20)return;
  const count=1+Math.round(t.patterning/20);
  if(t.defence==="crypsis"){for(let i=0;i<count;i++)c.push(rect(x+(i*3)%w,y+(i*2)%Math.max(1,h),unit*2,unit,p.shadow));}
  else {for(let i=0;i<count;i++)c.push(rect(x+(i*4)%w,y,unit,Math.max(unit,h),i%2?p.accent:p.shadow));}
}
function addSense(c,t,p,x,y,unit) {
  // Disclosure-neutral target marker. Exact sensory allocation is inferred information and must
  // not become a standardized eye/antenna/heat-organ code in exported pixels.
  c.push(rect(x,y,unit,unit,p.sense));
}
function alpha(color, alphaByte) { return color.replace(")", ` / ${Math.round(Math.min(255,alphaByte)/255*100)}%)`); }

export function compatibilityWarnings(raw) {
  const t=normalizeDescriptor(raw).traits,w=[];
  if(t.appendageType==="none"&&t.appendageCount>0)w.push("Appendage count is ignored while appendage type is none.");
  if(t.topology==="piscine"&&!["finned","none"].includes(t.appendageType))w.push("Piscine bodies read most clearly with finned or no appendages.");
  if(t.topology==="winged"&&!['feathered','membrane'].includes(t.appendageType))w.push("Winged bodies read most clearly with feathered or membrane appendages.");
  if(t.opacity<25&&t.coveringHardness>70)w.push("Very transparent, very hard covering needs an authored material treatment.");
  if(t.emanationStrength===0)w.push("Emanation kind is dormant while strength is zero.");
  return w;
}

export function anatomySummary(raw) {
  const t=normalizeDescriptor(raw).traits,arm=dominantArmament(t),sense=[['vision',t.vision],['mechanical',t.mechano],['chemical',t.chemo],['thermal',t.thermo]].sort((a,b)=>b[1]-a[1])[0][0];
  const covering=t.coveringHardness>65?'plated':t.coveringLength>60?'long-covered':t.coveringCoverage<25?'bare':'soft-covered';
  const scale=t.size>72?'large':t.size<34?'small':'medium';
  return `${scale} ${covering} ${t.topology}; ${t.appendageCount} ${t.appendageType} appendages; ${arm.kind} armament at ${t.reach} reach; ${sense}-led senses; ${t.defence} defence${t.toxic?'; toxic':''}${t.emanationStrength>0?`; ${t.emanationKind} emanation`:''}.`;
}

export function populationDescriptors(raw,count=24,mode="ecosystem") {
  const base=normalizeDescriptor(raw), random=rng(base.speciesSeed^0x50f17), topologies=traitDefinitions.find(x=>x.key==="topology").options, appendages=traitDefinitions.find(x=>x.key==="appendageType").options;
  return Array.from({length:count},(_,index)=>{const d=cloneDescriptor(base);d.specimenSeed=(base.specimenSeed+index*2654435761)>>>0;if(mode==="ecosystem"){d.speciesSeed=(base.speciesSeed+index*2246822519)>>>0;d.traits.topology=topologies[index%topologies.length];d.traits.appendageType=appendages[Math.floor(random()*appendages.length)];for(const key of ["size","build","coveringHardness","coveringLength","appendageCount","pierce","crush","rend","patterning","ornament"])d.traits[key]=Math.floor(random()*101);}return normalizeDescriptor(d);});
}

export function terrainCommands(kind,seed=1) {
  const random=rng(seed^Number.parseInt(hash(String(kind)),16)),palettes={soil:["#4a3828","#654a30","#84613d"],water:["#183d56","#245c73","#3b7e8d"],stone:["#393a3d","#56585b","#74777a"]},colors=palettes[kind]??palettes.soil,c=[rect(0,0,16,16,colors[1])];
  for(let i=0;i<22;i++){const x=Math.floor(random()*16),y=Math.floor(random()*16),width=kind==="water"?2+Math.floor(random()*4):1+Math.floor(random()*2);c.push(rect(x,y,Math.min(width,16-x),1,colors[random()>.55?2:0]));}return c;
}
export function floraCommands(raw) { const d=normalizeDescriptor(raw),random=rng(d.speciesSeed^0xf10a),p=paletteFor(d),c=terrainCommands("soil",d.speciesSeed);for(let stem=0;stem<5;stem++){const x=2+stem*3+Math.floor(random()*2),height=3+Math.floor(random()*5);c.push(rect(x,14-height,1,height,p.shadow),rect(x-1,13-height,3,2,p.accent));}return c; }
export function renderCommands(context,width,height,commands){context.clearRect(0,0,width,height);context.imageSmoothingEnabled=false;for(const command of commands){if(command.op!=="rect")continue;context.fillStyle=command.color;context.fillRect(command.x,command.y,command.w,command.h);}}
