import assert from "node:assert/strict";
import { defaults } from "../src/generator.js";
import { floraDefaults } from "../src/world-generator.js";
import { creatureLiveContract,floraLiveContract } from "../src/live-contract.js";
const creature=creatureLiveContract(defaults);assert.equal("topology" in creature.gameIdentity,false);assert.equal(creature.renderHints.topology,defaults.traits.topology);assert.equal(Math.round(Object.values(creature.gameIdentity.finish).reduce((a,b)=>a+b,0)),100);assert.equal(Math.round(Object.values(creature.gameIdentity.sensory).reduce((a,b)=>a+b,0)),100);assert.equal(creature.gameIdentity.emanation,null);assert.deepEqual(creature.adapterDiagnostics,[]);
const glowing=creatureLiveContract({...defaults,traits:{...defaults.traits,emanationStrength:70,emanationLight:10,emanationHeat:80,emanationCaustic:10}});assert.equal(glowing.gameIdentity.emanation.heat,80);assert.equal(glowing.adapterDiagnostics.length,0);
const migrated=creatureLiveContract({schemaVersion:3,traits:{emanationStrength:70,emanationKind:"heat"}});assert.equal(migrated.gameIdentity.emanation.heat,70);assert.equal(migrated.adapterDiagnostics[0].code,"assumed-emanation-allocation");
const flora=floraLiveContract(floraDefaults);assert.equal(Math.round(flora.gameIdentity.tissue.woody+flora.gameIdentity.tissue.fibrous+flora.gameIdentity.tissue.fleshy),floraDefaults.traits.tissueAmount);assert.equal(Math.round(Object.values(flora.gameIdentity.finish).reduce((a,b)=>a+b,0)),100);
console.log("Asset Lab live-contract adapter tests passed.");
