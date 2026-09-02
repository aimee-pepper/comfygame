import {makeCandidateReceipt, splashInventory} from "./world-splash-five-layer-inventory-v1.js";

const inventoryRoot = document.querySelector("#inventory");
const coverageCount = document.querySelector("#coverage-count");
const status = document.querySelector("#receipt-status");

function detailBlock(label, value) {
  const block = document.createElement("section");
  block.className = "detail-block";
  const heading = document.createElement("h4");
  heading.textContent = label;
  block.append(heading);
  if (Array.isArray(value)) {
    const list = document.createElement("ul");
    for (const item of value) {
      const entry = document.createElement("li");
      entry.textContent = item;
      list.append(entry);
    }
    block.append(list);
  } else if (value && typeof value === "object") {
    const list = document.createElement("dl");
    for (const [key, item] of Object.entries(value)) {
      const term = document.createElement("dt");
      term.textContent = key.replace(/([A-Z])/g, " $1");
      const description = document.createElement("dd");
      description.textContent = item;
      list.append(term, description);
    }
    block.append(list);
  } else {
    const copy = document.createElement("p");
    copy.textContent = value;
    block.append(copy);
  }
  return block;
}

for (const layer of splashInventory.layers) {
  const section = document.createElement("section");
  section.className = `layer layer-${layer.motion}`;
  section.dataset.layerId = layer.id;
  const heading = document.createElement("header");
  heading.className = "layer-heading";
  const title = document.createElement("h2");
  title.textContent = layer.name;
  const motion = document.createElement("span");
  motion.textContent = layer.motionLabel;
  heading.append(title, motion);
  section.append(heading);

  for (const item of layer.rows) {
    const details = document.createElement("details");
    details.className = "asset-row";
    details.dataset.assetId = item.id;
    const summary = document.createElement("summary");
    const text = document.createElement("span");
    text.className = "summary-text";
    const name = document.createElement("strong");
    name.textContent = item.name;
    const description = document.createElement("span");
    description.textContent = item.description;
    text.append(name, description);
    summary.append(text);
    details.append(summary);

    const expanded = document.createElement("div");
    expanded.className = "expanded-detail";
    expanded.append(
      detailBlock("Source field", item.sourceFields),
      detailBlock("Dimensions / overscan", item.dimensionsOverscan),
      detailBlock("Variants", item.variants),
      detailBlock("Sharing / reuse", item.sharingReuse),
      detailBlock("Transparency / edges", item.transparencyEdges),
      detailBlock("Completion status", item.completionStatus),
    );
    details.append(expanded);
    section.append(details);
  }
  inventoryRoot.append(section);
}

const rowCount = splashInventory.layers.reduce((sum, layer) => sum + layer.rows.length, 0);
coverageCount.textContent = `${splashInventory.layers.length} layers · ${rowCount} required asset families`;

async function receiptText() {
  return `${JSON.stringify(await makeCandidateReceipt(), null, 2)}\n`;
}

document.querySelector("#copy-receipt").addEventListener("click", async () => {
  await navigator.clipboard.writeText(await receiptText());
  status.textContent = "Candidate receipt copied. No approval or art is implied.";
});

document.querySelector("#download-receipt").addEventListener("click", async () => {
  const blob = new Blob([await receiptText()], {type: "application/json"});
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = "world-splash-five-layer-inventory-candidate-receipt.json";
  link.click();
  URL.revokeObjectURL(link.href);
  status.textContent = "Candidate receipt downloaded. Final artwork is still unsupplied.";
});

document.querySelector("#collapse-all").addEventListener("click", () => {
  document.querySelectorAll("details[open]").forEach(detail => detail.removeAttribute("open"));
  status.textContent = "All asset rows collapsed.";
});

window.__SPLASH01__ = Object.freeze({inventory: splashInventory, makeCandidateReceipt});

