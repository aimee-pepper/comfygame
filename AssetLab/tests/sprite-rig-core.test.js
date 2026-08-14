import assert from "node:assert/strict";
import { blendPoint, interpolateKeyframes, normalizedWeights, sampleClip } from "../src/sprite-rig-core.js";

assert.deepEqual(normalizedWeights({ a: 2, b: 1 }).map(item => [item.id, item.weight]), [["a", 2/3], ["b", 1/3]]);
assert.deepEqual(blendPoint({x:0,y:0},{a:1,b:1},(id) => id === "a" ? {x:2,y:0} : {x:0,y:2}), {x:1,y:1});
assert.equal(interpolateKeyframes([{time:0,rotation:0},{time:1,rotation:90}], .5), 45);
assert.equal(interpolateKeyframes([{time:0,rotation:10,interpolation:"held"},{time:1,rotation:90}], .5), 10);
assert.equal(sampleClip({duration:1,loop:true,tracks:{arm:[{time:0,rotation:0},{time:1,rotation:100}]}},1.25).arm,25);
console.log("sprite rig core tests passed");
