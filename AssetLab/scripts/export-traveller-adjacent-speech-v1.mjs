import {createCanvas, loadImage, GlobalFonts} from "@napi-rs/canvas";
import {createHash} from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";
import {bubblePlacement, bubbleVisualTokens, expectedSpeechRows, proofCensus, travellerSpeechContract} from "../src/traveller-adjacent-speech-v1.js";
import {buildExactSpeechRows} from "../src/traveller-speech-source-receipt-v1.js";
import {binderTemplate, characterCommands} from "../src/character-kit.js";

const assetLab=path.resolve(path.dirname(fileURLToPath(import.meta.url)),"..");
const root=path.resolve(assetLab,"..");
const output=path.join(assetLab,"artifacts/traveller-adjacent-speech-v1");
const evidence=path.join(output,"evidence"),sprites=path.join(output,"sprites");
const integration=path.join(assetLab,"integration/traveller-adjacent-speech-v1");
for(const directory of [output,evidence,sprites,integration])fs.mkdirSync(directory,{recursive:true});
GlobalFonts.registerFromPath(path.join(assetLab,"fonts/Jersey10-Regular.ttf"),"Jersey");
GlobalFonts.registerFromPath(path.join(assetLab,"fonts/Tiny5-Regular.ttf"),"Tiny");

const sha=value=>createHash("sha256").update(value).digest("hex");
const fileHash=file=>sha(fs.readFileSync(file));
const canonical=value=>Array.isArray(value)?`[${value.map(canonical).join(",")}]`:value&&typeof value==="object"?`{${Object.keys(value).sort().map(key=>`${JSON.stringify(key)}:${canonical(value[key])}`).join(",")}}`:JSON.stringify(value);
const shaObject=value=>sha(Buffer.from(canonical(value)));
const write=(file,value)=>fs.writeFileSync(file,typeof value==="string"?value:`${JSON.stringify(value,null,2)}\n`);

function generatedMeetings(){
  const source=fs.readFileSync(path.join(root,"Sources/Content/DraftMeetingCorpus.generated.swift"),"utf8");
  const encoded=source.match(/private static let encodedJSON = "([^"]+)"/)?.[1];
  const sourceFingerprint=source.match(/static let sourceFingerprint = "([^"]+)"/)?.[1];
  const sourceFiles=JSON.parse(`[${source.match(/static let sourceFiles = \[([^\]]+)\]/)?.[1]??""}]`);
  if(!encoded||!sourceFingerprint||sourceFiles.length!==4)throw new Error("generated-meeting-corpus-unreadable");
  return {meetings:JSON.parse(Buffer.from(encoded,"base64").toString("utf8")),sourceFingerprint,sourceFiles,sourceSHA256:sha(Buffer.from(source))};
}

function buildSourceReceipt(){
  const catalogueFile=path.join(root,"Sources/Content/Data/travellers.json"),catalogueBytes=fs.readFileSync(catalogueFile),catalogue=JSON.parse(catalogueBytes).travellers;
  const generated=generatedMeetings(),byID=new Map(catalogue.map(row=>[row.id,structuredClone(row)]));
  for(const source of generated.meetings){
    const traveller=byID.get(source.travellerID);if(!traveller)throw new Error(`generated-meeting-missing-traveller:${source.travellerID}`);
    traveller.meeting={opening:source.opening,questions:source.exchanges,offer:source.offer,accepted:source.accepted,declined:source.declined};
  }
  const effective=[...byID.values()].sort((a,b)=>a.id.localeCompare(b.id)).map(row=>({travellerID:row.id,displayName:row.name,opening:row.meeting?.opening??"",questions:row.meeting?.questions??[],offer:row.meeting?.offer??"",accepted:row.meeting?.accepted??"",declined:row.meeting?.declined??""}));
  const effectiveMeetingCorpusFingerprint=shaObject(effective);
  const rows=buildExactSpeechRows({effectiveMeetings:effective,expectedRows:expectedSpeechRows,corpusFingerprint:effectiveMeetingCorpusFingerprint,hashMeeting:shaObject});
  const body={schemaVersion:"traveller-adjacent-speech-source-receipt-v1",status:"candidate-unapproved",integrationReady:false,selectionRule:"opening-final-complete-direct-speech;otherwise-first-question-reply-with-complete-direct-speech/first-span",pairedQuotes:["straight-double","curly-double"],forbiddenSources:["ask","offer","accepted","declined","calling","blurb","signature","unquoted-narration"],effectiveMeetingCorpusFingerprint,sourceCatalogue:{file:"Sources/Content/Data/travellers.json",sha256:sha(catalogueBytes)},generatedOverlay:{file:"Sources/Content/DraftMeetingCorpus.generated.swift",sha256:generated.sourceSHA256,authoredSourceFingerprint:generated.sourceFingerprint,sourceFiles:generated.sourceFiles,meetingCount:generated.meetings.length},rows};
  return{...body,canonicalBodySHA256:shaObject(body)};
}

