import assert from "node:assert/strict";
import {mkdtemp,readFile,rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";

const temporary=await mkdtemp(join(tmpdir(),"bookbinder-ui-reviews-"));
const ledger=join(temporary,"nested","ui-gallery-reviews.json");
process.env.ASSETLAB_UI_REVIEW_FILE=ledger;
process.env.ASSETLAB_UI_APPROVAL_STYLE_DIR=join(temporary,"approved-styles");
process.env.ASSETLAB_UI_APPROVAL_ASSET_DIR=join(temporary,"approved-assets");
const {handleAssetLabRequest}=await import("../server.js");

function request(method,payload,path="/__ui-reviews"){
  const bytes=payload===undefined?[]:[Buffer.from(JSON.stringify(payload))];
  return {method,url:path,headers:{host:"127.0.0.1"},async *[Symbol.asyncIterator](){yield* bytes}};
}
function response(){
  return {status:0,headers:{},bytes:Buffer.alloc(0),writeHead(status,headers={}){this.status=status;this.headers=headers;return this},end(value=""){this.bytes=Buffer.isBuffer(value)?value:Buffer.from(value);return this},json(){return JSON.parse(this.bytes.toString())}};
}
async function invoke(method,payload){const result=response();await handleAssetLabRequest(request(method,payload),result);return result}

try{
  const empty=await invoke("GET");
  assert.equal(empty.status,200);
  assert.equal(empty.headers["Cache-Control"],"no-store");
  assert.deepEqual(empty.json(),{schemaVersion:2,reviews:{},approvals:{}},"a missing shared ledger must read as an empty review packet");
  const meta=response();await handleAssetLabRequest(request("GET",undefined,"/__assetlab-meta"),meta);
  assert.equal(meta.status,200);
  assert.equal(meta.headers["Cache-Control"],"no-store");
  assert.match(meta.json().revision,/^[a-f0-9]{7,12}$|^unavailable$/,"review UI must expose the exact served source revision");

  const invalid=await invoke("POST",{schemaVersion:1,screenID:"home",record:{choice:"maybe",notes:""}});
  assert.equal(invalid.status,400,"invalid review choices must be rejected without persistence");
  assert.equal((await invoke("POST",{schemaVersion:1,screenID:"home",record:{choice:"queue",notes:"  "}})).status,400,"queued implementation requires a concrete follow-up note");
  assert.equal((await invoke("POST",{schemaVersion:1,screenID:"home",record:{choice:"no",notes:""}})).status,400,"not-ready feedback requires a concrete correction note");

  const reviews={home:{choice:"yes",notes:""},"writing-desk":{choice:"no",notes:"Keep the page larger"}};
  const homeSaved=await invoke("POST",{schemaVersion:1,screenID:"home",record:reviews.home});
  assert.equal(homeSaved.status,201);
  assert.equal(homeSaved.json().screenID,"home");
  assert.equal(homeSaved.json().count,1);
  const saved=await invoke("POST",{schemaVersion:1,screenID:"writing-desk",record:reviews["writing-desk"]});
  assert.equal(saved.status,201);
  assert.equal(saved.json().screenID,"writing-desk");
  assert.equal(saved.json().count,2,"saving one screen must preserve reviews already saved for other screens");
  const persisted=JSON.parse(await readFile(ledger,"utf8"));
  assert.equal(persisted.schemaVersion,2);
  assert.match(persisted.updatedAt,/^\d{4}-\d\d-\d\dT/);
  assert.deepEqual(persisted.reviews,reviews);
  assert.ok(persisted.approvals.home?.snapshotSHA256,"implementation-ready feedback must freeze the exact rendered Home fixtures");

  const queued=await invoke("POST",{schemaVersion:1,screenID:"campaigns",record:{choice:"queue",notes:"A details-first load is acceptable",designVersion:"native-1"}});
  assert.equal(queued.status,201);
  const queuedLedger=JSON.parse(await readFile(ledger,"utf8"));
  assert.deepEqual(queuedLedger.reviews.campaigns,{choice:"queue",notes:"A details-first load is acceptable",designVersion:"native-1"});
  assert.deepEqual(queuedLedger.reviews.home,reviews.home,"a queued override must preserve other screen reviews");
  assert.equal(queuedLedger.approvals.campaigns.decision,"queue","queued implementation must freeze the reviewed Campaign fixtures");

  const rejectedReplacement=await invoke("POST",{schemaVersion:1,screenID:"home",record:{choice:"no",notes:9}});
  assert.equal(rejectedReplacement.status,400,"a failed Save must reject the malformed replacement");
  assert.deepEqual(JSON.parse(await readFile(ledger,"utf8")),queuedLedger,"a failed Save must leave the last shared review intact");

  const loaded=await invoke("GET");
  assert.deepEqual(loaded.json(),queuedLedger,"GET must return the shared packet saved by POST");
}finally{
  delete process.env.ASSETLAB_UI_REVIEW_FILE;
  delete process.env.ASSETLAB_UI_APPROVAL_STYLE_DIR;
  delete process.env.ASSETLAB_UI_APPROVAL_ASSET_DIR;
  await rm(temporary,{recursive:true,force:true});
}

console.log("UI review server persists and reloads the shared review ledger.");
