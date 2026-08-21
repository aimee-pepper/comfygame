const data = await fetch("./generated/wiki-data.json").then(response => {
  if (!response.ok) throw new Error("Generated wiki data is unavailable. Run npm run build.");
  return response.json();
});

const navItems = [
  ["overview", "Overview"], ["core-loop", "Core Loop"], ["world-writing", "World Writing"],
  ["exploration", "Exploration"], ["combat", "Combat"], ["people", "People"],
  ["village-buildings", "Village & Buildings"], ["resources-crafting", "Resources & Crafting"],
  ["items", "Items"], ["roadmap", "Roadmap"], ["history", "Decisions / History"],
  ["asset-gallery", "Asset Gallery"]
];

const authorityLinks = {
  "core-loop": "docs/core-loop-causal-presentation-plan-current.md",
  "world-writing": "docs/world-pages-templates-dictionary-current.md",
  exploration: "docs/world-look-and-control-occlusion-current.md",
  combat: "docs/combat-progression-current.md",
  people: "docs/roster-coherence-audit-current.md",
  "village-buildings": "docs/home-house-and-village-current.md",
  "resources-crafting": "docs/crafting-intuition-and-quality-review-current.md",
  items: "Sources/Content/Data/items.json",
  roadmap: "Sources/Content/Data/playability-roadmap.json",
  history: "docs/current-design-index.md",
  "asset-gallery": "docs/asset-production-output-contract-current.md"
};

