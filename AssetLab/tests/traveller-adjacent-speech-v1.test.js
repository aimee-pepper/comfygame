import assert from "node:assert/strict";
import {createHash} from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";
import {
  bubblePlacement, clearTravellerPresentation, eligibleNewlyAdjacent, emptyTravellerSpeechSession,
  enqueueNewlyAdjacent, exactEligibleTraveller, expectedSpeechRows, expireTravellerBubble,
  proofCensus, speechMotionSample, travellerSpeechContract,
} from "../src/traveller-adjacent-speech-v1.js";
import {buildExactSpeechRows, selectTravellerSpeech} from "../src/traveller-speech-source-receipt-v1.js";

const assetLab=path.resolve(path.dirname(fileURLToPath(import.meta.url)),"..");
const receipt=JSON.parse(fs.readFileSync(path.join(assetLab,"integration/traveller-adjacent-speech-v1/source-receipt.json")));
const manifest=JSON.parse(fs.readFileSync(path.join(assetLab,"artifacts/traveller-adjacent-speech-v1/manifest.json")));
const html=fs.readFileSync(path.join(assetLab,"traveller-adjacent-speech-v1.html"),"utf8");
const live=fs.readFileSync(path.join(assetLab,"traveller-adjacent-speech-v1-live.js"),"utf8");
const exporter=fs.readFileSync(path.join(assetLab,"scripts/export-traveller-adjacent-speech-v1.mjs"),"utf8");
const sha=value=>createHash("sha256").update(value).digest("hex");
const run="world-run-traveller-proof",receiptIDs=receipt.rows.map(row=>row.travellerID);
const action=(kind="step",extra={})=>({kind,accepted:true,finalPresented:true,teleportLike:false,...extra});
const tile=(travellerID,point,extra={})=>({point,worldRunID:run,visibility:"full",isRevealed:true,isCrumbled:false,content:{kind:"traveller",travellerID},...extra});

assert.equal(travellerSpeechContract.integrationReady,false);
assert.equal(receipt.status,"candidate-unapproved");assert.equal(receipt.integrationReady,false);
assert.equal(manifest.status,"candidate-unapproved");assert.equal(manifest.integrationReady,false);
assert.equal(receipt.rows.length,29);assert.equal(new Set(receipt.rows.map(row=>row.travellerID)).size,29);
assert.deepEqual(receipt.rows.map(({travellerID,sourceKey,text})=>({travellerID,sourceKey,text})),expectedSpeechRows);
assert.equal(receipt.rows.filter(row=>row.sourceKey.startsWith("exchange:")).length,2);
assert.deepEqual(receipt.rows.filter(row=>row.sourceKey.startsWith("exchange:")).map(row=>row.travellerID),["dagg","noll"]);
assert.equal(new Set(receipt.rows.map(row=>row.effectiveMeetingCorpusFingerprint)).size,1);
assert.equal(receipt.rows[0].effectiveMeetingCorpusFingerprint,receipt.effectiveMeetingCorpusFingerprint);
assert.equal(receipt.generatedOverlay.meetingCount,23);
assert.ok(receipt.forbiddenSources.includes("offer")&&receipt.forbiddenSources.includes("accepted")&&receipt.forbiddenSources.includes("ask"));

// T12 executable fail-closed source mutations: no already-exported receipt can mask drift.
const maraAuthority=expectedSpeechRows.find(row=>row.travellerID==="mara"),nollAuthority=expectedSpeechRows.find(row=>row.travellerID==="noll");
const buildRows=(effectiveMeetings,expectedRows)=>buildExactSpeechRows({effectiveMeetings,expectedRows,corpusFingerprint:"fixture-corpus",hashMeeting:meeting=>sha(JSON.stringify(meeting))});
const maraMeeting={travellerID:"mara",displayName:"Mara",opening:`Narration. ${maraAuthority.text}`,questions:[],offer:"\"Come with me.\"",accepted:"\"All right.\"",declined:"\"No.\""};
assert.equal(selectTravellerSpeech(maraMeeting).text,maraAuthority.text);
assert.equal(buildRows([maraMeeting],[maraAuthority]).length,1);
assert.throws(()=>buildRows([{...maraMeeting,opening:"Narration only."}],[maraAuthority]),/speech-source-missing:mara/);
assert.throws(()=>buildRows([{...maraMeeting,opening:"Narration. \"Changed selected bytes.\""}],[maraAuthority]),/speech-authority-mismatch:mara/);
const nollMeeting={travellerID:"noll",displayName:"Noll",opening:"Unquoted narration.",questions:[{id:"noll.join_left",ask:"\"Why?\"",reply:`${nollAuthority.text} More unquoted narration.`}],offer:"\"Offer quote.\"",accepted:"\"Accepted quote.\"",declined:"\"Declined quote.\""};
assert.equal(buildRows([nollMeeting],[nollAuthority])[0].sourceKey,"exchange:noll.join_left:first-direct-speech");
assert.throws(()=>buildRows([{...nollMeeting,questions:[{...nollMeeting.questions[0],reply:"Unquoted reply."}]}],[nollAuthority]),/speech-source-missing:noll/);
const excludedOnly={...nollMeeting,questions:[{id:"noll.join_left",ask:"\"Quoted player ask.\"",reply:"Unquoted reply."}],offer:"\"Quoted offer.\"",accepted:"\"Quoted accepted.\"",declined:"\"Quoted declined.\""};
assert.equal(selectTravellerSpeech(excludedOnly),null);assert.throws(()=>buildRows([excludedOnly],[nollAuthority]),/speech-source-missing:noll/);

