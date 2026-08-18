import assert from "node:assert/strict";
import {mkdtemp,readFile,rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";

const temporary=await mkdtemp(join(tmpdir(),"bookbinder-ui-reviews-"));
const ledger=join(temporary,"nested","ui-gallery-reviews.json");
process.env.ASSETLAB_UI_REVIEW_FILE=ledger;
const {handleAssetLabRequest}=await import("../server.js");

function request(method,payload){
  const bytes=payload===undefined?[]:[Buffer.from(JSON.stringify(payload))];
  return {method,url:"/__ui-reviews",headers:{host:"127.0.0.1"},async *[Symbol.asyncIterator](){yield* bytes}};
}
function response(){
  return {status:0,headers:{},bytes:Buffer.alloc(0),writeHead(status,headers={}){this.status=status;this.headers=headers;return this},end(value=""){this.bytes=Buffer.isBuffer(value)?value:Buffer.from(value);return this},json(){return JSON.parse(this.bytes.toString())}};
}
async function invoke(method,payload){const result=response();await handleAssetLabRequest(request(method,payload),result);return result}

try{
  const empty=await invoke("GET");
  assert.equal(empty.status,200);
  assert.equal(empty.headers["Cache-Control"],"no-store");
  assert.deepEqual(empty.json(),{schemaVersion:1,reviews:{}},"a missing shared ledger must read as an empty review packet");

  const invalid=await invoke("POST",{schemaVersion:1,reviews:{home:{choice:"maybe",notes:""}}});
  assert.equal(invalid.status,400,"invalid review choices must be rejected without persistence");

  const reviews={home:{choice:"yes",notes:""},"writing-desk":{choice:"no",notes:"Keep the page larger"}};
  const saved=await invoke("POST",{schemaVersion:1,reviews});
  assert.equal(saved.status,201);
  assert.deepEqual(saved.json(),{path:"reviews/ui-gallery-reviews.json",count:2});
  const persisted=JSON.parse(await readFile(ledger,"utf8"));
  assert.equal(persisted.schemaVersion,1);
  assert.match(persisted.updatedAt,/^\d{4}-\d\d-\d\dT/);
  assert.deepEqual(persisted.reviews,reviews);

  const loaded=await invoke("GET");
  assert.deepEqual(loaded.json(),persisted,"GET must return the shared packet saved by POST");
}finally{
  delete process.env.ASSETLAB_UI_REVIEW_FILE;
  await rm(temporary,{recursive:true,force:true});
}

console.log("UI review server persists and reloads the shared review ledger.");
