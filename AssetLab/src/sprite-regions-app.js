import { blendPoint } from "./sprite-rig-core.js";

const $ = (selector) => document.querySelector(selector);
const editor = $("#editor-canvas"), preview = $("#preview-canvas");
const ectx = editor.getContext("2d"), pctx = preview.getContext("2d", { alpha: true });

const palette = ["#d96c75", "#deaa63", "#e6d86c", "#6fbd8b", "#5ca8bd", "#8d80c7", "#bd72a7"];
let state = {
  version: "bookbinder.sprite-regions/v0.1",
  width: 48, height: 64, zoom: 10, tool: "pen",
  regions: [{ id: crypto.randomUUID(), name: "hips", color: palette[0], closed: false, nodes: [] }],
  anchors: [], bones: [], poses: [{ id: crypto.randomUUID(), name: "Bind pose", rotations: {} }],
  activeRegionId: null, selectedAnchorId: null, selectedBoneId: null, activePoseId: null, selection: null
};
state.activeRegionId = state.regions[0].id;
state.activePoseId = state.poses[0].id;
let history = [], drag = null;
let referenceImage = null;

const activeRegion = () => state.regions.find(r => r.id === state.activeRegionId);
const selectedAnchor = () => state.anchors.find(a => a.id === state.selectedAnchorId);
const selectedBone = () => state.bones.find(b => b.id === state.selectedBoneId);
const activePose = () => state.poses.find(p => p.id === state.activePoseId);
const clamp = (n, min, max) => Math.max(min, Math.min(max, n));
const round = n => Math.round(n * 1000) / 1000;

function snapshot() {
  history.push(JSON.stringify(state));
  if (history.length > 80) history.shift();
}

function pointFromEvent(event) {
  const rect = editor.getBoundingClientRect();
  return {
    x: clamp((event.clientX - rect.left) * editor.width / rect.width / state.zoom, 0, state.width),
    y: clamp((event.clientY - rect.top) * editor.height / rect.height / state.zoom, 0, state.height)
  };
}

function nodePath(region, transform = p => p) {
  const path = new Path2D(), nodes = region.nodes;
  if (!nodes.length) return path;
  let p = transform(nodes[0], nodes[0]); path.moveTo(p.x, p.y);
  for (let i = 1; i < nodes.length; i++) {
    const a = nodes[i - 1], b = nodes[i];
    const ao = transform({ x: a.outX, y: a.outY }, a), bi = transform({ x: b.inX, y: b.inY }, b), bp = transform(b, b);
    path.bezierCurveTo(ao.x, ao.y, bi.x, bi.y, bp.x, bp.y);
  }
  if (region.closed && nodes.length > 2) {
    const a = nodes.at(-1), b = nodes[0];
    const ao = transform({ x: a.outX, y: a.outY }, a), bi = transform({ x: b.inX, y: b.inY }, b), bp = transform(b, b);
    path.bezierCurveTo(ao.x, ao.y, bi.x, bi.y, bp.x, bp.y);
    path.closePath();
  }
  return path;
}

function rotationFor(boneId) { return Number(activePose()?.rotations?.[boneId] ?? 0); }
function boneTransform(boneId, seen = new Set()) {
  const bone = state.bones.find(b => b.id === boneId);
  if (!bone || seen.has(boneId)) return p => ({ x: p.x, y: p.y });
  seen.add(boneId);
  const parentTransform = bone.parentId ? boneTransform(bone.parentId, seen) : p => ({ x: p.x, y: p.y });
  const pivot = parentTransform(bone.start), angle = rotationFor(boneId) * Math.PI / 180, cos = Math.cos(angle), sin = Math.sin(angle);
  return point => {
    const inherited = parentTransform(point), dx = inherited.x - pivot.x, dy = inherited.y - pivot.y;
    return { x: pivot.x + dx * cos - dy * sin, y: pivot.y + dx * sin + dy * cos };
  };
}
function weightedPoint(point, weights) {
  const validIds = new Set(state.bones.map(bone => bone.id));
  return blendPoint(point, weights, (boneId, source) => boneTransform(boneId)(source), validIds);
}
function transformForRegion(region) {
  const rigid = region.boneId ? boneTransform(region.boneId) : p => ({ x: p.x, y: p.y });
  return (point, node) => Object.keys(node?.weights ?? {}).length ? weightedPoint(point, node.weights) : rigid(point);
}

