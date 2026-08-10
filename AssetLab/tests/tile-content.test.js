import assert from "node:assert/strict";
import { hash,commandBounds } from "../src/generator.js";
import { tileContentTypes,tileContentCommands,minimapContentCommands } from "../src/tile-content.js";
assert.equal(tileContentTypes.length,10);
const visible=tileContentTypes.map(type=>tileContentCommands({type,revealed:true,discovered:true}));
assert.equal(new Set(visible.map(hash)).size,10,"all ten tile-content families need distinct ordinary-map grammar");
const geometry=commands=>hash(commands.map(({x,y,w,h})=>({x,y,w,h})));assert.notEqual(geometry(tileContentCommands({type:"wildDrop",revealed:true})),geometry(tileContentCommands({type:"traveller",revealed:true})),"traveller and drop must remain distinct without color");
for(const commands of visible){const bounds=commandBounds(commands);assert.ok(bounds.minX>=0&&bounds.minY>=0&&bounds.maxX<=16&&bounds.maxY<=16);}
assert.notEqual(hash(tileContentCommands({type:"portal",portalDirection:"entry",revealed:true})),hash(tileContentCommands({type:"portal",portalDirection:"exit",revealed:true})),"entry and exit portals must differ");
for(const type of tileContentTypes)assert.deepEqual(tileContentCommands({type,revealed:false}),[],"fog must reveal no content");
for(const type of tileContentTypes)assert.deepEqual(minimapContentCommands({type,revealed:true,discovered:false}),[],"undiscovered content must not leak to minimap");
const promised=["portal","site","diaryPage","foundWriting","traveller"],quiet=tileContentTypes.filter(type=>!promised.includes(type));for(const type of promised)assert.ok(minimapContentCommands({type,revealed:true,discovered:true}).length>0);for(const type of quiet)assert.deepEqual(minimapContentCommands({type,revealed:true,discovered:true}),[]);
console.log("Asset Lab tile-content tests passed.");