const sourceReceipt=buildSourceReceipt();
write(path.join(integration,"source-receipt.json"),sourceReceipt);

const placeholderManifestFile=path.join(assetLab,"integration/named-character-placeholders-v1/manifest.json");
const placeholderManifest=JSON.parse(fs.readFileSync(placeholderManifestFile));
function commandsForTraveller(id){
  const entry=placeholderManifest.assets.find(asset=>asset.key.travellerID===id&&asset.key.profile==="mapTopDown"&&asset.key.facing==="south");
  if(!entry)throw new Error(`missing-placeholder-map-sprite:${id}`);return entry.commands;
}
function rgbaCanvas(commands,width=16,height=16){const canvas=createCanvas(width,height),x=canvas.getContext("2d");x.clearRect(0,0,width,height);x.imageSmoothingEnabled=false;for(const command of commands){x.fillStyle=command.color;x.fillRect(command.x,command.y,command.w,command.h)}return canvas}
const spriteCanvases=new Map();
for(const id of ["mara","tovin","oda","noll"]){const canvas=rgbaCanvas(commandsForTraveller(id));spriteCanvases.set(id,canvas);fs.writeFileSync(path.join(sprites,`${id}-map.png`),canvas.toBuffer("image/png"))}
const binder=rgbaCanvas(characterCommands("binder",{profile:"mapTopDown",facing:"north",descriptor:binderTemplate}));spriteCanvases.set("binder",binder);fs.writeFileSync(path.join(sprites,"binder-map.png"),binder.toBuffer("image/png"));

const terrainFile=path.join(assetLab,"artifacts/dynamic-terrain-style-v0.2/evidence/phone-opposed-cool-368x800.png");
const terrain=await loadImage(terrainFile),speechByID=new Map(sourceReceipt.rows.map(row=>[row.travellerID,row]));
const names=new Map(sourceReceipt.rows.map(row=>[row.travellerID,row.displayName]));