function drawEditor() {
  editor.width = state.width * state.zoom;
  editor.height = state.height * state.zoom;
  ectx.setTransform(state.zoom, 0, 0, state.zoom, 0, 0);
  ectx.clearRect(0, 0, state.width, state.height);
  ectx.imageSmoothingEnabled = false;
  if (referenceImage) {
    ectx.save(); ectx.globalAlpha = Number($("#reference-opacity").value) / 100;
    ectx.drawImage(referenceImage, 0, 0, state.width, state.height); ectx.restore();
  }

  for (const region of state.regions) {
    const path = nodePath(region, transformForRegion(region));
    ectx.save();
    ectx.globalAlpha = region.id === state.activeRegionId ? .62 : .38;
    ectx.fillStyle = region.color;
    if (region.closed) ectx.fill(path);
    ectx.globalAlpha = region.id === state.activeRegionId ? 1 : .55;
    ectx.strokeStyle = region.color;
    ectx.lineWidth = 1 / state.zoom * 2;
    ectx.stroke(path);
    ectx.restore();
    if ($("#show-vectors").checked) drawBoundaryKinds(region);
  }

  if ($("#show-grid").checked) {
    ectx.save(); ectx.beginPath(); ectx.lineWidth = 1 / state.zoom;
    for (let x = 0; x <= state.width; x++) { ectx.moveTo(x, 0); ectx.lineTo(x, state.height); }
    for (let y = 0; y <= state.height; y++) { ectx.moveTo(0, y); ectx.lineTo(state.width, y); }
    ectx.strokeStyle = "#756f6540"; ectx.stroke(); ectx.restore();
  }

  if ($("#show-vectors").checked) drawVectorControls();
  drawSkeleton();
  drawAnchors();
}

function drawSkeleton() {
  for (const bone of state.bones) {
    const transform = boneTransform(bone.id), start = transform(bone.start), end = transform(bone.end), selected = bone.id === state.selectedBoneId;
    ectx.save(); ectx.lineCap = "round"; ectx.strokeStyle = selected ? "#fff4bb" : "#62d2cf"; ectx.fillStyle = "#171614"; ectx.lineWidth = (selected ? 4 : 3) / state.zoom;
    ectx.beginPath(); ectx.moveTo(start.x, start.y); ectx.lineTo(end.x, end.y); ectx.stroke();
    ectx.beginPath(); ectx.arc(start.x, start.y, .45, 0, Math.PI * 2); ectx.fill(); ectx.stroke();
    ectx.beginPath(); ectx.arc(end.x, end.y, .3, 0, Math.PI * 2); ectx.fill(); ectx.stroke(); ectx.restore();
  }
}

function drawBoundaryKinds(region) {
  const nodes = region.nodes;
  if (nodes.length < 2) return;
  const count = region.closed ? nodes.length : nodes.length - 1;
  for (let i = 0; i < count; i++) {
    const a = nodes[i], b = nodes[(i + 1) % nodes.length];
    if (a.boundary?.type !== "seam") continue;
    ectx.save(); ectx.beginPath(); ectx.moveTo(a.x, a.y);
    ectx.bezierCurveTo(a.outX, a.outY, b.inX, b.inY, b.x, b.y);
    ectx.strokeStyle = "#f6d06f"; ectx.lineWidth = 3 / state.zoom; ectx.setLineDash([.65, .45]); ectx.stroke(); ectx.restore();
  }
}

