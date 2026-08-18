import { createServer } from "node:http";
import { execFile } from "node:child_process";
import { mkdir, readFile, stat, writeFile } from "node:fs/promises";
import { basename, dirname, extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import { generateLiveWorld, liveSymbolCatalogue } from "./src/live-worldgen-bridge.js";

const root = new URL(".", import.meta.url).pathname;
const port = Number(process.env.ASSETLAB_PORT ?? 4173);
const uiReviewFile = process.env.ASSETLAB_UI_REVIEW_FILE ?? join(root, "reviews", "ui-gallery-reviews.json");
const execFileAsync = promisify(execFile);
const types = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg"
};

async function body(request, limit = 100_000) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > limit) throw new Error("Request too large");
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

export async function handleAssetLabRequest(request, response) {
  const url = new URL(request.url, `http://${request.headers.host}`),pathname = decodeURIComponent(url.pathname);
  if(request.method==="GET"&&pathname==="/__assetlab-meta"){
    try{
      const {stdout}=await execFileAsync("git",["rev-parse","--short=12","HEAD"],{cwd:join(root,"..")} );
      response.writeHead(200,{"Content-Type":types[".json"],"Cache-Control":"no-store"}).end(JSON.stringify({revision:stdout.trim()}));
    }catch{response.writeHead(200,{"Content-Type":types[".json"],"Cache-Control":"no-store"}).end(JSON.stringify({revision:"unavailable"}));}
    return;
  }
  if(request.method==="GET"&&pathname==="/__ui-reviews"){
    try{const saved=await readFile(uiReviewFile);response.writeHead(200,{"Content-Type":types[".json"],"Cache-Control":"no-store"}).end(saved);}
    catch{response.writeHead(200,{"Content-Type":types[".json"],"Cache-Control":"no-store"}).end(JSON.stringify({schemaVersion:1,reviews:{}}));}
    return;
  }
  if(request.method==="POST"&&pathname==="/__ui-reviews"){
    try{
      const payload=JSON.parse((await body(request,250_000)).toString());
      const {screenID,record}=payload??{};
      if(payload?.schemaVersion!==1||!/^[a-z0-9-]{1,80}$/.test(screenID??"")||!record||typeof record!=="object"||!['yes','no'].includes(record.choice)||typeof record.notes!=="string"||record.notes.length>8_000){response.writeHead(400).end("Invalid UI review record");return;}
      await mkdir(dirname(uiReviewFile),{recursive:true});
      let existing={};
      try{const saved=JSON.parse((await readFile(uiReviewFile)).toString());if(saved?.schemaVersion===1&&saved.reviews&&typeof saved.reviews==="object"&&!Array.isArray(saved.reviews))existing=saved.reviews;}catch{}
      const updatedAt=new Date().toISOString();
      const packet={schemaVersion:1,updatedAt,reviews:{...existing,[screenID]:{choice:record.choice,notes:record.notes}}};
      await writeFile(uiReviewFile,`${JSON.stringify(packet,null,2)}\n`);
      response.writeHead(201,{"Content-Type":types[".json"]}).end(JSON.stringify({path:"reviews/ui-gallery-reviews.json",screenID,updatedAt,count:Object.keys(packet.reviews).length}));
    }catch(error){response.writeHead(500,{"Content-Type":types[".json"]}).end(JSON.stringify({error:String(error.message??error)}));}
    return;
  }
  if(request.method==="GET"&&pathname==="/__worldgen/catalogue"){
    try{response.writeHead(200,{"Content-Type":types[".json"]}).end(JSON.stringify({symbols:await liveSymbolCatalogue()}));}
    catch(error){response.writeHead(500,{"Content-Type":types[".json"]}).end(JSON.stringify({error:String(error.message??error)}));}return;
  }
  if(request.method==="POST"&&pathname==="/__worldgen"){
    try{
      const payload=JSON.parse((await body(request)).toString());
      const start=Number(payload.seed),count=Math.min(12,Math.max(1,Number(payload.count)||1));
      const scales=new Set(["minute","small","ordinary","large","vast"]);
      if(!Number.isSafeInteger(start)||start<0||!Array.isArray(payload.symbols)||!payload.symbols.every(value=>typeof value==="string")||!scales.has(payload.scale)){response.writeHead(400).end("Invalid world request");return;}
      const worlds=await Promise.all(Array.from({length:count},(_,index)=>generateLiveWorld({seed:start+index,symbols:payload.symbols,scale:payload.scale})));
      response.writeHead(200,{"Content-Type":types[".json"]}).end(JSON.stringify({worlds}));
    }catch(error){response.writeHead(500,{"Content-Type":types[".json"]}).end(JSON.stringify({error:String(error.message??error)}));}return;
  }
  if(request.method==="POST"&&pathname==="/__artifact"){
    const requested=basename(url.searchParams.get("name")??"");
    if(!/^[a-zA-Z0-9._-]+\.png$/.test(requested)){response.writeHead(400).end("Invalid PNG filename");return;}
    const chunks=[];let size=0;for await(const chunk of request){size+=chunk.length;if(size>5_000_000){response.writeHead(413).end("Artifact too large");return;}chunks.push(chunk);}
    const bytes=Buffer.concat(chunks);if(bytes.length<8||!bytes.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10]))){response.writeHead(415).end("Expected PNG bytes");return;}
    const directory=join(root,"artifacts");await mkdir(directory,{recursive:true});await writeFile(join(directory,requested),bytes);response.writeHead(201,{"Content-Type":"application/json"}).end(JSON.stringify({path:`artifacts/${requested}`,bytes:bytes.length}));return;
  }
  const relative = pathname === "/" ? "index.html" : pathname.slice(1);
  const file = normalize(join(root, relative));
  if (!file.startsWith(root)) {
    response.writeHead(403).end("Forbidden");
    return;
  }
  try {
    if (!(await stat(file)).isFile()) throw new Error("Not a file");
    response.writeHead(200, { "Content-Type": types[extname(file)] ?? "application/octet-stream", "Cache-Control": "no-store" });
    response.end(await readFile(file));
  } catch {
    response.writeHead(404).end("Not found");
  }
}

if(process.argv[1]&&fileURLToPath(import.meta.url)===normalize(process.argv[1])){
  createServer(handleAssetLabRequest).listen(port, "127.0.0.1", function () {
    const address=this.address();
    console.log(`Bookbinder Asset Lab: http://127.0.0.1:${typeof address==="object"&&address?address.port:port}`);
  });
}
