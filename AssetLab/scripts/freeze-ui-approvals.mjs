import {execFile} from "node:child_process";
import {mkdtemp,mkdir,readFile,rm,writeFile} from "node:fs/promises";
import {tmpdir} from "node:os";
import {dirname,join} from "node:path";
import {pathToFileURL} from "node:url";
import {promisify} from "node:util";
import {createUIApprovalProof,freezeUIApprovalStyles} from "../src/ui-approval-proof.js";

const execFileAsync=promisify(execFile),assetRoot=new URL("..",import.meta.url).pathname,repoRoot=join(assetRoot,"..");
const reviewFile=join(assetRoot,"reviews","ui-gallery-reviews.json"),styleDirectory=join(assetRoot,"reviews","approved-styles"),assetDirectory=join(assetRoot,"reviews","approved-assets");
const approvalRevision="4c8fce9",historicallyApproved=["storehouse","workshop","party","essence-spring","world-history","blacksmith","trading-post","recycler","tannery","bowyer","armoury","weaponsmith","scriptorium","survey-post","apothecary","reliquary","wayfarer-s-table"];

async function sourceAt(revision){
  const directory=await mkdtemp(join(tmpdir(),"bookbinder-ui-approval-"));
  const paths=["AssetLab/src/ui-gallery-app.js","AssetLab/src/ui-native-conformance.js","AssetLab/src/ui-preservation-ledger.js","AssetLab/ui-gallery.css","AssetLab/styles.css","AssetLab/fonts","AssetLab/integration/starting-town-home-v1"];
  await execFileAsync("git",["archive","--format=tar",revision,...paths],{cwd:repoRoot,maxBuffer:40_000_000,encoding:"buffer"}).then(({stdout})=>writeFile(join(directory,"archive.tar"),stdout));
  await execFileAsync("tar",["-xf",join(directory,"archive.tar"),"-C",directory]);
  return {directory,assetRoot:join(directory,"AssetLab")};
}

async function proofFor({screenID,decision,notes,designVersion,revision,sourceRoot,approvedAt}){
  const module=await import(`${pathToFileURL(join(sourceRoot,"src","ui-gallery-app.js")).href}?approval=${revision}`),screen=module.screens.find(item=>item.id===screenID);
  if(!screen)throw new Error(`Unknown historical UI screen ${screenID}`);
  const fixtureStates=module.fixtureStatesByScreen?.[screenID]??["Default","Selected","Confirm"],htmlByState=Object.fromEntries(fixtureStates.map(state=>[state,module.renderScreen(screen.title,state)])),rawCSS=`${await readFile(join(sourceRoot,"styles.css"),"utf8")}\n${await readFile(join(sourceRoot,"ui-gallery.css"),"utf8")}`,css=await freezeUIApprovalStyles({css:rawCSS,sourceRoot,assetDirectory});
  return {proof:createUIApprovalProof({screenID,decision,notes,designVersion,sourceRevision:revision,fixtureStates,htmlByState,css,approvedAt}),css};
}

const historical=await sourceAt(approvalRevision);
try{
  const packet=JSON.parse(await readFile(reviewFile,"utf8")),approvals={};
  for(const screenID of historicallyApproved){
    const record=packet.reviews?.[screenID];
    if(record?.choice!=="yes")throw new Error(`Historical approval missing for ${screenID}`);
    const {proof,css}=await proofFor({screenID,decision:"yes",notes:record.notes??"",designVersion:record.designVersion??"draft-0",revision:approvalRevision,sourceRoot:historical.assetRoot,approvedAt:"2026-08-18T20:36:44.000Z"});
    approvals[screenID]=proof;await mkdir(styleDirectory,{recursive:true});await writeFile(join(styleDirectory,`${proof.styleSHA256}.css`),css);
  }
  const current=await import(`${pathToFileURL(join(assetRoot,"src","ui-gallery-app.js")).href}?approval=current`),campaign=current.screens.find(item=>item.id==="campaigns"),campaignStates=current.fixtureStatesByScreen.campaigns??["Default","Selected","Confirm"],campaignRawCSS=`${await readFile(join(assetRoot,"styles.css"),"utf8")}\n${await readFile(join(assetRoot,"ui-gallery.css"),"utf8")}`,campaignCSS=await freezeUIApprovalStyles({css:campaignRawCSS,sourceRoot:assetRoot,assetDirectory}),campaignHTML=Object.fromEntries(campaignStates.map(state=>[state,current.renderScreen(campaign.title,state)]));
  const campaignProof=createUIApprovalProof({screenID:"campaigns",decision:"baseline",notes:"Restored and frozen by Aimee's direct instruction.",designVersion:"restored-a5f2512",sourceRevision:"a5f2512",fixtureStates:campaignStates,htmlByState:campaignHTML,css:campaignCSS,approvedAt:"2026-08-18T21:18:21.000Z"});
  approvals.campaigns=campaignProof;await mkdir(styleDirectory,{recursive:true});await writeFile(join(styleDirectory,`${campaignProof.styleSHA256}.css`),campaignCSS);
  const migrated={schemaVersion:2,updatedAt:packet.updatedAt,reviews:packet.reviews,approvals};
  await mkdir(dirname(reviewFile),{recursive:true});await writeFile(reviewFile,`${JSON.stringify(migrated,null,2)}\n`);
  console.log(`Frozen ${Object.keys(approvals).length} approved UI baselines.`);
}finally{await rm(historical.directory,{recursive:true,force:true})}
