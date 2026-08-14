import assert from "node:assert/strict";
import {bugReporterContract,bugReporterFixture,reportStates,reporterTarget,resolveReporterPlacement,reporterAvailability,validateReportText,reporterSceneCommands,reporterOverlayCommands,capturedSceneCommands,readySceneCommands,resolveBugReport,localSaveResult,transportResult} from "../src/bug-reporter-kit.js";

assert.deepEqual(bugReporterContract,{version:"debug-bug-reporter-fixture-1.0.0",evidenceRole:"proposedSemanticFixture",integrationReady:false,buildScope:"DEBUG-only",initialTriage:"untriaged",screenshotTiming:"before-sheet",reporterExcludedFromScreenshot:true,transportTruth:"local outbox until a configured destination acknowledges the same report ID"});
assert.deepEqual(reportStates,["draft","saving","unsent","sending","submitted","needsAttention"]);
assert.deepEqual(reporterTarget,{width:44,height:44,defaultEdge:"trailing",defaultFraction:.68});
const screens=[
  {screenWidth:390,screenHeight:844,safeTop:59,safeBottom:34,requiredActions:[{x:16,y:730,w:358,h:50}]},
  {screenWidth:390,screenHeight:844,safeTop:59,safeBottom:34,requiredActions:[{x:12,y:680,w:110,h:52},{x:268,y:680,w:110,h:52}]},
  {screenWidth:390,screenHeight:844,safeTop:59,safeBottom:34,requiredActions:[{x:12,y:650,w:366,h:126}]}
];
for(const screen of screens){const placement=resolveReporterPlacement(screen);assert.equal(placement.ok,true);assert.equal(placement.rect.w,44);assert.equal(placement.rect.h,44);for(const action of screen.requiredActions)assert.equal(placement.rect.x<action.x+action.w&&placement.rect.x+placement.rect.w>action.x&&placement.rect.y<action.y+action.h&&placement.rect.y+placement.rect.h>action.y,false);}
for(const broken of [{...screens[0],preferredEdge:"center"},{...screens[0],preferredFraction:NaN},{...screens[0],requiredActions:[{x:NaN,y:1,w:44,h:44}]},{...screens[0],requiredActions:[{x:1,y:1,w:0,h:44}]}])assert.equal(resolveReporterPlacement(broken).ok,false);
assert.deepEqual(reporterAvailability("DEBUG"),{visible:true,accessible:true});assert.deepEqual(reporterAvailability("Release"),{visible:false,accessible:false});
assert.equal(validateReportText("  ").valid,false);assert.equal(validateReportText("Tile overlaps route").valid,true);
assert.deepEqual(capturedSceneCommands(),reporterSceneCommands);assert.deepEqual(readySceneCommands().slice(0,reporterSceneCommands.length),capturedSceneCommands());assert.deepEqual(readySceneCommands().slice(reporterSceneCommands.length),reporterOverlayCommands);
assert.equal(resolveBugReport(bugReporterFixture).ok,true);
for(const mutate of [r=>{r.extra=true;},r=>{r.context.secret="no";},r=>{r.context.actionCount=21;},r=>{r.context.screen="";},r=>{r.context.runID="";},r=>{r.whatHappened="";},r=>{r.screenshotState="captureFailed";},r=>{r.screenshotState="removed";r.captureFailureReason="captureServiceError";},r=>{r.state="submitted";},r=>{r.remoteReference="premature";}]){const broken=structuredClone(bugReporterFixture);mutate(broken);assert.equal(resolveBugReport(broken).ok,false);}
for(const noScreenshot of [{...structuredClone(bugReporterFixture),screenshotState:"removed"},{...structuredClone(bugReporterFixture),screenshotState:"captureFailed",captureFailureReason:"appSceneUnavailable"}])assert.equal(resolveBugReport(noScreenshot).ok,true,"valid text report survives capture failure/removal");
const saved=localSaveResult(bugReporterFixture);assert.deepEqual(saved,{ok:true,state:"unsent",message:"Saved on this phone",queue:"Untriaged",id:bugReporterFixture.id,diagnostics:[]});
const unsent={...structuredClone(bugReporterFixture),state:"unsent"},needsAttention={...structuredClone(bugReporterFixture),state:"needsAttention"};
const failed=transportResult(unsent,{acknowledged:false});assert.equal(failed.state,"needsAttention");assert.match(failed.message,/Saved on this phone/);
const submitted=transportResult(needsAttention,{acknowledged:true,remoteReference:"triage-884"});assert.equal(submitted.state,"submitted");assert.equal(submitted.id,bugReporterFixture.id);assert.equal(submitted.remoteReference,"triage-884");
assert.equal(transportResult(unsent,{acknowledged:true,remoteReference:null}).ok,false);assert.equal(transportResult(unsent,{acknowledged:true,remoteReference:""}).ok,false);assert.equal(transportResult(bugReporterFixture,{acknowledged:false}).ok,false);assert.equal(localSaveResult(unsent).ok,false);
console.log("Asset Lab proposed bug-reporter fixture tests passed.");
