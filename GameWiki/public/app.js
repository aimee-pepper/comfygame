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
    ["core-loop", "Core Loop", "Write → arrive → explore → return → prepare, with live and not-yet-live steps separated."],
    ["world-writing", `${data.counts.runes} writing lexemes`, "Physical Pages, three hands, knowledge boundaries, costs and one stable detail route per lexeme."],
    ["exploration", "Exploration", "Movement, visibility, hazards, discoveries, collapse and return."],
    ["combat", "Combat", "Current scaling, reach, damage, equipment, statuses and God Mode evidence limits."],
    ["village-buildings", `${data.counts.stations} Home & Village destinations`, "Rooms, interfaces, shelves, progression surfaces, yard features, and village buildings—truthfully distinguished."],
    ["people", `${data.counts.travellers} authored people`, "Stable identities and current source dispositions."],
    ["roadmap", `${data.counts.roadmap} roadmap receipts`, "Operational status without silently promoting provisional work."],
    ["asset-gallery", "Asset evidence", "Acceptance, source integration and native/phone status remain separate receipts."]
  ];
  const liveCount = data.roadmap.filter(item => item.status === "complete" || item.status === "readyToTest").length;
  const currentPrimary = data.roadmap.find(item => item.isPrimary);
  return header("Private · generated", "What Bookbinder is", "Bookbinder is an expedition game about physically writing worlds, exploring what those words caused, and bringing knowledge and materials home to prepare the next journey.") +
    `<div class="grid">${cards.map(([route, title, text]) => `<a class="card" href="#/${route}"><h3>${escapeHTML(title)}</h3><p>${escapeHTML(text)}</p></a>`).join("")}</div>
    <h2>What is playable now</h2><div class="card"><p>The source-complete E4 Write pane is ready for signed in-place phone installation and ordinary-path review; the existing loop can bind worlds, explore terrain and encounters, collect objects and Pages, return home, use destinations and grow a party. ${liveCount} roadmap receipts are currently complete or awaiting acceptance. Dedicated Pages/The world Writing panes, the frozen arrival tableau and several presentation rebuilds remain absent or queued.</p></div>
    <h2>What is actually next</h2><div class="card"><p>${currentPrimary ? `${escapeHTML(currentPrimary.name)} is the sole current primary and remains ${escapeHTML(currentPrimary.status)}.` : "No sole current primary is registered."} Every verified phone-ready update installs promptly in place without uninstall/reset; installation does not authorize auto-launch. Writing E4 still awaits physical-phone acceptance, and protected isolated Terrain integration does not displace that gate. E5–E7 remain explicitly not started.</p></div>
    <h2>Truth boundary</h2><div class="card"><p>Plain-language summaries lead; provenance follows. Current pages prefer registered <code>*-current.md</code> authorities. Decision logs remain under History and never replace current facts. Proposed, paused and settled-not-live work is labelled where it appears.</p></div>${sourceReceipt(["docs/current-design-index.md", "docs/game-wiki-content-contract-current.md"])}`;
}

function sourceReceipt(paths) {
  const records = paths.map(path => data.authorities.find(item => item.path === path)).filter(Boolean);
  return `<div class="provenance"><strong>Why this is current</strong><br>${paths.map(escapeHTML).join(" · ")}<br>${records.map(item => `${escapeHTML(item.title)} — ${escapeHTML(item.status)}`).join("<br>")}<br>Generated at source hash: ${escapeHTML(data.generatedAtSourceHash)}</div>`;
}

function flow(steps) {
  return `<div class="progression-grid">${steps.map((step, index) => `<article class="card"><div class="kicker">Step ${index + 1}</div><h3>${escapeHTML(step[0])}</h3><p>${escapeHTML(step[1])}</p>${badge(step[2])}</article>`).join("")}</div>`;
}

