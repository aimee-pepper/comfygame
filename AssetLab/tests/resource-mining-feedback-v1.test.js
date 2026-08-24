import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import {execFileSync} from "node:child_process";
import {
  cancelMiningPresentation, coldRelaunchSession, committedHarvestGroup, deliverCommittedBatch,
  emptyPresentationSession, finishCurrentPresentation, miningFeedbackContract, motionSample, proofFixtures,
} from "../src/resource-mining-feedback-v1.js";

const root=path.resolve(import.meta.dirname,".."),out=path.join(root,"artifacts/resource-mining-feedback-v1");
const exporter=path.join(root,"scripts/export-resource-mining-feedback-v1.mjs"),sha=bytes=>crypto.createHash("sha256").update(bytes).digest("hex"),hash=file=>sha(fs.readFileSync(file));
const sourceManifest=JSON.parse(fs.readFileSync(path.join(root,"integration/resource-sprites-v1/manifest.json"),"utf8"));
const exactIDs=new Set(sourceManifest.resources.map(row=>row.id));

execFileSync(process.execPath,[exporter],{stdio:"inherit"});const first=fs.readFileSync(path.join(out,"manifest.json"));execFileSync(process.execPath,[exporter],{stdio:"inherit"});assert.deepEqual(fs.readFileSync(path.join(out,"manifest.json")),first,"export must be deterministic");
const m=JSON.parse(first);assert.equal(m.status,"candidate-not-approved");assert.equal(m.integrationReady,false);assert.equal(m.sourceAuthority.revision,"fb762e4682f3c53d41ca12fd64ebb8472ee8d90e");assert.equal(m.sourceIdentityPack.fieldAssets?Object.keys(m.sourceIdentityPack.fieldAssets).length:0,23);assert.deepEqual(m.miningFeedbackContract,miningFeedbackContract);
for(const resource of sourceManifest.resources){const row=m.sourceIdentityPack.fieldAssets[resource.id],field=resource.profiles.field;assert.equal(row.path,`integration/resource-sprites-v1/${field.path}`);assert.equal(row.pngSHA256,field.fileSHA256);assert.equal(row.rgbaSHA256,field.decodedRGBASHA256);assert.equal(hash(path.join(root,row.path)),row.pngSHA256);assert.deepEqual([row.width,row.height],[8,8]);}

