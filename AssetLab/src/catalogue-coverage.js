import {catalogueItemIDs} from "./item-kit.js";
export const uncoveredCatalogueGroups=Object.freeze({
treasure:Object.freeze(["essence_crystal","heat_core","caustic_core","light_core","conduit_fixture"]),
key:Object.freeze(["cache_key","anchor_frame"])});
export const uncoveredCatalogueIDs=Object.freeze(Object.values(uncoveredCatalogueGroups).flat());
export const nextCatalogueProofIDs=uncoveredCatalogueIDs;
export function catalogueCoverageSummary(liveIDs,packedGearIDs){
  const accepted=new Set([...catalogueItemIDs,...packedGearIDs]);
  return Object.freeze({liveExpected:liveIDs.length,accepted:liveIDs.filter(id=>accepted.has(id)).length,uncovered:liveIDs.filter(id=>!accepted.has(id)).length,nextProof:nextCatalogueProofIDs.length});
}
export const compactIdentityBoundary=Object.freeze({catalogue:"Known catalogItemID owns an authored core silhouette.",foundInstance:"Found instances preserve catalogue pixels; instance state remains external.",craftedInstance:"GearInstanceProfile.familyID owns a separately authored recipe-family silhouette; catalogue fallback is not visual authority.",resource:"ResourceID uses Resource v0.6 and never borrows catalogue identity.",worldMaterial:"Exact persisted MaterialSample value owns its known material cue; selection identity is context-owned.",unknown:"Unidentified curios share one disclosure-neutral unknown body."});
