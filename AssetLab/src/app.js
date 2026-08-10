import {
  defaults, traitDefinitions, cloneDescriptor, normalizeDescriptor, creatureCommands,
  terrainCommands, floraCommands, renderCommands, canonicalJSON, hash, rng,
  compatibilityWarnings, populationDescriptors, presets, anatomySummary,
  rebalanceAllocation, commandBounds, safeFilePart
} from "./generator.js";
import { creatureLiveContract } from "./live-contract.js";

const VERSIONS = Object.freeze({
  descriptorSchemaVersion: 4,
  grammarVersion: "creature-grammar-0.3.0",
  compositorVersion: "rect-compositor-0.2.0",
  assetLibraryVersion: "procedural-proof-0.2.0",
  renderProfileVersion: "profiles-0.2.0"
});
const ALLOCATIONS = {
  cyan: ["cyan", "magenta", "yellow"], magenta: ["cyan", "magenta", "yellow"], yellow: ["cyan", "magenta", "yellow"],
  vision: ["vision", "mechano", "chemo", "thermo"], mechano: ["vision", "mechano", "chemo", "thermo"],
  chemo: ["vision", "mechano", "chemo", "thermo"], thermo: ["vision", "mechano", "chemo", "thermo"],
  emanationLight:["emanationLight","emanationHeat","emanationCaustic"], emanationHeat:["emanationLight","emanationHeat","emanationCaustic"], emanationCaustic:["emanationLight","emanationHeat","emanationCaustic"]
};
const byId = id => document.getElementById(id);
const canvases = {
  world: byId("world"), fight: byId("fight"), flora: byId("flora"),
  soil: byId("terrain-soil"), water: byId("terrain-water"), stone: byId("terrain-stone"),
  population: byId("population"), comparison: byId("comparison")
};
let descriptor = cloneDescriptor(defaults);
let pinnedDescriptor = null;
const locks = new Set();

function buildPresets() {
  for (const name of Object.keys(presets)) byId("preset").add(new Option(name, name));
}

function buildControls() {
  const host = byId("controls"); host.replaceChildren();
  let activeGroup = "";
  for (const def of traitDefinitions) {
    if (def.group !== activeGroup) {
      activeGroup = def.group;
      const heading = document.createElement("h3"); heading.className = "trait-group"; heading.textContent = activeGroup; host.append(heading);
    }
    const wrapper = document.createElement("div"); wrapper.className = "trait";
    const lock = document.createElement("input"); lock.type = "checkbox"; lock.className = "lock"; lock.id = `lock-${def.key}`;
    lock.title = `Lock ${def.label} while randomizing`; lock.setAttribute("aria-label", `Lock ${def.label} while randomizing`);
    lock.addEventListener("change", () => lock.checked ? locks.add(def.key) : locks.delete(def.key));
    const label = document.createElement("label"); label.textContent = def.label; label.htmlFor = `trait-${def.key}`;
    const input = def.options ? document.createElement("select") : document.createElement("input");
    input.id = `trait-${def.key}`; input.dataset.trait = def.key;
    if (def.options) {
      for (const option of def.options) input.add(new Option(typeof option === "boolean" ? (option ? "yes" : "no") : option, String(option)));
      if (def.options.some(option => typeof option === "boolean")) input.dataset.boolean = "true";
      wrapper.classList.add("select-trait"); wrapper.append(lock, label, input);
    } else {
      input.type = "range"; input.min = def.min; input.max = def.max; input.step = def.step ?? 1;
      const output = document.createElement("output"); output.className = "trait-output"; output.dataset.output = def.key; output.htmlFor = input.id;
      const head = document.createElement("div"); head.className = "trait-head"; head.append(lock, label, output); wrapper.append(head, input);
    }
    input.addEventListener("input", () => {
      const value = def.options ? (input.dataset.boolean === "true" ? input.value === "true" : input.value) : Number(input.value);
      if (ALLOCATIONS[def.key]) rebalanceAllocation(descriptor.traits, def.key, ALLOCATIONS[def.key], value);
      else descriptor.traits[def.key] = value;
      byId("preset").value = "";
      renderAll();
    });
    host.append(wrapper);
  }
}

