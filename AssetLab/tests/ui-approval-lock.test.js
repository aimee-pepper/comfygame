import assert from "node:assert/strict";
import {mkdtemp,mkdir,readFile,rm,writeFile} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";
import {createUIApprovalProof,validateUIApprovalProof} from "../src/ui-approval-proof.js";

const temporary=await mkdtemp(join(tmpdir(),"bookbinder-ui-approval-lock-"));
const ledger=join(temporary,"ui-gallery-reviews.json"),styleDirectory=join(temporary,"approved-styles"),assetDirectory=join(temporary,"approved-assets");
process.env.ASSETLAB_UI_REVIEW_FILE=ledger;
process.env.ASSETLAB_UI_APPROVAL_STYLE_DIR=styleDirectory;
process.env.ASSETLAB_UI_APPROVAL_ASSET_DIR=assetDirectory;

const css=".phone{background:#17231d;color:#f4ead2}",fixtureStates=["Default","Selected","Confirm"],htmlByState=Object.fromEntries(fixtureStates.map(state=>[state,`<main data-state=\"${state}\">Home ${state}</main>`]));
const approved=createUIApprovalProof({screenID:"home",decision:"yes",notes:"Approved exactly",designVersion:"native-1",sourceRevision:"abc1234",fixtureStates,htmlByState,css,approvedAt:"2026-08-18T21:00:00.000Z"});
const queued=createUIApprovalProof({screenID:"party",decision:"queue",notes:"Implement after Campaigns",designVersion:"draft-2",sourceRevision:"abc1234",fixtureStates,htmlByState,css,approvedAt:"2026-08-18T21:01:00.000Z"});
const baseline=createUIApprovalProof({screenID:"campaigns",decision:"baseline",notes:"Restored baseline",designVersion:"restored-1",sourceRevision:"abc1234",fixtureStates,htmlByState,css,approvedAt:"2026-08-18T21:02:00.000Z"});

function request(method,payload,path="/__ui-reviews"){
  const bytes=payload===undefined?[]:[Buffer.from(JSON.stringify(payload))];
  return {method,url:path,headers:{host:"127.0.0.1"},async *[Symbol.asyncIterator](){yield* bytes}};
}
function response(){return {status:0,headers:{},bytes:Buffer.alloc(0),writeHead(status,headers={}){this.status=status;this.headers=headers;return this},end(value=""){this.bytes=Buffer.isBuffer(value)?value:Buffer.from(value);return this},json(){return JSON.parse(this.bytes.toString())}}}

try{
  await mkdir(styleDirectory,{recursive:true});
  await writeFile(join(styleDirectory,`${approved.styleSHA256}.css`),css);
  await writeFile(ledger,`${JSON.stringify({schemaVersion:2,updatedAt:"2026-08-18T21:02:00.000Z",reviews:{home:{choice:"yes",notes:"Approved exactly",designVersion:"native-1"},party:{choice:"queue",notes:"Implement after Campaigns",designVersion:"draft-2"},campaigns:{choice:"no",notes:"Keep restored baseline while revising"}},approvals:{home:approved,party:queued,campaigns:baseline}},null,2)}\n`);

  for(const proof of [approved,queued,baseline]){
    assert.equal(validateUIApprovalProof(proof,css),true,`${proof.screenID} stored snapshot digest must validate`);
    assert.deepEqual(Object.keys(proof.htmlByState),proof.fixtureStates,`${proof.screenID} must freeze every declared fixture state in order`);
    assert.ok(proof.fixtureStates.every(state=>proof.htmlByState[state].includes(`data-state=\"${state}\"`)));
    const tampered=structuredClone(proof);tampered.htmlByState.Default+="<p>changed</p>";
    assert.equal(validateUIApprovalProof(tampered,css),false,"changing any frozen fixture must invalidate its snapshot digest");
  }

  const {handleAssetLabRequest}=await import("../server.js");
  async function invoke(method,payload,path){const result=response();await handleAssetLabRequest(request(method,payload,path),result);return result}

  for(const [screenID,record] of [["home",{choice:"no",notes:"replace it"}],["party",{choice:"no",notes:"replace it"}]]){
    const rejected=await invoke("POST",{schemaVersion:1,screenID,record});
    assert.equal(rejected.status,409,`${screenID} approved decision must be immutable`);
  }
  const identical=await invoke("POST",{schemaVersion:1,screenID:"home",record:{choice:"yes",notes:"Approved exactly",designVersion:"native-1"}});
  assert.equal(identical.status,200,"an identical approved save is an idempotent no-op");
  assert.equal(identical.json().idempotent,true);

  const baselineReview=await invoke("POST",{schemaVersion:1,screenID:"campaigns",record:{choice:"no",notes:"Revise spacing again",designVersion:"draft-3"}});
  assert.equal(baselineReview.status,201,"No feedback remains editable while the approved baseline stays frozen");
  const afterNo=JSON.parse(await readFile(ledger,"utf8"));
  assert.deepEqual(afterNo.approvals.campaigns,baseline,"editing No feedback must not overwrite the frozen baseline");
  for(const choice of ["yes","queue"]){
    const rejected=await invoke("POST",{schemaVersion:1,screenID:"campaigns",record:{choice,notes:"new candidate",designVersion:"draft-4"}});
    assert.equal(rejected.status,409,"a restored baseline requires a separately versioned candidate and cannot be overwritten");
  }

  const editableFirst=await invoke("POST",{schemaVersion:1,screenID:"writing-desk",record:{choice:"no",notes:"First revision"}});
  const editableSecond=await invoke("POST",{schemaVersion:1,screenID:"writing-desk",record:{choice:"no",notes:"Second revision"}});
  assert.equal(editableFirst.status,201);assert.equal(editableSecond.status,201);
  assert.equal(JSON.parse(await readFile(ledger,"utf8")).reviews["writing-desk"].notes,"Second revision","unapproved No feedback must remain editable");

  const preview=await invoke("GET",undefined,"/__ui-approved-preview?screenID=home&state=Selected");
  assert.equal(preview.status,200);
  assert.equal(preview.headers["Content-Security-Policy"],"default-src 'none'; style-src 'unsafe-inline'; img-src 'self' data:; font-src 'self'; script-src 'none';");
  assert.match(preview.bytes.toString(),/Home Selected/);
  assert.doesNotMatch(preview.bytes.toString(),/<script\b|on(?:click|load|error)\s*=/i,"approved preview HTML must remain script-free");
}finally{
  delete process.env.ASSETLAB_UI_REVIEW_FILE;delete process.env.ASSETLAB_UI_APPROVAL_STYLE_DIR;delete process.env.ASSETLAB_UI_APPROVAL_ASSET_DIR;
  await rm(temporary,{recursive:true,force:true});
}

console.log("UI approval snapshots are immutable, complete, and safely previewed.");