function drawVectorControls() {
  const region = activeRegion();
  if (!region) return;
  for (let i = 0; i < region.nodes.length; i++) {
    const n = region.nodes[i], selected = state.selection?.node === i;
    ectx.save(); ectx.lineWidth = 1 / state.zoom; ectx.strokeStyle = "#ece5d5b8";
    ectx.beginPath(); ectx.moveTo(n.inX, n.inY); ectx.lineTo(n.x, n.y); ectx.lineTo(n.outX, n.outY); ectx.stroke();
    for (const [kind, x, y] of [["in", n.inX, n.inY], ["out", n.outX, n.outY]]) {
      ectx.fillStyle = state.selection?.node === i && state.selection?.kind === kind ? "#fff" : "#171614";
      ectx.strokeStyle = "#eee8dc"; ectx.beginPath(); ectx.rect(x - .28, y - .28, .56, .56); ectx.fill(); ectx.stroke();
    }
    ectx.fillStyle = selected ? "#fff" : region.color; ectx.strokeStyle = "#171614";
    ectx.beginPath(); ectx.arc(n.x, n.y, .42, 0, Math.PI * 2); ectx.fill(); ectx.stroke(); ectx.restore();
  }
}

function drawAnchors() {
  for (const anchor of state.anchors) {
    const selected = anchor.id === state.selectedAnchorId;
    ectx.save(); ectx.translate(anchor.x, anchor.y); ectx.rotate(Math.PI / 4);
    ectx.fillStyle = selected ? "#fff" : "#171614"; ectx.strokeStyle = "#f3cf78"; ectx.lineWidth = 2 / state.zoom;
    ectx.fillRect(-.5, -.5, 1, 1); ectx.strokeRect(-.5, -.5, 1, 1); ectx.restore();
    ectx.save(); ectx.font = `${9 / state.zoom}px ui-monospace`; ectx.fillStyle = "#171614";
    ectx.fillText(anchor.name, anchor.x + .8, anchor.y - .6); ectx.restore();
  }
}

function rasterize() {
  preview.width = state.width; preview.height = state.height;
  pctx.clearRect(0, 0, state.width, state.height);
  pctx.imageSmoothingEnabled = false;
  for (const region of state.regions) {
    if (!region.closed) continue;
    pctx.fillStyle = region.color;
    pctx.fill(nodePath(region, transformForRegion(region)));
  }
  const scale = Number($("#preview-scale").value);
  preview.style.width = `${state.width * scale}px`;
  preview.style.height = `${state.height * scale}px`;
}

function contract() {
  return {
    version: state.version,
    canvas: { width: state.width, height: state.height, unit: "pixel" },
    regions: state.regions.map(r => ({
      id: r.id, name: r.name, color: r.color, closed: r.closed, boneId: r.boneId ?? null,
      nodes: r.nodes.map(n => Object.fromEntries(Object.entries(n).map(([k,v]) => [k, typeof v === "number" ? round(v) : v])))
    })),
    anchors: state.anchors.map(a => ({ ...a, x: round(a.x), y: round(a.y) })),
    skeleton: state.bones.map(b => ({ ...b, start: { x: round(b.start.x), y: round(b.start.y) }, end: { x: round(b.end.x), y: round(b.end.y) } })),
    poses: state.poses.map(p => ({ id: p.id, name: p.name, duration: 0, tracks: Object.fromEntries(Object.entries(p.rotations).map(([boneId, rotation]) => [boneId, [{ time: 0, rotation }]])) }))
  };
}

