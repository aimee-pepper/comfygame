import {fitCommands,hash} from "./generator.js";
import {resourceInventoryIconCommands} from "./resource-kit.js";
import {itemIconCommands} from "./item-kit.js";

const rect=(x,y,w,h,color)=>({op:"rect",x,y,w,h,color}),ink="#171614",light="#eee5d5",metal="#aeb5b2",cloth="#8d6648",glass="#9bc4b7",fluid="#8fbc83",sampleAccent="#d8bd82";
export const economyIdentityContract=Object.freeze({version:"economy-identity-bridge-1.1.0",evidenceRole:"assetCorrespondenceFixture",integrationReady:false,contexts:Object.freeze(["inventory","tradingPost","recycler","blacksmith"]),identityKinds:Object.freeze(["resourceStack","worldMaterialSpecimen","ordinaryItem","foundGear","craftedGear"]),playerFacingCategory:"world resources"});
export const economyIdentityFixtures=Object.freeze([
  Object.freeze({key:"resource:rubble",identityKind:"resourceStack",resourceID:"rubble",quantity:7,name:"Rubble ×7",family:"rubble",resolvedDetail:"world resource pool"}),
  Object.freeze({key:"material:quill:value-fixture",identityKind:"worldMaterialSpecimen",materialKind:"quill",properties:Object.freeze({hardness:48,density:22,insulation:8,flexibility:36,lustre:52,reactivity:4}),grade:64,source:"glassy browser",qualifier:"glassy",name:"Fine glassy quill",family:"quillSpecimen",resolvedDetail:"World resource · glassy quill · individual specimen"}),
  Object.freeze({key:"item:salve_lesser:801",identityKind:"ordinaryItem",stackInstanceIDUInt64:"801",catalogID:"salve_lesser",quantity:2,name:"Lesser Salve ×2",family:"salve",resolvedDetail:"ordinary identified consumable"}),
  Object.freeze({key:"gear:blade_chipped:802",identityKind:"foundGear",stackInstanceIDUInt64:"802",catalogID:"blade_chipped",name:"Chipped Blade",family:"foundBlade",gearProfile:Object.freeze({version:1,stableInstanceIDUInt64:"802",familyID:null,recipeVersion:null,constructionTier:1,reforgeRank:0,legacyPowerCredit:0,slot:"weapon",damage:"rend",reach:"close",insulation:0,reactivity:0,consumedMaterials:Object.freeze([]),specialistProfile:null,displayProvenance:null,authoredUniqueRuleID:null}),resolvedDetail:"Authored salvage route · forged_edge_v1"}),
  Object.freeze({key:"gear:pointed_blade:9001",identityKind:"craftedGear",stackInstanceIDUInt64:"9001",catalogID:"blade_chipped",name:"Pointed Blade",family:"craftedBlade",gearProfile:Object.freeze({version:1,stableInstanceIDUInt64:"9001",familyID:"pointed_blade",recipeVersion:1,constructionTier:2,reforgeRank:0,legacyPowerCredit:0,slot:"weapon",damage:"pierce",reach:"close",insulation:4,reactivity:3,consumedMaterials:Object.freeze([Object.freeze({kind:"quill",properties:Object.freeze({hardness:48,density:22,insulation:8,flexibility:36,lustre:52,reactivity:4}),grade:64,source:"glassy browser",qualifier:"glassy"}),Object.freeze({kind:"fibre",properties:Object.freeze({hardness:12,density:18,insulation:24,flexibility:58,lustre:16,reactivity:3}),grade:51,source:"threaded groundcover",qualifier:"supple"})]),specialistProfile:"blacksmith",displayProvenance:"Pointed Blade · glassy browser + threaded groundcover",authoredUniqueRuleID:null}),resolvedDetail:"Pointed Blade · exact ordered two-material construction receipt"})
]);

