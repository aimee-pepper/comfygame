import {fitCommands,hash} from "./generator.js";
const rect=(x,y,w,h,color)=>({op:"rect",x,y,w,h,color});
export const gearSlots=Object.freeze(["weapon","offhand","head","armor","hands","feet","tool","keepsake"]);
export const itemFamilies=Object.freeze(["blade","spear","guard","hood","body","gloves","boots","pick","keepsake","sample"]);
export const itemGridColumns=6;
const ink="#171614",metal="#b8bdba",light="#eee5d5",cloth="#8d6648",accent="#d8bd82";
export function itemIconCommands(family){const c=[];switch(family){case"blade":c.push(rect(14,4,4,19,light),rect(11,20,10,3,metal),rect(14,23,4,6,cloth));break;case"spear":c.push(rect(15,3,2,25,cloth),rect(12,2,8,7,metal));break;case"guard":c.push(rect(7,5,18,19,metal),rect(10,8,12,12,cloth),rect(14,24,4,4,ink));break;case"hood":c.push(rect(8,7,16,17,cloth),rect(11,11,10,10,ink),rect(6,22,20,5,cloth));break;case"body":c.push(rect(8,6,6,5,cloth),rect(18,6,6,5,cloth),rect(6,10,20,17,metal),rect(13,13,6,11,cloth));break;case"gloves":c.push(rect(5,10,9,14,cloth),rect(18,10,9,14,cloth),rect(7,7,5,6,metal),rect(20,7,5,6,metal));break;case"boots":c.push(rect(7,6,7,17,cloth),rect(18,6,7,17,cloth),rect(4,21,11,6,metal),rect(17,21,11,6,metal));break;case"pick":c.push(rect(14,8,4,21,cloth),rect(5,5,22,5,metal),rect(4,7,6,4,light));break;case"keepsake":c.push(rect(14,4,4,24,accent),rect(7,11,18,4,accent),rect(10,7,12,12,ink),rect(13,10,6,6,light));break;case"sample":c.push(rect(7,20,18,6,cloth),rect(10,7,5,14,light),rect(15,4,6,9,light),rect(18,3,5,5,metal));break;default:throw new Error(`unknown-item-family:${family}`);}return fitCommands(c,32,32,1);}
export const itemIconHash=family=>{const occupied=new Set();for(const {x,y,w,h} of itemIconCommands(family))for(let py=y;py<y+h;py++)for(let px=x;px<x+w;px++)occupied.add(`${px},${py}`);return hash([...occupied].sort((a,b)=>{const [ax,ay]=a.split(",").map(Number),[bx,by]=b.split(",").map(Number);return ay-by||ax-bx;}));};
export const catalogueItemVisualVersion="catalogue-item-visual-1.0.0";
export const catalogueItemIDs=Object.freeze([
  "blade_chipped","bone_awl","field_maul","long_pick","split_board","padded_cap","guard_padded","wrapped_hands","worn_boots","bent_pick","pressed_leaf",
  "salve_lesser","salve","salve_greater","draught_clearing","draught_quenching","antidote_broad","stonebark_tonic","venom","firebrand","briar_oil","flashsalt","solvent","lure","stillwater","waystone","torch","farsight_draught",
  "curio_humming_shard","curio_bound_knot"
]);
const green="#79b56f",blue="#72a7c4",red="#b96055",purple="#8d78b2",gold="#d8bd82";
const catalogueShapes=Object.freeze({
  blade_chipped:[[14,3,4,9,light],[12,12,6,5,metal],[14,17,4,7,light],[10,23,12,3,metal],[14,26,4,4,cloth]],
  bone_awl:[[15,2,2,20,light],[12,5,8,3,metal],[13,22,6,7,cloth],[10,26,3,3,light]],
  field_maul:[[6,5,20,8,metal],[4,8,5,7,ink],[23,8,5,7,ink],[14,12,4,18,cloth]],
  long_pick:[[4,7,24,4,metal],[4,10,8,3,light],[14,10,4,20,cloth],[24,5,4,5,metal]],
  split_board:[[5,6,22,20,cloth],[8,9,4,14,light],[15,7,3,18,ink],[21,10,3,12,metal]],
  padded_cap:[[7,11,18,10,cloth],[10,7,12,6,cloth],[5,20,22,4,light],[9,15,14,7,ink]],
  guard_padded:[[7,5,7,6,cloth],[18,5,7,6,cloth],[5,10,22,18,cloth],[9,13,14,12,light],[14,12,4,14,ink]],
  wrapped_hands:[[5,8,8,17,cloth],[19,8,8,17,cloth],[7,5,4,7,light],[21,5,4,7,light],[4,17,10,3,ink],[18,14,10,3,ink]],
  worn_boots:[[6,6,8,18,cloth],[18,7,8,17,cloth],[3,22,12,6,metal],[17,23,12,5,metal],[7,10,6,2,light]],
  bent_pick:[[17,11,4,18,cloth],[7,5,12,4,metal],[5,8,10,4,metal],[10,11,7,3,light],[20,15,5,4,cloth]],
  pressed_leaf:[[15,3,3,26,cloth],[7,7,10,7,green],[17,13,9,8,green],[9,20,8,5,green],[11,10,4,2,light]],
  salve_lesser:[[11,9,10,18,green],[13,5,6,5,light],[9,14,14,4,cloth],[14,17,4,6,light]],
  salve:[[9,8,14,19,green],[12,4,8,5,metal],[7,13,4,9,cloth],[21,13,4,9,cloth],[13,15,6,7,light]],
  salve_greater:[[7,9,18,18,green],[10,5,12,5,light],[13,2,6,4,metal],[5,15,4,8,cloth],[23,15,4,8,cloth],[13,14,6,9,gold]],
  draught_clearing:[[8,11,19,16,blue],[10,6,8,6,metal],[5,14,5,9,light],[18,8,7,4,light],[12,16,9,3,ink]],
  draught_quenching:[[8,7,16,20,blue],[11,3,10,5,light],[5,11,5,6,metal],[22,9,5,9,metal],[12,17,8,4,ink]],
  antidote_broad:[[6,12,20,14,purple],[10,6,12,7,light],[14,2,4,5,metal],[9,16,4,4,ink],[19,16,4,4,ink],[14,21,4,4,ink]],
  stonebark_tonic:[[8,7,16,21,cloth],[11,3,10,5,metal],[5,12,5,12,cloth],[22,12,5,12,cloth],[12,12,8,11,green]],
  venom:[[13,3,6,6,light],[10,8,12,17,purple],[7,22,18,5,purple],[14,12,4,8,ink],[18,16,5,3,light]],
  firebrand:[[12,9,8,19,red],[9,6,14,5,metal],[14,2,4,6,gold],[6,12,6,8,red],[20,12,6,8,red]],
  briar_oil:[[9,7,14,20,gold],[12,3,8,5,metal],[5,14,6,5,green],[21,11,6,5,green],[13,14,6,8,ink]],
  flashsalt:[[7,11,18,16,gold],[11,6,10,6,light],[14,2,4,5,metal],[4,7,5,3,light],[23,6,5,3,light],[14,15,4,8,ink]],
  solvent:[[12,4,8,5,metal],[11,8,10,20,blue],[7,12,5,3,light],[20,17,6,3,light],[14,13,4,10,ink]],
  lure:[[8,10,16,16,cloth],[11,5,10,6,metal],[5,15,5,5,red],[22,15,5,5,red],[13,14,6,6,light],[15,25,2,5,cloth]],
  stillwater:[[6,13,20,13,blue],[9,8,14,6,light],[13,4,6,5,metal],[4,19,5,4,blue],[23,16,5,4,blue],[10,18,12,2,ink]],
  waystone:[[14,8,4,21,metal],[7,5,18,4,light],[7,2,4,8,gold],[14,1,4,8,gold],[21,2,4,8,gold],[10,13,12,4,purple],[5,26,22,3,ink]],
  torch:[[14,11,4,19,cloth],[10,6,12,8,red],[12,2,8,7,gold],[8,9,6,6,red],[18,8,6,6,gold]],
  farsight_draught:[[9,8,14,19,purple],[12,3,8,6,light],[5,11,5,5,metal],[22,11,5,5,metal],[12,14,8,6,blue],[14,16,4,2,ink]],
  curio_humming_shard:[[14,2,4,27,light],[9,7,5,6,purple],[18,10,7,5,purple],[7,19,7,5,metal],[18,22,5,4,metal]],
  curio_bound_knot:[[6,7,8,8,gold],[18,7,8,8,gold],[11,12,10,9,cloth],[6,20,8,7,gold],[18,20,8,7,gold],[14,5,4,24,ink]]
});