function wrap(x,text,maxWidth){const words=text.split(/\s+/),lines=[];let line="";for(const word of words){const next=line?`${line} ${word}`:word;if(x.measureText(next).width<=maxWidth||!line)line=next;else{lines.push(line);line=word}}if(line)lines.push(line);return lines}
function fill(x,color,rx,ry,rw,rh){x.fillStyle=color;x.fillRect(Math.round(rx),Math.round(ry),Math.round(rw),Math.round(rh))}
function drawChrome(x){fill(x,"#111d1e",0,0,368,64);fill(x,"#465952",0,62,368,2);x.fillStyle="#f4ecd7";x.font="34px Jersey";x.fillText("Explore",14,43);x.fillStyle="#dbe3dd";x.font="15px Tiny";x.fillText("Stability 73%",262,38)}
function drawMap(x){fill(x,"#102021",0,64,368,428);x.imageSmoothingEnabled=false;x.drawImage(terrain,8,72,352,352,8,72,352,352);fill(x,"#07101166",0,474,368,18)}
function drawBottom(x){fill(x,"#172726",0,492,368,78);fill(x,"#5c7069",0,492,368,1);fill(x,"#465952",0,569,368,1);x.fillStyle="#9fc2b9";x.font="15px Tiny";x.fillText("AT THIS PLACE",13,513);x.fillStyle="#f4ecd7";x.font="24px Jersey";x.fillText("Rain-soft ground",13,542);x.fillStyle="#b9c7c1";x.font="13px sans-serif";x.fillText("The path opens between living cover.",13,560);fill(x,"#13201f",0,570,368,106);for(const [index,label] of ["Look","Use Tile","Field Kit"].entries()){const bx=12+index*120;fill(x,index===1?"#36584c":"#13201f",bx,600,104,46);x.strokeStyle="#566a64";x.strokeRect(bx+.5,600.5,103,45);x.fillStyle="#f4ecd7";x.font="16px Tiny";x.textAlign="center";x.fillText(label,bx+52,628)}x.textAlign="left";fill(x,"#0b1314",0,676,368,124);x.fillStyle="#c4d0cb";x.font="15px Tiny";x.fillText("Health 12 / 12",14,710);x.fillText("turn 13",304,710)}
function drawPerson(x,{id,x:px,y:py},party=false){const canvas=spriteCanvases.get(party?"binder":id);x.imageSmoothingEnabled=false;x.drawImage(canvas,px-16,64+py-16,32,32)}
function bubbleMetrics(x,text){x.font="17px sans-serif";const lines=wrap(x,text,260);return{width:284,height:24+lines.length*21,lines}}
function drawBubble(x,id,anchor,progress=1){
  const row=speechByID.get(id),metrics=bubbleMetrics(x,row.text),absoluteAnchor={x:anchor.x,y:64+anchor.y};
  const placement=bubblePlacement({anchorX:absoluteAnchor.x,anchorY:absoluteAnchor.y,bubbleWidth:metrics.width,bubbleHeight:metrics.height,stageWidth:368,mapTop:68,mapBottom:488,blockedRects:[{x:absoluteAnchor.x-18,y:absoluteAnchor.y-18,width:36,height:36}]});
  const eased=1-(1-progress)**3,by=placement.y+bubbleVisualTokens.enterOffsetY*(1-eased);x.globalAlpha=eased;
  fill(x,"#07100f",placement.x-2,by+4,metrics.width+4,metrics.height-8);fill(x,"#07100f",placement.x+4,by-2,metrics.width-8,metrics.height+4);
  fill(x,"#b9cfb8",placement.x-1,by+4,metrics.width+2,metrics.height-8);fill(x,"#b9cfb8",placement.x+4,by-1,metrics.width-8,metrics.height+2);
  fill(x,"#11201f",placement.x,by+4,metrics.width,metrics.height-8);fill(x,"#11201f",placement.x+4,by,metrics.width-8,metrics.height);
  const tx=placement.x+placement.tailX;if(placement.tailDirection==="down"){fill(x,"#07100f",tx-7,by+metrics.height,14,8);fill(x,"#b9cfb8",tx-5,by+metrics.height,10,7);fill(x,"#11201f",tx-4,by+metrics.height,8,6)}else{fill(x,"#07100f",tx-7,by-8,14,8);fill(x,"#b9cfb8",tx-5,by-7,10,7);fill(x,"#11201f",tx-4,by-6,8,6)}
  x.fillStyle="#fff7e3";x.font="17px sans-serif";let ty=by+19;for(const line of metrics.lines){x.fillText(line,placement.x+12,ty);ty+=21}x.globalAlpha=1;
}
function grayscaleCanvas(source){const c=createCanvas(source.width,source.height),x=c.getContext("2d");x.drawImage(source,0,0);const image=x.getImageData(0,0,c.width,c.height);for(let i=0;i<image.data.length;i+=4){const y=Math.round(image.data[i]*.2126+image.data[i+1]*.7152+image.data[i+2]*.0722);image.data[i]=image.data[i+1]=image.data[i+2]=y}x.putImageData(image,0,0);return c}