function worldWriting() {
  const groups = ["target", "source", "qualifier", "compound"];
  const current = data.currentTruth.writing;
  return header("Physical writing system", "World Writing", "A world begins as a physical 6×6 page. Marks occupy space, links turn marks into requests, and a final bind freezes the exact page, costs, field loadout and world receipt.")
    + `<h2>Compose a page</h2>${flow([
      ["Choose a hand", "Rough charcoal writes large crude marks; Brush writes medium plain marks; Fountain pen writes refined one-cell marks. A better hand saves space, not meaning.", "live"],
      ["Place and connect", "Targets name what a request is about. Sources act only when linked to a target. Qualifiers modify a directly connected source. Compounds are compact self-contained statements.", "live"],
      ["Choose ink", "Ash/open leaves colour unspecified. Prepared ink recipes freeze exact CMY/Depth applications when the page is bound; ordinary editing spends nothing.", "live"],
      ["Review and bind", "The review surface redacts unread meanings before it forms any text. The same quote is compared inside one atomic mutation before Essence, ink, inventory or a collected page can move.", "partly live"]
    ])}`
    + `<h2>Four Writing Desk states</h2><div class="facts">
      <dl class="fact"><dt>Write</dt><dd>${escapeHTML(current.statusLabel)}: complete paper, Hand/Ink strip and canonical vocabulary palette. Placement, turning and connections remain zero-spend edits.</dd></dl>
      <dl class="fact"><dt>Pages</dt><dd>Designed, not yet implemented in E5: choose a reusable draft or one exact collected physical page without leaking unread semantics.</dd></dl>
      <dl class="fact"><dt>Templates</dt><dd>Live persistence: saved compositions can be loaded, renamed, overwritten and deleted; a template is not consumed by binding.</dd></dl>
      <dl class="fact"><dt>The world</dt><dd>Designed, not yet implemented in E6/E7: truthful costs, broad unread risk, causal outputs, loadout and final Bind & Depart.</dd></dl>
    </div>`
    + `<h2>Current visual boundary</h2><div class="card">${badge(current.status)}<p>The current native source bundles and hash-validates <code>${escapeHTML(current.parchment.stableKey)}</code>; that proves source integration, not ordinary-phone acceptance. The standalone artifact still records <code>integrationReady:${escapeHTML(current.parchment.artifactIntegrationReady)}</code>, so the wiki preserves both receipts instead of silently promoting either one.</p><p>${escapeHTML(current.markArtStatus)}. ${escapeHTML(current.vocabularyLabelStatus)}.</p></div>`
    + `<h2>Knowledge and disclosure</h2><div class="card"><p><strong>Known</strong> licenses a readable name and meaning. <strong>Encountered</strong> only proves that the mark was seen and may display <code>??</code>. Targets and writable qualifiers are rules-known; sources and compounds become known through campaign ownership. An unread mark never contributes hidden names, icons, sorting text, accessibility text, ecology claims, sight bands or narrow collapse estimates.</p></div>`
    + `<h2>Page sources and consumption</h2><div class="facts"><dl class="fact"><dt>Draft</dt><dd>Reusable after bind; its revision and frozen page hash participate in the quote.</dd></dl><dl class="fact"><dt>Collected / wild page</dt><dd>One physical instance with a canonical definition hash. Successful bind consumes only that selected instance; stale catalogue identity refuses.</dd></dl><dl class="fact"><dt>Starter pages</dt><dd>Authored World Pages promise a known starting identity, price and seed. Their exact current world receipts remain data-owned.</dd></dl><dl class="fact"><dt>Costs</dt><dd>Essence, exact ink-vial deductions and Field Kit stack moves are frozen in one quote. Any sufficient-but-different wallet, vial or stack state makes it stale.</dd></dl></div>`
    + `<h2>Canonical lexemes · ${data.symbols.length}</h2><p>These are development-facing catalogue identities. Each detail labels what may be disclosed to a player.</p>`
    + groups.map(kind => `<h3>${escapeHTML(titleCase(kind))} · ${data.symbols.filter(item => item.category === kind).length}</h3><div class="grid">${data.symbols.filter(item => item.category === kind).map(item => `<a class="card" href="#/lexeme/${item.slug}"><h3>${escapeHTML(item.name)}</h3>${badge(kind)}<p>${escapeHTML(item.summary)}</p><code>${escapeHTML(item.stableID)}</code></a>`).join("")}</div>`).join("")
    + sourceReceipt(["docs/writing-desk-b1-implementation-packet-current.md", "docs/world-pages-templates-dictionary-current.md"]);
}

