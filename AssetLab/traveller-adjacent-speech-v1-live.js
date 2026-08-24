import {bubblePlacement, bubbleVisualTokens, proofCensus} from "./src/traveller-adjacent-speech-v1.js";

const receipt = await fetch("integration/traveller-adjacent-speech-v1/source-receipt.json").then(response => response.json());
const rows = new Map(receipt.rows.map(row => [row.travellerID, row]));
const phone = document.getElementById("live-phone"), stage = document.getElementById("map-stage");
const bubble = document.getElementById("bubble"), bubbleCopy = document.getElementById("bubble-copy");
const people = document.getElementById("map-people"), liveReceipt = document.getElementById("live-receipt");

const scenarios = {
  T01: {current:"mara", queue:[], player:{x:184,y:304}, people:[{id:"mara",x:184,y:240,direction:"north"}], statement:"accepted step · newly cardinal · full/revealed/intact"},
  T07: {current:"mara", queue:["tovin","oda","noll"], player:{x:184,y:288}, people:[{id:"mara",x:184,y:232,direction:"north"},{id:"tovin",x:240,y:288,direction:"east"},{id:"oda",x:184,y:344,direction:"south"},{id:"noll",x:128,y:288,direction:"west"}], statement:"four newly adjacent · N/E/S/W FIFO"},
  T13O:{current:"oda",queue:[],player:{x:80,y:112},people:[{id:"oda",x:80,y:76,direction:"north"}],statement:"top-edge placement · complete Oda line"},
  T13T:{current:"tovin",queue:[],player:{x:316,y:278},people:[{id:"tovin",x:316,y:230,direction:"north"}],statement:"side-edge placement · complete Tovin line"},
  T05:{current:null,queue:[],player:{x:184,y:288},people:[],statement:"fringe/remembered/hidden/crumbled → no bubble and no traveller disclosure"},
};
let selected="T01", activeQueue=[];

function personNode({id,x,y,dim=false}, party=false){
  const img=document.createElement("img");
  img.className=`map-person${party?" party":""}`; img.src=`artifacts/traveller-adjacent-speech-v1/sprites/${party?"binder":id}-map.png`;
  img.style.left=`${x-16}px`;img.style.top=`${y-16}px`;if(dim)img.style.opacity=".28";
  return img;
}

function placeBubble(id, anchor){
  if(!id){bubble.className="speech-bubble is-hidden";return;}
  const row=rows.get(id);bubbleCopy.textContent=row.text;
  bubble.className="speech-bubble";bubble.style.width=`${bubbleVisualTokens.maxWidth}px`;
  bubble.style.visibility="hidden";bubble.style.display="block";
  const height=bubble.getBoundingClientRect().height;
  const placement=bubblePlacement({anchorX:anchor.x,anchorY:anchor.y,bubbleWidth:bubbleVisualTokens.maxWidth,bubbleHeight:height,stageWidth:stage.clientWidth,mapTop:8,mapBottom:420,blockedRects:[{x:anchor.x-18,y:anchor.y-18,width:36,height:36}]});
  bubble.style.left=`${placement.x}px`;bubble.style.top=`${placement.y}px`;bubble.style.setProperty("--tail-x",`${placement.tailX}px`);bubble.dataset.tail=placement.tailDirection;bubble.style.visibility="visible";
  bubble.classList.add("is-entering");
}

function receiptDefinition(scenario){
  const current=scenario.current?rows.get(scenario.current):null, pairs=[
    ["proof",selected],["result",scenario.statement],["current",current?`${current.travellerID} · ${current.sourceKey}`:"none"],
    ["queue",scenario.queue.length?scenario.queue.join(" → "):"empty"],["receipt",receipt.effectiveMeetingCorpusFingerprint],["mutation","none · hit-test transparent"],
  ];
  liveReceipt.replaceChildren(...pairs.flatMap(([term,value])=>{const dt=document.createElement("dt"),dd=document.createElement("dd");dt.textContent=term;dd.textContent=value;return[dt,dd]}));
}

function render(scenarioID){
  selected=scenarioID;const scenario=structuredClone(scenarios[scenarioID]);activeQueue=[...(scenario.current?[scenario.current]:[]),...scenario.queue];
  phone.dataset.proof=scenarioID;document.querySelectorAll("[data-scenario]").forEach(button=>button.classList.toggle("is-selected",button.dataset.scenario===scenarioID));
  people.replaceChildren(personNode({...scenario.player,id:"binder"},true),...scenario.people.map(person=>personNode(person)));
  const currentPerson=scenario.people.find(person=>person.id===scenario.current);placeBubble(scenario.current,currentPerson??scenario.player);receiptDefinition(scenario);
}

document.querySelectorAll("[data-scenario]").forEach(button=>button.addEventListener("click",()=>render(button.dataset.scenario)));
document.getElementById("replay").addEventListener("click",()=>render(selected));
document.getElementById("advance").addEventListener("click",()=>{
  if(selected!=="T07"||activeQueue.length===0)return;activeQueue.shift();const scenario=structuredClone(scenarios.T07);scenario.current=activeQueue[0]??null;scenario.queue=activeQueue.slice(1);const anchor=scenario.people.find(person=>person.id===scenario.current)??scenario.player;placeBubble(scenario.current,anchor);receiptDefinition(scenario);
});

const table=document.createElement("table"),head=document.createElement("thead"),headRow=document.createElement("tr");for(const label of ["ID","Closed proof"]){const th=document.createElement("th");th.textContent=label;headRow.append(th)}head.append(headRow);const body=document.createElement("tbody");for(const row of proofCensus){const tr=document.createElement("tr"),id=document.createElement("td"),statement=document.createElement("td");id.textContent=row.id;statement.textContent=row.statement;tr.append(id,statement);body.append(tr)}table.append(head,body);document.getElementById("fixture-census").append(table);
render("T01");
