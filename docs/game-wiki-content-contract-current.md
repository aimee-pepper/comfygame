# Internal Game Wiki — content and completeness contract

**Status:** Current Game Design/Orchestration authority for the source-generated internal wiki.
**Purpose:** Make the game understandable as a coherent system without asking Aimee to read repository files,
while never presenting proposed or historical material as live behavior.
**Implementation:** `GameWiki/**` is generated from registered game data and current authorities. Handwritten
page content may provide layout grammar, but entity facts and status are derived rather than copied.
**Updated:** 21 August 2026

## Current progress

**Checkpoint A — Catalogue + Resources: accepted.** Live browser review at 368×800 proved the exact item
partition, slot/damage/reach groupings, stable detail routes, World/live-Creature/designed-Creature/currency
separation and no horizontal overflow. The initial route-scroll defect and fabricated `Table`/`Families`
material entries were corrected: internal navigation now opens every route at its heading, and the designed
Creature set derives exactly 18 stable ComponentProfile families.

**Current checkpoint B — People.** Generate the People index and all named-traveller detail routes from the
canonical 29-person authorities. This is the next source-generated slice; it does not wait for every meeting
to become live and must label live, authored-not-live and held content honestly.

## What “complete” means

The existing wiki foundation is technically generated but not content-complete. A route that only names an
authority file, says extraction is pending, or presents one undifferentiated catalogue is a placeholder.
Generator freshness does not make that page complete.

A complete route:

1. answers what the system is, why the player uses it and where it appears;
2. exposes its real components and relationships through structured generated facts;
3. distinguishes **live**, **settled design / not yet implemented**, **provisional or review-gated**, and
   **historical** truth;
4. links every catalogue entity to a stable detail route;
5. has no blank primary explanation and no “see source” substitute for content;
6. updates when its registered source changes, with tests proving every source entity is accounted for.

The wiki is private/internal. It may explain undisclosed systems for development, but player-disclosure state
must still be labelled so internal truth cannot accidentally become a release-facing screen.

## Truth and provenance

Every generated fact carries source path/hash, stable ID where one exists, implementation disposition and
the aggregate generation hash. Dispositions are `live`, `settled-not-live`, `provisional`, `removed`, and
`history`.

`*-current.md`, current content data and current source rules outrank session/history files. History is
searchable only under Decisions / History and never silently fills a current field. A conflict renders a
visible conflict receipt and fails generation when it affects an exact field; the generator does not blend
both answers.

## Required navigation and route depth

| Route | Required generated content |
|---|---|
| **Overview** | premise, playable-loop diagram, build/install receipt, major live/system gaps and links to every section |
| **Core Loop** | Writing → arrival → exploration → discovery → return → preparation; costs, receipts, failure/continuation and first-three-world progression |
| **World Writing** | tools/hands, Pages/Templates, 21 runes, known vs encountered meanings, costs, starter/wild World Pages and causal outputs |
| **Exploration** | map/visibility, movement, terrain/hazards, sites/POIs, resources, creatures, Field actions, collapse/escape and Return receipts |
| **Combat** | scaling, party/rank/reach, damage triangle, statuses, equipment, progression trees and implementation/playtest disposition |
| **People** | one route per traveller with role, station, campaign phase/order, clue/page coverage, meeting/dialogue state and visual status |
| **Home & Village** | Binder House, Library, districts and every canonical destination/building with lifecycle/forms/capabilities/assets |
| **Resources & Crafting** | World Resources, Creature Materials and Currencies as distinct domains; quality/components, stations and schematics |
| **Catalogue** | Gear, Consumables, Curios, Treasures and Keys as distinct routes and filters; never one flat Items grid |
| **Roadmap** | priorities by band/workstream, sole primaries, gates and latest verified checkpoint |
| **Decisions / History** | current authority registry plus explicitly historical decisions and supersession links |
| **Asset Gallery** | accepted committed assets as usable art; accepted candidate/unintegrated slots remain labelled without false paths |

No required top-level route may call a generic `authorityPage` fallback. Each route has its own generator,
structured data shape, renderer and completeness test.

## Catalogue taxonomy

### Gear

All live `items.json` entries with `kind == gear` appear under **Gear**, grouped first by exact slot: Weapon,
Offhand, Head, Body/Armor, Hands, Feet, Tool and Keepsake. Weapons additionally show damage kind and reach.
Every gear detail includes stable ID, name, blurb, rarity, slot, construction/effective tier fields,
damage/reach, protection/insulation/reactivity where authored, unique/apex rule or ward where present, Trading
Post and Recycler disposition, source status and asset status. Missing optional mechanics say “none authored”;
they do not disappear into a generic summary.