function renderLists() {
  $("#region-list").replaceChildren(...state.regions.map(region => {
    const button = document.createElement("button"); button.className = `entity-row${region.id === state.activeRegionId ? " active" : ""}`;
    button.innerHTML = `<span class="entity-swatch"></span><span></span><span class="entity-meta"></span>`;
    button.children[0].style.background = region.color; button.children[1].textContent = region.name;
    button.children[2].textContent = `${region.nodes.length} pt${region.nodes.length === 1 ? "" : "s"}`;
    button.onclick = () => { state.activeRegionId = region.id; state.selection = null; sync(); };
    return button;
  }));
  const region = activeRegion();
  $("#region-name").value = region?.name ?? ""; $("#region-color").value = region?.color ?? "#000000";
  const neighbor = $("#boundary-neighbor");
  const previousNeighbor = neighbor.value;
  neighbor.replaceChildren(new Option("None", ""), ...state.regions.filter(r => r.id !== state.activeRegionId).map(r => new Option(r.name, r.id)));
  const selectedNode = region?.nodes[state.selection?.node];
  const boundary = selectedNode?.boundary ?? { type: "outer", neighborRegionId: "" };
  $("#boundary-type").value = boundary.type;
  neighbor.value = boundary.neighborRegionId ?? previousNeighbor ?? "";
  $("#boundary-type").disabled = !selectedNode;
  neighbor.disabled = !selectedNode || boundary.type !== "seam";

  $("#anchor-list").replaceChildren(...state.anchors.map(anchor => {
    const button = document.createElement("button"); button.className = `entity-row${anchor.id === state.selectedAnchorId ? " active" : ""}`;
    button.innerHTML = `<span>◆</span><span></span><span class="entity-meta"></span>`;
    button.children[1].textContent = anchor.name; button.children[2].textContent = `${anchor.regionIds.length} link${anchor.regionIds.length === 1 ? "" : "s"}`;
    button.onclick = () => { state.selectedAnchorId = anchor.id; sync(); };
    return button;
  }));

  $("#bone-list").replaceChildren(...state.bones.map(bone => {
    const button = document.createElement("button"); button.className = `entity-row${bone.id === state.selectedBoneId ? " active" : ""}`;
    button.innerHTML = `<span>●</span><span></span><span class="entity-meta"></span>`; button.children[1].textContent = bone.name;
    button.children[2].textContent = state.regions.filter(r => r.boneId === bone.id).length ? `${state.regions.filter(r => r.boneId === bone.id).length} bound` : "unbound";
    button.onclick = () => { state.selectedBoneId = bone.id; sync(); }; return button;
  }));
  const parentSelect = $("#bone-parent");
  parentSelect.replaceChildren(new Option("None · root", ""), ...state.bones.filter(b => b.id !== state.selectedBoneId).map(b => new Option(b.name, b.id)));
  parentSelect.value = selectedBone()?.parentId ?? ""; parentSelect.disabled = !selectedBone();
  const angle = selectedBone() ? rotationFor(selectedBone().id) : 0; $("#bone-angle").value = angle; $("#bone-angle").disabled = !selectedBone(); $("#bone-angle-output").value = `${angle}°`;
  const weightedNode = activeRegion()?.nodes[state.selection?.node], pointWeight = selectedBone() && weightedNode ? Math.round((weightedNode.weights?.[selectedBone().id] ?? 0) * 100) : 0;
  $("#point-weight").value = pointWeight; $("#point-weight").disabled = !selectedBone() || !weightedNode; $("#point-weight-output").value = `${pointWeight}%`;

  const poseSelect = $("#pose-select"); poseSelect.replaceChildren(...state.poses.map(p => new Option(p.name, p.id))); poseSelect.value = state.activePoseId;
  $("#pose-name").value = activePose()?.name ?? "";
}

function sync(message) {
  drawEditor(); rasterize(); renderLists();
  $("#grid-width").value = state.width; $("#grid-height").value = state.height; $("#zoom").value = state.zoom;
  $("#region-count").textContent = `${state.regions.length} region${state.regions.length === 1 ? "" : "s"}`;
  $("#anchor-count").textContent = `${state.anchors.length} anchor${state.anchors.length === 1 ? "" : "s"}`;
  $("#path-status").textContent = activeRegion()?.closed ? "Closed path" : "Open path";
  $("#json-preview").value = JSON.stringify(contract(), null, 2);
  if (message) $("#status").textContent = message;
  localStorage.setItem("bookbinder.sprite-regions.autosave", JSON.stringify(contract()));
}

