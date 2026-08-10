import { hash } from "./generator.js";

export function rasterTokens(commands,width,height){
  const pixels=Array(width*height).fill("transparent");
  for(const command of commands){
    const startX=Math.max(0,command.x),startY=Math.max(0,command.y),endX=Math.min(width,command.x+command.w),endY=Math.min(height,command.y+command.h);
    for(let y=startY;y<endY;y++)for(let x=startX;x<endX;x++)pixels[y*width+x]=command.color;
  }
  return pixels;
}
export function rasterHash(commands,width,height){return hash(rasterTokens(commands,width,height));}
export function diffRasters(before,after,width){
  if(before.length!==after.length)throw new Error("Raster sizes differ");
  let changed=0,minX=Infinity,minY=Infinity,maxX=-1,maxY=-1;
  for(let index=0;index<before.length;index++)if(before[index]!==after[index]){changed++;const x=index%width,y=Math.floor(index/width);minX=Math.min(minX,x);minY=Math.min(minY,y);maxX=Math.max(maxX,x);maxY=Math.max(maxY,y);}
  return{changedPixels:changed,bounds:changed?{x:minX,y:minY,width:maxX-minX+1,height:maxY-minY+1}:null};
}