// Review-only second slice. These are exact catalogue identities, never a generic tier treatment:
// related objects retain construction ancestry where honest, while slot-only counterparts (such as
// Long Pick / Warded Spear and Pressed Leaf / Cold Compass) use their actual object anatomy.
export const tier2CatalogueVisualVersion="catalogue-tier2-proof-0.1.0";
export const tier2CatalogueItemIDs=Object.freeze([
  "blade_keen","raking_edge","banded_mace","warded_spear","banded_buckler","ridged_helm",
  "guard_banded","studded_gloves","shod_boots","balanced_pick","cold_compass"
]);
export const tier2ComparisonPairs=Object.freeze([
  ["blade_chipped","blade_keen"],["bone_awl","raking_edge"],["field_maul","banded_mace"],
  ["long_pick","warded_spear"],["split_board","banded_buckler"],["padded_cap","ridged_helm"],
  ["guard_padded","guard_banded"],["wrapped_hands","studded_gloves"],
  ["worn_boots","shod_boots"],["bent_pick","balanced_pick"],["pressed_leaf","cold_compass"]
]);
const tier2Shapes=Object.freeze({
  blade_keen:[[15,2,3,20,light],[11,5,4,13,metal],[18,3,4,15,metal],[9,21,14,3,light],[14,24,5,6,cloth]],
  raking_edge:[[5,8,18,3,metal],[6,4,4,8,light],[12,3,4,8,light],[18,5,5,7,light],[20,10,4,17,cloth],[16,25,10,4,metal]],
  banded_mace:[[8,4,16,5,metal],[5,9,22,7,cloth],[8,11,16,2,gold],[14,15,4,15,metal],[11,25,10,4,cloth]],
  warded_spear:[[15,2,3,27,cloth],[10,3,13,8,metal],[12,1,8,4,light],[9,13,12,3,purple],[12,24,9,3,metal]],
  banded_buckler:[[7,6,18,20,metal],[10,4,12,4,light],[5,10,4,12,cloth],[23,10,4,12,cloth],[11,10,10,12,ink],[14,13,4,7,light]],
  ridged_helm:[[7,10,18,15,metal],[10,6,12,5,cloth],[14,2,4,8,light],[5,18,5,7,metal],[22,18,5,7,metal],[12,16,8,4,ink]],
  guard_banded:[[6,5,8,7,metal],[18,5,8,7,metal],[4,11,24,17,cloth],[7,14,18,3,light],[10,18,12,8,metal],[14,16,4,12,ink]],
  studded_gloves:[[4,9,10,16,metal],[18,8,10,17,metal],[6,5,6,7,cloth],[20,4,6,7,cloth],[6,14,3,3,light],[20,13,3,3,light],[23,19,3,3,light]],
  shod_boots:[[6,5,8,18,metal],[18,5,8,18,metal],[3,21,12,7,cloth],[17,20,12,8,cloth],[8,9,4,3,light],[20,9,4,3,light],[5,26,11,3,metal]],
  balanced_pick:[[14,8,4,21,cloth],[5,5,22,5,metal],[3,7,7,5,light],[23,7,6,5,light],[12,12,8,3,blue],[11,26,10,3,metal]],
  cold_compass:[[7,7,18,18,metal],[10,4,12,5,light],[12,10,8,12,blue],[15,12,3,8,ink],[10,15,12,3,ink],[14,25,4,4,cloth]]
});
export function tier2CatalogueItemIconCommands(id){const shape=tier2Shapes[id];if(!shape)throw new Error(`unknown-tier2-catalogue-item:${id}`);return fitCommands(shape.map(([x,y,w,h,color])=>rect(x,y,w,h,color)),32,32,1);}
export const tier2CatalogueItemSilhouetteHash=id=>{const occupied=new Set();for(const {x,y,w,h} of tier2CatalogueItemIconCommands(id))for(let py=y;py<y+h;py++)for(let px=x;px<x+w;px++)occupied.add(`${px},${py}`);return hash([...occupied].sort());};

