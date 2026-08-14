import {resourceCatalogue} from "./resource-kit.js";
import {canonicalJSON,hash} from "./generator.js";

export const tradingPostContract=Object.freeze({
  version:"trading-post-ui-1.0.0",
  evidenceRole:"proposedSemanticFixture",
  integrationReady:false,
  collectionGrammar:"physical-object-six-across",
  ordinaryColumns:6,
  permanentNamesUnderIcons:false,
  selectionMutation:false,
  accessibilityColumns:"may-reduce-without-clipping",
  stationID:"trading_post",
  merchantID:"vance",
  stockOwnership:"proposed-persisted-snapshot",
  sellAvailability:"proposed-independent-of-stock-refresh",
  mutation:"rules-owned-confirm-only",
  currency:"goldCoins"
});

export const tradeBands=Object.freeze({staple:Object.freeze({sell:1,buy:3}),uncommon:Object.freeze({sell:2,buy:6}),rare:Object.freeze({sell:5,buy:null}),precious:Object.freeze({sell:12,buy:null})});

export const tradingPostFixtures=Object.freeze({
  wallet:18,
  refresh:Object.freeze({state:"ready",sequence:4,outcomeID:"outcome-17"}),
  stock:Object.freeze([
    Object.freeze({lineID:"stock-401",kind:"resource",identity:"clay",name:"Clay",family:"clay",quantity:6,unitPrice:3,known:true}),
    Object.freeze({lineID:"stock-402",kind:"resource",identity:"quartz",name:"Quartz",family:"quartz",quantity:2,unitPrice:6,known:true}),
    Object.freeze({lineID:"stock-403",kind:"resource",identity:"fiber",name:"Fibre",family:"fiber",quantity:8,unitPrice:3,known:true}),
    Object.freeze({lineID:"stock-404",kind:"resource",identity:"timber",name:"Timber",family:"timber",quantity:4,unitPrice:3,known:true}),
    Object.freeze({lineID:"stock-405",kind:"resource",identity:"salt",name:"Salt",family:"salt",quantity:5,unitPrice:3,known:true}),
    Object.freeze({lineID:"stock-406",kind:"resource",identity:"copper",name:"Copper",family:"copper",quantity:2,unitPrice:6,known:true})
  ]),
  holdings:Object.freeze([
    Object.freeze({selectionID:"sell-rubble",kind:"resource",identity:"rubble",name:"Rubble",family:"rubble",quantity:7,selectedQuantity:3,unitPrice:1,eligibility:"eligible",reason:null}),
    Object.freeze({selectionID:"sell-sample",kind:"sample",identity:"fixture-bin-7-index-0",name:"Fang sample · rare",family:"sample",quantity:1,selectedQuantity:1,unitPrice:4,eligibility:"eligible",reason:null}),
    Object.freeze({selectionID:"sell-chipped",kind:"gear",identity:"blade-2",name:"Chipped Blade",family:"blade",quantity:1,selectedQuantity:1,unitPrice:8,eligibility:"eligible",reason:null}),
    Object.freeze({selectionID:"sell-blade",kind:"gear",identity:"pointed-1",name:"Pointed Blade",family:"blade",quantity:1,selectedQuantity:1,unitPrice:null,eligibility:"cannotAct",reason:"Worn by Mara"}),
    Object.freeze({selectionID:"sell-unknown",kind:"item",identity:"keep-11",name:"Unknown item",family:"keepsake",quantity:1,selectedQuantity:1,unitPrice:null,eligibility:"cannotAct",reason:"Identify before selling"}),
    Object.freeze({selectionID:"sell-locked",kind:"gear",identity:"boots-9",name:"Field Boots",family:"boots",quantity:1,selectedQuantity:1,unitPrice:null,eligibility:"cannotAct",reason:"Locked · Keep"})
  ])
});

const exactKeys=(value,keys,label)=>{if(!value||typeof value!=="object"||Array.isArray(value)||JSON.stringify(Object.keys(value).sort())!==JSON.stringify([...keys].sort()))throw new Error(`invalid-${label}-fields`);};
const stockLine=line=>{exactKeys(line,["lineID","kind","identity","name","family","quantity","unitPrice","known"],"stock-line");if(!line.lineID||!line.identity||!line.name||!Number.isInteger(line.quantity)||line.quantity<0||!Number.isInteger(line.unitPrice)||line.unitPrice<1||line.known!==true)throw new Error("invalid-stock-line");return line;};
const holdingLine=line=>{exactKeys(line,["selectionID","kind","identity","name","family","quantity","selectedQuantity","unitPrice","eligibility","reason"],"holding-line");if(!line.selectionID||!line.identity||!line.name||!Number.isInteger(line.quantity)||line.quantity<1||!Number.isInteger(line.selectedQuantity)||line.selectedQuantity<1||line.selectedQuantity>line.quantity||!["eligible","cannotAct"].includes(line.eligibility))throw new Error("invalid-holding-line");if(line.eligibility==="eligible"&&(!Number.isInteger(line.unitPrice)||line.unitPrice<1||line.reason!==null))throw new Error("invalid-eligible-holding");if(line.eligibility==="cannotAct"&&(line.unitPrice!==null||typeof line.reason!=="string"||!line.reason))throw new Error("invalid-ineligible-holding");return line;};

