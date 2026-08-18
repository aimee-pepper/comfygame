import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {preservationLedger} from "../src/ui-preservation-ledger.js";
import {fixtureStatesByScreen,fontChoices,implementationReviewPacket,implementationReviewRecordPacket,nativeConformance,normalizeImplementationReviews,priorityScreenIDs,renderers,renderScreen,reviewStorageKey,screens} from "../src/ui-gallery-app.js";
const galleryApp=await readFile(new URL("../src/ui-gallery-app.js",import.meta.url),"utf8");
const css=await readFile(new URL("../ui-gallery.css",import.meta.url),"utf8");
const galleryHtml=await readFile(new URL("../ui-gallery.html",import.meta.url),"utf8");
const required=["Campaigns","Home","Writing Desk","Storehouse","Workshop","Party","Essence Spring","Constellation","Library","Bestiary","Research","World History","Blacksmith","Trading Post","Recycler","Tannery","Bowyer","Armoury","Weaponsmith","Scriptorium","Survey Post","Apothecary","Reliquary","Wayfarer’s Table","Anchorage","Distillery","Channelworks","Firepit","Gear","World","Encounter","Loot Decision","Return Recap","Settings"];
assert.deepEqual(screens.map(({title})=>title),required,"screen order is an intentional ordinary-phone contract");
assert.deepEqual([...renderers.keys()],required,"every gallery entry must have one explicit renderer");
assert.deepEqual([...priorityScreenIDs],["campaigns","home","writing-desk","world"],"the default review lane must stay focused on the four explicitly prioritized gameplay screens");
assert.match(galleryApp,/category="Priority"/,"the gallery must open in the focused review lane rather than the 34-screen backlog");
assert.match(galleryApp,/function step\(delta\)\{const sequence=filtered\(\)/,"Previous and Next must stay inside the selected review lane");
assert.deepEqual(Object.keys(preservationLedger).sort(),required.slice().sort(),"every proposed screen must audit the native structure it preserves");
for(const [title,[nativeSource,...facts]] of Object.entries(preservationLedger)){assert.match(nativeSource,/\.swift/,`${title} must name its native source`);assert.ok(facts.length>=2,`${title} needs explicit preservation facts`)}
assert.match(css,/width:368px;height:800px/);
for(const title of required){
  for(const fixtureState of ["Default","Selected","Confirm"]){
    const html=renderScreen(title,fixtureState);
    assert.match(html,/class="safe-top"/,`${title} ${fixtureState} must render phone chrome`);
    assert.ok(html.length>500,`${title} ${fixtureState} must render a substantive fixture`);
  }
}
const requiredMarkers={
  Campaigns:"book-progress",Home:"town-scene","Writing Desk":"writing-desk",Storehouse:"storehouse-cabinet",Workshop:"project-strip",Party:"party-formation",
  "Essence Spring":"spring-basin",Constellation:"constellation-surface",Library:"library-catalogue",Bestiary:"specimen-folio","World History":"world-archive",Blacksmith:"comparison-rack",
  "Trading Post":"market-stall",
  Recycler:"salvage-table",Tannery:"hide-frame",Bowyer:"bow-jig",Armoury:"armour-stand",
  Weaponsmith:"weapon-rack",Apothecary:"bottle-shelf",Reliquary:"interpretation-board",
  "Survey Post":"instrument-board",
  "Wayfarer’s Table":"fieldcraft-board",Distillery:"class=\"still\"",Channelworks:"conduit-diagram",
  Firepit:"camp-circle","Loot Decision":"gear-balance","Return Recap":"return-outcome",Settings:"appearance-board"
};
for(const [title,marker] of Object.entries(requiredMarkers))assert.match(renderScreen(title),new RegExp(marker),`${title} must reach its specialized composition`);
assert.deepEqual(fixtureStatesByScreen.constellation,["Default","Selected","Confirm","Bought"],"Constellation must expose its distinct shortfall, selection, confirmation and purchased states");
assert.match(renderScreen("Constellation","Default"),/✦ 1 Motes[\s\S]*Needs 2 more Motes/,"Constellation Default must be the truthful shortfall fixture");
assert.match(renderScreen("Constellation","Selected"),/Ready to fix in place[\s\S]*Rank[\s\S]*0\/1[\s\S]*Cost[\s\S]*3 Motes[\s\S]*Fix in place · 3 Motes/,"Constellation Selected must put the exact purchase facts and action inside anchored detail");
assert.match(renderScreen("Constellation","Confirm"),/Fix The Long Instruction in place\?[\s\S]*This permanently changes Reality for the current campaign\.[\s\S]*Spend 3 Motes[\s\S]*Not yet/,"Constellation Confirm must remain pre-purchase and show the native confirmation dialog");
assert.match(renderScreen("Constellation","Bought"),/✦ 1 Motes[\s\S]*Fixed in place[\s\S]*Rank[\s\S]*1\/1/,"Constellation Bought must show the post-purchase rank and independent bought state");
assert.doesNotMatch(renderScreen("Constellation","Bought"),/Fix in place ·|Cost[\s\S]*3 Motes|bottom-rail/,"a bought Constellation node must expose no purchase or global action");
assert.doesNotMatch(renderScreen("Constellation","Default"),/orbit-ring|star-inscription|0 → 1|costs 3|>slot<|>owned<|bottom-rail/,"Constellation must not invent graph structure, shorthand or global actions");
assert.equal(nativeConformance.constellation.status,"verified","Constellation may reopen review only after all current purchase states match native behavior");
assert.match(renderScreen("Campaigns"),/OLDER TEST VERSION[\s\S]*Format 12[\s\S]*current format 13/,"campaign proposal must preserve explicit legacy/current-version handling");
assert.match(renderScreen("Apothecary"),/Scent Mask/,"Apothecary must represent the live learned treatment truthfully");
assert.match(renderScreen("Library"),/Unknown and legacy records remain unguessed/,"Library must not infer missing record identity");
assert.match(renderScreen("Bestiary"),/quadruped · long ears[\s\S]*sinuous · membrane appendage/,"Bestiary must preserve materially different generated morphology");
assert.match(renderScreen("World History"),/Earlier[\s\S]*World 9[\s\S]*Later[\s\S]*World 12/,"History must expose chronology independently of selection order");
assert.match(renderScreen("Trading Post"),/owned 2 · stock 5[\s\S]*properties unknown/,"Trading Post must keep owned, stock and disclosure truth on its wares");
assert.match(renderScreen("Survey Post"),/EIGHT INDEPENDENT ROOTS[\s\S]*NO SHARED NODE EDGE/,"Survey instruments must not be flattened into a fake graph");
assert.match(renderScreen("World","Travel"),/world-map-grid[\s\S]*world-place-info[\s\S]*Field Kit[\s\S]*world-minimap/,"World must preserve its fixed-scale map, place truth, persistent Field Kit status, and minimap");
assert.doesNotMatch(renderScreen("World","Travel"),/world-event-log|world-map-scale|FIXED 11×11/,"World must not restore the rejected redundant narration bar or camera badge");
assert.match(renderScreen("Encounter"),/CURRENT ACTOR · BINDER[\s\S]*Glassback · 6\/13[\s\S]*Selected consequence/,"Encounter must expose current actor, exact target and consequence");
const campaignsDefault=renderScreen("Campaigns","Default");
assert.equal((campaignsDefault.match(/class="book-stack campaign-book/g)??[]).length,3,"Campaigns must keep three equally structured campaign buttons in the review fixture");
for(const [label,title] of [["seven progress volumes","Aimee’s Book"],["four progress volumes","Field Notes"],["two legacy volumes","Old Test Book"]]){
  const volumeIndex=campaignsDefault.indexOf(`aria-label="${label}"`),titleIndex=campaignsDefault.indexOf(`<h4>${title}</h4>`);
  assert.ok(volumeIndex>=0&&volumeIndex<titleIndex,`${title} must show its progress-book row above its unchanged title and facts`);
}
assert.match(campaignsDefault,/13 \/ 13 health · Level 4[\s\S]*Base · played today/,"Campaigns must retain current health, level, location and last-played truth");
assert.match(campaignsDefault,/OLDER TEST VERSION[\s\S]*Format 12[\s\S]*current format 13[\s\S]*Export unchanged · confirmed Delete/,"an older campaign must expose both versions and safe actions without implying load");
assert.match(renderScreen("Campaigns","Selected"),/Selected campaign[\s\S]*Continue loads the newest playable campaign/,"Selected must explain Continue authority without changing card geometry");
assert.match(renderScreen("Campaigns","Confirm"),/Delete “Old Test Book”\?[\s\S]*Cancel[\s\S]*Delete campaign/,"Confirm must name the exact campaign and keep cancellation available");
assert.match(css,/Foundation v0\.2/);
assert.match(css,/\.foundation-board/);
assert.match(css,/@font-face\{font-family:"Pixelify Sans"/,"gallery must bundle its compact mixed-case pixel display font");
assert.deepEqual(fontChoices.map(({id})=>id),["jersey-tiny","pixelify","jersey","silkscreen","tiny5"],"font chooser order is a deliberate review contract");
assert.match(galleryHtml,/id="pixel-font-choice"/,"gallery must expose a live pixel-font chooser");
assert.match(galleryHtml,/Yes, implementation ready[\s\S]*Implement, but queue changes[\s\S]*No, not ready/,"every preview must expose full approval, queued approval and blocked decisions");
assert.match(galleryHtml,/id="implementation-feedback"[\s\S]*Required when this screen is not ready/,"a not-ready review must request specific feedback");
assert.match(galleryHtml,/id="implementation-review-save"[\s\S]*Save feedback/,"review feedback must have an explicit Save button");
assert.match(galleryHtml,/Native behavior contract[\s\S]*id="assetlab-revision"/,"reviewers must see native conformance and the exact served AssetLab revision");
assert.deepEqual(Object.keys(nativeConformance).sort(),screens.map(({id})=>id).sort(),"every gallery screen must carry an explicit native-conformance status");
assert.ok(Object.values(nativeConformance).every(record=>["verified","failed","pending"].includes(record.status)&&record.source&&record.designVersion),"conformance records must be closed, source-owned and design-versioned");
assert.equal(nativeConformance["writing-desk"].designVersion,"native-2","the rebuilt Writing candidate must request a fresh review instead of inheriting feedback for the earlier layout");
assert.equal(nativeConformance.world.designVersion,"native-2","the rebuilt World candidate must request a fresh review instead of inheriting feedback for the earlier layout");
assert.match(galleryApp,/input\.value==="yes"&&!conformanceReady/,"implementation-ready approval must be unavailable until native behavior is verified");
assert.match(galleryApp,/const staleApproval=Boolean\(storedRecord\.choice\)&&storedRecord\.designVersion!==conformance\.designVersion/,"every decision for a superseded mock must remain historical rather than silently applying to the rebuilt screen");
assert.equal(reviewStorageKey,"bookbinder.assetlab.ui-gallery-reviews.v1");
assert.deepEqual(normalizeImplementationReviews({campaigns:{choice:"no",notes:"Tighten spacing",designVersion:"draft-0"},home:{choice:"yes",notes:""},gear:{choice:"queue",notes:"Load after a details click",designVersion:"draft-0"},invented:{choice:"yes",notes:"ignored"}}),{campaigns:{choice:"no",notes:"Tighten spacing",designVersion:"draft-0"},home:{choice:"yes",notes:"",designVersion:""},gear:{choice:"queue",notes:"Load after a details click",designVersion:"draft-0"}},"stored reviews must retain the explicit queued-change override and reject unknown screens");
assert.deepEqual(implementationReviewPacket({home:{choice:"yes",notes:"",designVersion:"native-1"},invented:{choice:"no",notes:"ignored"}}),{schemaVersion:1,reviews:{home:{choice:"yes",notes:"",designVersion:"native-1"}}},"the shared packet helper must emit only normalized, versioned gallery reviews");
assert.deepEqual(implementationReviewRecordPacket("campaigns",{choice:"no",notes:"Keep the progress books",designVersion:"draft-0"}),{schemaVersion:1,screenID:"campaigns",record:{choice:"no",notes:"Keep the progress books",designVersion:"draft-0"}},"explicit Save must send only the current screen review and reviewed design version");
assert.deepEqual(implementationReviewRecordPacket("campaigns",{choice:"queue",notes:"A details-first load is acceptable",designVersion:"native-1"}),{schemaVersion:1,screenID:"campaigns",record:{choice:"queue",notes:"A details-first load is acceptable",designVersion:"native-1"}},"queued implementation must remain a first-class shared decision");
assert.equal(implementationReviewRecordPacket("invented",{choice:"yes",notes:"ignored"}),null,"explicit Save must fail closed for an unknown screen");
assert.match(galleryApp,/Draft saved on this device · not shared yet\./,"typing must disclose that feedback remains a local draft");
assert.doesNotMatch(galleryApp,/implementation-feedback"\)\.oninput[\s\S]{0,180}syncImplementationReviews/,"typing feedback must not POST to the shared ledger");
assert.ok(galleryApp.indexOf('await fetch("/__ui-reviews"')<galleryApp.indexOf("delete implementationDrafts[screenID]"),"Save must retain the draft until the server responds");
assert.ok(galleryApp.indexOf("if(!response.ok)throw")<galleryApp.indexOf('state:"shared"'),"Save must not display shared success for a failed response");
assert.match(galleryApp,/Could not save to the shared project ledger\. Your draft is still on this device/,"a failed Save must visibly promise that the draft was retained");
assert.match(galleryApp,/An earlier implementation decision is preserved for the previous mock\. This rebuilt screen needs a fresh review\./,"neither full nor queued approval may silently transfer to a rebuilt screen");
assert.match(galleryApp,/Implement, but queue changes to explicitly override noncritical differences/,"the review tool must explain Aimee's explicit conformance override");
assert.match(css,/\.implementation-review/);
for(const family of ["Jersey 10","Silkscreen","Tiny5"])assert.match(css,new RegExp(`font-family:\"${family}\"`),`${family} must be bundled for live comparison`);
assert.match(css,/--font-reading/,"long prose must retain a separate readable face");
assert.match(galleryHtml,/Pixel display type owns titles, labels and controls/,"gallery must make the pixel/display prose split reviewable");
assert.match(css,/town-starting-home-v1-phone-v2\.png/,"Home must use the phone-composed full-scene asset");
assert.match(css,/\.town-scene\{height:624px/,"Home scene must own the full phone content body");
assert.match(renderScreen("Home"),/town-tabs/,"Home destinations must overlay the scene instead of shrinking it");
assert.match(renderScreen("Home"),/>Bind &amp; Depart<|>Bind & Depart</,"Home must not claim the Base action binds a named existing world");
assert.doesNotMatch(renderScreen("Wayfarer’s Table"),/bottom-rail|route-table|Review departure/,"Wayfarer must remain the native informational station, without invented planning or actions");
assert.match(renderScreen("Wayfarer’s Table"),/Satchel capacity[\s\S]*10 slots[\s\S]*Organic harvests[\s\S]*\+1 each[\s\S]*Visible flora[\s\S]*identified on sight/,"Wayfarer must render the exact current tier-zero fieldcraft benefits");
assert.equal(nativeConformance["wayfarer-s-table"].status,"verified","Wayfarer may reopen implementation review only after its passive native contract is exact");
assert.match(renderScreen("Reliquary"),/The Reliquary[\s\S]*Field interpretation[\s\S]*Site locations[\s\S]*revealed on arrival[\s\S]*Recovered resources[\s\S]*\+1 each[\s\S]*Reaching and searching each place is still fieldwork/,"Reliquary must render only its exact passive native benefits and fieldwork caveat");
assert.doesNotMatch(renderScreen("Reliquary"),/Glass Compass|singular object|provenance|inscription|bottom-rail|Read inscription/,"Reliquary must not invent an artifact collection workflow or actions");
assert.equal(nativeConformance.reliquary.status,"verified","Reliquary may reopen implementation review only after its passive native contract is exact");
assert.deepEqual(fixtureStatesByScreen.settings,["Default","DEBUG"],"Settings must separate release and DEBUG-only destinations");
const settingsDefault=renderScreen("Settings","Default"),settingsDebug=renderScreen("Settings","DEBUG");
assert.match(settingsDefault,/Appearance[\s\S]*System[\s\S]*Light[\s\S]*Dark[\s\S]*Field Notes[\s\S]*How writing and expeditions work[\s\S]*Save games[\s\S]*Return to the campaign chooser/,"release Settings must preserve its exact themes and two destinations");
assert.match(settingsDefault,/System follows your phone, including its sunset schedule\. Dark overrides it — for when the phone is bright and you are not\./,"Settings must preserve the exact appearance explanation");
assert.doesNotMatch(settingsDefault,/Gameplay|Sound|Help|Reset|Done|Homework|Debug Tools|acceptance|Installed source|bottom-rail/,"release Settings must contain neither invented utilities nor DEBUG-only content or actions");
for(const label of ["Homework","Debug Tools","Compound Assembly acceptance","Starter World Pages acceptance","Wild World Pages acceptance","Rune Dictionary acceptance","Page Templates acceptance","Installed source"])assert.match(settingsDebug,new RegExp(label),`DEBUG Settings must retain ${label}`);
assert.match(settingsDebug,/Save games[\s\S]*data-direction="exit"|data-direction="exit"[\s\S]*Save games/,"Save games must remain the sole campaign-exit destination");
assert.equal((settingsDebug.match(/data-direction="exit"/g)??[]).length,1,"only Save games may use the exit direction grammar");
assert.equal(nativeConformance.settings.status,"verified","Settings may reopen review only after release and DEBUG states match native behavior");
for(const marker of new Set(Object.values(requiredMarkers))){
  const className=marker.replace(/^class=\\?"|\\?"$/g,"");
  assert.match(css,new RegExp(`\\.${className}`),`${className} needs an authored style contract`);
}
console.log(`UI gallery covers ${required.length} ordinary-phone screens.`);