function ordinarySalve(){return fitCommands([rect(11,5,10,4,ink),rect(13,3,6,3,metal),rect(9,9,14,17,glass),rect(11,12,10,11,fluid),rect(13,15,6,3,light)],32,32,1);}
function foundBlade(){return fitCommands([rect(14,4,4,8,light),rect(13,12,4,7,light),rect(11,19,10,3,metal),rect(14,22,4,7,cloth),rect(17,4,3,3,ink)],32,32,1);}
function craftedBlade(){return fitCommands([rect(15,2,2,2,light),rect(13,4,6,17,light),rect(11,20,10,3,metal),rect(14,23,4,6,cloth),rect(15,8,2,9,metal),rect(10,21,2,2,sampleAccent),rect(20,21,2,2,sampleAccent)],32,32,1);}
function resourceStackIcon(id){return resourceInventoryIconCommands(id).map(command=>({...command,x:command.x*2,y:command.y*2,w:command.w*2,h:command.h*2}));}
function quillSpecimen(){return fitCommands([...itemIconCommands("sample"),rect(20,5,3,12,"#c9d6d2"),rect(23,7,2,8,"#8aa6a0"),rect(19,5,5,2,light)],32,32,1);}
const fieldsByKind=Object.freeze({resourceStack:["family","identityKind","key","name","quantity","resolvedDetail","resourceID"],worldMaterialSpecimen:["family","grade","identityKind","key","materialKind","name","properties","qualifier","resolvedDetail","source"],ordinaryItem:["catalogID","family","identityKind","key","name","quantity","resolvedDetail","stackInstanceIDUInt64"],foundGear:["catalogID","family","gearProfile","identityKind","key","name","resolvedDetail","stackInstanceIDUInt64"],craftedGear:["catalogID","family","gearProfile","identityKind","key","name","resolvedDetail","stackInstanceIDUInt64"]});
export function economyIdentityCommands(identity){
  if(!identity||typeof identity!=="object"||Array.isArray(identity))throw new Error("invalid-economy-identity");
  const expected=fieldsByKind[identity.identityKind],actual=Object.keys(identity).sort();if(!expected||JSON.stringify(actual)!==JSON.stringify([...expected].sort()))throw new Error("unknown-or-missing-economy-identity-field");
  const canonical=economyIdentityFixtures.find(item=>item.key===identity.key);if(!canonical||JSON.stringify(canonical)!==JSON.stringify(identity))throw new Error(`unknown-or-drifted-economy-identity:${identity.key}`);
  if(identity.identityKind==="resourceStack")return resourceStackIcon(identity.family);
  if(identity.identityKind==="worldMaterialSpecimen")return quillSpecimen();
  if(identity.identityKind==="ordinaryItem")return ordinarySalve();
  if(identity.identityKind==="foundGear")return foundBlade();
  if(identity.identityKind==="craftedGear")return craftedBlade();
  throw new Error(`unknown-economy-identity-kind:${identity.identityKind}`);
}
export const economyIdentityHash=identity=>hash(economyIdentityCommands(identity));
export const economyIdentityKey=identity=>identity.identityKind==="resourceStack"?`ResourceID:${identity.resourceID}`:identity.identityKind==="worldMaterialSpecimen"?`MaterialValue:${identity.materialKind}:${identity.source}:${identity.qualifier}`:`InstanceID:${identity.stackInstanceIDUInt64}`;
function contextHandle(context,identity){if(identity.identityKind!=="worldMaterialSpecimen")return economyIdentityKey(identity);if(context==="inventory")return"bin 4 · entry 2";if(context==="tradingPost")return"not individually transferable";if(context==="recycler")return"preview revision 22 · return 0";return"craft preview · bin 4 · entry 2";}
export function economyContextRows(context){if(!economyIdentityContract.contexts.includes(context))throw new Error(`unknown-economy-context:${context}`);return economyIdentityFixtures.map(identity=>Object.freeze({context,identity,contextHandle:contextHandle(context,identity),commands:economyIdentityCommands(identity)}));}
