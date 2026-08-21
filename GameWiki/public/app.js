import { resetRouteScroll } from "./route-scroll.js";

const data = await fetch("./generated/wiki-data.json").then(response => {
  if (!response.ok) throw new Error("Generated wiki data is unavailable. Run npm run build.");
  return response.json();
});

const navItems = [
  ["overview", "Overview"], ["core-loop", "Core Loop"], ["world-writing", "World Writing"],
  ["exploration", "Exploration"], ["combat", "Combat"], ["people", "People"],
  ["village-buildings", "Home & Village"], ["resources-crafting", "Resources & Crafting"],
  ["catalogue", "Catalogue"], ["roadmap", "Roadmap"], ["history", "Decisions / History"],
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
  catalogue: "Sources/Content/Data/items.json",
  roadmap: "Sources/Content/Data/playability-roadmap.json",
  history: "docs/current-design-index.md",
  "asset-gallery": "docs/asset-production-output-contract-current.md"
};

const escapeHTML = value => String(value ?? "").replace(/[&<>'"]/g, character => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;" })[character]);
const titleCase = value => String(value).replace(/([a-z])([A-Z])/g, "$1 $2").replace(/[-_]/g, " ").replace(/\b\w/g, letter => letter.toUpperCase());
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
    ["village-buildings", `${data.counts.stations} Home & Village destinations`, "Rooms, interfaces, shelves, progression surfaces, yard features, and village buildings—truthfully distinguished."],
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
  const kinds = [...new Set(data.stations.map(station => station.destinationKind))];
  return header("Complete first slice", "Home & Village destinations", "Every live destination catalogue entry, with rooms, interfaces, shelves, progression surfaces, yard features, removed compatibility routes, and actual village buildings kept distinct.") +
    `<p><label for="destination-kind-filter">Destination kind </label><select id="destination-kind-filter"><option value="all">All destinations</option>${kinds.map(kind => `<option value="${escapeHTML(kind)}">${escapeHTML(titleCase(kind))}</option>`).join("")}</select></p>` +
    `<div class="grid" id="destination-grid">${data.stations.map(station => `<a class="card" data-destination-kind="${escapeHTML(station.destinationKind)}" href="#/station/${station.slug}"><h3>${escapeHTML(station.name)}</h3>${badge(station.destinationKind)}${badge(station.disposition)}${station.zoneDisposition === "provisional" ? badge("zone provisional") : ""}<p>${escapeHTML(station.zone)}</p><p>${escapeHTML(station.blurb)}</p></a>`).join("")}</div>`;
}

function stationDetail(slug) {
  const station = data.stations.find(item => item.slug === slug);
  if (!station) return notFound();
  const cost = station.buildCost.length ? `<div class="cost">${station.buildCost.map(part => `<span>${escapeHTML(part.quantity)} ${escapeHTML(titleCase(part.id))}</span>`).join("")}</div>` : "No construction charge in the live catalogue.";
  const progression = station.forms.length ? `<h2>Built, Improved and Mastered</h2><div class="progression-grid">${station.forms.map(form => `<article class="card"><div>${form.authorityLabels.map(badge).join("")}</div><h3>${escapeHTML(titleCase(form.state))} · Tier ${form.tier}${form.name !== titleCase(form.state) ? ` — ${escapeHTML(form.name)}` : ""}</h3><p><strong>Capability:</strong> ${escapeHTML(form.capability)}</p><p><strong>Physical referent:</strong> ${escapeHTML(form.visualReferent)}</p></article>`).join("")}</div>` : station.progressionNote ? `<h2>Destination progression</h2><div class="card">${station.id === "constellation" ? badge("proposed / review-gated") : badge("authored presentation")}<p>${escapeHTML(station.progressionNote)}</p></div>` : "";
  const constellation = station.constellationProposal.length ? `<h2>Constellation proposal</h2><div class="grid">${station.constellationProposal.map(star => `<article class="card">${badge(star.status)}${badge(star.cluster)}<h3>${escapeHTML(star.name)}</h3><p><code>${escapeHTML(star.id)}</code> · ${escapeHTML(star.cost)}</p><p>${escapeHTML(star.permission)}</p><p><strong>Blocked while:</strong> ${escapeHTML(star.blocker)}</p></article>`).join("")}</div><p class="empty">The six mastery stars are proposed and review-gated, not implemented. Long Instruction remains the existing authored star.</p>` : "";
  const visualKey = station.visualKey ? `<h2>Production visual key</h2><div class="facts"><dl class="fact"><dt>Foundation clue</dt><dd>${escapeHTML(station.visualKey.foundation)}</dd></dl><dl class="fact"><dt>Built silhouette</dt><dd>${escapeHTML(station.visualKey.builtKey)}</dd></dl><dl class="fact"><dt>Materials / accents</dt><dd>${escapeHTML(station.visualKey.materials)}</dd></dl><dl class="fact"><dt>Protected continuity</dt><dd>${escapeHTML(station.visualKey.protectedFeatures)}</dd></dl><dl class="fact"><dt>Must not converge with</dt><dd>${escapeHTML(station.visualKey.exclusions)}</dd></dl></div>` : "";
  return header("Live station", station.name, station.blurb) +
    `<div class="facts">
      <dl class="fact"><dt>Stable ID</dt><dd>${escapeHTML(station.id)}</dd></dl>
      <dl class="fact"><dt>Destination kind</dt><dd>${escapeHTML(titleCase(station.destinationKind))}</dd></dl>
      <dl class="fact"><dt>Zone</dt><dd>${escapeHTML(station.zone)}</dd></dl>
      <dl class="fact"><dt>Lifecycle</dt><dd>${escapeHTML(station.lifecycle)}</dd></dl>
      <dl class="fact"><dt>Keeper / build authority</dt><dd>${escapeHTML(station.keeperAuthority)}</dd></dl>
      <dl class="fact"><dt>Catalogue maxTier</dt><dd>${escapeHTML(station.catalogueMaxTier)} · non-semantic legacy field</dd></dl>
      <dl class="fact"><dt>Disposition</dt><dd>${escapeHTML(station.disposition)}</dd></dl>
    </div>
    <h2>Construction</h2><div class="card">${cost}${station.buildBlurb ? `<p>${escapeHTML(station.buildBlurb)}</p>` : ""}</div>
    <h2>Upgrade authority</h2><div class="card">${badge(station.upgradeAuthorityStatus)}<p>${escapeHTML(station.upgradeNote)}</p>${station.upgradeAuthoritySourcePaths.length ? `<p><code>${station.upgradeAuthoritySourcePaths.map(escapeHTML).join(" · ")}</code></p>` : ""}</div>
    ${progression}${constellation}${visualKey}
    ${station.assetSlots.length ? `<h2>Stable asset slots</h2><div class="sprite-slots">${station.assetSlots.map(slot => `<div class="sprite-slot"><code>${escapeHTML(slot.key)}</code><br>${escapeHTML(slot.status)}</div>`).join("")}</div>` : ""}
    ${provenance(station)}<p>${hashLink("village-buildings", "← All destinations")}</p>`;
}

function people() {
  return header("Authored catalogue", "People", "Stable traveller identities from the live content catalogue.") + `<div class="grid">${data.travellers.map(person => `<article class="card"><h3>${escapeHTML(person.name)}</h3>${badge(person.disposition)}<p>${escapeHTML(person.summary)}</p>${provenance(person)}</article>`).join("")}</div>`;
}

function resources() {
  const world = data.resources.filter(item => item.domain === "worldResource");
  const currencies = data.resources.filter(item => item.domain === "currencyEssence");
  const resourceCards = records => `<div class="grid">${records.map(item => `<a class="card" href="#/resource/${item.slug}"><h3>${escapeHTML(item.name)}</h3>${badge(item.disposition)}${badge(item.tradeBand)}<p>${escapeHTML(item.summary)}</p></a>`).join("")}</div>`;
  const materialCards = records => `<div class="grid">${records.map(item => `<a class="card" href="#/creature-material/${item.slug}"><h3>${escapeHTML(titleCase(item.name))}</h3>${badge(item.status)}<p>${escapeHTML(item.summary)}</p><p><code>${escapeHTML(item.familyID)}</code></p></a>`).join("")}</div>`;
  return header("Source-partitioned catalogue", "Resources & Crafting", "World resources, creature materials and currencies remain separate. Live and proposed material models are never merged.")
    + `<h2>World Resources · live</h2>${resourceCards(world)}`
    + `<h2>Creature Materials · current live model</h2>${materialCards(data.creatureMaterials.filter(item => item.disposition === "live"))}`
    + `<h2>Creature Materials · designed, not yet live</h2><p class="empty">The ecology overhaul is current design authority, not implemented production state.</p>${materialCards(data.creatureMaterials.filter(item => item.disposition === "proposed"))}`
    + `<h2>Currencies & Essence</h2>${resourceCards(currencies)}`;
}

const catalogueKinds = { gear: "Gear", consumable: "Consumables", curio: "Curios", treasure: "Treasures", key: "Keys" };
const slotOrder = ["weapon", "offhand", "head", "armor", "hands", "feet", "tool", "keepsake"];

function itemCards(records) {
  return `<div class="grid">${records.map(item => {
    const weaponLine = item.gear?.slot === "weapon"
      ? `<p><strong>${escapeHTML(titleCase(item.gear.damage))}</strong> damage · ${escapeHTML(titleCase(item.gear.reach))} reach</p>`
      : "";
    return `<a class="card" href="#/item/${item.slug}"><h3>${escapeHTML(item.name)}</h3>${badge(item.rarity)}${badge(item.category)}${weaponLine}<p>${escapeHTML(item.summary)}</p></a>`;
  }).join("")}</div>`;
}

function catalogue(kind = null) {
  if (!kind) return header("Live source catalogue", "Catalogue", "Every live item belongs to one exact player-facing family; nothing is flattened into one undifferentiated grid.")
    + `<div class="grid">${Object.entries(catalogueKinds).map(([id, label]) => { const count = data.items.filter(item => item.category === id).length; const route = id === "gear" ? "gear" : id === "consumable" ? "consumables" : `${id}s`; return `<a class="card" href="#/catalogue/${route}"><h3>${label}</h3><p>${count} live entries</p></a>`; }).join("")}</div>`;
  const singular = kind === "consumables" ? "consumable" : kind.replace(/s$/, "");
  const records = data.items.filter(item => item.category === singular);
  if (singular === "gear") {
    return header("Live source catalogue", "Gear", "Gear is grouped by exact equipped slot; weapons additionally expose damage kind and reach.")
      + slotOrder.map(slot => { const group = records.filter(item => item.gear?.slot === slot); return `<h2>${slot === "armor" ? "Body / Armor" : titleCase(slot)} · ${group.length}</h2>${itemCards(group)}`; }).join("");
  }
  return header("Live source catalogue", catalogueKinds[singular], `${records.length} exact live ${catalogueKinds[singular].toLowerCase()} entries.`) + itemCards(records);
}

function itemDetail(slug) {
  const item = data.items.find(candidate => candidate.slug === slug);
  if (!item) return notFound();
  const authoredValue = value => value === undefined || value === null || value === "" ? "None authored in items.json" : Array.isArray(value) ? value.map(titleCase).join(" · ") : titleCase(value);
  const gear = item.gear ? `<h2>Gear rules</h2><div class="facts">
    <dl class="fact"><dt>Slot</dt><dd>${escapeHTML(authoredValue(item.gear.slot))}</dd></dl>
    <dl class="fact"><dt>Tier</dt><dd>${escapeHTML(authoredValue(item.gear.tier))}</dd></dl>
    <dl class="fact"><dt>Damage</dt><dd>${escapeHTML(authoredValue(item.gear.damage))}</dd></dl>
    <dl class="fact"><dt>Reach</dt><dd>${escapeHTML(authoredValue(item.gear.reach))}</dd></dl>
    <dl class="fact"><dt>Wards against</dt><dd>${escapeHTML(authoredValue(item.gear.wardsAgainst))}</dd></dl>
    <dl class="fact"><dt>Insulation</dt><dd>${escapeHTML(authoredValue(item.gear.insulation))}</dd></dl>
    <dl class="fact"><dt>Reactivity</dt><dd>${escapeHTML(authoredValue(item.gear.reactivity))}</dd></dl>
    <dl class="fact"><dt>Break rule</dt><dd>${escapeHTML(authoredValue(item.gear.breaks))}</dd></dl>
  </div>` : "";
  const consumable = item.consumable ? `<h2>Consumable rules</h2><div class="facts">${Object.entries(item.consumable).map(([key, value]) => `<dl class="fact"><dt>${escapeHTML(titleCase(key))}</dt><dd>${escapeHTML(value)}</dd></dl>`).join("")}</div>` : "";
  return header(`${titleCase(item.category)} · live`, item.name, item.summary) + `<div class="facts"><dl class="fact"><dt>Stable ID</dt><dd>${escapeHTML(item.id)}</dd></dl><dl class="fact"><dt>Kind</dt><dd>${escapeHTML(item.category)}</dd></dl><dl class="fact"><dt>Rarity</dt><dd>${escapeHTML(item.rarity)}</dd></dl><dl class="fact"><dt>Trading Post</dt><dd>${escapeHTML(item.tradingPostDisposition)}</dd></dl><dl class="fact"><dt>Recycler</dt><dd>${escapeHTML(item.recyclerDisposition)}</dd></dl></div>${gear}${consumable}${provenance(item)}<p>${hashLink("catalogue", "← Catalogue")}</p>`;
}

function resourceDetail(slug) {
  const item = data.resources.find(candidate => candidate.slug === slug);
  if (!item) return notFound();
  return header(`${titleCase(item.domain)} · live`, item.name, item.summary) + `<div class="facts"><dl class="fact"><dt>Stable ID</dt><dd>${escapeHTML(item.id)}</dd></dl><dl class="fact"><dt>Driven by</dt><dd>${escapeHTML(item.drivenBy)}</dd></dl><dl class="fact"><dt>Trade band</dt><dd>${escapeHTML(item.tradeBand)}</dd></dl><dl class="fact"><dt>Reality currency</dt><dd>${item.isRealityCurrency ? "Yes" : "No"}</dd></dl></div><h2>Requires</h2><div class="card"><p>${escapeHTML(item.requires.join(" · ") || "No hard generation requirement.")}</p></div><h2>Favours</h2><div class="card"><p>${escapeHTML(item.favours.join(" · ") || "No authored favour condition.")}</p></div><h2>Known live uses</h2><div class="card"><ul>${item.currentUses.map(use => `<li>${escapeHTML(use)}</li>`).join("")}</ul></div>${provenance(item)}<p>${hashLink("resources-crafting", "← Resources & Crafting")}</p>`;
}

function creatureMaterialDetail(slug) {
  const material = data.creatureMaterials.find(candidate => candidate.slug === slug);
  if (!material) return notFound();
  return header(`${material.disposition === "live" ? "Live transitional model" : "Settled design · not yet live"}`, titleCase(material.name), material.summary)
    + `<div class="facts"><dl class="fact"><dt>Stable family</dt><dd>${escapeHTML(material.familyID)}</dd></dl><dl class="fact"><dt>Implementation</dt><dd>${escapeHTML(material.status)}</dd></dl><dl class="fact"><dt>Legal roles</dt><dd>${escapeHTML(material.legalRoles)}</dd></dl><dl class="fact"><dt>Named contribution</dt><dd>${escapeHTML(material.contribution)}</dd></dl><dl class="fact"><dt>Restriction / trade-off</dt><dd>${escapeHTML(material.restriction)}</dd></dl><dl class="fact"><dt>Visual treatment</dt><dd>${escapeHTML(material.visualTreatment)}</dd></dl></div>`
    + `${provenance(material)}<p>${hashLink("resources-crafting", "← Resources & Crafting")}</p>`;
}

function roadmap() {
  return header("Operational board", "Roadmap", "Current statuses remain operational facts, including explicit holds and provisional work.") + `<div class="table-wrap"><table><thead><tr><th>Item</th><th>Status</th><th>Workstream</th></tr></thead><tbody>${data.roadmap.map(item => `<tr><td><strong>${escapeHTML(item.name)}</strong><br><small>${escapeHTML(item.id)}</small></td><td>${badge(item.status)}</td><td>${escapeHTML(item.workstream)}</td></tr>`).join("")}</tbody></table></div>`;
}

function history() {
  return header("Separated archive", "Decisions / History", "Historical records remain discoverable without overriding current authorities.") + `<h2>Current authority registry</h2><div class="grid">${data.authorities.slice(0, 18).map(item => `<article class="card"><h3>${escapeHTML(item.title)}</h3>${badge(item.status)}<p><code>${escapeHTML(item.path)}</code></p></article>`).join("")}</div><h2>Historical records</h2><div class="card"><p>${data.history.length} archived or session-decision documents are registered as history.</p><ul>${data.history.slice(0, 30).map(item => `<li><code>${escapeHTML(item.path)}</code></li>`).join("")}</ul></div>`;
}

function assets() {
  return header("Evidence only", "Asset Gallery", "Only committed and accepted art may appear as final. Rejected pixels stay absent; stable slots remain inspectable.") + `<div class="empty"><strong>No accepted building art registered.</strong><p>${escapeHTML(data.assetGallery.note)}</p></div><div class="grid">${data.assetGallery.slots.map(slot => `<article class="card"><h3><code>${escapeHTML(slot.key)}</code></h3>${badge(slot.status)}<p>${slot.assetPath ? escapeHTML(slot.assetPath) : "No accepted asset path."}</p></article>`).join("")}</div>`;
}

function notFound() { return header("404", "Page not found", "This internal route is not registered."); }

function render({ resetScroll = false } = {}) {
  const route = location.hash.replace(/^#\/?/, "") || "overview";
  const [root, detail] = route.split("/");
  let content;
  if (root === "overview") content = overview();
  else if (root === "village-buildings") content = village();
  else if (root === "station") content = stationDetail(detail);
  else if (root === "people") content = people();
  else if (root === "resources-crafting") content = resources();
  else if (root === "catalogue") content = catalogue(detail);
  else if (root === "item") content = itemDetail(detail);
  else if (root === "resource") content = resourceDetail(detail);
  else if (root === "creature-material") content = creatureMaterialDetail(detail);
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
  const kindFilter = document.querySelector("#destination-kind-filter");
  kindFilter?.addEventListener("change", () => {
    document.querySelectorAll("[data-destination-kind]").forEach(card => { card.hidden = kindFilter.value !== "all" && card.dataset.destinationKind !== kindFilter.value; });
  });
  if (resetScroll) resetRouteScroll(window, document.querySelector(".main"));
}

addEventListener("hashchange", () => render({ resetScroll: true }));
render({ resetScroll: true });