const escapeHTML = value => String(value ?? "").replace(/[&<>'"]/g, character => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;" })[character]);
const titleCase = value => String(value).replace(/[-_]/g, " ").replace(/\b\w/g, letter => letter.toUpperCase());
const badge = value => `<span class="badge ${escapeHTML(String(value).toLowerCase().replace(/[^a-z]+/g, "-"))}">${escapeHTML(value)}</span>`;
const hashLink = (route, label) => `<a href="#/${route}">${escapeHTML(label)}</a>`;

function provenance(record) {
  const p = record.provenance;
  return `<div class="provenance"><strong>Source receipt</strong><br>${p.sourcePaths.map(escapeHTML).join(" · ")}<br>${p.stableID ? `Stable ID: ${escapeHTML(p.stableID)} · ` : ""}Disposition: ${escapeHTML(p.disposition)}<br>Generated at source hash: ${escapeHTML(p.generatedAtSourceHash)}</div>`;
}

function layout(route, content) {
  const nav = navItems.map(([id, label]) => `<a class="${route === id ? "active" : ""}" href="#/${id}">${label}</a>`).join("");
  return `<div class="shell">
    <aside class="sidebar">
      <div class="brand"><div class="brand-mark">B</div><div><strong>Bookbinder</strong><small>Internal source wiki</small></div></div>
      <label for="wiki-search">Search facts</label>
      <input class="search" id="wiki-search" type="search" placeholder="Station, person, rune…" autocomplete="off">
      <div class="search-results" id="search-results" hidden></div>
      <nav class="nav" aria-label="Wiki sections">${nav}</nav>
    </aside>
    <main class="main">${content}</main>
  </div>`;
}

function header(kicker, title, lede) {
  return `<div class="topline"><div><div class="kicker">${escapeHTML(kicker)}</div><h1>${escapeHTML(title)}</h1><p class="lede">${escapeHTML(lede)}</p></div><div class="stamp">Source ${data.generatedAtSourceHash.slice(0, 12)}</div></div>`;
}

function overview() {
  const cards = [
    ["core-loop", "Core Loop", "The current causal route from writing through return."],
    ["village-buildings", `${data.counts.stations} live station records`, "The first complete vertical slice, with honest lifecycle and upgrade gaps."],
    ["people", `${data.counts.travellers} authored people`, "Stable identities and current source dispositions."],
    ["roadmap", `${data.counts.roadmap} roadmap receipts`, "Operational status without silently promoting provisional work."],
    ["asset-gallery", "Asset evidence", "Accepted work only; missing art stays visibly missing."]
  ];
  return header("Private · generated", "Bookbinder field index", "A browsable view of current repository truth. Facts retain their source, stable identity, disposition, and exact source hash.") +
    `<div class="grid">${cards.map(([route, title, text]) => `<a class="card" href="#/${route}"><h3>${escapeHTML(title)}</h3><p>${escapeHTML(text)}</p></a>`).join("")}</div>
    <h2>Truth boundary</h2><div class="card"><p>Current pages prefer registered <code>*-current.md</code> authorities. Decision logs are retained under History, but never replace current facts. Purple labels indicate open, paused, or provisional material.</p><p>Authority: <code>docs/current-design-index.md</code></p></div>`;
}

function authorityPage(route, title, lede) {
  const source = authorityLinks[route];
  const authority = data.authorities.find(item => item.path === source);
  return header("Authority route", title, lede) + `<div class="card"><h3>Current source</h3><p><code>${escapeHTML(source)}</code></p>${authority ? `${badge(authority.status)}${provenance(authority)}` : `<p class="empty">This route is registered, but its current authority has not been extracted into a vertical slice yet.</p>`}</div>`;
}

function village() {
  return header("Complete first slice", "Village & Buildings", "Every live station catalogue entry, enriched only by the current lifecycle and Binder House authorities.") +
    `<div class="grid">${data.stations.map(station => `<a class="card" href="#/station/${station.slug}"><h3>${escapeHTML(station.name)}</h3>${badge(station.disposition)}${badge(station.lifecycle)}<p>${escapeHTML(station.zone)}</p><p>${escapeHTML(station.blurb)}</p></a>`).join("")}</div>`;
}

function stationDetail(slug) {
  const station = data.stations.find(item => item.slug === slug);
  if (!station) return notFound();
  const cost = station.buildCost.length ? `<div class="cost">${station.buildCost.map(part => `<span>${escapeHTML(part.quantity)} ${escapeHTML(titleCase(part.id))}</span>`).join("")}</div>` : "No construction charge in the live catalogue.";
  return header("Live station", station.name, station.blurb) +
    `<div class="facts">
      <dl class="fact"><dt>Stable ID</dt><dd>${escapeHTML(station.id)}</dd></dl>
      <dl class="fact"><dt>Zone</dt><dd>${escapeHTML(station.zone)}</dd></dl>
      <dl class="fact"><dt>Lifecycle</dt><dd>${escapeHTML(station.lifecycle)}</dd></dl>
      <dl class="fact"><dt>Keeper / builder</dt><dd>${escapeHTML(station.keeper ?? "None authored")}</dd></dl>
      <dl class="fact"><dt>Catalogue maxTier</dt><dd>${escapeHTML(station.catalogueMaxTier)}</dd></dl>
      <dl class="fact"><dt>Disposition</dt><dd>${escapeHTML(station.disposition)}</dd></dl>
    </div>
    <h2>Construction</h2><div class="card">${cost}${station.buildBlurb ? `<p>${escapeHTML(station.buildBlurb)}</p>` : ""}</div>
    <h2>Upgrade authority</h2><div class="card">${badge("incomplete")}<p>${escapeHTML(station.upgradeNote)}</p></div>
    <h2>Sprite evidence</h2><div class="sprite-slots"><div class="sprite-slot">Built sprite<br>not registered</div><div class="sprite-slot">Improved sprite<br>not registered</div></div>
    ${provenance(station)}<p>${hashLink("village-buildings", "← All stations")}</p>`;
}

function people() {
  return header("Authored catalogue", "People", "Stable traveller identities from the live content catalogue.") + `<div class="grid">${data.travellers.map(person => `<article class="card"><h3>${escapeHTML(person.name)}</h3>${badge(person.disposition)}<p>${escapeHTML(person.summary)}</p>${provenance(person)}</article>`).join("")}</div>`;
}

function resources() {
  return header("Authored catalogue", "Resources & Crafting", "Live resource identities. Crafting decisions remain visibly provisional where the roadmap says so.") + `<div class="grid">${data.resources.map(item => `<article class="card"><h3>${escapeHTML(item.name)}</h3>${badge(item.disposition)}<p>${escapeHTML(item.summary)}</p></article>`).join("")}</div>`;
}

function items() {
  return header("Authored catalogue", "Items", "Live item identities from the source catalogue.") + `<div class="grid">${data.items.map(item => `<article class="card"><h3>${escapeHTML(item.name)}</h3>${badge(item.disposition)}<p>${escapeHTML(item.summary)}</p></article>`).join("")}</div>`;
}

function roadmap() {
  return header("Operational board", "Roadmap", "Current statuses remain operational facts, including explicit holds and provisional work.") + `<div class="table-wrap"><table><thead><tr><th>Item</th><th>Status</th><th>Workstream</th></tr></thead><tbody>${data.roadmap.map(item => `<tr><td><strong>${escapeHTML(item.name)}</strong><br><small>${escapeHTML(item.id)}</small></td><td>${badge(item.status)}</td><td>${escapeHTML(item.workstream)}</td></tr>`).join("")}</tbody></table></div>`;
}

function history() {
  return header("Separated archive", "Decisions / History", "Historical records remain discoverable without overriding current authorities.") + `<h2>Current authority registry</h2><div class="grid">${data.authorities.slice(0, 18).map(item => `<article class="card"><h3>${escapeHTML(item.title)}</h3>${badge(item.status)}<p><code>${escapeHTML(item.path)}</code></p></article>`).join("")}</div><h2>Historical records</h2><div class="card"><p>${data.history.length} archived or session-decision documents are registered as history.</p><ul>${data.history.slice(0, 30).map(item => `<li><code>${escapeHTML(item.path)}</code></li>`).join("")}</ul></div>`;
}

function assets() {
  return header("Evidence only", "Asset Gallery", "Only committed and accepted art may appear as final. Review evidence must be labelled; missing art stays missing.") + `<div class="empty"><strong>No accepted art registered for this slice.</strong><p>${escapeHTML(data.assetGallery.note)}</p></div>`;
}

function notFound() { return header("404", "Page not found", "This internal route is not registered."); }

function render() {
  const route = location.hash.replace(/^#\/?/, "") || "overview";
  const [root, detail] = route.split("/");
  let content;
  if (root === "overview") content = overview();
  else if (root === "village-buildings") content = village();
  else if (root === "station") content = stationDetail(detail);
  else if (root === "people") content = people();
  else if (root === "resources-crafting") content = resources();
  else if (root === "items") content = items();
  else if (root === "roadmap") content = roadmap();
  else if (root === "history") content = history();
  else if (root === "asset-gallery") content = assets();
  else if (navItems.some(([id]) => id === root)) content = authorityPage(root, navItems.find(([id]) => id === root)[1], `Current authority index for ${navItems.find(([id]) => id === root)[1].toLowerCase()}.`);
  else content = notFound();
  document.querySelector("#app").innerHTML = layout(root, content);
  const input = document.querySelector("#wiki-search");
  const results = document.querySelector("#search-results");
  input.addEventListener("input", () => {
    const query = input.value.trim().toLowerCase();
    if (!query) { results.hidden = true; results.innerHTML = ""; return; }
    const matches = data.search.filter(item => `${item.name} ${item.id} ${item.summary} ${item.type}`.toLowerCase().includes(query)).slice(0, 12);
    results.innerHTML = matches.length ? matches.map(item => `<a href="#/${item.route}"><strong>${escapeHTML(item.name)}</strong><small>${escapeHTML(item.type)} · ${escapeHTML(item.id)} · ${escapeHTML(item.disposition)}</small></a>`).join("") : `<a href="#/${root}">No matching generated fact</a>`;
    results.hidden = false;
  });
}

addEventListener("hashchange", render);
render();
