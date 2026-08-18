import assert from "node:assert/strict";
import {fixtureStatesByScreen,renderScreen} from "../src/ui-gallery-app.js";

const states=["Returned","Collapsed","Receipt detail"];
assert.deepEqual(fixtureStatesByScreen["return-recap"],states,"World exit must expose return, collapse and exact-detail review states");

const rendered=Object.fromEntries(states.map(state=>[state,renderScreen("Return Recap",state)]));
for(const [state,html] of Object.entries(rendered)){
  assert.match(html,/return-outcome/,`${state} must lead with the persisted expedition outcome`);
  assert.match(html,/Turns[\s\S]*Haul/,`${state} must preserve turns and haul fraction`);
  assert.match(html,/RECOVERED[\s\S]*Resources · 7 units/,`${state} must preserve recovered resource truth`);
  assert.match(html,/Lesser Salve[\s\S]*World Page/,`${state} must preserve exact recovered item and page identities`);
  assert.match(html,/KEPT WITH YOU[\s\S]*Writing & travellers[\s\S]*party total/,`${state} must preserve writing, travellers and party progress`);
  assert.match(html,/LOST[\s\S]*Chipped blade[\s\S]*Field Page/,`${state} must preserve losses in the same receipt`);
  assert.match(html,/NEXT DEPARTURE[\s\S]*40 Essence held/,`${state} must preserve the Essence runway`);
  assert.match(html,/return-action-rail[\s\S]*Return to Base/,`${state} must expose only the actual dismissal destination`);
  assert.doesNotMatch(html,/Recovered<\/button>|Lost<\/button>|>History<|bottom-rail/,`${state} must not restore invented tabs, History action or a generic paired rail`);
  assert.equal((html.match(/class="recap-tile/g)??[]).length,7,`${state} must use one compact shared exact-identity tile grammar`);
}

assert.match(rendered.Returned,/RETURN COMPLETE[\s\S]*Home with what you carried/);
assert.match(rendered.Collapsed,/WORLD COLLAPSED[\s\S]*The path closed behind you[\s\S]*4 \/ 9/);
assert.doesNotMatch(rendered.Returned,/recap-detail/,"ordinary return must not open an item detail by itself");
assert.match(rendered["Receipt detail"],/recap-detail[\s\S]*RECOVERED ITEM[\s\S]*Lesser Salve[\s\S]*Storehouse/,"exact item detail must remain anchored to the receipt identity");

console.log("World exit candidate tests passed.");