// M01: only a newly accepted harvest batch with a positive harvested event owns one subject.
const m01=committedHarvestGroup(proofFixtures.M01.batch,exactIDs);assert.deepEqual(m01.subjects,[{resourceID:"ore",amount:3,profile:"field",logicalSize:8}]);assert.equal(m01.turnAfter,13);
const wrongAction={...proofFixtures.M01.batch,batchID:"wrong-action",sourceAction:"step"};assert.equal(committedHarvestGroup(wrongAction,exactIDs),null);assert.equal(committedHarvestGroup(proofFixtures.M05.batch,exactIDs),null);
// M02: primary/secondary event order is preserved in one group.
const m02=committedHarvestGroup(proofFixtures.M02.batch,exactIDs);assert.deepEqual(m02.subjects.map(x=>[x.resourceID,x.amount]),[["timber",5],["resin",2]]);
// M03: repeat IDs coalesce by exact positive total, at first occurrence.
const m03=committedHarvestGroup(proofFixtures.M03.batch,exactIDs);assert.deepEqual(m03.subjects.map(x=>[x.resourceID,x.amount]),[["ore",5]]);assert.equal(m03.positiveHarvestEventCount,2);
// M04: exhaustion does not create a second reward subject.
const m04=committedHarvestGroup(proofFixtures.M04.batch,exactIDs);assert.deepEqual(m04.subjects.map(x=>[x.resourceID,x.amount]),[["quartz",1]]);
// M05: malformed/zero/negative harvested entries and blocked events imply no presentation.
const invalidAmounts={...proofFixtures.M01.batch,batchID:"invalid-amounts",orderedEvents:[{kind:"harvested",resourceID:"ore",amount:0,exhausted:false},{kind:"harvested",resourceID:"ore",amount:-2,exhausted:false}]};assert.equal(committedHarvestGroup(invalidAmounts,exactIDs),null);
// M06: unique batches FIFO; duplicate delivery never replays.
let session=emptyPresentationSession("world-run-mining-proof",proofFixtures.M06a.counts);session=deliverCommittedBatch(session,proofFixtures.M06a.batch,exactIDs);session=deliverCommittedBatch(session,proofFixtures.M06b.batch,exactIDs);session=deliverCommittedBatch(session,proofFixtures.M06a.batch,exactIDs);assert.equal(session.current.batchID,"mining-m06-a");assert.deepEqual(session.queue.map(x=>x.batchID),["mining-m06-b"]);assert.deepEqual(session.seenBatchIDs,["mining-m06-a","mining-m06-b"]);session=finishCurrentPresentation(session);assert.equal(session.current.batchID,"mining-m06-b");assert.equal(session.queue.length,0);
// M07: presentation helpers never alter already-committed counts.
const beforeCounts=structuredClone(session.committedCounts);const a=motionSample({source:{x:184,y:298},destination:{x:18,y:537},groupProgress:0}),z=motionSample({source:{x:184,y:298},destination:{x:18,y:537},groupProgress:1});assert.equal(a.scale,2);assert.equal(z.scale,1);assert.equal(z.acknowledged,true);assert.deepEqual(session.committedCounts,beforeCounts);
// M08: dismiss/expiry finish only the current travelling group and advance committed FIFO once.
for(const reason of ["dismiss","expiry"]){let queued=emptyPresentationSession("world-run-mining-proof",proofFixtures.M06a.counts);queued=deliverCommittedBatch(queued,proofFixtures.M06a.batch,exactIDs);queued=deliverCommittedBatch(queued,proofFixtures.M06b.batch,exactIDs);const advanced=cancelMiningPresentation(queued,reason);assert.equal(advanced.current.batchID,"mining-m06-b");assert.deepEqual(advanced.queue,[]);assert.deepEqual(advanced.committedCounts,queued.committedCounts);const finished=cancelMiningPresentation(advanced,reason);assert.equal(finished.current,null);assert.deepEqual(finished.queue,[]);}
// Losing World ownership clears current and all queued visuals without changing committed counts.
for(const reason of ["navigation","encounter","return-home","run-change"]){let queued=emptyPresentationSession("world-run-mining-proof",proofFixtures.M06a.counts);queued=deliverCommittedBatch(queued,proofFixtures.M06a.batch,exactIDs);queued=deliverCommittedBatch(queued,proofFixtures.M06b.batch,exactIDs);const cancelled=cancelMiningPresentation(queued,reason);assert.equal(cancelled.current,null);assert.deepEqual(cancelled.queue,[]);assert.deepEqual(cancelled.committedCounts,queued.committedCounts);}
// M09: relaunch starts with persisted count and no presentation or replay receipt.
const relaunched=coldRelaunchSession("world-run-mining-proof",{ore:12});assert.deepEqual(relaunched.committedCounts,{ore:12});assert.equal(relaunched.current,null);assert.deepEqual(relaunched.queue,[]);assert.deepEqual(relaunched.seenBatchIDs,[]);
// M10: unresolved exact field identity is omitted and cannot substitute another resource.
const m10=committedHarvestGroup(proofFixtures.M10.batch,exactIDs);assert.deepEqual(m10.subjects,[]);assert.deepEqual(m10.omittedSubjects,[{resourceID:"future_resource",amount:1,profile:"field",logicalSize:8,omission:"missing-exact-field-identity"}]);

assert.deepEqual(Object.keys(m.coverage),["M01","M02","M03","M04","M05","M06","M07","M08","M09","M10"]);assert.match(m.coverage.M08,/advances one committed FIFO group/);assert.match(m.coverage.M08,/exits clear current \+ queue/);assert.equal(m.outputs.length,8);for(const row of m.outputs){const file=path.join(out,row.path),bytes=fs.readFileSync(file);assert.equal(hash(file),row.sha256);assert.equal(bytes.readUInt32BE(16),368);assert.equal(bytes.readUInt32BE(20),800);}assert.equal(hash(path.join(out,m.contactSheet.path)),m.contactSheet.sha256);
const html=fs.readFileSync(path.join(root,"resource-mining-feedback-v1.html"),"utf8"),css=fs.readFileSync(path.join(root,"resource-mining-feedback-v1.css"),"utf8"),live=fs.readFileSync(path.join(root,"resource-mining-feedback-v1-live.js"),"utf8");for(const token of ["M01","M02","M03","M04","M05","M06","M07","M08","M09","M10","exact accepted 8px"]){assert.ok(html.includes(token)||live.includes(token),token)}assert.ok(html.includes('<span class="origin-caption">Use Tile</span>'));assert.ok(html.includes("<strong>Use Tile</strong>"));assert.ok(!html.includes("<strong>Harvest</strong>"));assert.ok(!`${html}\n${live}`.match(/Committed harvest receipt|Presentation canceled|mining presentation pending|identity unavailable/i));assert.ok(css.includes("image-rendering:pixelated"));assert.ok(!`${html}\n${css}\n${live}`.match(/one particle per unit|generic cube|large inventory sprite/i));
console.log("resource mining feedback v1 passed");
