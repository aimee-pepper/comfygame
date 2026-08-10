const rect=(x,y,w,h,color)=>({op:"rect",x,y,w,h,color});
const ink="#f4ead7",dark="#171614",gold="#d9ae59",blue="#69c4d4",red="#df6a62",green="#83b86b",violet="#a98ac4";

export const tileContentTypes=Object.freeze(["empty","node","wildDrop","hazard","portal","lockedCache","site","diaryPage","foundWriting","traveller"]);

export function tileContentCommands(raw={}){
  const type=tileContentTypes.includes(raw.type)?raw.type:"empty",direction=raw.portalDirection==="exit"?"exit":"entry";
  if(!raw.revealed||type==="empty")return [];
  switch(type){
  case "node": return [rect(4,7,8,6,dark),rect(5,5,3,3,ink),rect(9,4,3,4,gold),rect(7,9,3,3,gold)];
  case "wildDrop": return [rect(5,8,6,4,dark),rect(6,6,4,5,green),rect(9,5,2,2,ink)];
  case "hazard": return [rect(3,11,10,2,dark),rect(4,8,2,3,red),rect(7,5,2,6,red),rect(10,8,2,3,red)];
  case "portal": return direction==="entry"?[rect(3,3,10,10,blue),rect(5,5,6,6,dark),rect(7,7,2,2,ink)]:[rect(3,3,10,10,ink),rect(5,5,6,6,dark),rect(2,7,5,2,blue),rect(2,6,2,4,blue)];
  case "lockedCache": return [rect(3,7,10,7,dark),rect(4,8,8,5,gold),rect(6,4,5,5,dark),rect(7,5,3,3,ink),rect(8,9,2,3,dark)];
  case "site": return [rect(2,10,12,4,dark),rect(3,6,10,6,gold),rect(5,4,6,3,ink),rect(7,8,2,4,dark)];
  case "diaryPage": return [rect(4,3,9,11,dark),rect(3,2,9,11,ink),rect(5,5,5,1,violet),rect(5,8,4,1,dark),rect(5,10,5,1,dark)];
  case "foundWriting": return [rect(2,5,12,8,dark),rect(3,4,10,8,ink),rect(5,6,1,4,violet),rect(8,6,1,4,violet),rect(11,6,1,4,violet)];
  case "traveller": return [rect(6,2,4,4,dark),rect(7,3,2,2,ink),rect(4,6,8,3,dark),rect(2,7,3,2,ink),rect(11,7,3,2,ink),rect(6,8,4,4,blue),rect(5,12,2,3,dark),rect(9,12,2,3,dark)];
  default:return [];
  }
}

export function minimapContentCommands(raw={}){
  const type=tileContentTypes.includes(raw.type)?raw.type:"empty";
  if(!raw.revealed||!raw.discovered||type==="empty")return [];
  if(type==="portal")return raw.portalDirection==="exit"?[rect(0,0,4,4,ink),rect(0,1,3,2,blue)]:[rect(0,0,4,4,blue),rect(1,1,2,2,dark)];
  if(type==="site")return[rect(0,1,4,3,gold),rect(1,0,2,1,ink)];
  if(type==="diaryPage")return[rect(0,0,3,4,ink),rect(3,1,1,3,violet)];
  if(type==="foundWriting")return[rect(0,1,4,2,violet),rect(1,0,1,4,ink)];
  if(type==="traveller")return[rect(1,0,2,2,ink),rect(0,2,4,2,blue)];
  return [];
}
