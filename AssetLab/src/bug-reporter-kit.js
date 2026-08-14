export const bugReporterContract=Object.freeze({
  version:"debug-bug-reporter-fixture-1.0.0",
  evidenceRole:"proposedSemanticFixture",
  integrationReady:false,
  buildScope:"DEBUG-only",
  initialTriage:"untriaged",
  screenshotTiming:"before-sheet",
  reporterExcludedFromScreenshot:true,
  transportTruth:"local outbox until a configured destination acknowledges the same report ID"
});

export const reporterTarget=Object.freeze({width:44,height:44,defaultEdge:"trailing",defaultFraction:0.68});
const intersects=(a,b)=>a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y;
export function resolveReporterPlacement({screenWidth,screenHeight,safeTop,safeBottom,requiredActions,preferredEdge="trailing",preferredFraction=.68}){
  const actionGeometry=Array.isArray(requiredActions)&&requiredActions.every(a=>a&&[a.x,a.y,a.w,a.h].every(Number.isFinite)&&a.w>0&&a.h>0);
  if(![screenWidth,screenHeight,safeTop,safeBottom].every(Number.isFinite)||screenWidth<reporterTarget.width+16||screenHeight<reporterTarget.height+safeTop+safeBottom+16||safeTop<0||safeBottom<0||!actionGeometry||!["leading","trailing"].includes(preferredEdge)||!Number.isFinite(preferredFraction)||preferredFraction<0||preferredFraction>1)return{ok:false,diagnostics:[issue("invalid-placement-input","placement","closed screen, edge, fraction and finite positive action geometry required")]};
  const inset=8,minY=safeTop+inset,maxY=screenHeight-safeBottom-inset-reporterTarget.height,at=f=>Math.max(minY,Math.min(maxY,Math.round(minY+(maxY-minY)*f))),edges=preferredEdge==="leading"?["leading","trailing"]:["trailing","leading"],fractions=[preferredFraction,.5,.25,.8];
  for(const edge of edges)for(const fraction of fractions){const rect={x:edge==="trailing"?screenWidth-inset-reporterTarget.width:inset,y:at(fraction),w:reporterTarget.width,h:reporterTarget.height,edge,fraction};if(requiredActions.every(action=>!intersects(rect,action)))return{ok:true,rect,diagnostics:[]};}
  return{ok:false,diagnostics:[issue("no-safe-placement","placement","no candidate edge position avoids required actions")]};
}

export function reporterAvailability(buildConfiguration){return buildConfiguration==="DEBUG"?{visible:true,accessible:true}:{visible:false,accessible:false};}
export function validateReportText(value){return typeof value==="string"&&value.trim().length>0?{valid:true,message:""}:{valid:false,message:"Describe what happened before saving."};}

export const reporterSceneCommands=Object.freeze([
  Object.freeze({op:"rect",x:0,y:0,w:366,h:180,color:"#20201d"}),
  Object.freeze({op:"rect",x:8,y:76,w:292,h:8,color:"#ddbf70"}),
  Object.freeze({op:"rect",x:300,y:76,w:8,h:64,color:"#ddbf70"}),
  Object.freeze({op:"rect",x:294,y:129,w:16,h:16,color:"#f1e4cd"})
]);
export const reporterOverlayCommands=Object.freeze([Object.freeze({op:"rect",x:302,y:12,w:52,h:52,color:"#302b25"}),Object.freeze({op:"rect",x:315,y:26,w:26,h:18,color:"#d8aa62"})]);
export const capturedSceneCommands=()=>reporterSceneCommands.map(command=>({...command}));
export const readySceneCommands=()=>[...capturedSceneCommands(),...reporterOverlayCommands.map(command=>({...command}))];

export const reportStates=Object.freeze(["draft","saving","unsent","sending","submitted","needsAttention"]);

const allowed=Object.freeze(["id","state","whatHappened","expected","screenshotState","captureFailureReason","context","remoteReference"]);
const contextAllowed=Object.freeze(["screen","route","build","campaignHash","runID","worldID","position","actionCount"]);
const issue=(code,path,message)=>({code,path,message});
function unknownFields(value,keys,path,issues){if(!value||typeof value!=="object"||Array.isArray(value))return;for(const key of Object.keys(value))if(!keys.includes(key))issues.push(issue("unknown-field",path?`${path}.${key}`:key,"field is outside the proposed reporter fixture"));}

