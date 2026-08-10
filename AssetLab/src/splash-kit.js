import {fitCommands,hash} from "./generator.js";
import {siteCommands} from "./place-kit.js";

const rect=(x,y,w,h,color)=>({op:"rect",x,y,w,h,color});
export const splashTransitions=Object.freeze(["entry","portal","waystone","defeat","collapse"]);
export const reservedSplashTransitions=Object.freeze(["abandon"]);
export const continuityModes=Object.freeze(["transient","anchored"]);
export const splashTerrains=Object.freeze(["water","soil","ice","ash"]);
export const splashLights=Object.freeze(["dim","bright"]);
export const splashFloraClasses=Object.freeze(["none","low","tall"]);
export const disclosedSiteProfiles=Object.freeze(["salt_pan","wind_carved_gallery","rootbound_sink","obsidian_vent","flooded_causeway","signal_cairn"]);
export const splashProofWorld=Object.freeze({terrain:"water",light:"dim",floraClass:"tall"});
export const emptySplashDisclosure=Object.freeze({siteProfile:null,apexLocationKnown:false});

const palettes={water:{dark:"#253b49",body:"#41697a",light:"#7da4a8"},soil:{dark:"#473728",body:"#795f43",light:"#b18d5e"},ice:{dark:"#354d58",body:"#7197a1",light:"#c2d9d8"},ash:{dark:"#39363a",body:"#6d696d",light:"#ada5a1"}};
const hasOnly=(value,keys)=>value&&typeof value==="object"&&!Array.isArray(value)&&Object.keys(value).every(key=>keys.includes(key));

export function validateSplashRequest({transition,continuity,world,disclosure,allowNoncanonical=false}={}){
  const issues=[];
  if(typeof allowNoncanonical!=="boolean")issues.push("invalid-noncanonical-flag");
  if(!splashTransitions.includes(transition)&&!(allowNoncanonical&&reservedSplashTransitions.includes(transition)))issues.push(reservedSplashTransitions.includes(transition)?"reserved-transition-requires-noncanonical":"unknown-transition");
  if(!continuityModes.includes(continuity))issues.push("unknown-continuity");
  if(!hasOnly(world,["terrain","light","floraClass"]))issues.push("invalid-world-fields");
  else {if(!splashTerrains.includes(world.terrain))issues.push("unknown-terrain");if(!splashLights.includes(world.light))issues.push("unknown-light");if(!splashFloraClasses.includes(world.floraClass))issues.push("unknown-flora-class");}
  if(!hasOnly(disclosure,["siteProfile","apexLocationKnown"]))issues.push("invalid-disclosure-fields");
  else {if(disclosure.siteProfile!==null&&!disclosedSiteProfiles.includes(disclosure.siteProfile))issues.push("unknown-site-profile");if(typeof disclosure.apexLocationKnown!=="boolean")issues.push("invalid-apex-location-knowledge");}
  return issues;
}

function frame(p){return[rect(2,2,156,96,"#d8bd82"),rect(6,6,148,88,"#171614"),rect(10,10,140,80,p.dark)];}
function intactScene(world,disclosure){const p=palettes[world.terrain],c=[...frame(p),rect(10,54,140,36,p.body),rect(10,72,140,18,p.light),rect(10,10,140,18,world.light==="dim"?"#262633":"#6f8792")];if(world.floraClass==="tall")for(const x of [22,42,118,136])c.push(rect(x,42,4,30,"#36543a"),rect(x-5,38,14,7,"#5e7d52"));if(world.floraClass==="low")for(const x of [20,52,104,132])c.push(rect(x,66,14,6,"#59794e"));if(disclosure.siteProfile)c.push(...siteCommands(disclosure.siteProfile,{palette:"warm"}).map(command=>({...command,x:command.x+108,y:command.y+48})));if(disclosure.apexLocationKnown)c.push(rect(138,18,6,6,"#d8bd82"));return c;}
export function splashCommands(request={}){if(!hasOnly(request,["transition","continuity","world","disclosure","allowNoncanonical"]))throw new Error("invalid-splash-request:invalid-request-fields");const {transition,continuity,world,disclosure,allowNoncanonical=false}=request,issues=validateSplashRequest({transition,continuity,world,disclosure,allowNoncanonical});if(issues.length)throw new Error(`invalid-splash-request:${issues.join(",")}`);const c=intactScene(world,disclosure);if(transition==="entry")c.push(rect(74,72,12,12,"#d8bd82"),rect(77,75,6,6,"#171614"));if(transition==="portal")c.push(rect(68,58,24,28,"#72b5ad"),rect(74,64,12,16,"#171614"));if(transition==="waystone")c.push(rect(140,82,7,7,"#9587bd"),rect(142,84,3,3,"#d8bd82"));if(transition==="defeat")c.push(rect(68,66,24,3,"#d8bd82"),rect(72,60,16,3,"#d8bd82"),rect(76,54,8,3,"#d8bd82"),rect(78,48,4,3,"#d8bd82"));if(transition==="collapse")c.push(rect(28,62,8,28,"#171614"),rect(60,54,10,36,"#171614"),rect(104,65,7,25,"#171614"),rect(132,58,8,32,"#171614"));if(transition==="abandon")c.push(rect(66,40,28,28,"#282525"),rect(70,44,20,20,"#171614"));if(continuity==="anchored")c.push(rect(152,18,4,58,"#d8bd82"),rect(152,14,7,8,"#d8bd82"));return fitCommands(c,160,100,0);}
export function splashHash(commands){return hash(commands);}