function setTool(tool) {
  state.tool = tool; drag = null;
  document.querySelectorAll("[data-tool]").forEach(button => {
    const active = button.dataset.tool === tool; button.classList.toggle("tool-active", active); button.setAttribute("aria-pressed", active);
  });
  $("#status").textContent = tool === "pen" ? "Click to place points; drag while placing to create curves." : tool === "select" ? "Drag points or square Bézier handles." : tool === "anchor" ? "Click to place a named joint anchor." : "Drag from one joint to the next to create a bone.";
}

function hitTest(point) {
  const region = activeRegion(), radius = .85;
  if (state.tool === "anchor") {
    const anchor = state.anchors.findLast(a => Math.hypot(a.x - point.x, a.y - point.y) < radius);
    return anchor ? { type: "anchor", id: anchor.id } : null;
  }
  if (state.tool === "bone") {
    const bone = [...state.bones].reverse().find(b => { const t = boneTransform(b.id), s = t(b.start), e = t(b.end); return Math.min(Math.hypot(s.x-point.x,s.y-point.y),Math.hypot(e.x-point.x,e.y-point.y)) < .9; });
    return bone ? { type: "bone", id: bone.id } : null;
  }
  if (!region) return null;
  for (let i = region.nodes.length - 1; i >= 0; i--) {
    const n = region.nodes[i];
    for (const kind of ["in", "out"]) if (Math.hypot(n[`${kind}X`] - point.x, n[`${kind}Y`] - point.y) < radius) return { type: "node", node: i, kind };
    if (Math.hypot(n.x - point.x, n.y - point.y) < radius) return { type: "node", node: i, kind: "point" };
  }
  return null;
}

editor.addEventListener("pointerdown", event => {
  const point = pointFromEvent(event), region = activeRegion(), hit = hitTest(point);
  editor.setPointerCapture(event.pointerId);
  if (state.tool === "pen") {
    if (!region || region.closed) return;
    if (region.nodes.length > 2 && Math.hypot(region.nodes[0].x - point.x, region.nodes[0].y - point.y) < .9) { snapshot(); region.closed = true; sync("Path closed. Raster preview updated."); return; }
    snapshot();
    const node = { x: point.x, y: point.y, inX: point.x, inY: point.y, outX: point.x, outY: point.y, weights: {}, boundary: { id: crypto.randomUUID(), type: "outer", neighborRegionId: "" } };
    region.nodes.push(node); state.selection = { node: region.nodes.length - 1, kind: "point" };
    drag = { type: "new-node", node: region.nodes.length - 1, origin: point }; sync();
  } else if (state.tool === "select" && hit?.type === "node") {
    snapshot(); state.selection = { node: hit.node, kind: hit.kind }; drag = hit; sync();
  } else if (state.tool === "anchor") {
    if (hit?.type === "anchor") { state.selectedAnchorId = hit.id; snapshot(); drag = hit; sync(); return; }
    snapshot(); const anchor = { id: crypto.randomUUID(), name: $("#anchor-name").value.trim() || `anchor-${state.anchors.length + 1}`, x: point.x, y: point.y, regionIds: region ? [region.id] : [] };
    state.anchors.push(anchor); state.selectedAnchorId = anchor.id; drag = { type: "anchor", id: anchor.id }; sync("Anchor placed. Activate another region and link it if this is a shared seam.");
  } else if (state.tool === "bone") {
    if (hit?.type === "bone") { state.selectedBoneId = hit.id; sync(); return; }
    snapshot(); const bone = { id: crypto.randomUUID(), name: $("#bone-name").value.trim() || `bone-${state.bones.length + 1}`, parentId: state.selectedBoneId || null, start: { ...point }, end: { ...point } };
    state.bones.push(bone); state.selectedBoneId = bone.id; drag = { type: "new-bone", id: bone.id }; sync();
  }
});