export function resolveBugReport(raw){
  const issues=[];unknownFields(raw,allowed,"",issues);unknownFields(raw?.context,contextAllowed,"context",issues);
  if(typeof raw?.id!=="string"||!/^bug-[a-z0-9-]{8,64}$/.test(raw.id))issues.push(issue("invalid-id","id","stable BugReportID required"));
  if(!reportStates.includes(raw?.state))issues.push(issue("invalid-state","state","unknown reporter state"));
  if(typeof raw?.whatHappened!=="string"||raw.whatHappened.trim().length<1)issues.push(issue("required","whatHappened","describe what happened"));
  if(typeof raw?.expected!=="string")issues.push(issue("invalid-type","expected","expected must be a string, including empty"));
  if(!["attached","removed","captureFailed"].includes(raw?.screenshotState))issues.push(issue("invalid-screenshot-state","screenshotState","attached, removed, or captureFailed required"));
  if(raw?.screenshotState==="captureFailed"&&!['appSceneUnavailable','captureServiceError'].includes(raw?.captureFailureReason))issues.push(issue("invalid-capture-failure","captureFailureReason","allowlisted failure reason required"));
  if(raw?.screenshotState!=="captureFailed"&&raw?.captureFailureReason!=null)issues.push(issue("unexpected-capture-failure","captureFailureReason","only captureFailed owns a reason"));
  if(!raw?.context||typeof raw.context!=="object"||Array.isArray(raw.context))issues.push(issue("invalid-context","context","bounded context object required"));
  else{
    for(const key of ["screen","route","build"])if(typeof raw.context[key]!=="string"||raw.context[key].length<1||raw.context[key].length>80)issues.push(issue("invalid-context-value",`context.${key}`,"required bounded string"));
    for(const key of ["campaignHash","runID","worldID","position"])if(raw.context[key]!=null&&(typeof raw.context[key]!=="string"||raw.context[key].length<1||raw.context[key].length>80))issues.push(issue("invalid-context-value",`context.${key}`,"optional nonempty bounded string or absent"));
    if(!Number.isInteger(raw.context.actionCount)||raw.context.actionCount<0||raw.context.actionCount>20)issues.push(issue("invalid-context-value","context.actionCount","bounded semantic action count 0...20"));
  }
  if(raw?.state==="submitted"&&(typeof raw?.remoteReference!=="string"||raw.remoteReference.length<1||raw.remoteReference.length>120))issues.push(issue("missing-remote-reference","remoteReference","submitted requires nonempty bounded destination acknowledgement"));
  if(raw?.state!=="submitted"&&raw?.remoteReference!=null)issues.push(issue("premature-remote-reference","remoteReference","only submitted reports own a remote reference"));
  if(issues.length)return{ok:false,diagnostics:issues};
  return{ok:true,report:structuredClone(raw),diagnostics:[]};
}

export function localSaveResult(report){
  if(report?.state!=="draft")return{ok:false,diagnostics:[issue("illegal-transition","state","only a draft may be saved to the local outbox")]};
  const resolved=resolveBugReport({...report,state:"unsent",remoteReference:undefined});
  if(!resolved.ok)return resolved;
  return{ok:true,state:"unsent",message:"Saved on this phone",queue:"Untriaged",id:report.id,diagnostics:[]};
}

export function transportResult(report,{acknowledged=false,remoteReference=null}={}){
  if(!["unsent","needsAttention"].includes(report?.state))return{ok:false,diagnostics:[issue("illegal-transition","state","only unsent or needsAttention may begin a transport attempt")]};
  const state=acknowledged?"submitted":"needsAttention",candidate={...report,state,remoteReference:acknowledged?remoteReference:undefined};
  const resolved=resolveBugReport(candidate);if(!resolved.ok)return resolved;
  return{ok:true,state,message:acknowledged?"Submitted":"Saved on this phone · sharing needs attention",id:report.id,remoteReference:acknowledged?remoteReference:null,diagnostics:[]};
}

export const bugReporterFixture=Object.freeze({
  id:"bug-map-route-0017",
  state:"draft",
  whatHappened:"The route line disappeared behind the raised tile.",
  expected:"The route should stay visible on the lifted surface.",
  screenshotState:"attached",
  context:Object.freeze({screen:"World",route:"world.map",build:"DEBUG fixture",campaignHash:"camp-7d3a",runID:"run-12",worldID:"world-5",position:"14,9",actionCount:20})
});