// T01: exact successful step into new cardinal adjacency.
const t01=eligibleNewlyAdjacent({action:action(),beforePlayer:{x:0,y:2},afterPlayer:{x:1,y:2},finalTiles:[tile("mara",{x:1,y:1})],worldRunID:run,activeWorldRunID:run,receiptTravellerIDs:receiptIDs});
assert.deepEqual(t01,[{travellerID:"mara",direction:"north",point:{x:1,y:1},worldRunID:run}]);
let session=enqueueNewlyAdjacent(emptyTravellerSpeechSession(run),t01,receipt.rows);
assert.equal(session.current.travellerID,"mara");assert.deepEqual(session.shownTravellerIDs,["mara"]);
assert.equal(session.current.text,receipt.rows.find(row=>row.travellerID==="mara").text);

// T02/T03: adjacency retained and same-session leave/re-enter do not repeat.
const t02=eligibleNewlyAdjacent({action:action(),beforePlayer:{x:0,y:1},afterPlayer:{x:1,y:0},finalTiles:[tile("mara",{x:1,y:1})],worldRunID:run,activeWorldRunID:run,receiptTravellerIDs:receiptIDs});
assert.deepEqual(t02,[]);
const t03=eligibleNewlyAdjacent({action:action(),beforePlayer:{x:1,y:2},afterPlayer:{x:1,y:1},finalTiles:[tile("mara",{x:1,y:0})],worldRunID:run,activeWorldRunID:run,shownTravellerIDs:["mara"],receiptTravellerIDs:receiptIDs});
assert.deepEqual(t03,[]);

// T04: refusal/no movement/teleport-like/nonmovement never qualifies.
for(const blockedAction of [action("step",{accepted:false}),action("step",{finalPresented:false}),action("step",{teleportLike:true}),action("selection"),action("step")]){
  const before=blockedAction===blockedAction?{x:0,y:2}:{x:0,y:2};
  const after=blockedAction.kind==="step"&&blockedAction.accepted&&blockedAction.finalPresented&&!blockedAction.teleportLike?{x:0,y:2}:{x:1,y:2};
  assert.deepEqual(eligibleNewlyAdjacent({action:blockedAction,beforePlayer:before,afterPlayer:after,finalTiles:[tile("mara",{x:1,y:1})],worldRunID:run,activeWorldRunID:run,receiptTravellerIDs:receiptIDs}),[]);
}
assert.deepEqual(eligibleNewlyAdjacent({action:action(),beforePlayer:{x:0,y:2},afterPlayer:{x:2,y:2},finalTiles:[tile("mara",{x:2,y:1})],worldRunID:run,activeWorldRunID:run,receiptTravellerIDs:receiptIDs}),[],"step must be a single cardinal move");

// T05: only full, revealed, intact exact traveller in the current run.
assert.equal(exactEligibleTraveller(tile("mara",{x:0,y:0}),run),true);
for(const bad of [
  tile("mara",{x:0,y:0},{visibility:"fringe"}),tile("mara",{x:0,y:0},{visibility:"remembered"}),tile("mara",{x:0,y:0},{visibility:"hidden"}),
  tile("mara",{x:0,y:0},{isRevealed:false}),tile("mara",{x:0,y:0},{isCrumbled:true}),tile("mara",{x:0,y:0},{content:null}),tile("mara",{x:0,y:0},{worldRunID:"other-run"}),
])assert.equal(exactEligibleTraveller(bad,run),false);

// T06: same tile has no cardinal bubble ownership.
assert.deepEqual(eligibleNewlyAdjacent({action:action(),beforePlayer:{x:0,y:1},afterPlayer:{x:1,y:1},finalTiles:[tile("mara",{x:1,y:1})],worldRunID:run,activeWorldRunID:run,receiptTravellerIDs:receiptIDs}),[]);

// T07: N/E/S/W order remains exact under adversarial density.
const neighbours=[tile("mara",{x:0,y:-1}),tile("tovin",{x:1,y:0}),tile("oda",{x:0,y:1}),tile("noll",{x:-1,y:0})];
const t07=eligibleNewlyAdjacent({action:action("auto-travel"),beforePlayer:{x:9,y:9},afterPlayer:{x:0,y:0},finalTiles:neighbours.reverse(),worldRunID:run,activeWorldRunID:run,receiptTravellerIDs:receiptIDs});
assert.deepEqual(t07.map(row=>row.direction),["north","east","south","west"]);assert.deepEqual(t07.map(row=>row.travellerID),["mara","tovin","oda","noll"]);
session=enqueueNewlyAdjacent(emptyTravellerSpeechSession(run),t07,receipt.rows);assert.equal(session.current.travellerID,"mara");assert.deepEqual(session.queue.map(row=>row.travellerID),["tovin","oda","noll"]);

