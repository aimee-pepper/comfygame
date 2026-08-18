import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";

const manifest=JSON.parse(await readFile(new URL("../integration/ui-priority-v1/manifest.json",import.meta.url),"utf8"));
const css=await readFile(new URL("../ui-gallery.css",import.meta.url),"utf8");
const html=await readFile(new URL("../ui-gallery.html",import.meta.url),"utf8");

assert.equal(manifest.integrationReady,true);
assert.deepEqual(manifest.implementationOrder,["campaigns","home","writing-desk","world","return-recap"]);
assert.deepEqual(manifest.ordinaryPhone,{width:368,height:800,contentSize:"ordinary"});
assert.deepEqual(manifest.typography,{display:"Jersey 10",compact:"Tiny5",prose:"system readable face"});
assert.deepEqual(manifest.screens.map(({id})=>id),manifest.implementationOrder);
assert.equal(new Set(manifest.appearance.semanticTokens).size,manifest.appearance.semanticTokens.length);
for(const token of manifest.appearance.semanticTokens)assert.ok(css.includes(`--theme-${token}`),`shared theme token ${token} must exist in the gallery source`);
assert.match(html,/id="preview-appearance"/);
for(const screen of manifest.screens){
  assert.ok(screen.nativeFiles.length>=2,`${screen.id} must name production and test consumers`);
  assert.ok(screen.states.length>=3,`${screen.id} must provide reviewable state coverage`);
  assert.ok(screen.preserve.length>=4,`${screen.id} must carry an explicit preservation contract`);
}
assert.match(manifest.nativeBoundary.rules.join(" "),/No gameplay/);
console.log("Priority UI theme and native handoff are closed and implementation-ready.");
