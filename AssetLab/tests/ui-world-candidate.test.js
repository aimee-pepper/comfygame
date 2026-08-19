import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import {fixtureStatesByScreen,previewActionState,renderScreen} from "../src/ui-gallery-app.js";

const states=["Compare versions","Previous layout","Travel","Look","Harvest","Search","Portal","Cache","Survey & anchor","Loose page","Night sight"];

assert.deepEqual(fixtureStatesByScreen.world,states,"World must expose the exact current travel and interaction proof states");

const rendered=Object.fromEntries(states.map(state=>[state,renderScreen("World",state)]));
const css=readFileSync(new URL("../ui-gallery.css",import.meta.url),"utf8");

for(const [selector,height] of [["world-expedition-header",58],["party-health-strip",39],["world-map-stage",470],["world-field-strip",28],["world-controls",175]]){
  assert.match(css,new RegExp(`\\.${selector}\\{[^}]*height:${height}px`),`${selector} must retain its measured ordinary-phone height`);
}
assert.equal(30+58+39+470+28+175,800,"World bands must exactly fill the ordinary 368×800 phone without overlap or dead space");

assert.equal(previewActionState("world","Look","Travel"),"Look","the in-phone Look action must arm inspection mode");
assert.equal(previewActionState("world","Cancel","Look"),"Travel","the in-phone Cancel action must return to travel controls");

assert.match(rendered["Compare versions"],/world-candidate/,"the screen renderer must remain a full-size current phone while the gallery shell owns comparison layout");
assert.doesNotMatch(rendered["Compare versions"],/world-version-compare|Previous layout/,"the screen renderer must never squeeze two versions into one phone pane");
assert.match(rendered["Previous layout"],/FIXED 11×11 CAMERA[\s\S]*Gather 1 Resin[\s\S]*bottom-rail/,"the prior World composition must remain independently inspectable at full size");

for(const [state,html] of Object.entries(rendered).filter(([name])=>!["Compare versions","Previous layout"].includes(name))){
  assert.match(html,/world-candidate/,`${state} must use the dedicated World composition`);
  assert.match(html,/world-expedition-header[\s\S]*Explore[\s\S]*world-header-status/,`${state} must retain the crafted Explore header with inline status`);
  assert.match(html,/world-header-status[\s\S]*STABILITY[\s\S]*COLLAPSE/,`${state} must preserve Stability and collapse truth beside Explore`);
  assert.match(html,/party-health-strip/,`${state} must preserve the party-health strip`);
  assert.equal((html.match(/party-health-bar/g)??[]).length,3,`${state} must show one proportional health bar per visible party member`);
  assert.match(html,/world-map-grid/,`${state} must preserve the fixed map viewport`);
  assert.equal((html.match(/world-map-cell/g)??[]).length,121,`${state} must render an 11×11 fixed-scale viewport`);
  assert.doesNotMatch(html,/world-map-scale|FIXED 11×11/,`${state} must not show the redundant fixed-camera badge`);
  assert.doesNotMatch(html,/world-event-log/,`${state} must not keep the redundant narration bar`);
  assert.match(html,/world-place-info/,`${state} must restore the place-information panel without embedding actions in it`);
  assert.ok(html.indexOf("world-map-stage")<html.indexOf("world-place-info")&&html.indexOf("world-place-info")<html.indexOf("world-field-strip"),`${state} must overlay place information inside the map before the compact field strip`);
  assert.match(html,/world-field-strip/,`${state} must keep Field Kit, resources, and turn visible`);
  assert.match(html,/world-navigation-row[\s\S]*class="dpad[\s\S]*world-map-controls[\s\S]*world-minimap[\s\S]*world-actions/,`${state} must keep the larger movement pad beside a minimap with both actions directly beneath it`);
  assert.match(html,/class="dpad/,`${state} must preserve directional movement or inspection`);
  assert.match(html,/world-minimap/,`${state} must preserve the explored minimap`);
  assert.match(html,/world-actions/,`${state} must preserve native Interact and Look actions`);
  assert.ok(html.indexOf("world-navigation-row")<html.indexOf("world-actions"),`${state} must place action buttons below movement and minimap`);
  assert.match(html,/>Interact</,`${state} must retain the generic rules-owned Interact label`);
  assert.doesNotMatch(html,/bottom-rail/,`${state} must not inherit a generic two-button rail`);
  assert.doesNotMatch(html,/Gather 1 Resin/,`${state} must not invent a direct Gather CTA`);
  assert.doesNotMatch(html,/LOOK \/ GATHER/,`${state} must not retain v1's redundant action label inside the information panel`);
}

assert.match(rendered.Travel,/pixel-btn primary" disabled>Interact<\/button>/);
assert.match(rendered.Travel,/pixel-btn ">Look<\/button>/);
assert.match(rendered.Look,/look-armed/);
assert.match(rendered.Look,/Inspection directions/);
assert.match(rendered.Look,/pixel-btn active">Cancel<\/button>/);
assert.match(rendered.Harvest,/Harvest Resin · 3 left/);
assert.match(rendered.Search,/Fallen shrine[\s\S]*Search · 2 turns remain/);
assert.match(rendered.Portal,/Atlas Seam[\s\S]*Return home/);
assert.match(rendered.Cache,/Locked cache[\s\S]*Key required[\s\S]*pixel-btn primary" disabled>Interact<\/button>/);

assert.match(rendered["Survey & anchor"],/world-context-sheet/);
assert.match(rendered["Survey & anchor"],/Natural Atlas Seam/);
assert.match(rendered["Survey & anchor"],/Survey uses 1 turn/);
assert.match(rendered["Survey & anchor"],/Place Anchor Frame/);
assert.match(rendered["Loose page"],/world-context-sheet/);
assert.match(rendered["Loose page"],/Field Kit full/);
assert.match(rendered["Loose page"],/Unknown World Page[\s\S]*Take or replace one carried family/);
assert.match(rendered["Loose page"],/Choose a slot/);

assert.match(rendered["Night sight"],/LOW ILLUMINATION · CLEAR 3/);
assert.match(rendered["Night sight"],/world-map-cell[^\"]* fringe/);
assert.match(rendered["Night sight"],/world-map-cell[^\"]* hidden/);

console.log("World candidate tests passed.");