const states=[
  {file:"t01-mara-enter-368x800.png",current:"mara",progress:.34,player:{x:184,y:304},people:[{id:"mara",x:184,y:240}]},
  {file:"t01-mara-hold-368x800.png",current:"mara",progress:1,player:{x:184,y:304},people:[{id:"mara",x:184,y:240}]},
  {file:"t07-fifo-north-368x800.png",current:"mara",progress:1,player:{x:184,y:288},people:[{id:"mara",x:184,y:232},{id:"tovin",x:240,y:288},{id:"oda",x:184,y:344},{id:"noll",x:128,y:288}]},
  {file:"t07-fifo-east-368x800.png",current:"tovin",progress:1,player:{x:184,y:288},people:[{id:"mara",x:184,y:232},{id:"tovin",x:240,y:288},{id:"oda",x:184,y:344},{id:"noll",x:128,y:288}]},
  {file:"t05-nondisclosed-368x800.png",current:null,progress:1,player:{x:184,y:288},people:[]},
  {file:"t06-same-tile-meeting-368x800.png",current:null,progress:1,player:{x:184,y:244},people:[{id:"mara",x:184,y:244}],meeting:true},
  {file:"t13-oda-wrap-368x800.png",current:"oda",progress:1,player:{x:80,y:112},people:[{id:"oda",x:80,y:76}]},
  {file:"t13-tovin-wrap-368x800.png",current:"tovin",progress:1,player:{x:316,y:278},people:[{id:"tovin",x:316,y:230}]},
  {file:"t08-cleared-368x800.png",current:null,progress:1,player:{x:184,y:304},people:[{id:"mara",x:184,y:240}]},
];
const rendered=[];
for(const state of states){const canvas=createCanvas(368,800),x=canvas.getContext("2d");drawChrome(x);drawMap(x);drawPerson(x,{id:"binder",...state.player},true);for(const person of state.people)drawPerson(x,person);if(state.current)drawBubble(x,state.current,state.people.find(person=>person.id===state.current),state.progress);drawBottom(x);const file=path.join(evidence,state.file);fs.writeFileSync(file,canvas.toBuffer("image/png"));rendered.push({state,...state,canvas,file,sha256:fileHash(file)})}
const gray=grayscaleCanvas(rendered.find(row=>row.file.endsWith("t01-mara-hold-368x800.png")).canvas),grayFile=path.join(evidence,"t01-mara-hold-grayscale-368x800.png");fs.writeFileSync(grayFile,gray.toBuffer("image/png"));

const sheet=createCanvas(1280,3300),sx=sheet.getContext("2d");fill(sx,"#091110",0,0,sheet.width,sheet.height);sx.fillStyle="#f4ecd7";sx.font="48px Jersey";sx.fillText("TRAVELLER ADJACENT SPEECH · CANDIDATE / NOT APPROVED",28,58);sx.fillStyle="#e4c46e";sx.font="18px Tiny";sx.fillText("exact authored quote only · existing map sprites · no identity label · hit-test transparent",28,88);const columns=[28,438,848];for(const [index,row] of [...rendered,{file:grayFile,canvas:gray}].entries()){const col=index%3,rowIndex=Math.floor(index/3),ox=columns[col],oy=122+rowIndex*784;sx.fillStyle="#e4c46e";sx.font="17px Tiny";sx.fillText(path.basename(row.file),ox,oy);sx.drawImage(row.canvas,ox,oy+18,368,736)}
const contactFile=path.join(output,"review-contact-sheet.png");fs.writeFileSync(contactFile,sheet.toBuffer("image/png"));

