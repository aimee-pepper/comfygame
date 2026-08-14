export const authoredColorVocabularyCandidateVersion="authored-color-vocabulary-candidate-0.1.0";

const entries=[
  {id:"red",name:"Red",route:"starter",oklch:[.60,.20,25],patternID:"split-vertical"},
  {id:"yellow",name:"Yellow",route:"starter",oklch:[.82,.16,95],patternID:"sun-cross"},
  {id:"blue",name:"Blue",route:"starter",oklch:[.58,.18,255],patternID:"double-wave"},
  {id:"grey",name:"Grey",route:"starter",oklch:[.62,.02,260],patternID:"middle-band"},
  {id:"orange",name:"Orange",route:"common",oklch:[.70,.18,55],patternID:"corner-step"},
  {id:"green",name:"Green",route:"common",oklch:[.62,.16,145],patternID:"leaf-chevron"},
  {id:"violet",name:"Violet",route:"common",oklch:[.55,.18,300],patternID:"diagonal-pair"},
  {id:"white",name:"White",route:"common",oklch:[.91,.015,95],patternID:"open-center"},
  {id:"black",name:"Black",route:"common",oklch:[.25,.015,260],patternID:"closed-center"},
  {id:"ochre",name:"Ochre",route:"common",oklch:[.64,.13,75],patternID:"earth-strata"},
  {id:"cyan",name:"Cyan",route:"later",oklch:[.70,.14,205],patternID:"three-dots"},
  {id:"magenta",name:"Magenta",route:"later",oklch:[.62,.20,335],patternID:"diamond"}
];

const clamp=n=>Math.max(0,Math.min(1,n));
export function oklchToSRGB(tuple){if(!Array.isArray(tuple)||tuple.length!==3||!tuple.every(Number.isFinite)||tuple[0]<0||tuple[0]>1||tuple[1]<0||tuple[1]>.4)throw new Error("invalid-oklch-tuple");const [L,C,h]=tuple,r=h*Math.PI/180,a=C*Math.cos(r),b=C*Math.sin(r),l_=L+.3963377774*a+.2158037573*b,m_=L-.1055613458*a-.0638541728*b,s_=L-.0894841775*a-1.291485548*b,l=l_**3,m=m_**3,s=s_**3,linear=[4.0767416621*l-3.3077115913*m+.2309699292*s,-1.2684380046*l+2.6097574011*m-.3413193965*s,-.0041960863*l-.7034186147*m+1.707614701*s];return Object.freeze(linear.map(v=>Math.round(255*clamp(v<=.0031308?12.92*v:1.055*v**(1/2.4)-.055))));}
export const authoredColorVocabulary=Object.freeze(entries.map(entry=>Object.freeze({...entry,oklch:Object.freeze([...entry.oklch])})));
export const authoredColorByID=Object.freeze(Object.fromEntries(authoredColorVocabulary.map(entry=>[entry.id,Object.freeze({...entry,srgb:oklchToSRGB(entry.oklch)})])));
export const authoredColorGamutPolicy=Object.freeze({space:"OKLCH",conversion:"OKLab matrix constants pinned in source",gamut:"per-channel linear-sRGB clipping",transferThreshold:.0031308,quantization:"round to nearest 8-bit channel"});
const patternRects=Object.freeze({"split-vertical":[[15,5,2,22]],"sun-cross":[[7,15,18,2],[15,7,2,18]],"double-wave":[[5,10,9,2],[12,15,15,2]],"middle-band":[[5,14,22,4]],"corner-step":[[5,7,8,3],[10,10,8,3],[15,13,8,3]],"leaf-chevron":[[7,9,3,14],[10,12,5,3],[15,9,3,3]],"diagonal-pair":Array.from({length:16},(_,i)=>[[6+i,7+i,2,2],[15+i,7+i,2,2]]).flat(),"open-center":[[8,8,16,3],[8,21,16,3],[8,11,3,10],[21,11,3,10]],"closed-center":[[9,9,14,14]],"earth-strata":[[5,9,22,3],[8,15,19,3],[5,21,14,3]],"three-dots":[[6,14,4,4],[14,14,4,4],[22,14,4,4]],diamond:Array.from({length:8},(_,i)=>[[15-i,8+i,2,2],[16+i,8+i,2,2],[8+i,16+i,2,2],[23-i,16+i,2,2]]).flat()});
export function resolveAuthoredColorPattern(patternID){const rects=patternRects[patternID];if(!rects)throw new Error(`unknown-authored-color-pattern:${patternID}`);return Object.freeze(rects.map(rect=>Object.freeze([...rect])));}
export const authoredColorScopeExamples=Object.freeze({sun:"emitter",smoke:"atmosphere",granite:"material",bloom:"flora"});
export function resolveAuthoredColorID(id){const value=authoredColorByID[id];if(!value)throw new Error(`unknown-authored-color:${id}`);return value;}