function syncControls() {
  byId("species-seed").value = descriptor.speciesSeed;
  byId("specimen-seed").value = descriptor.specimenSeed;
  byId("reroll-species").disabled = byId("species-seed-lock").checked;
  byId("reroll-specimen").disabled = byId("specimen-seed-lock").checked;
  for (const def of traitDefinitions) {
    const input = document.querySelector(`[data-trait="${def.key}"]`); input.value = String(descriptor.traits[def.key]);
    const output = document.querySelector(`[data-output="${def.key}"]`); if (output) output.textContent = descriptor.traits[def.key];
  }
}

function draw(canvas, commands) { renderCommands(canvas.getContext("2d"), canvas.width, canvas.height, commands); }

function renderAll() {
  descriptor = normalizeDescriptor(descriptor); syncControls();
  const world = creatureCommands(descriptor, "world"), fight = creatureCommands(descriptor, "fight");
  draw(canvases.world, world); draw(canvases.fight, fight);
  draw(canvases.soil, terrainCommands("soil", descriptor.speciesSeed));
  draw(canvases.water, terrainCommands("water", descriptor.speciesSeed));
  draw(canvases.stone, terrainCommands("stone", descriptor.speciesSeed));
  draw(canvases.flora, floraCommands(descriptor));
  drawPopulation(); drawComparison(); drawWarnings(); drawDiagnostics(world, fight);
  byId("anatomy-summary").textContent = anatomySummary(descriptor);
  if (document.activeElement !== byId("json")) byId("json").value = JSON.stringify(descriptor, null, 2);
  byId("descriptor-hash").textContent = `descriptor ${hash(canonicalJSON(descriptor))}`;
  byId("world-hash").textContent = `pixels ${pixelHash(canvases.world)}`;
  byId("fight-hash").textContent = `pixels ${pixelHash(canvases.fight)}`;
  applyScale();
}

function applyScale() {
  const scale = Number(byId("scale").value);
  for (const canvas of Object.values(canvases).filter(canvas => ![canvases.population, canvases.comparison].includes(canvas))) {
    const ownScale = [canvases.world, canvases.fight].includes(canvas) ? scale : Math.max(4, scale);
    canvas.style.width = `${canvas.width * ownScale}px`; canvas.style.height = `${canvas.height * ownScale}px`;
  }
}

function randomize() {
  const random = rng(descriptor.speciesSeed ^ Date.now());
  for (const def of traitDefinitions) {
    if (locks.has(def.key)) continue;
    descriptor.traits[def.key] = def.options ? def.options[Math.floor(random() * def.options.length)] : def.min + Math.floor(random() * (def.max - def.min + 1));
  }
  if (!byId("species-seed-lock").checked) descriptor.speciesSeed = Math.floor(random() * 0xffffffff);
  byId("preset").value = ""; renderAll();
}

function drawPopulation() {
  const mode=byId("population-mode").value, canvas=canvases.population,context=canvas.getContext("2d"),cellW=32,cellH=24;
  context.clearRect(0,0,canvas.width,canvas.height); context.imageSmoothingEnabled=false;
  for(const [index,candidate] of populationDescriptors(descriptor,24,mode).entries()){
    const scratch=document.createElement("canvas");scratch.width=16;scratch.height=16;renderCommands(scratch.getContext("2d"),16,16,creatureCommands(candidate,"world"));
    const cellX=(index%6)*cellW,cellY=Math.floor(index/6)*cellH;context.fillStyle=index%2?"#27241f":"#211f1b";context.fillRect(cellX,cellY,cellW,cellH);context.drawImage(scratch,cellX+8,cellY+4);
  }
  byId("population-note").textContent=mode==="species"
    ? "One species, 24 specimen seeds. Mechanical anatomy stays fixed; only bounded cosmetic marks vary."
    : "Twenty-four species spanning every topology. This tests the breadth of the ecosystem grammar.";
}

function drawWarnings() {
  const host=byId("warnings");host.replaceChildren();
  for(const warning of compatibilityWarnings(descriptor)){const item=document.createElement("div");item.className="warning";item.textContent=warning;host.append(item);}
}