function lexemeDetail(slug) {
  const item = data.symbols.find(candidate => candidate.slug === slug);
  if (!item) return notFound();
  return header(`${titleCase(item.category)} lexeme · ${item.disposition}`, item.name, item.summary)
    + `<div class="facts"><dl class="fact"><dt>Stable ID</dt><dd>${escapeHTML(item.stableID)}</dd></dl><dl class="fact"><dt>Identity</dt><dd>${escapeHTML(titleCase(item.category))}</dd></dl><dl class="fact"><dt>Acquisition/source</dt><dd>${escapeHTML(item.acquisition)}</dd></dl><dl class="fact"><dt>Writing cost</dt><dd>${item.essenceCost == null ? "No separate catalogue Essence cost" : `${item.essenceCost} Essence`}</dd></dl><dl class="fact"><dt>Writability</dt><dd>${escapeHTML(item.writability)}</dd></dl><dl class="fact"><dt>Player disclosure</dt><dd>${escapeHTML(item.disclosure)}</dd></dl></div>`
    + (item.expansion.length ? `<h2>Typed authored effect</h2><div class="card"><ul>${item.expansion.map(value => `<li>${escapeHTML(value)}</li>`).join("")}</ul></div>` : "")
    + (item.attachesTo.length ? `<h2>Legal subjects</h2><div class="card"><p>${escapeHTML(item.attachesTo.join(" · "))}</p></div>` : "")
    + provenance(item) + `<p>${hashLink("world-writing", "← World Writing")}</p>`;
}

function coreLoop() {
  return header("Playable expedition cycle", "Core Loop", "Write a world, enter it, bring back evidence, and use that evidence to make the next expedition more deliberate.")
    + flow([
      ["Write", "Compose or choose a physical page. The review shows only meanings the campaign actually knows and freezes exact costs before binding.", "live + installed E4"],
      ["Arrive", "A successful new bind freezes a world identity and arrival receipt. The dedicated arrival presentation is designed and queued; it must not reroll or reveal hidden content.", "settled-not-live"],
      ["Explore", "Move, Look and Use Tile on a visibility-limited map. Discover terrain, resources, pages, sites and people while stability declines.", "live"],
      ["Collapse or leave", "Returning, retreating and collapse produce typed outcomes. Protected and ordinary carried objects follow different loss rules.", "live"],
      ["Review", "The return receipt separates recovered, lost and progression facts. The current receipt mechanics are live; the final object-layout screen remains queued.", "partly live"],
      ["Prepare at home", "Spend recovered materials and Essence, meet people, build destinations and improve the next written expedition.", "live + expanding"]
    ])
    + `<h2>What can fail without corrupting a campaign</h2><div class="card"><p>A stale bind quote, missing collected page, changed wallet/vial/Field Kit stack, active run, failed generator or failed visual adapter must refuse before any spend or consumption. Inside a world, retreat remains a real costed choice; collapse resolves through the return receipt rather than silently deleting the expedition.</p></div>`
    + `<h2>First-three-world progression</h2><div class="card"><p>The opening sequence uses authored starter pages to teach writing, arrival, movement, discovery and return one causal step at a time. Open Flats, Rainwashed Shore and Stone Hollow retain distinct world facts; the wiki labels their presentation work separately from live generation.</p></div>`
    + sourceReceipt(["docs/core-loop-causal-presentation-plan-current.md", "docs/first-three-worlds-execution-plan-current.md"]);
}

