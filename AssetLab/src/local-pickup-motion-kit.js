import crypto from "node:crypto";
import {resourceInventoryIconCommands} from "./resource-kit.js";

export const PICKUP_SIZE=16;
export const PICKUP_KEYS=Object.freeze(["pickup.resource.quartz","pickup.resource.essence_raw","pickup.item.blade_chipped","pickup.writing.page","pickup.object.unknown"]);
export const FRAME_TIMES=Object.freeze([0,180,450]);
export const PICKUP_PIVOT=Object.freeze({x:8,y:8});
const rgba=hex=>{const value=hex.slice(1);return[value.length===3?parseInt(value[0]+value[0],16):parseInt(value.slice(0,2),16),value.length===3?parseInt(value[1]+value[1],16):parseInt(value.slice(2,4),16),value.length===3?parseInt(value[2]+value[2],16):parseInt(value.slice(4,6),16),255]};
const blank=()=>new Uint8ClampedArray(PICKUP_SIZE*PICKUP_SIZE*4);
const set=(pixels,x,y,color)=>{if(x>=0&&x<16&&y>=0&&y<16)pixels.set(Array.isArray(color)?color:rgba(color),(y*16+x)*4)};
const rect=(pixels,x,y,w,h,color)=>{for(let py=y;py<y+h;py++)for(let px=x;px<x+w;px++)set(pixels,px,py,color)};
const commandsToPixels=commands=>{const out=blank();for(const command of commands)rect(out,command.x,command.y,command.w,command.h,command.color);return out};

function chippedBlade(){const p=blank(),dark="#312820",steel="#adb4ae",light="#e7dfca",wrap="#805d43";rect(p,7,1,3,3,light);rect(p,6,4,4,3,steel);rect(p,6,7,3,3,light);set(p,9,7,dark);rect(p,4,10,8,2,dark);rect(p,5,10,6,1,steel);rect(p,7,12,2,3,wrap);set(p,8,15,wrap);return p}
function recoveredPage(){const p=blank(),edge="#6d5538",paper="#eee2bf",shade="#ccb98c",fold="#9f8257";rect(p,3,3,10,10,edge);rect(p,4,2,8,11,paper);rect(p,5,4,6,1,shade);rect(p,5,7,5,1,shade);rect(p,5,10,4,1,shade);for(let i=0;i<4;i++)set(p,8+i,9+i,fold);rect(p,9,10,3,2,"#dac99e");return p}
function unknownParcel(){const p=blank(),edge="#332820",cloth="#8c684b",light="#c9aa72",tie="#d1bb82";rect(p,3,5,10,8,edge);rect(p,4,4,8,9,cloth);rect(p,3,7,10,2,light);rect(p,7,3,2,11,tie);set(p,5,4,light);set(p,10,4,light);return p}

export function pickupIdentityPixels(key){
  if(key==="pickup.resource.quartz")return commandsToPixels(resourceInventoryIconCommands("quartz"));
  if(key==="pickup.resource.essence_raw")return commandsToPixels(resourceInventoryIconCommands("essence_raw"));
  if(key==="pickup.item.blade_chipped")return chippedBlade();
  if(key==="pickup.writing.page")return recoveredPage();
  if(key==="pickup.object.unknown")return unknownParcel();
  throw new Error(`unknown-pickup-identity:${key}`);
}
export const literalGray=pixels=>{const out=new Uint8ClampedArray(pixels);for(let i=0;i<out.length;i+=4){const v=Math.round(out[i]*.2126+out[i+1]*.7152+out[i+2]*.0722);out[i]=out[i+1]=out[i+2]=v}return out};
export const rgbaHash=pixels=>crypto.createHash("sha256").update(Buffer.from(pixels)).digest("hex");
export const alphaMask=pixels=>Array.from({length:256},(_,i)=>pixels[i*4+3]);
export function occupiedBounds(pixels){const points=[];for(let y=0;y<16;y++)for(let x=0;x<16;x++)if(pixels[(y*16+x)*4+3])points.push([x,y]);if(!points.length)return null;return{x:Math.min(...points.map(p=>p[0])),y:Math.min(...points.map(p=>p[1])),width:Math.max(...points.map(p=>p[0]))-Math.min(...points.map(p=>p[0]))+1,height:Math.max(...points.map(p=>p[1]))-Math.min(...points.map(p=>p[1]))+1}}

