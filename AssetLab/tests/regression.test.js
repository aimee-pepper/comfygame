import assert from "node:assert/strict";
import { rasterTokens,rasterHash,diffRasters } from "../src/regression.js";
const first=[{x:1,y:1,w:2,h:2,color:"red"}],second=[...first,{x:2,y:2,w:1,h:1,color:"blue"}];
const a=rasterTokens(first,4,4),b=rasterTokens(second,4,4);
assert.notEqual(rasterHash(first,4,4),rasterHash(second,4,4));
assert.deepEqual(diffRasters(a,a,4),{changedPixels:0,bounds:null});
assert.deepEqual(diffRasters(a,b,4),{changedPixels:1,bounds:{x:2,y:2,width:1,height:1}});
console.log("Asset Lab regression tests passed.");
