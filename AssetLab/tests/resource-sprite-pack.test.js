import assert from "node:assert/strict";
import {createHash} from "node:crypto";
import {readFile} from "node:fs/promises";
import test from "node:test";
import {fileURLToPath} from "node:url";
import path from "node:path";
import {inflateSync} from "node:zlib";

const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,"../..");
const pack=path.join(root,"AssetLab/integration/resource-sprites-v1");
const sha=value=>createHash("sha256").update(value).digest("hex");
const json=async file=>JSON.parse(await readFile(file,"utf8"));
const canonical=value=>value===null||typeof value!=="object"?JSON.stringify(value):Array.isArray(value)?`[${value.map(canonical).join(",")}]`:`{${Object.keys(value).sort().map(key=>`${JSON.stringify(key)}:${canonical(value[key])}`).join(",")}}`;

function rgbaPNG(bytes){
  assert.equal(bytes.subarray(1,4).toString(),"PNG");
  let offset=8,width,height,depth,type,idat=[];
  while(offset<bytes.length){
    const length=bytes.readUInt32BE(offset),kind=bytes.subarray(offset+4,offset+8).toString(),data=bytes.subarray(offset+8,offset+8+length);offset+=12+length;
    if(kind==="IHDR"){width=data.readUInt32BE(0);height=data.readUInt32BE(4);depth=data[8];type=data[9];}
    if(kind==="IDAT")idat.push(data);
    if(kind==="IEND")break;
  }
  assert.equal(depth,8);assert.equal(type,6);
  const raw=inflateSync(Buffer.concat(idat)),stride=width*4,pixels=Buffer.alloc(stride*height);
  const paeth=(a,b,c)=>{const p=a+b-c,pa=Math.abs(p-a),pb=Math.abs(p-b),pc=Math.abs(p-c);return pa<=pb&&pa<=pc?a:pb<=pc?b:c;};
  for(let y=0;y<height;y++){
    const filter=raw[y*(stride+1)],row=raw.subarray(y*(stride+1)+1,(y+1)*(stride+1)),out=y*stride;
    for(let x=0;x<stride;x++){
      const left=x>=4?pixels[out+x-4]:0,up=y?pixels[out-stride+x]:0,upLeft=y&&x>=4?pixels[out-stride+x-4]:0;
      const predictor=filter===0?0:filter===1?left:filter===2?up:filter===3?Math.floor((left+up)/2):filter===4?paeth(left,up,upLeft):NaN;
      assert.ok(Number.isFinite(predictor),`unsupported PNG filter ${filter}`);pixels[out+x]=(row[x]+predictor)&255;
    }
  }
  return{width,height,data:pixels};
}

test("resource sprite pack covers the exact live catalogue in all eligible profiles",async()=>{
  const catalogue=await json(path.join(root,"Sources/Content/Data/resources.json"));
  const manifest=await json(path.join(pack,"manifest.json"));
  const ids=catalogue.resources.map(entry=>entry.id);
  assert.equal(ids.length,23);
  assert.deepEqual(manifest.resources.map(entry=>entry.id),ids);
  assert.equal(manifest.catalogueSHA256,sha(await readFile(path.join(root,manifest.catalogueAuthority))));
  assert.equal(manifest.integrationReady,true);
  for(const entry of manifest.resources){
    assert.ok(entry.profiles.inventory);
    assert.ok(entry.profiles.field);
    assert.equal(entry.profiles.map===null,entry.id==="mote");
  }
});

test("sprites are exact-sized alpha PNGs with bounded palettes and no empty eligible identity",async()=>{
  const manifest=await json(path.join(pack,"manifest.json"));
  for(const entry of manifest.resources)for(const [profile,record] of Object.entries(entry.profiles)){
    if(record===null)continue;
    const bytes=await readFile(path.join(pack,record.path));
    assert.equal(sha(bytes),record.fileSHA256,`${profile}/${entry.id} hash`);
    const png=rgbaPNG(bytes);
    assert.equal(png.width,record.width);
    assert.equal(png.height,record.height);
    const colors=new Set(),alpha=[];
    for(let index=0;index<png.data.length;index+=4){
      const a=png.data[index+3];alpha.push(a);
      if(a)colors.add(`${png.data[index]},${png.data[index+1]},${png.data[index+2]}`);
    }
    assert.ok(alpha.some(value=>value===0),`${profile}/${entry.id} transparent padding`);
    assert.ok(alpha.some(value=>value===255),`${profile}/${entry.id} opaque identity`);
    assert.ok(alpha.every(value=>value===0||value===255),`${profile}/${entry.id} hard alpha`);
    assert.ok(colors.size<=record.maxOpaqueColors,`${profile}/${entry.id} palette`);
    assert.equal(alpha.filter(Boolean).length,record.occupiedPixels);
  }
});

test("every profile is fail-closed and silhouette-distinct at its actual logical size",async()=>{
  const manifest=await json(path.join(pack,"manifest.json"));
  for(const profile of ["inventory","map","field"]){
    const records=manifest.resources.map(entry=>entry.profiles[profile]).filter(Boolean);
    assert.equal(new Set(records.map(record=>record.silhouetteSHA256)).size,records.length,profile);
  }
  const body={...manifest};delete body.canonicalBodySHA256;
  assert.equal(sha(Buffer.from(canonical(body))),manifest.canonicalBodySHA256);
});
