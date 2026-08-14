import {mkdir,writeFile} from "node:fs/promises";
import {createHash} from "node:crypto";
import {deflateSync} from "node:zlib";
import {catalogueItemIconCommands,tier2CatalogueVisualVersion,tier2ComparisonPairs,tier2CatalogueItemIDs,tier2CatalogueItemIconCommands} from "../src/item-kit.js";
import {unknownItemIconCommands} from "../src/item-kit.js";
import {economyIdentityCommands,economyIdentityFixtures} from "../src/economy-identity-kit.js";
import {resourceInventoryIconCommands} from "../src/resource-kit.js";

const width=800,height=410,rgba=Buffer.alloc(width*height*4),background=[23,22,20,255],panel=[36,34,31,255],line=[98,91,81,255];
for(let at=0;at<rgba.length;at+=4)rgba.set(background,at);
const pixel=(x,y,color)=>{if(x<0||y<0||x>=width||y>=height)return;rgba.set(color,(y*width+x)*4);};
const fill=(x,y,w,h,color)=>{for(let py=y;py<y+h;py++)for(let px=x;px<x+w;px++)pixel(px,py,color);};
const channels=hex=>[1,3,5].map(i=>parseInt(hex.slice(i,i+2),16)).concat(255);
const gray=color=>{const value=Math.round(color[0]*.2126+color[1]*.7152+color[2]*.0722);return[value,value,value,color[3]];};
const drawCell=(commands,index,originX,asGray)=>{const x=originX+(index%6)*60,y=18+Math.floor(index/6)*60;fill(x,y,54,54,panel);fill(x,y,54,1,line);fill(x,y+53,54,1,line);fill(x,y,1,54,line);fill(x+53,y,1,54,line);for(const command of commands){const color=asGray?gray(channels(command.color)):channels(command.color);fill(x+11+command.x,y+11+command.y,command.w,command.h,color);}};
const paired=tier2ComparisonPairs.flat();
for(const [index,id] of paired.entries()){const commands=tier2CatalogueItemIDs.includes(id)?tier2CatalogueItemIconCommands(id):catalogueItemIconCommands(id);drawCell(commands,index,12,false);drawCell(commands,index,412,true);}
const scale2=commands=>commands.map(command=>({...command,x:command.x*2,y:command.y*2,w:command.w*2,h:command.h*2}));
const risk=[...tier2CatalogueItemIDs.map(id=>({id,commands:tier2CatalogueItemIconCommands(id)})),{id:"unknown",commands:unknownItemIconCommands()},{id:"resource:rubble",commands:economyIdentityCommands(economyIdentityFixtures[0])},{id:"material:glassy_quill",commands:economyIdentityCommands(economyIdentityFixtures[1])},{id:"resource:essence_raw",commands:scale2(resourceInventoryIconCommands("essence_raw"))}];
for(const [index,entry] of risk.entries()){const x=12+(index%12)*60,y=278+Math.floor(index/12)*60;fill(x,y,54,54,panel);fill(x,y,54,1,line);fill(x,y+53,54,1,line);fill(x,y,1,54,line);fill(x+53,y,1,54,line);for(const command of entry.commands)fill(x+11+command.x,y+11+command.y,command.w,command.h,gray(channels(command.color)));}
const crcTable=Array.from({length:256},(_,n)=>{let c=n;for(let k=0;k<8;k++)c=(c&1)?0xedb88320^(c>>>1):c>>>1;return c>>>0;});
const crc=buffer=>{let c=0xffffffff;for(const byte of buffer)c=crcTable[(c^byte)&255]^(c>>>8);return(c^0xffffffff)>>>0;};
const chunk=(type,data)=>{const name=Buffer.from(type),result=Buffer.alloc(12+data.length);result.writeUInt32BE(data.length);name.copy(result,4);data.copy(result,8);result.writeUInt32BE(crc(Buffer.concat([name,data])),8+data.length);return result;};
const raw=Buffer.alloc((width*4+1)*height);for(let y=0;y<height;y++)rgba.copy(raw,y*(width*4+1)+1,y*width*4,(y+1)*width*4);
const ihdr=Buffer.alloc(13);ihdr.writeUInt32BE(width,0);ihdr.writeUInt32BE(height,4);ihdr[8]=8;ihdr[9]=6;
const png=Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk("IHDR",ihdr),chunk("IDAT",deflateSync(raw)),chunk("IEND",Buffer.alloc(0))]);
const output=new URL("../artifacts/",import.meta.url);await mkdir(output,{recursive:true});
await writeFile(new URL("catalogue-tier2-proof-v0.1.png",output),png);
const key={evidenceRole:"assetlabReviewFixture",integrationReady:false,version:tier2CatalogueVisualVersion,panelOrder:["color","literalGrayscale","literalGrayscaleCrossDomainRiskRow"],cellOrder:"counterpart then tier2",pairs:tier2ComparisonPairs.map(([accepted,tier2],index)=>({number:index+1,accepted,tier2})),riskRow:risk.map(entry=>entry.id),pngSHA256:createHash("sha256").update(png).digest("hex")};
await writeFile(new URL("catalogue-tier2-proof-v0.1.json",output),`${JSON.stringify(key,null,2)}\n`);
console.log(JSON.stringify({file:"artifacts/catalogue-tier2-proof-v0.1.png",width,height,pngSHA256:key.pngSHA256,pairs:key.pairs.length},null,2));
