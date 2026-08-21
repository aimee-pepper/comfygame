import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";

const manifest=JSON.parse(await readFile(new URL("../integration/ui-priority-v1/manifest.json",import.meta.url),"utf8"));
const css=await readFile(new URL("../ui-gallery.css",import.meta.url),"utf8");
const html=await readFile(new URL("../ui-gallery.html",import.meta.url),"utf8");

assert.equal(manifest.schemaVersion,2);
assert.equal(manifest.integrationReady,false,"a mixed-review multi-screen index must not claim package-wide readiness");
assert.equal(manifest.readinessScope,"per-screen-only");
assert.equal(manifest.packageStatus,"ordered-handoff-index");
assert.equal(manifest.deliveryContract,"docs/cross-lead-delivery-contract-current.md");
assert.deepEqual(manifest.implementationOrder,["campaigns","home","writing-desk","world","return-recap"]);
assert.deepEqual(manifest.ordinaryPhone,{width:368,height:800,contentSize:"ordinary"});
assert.deepEqual(manifest.typography,{display:"Jersey 10",compact:"Tiny5",prose:"system readable face"});
assert.deepEqual(manifest.screens.map(({id})=>id),manifest.implementationOrder);
assert.equal(new Set(manifest.appearance.semanticTokens).size,manifest.appearance.semanticTokens.length);
for(const token of manifest.appearance.semanticTokens)assert.ok(css.includes(`--theme-${token}`),`shared theme token ${token} must exist in the gallery source`);
assert.match(html,/id="preview-appearance"/);
for(const screen of manifest.screens){
  assert.equal(typeof screen.integrationReady,"boolean",`${screen.id} must track readiness independently`);
  assert.ok(screen.behaviorAuthority.includes("docs/cross-lead-delivery-contract-current.md")||screen.behaviorAuthority.some(authority=>authority.startsWith("docs/cross-lead-delivery-contract-current.md#")),`${screen.id} must point to the cross-lead behavior fence`);
  assert.equal(typeof screen.receipts.designSettled,"boolean");
  assert.equal(typeof screen.receipts.assetCandidate,"boolean");
  assert.ok(screen.receipts.visualReview.status);
  assert.ok(screen.receipts.assetFrozen.status);
  assert.ok(screen.receipts.nativeIntegration.status);
  assert.ok(screen.nativeFiles.length>=2,`${screen.id} must name production and test consumers`);
  assert.ok(screen.states.length>=3,`${screen.id} must provide reviewable state coverage`);
  assert.ok(screen.preserve.length>=4,`${screen.id} must carry an explicit preservation contract`);
}
assert.deepEqual(manifest.screens.filter(screen=>screen.integrationReady).map(screen=>screen.id),["home"]);
assert.equal(manifest.screens.find(screen=>screen.id==="campaigns").receipts.visualReview.status,"rejected");
assert.equal(manifest.screens.find(screen=>screen.id==="writing-desk").receipts.assetFrozen.status,"not-frozen");
assert.equal(manifest.screens.find(screen=>screen.id==="world").receipts.nativeIntegration.status,"not-integrated-ui-redesign");
assert.match(manifest.nativeBoundary.rules.join(" "),/No gameplay/);
console.log("Priority UI handoff receipts are tracked per screen without package-wide readiness.");