function exploration() {
  const terrain = data.currentTruth.terrain;
  return header("Inside a written world", "Exploration", "The map is a limited, remembered place—not a full-board inventory. Visibility controls current disclosure; memory preserves terrain without preserving moving threats.")
    + `<h2>Map actions</h2><div class="facts"><dl class="fact"><dt>Move</dt><dd>Movement spends turns and follows terrain, elevation, obstruction and encounter rules.</dd></dl><dl class="fact"><dt>Look</dt><dd>A zero-turn adjacent preview. It disarms on any non-direction surface or state change and must not reveal facts beyond current knowledge.</dd></dl><dl class="fact"><dt>Use Tile</dt><dd>The stable contextual action for the current tile: harvest, search, inspect, take, contact or use a site. Exhausted nodes must become unavailable truthfully.</dd></dl><dl class="fact"><dt>Field Kit</dt><dd>Carried capacity is finite. Taking a page or object can open an exact swap decision; cancellation and stale choices mutate nothing.</dd></dl></div>`
    + `<h2>Visibility and memory</h2><div class="card"><p><strong>Full</strong> shows terrain and current entities. <strong>Fringe</strong> shows terrain/elevation without flora, objects or moving mobs. <strong>Remembered</strong> shows explored terrain and static learned objects, but not moving mobs. <strong>Hidden</strong> is opaque and carries no terrain payload into disclosure-safe receipts. Atmosphere may soften visibility; it is not a shortcut for the visibility math.</p></div>`
    + `<h2>World contents</h2><div class="progression-grid"><article class="card"><h3>Terrain & hazards</h3><p>Ground, water, elevation and active flora decide passability, movement cost and learned consequence cues. Hazard details appear only when seen or earned.</p>${badge("live")}</article><article class="card"><h3>Resources & objects</h3><p>World resource nodes, loose Essence, items and pages are physical finds. A local pickup is one exact group and inventory transaction.</p>${badge("live")}</article><article class="card"><h3>Sites & people</h3><p>Sites can be inspected or used; traveller presence follows written-world conditions. Hidden sites and identities remain undisclosed.</p>${badge("live")}</article><article class="card"><h3>Creatures</h3><p>Ordinary and apex creatures occupy the world and can initiate combat. The final habitat/material ecology projection is settled design but not yet live.</p>${badge("mixed")}</article></div>`
    + `<h2>Current Terrain presentation boundary</h2><div class="facts"><dl class="fact"><dt>Closed border correction</dt><dd>${badge(terrain.borderCorrection.status)} ${escapeHTML(terrain.borderCorrection.summary)}</dd></dl><dl class="fact"><dt>Layered shapes & motion</dt><dd>${badge(terrain.layeredPresentation.status)} ${escapeHTML(terrain.layeredPresentation.nativeStatus)}. This changes presentation only.</dd></dl><dl class="fact"><dt>Atmosphere & height shade</dt><dd>${badge(terrain.atmosphere.status)} ${escapeHTML(terrain.atmosphere.nativeStatus)}. It is not current native terrain behavior.</dd></dl></div>`
    + `<h2>Stability, collapse and turns-left</h2><div class="card"><p>Stability is the world’s remaining ability to hold together. “Turns left” is a current estimate derived from the active world, not a second timer. Leaving early, retreating or collapse each produce their own typed return outcome and preservation rules.</p></div>`
    + sourceReceipt(["docs/world-screen-phone-composition-current.md", "docs/field-feedback-and-loot-presentation-current.md", "docs/core-loop-causal-presentation-plan-current.md"]);
}

