import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {preservationLedger} from "../src/ui-preservation-ledger.js";
import {fontChoices,implementationReviewPacket,normalizeImplementationReviews,renderers,renderScreen,reviewStorageKey,screens} from "../src/ui-gallery-app.js";
const css=await readFile(new URL("../ui-gallery.css",import.meta.url),"utf8");
const galleryHtml=await readFile(new URL("../ui-gallery.html",import.meta.url),"utf8");
const required=["Campaigns","Home","Writing Desk","Storehouse","Workshop","Party","Essence Spring","Constellation","Library","Bestiary","Research","World History","Blacksmith","Trading Post","Recycler","Tannery","Bowyer","Armoury","Weaponsmith","Scriptorium","Survey Post","Apothecary","Reliquary","Wayfarer’s Table","Anchorage","Distillery","Channelworks","Firepit","Gear","World","Encounter","Loot Decision","Return Recap","Settings"];
assert.deepEqual(screens.map(({title})=>title),required,"screen order is an intentional ordinary-phone contract");
assert.deepEqual([...renderers.keys()],required,"every gallery entry must have one explicit renderer");
assert.deepEqual(Object.keys(preservationLedger).sort(),required.slice().sort(),"every proposed screen must audit the native structure it preserves");
for(const [title,[nativeSource,...facts]] of Object.entries(preservationLedger)){assert.match(nativeSource,/\.swift/,`${title} must name its native source`);assert.ok(facts.length>=2,`${title} needs explicit preservation facts`)}
assert.match(css,/width:368px;height:800px/);
for(const title of required){
  for(const fixtureState of ["Default","Selected","Confirm"]){
    const html=renderScreen(title,fixtureState);
    assert.match(html,/class="safe-top"/,`${title} ${fixtureState} must render phone chrome`);
    assert.match(html,/class="bottom-rail"/,`${title} ${fixtureState} must keep actions reachable`);
    assert.ok(html.length>500,`${title} ${fixtureState} must render a substantive fixture`);
  }
}
const requiredMarkers={
  Campaigns:"book-progress",Home:"town-scene","Writing Desk":"writing-desk",Storehouse:"storehouse-cabinet",Workshop:"project-strip",Party:"party-formation",
  "Essence Spring":"spring-basin",Constellation:"constellation-field",Library:"library-catalogue",Bestiary:"specimen-folio","World History":"world-archive",Blacksmith:"comparison-rack",
  "Trading Post":"market-stall",
  Recycler:"salvage-table",Tannery:"hide-frame",Bowyer:"bow-jig",Armoury:"armour-stand",
  Weaponsmith:"weapon-rack",Apothecary:"bottle-shelf",Reliquary:"reliquary-room",
  "Survey Post":"instrument-board",
  "Wayfarer’s Table":"route-table",Distillery:"class=\"still\"",Channelworks:"conduit-diagram",
  Firepit:"camp-circle","Loot Decision":"gear-balance","Return Recap":"receipt-paper",Settings:"utility-board"
};
for(const [title,marker] of Object.entries(requiredMarkers))assert.match(renderScreen(title),new RegExp(marker),`${title} must reach its specialized composition`);
assert.match(renderScreen("Constellation","Confirm"),/fixed in place/,"fixture states must execute stateful renderer branches");
assert.match(renderScreen("Campaigns"),/OLDER TEST VERSION 12/,"campaign proposal must preserve explicit legacy-version handling");
assert.match(renderScreen("Apothecary"),/Scent Mask/,"Apothecary must represent the live learned treatment truthfully");
assert.match(renderScreen("Library"),/Unknown and legacy records remain unguessed/,"Library must not infer missing record identity");
assert.match(renderScreen("Bestiary"),/quadruped · long ears[\s\S]*sinuous · membrane appendage/,"Bestiary must preserve materially different generated morphology");
assert.match(renderScreen("World History"),/Earlier[\s\S]*World 9[\s\S]*Later[\s\S]*World 12/,"History must expose chronology independently of selection order");
assert.match(renderScreen("Trading Post"),/owned 2 · stock 5[\s\S]*properties unknown/,"Trading Post must keep owned, stock and disclosure truth on its wares");
assert.match(renderScreen("Survey Post"),/EIGHT INDEPENDENT ROOTS[\s\S]*NO SHARED NODE EDGE/,"Survey instruments must not be flattened into a fake graph");
assert.match(renderScreen("World"),/Field Kit 5[\s\S]*mini-map[\s\S]*FIXED 11×11 CAMERA/,"World must preserve fixed-scale map, minimap truth, and persistent Field Kit status");
assert.match(renderScreen("Encounter"),/CURRENT ACTOR · BINDER[\s\S]*Glassback · 6\/13[\s\S]*Selected consequence/,"Encounter must expose current actor, exact target and consequence");
assert.match(css,/Foundation v0\.2/);
assert.match(css,/\.foundation-board/);
assert.match(css,/@font-face\{font-family:"Pixelify Sans"/,"gallery must bundle its compact mixed-case pixel display font");
assert.deepEqual(fontChoices.map(({id})=>id),["jersey-tiny","pixelify","jersey","silkscreen","tiny5"],"font chooser order is a deliberate review contract");
assert.match(galleryHtml,/id="pixel-font-choice"/,"gallery must expose a live pixel-font chooser");
assert.match(galleryHtml,/Yes, implementation ready[\s\S]*No, not ready/,"every selected preview must expose a mutually exclusive implementation gate");
assert.match(galleryHtml,/id="implementation-feedback"[\s\S]*Required when this screen is not ready/,"a not-ready review must request specific feedback");
assert.equal(reviewStorageKey,"bookbinder.assetlab.ui-gallery-reviews.v1");
assert.deepEqual(normalizeImplementationReviews({campaigns:{choice:"no",notes:"Tighten spacing"},home:{choice:"yes",notes:""},invented:{choice:"yes",notes:"ignored"},gear:{choice:"maybe",notes:7}}),{campaigns:{choice:"no",notes:"Tighten spacing"},home:{choice:"yes",notes:""}},"stored reviews must be restricted to known screens and valid choices");
assert.deepEqual(implementationReviewPacket({home:{choice:"yes",notes:""},invented:{choice:"no",notes:"ignored"}}),{schemaVersion:1,reviews:{home:{choice:"yes",notes:""}}},"the shared packet helper must emit only normalized gallery reviews");
assert.match(css,/\.implementation-review/);
for(const family of ["Jersey 10","Silkscreen","Tiny5"])assert.match(css,new RegExp(`font-family:\"${family}\"`),`${family} must be bundled for live comparison`);
assert.match(css,/--font-reading/,"long prose must retain a separate readable face");
assert.match(galleryHtml,/Pixel display type owns titles, labels and controls/,"gallery must make the pixel/display prose split reviewable");
assert.match(css,/town-starting-home-v1-phone-v2\.png/,"Home must use the phone-composed full-scene asset");
assert.match(css,/\.town-scene\{height:624px/,"Home scene must own the full phone content body");
assert.match(renderScreen("Home"),/town-tabs/,"Home destinations must overlay the scene instead of shrinking it");
for(const marker of new Set(Object.values(requiredMarkers))){
  const className=marker.replace(/^class=\\?"|\\?"$/g,"");
  assert.match(css,new RegExp(`\\.${className}`),`${className} needs an authored style contract`);
}
console.log(`UI gallery covers ${required.length} ordinary-phone screens.`);