export const tier3CatalogueVisualVersion="catalogue-tier3-proof-0.1.0";
export const tier3CatalogueItemIDs=Object.freeze([
  "ripping_hook","blade_binders","anvilfall","parting_needle","tower_guard","visored_casque",
  "guard_vault","gauntlets_of_hold","longstriders","corebreaker","someones_ring"
]);
export const tier3ComparisonPairs=Object.freeze([
  ["blade_keen","ripping_hook"],["raking_edge","blade_binders"],["banded_mace","anvilfall"],
  ["warded_spear","parting_needle"],["banded_buckler","tower_guard"],["ridged_helm","visored_casque"],
  ["guard_banded","guard_vault"],["studded_gloves","gauntlets_of_hold"],
  ["shod_boots","longstriders"],["balanced_pick","corebreaker"],["cold_compass","someones_ring"]
]);
const tier3Shapes=Object.freeze({
  ripping_hook:[[14,5,4,24,cloth],[8,3,10,4,metal],[5,5,7,8,light],[5,11,4,7,light],[9,16,6,3,metal],[12,26,9,3,ink]],
  blade_binders:[[15,2,3,23,light],[11,4,4,17,metal],[18,5,4,16,purple],[8,22,16,3,cloth],[13,25,7,4,metal]],
  anvilfall:[[6,5,20,10,cloth],[4,8,5,8,metal],[23,8,5,8,metal],[9,15,14,4,light],[14,18,4,12,cloth],[11,26,10,4,metal]],
  parting_needle:[[15,1,2,26,light],[12,5,8,3,metal],[10,19,12,3,metal],[13,22,6,7,cloth],[18,3,4,4,purple]],
  tower_guard:[[6,3,20,26,metal],[9,6,14,20,cloth],[12,4,8,23,light],[5,10,4,14,ink],[23,10,4,14,ink],[14,12,4,9,metal]],
  visored_casque:[[6,9,20,17,metal],[9,5,14,6,light],[12,2,8,5,cloth],[5,16,22,5,ink],[9,18,14,3,light],[8,25,16,4,cloth]],
  guard_vault:[[5,4,8,7,metal],[19,4,8,7,metal],[3,10,26,19,ink],[6,12,20,16,metal],[10,14,12,12,cloth],[14,11,4,17,light]],
  gauntlets_of_hold:[[4,7,11,19,metal],[17,7,11,19,metal],[7,3,6,8,cloth],[19,3,6,8,cloth],[7,13,6,6,ink],[19,13,6,6,ink],[3,23,13,5,light],[16,23,13,5,light]],
  longstriders:[[7,3,6,22,cloth],[19,3,6,22,cloth],[4,22,12,7,metal],[16,21,13,8,metal],[10,8,3,11,light],[19,7,3,12,light],[5,27,12,2,ink]],
  corebreaker:[[14,10,4,20,cloth],[4,5,24,6,metal],[3,8,8,6,ink],[22,8,7,6,ink],[8,3,5,5,light],[19,3,5,5,light],[11,13,10,4,red]],
  someones_ring:[[8,7,16,16,gold],[11,10,10,10,ink],[13,3,6,6,purple],[15,1,2,4,light],[5,20,7,5,cloth],[20,20,7,5,cloth]]
});
export function tier3CatalogueItemIconCommands(id){const shape=tier3Shapes[id];if(!shape)throw new Error(`unknown-tier3-catalogue-item:${id}`);return fitCommands(shape.map(([x,y,w,h,color])=>rect(x,y,w,h,color)),32,32,1);}
export const tier3CatalogueItemSilhouetteHash=id=>{const occupied=new Set();for(const {x,y,w,h} of tier3CatalogueItemIconCommands(id))for(let py=y;py<y+h;py++)for(let px=x;px<x+w;px++)occupied.add(`${px},${py}`);return hash([...occupied].sort());};
export function catalogueItemIconCommands(id){const shape=catalogueShapes[id];if(!shape)throw new Error(`unknown-catalogue-item:${id}`);return fitCommands(shape.map(([x,y,w,h,color])=>rect(x,y,w,h,color)),32,32,1);}
export const unknownItemIconCommands=()=>fitCommands([rect(7,8,18,19,cloth),rect(5,12,22,4,ink),rect(10,5,12,5,light),rect(13,14,6,8,ink),rect(15,16,2,3,light)],32,32,1);
export function resolveCatalogueItemIcon(request){if(!request||typeof request!=="object"||Array.isArray(request))throw new Error("invalid-catalogue-item-request");const expected=["catalogItemID","identified"],actual=Object.keys(request).sort();if(JSON.stringify(actual)!==JSON.stringify(expected))throw new Error("unknown-or-missing-catalogue-item-field");const{catalogItemID,identified}=request;if(typeof catalogItemID!=="string"||typeof identified!=="boolean")throw new Error("invalid-catalogue-item-request");if(!catalogueItemIDs.includes(catalogItemID))throw new Error(`unknown-catalogue-item:${catalogItemID}`);if(!identified){if(!["curio_humming_shard","curio_bound_knot"].includes(catalogItemID))throw new Error(`unidentified-state-not-supported:${catalogItemID}`);return unknownItemIconCommands();}return catalogueItemIconCommands(catalogItemID);}
export const catalogueItemSilhouetteHash=id=>{const occupied=new Set();for(const {x,y,w,h} of catalogueItemIconCommands(id))for(let py=y;py<y+h;py++)for(let px=x;px<x+w;px++)occupied.add(`${px},${py}`);return hash([...occupied].sort());};
export const equipmentFixtures=Object.freeze([
  {id:"pointed-1",name:"Pointed Blade",family:"blade",slot:"weapon",where:"Worn · Mara",delta:"current · 6 damage"},{id:"blade-2",name:"Chipped Blade",family:"blade",slot:"weapon",where:"Stored",delta:"−2 damage"},{id:"spear-3",name:"Long Spear",family:"spear",slot:"weapon",where:"Carried · current world",delta:"+1 damage · unavailable at home"},{id:"blade-4",name:"Pointed Blade",family:"blade",slot:"weapon",where:"Overflow · safe",delta:"+0 damage · Storehouse full"},{id:"guard-5",name:"Padded Guard",family:"guard",slot:"offhand",where:"Stored",delta:"protection known"},{id:"hood-6",name:"Survey Hood",family:"hood",slot:"head",where:"Worn · Isolde",delta:"protection known"},{id:"body-7",name:"Field Coat",family:"body",slot:"armor",where:"Stored",delta:"protection known"},{id:"gloves-8",name:"Work Gloves",family:"gloves",slot:"hands",where:"Stored",delta:"protection known"},{id:"boots-9",name:"Field Boots",family:"boots",slot:"feet",where:"Stored",delta:"protection known"},{id:"pick-10",name:"Delver Pick",family:"pick",slot:"tool",where:"Stored",delta:"no gear comparison"},{id:"keep-11",name:"Quill Keepsake",family:"keepsake",slot:"keepsake",where:"Overflow · safe",delta:"known keepsake"}
]);
export function resolveEquipmentFilter(slot){if(slot!=="all"&&!gearSlots.includes(slot))throw new Error(`unknown-gear-slot:${slot}`);const items=slot==="all"?[...equipmentFixtures]:equipmentFixtures.filter(item=>item.slot===slot),baseline=slot==="weapon"?equipmentFixtures.find(item=>item.id==="pointed-1"):null,displayName=slot==="all"?"All":slot==="armor"?"Body":slot==="offhand"?"Off-hand":slot[0].toUpperCase()+slot.slice(1);return{slot,displayName,items,baseline};}
export function locationSnapshots(){return["Stored","Worn · Mara","Overflow · safe","Carried · current world"].map(where=>({...equipmentFixtures[0],where,delta:where.startsWith("Carried")?"unavailable at home":"identity unchanged"}));}
const itemMetadata=Object.freeze({
  "pointed-1":Object.freeze({quantity:1,known:true,rarity:"ordinary",provenance:"Crafted at the Blacksmith"}),
  "blade-2":Object.freeze({quantity:3,known:true,rarity:"fine",provenance:"Known inventory record"}),
  "spear-3":Object.freeze({quantity:1,known:true,rarity:"ordinary",provenance:"Known inventory record"}),
  "blade-4":Object.freeze({quantity:1,known:true,rarity:"ordinary",provenance:"Known inventory record"}),
  "guard-5":Object.freeze({quantity:1,known:true,rarity:"ordinary",provenance:"Known inventory record"}),
  "hood-6":Object.freeze({quantity:3,known:true,rarity:"ordinary",provenance:"Known inventory record"}),
  "body-7":Object.freeze({quantity:1,known:true,rarity:"ordinary",provenance:"Known inventory record"}),
  "gloves-8":Object.freeze({quantity:1,known:true,rarity:"ordinary",provenance:"Known inventory record"}),
  "boots-9":Object.freeze({quantity:1,known:true,rarity:"ordinary",provenance:"Known inventory record"}),
  "pick-10":Object.freeze({quantity:3,known:true,rarity:"ordinary",provenance:"Known inventory record"}),
  "keep-11":Object.freeze({quantity:1,known:false,rarity:"singular",provenance:"Unknown until identified"})
});
export function itemDisplayMeta(item){const metadata=itemMetadata[item.id];if(!metadata)throw new Error(`unknown-equipment-fixture:${item.id}`);return{...item,...metadata};}
export function itemLocationActions(where){if(where.startsWith("Worn"))return["Take off","Inspect"];if(where.startsWith("Stored"))return["Equip","Inspect"];if(where.startsWith("Overflow"))return["Store first","Inspect"];return["Unavailable","Inspect"];}
export const itemCountLabel=count=>`${count} ${count===1?"item":"items"}`;
export const equipmentGridSelectionProof=Object.freeze({selectedOrdinaryIndex:0,unselectedFineIndex:1,selectedFineIndex:1});