function drawComparison() {
  const canvas=canvases.comparison,context=canvas.getContext("2d");context.clearRect(0,0,canvas.width,canvas.height);context.imageSmoothingEnabled=false;
  context.fillStyle="#171614";context.fillRect(0,0,52,52);context.fillStyle="#211f1b";context.fillRect(52,0,52,52);
  const drawCandidate=(candidate,x)=>{if(!candidate)return;const scratch=document.createElement("canvas");scratch.width=48;scratch.height=48;renderCommands(scratch.getContext("2d"),48,48,creatureCommands(candidate,"fight"));context.drawImage(scratch,x+2,2);};
  drawCandidate(pinnedDescriptor,0);drawCandidate(descriptor,52);
  if(!pinnedDescriptor){context.fillStyle="#aaa397";context.font="3px monospace";context.fillText("PIN A CANDIDATE",7,27);}
}

function drawDiagnostics(world,fight){
  const deterministic=hash(world)===hash(creatureCommands(descriptor,"world"))&&hash(fight)===hash(creatureCommands(descriptor,"fight"));
  setDiagnostic("determinism",deterministic,deterministic?"repeat render hashes agree":"repeat render mismatch");
  const wb=commandBounds(world),fb=commandBounds(fight),bounded=wb.minX>=0&&wb.minY>=0&&wb.maxX<=16&&wb.maxY<=16&&fb.minX>=0&&fb.minY>=0&&fb.maxX<=48&&fb.maxY<=48;
  setDiagnostic("bounds",bounded,bounded?"both profiles inside canvas":"sprite geometry exceeds canvas");
  const colorTotal=descriptor.traits.cyan+descriptor.traits.magenta+descriptor.traits.yellow,senseTotal=descriptor.traits.vision+descriptor.traits.mechano+descriptor.traits.chemo+descriptor.traits.thermo,allocated=colorTotal===100&&senseTotal===100;
  setDiagnostic("allocation",allocated,`CMY ${colorTotal} · senses ${senseTotal}`);
}
function setDiagnostic(id,ok,text){byId(`${id}-dot`).className=`dot ${ok?"ok":"bad"}`;byId(`${id}-status`).textContent=text;}

function pixelHash(canvas){
  const bytes=canvas.getContext("2d").getImageData(0,0,canvas.width,canvas.height).data;let h=0x811c9dc5;
  for(const byte of bytes){h^=byte;h=Math.imul(h,0x01000193);}return(h>>>0).toString(16).padStart(8,"0");
}

function manifest(){
  const contract=creatureLiveContract(descriptor);
  return {manifestVersion:3,identityKind:"creature",logicalID:descriptor.logicalID,authoringDescriptor:descriptor,gameIdentity:contract.gameIdentity,renderHints:contract.renderHints,adapterDiagnostics:contract.adapterDiagnostics,pipelineVersions:VERSIONS,outputs:[
    {profile:"world",file:`${fileStem()}-world.png`,pixelWidth:16,pixelHeight:16,pivot:{x:8,y:8},pixelHash:pixelHash(canvases.world)},
    {profile:"fight",file:`${fileStem()}-fight.png`,pixelWidth:48,pixelHeight:48,pivot:{x:24,y:42},pixelHash:pixelHash(canvases.fight)}
  ]};
}
function fileStem(){return `${safeFilePart(descriptor.logicalID,"creature")}-s${descriptor.speciesSeed}-i${descriptor.specimenSeed}`;}

function download(name,blob){
  if(!blob){showStatus("Export failed: the browser returned no file.",true);return;}
  const link=document.createElement("a"),url=URL.createObjectURL(blob);link.href=url;link.download=safeFilePart(name,"asset");link.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
}
function downloadJSON(name,value){download(name,new Blob([JSON.stringify(value,null,2)],{type:"application/json"}));}
function exportPNG(profile){canvases[profile].toBlob(blob=>download(`${fileStem()}-${profile}.png`,blob),"image/png");}
function showStatus(message,isError=false){const status=byId("json-status");status.textContent=message;status.style.color=isError?"#e88c7c":"";}

