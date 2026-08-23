import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createCanvas, loadImage } from "@napi-rs/canvas";
import { sha256 } from "../src/exploration-catalogue-objects-v1-kit.js";

const root = path.resolve(import.meta.dirname, "..");
const product = path.join(root, "integration", "exploration-map-final-art-review");
const receipt = JSON.parse(fs.readFileSync(path.join(product, "review-receipt.json")));
assert.equal(receipt.schemaVersion, "exploration-map-final-art-review-v1");
assert.equal(receipt.status, "candidate-unapproved");
assert.equal(receipt.integrationReady, false);
assert.equal(receipt.runtimeMerge, false);
assert.deepEqual(receipt.coverage, {
  catalogueItemIDs:102, catalogueGearIDs:75, catalogueTreasureCurioConsumableKeyIDs:27,
  reviewStableKeys:154, reviewRuntimePNGs:141,
});

const manifests = [
  ["exploration-map-identities-v1", "exploration-map-identities-v1.json"],
  ["exploration-loose-items-v1", "exploration-loose-items-v1.json"],
  ["exploration-catalogue-objects-v1", "exploration-catalogue-objects-v1.json"],
];
const manifestByID = {};
for (const [id,file] of manifests) {
  const bytes = fs.readFileSync(path.join(product, "receipts", file));
  const row = receipt.candidatePacks[id];
  assert.equal(sha256(bytes), row.manifestSHA256, `${id} manifest receipt drifted`);
  const manifest = JSON.parse(bytes);
  manifestByID[id] = manifest;
  assert.equal(manifest.canonicalBodySHA256, row.canonicalBodySHA256);
  assert.equal(manifest.runtimeAssetAggregateSHA256, row.runtimeAssetAggregateSHA256);
  assert.equal(manifest.status, "candidate-unapproved");
  assert.equal(manifest.integrationReady, false);
}

const catalogue = JSON.parse(fs.readFileSync(path.join(root,"..","Sources","Content","Data","items.json"))).items;
const gearIDs = manifestByID["exploration-loose-items-v1"].requestABI.catalogueIDs;
const objectIDs = manifestByID["exploration-catalogue-objects-v1"].requestABI.catalogueIDs;
assert.equal(catalogue.length,102);
assert.equal(gearIDs.length,75);
assert.equal(objectIDs.length,27);
assert.equal(gearIDs.filter(id=>objectIDs.includes(id)).length,0,"catalogue packs must not overlap");
assert.deepEqual([...gearIDs,...objectIDs].sort(),catalogue.map(row=>row.id).sort(),"every current catalogue ID must resolve exactly once");

const sites = JSON.parse(fs.readFileSync(path.join(root,"..","Sources","Content","Data","sites.json"))).sites;
const identityManifest = manifestByID["exploration-map-identities-v1"];
const siteIdentities = identityManifest.identities.filter(row=>row.kind==="site");
assert.equal(sites.length,9);
assert.deepEqual(siteIdentities.map(row=>row.id).sort(),sites.map(row=>row.id).sort(),"all live sites need exact candidate identity");
for(const site of siteIdentities){
  const expectedStates=site.searchable?["unlooted","looted"]:["ordinary"];
  assert.deepEqual(site.states,expectedStates);
  if(site.searchable) assert.equal(site.lootedStateAuthority,"PlacedSite.isLooted");
}
assert.deepEqual(identityManifest.production.minimap.categories,["portal","page","cache","site","hazard","resource"]);
for(const category of identityManifest.production.minimap.categories) assert.ok(identityManifest.assetsByKey[`minimap/${category}/ordinary`]);
assert.ok(manifestByID["exploration-loose-items-v1"].assetsByKey["minimap/item"]);

const worldView = fs.readFileSync(path.join(root,"..","Sources","Screens","WorldView.swift"),"utf8");
for(const systemSymbol of ["figure.stand","doc.text.fill","shippingbox.fill","sparkle","exclamationmark.triangle.fill","arrow.down.left.circle","circle.circle","lock.fill","doc.text","note.text","building.columns"]){
  assert.ok(worldView.includes(`\"${systemSymbol}\"`),`live symbol census changed: ${systemSymbol}`);
}
const minimapView = fs.readFileSync(path.join(root,"..","Sources","Screens","MinimapView.swift"),"utf8");
assert.ok(minimapView.includes("case portal, page, apex, site, resource, item, traveller, encounter, cache, hazard"));
for(const candidate of ["portal","page","site","resource","item","cache","hazard"]) assert.ok(readinessPlaceholder(candidate));

