import crypto from "node:crypto";
export const wallGrounds=Object.freeze(["stone","soil","sand","ash","rubble","mud"]),wallJoins=Object.freeze(["span","leftCap","rightCap","isolated"]),wallRoles=Object.freeze(["deepShadow","bodyDark","body","bodyLight","highlight"]);
const exact=(o,k,l)=>{if(!o||Array.isArray(o)||typeof o!=="object"||Object.keys(o).sort().join()!==[...k].sort().join())throw Error(`invalid-${l}-fields`);};
export function normalizeSouthWallRequest(r){exact(r,["schemaVersion","ground","southExposureLevels","southNeighborDisclosure","westContinuation","eastContinuation","featureVariant","worldGradeDescriptorHash"],"south-wall-request");if(r.schemaVersion!=="terrain-south-wall-v1"||!wallGrounds.includes(r.ground)||!["known","hidden","outOfMap"].includes(r.southNeighborDisclosure)||typeof r.westContinuation!=="boolean"||typeof r.eastContinuation!=="boolean"||!Number.isSafeInteger(r.southExposureLevels)||r.southExposureLevels<0||r.southExposureLevels>3||!Number.isSafeInteger(r.featureVariant)||r.featureVariant<0||r.featureVariant>3||typeof r.worldGradeDescriptorHash!=="string"||!r.worldGradeDescriptorHash)throw Error("invalid-south-wall-request");if(r.southNeighborDisclosure!=="known"&&r.southExposureLevels!==0)throw Error("undisclosed-south-exposure");return Object.freeze(structuredClone(r));}
export const joinFor=r=>r.westContinuation?(r.eastContinuation?"span":"rightCap"):(r.eastContinuation?"leftCap":"isolated");
const templates={
 stone:[[1,2,2,1,2,2,1,2,1,2,2,1,2,1,2,1],[0,1,1,0,1,1,0,1,0,1,1,0,1,0,1,0],[1,2,1,2,1,1,2,1,2,1,2,1,1,2,1,2]],
 soil:[[1,1,2,2,1,1,2,1,1,2,2,1,1,2,1,1],[0,1,1,2,1,0,1,1,2,1,1,0,1,2,1,0],[1,2,2,1,1,2,1,2,2,1,2,1,1,2,2,1]],
 sand:[[2,2,2,1,2,1,2,2,1,2,1,2,2,1,2,1],[1,2,1,1,1,0,1,2,1,1,0,1,2,1,1,0],[1,1,2,1,2,1,1,2,1,2,1,1,2,1,2,1]],
 ash:[[1,2,1,1,2,1,2,1,1,2,1,2,1,1,2,1],[0,1,0,1,1,0,1,0,1,1,0,1,0,1,1,0],[1,1,2,1,1,2,1,1,2,1,1,2,1,1,2,1]],
 rubble:[[2,2,1,2,1,1,1,2,2,1,2,2,1,2,1,1],[0,2,0,1,1,0,1,2,1,0,2,1,0,1,1,0],[1,2,1,2,1,2,0,2,1,2,1,2,0,2,1,2]],
 mud:[[1,2,2,1,1,2,1,1,2,2,1,1,2,1,1,2],[0,1,1,0,0,1,0,0,1,1,0,0,1,0,0,1],[1,1,2,1,1,1,2,1,1,2,1,1,1,2,1,1]]
};
export function wallRoleMap(raw){const r=normalizeSouthWallRequest(raw);if(r.southExposureLevels===0)return new Int8Array(48).fill(-1);const rows=templates[r.ground].map((row,y)=>row.map((v,x)=>(v+(r.featureVariant===3&&((x+y)%7===0)?1:0))%5));const join=joinFor(r);for(let y=0;y<3;y++){if(join==="leftCap"||join==="isolated")rows[y][0]=y===0?4:0;if(join==="rightCap"||join==="isolated")rows[y][15]=y===0?4:0;}const out=new Int8Array(48).fill(-1),start=3-r.southExposureLevels;for(let y=start;y<3;y++)for(let x=0;x<16;x++)out[y*16+x]=rows[y][x];return out;}
export const canonicalJSON=v=>JSON.stringify(sort(v));function sort(v){if(Array.isArray(v))return v.map(sort);if(v&&typeof v==="object")return Object.fromEntries(Object.keys(v).sort().map(k=>[k,sort(v[k])]));return v;}export const sha256=b=>crypto.createHash("sha256").update(b).digest("hex");