function saveWorkspace(){
  try{localStorage.setItem("bookbinder.assetlab.workspace.v1",JSON.stringify({descriptor,pinnedDescriptor,locks:[...locks],speciesSeedLocked:byId("species-seed-lock").checked,specimenSeedLocked:byId("specimen-seed-lock").checked,populationMode:byId("population-mode").value,scale:byId("scale").value}));showStatus("Workspace saved in this browser.");}
  catch(error){showStatus(`Workspace save failed: ${error.message}`,true);}
}
function loadWorkspace(){
  try{const stored=localStorage.getItem("bookbinder.assetlab.workspace.v1");if(!stored){showStatus("No saved workspace found.",true);return;}const workspace=JSON.parse(stored);descriptor=normalizeDescriptor(workspace.descriptor);pinnedDescriptor=workspace.pinnedDescriptor?normalizeDescriptor(workspace.pinnedDescriptor):null;locks.clear();for(const key of workspace.locks??[])locks.add(key);document.querySelectorAll('[id^="lock-"]').forEach(input=>input.checked=locks.has(input.id.slice(5)));byId("species-seed-lock").checked=!!workspace.speciesSeedLocked;byId("specimen-seed-lock").checked=!!workspace.specimenSeedLocked;byId("population-mode").value=workspace.populationMode??"ecosystem";byId("scale").value=workspace.scale??"4";showStatus("Workspace loaded.");renderAll();}
  catch(error){showStatus(`Workspace load failed: ${error.message}`,true);}
}

buildControls();buildPresets();
byId("species-seed").addEventListener("input",event=>{descriptor.speciesSeed=Number(event.target.value);byId("preset").value="";renderAll();});
byId("specimen-seed").addEventListener("input",event=>{descriptor.specimenSeed=Number(event.target.value);renderAll();});
byId("species-seed-lock").addEventListener("change",renderAll);byId("specimen-seed-lock").addEventListener("change",renderAll);
byId("scale").addEventListener("change",applyScale);byId("population-mode").addEventListener("change",renderAll);byId("randomize").addEventListener("click",randomize);
byId("reroll-species").addEventListener("click",()=>{if(!byId("species-seed-lock").checked){descriptor.speciesSeed=Math.floor(Math.random()*0xffffffff);byId("preset").value="";renderAll();}});
byId("reroll-specimen").addEventListener("click",()=>{if(!byId("specimen-seed-lock").checked){descriptor.specimenSeed=Math.floor(Math.random()*0xffffffff);renderAll();}});
byId("preset").addEventListener("change",event=>{if(!event.target.value)return;descriptor.traits=cloneDescriptor({traits:presets[event.target.value]}).traits;descriptor=normalizeDescriptor(descriptor);renderAll();});
byId("pin-candidate").addEventListener("click",()=>{pinnedDescriptor=cloneDescriptor(descriptor);renderAll();});
byId("export-population").addEventListener("click",()=>canvases.population.toBlob(blob=>download(`${fileStem()}-${byId("population-mode").value}-population.png`,blob),"image/png"));
byId("reset").addEventListener("click",()=>{descriptor=cloneDescriptor(defaults);pinnedDescriptor=null;locks.clear();document.querySelectorAll(".lock").forEach(input=>input.checked=false);byId("preset").value="";renderAll();});
byId("apply-json").addEventListener("click",()=>{try{descriptor=normalizeDescriptor(JSON.parse(byId("json").value));byId("preset").value="";showStatus("Descriptor applied.");renderAll();}catch(error){showStatus(`Invalid JSON: ${error.message}`,true);}});
byId("copy-json").addEventListener("click",async()=>{try{await navigator.clipboard.writeText(JSON.stringify(descriptor,null,2));showStatus("Copied.");}catch(error){showStatus(`Copy failed: ${error.message}`,true);}});
byId("download-json").addEventListener("click",()=>downloadJSON(`${fileStem()}-identity.json`,descriptor));
byId("download-manifest").addEventListener("click",()=>downloadJSON(`${fileStem()}-manifest.json`,manifest()));
byId("save-workspace").addEventListener("click",saveWorkspace);byId("load-workspace").addEventListener("click",loadWorkspace);
byId("import-json").addEventListener("change",async event=>{try{const file=event.target.files?.[0];if(!file)return;descriptor=normalizeDescriptor(JSON.parse(await file.text()));byId("preset").value="";showStatus("Fixture imported.");renderAll();}catch(error){showStatus(`Import failed: ${error.message}`,true);}});
document.querySelectorAll("[data-export]").forEach(button=>button.addEventListener("click",()=>exportPNG(button.dataset.export)));
renderAll();
