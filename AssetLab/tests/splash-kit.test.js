import assert from "node:assert/strict";
import {splashProofWorld,emptySplashDisclosure,splashTransitions,reservedSplashTransitions,splashCommands,splashHash,validateSplashRequest} from "../src/splash-kit.js";
import {commandBounds} from "../src/generator.js";

const request=(transition,continuity="transient")=>({transition,continuity,world:{...splashProofWorld},disclosure:{...emptySplashDisclosure}});
const hashes=[];
for(const transition of splashTransitions){const commands=splashCommands(request(transition)),bounds=commandBounds(commands);assert.ok(bounds.minX>=0&&bounds.minY>=0&&bounds.maxX<=160&&bounds.maxY<=100);hashes.push(splashHash(commands));}
assert.equal(new Set(hashes).size,splashTransitions.length);
assert.deepEqual(reservedSplashTransitions,["abandon"]);
assert.throws(()=>splashCommands(request("abandon")),/reserved-transition-requires-noncanonical/);
assert.doesNotThrow(()=>splashCommands({...request("abandon"),allowNoncanonical:true}));
assert.throws(()=>splashCommands({...request("entry"),world:{...splashProofWorld,atmosphere:"clear"}}),/invalid-world-fields/);
assert.throws(()=>splashCommands({...request("entry"),disclosure:{siteProfile:"vault",apexLocationKnown:false}}),/unknown-site-profile/);
assert.throws(()=>splashCommands({...request("entry"),disclosure:{...emptySplashDisclosure,apexIdentityKnown:true}}),/invalid-disclosure-fields/);
assert.doesNotThrow(()=>splashCommands(request("collapse","anchored")),"an anchored realm persists through collapse");
assert.throws(()=>splashCommands({...request("entry"),extra:true}),/invalid-request-fields/);assert.throws(()=>splashCommands({...request("abandon"),allowNoncanonical:"yes"}),/invalid-noncanonical-flag/);
const entry=splashCommands(request("entry"));assert.deepEqual(entry,splashCommands(request("entry")));const owned=request("portal");const snapshot=structuredClone(owned);splashCommands(owned);assert.deepEqual(owned,snapshot,"renderer must not mutate caller input");
const baseLength=entry.length-2,base=entry.slice(0,baseLength);for(const transition of ["portal","waystone","defeat"]){assert.deepEqual(splashCommands(request(transition)).slice(0,baseLength),base,`${transition} must preserve world geometry`);}assert.deepEqual(splashCommands(request("portal","anchored")).slice(0,baseLength),base,"anchored continuity must preserve world geometry");
assert.notEqual(splashHash(splashCommands(request("portal"))),splashHash(splashCommands(request("portal","anchored"))),"continuity is independent of transition");
const cairn=splashCommands({...request("entry"),disclosure:{siteProfile:"signal_cairn",apexLocationKnown:false}}),pan=splashCommands({...request("entry"),disclosure:{siteProfile:"salt_pan",apexLocationKnown:false}});assert.notEqual(splashHash(cairn),splashHash(pan),"accepted authored site profiles must retain identity");
console.log("Asset Lab splash lifecycle tests passed.");
