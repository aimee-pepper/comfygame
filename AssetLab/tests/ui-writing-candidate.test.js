import assert from "node:assert/strict";
import {fixtureStatesByScreen,renderScreen} from "../src/ui-gallery-app.js";

const states=["Write","Runebook","Pages · Collected","Pages · Templates","The world","Collected world","Born anchored","Clear Confirm"];

assert.deepEqual(
  fixtureStatesByScreen["writing-desk"],
  states,
  "Writing Desk must expose the exact native workflow states instead of generic gallery states"
);

const rendered=Object.fromEntries(states.map(state=>[state,renderScreen("Writing Desk",state)]));

for(const [state,html] of Object.entries(rendered)){
  assert.match(html,/Write[\s\S]*Pages[\s\S]*The world/,`${state} must preserve the three native panes and their wording`);
  assert.doesNotMatch(html,/writing-tool-rack/,`${state} must not restore the rejected side-by-side tool rack`);
  assert.doesNotMatch(html,/bottom-rail/,`${state} must not turn Writing Desk into a generic two-button rail`);
}

const write=rendered.Write;
assert.match(write,/writing-pane/,"Write must identify the native writing workspace");
assert.match(write,/write-page|page-sheet/,"Write must retain the page as its dominant workspace");
assert.match(write,/target-bin-rail/,"Write must retain one horizontal rail of target bins");
assert.match(write,/writing-palette(?: full-width)?"(?: data-layout="full-width")?/,"the open bin must render as a full-width palette below its rail");
assert.ok(
  Math.max(write.indexOf("write-page"),write.indexOf("page-sheet")) < write.indexOf("target-bin-rail") &&
    write.indexOf("target-bin-rail") < write.indexOf("writing-palette"),
  "Write order must remain page, target-bin rail, then palette"
);
assert.match(write,/clear-context-action/,"Clear must remain a contextual Write action");
assert.doesNotMatch(write,/Bind &amp; Depart|Bind & Depart|bind-and-depart/,"Write must not expose the departure action");
assert.doesNotMatch(write,/clear-confirmation|Clear this page\?/,"ordinary Write must not look pre-confirmed");

const runebook=rendered.Runebook;
assert.match(runebook,/writing-pane/,"Runebook is a selected Compounds bin within Write, not another pane");
assert.match(runebook,/target-bin-rail[\s\S]*Compounds/,"Runebook must remain reachable through the target-bin rail's Compounds bin");
assert.match(runebook,/personal-runebook[\s\S]*My Runebook/,"Runebook must represent the personal compound flow");
assert.doesNotMatch(runebook,/Bind &amp; Depart|Bind & Depart|bind-and-depart/,"Runebook must not expose the departure action");

const collected=rendered["Pages · Collected"];
assert.match(collected,/pages-pane/,"Collected must be represented inside Pages");
assert.match(collected,/pages-section-tabs[\s\S]*Collected[\s\S]*Templates/,"Pages must preserve its Collected/Templates switch");
assert.match(collected,/collected-pages/,"Collected must show the saved World Page flow");
assert.doesNotMatch(collected,/template-shelf|Bind &amp; Depart|Bind & Depart|bind-and-depart|clear-context-action/,"Collected must not merge Templates, departure, or Write actions into its surface");

const templates=rendered["Pages · Templates"];
assert.match(templates,/pages-pane/,"Templates must be represented inside Pages");
assert.match(templates,/pages-section-tabs[\s\S]*Collected[\s\S]*Templates/,"Templates must preserve the same Pages section switch");
assert.match(templates,/template-shelf/,"Templates must show its save/load/rename/overwrite/delete shelf flow");
assert.doesNotMatch(templates,/collected-pages|Bind &amp; Depart|Bind & Depart|bind-and-depart|clear-context-action/,"Templates must not merge Collected, departure, or Write actions into its surface");

const world=rendered["The world"];
assert.match(world,/world-pane/,"The world must have a dedicated projection pane");
assert.match(world,/bind-and-depart[\s\S]*Bind (?:&amp;|&) Depart/,"Bind & Depart must live in The world");
assert.doesNotMatch(world,/clear-context-action|target-bin-rail|writing-palette|pages-section-tabs/,"The world must not inherit Write or Pages controls");

const collectedWorld=rendered["Collected world"];
assert.match(collectedWorld,/world-pane/,"a selected collected page must open in The world rather than inventing another pane");
assert.match(collectedWorld,/collected-world-disclosure[\s\S]*Collected World Page · consumed only when departure succeeds/,"the selected collected World Page must disclose its success-only consumption rule");
assert.match(collectedWorld,/bind-and-depart[\s\S]*Bind (?:&amp;|&) Depart/,"a collected World Page must retain the native departure action");
assert.doesNotMatch(collectedWorld,/clear-context-action|target-bin-rail|writing-palette|pages-section-tabs/,"a collected World Page must not inherit Write or Pages controls");

const bornAnchored=rendered["Born anchored"];
assert.match(bornAnchored,/world-pane/,"Born anchored must remain a state of The world");
assert.match(bornAnchored,/born-anchored-toggle[\s\S]*Born anchored/,"the anchored state must expose the native toggle");
assert.match(bornAnchored,/Keep this world in the Atlas · \+\d+ essence/,"the anchored toggle must disclose its exact premium");
assert.match(bornAnchored,/bind-readiness[\s\S]*Ready/,"Born anchored must show whether the premium-adjusted bind is ready");
assert.match(bornAnchored,/bind-and-depart[\s\S]*Bind (?:&amp;|&) Depart/,"Born anchored must retain the native departure action");
assert.doesNotMatch(bornAnchored,/clear-context-action|target-bin-rail|writing-palette|pages-section-tabs/,"Born anchored must not inherit Write or Pages controls");

const clearConfirm=rendered["Clear Confirm"];
assert.match(clearConfirm,/writing-pane/,"Clear confirmation must retain Write beneath its confirmation");
assert.match(clearConfirm,/clear-context-action/,"Clear confirmation must originate from the contextual Clear action");
assert.match(clearConfirm,/clear-confirmation[\s\S]*Clear this page\?[\s\S]*Clear 2 marks[\s\S]*Keep writing/,"Clear must be explicitly confirmed with the native destructive and cancel copy");
assert.doesNotMatch(clearConfirm,/Bind &amp; Depart|Bind & Depart|bind-and-depart/,"Clear confirmation must not be paired with departure");