function readinessPlaceholder(marker){
  // Defined against the receipt below as a small helper so the source census cannot drift silently.
  const data=JSON.parse(fs.readFileSync(path.join(product,"consumer-readiness.json")));
  return data.currentMinimapSymbolReplacements.some(row=>row.marker===marker&&row.status==="candidate"&&row.stableKey);
}

const expectedEvidence = {
  identities:["applied-map-full-368x800.png","applied-map-full-grayscale-368x800.png","production-sprites-native-400pct.png","ambient-animation-strips-800pct.png","minimap-category-sprites-native-1600pct.png"],
  gear:["applied-map-catalogue-1-368x800.png","applied-map-catalogue-3-368x800.png","applied-map-catalogue-5-368x800.png","accepted-source-to-map-native-800pct.png"],
  objects:["applied-map-objects-1-368x800.png","applied-map-objects-2-368x800.png","applied-map-objects-3-368x800.png","production-objects-native-800pct.png","curio-disclosure-and-visibility-800pct.png"],
};
for (const [family,files] of Object.entries(expectedEvidence)) {
  assert.deepEqual(fs.readdirSync(path.join(product,"evidence",family)).sort(), [...files].sort());
  for (const file of files) {
    const image = await loadImage(path.join(product,"evidence",family,file));
    assert.ok(image.width > 0 && image.height > 0);
    if (file.includes("368x800")) assert.deepEqual([image.width,image.height],[368,800]);
    const canvas = createCanvas(image.width,image.height); canvas.getContext("2d").drawImage(image,0,0);
    const rgba = canvas.getContext("2d").getImageData(0,0,image.width,image.height).data;
    assert.ok(rgba.some((value,index)=>index%4===3 && value>0), `${family}/${file} has no visible pixels`);
  }
}

assert.deepEqual(receipt.blockedFinalFamilies.map(row=>row.family), ["named-travellers","ordinary-and-apex-creatures","Binder-and-Quill"]);
const namedPlaceholder = JSON.parse(fs.readFileSync(path.join(root,"integration","named-character-placeholders-v1","manifest.json")));
assert.equal(namedPlaceholder.finalArt, false);

const readiness = JSON.parse(fs.readFileSync(path.join(product,"consumer-readiness.json")));
assert.equal(readiness.schemaVersion,"exploration-map-final-art-consumer-readiness-v1");
assert.equal(readiness.status,"candidate-unapproved");
assert.equal(readiness.integrationReady,false);
assert.deepEqual(readiness.ordinaryMapConsumer.logicalCanvas,[16,19]);
assert.equal(readiness.ordinaryMapConsumer.runtimePolicy,"stable lookup of complete premade PNG only");
assert.deepEqual(readiness.currentMinimapSymbolReplacements.filter(row=>row.status==="candidate").map(row=>row.marker),["portal","page","site","resource","item","cache","hazard"]);
assert.deepEqual(readiness.currentMinimapSymbolReplacements.filter(row=>row.status==="blocked").map(row=>row.marker),["traveller","encounter","apex"]);
assert.equal(readiness.currentWorldSymbolReplacements.filter(row=>row.status==="blocked").length,3);
assert.equal(readiness.animationIndex.animatedPremade.length,8);
assert.ok(readiness.animationIndex.staticPremade.includes("all-102-catalogue-items"));

const html = fs.readFileSync(path.join(root,"exploration-map-final-art-review.html"),"utf8");
assert.ok(html.includes("three frozen candidates"));
assert.ok(html.includes("runtime-generated images"));
assert.ok(html.includes("Named travellers"));
assert.ok(html.includes("Binder and Quill"));
assert.ok(html.includes("current symbol → premade replacement"));
assert.ok(!/Accessibility|VoiceOver|Dynamic Type|XXXL/i.test(html));

console.log("exploration map final-art review: 3 isolated candidate packs, 102 catalogue IDs, 154 stable keys; blocker provenance passed");