const evidenceRows=[...rendered.map(row=>({file:`evidence/${path.basename(row.file)}`,width:368,height:800,sha256:row.sha256})),{file:"evidence/t01-mara-hold-grayscale-368x800.png",width:368,height:800,sha256:fileHash(grayFile)}];
const interactionAuthorityFiles=[
  "Sources/Screens/TravellerMeetingView.swift",
  "Sources/Rules/WorldRules.swift",
  "Sources/Rules/GameActions+World.swift",
  "Sources/Persistence/GameStore.swift",
].map(file=>({file,sha256:fileHash(path.join(root,file)),ownership:file.endsWith("TravellerMeetingView.swift")?"full-opening-question-offer-accepted-declined-meeting-ui":file.endsWith("WorldRules.swift")?"recruitment-rules-mutation":file.endsWith("GameActions+World.swift")?"GameStore-recruit-action-and-flush":"persisted-game-state-owner"}));
const manifestBody={schemaVersion:"traveller-adjacent-speech-proof-v1",status:"candidate-unapproved",integrationReady:false,sourceReceipt:{file:"AssetLab/integration/traveller-adjacent-speech-v1/source-receipt.json",sha256:fileHash(path.join(integration,"source-receipt.json")),canonicalBodySHA256:sourceReceipt.canonicalBodySHA256,rowCount:sourceReceipt.rows.length,effectiveMeetingCorpusFingerprint:sourceReceipt.effectiveMeetingCorpusFingerprint},contract:travellerSpeechContract,visualTokens:bubbleVisualTokens,visualOwnership:{bubble:"pixel-stepped dark local scrim with exact traveller tail",speakerIdentity:"no name header and no map labels; existing traveller sprite plus tail owns association",copy:"byte-pinned direct-speech span only",placement:"above first; below/clamped at map edge; never covers fixed controls",motion:"brief 6px fade/settle; fixed hold; fade removal",interaction:"pointer/hit-test transparent; never looks or behaves like a control"},acceptedExistingInputs:{terrain:{file:path.relative(root,terrainFile),sha256:fileHash(terrainFile)},namedCharacterPlaceholderManifest:{file:path.relative(root,placeholderManifestFile),sha256:fileHash(placeholderManifestFile),finalArt:false},fonts:[{file:"AssetLab/fonts/Jersey10-Regular.ttf",sha256:fileHash(path.join(assetLab,"fonts/Jersey10-Regular.ttf"))},{file:"AssetLab/fonts/Tiny5-Regular.ttf",sha256:fileHash(path.join(assetLab,"fonts/Tiny5-Regular.ttf"))}]},coverage:proofCensus,evidence:evidenceRows,contactSheet:{file:"review-contact-sheet.png",width:1280,height:2520,sha256:fileHash(contactFile)},spriteReferences:["binder","mara","tovin","oda","noll"].map(id=>({id,file:`sprites/${id}-map.png`,sha256:fileHash(path.join(sprites,`${id}-map.png`)),role:id==="binder"?"existing-party-proof-reference":"existing-functional-named-character-placeholder",finalArt:false})),exclusions:["native-implementation","gameplay-mutation","meeting-content-change","character-art","traveller-name-disclosure","runtime-prose-parsing","runtime-generated-imagery","mining-feedback","world-splash-parallax"]};
manifestBody.preservedInteractionAuthority=interactionAuthorityFiles;
manifestBody.contactSheet.height=3300;
const manifest={...manifestBody,canonicalBodySHA256:shaObject(manifestBody)};write(path.join(output,"manifest.json"),manifest);
write(path.join(integration,"README.md"),`# Traveller Adjacent Speech Bubble v1\n\nCandidate-only Asset proof. integrationReady is false. Native implementation is excluded.\n\n- Source receipt: 29 byte-pinned effective TravellerMeeting rows.\n- Trigger: accepted final presented cardinal adjacency only.\n- Queue: North, East, South, West.\n- Phone: exact authored quote only; no speaker name or map labels; noninteractive.\n- Current character pixels are the accepted functional placeholder pack and are not promoted as final named-character art.\n- Body: ${manifest.canonicalBodySHA256}\n`);
console.log(JSON.stringify({body:manifest.canonicalBodySHA256,manifestFileSHA256:fileHash(path.join(output,"manifest.json")),sourceReceiptBody:sourceReceipt.canonicalBodySHA256,sourceReceiptFileSHA256:fileHash(path.join(integration,"source-receipt.json")),contactSheetSHA256:fileHash(contactFile),evidence:evidenceRows.length},null,2));
