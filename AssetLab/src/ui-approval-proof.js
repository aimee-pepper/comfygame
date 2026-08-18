import {createHash} from "node:crypto";
import {mkdir,readFile,writeFile} from "node:fs/promises";
import {extname,join,resolve} from "node:path";

const allowedDecisions=new Set(["yes","queue","baseline"]);
const sha256=value=>createHash("sha256").update(value).digest("hex");

function canonicalPayload({screenID,decision,notes,designVersion,sourceRevision,fixtureStates,htmlByState,styleSHA256}){
  return {screenID,decision,notes,designVersion,sourceRevision,fixtureStates,htmlByState:Object.fromEntries(fixtureStates.map(state=>[state,htmlByState[state]])),styleSHA256};
}

export function createUIApprovalProof({screenID,decision,notes="",designVersion="",sourceRevision,fixtureStates,htmlByState,css,approvedAt=new Date().toISOString()}){
  if(!/^[a-z0-9-]{1,80}$/.test(screenID??"")||!allowedDecisions.has(decision)||typeof notes!=="string"||typeof designVersion!=="string"||typeof sourceRevision!=="string"||!sourceRevision||!Array.isArray(fixtureStates)||fixtureStates.length===0||new Set(fixtureStates).size!==fixtureStates.length||!fixtureStates.every(state=>typeof state==="string"&&state.length>0&&typeof htmlByState?.[state]==="string")||typeof css!=="string"||!css)throw new Error("Invalid UI approval proof input");
  const styleSHA256=sha256(css),payload=canonicalPayload({screenID,decision,notes,designVersion,sourceRevision,fixtureStates,htmlByState,styleSHA256});
  return {...payload,approvedAt,stylePath:`reviews/approved-styles/${styleSHA256}.css`,snapshotSHA256:sha256(JSON.stringify(payload))};
}

export function validateUIApprovalProof(value,css){
  if(!value||typeof value!=="object"||Array.isArray(value)||typeof css!=="string")return false;
  try{
    const recreated=createUIApprovalProof({...value,css,approvedAt:value.approvedAt});
    return recreated.snapshotSHA256===value.snapshotSHA256&&recreated.styleSHA256===value.styleSHA256&&recreated.stylePath===value.stylePath;
  }catch{return false}
}

export function sameUIApproval(left,right){
  return Boolean(left&&right&&left.snapshotSHA256===right.snapshotSHA256&&left.decision===right.decision&&left.notes===right.notes);
}

export async function freezeUIApprovalStyles({css,sourceRoot,assetDirectory,publicPrefix="/reviews/approved-assets"}){
  if(typeof css!=="string"||!css||typeof sourceRoot!=="string"||typeof assetDirectory!=="string")throw new Error("Invalid UI approval style input");
  await mkdir(assetDirectory,{recursive:true});
  const replacements=new Map(),matches=[...css.matchAll(/url\((['"]?)([^)'"\s]+)\1\)/g)];
  for(const match of matches){
    const reference=match[2];
    if(/^(?:data:|https?:|\/)/.test(reference))continue;
    const source=resolve(sourceRoot,reference);
    if(!source.startsWith(resolve(sourceRoot)))throw new Error(`UI approval asset escapes root: ${reference}`);
    const bytes=await readFile(source),digest=sha256(bytes),extension=extname(source).toLowerCase(),filename=`${digest}${extension}`;
    await writeFile(join(assetDirectory,filename),bytes,{flag:"wx"}).catch(async error=>{if(error?.code!=="EEXIST")throw error;const existing=await readFile(join(assetDirectory,filename));if(sha256(existing)!==digest)throw new Error(`Frozen UI asset hash mismatch: ${filename}`)});
    replacements.set(match[0],`url("${publicPrefix}/${filename}")`);
  }
  return [...replacements].reduce((value,[before,after])=>value.replaceAll(before,after),css);
}