function combat() {
  return header("Turn-based encounters", "Combat", "Combat resolves party position, reach, equipment and conditions against an encounter frozen when contact begins. Scaling source is complete and awaiting ordinary-phone feel review.")
    + `<h2>How an encounter is formed</h2><div class="facts"><dl class="fact"><dt>Frozen receipt</dt><dd>Difficulty inputs, party state and encounter identity freeze at opening so later UI cannot reinterpret the fight.</dd></dl><dl class="fact"><dt>Party and rank</dt><dd>Party size, individual levels and uneven progression feed the deterministic scaling matrix; ordinary Normal fights target a short victorious curve.</dd></dl><dl class="fact"><dt>Reach</dt><dd>Weapon and action reach decide legal targets and positioning. The Gear catalogue lists exact weapon damage kind and reach.</dd></dl><dl class="fact"><dt>Apex</dt><dd>Apex encounters use their own authored/scaled profile and do not leak ordinary reward or difficulty assumptions.</dd></dl></div>`
    + `<h2>Damage, defence and statuses</h2><div class="card"><p>Physical damage kinds interact with covering and wards; emanations, conditions, cooldowns and equipment-derived protection remain separate typed rules. Logs record the actual decisions and harm rather than a simplified UI estimate. Equipment changes available actions and protection without silently changing a frozen encounter receipt.</p></div>`
    + `<h2>God Mode and evidence</h2><div class="card">${badge("readyToTest")}<p>DEBUG God Mode freezes only into newly opened encounters. Enemy choices, incoming damage, conditions, cooldowns and logs remain ordinary; lethal party damage is recorded while active party HP floors at 1 and defeat is suppressed. It grants no offence, loot, XP, spawn or retreat advantage. Bug reports remain valid for UI, crashes, content, worlds and economy; only combat-balance conclusions are marked invalid.</p></div>`
    + `<h2>Progression status</h2><div class="facts"><dl class="fact"><dt>Current production</dt><dd>Live combat trees, points, prerequisites, skills and current equipment rules continue to drive play.</dd></dl><dl class="fact"><dt>Graph design</dt><dd>A newer graph authority and Constellation mastery proposal exist, but restructuring/capacity choices remain held or queued. The wiki does not present them as unlocked production behavior.</dd></dl><dl class="fact"><dt>Scaling acceptance</dt><dd>Source and automated matrices are green. Phone feel is nonblocking acceptance evidence and may reopen tuning without blocking other source work.</dd></dl></div>`
    + sourceReceipt(["docs/combat-progression-current.md", "docs/core-loop-causal-presentation-plan-current.md"]);
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
  const phases = [...new Set(data.travellers.map(person => person.campaignPhase))];
  return header("Complete traveller slice", "People", "All 29 stable traveller identities, ordered by authored arrival. Live content and authored-but-not-live meetings remain visibly distinct.")
    + `<p><label for="people-phase-filter">Campaign phase </label><select id="people-phase-filter"><option value="all">All phases</option>${phases.map(phase => `<option value="${escapeHTML(phase)}">${escapeHTML(titleCase(phase))}</option>`).join("")}</select></p>`
    + `<div class="grid" id="people-grid">${data.travellers.map(person => `<a class="card" data-person-phase="${escapeHTML(person.campaignPhase)}" href="#/person/${person.slug}"><h3>${escapeHTML(person.authoredOrder)} · ${escapeHTML(person.name)}</h3>${badge(person.meetingStatus)}${badge(person.campaignPhase)}<p><strong>${escapeHTML(person.calling)}</strong></p><p>${escapeHTML(person.summary)}</p><p>${person.pageCount} diary pages · ${person.clueCount} location clues</p></a>`).join("")}</div>`;
}