export function normalizePickupRequest(request){
  const exact=["group","mapViewportBounds","reducedMotion","sourcePointInMapViewport","sourceTileCoordinate","transactionReceiptID","worldRunID"].sort();
  if(!request||JSON.stringify(Object.keys(request).sort())!==JSON.stringify(exact))throw new Error("invalid-pickup-request-fields");
  const receipt=request.transactionReceiptID,receiptKeys=["actionKind","mapSeed","runIndex","sourceTileCoordinate","turnsTakenBeforeAction"].sort();
  if(!receipt||JSON.stringify(Object.keys(receipt).sort())!==JSON.stringify(receiptKeys)||!Number.isInteger(receipt.runIndex)||!Number.isInteger(receipt.mapSeed)||!Number.isInteger(receipt.turnsTakenBeforeAction)||!["stepPickup","harvest"].includes(receipt.actionKind)||JSON.stringify(receipt.sourceTileCoordinate)!==JSON.stringify(request.sourceTileCoordinate)||!request.worldRunID)throw new Error("invalid-pickup-receipt");
  const group=request.group;if(!group||JSON.stringify(Object.keys(group).sort())!==JSON.stringify(["knownness","presentationIdentityKey","quantity"].sort()))throw new Error("invalid-pickup-group-fields");if(!PICKUP_KEYS.includes(group.presentationIdentityKey)||!Number.isInteger(group.quantity)||group.quantity<1||!["known","unidentified"].includes(group.knownness))throw new Error("invalid-pickup-group");if(group.knownness==="unidentified"&&group.presentationIdentityKey!=="pickup.object.unknown")throw new Error("unidentified-must-use-opaque-parcel");if(group.knownness==="known"&&group.presentationIdentityKey==="pickup.object.unknown")throw new Error("known-cannot-use-opaque-parcel");return{...request,group:{...group}};
}

const clamp=(value,min,max)=>Math.max(min,Math.min(max,value));
export function pickupPresentation(request,timeMS,tileHeight=32,labelWidth=28){
  const value=normalizePickupRequest(request),elapsed=Math.max(0,timeMS),group=value.group,bounds=value.mapViewportBounds,duration=value.reducedMotion?250:450,progress=clamp(elapsed/duration,0,1),travel=value.reducedMotion?0:1.5*tileHeight*progress,opacity=value.reducedMotion?1-progress:elapsed<=180?1:Math.max(0,1-(elapsed-180)/270),scale=value.reducedMotion?.9+.1*progress:elapsed<=180?1+.05*(elapsed/180):1.05-.1*((elapsed-180)/270),iconHalf=16*scale,label=group.quantity>1?`×${group.quantity}`:null,labelGap=label?4:0,rightExtent=Math.max(iconHalf,label?iconHalf+labelGap+labelWidth:iconHalf),leftExtent=iconHalf,minX=bounds.x+leftExtent,maxX=bounds.x+bounds.width-rightExtent,minY=bounds.y+iconHalf,maxY=bounds.y+bounds.height-iconHalf,x=clamp(value.sourcePointInMapViewport.x,minX,maxX),startY=clamp(value.sourcePointInMapViewport.y,minY,maxY),y=clamp(startY-travel,minY,maxY),frameBounds={left:x-leftExtent,right:x+rightExtent,top:y-iconHalf,bottom:y+iconHalf};
  return{frame:{key:group.presentationIdentityKey,quantity:group.quantity,x,y,opacity,scale,label,labelX:x+iconHalf+labelGap,labelY:y-7,bounds:frameBounds},clipRect:{...bounds},duplicateKey:`${value.worldRunID}:${value.transactionReceiptID.runIndex}:${value.transactionReceiptID.mapSeed}:${value.transactionReceiptID.turnsTakenBeforeAction}:${value.transactionReceiptID.actionKind}:${value.sourceTileCoordinate.x},${value.sourceTileCoordinate.y}`,layerOrder:["terrain-content-party-cues-selection","local-pickup-feedback","look-tutorial-bug-system-overlays"]};
}
