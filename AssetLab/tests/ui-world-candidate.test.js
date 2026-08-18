import assert from "node:assert/strict";
import {fixtureStatesByScreen,renderScreen} from "../src/ui-gallery-app.js";

const states=["Compare versions","Travel","Look","Harvest","Search","Portal","Cache","Survey & anchor","Loose page","Dense log","Night sight"];

assert.deepEqual(fixtureStatesByScreen.world,states,"World must expose the exact current travel and interaction proof states");

const rendered=Object.fromEntries(states.map(state=>[state,renderScreen("World",state)]));

assert.match(rendered["Compare versions"],/world-version-compare[\s\S]*Previous layout[\s\S]*Current redesign/,"World comparison must keep both actual compositions visible together");
assert.match(rendered["Compare versions"],/Gather 1 Resin[\s\S]*world-candidate/,"comparison must place the preserved prior layout before the current candidate");

for(const [state,html] of Object.entries(rendered).filter(([name])=>name!=="Compare versions")){
  assert.match(html,/world-candidate/,`${state} must use the dedicated World composition`);
  assert.match(html,/world-status-header/,`${state} must preserve Stability and collapse truth`);
  assert.match(html,/party-health-strip/,`${state} must preserve the party-health strip`);
  assert.match(html,/world-map-grid/,`${state} must preserve the fixed map viewport`);
  assert.equal((html.match(/world-map-cell/g)??[]).length,121,`${state} must render an 11×11 fixed-scale viewport`);
  assert.match(html,/FIXED 11×11/,`${state} must disclose fixed map scale in the proof`);
  assert.match(html,/world-event-log/,`${state} must keep the event log above persistent controls`);
  assert.match(html,/world-field-strip/,`${state} must keep Field Kit, resources, and turn visible`);
  assert.match(html,/class="dpad/,`${state} must preserve directional movement or inspection`);
  assert.match(html,/world-minimap/,`${state} must preserve the explored minimap`);
  assert.match(html,/world-actions/,`${state} must preserve native Interact and Look actions`);
  assert.match(html,/>Interact</,`${state} must retain the generic rules-owned Interact label`);
  assert.doesNotMatch(html,/bottom-rail/,`${state} must not inherit a generic two-button rail`);
  assert.doesNotMatch(html,/Gather 1 Resin/,`${state} must not invent a direct Gather CTA`);
}

assert.match(rendered.Travel,/disabled><b>Interact<\/b><small>Nothing to interact with here/);
assert.match(rendered.Travel,/>Look<\/b><small>Inspect without moving/);
assert.match(rendered.Look,/look-armed/);
assert.match(rendered.Look,/Inspection directions/);
assert.match(rendered.Look,/>Cancel<\/b><small>Choose a direction/);
assert.match(rendered.Harvest,/Harvest Resin · 3 left/);
assert.match(rendered.Harvest,/You gather Resin\. Two remain here\./);
assert.match(rendered.Search,/Search Fallen shrine · 2 turns remain/);
assert.match(rendered.Portal,/Return home through Atlas Seam/);
assert.match(rendered.Cache,/disabled><b>Interact<\/b><small>Locked cache · Key required/);

assert.match(rendered["Survey & anchor"],/world-context-sheet/);
assert.match(rendered["Survey & anchor"],/Natural Atlas Seam/);
assert.match(rendered["Survey & anchor"],/Survey uses 1 turn/);
assert.match(rendered["Survey & anchor"],/Place Anchor Frame/);
assert.match(rendered["Loose page"],/world-context-sheet/);
assert.match(rendered["Loose page"],/Field Kit full/);
assert.match(rendered["Loose page"],/Take Unknown World Page/);
assert.match(rendered["Loose page"],/Choose a slot/);

assert.match(rendered["Dense log"],/Nothing in this report moves the controls below\./);
assert.ok(rendered["Dense log"].indexOf("world-event-log")<rendered["Dense log"].indexOf("world-field-strip"),"variable event copy must precede rather than displace persistent field controls");
assert.match(rendered["Night sight"],/LOW ILLUMINATION · CLEAR 3/);
assert.match(rendered["Night sight"],/world-map-cell[^\"]* fringe/);
assert.match(rendered["Night sight"],/world-map-cell[^\"]* hidden/);

console.log("World candidate tests passed.");