function personDetail(slug) {
  const person = data.travellers.find(candidate => candidate.slug === slug);
  if (!person) return notFound();
  const station = person.station
    ? `${hashLink(`station/${person.station.slug}`, person.station.name)} · ${escapeHTML(person.station.zone)} · ${escapeHTML(titleCase(person.station.destinationKind))}`
    : "No owned destination in the live station catalogue.";
  const teaching = person.teaching
    ? `<code>${escapeHTML(person.teaching.stableID)}</code> from <code>${escapeHTML(person.teaching.pageID)}</code> · ${escapeHTML(titleCase(person.teaching.kind))}`
    : "No singular diary teaching is authored for this traveller.";
  const meetingCopy = person.meetingStatus === "live"
    ? `${person.meetingQuestionCount} stable question/reply exchanges are present in the live traveller catalogue.`
    : "A reviewed meeting exists in authored review authority, but no meeting object is live in travellers.json yet.";
  return header(`Traveller ${person.authoredOrder} · ${titleCase(person.campaignPhase)}`, person.name, `${person.calling}. ${person.summary}`)
    + `<div class="facts">
      <dl class="fact"><dt>Stable ID</dt><dd>${escapeHTML(person.id)}</dd></dl>
      <dl class="fact"><dt>Calling / role</dt><dd>${escapeHTML(person.calling)}</dd></dl>
      <dl class="fact"><dt>Campaign order</dt><dd>${person.authoredOrder} · arrival band ${person.storyArrivalBand}</dd></dl>
      <dl class="fact"><dt>Phase</dt><dd>${escapeHTML(titleCase(person.campaignPhase))}</dd></dl>
      <dl class="fact"><dt>Worldwork</dt><dd>${person.worldwork == null ? "Not authored" : escapeHTML(person.worldwork)}</dd></dl>
      <dl class="fact"><dt>Diary coverage</dt><dd>${person.pageCount} pages · ${person.clueCount} location clues</dd></dl>
    </div>
    <h2>Home contribution</h2><div class="card"><p>${station}</p></div>
    <h2>Diary teaching</h2><div class="card"><p>${teaching}</p></div>
    <h2>Meeting & recruitment</h2><div class="card">${badge(person.meetingStatus)}${badge(person.recruitmentStatus)}<p>${escapeHTML(meetingCopy)}</p></div>
    <h2>Visual identity</h2><div class="card">${badge("live")}<p>${escapeHTML(person.visualStatus)}. The wiki does not imply that a final portrait asset exists.</p></div>
    ${provenance(person)}<p>${hashLink("people", "← All people")}</p>`;
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
  const groups = Object.groupBy(data.roadmap, item => item.status);
  return header("Operational board", "Roadmap", "This is the work ledger—not a list of everything designed. Status, owner, gate and evidence remain separate from visual or phone acceptance.")
    + Object.entries(groups).map(([status, items]) => `<h2>${escapeHTML(titleCase(status))} · ${items.length}</h2><div class="grid">${items.map(item => `<a class="card" href="#/roadmap/${item.slug}"><h3>${escapeHTML(item.name)}</h3>${badge(item.status)}${badge(item.workstream)}<p>${escapeHTML(item.summary)}</p></a>`).join("")}</div>`).join("");
}

function roadmapDetail(slug) {
  const item = data.roadmap.find(candidate => candidate.slug === slug);
  if (!item) return notFound();
  return header(`${titleCase(item.status)} · ${titleCase(item.workstream)}`, item.name, item.summary)
    + `<div class="facts"><dl class="fact"><dt>Stable ID</dt><dd>${escapeHTML(item.id)}</dd></dl><dl class="fact"><dt>Band</dt><dd>${escapeHTML(item.band)}</dd></dl><dl class="fact"><dt>Workstream</dt><dd>${escapeHTML(item.workstream)}</dd></dl><dl class="fact"><dt>Owner</dt><dd>${escapeHTML(item.owner)}</dd></dl><dl class="fact"><dt>Status</dt><dd>${escapeHTML(item.status)}</dd></dl><dl class="fact"><dt>Current primary</dt><dd>${item.isPrimary ? "Yes — sole registered primary" : "No"}</dd></dl></div>`
    + `<h2>Acceptance gate</h2><div class="card"><p>${escapeHTML(item.gate)}</p></div>${provenance(item)}<p>${hashLink("roadmap", "← Roadmap")}</p>`;
}

