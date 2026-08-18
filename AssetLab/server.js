import { createServer } from "node:http";
import { execFile } from "node:child_process";
import { mkdir, readFile, rename, stat, writeFile } from "node:fs/promises";
import { basename, dirname, extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import { generateLiveWorld, liveSymbolCatalogue } from "./src/live-worldgen-bridge.js";
import {fixtureStatesByScreen,renderScreen,screens} from "./src/ui-gallery-app.js";
import {createUIApprovalProof,freezeUIApprovalStyles,sameUIApproval} from "./src/ui-approval-proof.js";

const root = new URL(".", import.meta.url).pathname;
const port = Number(process.env.ASSETLAB_PORT ?? 4173);
const uiReviewFile = process.env.ASSETLAB_UI_REVIEW_FILE ?? join(root, "reviews", "ui-gallery-reviews.json");
const uiApprovalStyleDirectory=process.env.ASSETLAB_UI_APPROVAL_STYLE_DIR??join(root,"reviews","approved-styles");
const uiApprovalAssetDirectory=process.env.ASSETLAB_UI_APPROVAL_ASSET_DIR??join(root,"reviews","approved-assets");
const execFileAsync = promisify(execFile);
const types = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg"
  ,".ttf":"font/ttf"
  ,".woff2":"font/woff2"
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
    catch{response.writeHead(200,{"Content-Type":types[".json"],"Cache-Control":"no-store"}).end(JSON.stringify({schemaVersion:2,reviews:{},approvals:{}}));}
    return;
  }
  if(request.method==="GET"&&pathname==="/__ui-approved-preview"){
    try{
      const screenID=url.searchParams.get("screenID")??"",requestedState=url.searchParams.get("state")??"";
      const packet=JSON.parse((await readFile(uiReviewFile)).toString()),approval=packet?.approvals?.[screenID];
      if(!approval||!approval.fixtureStates?.includes(requestedState)||typeof approval.htmlByState?.[requestedState]!=="string"){response.writeHead(404).end("Approved UI preview not found");return;}
      const css=await readFile(join(uiApprovalStyleDirectory,`${approval.styleSHA256}.css`),"utf8");
      const document=`<!doctype html><html data-pixel-font="jersey-tiny"><head><meta charset="utf-8"><meta name="viewport" content="width=368,initial-scale=1"><base href="/"><style>${css.replaceAll("</style","<\\/style")}</style></head><body><div class="phone">${approval.htmlByState[requestedState]}</div></body></html>`;
      response.writeHead(200,{"Content-Type":types[".html"],"Cache-Control":"immutable, max-age=31536000","Content-Security-Policy":"default-src 'none'; style-src 'unsafe-inline'; img-src 'self' data:; font-src 'self'; script-src 'none';","X-Content-Type-Options":"nosniff"}).end(document);
    }catch{response.writeHead(404).end("Approved UI preview not found");}
    return;
  }
  if(request.method==="POST"&&pathname==="/__ui-reviews"){
    try{
      const payload=JSON.parse((await body(request,250_000)).toString());
      const {screenID,record}=payload??{};
      const screen=screens.find(item=>item.id===screenID);
      if(payload?.schemaVersion!==1||!screen||!record||typeof record!=="object"||!['yes','queue','no'].includes(record.choice)||typeof record.notes!=="string"||record.notes.length>8_000||(['queue','no'].includes(record.choice)&&!record.notes.trim())||(record.designVersion!==undefined&&(typeof record.designVersion!=="string"||record.designVersion.length>80))){response.writeHead(400).end("Invalid UI review record");return;}
      await mkdir(dirname(uiReviewFile),{recursive:true});
      let existing={},approvals={};
      try{const saved=JSON.parse((await readFile(uiReviewFile)).toString());if([1,2].includes(saved?.schemaVersion)&&saved.reviews&&typeof saved.reviews==="object"&&!Array.isArray(saved.reviews))existing=saved.reviews;if(saved?.schemaVersion===2&&saved.approvals&&typeof saved.approvals==="object"&&!Array.isArray(saved.approvals))approvals=saved.approvals;}catch{}
      const locked=approvals[screenID];
      if(locked&&locked.decision!=="baseline"){
        const equivalent=locked.decision===record.choice&&locked.notes===record.notes&&(record.designVersion??"")===(locked.designVersion??"");
        if(!equivalent){response.writeHead(409,{"Content-Type":types[".json"]}).end(JSON.stringify({code:"approved-screen-immutable",screenID}));return;}
        response.writeHead(200,{"Content-Type":types[".json"]}).end(JSON.stringify({path:"reviews/ui-gallery-reviews.json",screenID,updatedAt:null,count:Object.keys(existing).length,approval:locked,idempotent:true}));return;
      }
      if(locked?.decision==="baseline"&&['yes','queue'].includes(record.choice)){response.writeHead(409,{"Content-Type":types[".json"]}).end(JSON.stringify({code:"approved-baseline-requires-new-candidate",screenID}));return;}
      const updatedAt=new Date().toISOString();
      let approval;
      if(['yes','queue'].includes(record.choice)){
        const fixtureStates=fixtureStatesByScreen[screenID]??["Default","Selected","Confirm"],htmlByState=Object.fromEntries(fixtureStates.map(fixtureState=>[fixtureState,renderScreen(screen.title,fixtureState)])),rawCSS=`${await readFile(join(root,"styles.css"),"utf8")}\n${await readFile(join(root,"ui-gallery.css"),"utf8")}`,css=await freezeUIApprovalStyles({css:rawCSS,sourceRoot:root,assetDirectory:uiApprovalAssetDirectory}),{stdout}=await execFileAsync("git",["rev-parse","--short=12","HEAD"],{cwd:join(root,"..")});
        approval=createUIApprovalProof({screenID,decision:record.choice,notes:record.notes,designVersion:record.designVersion??"",sourceRevision:stdout.trim(),fixtureStates,htmlByState,css,approvedAt:updatedAt});
        await mkdir(uiApprovalStyleDirectory,{recursive:true});
        const styleFile=join(uiApprovalStyleDirectory,`${approval.styleSHA256}.css`);
        await writeFile(styleFile,css,{flag:"wx"}).catch(async error=>{if(error?.code!=="EEXIST")throw error;const existingStyle=await readFile(styleFile,"utf8");if(existingStyle!==css)throw new Error("Approved UI style hash collision")});
        if(locked&&!sameUIApproval(locked,approval)){response.writeHead(409,{"Content-Type":types[".json"]}).end(JSON.stringify({code:"approved-screen-immutable",screenID}));return;}
        approvals={...approvals,[screenID]:approval};
      }
      const packet={schemaVersion:2,updatedAt,reviews:{...existing,[screenID]:{choice:record.choice,notes:record.notes,...(record.designVersion?{designVersion:record.designVersion}:{})}},approvals};
      const temporary=`${uiReviewFile}.${process.pid}.tmp`;await writeFile(temporary,`${JSON.stringify(packet,null,2)}\n`);await rename(temporary,uiReviewFile);
      response.writeHead(201,{"Content-Type":types[".json"]}).end(JSON.stringify({path:"reviews/ui-gallery-reviews.json",screenID,updatedAt,count:Object.keys(packet.reviews).length,...(approval?{approval}:{})}));
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
