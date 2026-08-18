import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {preservationLedger} from "../src/ui-preservation-ledger.js";
import {renderers,renderScreen,screens} from "../src/ui-gallery-app.js";
const css=await readFile(new URL("../ui-gallery.css",import.meta.url),"utf8");
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
  Campaigns:"book-progress",Home:"town-scene","Writing Desk":"page-grid",Workshop:"project-strip",
  "Essence Spring":"spring-basin",Constellation:"constellation-field",Blacksmith:"comparison-rack",
  Recycler:"salvage-table",Tannery:"hide-frame",Bowyer:"bow-jig",Armoury:"armour-stand",
  Weaponsmith:"weapon-rack",Apothecary:"bottle-shelf",Reliquary:"reliquary-room",
  "Wayfarer’s Table":"route-table",Distillery:"class=\"still\"",Channelworks:"conduit-diagram",
  Firepit:"camp-circle","Loot Decision":"gear-balance","Return Recap":"receipt-paper",Settings:"utility-board"
};
for(const [title,marker] of Object.entries(requiredMarkers))assert.match(renderScreen(title),new RegExp(marker),`${title} must reach its specialized composition`);
assert.match(renderScreen("Constellation","Confirm"),/fixed in place/,"fixture states must execute stateful renderer branches");
assert.match(css,/Foundation v0\.2/);
assert.match(css,/\.foundation-board/);
assert.match(css,/town-starting-home-v1-phone-v2\.png/,"Home must use the phone-composed full-scene asset");
assert.match(css,/\.town-scene\{height:624px/,"Home scene must own the full phone content body");
assert.match(renderScreen("Home"),/town-tabs/,"Home destinations must overlay the scene instead of shrinking it");
for(const marker of new Set(Object.values(requiredMarkers))){
  const className=marker.replace(/^class=\\?"|\\?"$/g,"");
  assert.match(css,new RegExp(`\\.${className}`),`${className} needs an authored style contract`);
}
console.log(`UI gallery covers ${required.length} ordinary-phone screens.`);
