import { readFile } from "node:fs/promises";
import { defaults,cloneDescriptor,creatureCommands,presets,hash,canonicalJSON } from "../src/generator.js";
import { floraDefaults,floraCommands,transitionedTerrainCommands } from "../src/world-generator.js";
import { combatFixture,combatMetrics,validateCombatFixture,allCombatPositions,hitRect,rectsOverlap } from "../src/combat-generator.js";
import { tileContentTypes,tileContentCommands,minimapContentCommands } from "../src/tile-content.js";
import { characterCommands,binderTemplate,namedCharacterCatalogue } from "../src/character-kit.js";
import { resourceCatalogue,resourceWorldCommands,resourceMinimapCommands } from "../src/resource-kit.js";
import { splashProofWorld,emptySplashDisclosure,splashCommands } from "../src/splash-kit.js";
import { launchCommands } from "../src/launch-kit.js";
import { rasterHash } from "../src/regression.js";

const baseline=JSON.parse(await readFile(new URL("../fixtures/golden-v1.json",import.meta.url),"utf8"));
const current={};
for(const [name,traits] of Object.entries(presets)){const d=cloneDescriptor(defaults);d.logicalID=name;d.traits=cloneDescriptor(traits);for(const [profile,size] of [["world",16],["fight",48]])current[`creature/${name}/${profile}`]=rasterHash(creatureCommands(d,profile),size,size);}
const floraFixtures={ordinary:floraDefaults,low_spreading:{...floraDefaults,speciesSeed:71,traits:{...floraDefaults.traits,stature:18,habit:"spreading"}},active:{...floraDefaults,speciesSeed:72,traits:{...floraDefaults.traits,defenceType:"active",defence:90}}};
for(const [name,d] of Object.entries(floraFixtures))for(const [profile,size] of [["world",16],["detail",48],["hostile",48]])current[`flora/${name}/${profile}`]=rasterHash(floraCommands(d,profile),size,size);
for(const ground of ["soil","water","deepWater"])for(const adjacency of [0,5,10,15])current[`terrain/${ground}/${adjacency}`]=rasterHash(transitionedTerrainCommands({ground,adjacency,revealed:true,terrainSeedUInt32:404}),16,16);
current["terrain/fog"]=rasterHash(transitionedTerrainCommands({ground:"water",revealed:false}),16,16);
current["terrain/crack"]=rasterHash(transitionedTerrainCommands({ground:"soil",revealed:true,cracking:true}),16,16);
for(const type of tileContentTypes){current[`content/${type}/world`]=rasterHash(tileContentCommands({type,revealed:true,discovered:true}),16,16);current[`content/${type}/minimap`]=rasterHash(minimapContentCommands({type,revealed:true,discovered:true}),4,4);}
current["content/portal/exit-world"]=rasterHash(tileContentCommands({type:"portal",portalDirection:"exit",revealed:true,discovered:true}),16,16);current["content/portal/exit-minimap"]=rasterHash(minimapContentCommands({type:"portal",portalDirection:"exit",revealed:true,discovered:true}),4,4);
for(const [index,ground] of ["mud","growth","rubble","chasm"].entries()){const content=index<3?tileContentCommands({type:["hazard","traveller","site"][index],revealed:true,discovered:true}):[],route=index<3?[{op:"rect",x:1,y:6,w:14,h:4,color:"#e1c06f"}]:[];current[`content/collision/${ground}`]=rasterHash([...transitionedTerrainCommands({ground,revealed:true,terrainSeedUInt32:500+index}),...route,...content],16,16);}
for(const id of ["rubble","clay","ore","copper","silver","quartz","obsidian","mercury","adamant","fiber","resin","ichor","rift_glass"]){const resource=resourceCatalogue.find(item=>item.id===id),environment=resource.sourceClass==="unstableSubstrate"?"unstable":"stone";current[`resource/${id}/remaining`]=rasterHash(resourceWorldCommands(id,{environment}),16,16);current[`resource/${id}/exhausted`]=rasterHash(resourceWorldCommands(id,{environment,state:"exhausted"}),16,16);}
current["resource/quartz/minimap"]=rasterHash(resourceMinimapCommands("quartz",{revealed:true,discovered:true}),4,4);current["resource/quartz/minimap-exhausted"]=rasterHash(resourceMinimapCommands("quartz",{revealed:true,discovered:true,state:"exhausted"}),4,4);
current["resource/essence_raw/world-delegated"]=rasterHash(tileContentCommands({type:"wildDrop",revealed:true,discovered:true}),16,16);current["resource/mote/no-world"]=rasterHash(resourceWorldCommands("mote"),16,16);current["resource/mote/no-minimap"]=rasterHash(resourceMinimapCommands("mote",{revealed:true,discovered:true}),4,4);
const splashRequest=(transition,continuity="transient",disclosure=emptySplashDisclosure)=>({transition,continuity,world:splashProofWorld,disclosure});
for(const transition of ["entry","portal","waystone","defeat","collapse"])current[`splash/${transition}/transient`]=rasterHash(splashCommands(splashRequest(transition)),160,100);
current["splash/portal/anchored"]=rasterHash(splashCommands(splashRequest("portal","anchored")),160,100);
current["splash/entry/disclosed"]=rasterHash(splashCommands(splashRequest("entry","transient",{siteProfile:"signal_cairn",apexLocationKnown:true})),160,100);
for(const theme of ["light","dark"])current[`launch/${theme}`]=rasterHash(launchCommands(theme),390,844);
for(const {id} of namedCharacterCatalogue){current[`character/${id}/world`]=rasterHash(characterCommands(id,{profile:"world"}),16,16);current[`character/${id}/combat`]=rasterHash(characterCommands(id,{profile:"combat"}),48,48);current[`character/${id}/prone`]=rasterHash(characterCommands(id,{profile:"combat",pose:"passedOut"}),48,48);}
for(const seed of [41,42,43,44])for(const [profile,size] of [["world",16],["combat",48]])current[`character/generated-${seed}/${profile}`]=rasterHash(characterCommands("generated_person",{profile,generatedSeed:seed}),size,size);
for(const [profile,size] of [["world",16],["combat",48]])current[`character/binder/${profile}`]=rasterHash(characterCommands("binder",{profile,descriptor:binderTemplate}),size,size);current["character/binder/prone"]=rasterHash(characterCommands("binder",{profile:"combat",pose:"passedOut",descriptor:binderTemplate}),48,48);
for(const grade of ["warm","cold"])current[`character/mara/grade-${grade}`]=rasterHash(characterCommands("mara",{profile:"combat",environmentGrade:grade}),48,48);
for(const id of ["mara","tovin"])for(const facing of ["north","east","south","west"])current[`character/${id}/mapTopDown-${facing}`]=rasterHash(characterCommands(id,{profile:"mapTopDown",facing}),16,16);
for(const id of ["halloway","isolde","wren","ashe"])current[`character/${id}/mapTopDown-north`]=rasterHash(characterCommands(id,{profile:"mapTopDown",facing:"north"}),16,16);
for(const seed of [41,42,43])current[`character/generated-${seed}/mapTopDown-north`]=rasterHash(characterCommands("generated_person",{profile:"mapTopDown",generatedSeed:seed,facing:"north"}),16,16);
for(const facing of ["north","east","south","west"])current[`character/binder/mapTopDown-${facing}`]=rasterHash(characterCommands("binder",{profile:"mapTopDown",facing,descriptor:binderTemplate}),16,16);
for(const gear of ["blade","spear","bow","lightArmor","heavyArmor"])current[`character/halloway/gear-${gear}`]=rasterHash(characterCommands("halloway",{profile:"combat",gear}),48,48);current["character/halloway/prone-blade"]=rasterHash(characterCommands("halloway",{profile:"combat",pose:"passedOut",gear:"blade"}),48,48);
for(const mode of ["5v3","2v1"]){const fixture=combatFixture(mode),issues=validateCombatFixture(fixture);if(issues.length)throw new Error(`Invalid combat ${mode}: ${issues.join(", ")}`);current[`combat/${mode}/contract`]=hash(canonicalJSON(fixture));}
const positions=allCombatPositions();for(let a=0;a<positions.length;a++)for(let b=a+1;b<positions.length;b++)if(rectsOverlap(hitRect(positions[a]),hitRect(positions[b])))throw new Error(`Combat hit ownership overlap: ${positions[a].id}/${positions[b].id}`);
current["combat/metrics"]=hash(canonicalJSON(combatMetrics));

const keys=new Set([...Object.keys(baseline.hashes),...Object.keys(current)]),changes=[];
for(const key of [...keys].sort())if(baseline.hashes[key]!==current[key])changes.push({key,before:baseline.hashes[key]??null,after:current[key]??null});
console.log(JSON.stringify({baselineVersion:baseline.baselineVersion,checked:Object.keys(current).length,changed:changes.length,changes},null,2));
if(changes.length)process.exitCode=1;