export function resolveTradingPost(request){
  exactKeys(request,["mode","wallet","stockState","line","quantity"],"trading-post-request");
  const {mode,wallet,stockState,line,quantity}=request;
  if(!Number.isInteger(wallet)||wallet<0||!["ready","awaitingRefresh"].includes(stockState)||!Number.isInteger(quantity)||quantity<1)throw new Error("invalid-trading-post-request");
  if(mode==="buy"){
    if(stockState!=="ready")return Object.freeze({mode,state:"cannotAct",title:"Stock awaiting expedition return",reason:"Selling is still available",mutationAllowed:false});
    const item=stockLine(line);if(quantity>item.quantity)return Object.freeze({mode,state:"cannotAct",title:item.name,reason:`Only ${item.quantity} remaining`,mutationAllowed:false});
    const total=quantity*item.unitPrice;if(total>wallet)return Object.freeze({mode,state:"cannotAct",title:item.name,reason:`Need ${total-wallet} more gold`,mutationAllowed:false});
    return Object.freeze({mode,state:"preview",title:item.name,quantity,unitPrice:item.unitPrice,total,walletBefore:wallet,walletAfter:wallet-total,remainingBefore:item.quantity,remainingAfter:item.quantity-quantity,mutationAllowed:false,confirmAction:"Confirm buy"});
  }
  if(mode==="sell"){
    const item=holdingLine(line);if(item.eligibility!=="eligible")return Object.freeze({mode,state:"cannotAct",title:item.name,reason:item.reason,mutationAllowed:false});
    if(quantity>item.selectedQuantity)return Object.freeze({mode,state:"cannotAct",title:item.name,reason:`Only ${item.selectedQuantity} selected`,mutationAllowed:false});
    const total=quantity*item.unitPrice;return Object.freeze({mode,state:"preview",title:item.name,quantity,unitPrice:item.unitPrice,total,walletBefore:wallet,walletAfter:wallet+total,remainingBefore:item.quantity,remainingAfter:item.quantity-quantity,mutationAllowed:false,confirmAction:"Confirm sale"});
  }
  throw new Error(`unknown-trading-mode:${mode}`);
}

export function proposedTradingPostResult(preview){if(!preview||preview.state!=="preview"||preview.mutationAllowed!==false)throw new Error("invalid-trading-preview");return Object.freeze({...preview,state:"proposedResult",mutationAllowed:false,result:preview.mode==="buy"?`${preview.quantity} added to Resource Pool`:`${preview.quantity} removed · ${preview.total} Gold Coins received`});}
export function cancelTradingPostPreview(preview){if(!preview||preview.state!=="preview"||preview.mutationAllowed!==false)throw new Error("invalid-trading-preview");return Object.freeze({state:"cancelled",wallet:preview.walletBefore,remaining:preview.remainingBefore,mutationAllowed:false,result:"No changes"});}
export function tradingStockSnapshotHash({refresh,stock}){if(!refresh||!Array.isArray(stock))throw new Error("invalid-trading-stock-snapshot");return hash(canonicalJSON({refresh,stock}));}

export function authoredResourceSellPrice(id){const item=resourceCatalogue.find(entry=>entry.id===id);if(!item)throw new Error(`unknown-resource-family:${id}`);const bands={rubble:"staple",clay:"staple",ore:"staple",salt:"staple",fiber:"staple",timber:"staple",pulp:"staple",resin:"staple",copper:"uncommon",quartz:"uncommon",obsidian:"uncommon",sulfur:"uncommon",toxin:"uncommon",spore:"uncommon",reagent:"uncommon",silver:"rare",mercury:"rare",ichor:"rare",rift_glass:"rare",gold:"precious",adamant:"precious",essence_raw:null,mote:null};const band=bands[id];return band?Object.freeze({band,sell:tradeBands[band].sell,buy:tradeBands[band].buy}):Object.freeze({band:"nontradeable",sell:null,buy:null});}
