import crypto from "node:crypto";

export const TILE_SIZE=16;
export const CENTRAL_RESERVATION=Object.freeze({x:5,y:5,width:6,height:6});
export const DIRECTIONS=Object.freeze(["north","east","south","west"]);
export const CUE_KINDS=Object.freeze(["known-harm","slow"]);
export const CUE_PALETTE=Object.freeze({
  harmBody:[216,107,92,255],
  harmHighlight:[244,165,139,255],
  slowOuter:[76,86,92,255],
  slowInner:[132,142,145,255]
});
export const BACKGROUNDS=Object.freeze({
  darkStone:{base:[53,57,59,255],detail:[82,87,86,255]},
  lightSand:{base:[201,177,119,255],detail:[164,137,87,255]},
  shallowWater:{base:[55,116,137,255],detail:[103,164,173,255]},
  denseGrowth:{base:[53,100,61,255],detail:[93,139,75,255]}
});

export const sha256=bytes=>crypto.createHash("sha256").update(bytes).digest("hex");
const blank=()=>new Uint8ClampedArray(TILE_SIZE*TILE_SIZE*4);
const set=(pixels,x,y,rgba)=>pixels.set(rgba,(y*TILE_SIZE+x)*4);
const alphaAt=(pixels,x,y)=>pixels[(y*TILE_SIZE+x)*4+3];

function northCue(kind){
  const pixels=blank();
  if(kind==="known-harm"){
    // Separated shoulders step inward, then join as one short lighter inner bow.
    [[3,4,0],[11,12,0],[4,5,1],[10,11,1],[5,6,2],[9,10,2]].forEach(([start,end,y])=>{for(let x=start;x<=end;x++)set(pixels,x,y,CUE_PALETTE.harmBody)});
    for(let x=6;x<=9;x++)set(pixels,x,3,CUE_PALETTE.harmHighlight);
  }else if(kind==="slow"){
    const rays=[[[3,1],[4,2],[5,3]],[[7,0],[7,1],[7,2]],[[12,1],[11,2],[10,3]]];
    for(const ray of rays)ray.forEach(([x,y],index)=>set(pixels,x,y,index===0?CUE_PALETTE.slowOuter:CUE_PALETTE.slowInner));
  }else throw new Error(`unknown cue kind: ${kind}`);
  return pixels;
}

export function rotateClockwise(pixels,quarterTurns){
  if(!(pixels instanceof Uint8ClampedArray)||pixels.length!==TILE_SIZE*TILE_SIZE*4)throw new Error("invalid cue pixels");
  let source=new Uint8ClampedArray(pixels),turns=((quarterTurns%4)+4)%4;
  for(let n=0;n<turns;n++){const out=blank();for(let y=0;y<TILE_SIZE;y++)for(let x=0;x<TILE_SIZE;x++){const i=(y*TILE_SIZE+x)*4;if(source[i+3])out.set(source.slice(i,i+4),(x*TILE_SIZE+(TILE_SIZE-1-y))*4)}source=out}
  return source;
}

export function cueLayer(kind,direction){
  const turns=DIRECTIONS.indexOf(direction);if(turns<0)throw new Error(`unknown cue direction: ${direction}`);
  return rotateClockwise(northCue(kind),turns);
}

export function compositeCueLayers(layers){
  const out=blank();
  for(const layer of layers){if(!(layer instanceof Uint8ClampedArray)||layer.length!==out.length)throw new Error("invalid cue layer");for(let i=0;i<out.length;i+=4)if(layer[i+3])out.set(layer.slice(i,i+4),i)}
  return out;
}

export function cueStatePixels(state){
  const layers=[];for(const direction of DIRECTIONS){const kinds=state?.[direction]??[];for(const kind of kinds)layers.push(cueLayer(kind,direction))}return compositeCueLayers(layers);
}

export function backgroundPixels(backgroundID){
  const palette=BACKGROUNDS[backgroundID];if(!palette)throw new Error(`unknown cue background: ${backgroundID}`);const pixels=blank();for(let y=0;y<TILE_SIZE;y++)for(let x=0;x<TILE_SIZE;x++){const detail=((x*5+y*3+(x>>2))%11===0)||backgroundID==="denseGrowth"&&((x+y*2)%7===0);set(pixels,x,y,detail?palette.detail:palette.base)}return pixels;
}

export function partyMarkerPixels(){
  const pixels=blank(),disc=[45,79,78,255],discEdge=[111,140,132,255],edge=[39,31,25,255],paper=[231,210,159,255],gold=[204,158,69,255];
  [[6,9],[4,11],[3,12],[2,13],[2,13],[2,13],[2,13],[3,12],[4,11],[6,9]].forEach(([start,end],index)=>{const y=index+2;for(let x=start;x<=end;x++)set(pixels,x,y,(x===start||x===end||index===0||index===9)?discEdge:disc)});
  for(let y=5;y<=10;y++)for(let x=5;x<=10;x++)set(pixels,x,y,(x===5||x===10||y===5||y===10)?edge:paper);
  set(pixels,7,7,gold);set(pixels,8,7,gold);set(pixels,7,8,gold);set(pixels,8,8,gold);
  return pixels;
}

export function tilePixels({backgroundID="darkStone",state={},visibility="full",party=true}={}){
  if(!["full","fringe","hidden"].includes(visibility))throw new Error(`unknown cue visibility: ${visibility}`);
  const background=backgroundPixels(backgroundID),out=new Uint8ClampedArray(background);
  if(visibility==="hidden")for(let i=0;i<out.length;i+=4)set(out,(i/4)%16,Math.floor(i/64),[10,13,13,255]);
  if(visibility==="fringe")for(let i=0;i<out.length;i+=4){out[i]=Math.floor(out[i]*.42);out[i+1]=Math.floor(out[i+1]*.42);out[i+2]=Math.floor(out[i+2]*.42)}
  if(party){const marker=partyMarkerPixels();for(let i=0;i<out.length;i+=4)if(marker[i+3])out.set(marker.slice(i,i+4),i)}
  if(visibility==="full"){const cues=cueStatePixels(state);for(let i=0;i<out.length;i+=4)if(cues[i+3])out.set(cues.slice(i,i+4),i)}
  return out;
}

export function opaqueCoordinates(pixels){const points=[];for(let y=0;y<TILE_SIZE;y++)for(let x=0;x<TILE_SIZE;x++)if(alphaAt(pixels,x,y))points.push([x,y]);return points}
export function alphaMask(pixels){const out=[];for(let i=3;i<pixels.length;i+=4)out.push(pixels[i]);return out}
export function literalGray(pixels){const out=new Uint8ClampedArray(pixels);for(let i=0;i<out.length;i+=4){const value=Math.round(out[i]*.2126+out[i+1]*.7152+out[i+2]*.0722);out[i]=out[i+1]=out[i+2]=value}return out}
export function rgbaHash(pixels){return sha256(Buffer.from(pixels))}