### Consumables

Every `kind == consumable` item has a detail route showing exact effect, potency, legal target/use timing,
recipe/knowledge source when registered, trade/recycle disposition and implementation status. Coatings and
ordinary consumables may be filtered separately but remain in this domain.

### Curios, Treasures and Keys

These are three distinct catalogue groups. Curios show identified/unidentified identity where authored.
Treasures show their exact system or crafting role without pretending they are currency. Keys show the lock
family/provenance they are allowed to open and never group with quest/story keys by visual resemblance alone.

The current source catalogue contains 102 items. Tests derive and compare the partition directly to
`items.json`; the current expected receipt is 75 Gear, 18 Consumables, 2 Curios, 5 Treasures and 2 Keys. A
new kind fails generation until it receives an explicit player-facing group and detail renderer.

## Resource taxonomy

### World Resources

Named world-produced holdings from `resources.json` appear as World Resources, not Items or Creature
Materials. Each detail shows stable ID/name, generation driver, exact requires/favours, trade band, current
harvest/capability gate, known station/recipe/build uses, quality/stack status and live/proposed disposition.
The generator turns structured pressure requirements into a readable explanation; an empty summary is a test
failure.

### Creature Materials

Creature remains occupy their own domain. The wiki separately exposes currently live `MaterialKind`/remains
behavior and the settled ecology/material family authority that is not yet live. It must not present Feather,
Fin, Scale, Shell, Horn, Oil or Venom as live merely because their design is settled, and it must not describe
transitional generic Hide/Bone behavior as final. Each family detail shows visible anatomical source,
habitat/body relationship, legal component/ingredient uses, stack/quality rule and implementation status.

### Currencies and Essence

Gold Coins, Raw Essence, refined Essence and Motes form a separate currency/progression group. They are not
gear, ordinary resources or interchangeable materials. Each detail explains acquisition, current sinks,
persistence layer and whether it participates in quality. Gold Ore remains a World Resource and is never
conflated with Gold Coins.

Every current `resources.json` ID is accounted for exactly once in a player-facing domain/status. Additional
currency facts come from their real model/rule authority rather than being inserted into `resources.json`
solely for the wiki.

## Entity detail requirements

Stable detail routes are required for every item, resource, traveller, rune, destination/building and
roadmap entry. Detail routes retain filters and focus on Back.

- **Traveller:** role, station/district, campaign phase/order, authored clue/page count, meeting/recruitment
  state, diary teachings, concise role description and current asset.
- **Rune:** canonical identity, encountered/known distinction, writing targets/qualifiers, costs and sources;
  no disclosure is inferred from catalogue presence.
- **Destination:** kind, place, keeper, lifecycle, actions, build cost, three forms, implementation and assets.
- **Roadmap entry:** status, band, workstream, dependency/gate, latest receipt and source; “later” alone is not
  an acceptable schedule.

Search results include domain, subtype, stable ID, disposition and exact detail route. Search never routes an
item or resource to its undifferentiated parent grid.

## Automatic completeness gates

Generation/tests fail when:

1. a required top-level route uses generic placeholder/fallback copy;
2. a required route has no structured facts;
3. an item/resource/traveller/rune/destination lacks exactly one category and detail route;
4. a catalogue kind or gear slot is unknown/unclassified;
5. a resource has an empty primary explanation;
6. live and settled-not-live facts are merged without disposition;
7. candidate art is shown as integrated/final or an unaccepted file is copied into the gallery;
8. generated data is stale against any registered source hash;
9. a source entity count changes without the derived partition changing with it;
10. a current route cites history without an explicit current supersession receipt.

Browser checks cover desktop and 368-point layouts, every top-level route, one detail from every catalogue/
resource subtype, filter persistence, search routing and no horizontal clipping.

## Implementation order

The wiki does not pre-empt a compiling/high-priority gameplay checkpoint. Once a clean GameWiki boundary is
available, continue without treating each slice as a stop:

1. Catalogue taxonomy + item details — **accepted**;
2. World Resources / Creature Materials / Currencies + details — **accepted**;
3. People + traveller details — **current**;
4. World Writing + rune details;
5. Core Loop and Exploration;
6. Combat;
7. Overview reconciliation, Roadmap detail and History supersession links;
8. accepted-asset ingestion when committed asset paths actually exist.

Each slice is source-generated and tested. Completion receipts say what became useful to Aimee, not merely
how many files or hashes changed.