editor.addEventListener("pointermove", event => {
  const point = pointFromEvent(event); $("#cursor-readout").textContent = `x ${point.x.toFixed(1)} · y ${point.y.toFixed(1)}`;
  if (!drag) return;
  if (drag.type === "new-node") {
    const n = activeRegion().nodes[drag.node], dx = point.x - drag.origin.x, dy = point.y - drag.origin.y;
    n.outX = n.x + dx; n.outY = n.y + dy; n.inX = n.x - dx; n.inY = n.y - dy;
  } else if (drag.type === "node") {
    const n = activeRegion().nodes[drag.node];
    if (drag.kind === "point") { const dx = point.x - n.x, dy = point.y - n.y; n.x = point.x; n.y = point.y; n.inX += dx; n.inY += dy; n.outX += dx; n.outY += dy; }
    else { n[`${drag.kind}X`] = point.x; n[`${drag.kind}Y`] = point.y; }
  } else if (drag.type === "anchor") { const a = state.anchors.find(item => item.id === drag.id); if (a) { a.x = point.x; a.y = point.y; } }
  else if (drag.type === "new-bone") { const b = state.bones.find(item => item.id === drag.id); if (b) b.end = { ...point }; }
  drawEditor(); rasterize();
});
editor.addEventListener("pointerup", () => { drag = null; sync(); });