// T08: expiry advances exactly once; a new accepted action clears presentation without touching shown IDs.
const afterExpiry=expireTravellerBubble(session);assert.equal(afterExpiry.current.travellerID,"tovin");assert.deepEqual(afterExpiry.queue.map(row=>row.travellerID),["oda","noll"]);
assert.deepEqual(afterExpiry.shownTravellerIDs,["mara","tovin"]);
const cleared=clearTravellerPresentation(afterExpiry,"accepted-world-action");assert.equal(cleared.current,null);assert.deepEqual(cleared.queue,[]);assert.deepEqual(cleared.shownTravellerIDs,["mara","tovin"]);

// T09/T15: stale eligible arrays fail closed across world-run changes, and deterministic replay matches.
const stale=structuredClone(t01);stale[0].worldRunID="old-run";
assert.deepEqual(enqueueNewlyAdjacent(emptyTravellerSpeechSession(run),stale,receipt.rows),emptyTravellerSpeechSession(run));
assert.deepEqual(enqueueNewlyAdjacent(emptyTravellerSpeechSession(run),t01,receipt.rows),enqueueNewlyAdjacent(emptyTravellerSpeechSession(run),t01,receipt.rows));
for(const reason of ["meeting","encounter","return","navigation","run-change","traveller-removed","traveller-crumbled","visibility-loss"]){const closed=clearTravellerPresentation(session,reason);assert.equal(closed.current,null);assert.deepEqual(closed.queue,[])}

// T10: cold relaunch is an empty transient session; adjacency alone never creates a bubble.
assert.deepEqual(emptyTravellerSpeechSession(run),{worldRunID:run,shownTravellerIDs:[],current:null,queue:[]});

// T11: auto-travel consumes only the final player position and final tiles.
const t11=eligibleNewlyAdjacent({action:action("auto-travel"),beforePlayer:{x:0,y:0},afterPlayer:{x:8,y:8},finalTiles:[tile("mara",{x:8,y:7})],worldRunID:run,activeWorldRunID:run,receiptTravellerIDs:receiptIDs});
assert.deepEqual(t11.map(row=>row.travellerID),["mara"]);

// T12/T13: source completeness and long lines survive exactly.
for(const id of ["oda","tovin"]){const row=receipt.rows.find(item=>item.travellerID===id);assert.ok(row.text.length>75);assert.ok(html.includes(`${id}-wrap-368x800.png`))}
assert.equal(receipt.rows.some(row=>row.text.includes("…")),false);

// T14: pin the native full-meeting and recruitment owners byte-for-byte; this boundary does not touch Sources.
assert.equal(manifest.preservedInteractionAuthority.length,4);
for(const authority of manifest.preservedInteractionAuthority){const file=path.resolve(assetLab,"..",authority.file);assert.ok(fs.existsSync(file));assert.equal(sha(fs.readFileSync(file)),authority.sha256)}
assert.deepEqual(fs.readdirSync(path.join(assetLab,"..","Sources"),{recursive:true}).filter(file=>typeof file==="string"&&file.includes("traveller-adjacent-speech-v1")),[]);
assert.ok(manifest.exclusions.includes("meeting-content-change"));assert.equal(manifest.contract.mutation,"none");

// Visual bounds: edge placement stays in map, points to the exact anchor, and is never hit-testable.
for(const placement of [
  bubblePlacement({anchorX:18,anchorY:82,bubbleWidth:284,bubbleHeight:120,stageWidth:368,mapTop:64,mapBottom:492}),
  bubblePlacement({anchorX:350,anchorY:460,bubbleWidth:284,bubbleHeight:120,stageWidth:368,mapTop:64,mapBottom:492}),
]){assert.ok(placement.x>=8&&placement.x+placement.width<=360);assert.ok(placement.y>=64&&placement.y+placement.height<=492);assert.equal(placement.hitTestTransparent,true);assert.ok(placement.tailX>=12&&placement.tailX<=272)}
assert.deepEqual(speechMotionSample(0),{opacity:0,translateY:6});assert.deepEqual(speechMotionSample(1),{opacity:1,translateY:0});

// No identity or proof instrumentation is mounted inside the phone.
assert.equal(html.includes("bubble-name"),false);assert.equal(html.includes("map-proof-label"),false);assert.equal(live.includes("person-label"),false);
assert.equal(exporter.includes("The existing full meeting owns this arrival."),false);assert.equal(html.includes("The existing full meeting owns this arrival."),false);
assert.equal(html.includes("integrationReady:true"),false);assert.equal(proofCensus.length,15);assert.equal(manifest.coverage.length,15);
assert.equal(manifest.evidence.length,10);for(const row of manifest.evidence)assert.ok(fs.existsSync(path.join(assetLab,"artifacts/traveller-adjacent-speech-v1",row.file)));

console.log("Traveller Adjacent Speech Bubble v1: T01–T15, 29 source rows, run ownership and no identity leakage PASS");
