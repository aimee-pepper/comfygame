import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {catalogueItemIDs} from "../src/item-kit.js";
import {uncoveredCatalogueGroups,uncoveredCatalogueIDs,nextCatalogueProofIDs,catalogueCoverageSummary,compactIdentityBoundary} from "../src/catalogue-coverage.js";
const live=JSON.parse(await readFile(new URL("../../Sources/Content/Data/items.json",import.meta.url),"utf8")).items;
const liveIDs=live.map(item=>item.id),accepted=new Set(catalogueItemIDs),uncovered=liveIDs.filter(id=>!accepted.has(id));
assert.equal(liveIDs.length,78);assert.equal(new Set(liveIDs).size,78);assert.deepEqual(uncovered.sort(),[...uncoveredCatalogueIDs].sort());assert.deepEqual(catalogueCoverageSummary,{liveExpected:78,accepted:30,uncovered:48,nextProof:11});assert.deepEqual(Object.fromEntries(Object.entries(uncoveredCatalogueGroups).map(([key,ids])=>[key,ids.length])),{treasure:5,key:2,standardProgression:33,wildWeapon:8});
for(const id of nextCatalogueProofIDs){const item=live.find(candidate=>candidate.id===id);assert.equal(item?.kind,"gear");assert.equal(item?.gear?.tier,2,`${id} must remain an exact live tier-2 counterpart`);}assert.equal(new Set(nextCatalogueProofIDs).size,11);assert.equal(Object.keys(compactIdentityBoundary).length,6);assert.match(compactIdentityBoundary.craftedInstance,/familyID/);assert.match(compactIdentityBoundary.worldMaterial,/context-owned/);assert.match(compactIdentityBoundary.unknown,/disclosure-neutral/);
console.log("Asset Lab catalogue coverage audit tests passed.");