document.querySelectorAll("[data-tool]").forEach(button => button.onclick = () => setTool(button.dataset.tool));
$("#add-region").onclick = () => { snapshot(); const index = state.regions.length; const region = { id: crypto.randomUUID(), name: `region-${index + 1}`, color: palette[index % palette.length], closed: false, nodes: [] }; state.regions.push(region); state.activeRegionId = region.id; setTool("pen"); sync("New region ready. Draw its boundary."); };
$("#delete-region").onclick = () => { if (!activeRegion() || state.regions.length === 1) return; snapshot(); const id = state.activeRegionId; state.regions = state.regions.filter(r => r.id !== id); state.anchors.forEach(a => a.regionIds = a.regionIds.filter(rid => rid !== id)); state.activeRegionId = state.regions[0].id; sync("Region deleted."); };
$("#region-name").oninput = event => { activeRegion().name = event.target.value; sync(); };
$("#region-color").oninput = event => { activeRegion().color = event.target.value; sync(); };
$("#boundary-type").onchange = event => { const n = activeRegion()?.nodes[state.selection?.node]; if (!n) return; snapshot(); n.boundary ??= { id: crypto.randomUUID(), type: "outer", neighborRegionId: "" }; n.boundary.type = event.target.value; if (n.boundary.type === "outer") n.boundary.neighborRegionId = ""; sync(n.boundary.type === "seam" ? "This curve is now a shared seam. Choose its neighboring zone." : "This curve is now an outside silhouette edge."); };
$("#boundary-neighbor").onchange = event => { const n = activeRegion()?.nodes[state.selection?.node]; if (!n) return; snapshot(); n.boundary ??= { id: crypto.randomUUID(), type: "seam", neighborRegionId: "" }; n.boundary.type = "seam"; n.boundary.neighborRegionId = event.target.value; sync("Shared seam linked to both color zones."); };
$("#close-path").onclick = () => { const r = activeRegion(); if (r?.nodes.length > 2) { snapshot(); r.closed = true; sync("Path closed. Raster preview updated."); } };
$("#link-anchor").onclick = () => { const a = selectedAnchor(), r = activeRegion(); if (!a || !r) return; snapshot(); if (!a.regionIds.includes(r.id)) a.regionIds.push(r.id); sync(`Linked ${a.name} to ${r.name}.`); };
$("#delete-anchor").onclick = () => { if (!selectedAnchor()) return; snapshot(); state.anchors = state.anchors.filter(a => a.id !== state.selectedAnchorId); state.selectedAnchorId = null; sync("Anchor deleted."); };
$("#bind-region").onclick = () => { const bone = selectedBone(), region = activeRegion(); if (!bone || !region) return; snapshot(); region.boneId = bone.id; sync(`${region.name} now follows ${bone.name}.`); };
$("#point-weight").oninput = event => { const bone = selectedBone(), node = activeRegion()?.nodes[state.selection?.node]; if (!bone || !node) return; node.weights ??= {}; const value = Number(event.target.value) / 100; if (value) node.weights[bone.id] = value; else delete node.weights[bone.id]; $("#point-weight-output").value = `${event.target.value}%`; drawEditor(); rasterize(); };
$("#point-weight").onchange = () => sync("Point weight saved. All nonzero influences are normalized during deformation.");
$("#auto-weight-region").onclick = () => { const region = activeRegion(); if (!region || !state.bones.length) return; snapshot(); for (const node of region.nodes) { const nearest = state.bones.map(bone => { const dx = bone.end.x - bone.start.x, dy = bone.end.y - bone.start.y, length2 = dx*dx + dy*dy || 1, t = clamp(((node.x-bone.start.x)*dx+(node.y-bone.start.y)*dy)/length2,0,1), px = bone.start.x+t*dx, py = bone.start.y+t*dy; return { id: bone.id, distance: Math.hypot(node.x-px,node.y-py) }; }).sort((a,b) => a.distance-b.distance).slice(0,2); const influences = nearest.map(item => 1 / Math.max(.25, item.distance)); const total = influences.reduce((a,b) => a+b,0); node.weights = Object.fromEntries(nearest.map((item,index) => [item.id, influences[index]/total])); } region.boneId = null; sync(`${region.name} was blended across its two nearest bones.`); };
$("#delete-bone").onclick = () => { const bone = selectedBone(); if (!bone) return; snapshot(); state.regions.forEach(r => { if (r.boneId === bone.id) r.boneId = null; }); state.bones.forEach(b => { if (b.parentId === bone.id) b.parentId = bone.parentId ?? null; }); state.bones = state.bones.filter(b => b.id !== bone.id); state.poses.forEach(p => delete p.rotations[bone.id]); state.selectedBoneId = null; sync("Bone deleted; bound regions were released."); };
$("#bone-parent").onchange = event => { const bone = selectedBone(); if (!bone) return; snapshot(); bone.parentId = event.target.value || null; sync("Bone hierarchy updated."); };
$("#bone-angle").oninput = event => { const bone = selectedBone(), pose = activePose(); if (!bone || !pose) return; pose.rotations[bone.id] = Number(event.target.value); $("#bone-angle-output").value = `${event.target.value}°`; drawEditor(); rasterize(); };
$("#bone-angle").onchange = () => sync("Pose angle saved as a one-keyframe animation track.");
$("#add-pose").onclick = () => { snapshot(); const pose = { id: crypto.randomUUID(), name: `Pose ${state.poses.length + 1}`, rotations: {} }; state.poses.push(pose); state.activePoseId = pose.id; sync("New pose created."); };
$("#pose-select").onchange = event => { state.activePoseId = event.target.value; sync("Pose loaded."); };
$("#pose-name").oninput = event => { if (activePose()) activePose().name = event.target.value; sync(); };
$("#duplicate-pose").onclick = () => { if (!activePose()) return; snapshot(); const pose = { id: crypto.randomUUID(), name: `${activePose().name} copy`, rotations: { ...activePose().rotations } }; state.poses.push(pose); state.activePoseId = pose.id; sync("Pose duplicated."); };
$("#reset-pose").onclick = () => { if (!activePose()) return; snapshot(); activePose().rotations = {}; sync("Pose angles reset."); };
$("#undo").onclick = () => { const previous = history.pop(); if (!previous) return; state = JSON.parse(previous); sync("Undid last change."); };
$("#show-grid").onchange = drawEditor; $("#show-vectors").onchange = drawEditor; $("#preview-scale").onchange = rasterize;
$("#reference-opacity").oninput = drawEditor;
$("#clear-reference").onclick = () => { referenceImage = null; $("#reference-image").value = ""; drawEditor(); $("#status").textContent = "Reference underlay cleared."; };
$("#reference-image").onchange = event => { const file = event.target.files[0]; if (!file) return; const image = new Image(); image.onload = () => { snapshot(); referenceImage = image; state.width = clamp(image.naturalWidth, 8, 256); state.height = clamp(image.naturalHeight, 8, 256); sync(`Reference loaded at ${state.width}×${state.height}. It stays local and is not included in exports.`); URL.revokeObjectURL(image.src); }; image.src = URL.createObjectURL(file); };
for (const [id, key] of [["#grid-width", "width"], ["#grid-height", "height"], ["#zoom", "zoom"]]) $(id).onchange = event => { snapshot(); state[key] = Number(event.target.value); sync(); };

