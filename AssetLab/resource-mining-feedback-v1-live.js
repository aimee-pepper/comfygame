import {
  committedHarvestGroup, motionContract, motionSample, proofFixtures,
} from "./src/resource-mining-feedback-v1.js";

const exactIDs = new Set([
  "rubble","clay","ore","copper","silver","gold","quartz","obsidian","salt","sulfur","mercury","adamant",
  "fiber","timber","pulp","resin","toxin","spore","reagent","ichor","rift_glass","essence_raw","mote",
]);
const names = {ore:"Iron Ore", timber:"Timber", resin:"Resin", quartz:"Quartz"};
const phone = document.querySelector("#live-phone"), satchel = document.querySelector("#live-satchel");
const layer = document.querySelector("#particle-layer"), receipt = document.querySelector("#live-receipt");
let selected = "M01", animationFrame = 0;
const iconPath = id => `integration/resource-sprites-v1/field/${id}.png`;

function groupFor(key) {
  const fixture = proofFixtures[key];
  return fixture.batch ? committedHarvestGroup(fixture.batch, exactIDs) : null;
}

function renderSatchel(key) {
  satchel.replaceChildren();
  for (const [id, amount] of Object.entries(proofFixtures[key].counts)) {
    const entry = document.createElement("span");
    entry.className = "satchel-entry"; entry.dataset.resource = id;
    const img = document.createElement("img"); img.src = iconPath(id); img.alt = "";
    const count = document.createElement("span"); count.textContent = String(amount);
    entry.append(img, count); satchel.append(entry);
  }
  document.querySelector(".place-pane small").textContent = proofFixtures[key].batch?.orderedNarrations?.[0] ?? "";
  const group = groupFor(key);
  const rows = [
    ["batch", group?.batchID ?? "none"],
    ["subjects", group?.subjects.map(x => `${names[x.resourceID] ?? x.resourceID} ×${x.amount}`).join(" → ") || "none"],
    ["count", "already committed at frame 1"],
    ["completion", "travelling copy removed; no mutation"],
  ];
  receipt.replaceChildren(...rows.flatMap(([term, value]) => {
    const dt = document.createElement("dt"), dd = document.createElement("dd");
    dt.textContent = term; dd.textContent = value; return [dt, dd];
  }));
}

function replay() {
  cancelAnimationFrame(animationFrame); layer.replaceChildren();
  document.querySelectorAll(".satchel-entry").forEach(node => node.classList.remove("ack"));
  const group = groupFor(selected); if (!group?.subjects.length) return;
  const source = {x:184,y:300};
  const particles = group.subjects.map(subject => {
    const node = document.createElement("span"); node.className = "reward-particle";
    const img = document.createElement("img"); img.src = iconPath(subject.resourceID); img.alt = "";
    const amount = document.createElement("b"); amount.textContent = `×${subject.amount}`;
    node.append(img, amount); layer.append(node); return {subject,node,img};
  });
  const start = performance.now();
  const frame = now => {
    const groupProgress = Math.max(0, Math.min(1, (now - start) / (motionContract.durationMS + (particles.length - 1) * motionContract.orderedSubjectStaggerMS)));
    particles.forEach(({subject,node,img}, index) => {
      const target = document.querySelector(`.satchel-entry[data-resource="${subject.resourceID}"] img`);
      if (!target) { node.remove(); return; }
      const phoneRect = phone.getBoundingClientRect(), targetRect = target.getBoundingClientRect();
      const destination = {x:targetRect.left-phoneRect.left+4,y:targetRect.top-phoneRect.top+4};
      const sample = motionSample({source,destination,groupProgress,subjectIndex:index,subjectCount:particles.length});
      node.style.transform = `translate(${sample.x-4}px,${sample.y-4}px)`;
      node.style.opacity = String(sample.opacity); img.style.transform = `scale(${sample.scale})`;
      if (sample.acknowledged) target.closest(".satchel-entry")?.classList.add("ack");
    });
    if (groupProgress < 1) animationFrame = requestAnimationFrame(frame);
    else setTimeout(() => layer.replaceChildren(), 80);
  };
  animationFrame = requestAnimationFrame(frame);
}

document.querySelectorAll("[data-scenario]").forEach(button => button.addEventListener("click", () => {
  selected = button.dataset.scenario; phone.dataset.proof = selected;
  document.querySelectorAll("[data-scenario]").forEach(node => node.classList.toggle("is-selected", node === button));
  renderSatchel(selected); replay();
}));
document.querySelector("#replay").addEventListener("click", replay);
document.querySelector('[data-scenario="M01"]').classList.add("is-selected"); renderSatchel(selected); replay();

const coverage = [
  ["M01","primary yield","one exact Ore subject + exact amount"],
  ["M02","primary + secondary","ordered Timber then Resin; one transaction"],
  ["M03","repeated same ID","one Ore subject with summed ×5"],
  ["M04","depleted final pull","one committed Quartz subject; exhaustion adds none"],
  ["M05","refused / stale / busy","zero subjects and zero reward implication"],
  ["M06","two valid batches","FIFO; duplicate batchID never replays"],
  ["M07","commit timing","toolbar final at start and unchanged at end"],
  ["M08","presentation ownership","Dismiss/expiry advances FIFO; leaving World clears all; gameplay untouched"],
  ["M09","cold relaunch","persisted count; no animation"],
  ["M10","missing identity","subject omitted; no substitute art"],
];
document.querySelector("#fixture-census").innerHTML = `<table><thead><tr><th>State</th><th>Truth</th><th>Proof</th></tr></thead><tbody>${coverage.map(row=>`<tr>${row.map(cell=>`<td>${cell}</td>`).join("")}</tr>`).join("")}</tbody></table>`;
