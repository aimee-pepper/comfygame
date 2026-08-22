export const PAGE=172,MARGIN=5,WRITING=162,SOCKET=27,AXIS=6;
export const parchmentPalette=Object.freeze({edgeDeep:[147,108,68,255],edge:[174,134,87,255],edgeLight:[199,163,111,255],paperDeep:[207,174,122,255],paperDark:[215,184,135,255],paper:[224,199,154,255],paperWarm:[231,209,169,255],paperLight:[239,222,187,255],fiberDark:[195,158,108,255],fiberLight:[240,220,180,255],rule:[213,184,137,255]});
export const guideCoordinates=Object.freeze([1,2,3,4,5].map(i=>MARGIN+i*SOCKET));
export function assertParchmentGeometry(pixels){if(!(pixels instanceof Uint8ClampedArray)||pixels.length!==PAGE*PAGE*4)throw Error("invalid-parchment-rgba");if(guideCoordinates.join()!=="32,59,86,113,140")throw Error("invalid-parchment-guides");return true;}
export function literalGrayscale(pixels){assertParchmentGeometry(pixels);const out=new Uint8ClampedArray(pixels);for(let i=0;i<out.length;i+=4){const v=Math.round(out[i]*.2126+out[i+1]*.7152+out[i+2]*.0722);out[i]=out[i+1]=out[i+2]=v;}return out;}