function download(name, blob) { const a = document.createElement("a"); a.href = URL.createObjectURL(blob); a.download = name; a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 1000); }
$("#export-json").onclick = () => download("sprite-regions.json", new Blob([JSON.stringify(contract(), null, 2)], { type: "application/json" }));
$("#export-png").onclick = () => preview.toBlob(blob => download("sprite-regions.png", blob), "image/png");
$("#import-json").onchange = async event => { try { const data = JSON.parse(await event.target.files[0].text()); snapshot(); state.width = data.canvas.width; state.height = data.canvas.height; state.regions = data.regions; state.anchors = data.anchors ?? []; state.bones = data.skeleton ?? []; state.poses = (data.poses ?? []).map(p => ({ id: p.id, name: p.name, rotations: Object.fromEntries(Object.entries(p.tracks ?? {}).map(([boneId, keys]) => [boneId, keys[0]?.rotation ?? 0])) })); if (!state.poses.length) state.poses = [{ id: crypto.randomUUID(), name: "Bind pose", rotations: {} }]; state.activePoseId = state.poses[0].id; state.activeRegionId = state.regions[0]?.id; state.selectedAnchorId = null; state.selectedBoneId = null; state.selection = null; sync("Imported region and rig contract."); } catch { $("#status").textContent = "That file is not a valid sprite-region contract."; } event.target.value = ""; };
$("#new-document").onclick = () => { snapshot(); const region = { id: crypto.randomUUID(), name: "hips", color: palette[0], closed: false, nodes: [] }, pose = { id: crypto.randomUUID(), name: "Bind pose", rotations: {} }; state.regions = [region]; state.anchors = []; state.bones = []; state.poses = [pose]; state.activeRegionId = region.id; state.activePoseId = pose.id; state.selectedAnchorId = null; state.selectedBoneId = null; sync("New document ready."); };
window.addEventListener("keydown", event => { if (/INPUT|TEXTAREA|SELECT/.test(event.target.tagName)) return; if (event.key.toLowerCase() === "p") setTool("pen"); if (event.key.toLowerCase() === "v") setTool("select"); if (event.key.toLowerCase() === "a") setTool("anchor"); if (event.key.toLowerCase() === "b") setTool("bone"); if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "z") { event.preventDefault(); $("#undo").click(); } });

try {
  const saved = JSON.parse(localStorage.getItem("bookbinder.sprite-regions.autosave"));
  if (saved?.version && saved.regions?.length) { state.width = saved.canvas.width; state.height = saved.canvas.height; state.regions = saved.regions; state.anchors = saved.anchors ?? []; state.bones = saved.skeleton ?? []; state.poses = (saved.poses ?? []).map(p => ({ id: p.id, name: p.name, rotations: Object.fromEntries(Object.entries(p.tracks ?? {}).map(([boneId, keys]) => [boneId, keys[0]?.rotation ?? 0])) })); if (!state.poses.length) state.poses = [{ id: crypto.randomUUID(), name: "Bind pose", rotations: {} }]; state.activeRegionId = state.regions[0].id; state.activePoseId = state.poses[0].id; }
} catch {}
sync();