function history() {
  return header("Current truth and separated archive", "Decisions / History", "Use current authorities to understand the game now. Use History to learn why it changed; historical decisions never silently override a current page.")
    + `<h2>How to read this</h2><div class="card"><p><strong>Current authority</strong> is the active contract for implementation. <strong>Operational roadmap</strong> says whether anyone should act on it now. <strong>History</strong> records prior decisions and rejected alternatives. A detailed design can therefore be settled-not-live or paused without becoming current gameplay.</p></div>`
    + `<h2>Current authority registry · ${data.authorities.length}</h2><div class="grid">${data.authorities.map(item => `<article class="card"><h3>${escapeHTML(item.title)}</h3>${badge(item.status)}<p>This document currently defines or routes one part of the game.</p><code>${escapeHTML(item.path)}</code></article>`).join("")}</div>`
    + `<h2>Historical records · ${data.history.length}</h2><div class="card"><p>These archived and session-decision documents are retained for provenance. They are not used to fill missing current facts.</p><ul>${data.history.map(item => `<li><strong>${escapeHTML(item.title)}</strong><br><code>${escapeHTML(item.path)}</code></li>`).join("")}</ul></div>`;
}

function assets() {
  const writing = data.currentTruth.writing;
  const terrain = data.currentTruth.terrain;
  return header("Evidence only", "Asset Gallery", "Acceptance, committed source integration and native/phone acceptance are separate receipts. Candidate art is never promoted by implication.")
    + `<h2>Current non-building receipts</h2><div class="facts"><dl class="fact"><dt>Writing parchment</dt><dd>${badge(writing.status)} <code>${escapeHTML(writing.parchment.stableKey)}</code> is hash-pinned in the native source and bundle; ordinary-phone acceptance remains pending.</dd></dl><dl class="fact"><dt>Layered Terrain</dt><dd>${badge(terrain.layeredPresentation.status)} ${escapeHTML(terrain.layeredPresentation.nativeStatus)}. No native asset path is claimed here.</dd></dl></div>`
    + `<h2>Home & Village slots</h2><div class="empty"><strong>No native-ready building art registered.</strong><p>${escapeHTML(data.assetGallery.note)}</p></div><div class="grid">${data.assetGallery.slots.map(slot => `<article class="card"><h3><code>${escapeHTML(slot.key)}</code></h3>${badge(slot.status)}<p>${slot.assetPath ? escapeHTML(slot.assetPath) : "No accepted native asset path."}</p></article>`).join("")}</div>`;
}

function notFound() { return header("404", "Page not found", "This internal route is not registered."); }

function render({ resetScroll = false } = {}) {
  const route = location.hash.replace(/^#\/?/, "") || "overview";
  const [root, detail] = route.split("/");
  let content;
  if (root === "overview") content = overview();
  else if (root === "core-loop") content = coreLoop();
  else if (root === "world-writing") content = worldWriting();
  else if (root === "lexeme") content = lexemeDetail(detail);
  else if (root === "exploration") content = exploration();
  else if (root === "combat") content = combat();
  else if (root === "village-buildings") content = village();
  else if (root === "station") content = stationDetail(detail);
  else if (root === "people") content = people();
  else if (root === "person") content = personDetail(detail);
  else if (root === "resources-crafting") content = resources();
  else if (root === "catalogue") content = catalogue(detail);
  else if (root === "item") content = itemDetail(detail);
  else if (root === "resource") content = resourceDetail(detail);
  else if (root === "creature-material") content = creatureMaterialDetail(detail);
  else if (root === "roadmap") content = detail ? roadmapDetail(detail) : roadmap();
  else if (root === "history") content = history();
  else if (root === "asset-gallery") content = assets();
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
  const phaseFilter = document.querySelector("#people-phase-filter");
  phaseFilter?.addEventListener("change", () => {
    document.querySelectorAll("[data-person-phase]").forEach(card => { card.hidden = phaseFilter.value !== "all" && card.dataset.personPhase !== phaseFilter.value; });
  });
  if (resetScroll) resetRouteScroll(window, document.querySelector(".main"));
}

addEventListener("hashchange", () => render({ resetScroll: true }));
render({ resetScroll: true });
