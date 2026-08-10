import { normalizeDescriptor } from "./generator.js";
import { normalizeFlora } from "./world-generator.js";

const allocation=(values,total=100)=>{const sum=values.reduce((value,item)=>value+item,0)||1;let used=0;return values.map((item,index)=>{const value=index===values.length-1?total-used:Math.round(item/sum*total*1000)/1000;used+=value;return value;});};

export function creatureLiveContract(raw){
  const assumedEmanation=!!raw?.traits&&!["emanationLight","emanationHeat","emanationCaustic"].some(key=>Number.isFinite(Number(raw.traits[key]))),descriptor=normalizeDescriptor(raw),t=descriptor.traits;
  const [cyan,magenta,yellow]=allocation([t.cyan,t.magenta,t.yellow]),[opacity,shine,schiller]=allocation([t.opacity,t.shine,t.schiller]),[vision,mechano,chemo,thermo]=allocation([t.vision,t.mechano,t.chemo,t.thermo]),[light,heat,caustic]=allocation([t.emanationLight,t.emanationHeat,t.emanationCaustic]),[pierceMix,crushMix,rendMix]=allocation([t.pierce,t.crush,t.rend],1);
  const adapterDiagnostics=[];
  if(assumedEmanation)adapterDiagnostics.push({severity:"warning",code:"assumed-emanation-allocation",field:"traits.emanationKind",message:"Legacy dominant-kind emanation was expanded to an assumed 70/15/15 allocation; review before integration."});
  return {gameIdentity:{size:t.size,covering:{hardness:t.coveringHardness,length:t.coveringLength,coverage:t.coveringCoverage},boneDensity:t.boneDensity,armament:{pierce:t.pierce,crush:t.crush,rend:t.rend,reach:t.reach,delivery:t.delivery,mix:{pierce:pierceMix,crush:crushMix,rend:rendMix}},ornament:t.ornament,build:t.build,appendages:{count:t.appendageCount,type:t.appendageType},coloration:{cyan,magenta,yellow,depth:t.colorDepth,patterning:t.patterning},finish:{opacity,shine,schiller},sensory:{vision,mechano,chemo,thermo},emanation:t.emanationStrength>0?{strength:t.emanationStrength,light,heat,caustic}:null,defence:t.defence==="none"?null:t.defence,isToxic:t.toxic},renderHints:{schemaVersion:1,topology:t.topology},adapterDiagnostics};
}

export function floraLiveContract(raw){
  const descriptor=normalizeFlora(raw),t=descriptor.traits,[cyan,magenta,yellow]=allocation([t.cyan,t.magenta,t.yellow]),[opacity,shine,schiller]=allocation([t.opacity,t.shine,t.schiller]),[woodyMix,fibrousMix,fleshyMix]=allocation([t.woody,t.fibrous,t.fleshy],1);
  return {gameIdentity:{stature:t.stature,tissue:{woody:t.tissueAmount*woodyMix,fibrous:t.tissueAmount*fibrousMix,fleshy:t.tissueAmount*fleshyMix,mix:{woody:woodyMix,fibrous:fibrousMix,fleshy:fleshyMix}},defence:t.defence,defenceType:t.defenceType,habit:t.habit,coloration:{cyan,magenta,yellow,depth:t.colorDepth,patterning:t.patterning},finish:{opacity,shine,schiller},metabolism:t.metabolism},renderHints:{schemaVersion:1},adapterDiagnostics:[]};
}
