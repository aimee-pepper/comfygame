# Static/manual authority audit — current

**Status:** active audit; first repository pass 11 Aug 2026
**Owner:** Game Design classifies authority; Engineering automates only approved cases
**Roadmap ID:** `dynamic-authority-audit`

## Boundary

“Dynamic” does not mean procedural or remotely configurable. Authored prose, balance constants,
stable IDs, visual identity mappings and deliberate campaign order remain authored. This audit finds
facts copied into two or more places where one copy can change without the others, and recurring
status chores that can be derived from evidence already in the repository.

Classify each finding as:

- **derive** — one canonical source already exists; consumers should read or generate from it;
- **validate** — two representations are legitimately required, but a test must prove agreement;
- **author** — the apparent duplication is an intentional design decision and remains explicit;
- **archive** — historical text remains readable but must stop presenting itself as current status.

## First-pass findings

| Priority | Area | Drift risk | Direction |
|---|---|---|---|
| Closed | DEBUG Roadmap | Swift UI and Markdown previously repeated operational status | **Derive:** the app now renders bundled `playability-roadmap.json`; Markdown owns rationale and checkpoint history only |
| P0 active | Save ownership | One implicit save path made campaign identity and current game inseparable | **Derive:** UUID slot envelope owns metadata plus payload; campaign chooser reads the slot catalogue; legacy file is adopted once |
| P1 | Installed checkpoint context | Bug reports previously required a person to remember which roadmap/build state they described | **Derive:** every new report captures the bundled roadmap checkpoint plus app build; old reports decode without the field |
| P1 | Station presentation order | `stations.json` contains repeated `sortOrder` values; current secondary order is merely JSON array order and the Swift comparator has no explicit tie-break | **Author/validate:** either give every station a unique authored position or add an explicit group + within-group order; do not let incidental decode order decide Base layout |
| P1 | Authored-text atlas census | DEBUG tests hard-code 28 travellers, 233 pages, 7 live meetings and 21 missing meetings | **Validate:** retain intentional corpus-size milestone assertions only as named snapshots; derive completeness/missing sets from catalogue IDs so adding Noll cannot require hunting several arithmetic mirrors |
| P1 | Generated meeting corpus | Markdown drafts are compiled into `DraftMeetingCorpus.generated.swift`; the generator exists, but ordinary build correctness depends on someone rerunning it | **Validate/generate:** add a check mode to the normal verification path that fails when generated output differs from its Markdown sources; never make runtime parse design Markdown |
| P1 | Resource identity surfaces | Map and collection UI previously had separate resource symbols, allowing accepted v0.6 identities to degrade to generic icons | **Derive:** one native resource grammar now feeds map and collection surfaces, with the inventory-only Mote exception fixture-covered |
| P1 | Item identity surfaces | Catalogue SF Symbols collapse multiple boots, keepsakes, tools and weapon families into identical six-across tiles | **Author once/derive:** Asset authors a versioned stable item-identity mapping; Storehouse, Trading Post, loot, equipment and Recycler consume the same resolved identity |
| P1 | Traveller identity surfaces | Party and Library use generic person/catalogue symbols despite accepted named-character identity work | **Derive after adapter:** one persisted character identity/facing adapter should feed map, Party and Library; no screen-local surrogate portraits |
| P1 | Distillery requirement copy | `StationViews` manually repeated Essence, catalyst and material thresholds separately from `DistilleryRules`, so a tuning change could make visible requirements lie | **Derive:** one structured rules-owned requirement now drives candidate eligibility, catalyst options and visible requirement text; focused boundary tests protect the shared thresholds |
| P2 | Current-document indexing | `current-design-index.md` is a manually curated router and several old “current” documents retain stale live-status paragraphs | **Validate/archive:** add lightweight structured metadata or a manifest for current/superseded/owner/roadmap IDs and generate a drift report; keep prose and decision history authored |
| P2 | Exact catalogue counts in tests | Some raw counts are useful release-scope assertions; others are accidental edit taxes | **Classify:** replace accidental totals with set/reference invariants, retain explicit scope caps only when the number itself is a settled design promise |
| P2 | Data-to-route bridge | Station route strings and compiled `AppRoute` cases must both exist | **Validate, do not derive:** views are compiled code; keep the existing routing completeness test and improve its error to name missing/orphan routes |

## First implementation order

1. Finish and test save-slot ownership; it removes the highest-cost manual test-state bottleneck.
2. Keep roadmap checkpoint/build context attached automatically to bug reports.
3. Make generated meeting-corpus drift a normal verification failure.
4. Resolve station ordering before Noll/Recycler adds another station and exposes incidental ties.
5. Convert atlas completeness from arithmetic mirrors to catalogue-ID set comparison while retaining
   named corpus milestone snapshots separately.
6. Introduce a structured document-status manifest only after the live gameplay blockers above; do
   not bulk-edit decision history merely to satisfy a tool.

## Acceptance for the audit itself

- Every candidate names its canonical authority and all known consumers.
- Automation does not erase authored judgment or make old decisions disappear.
- A changed canonical source either updates consumers automatically or fails verification with a
  precise message.
- No dynamic/runtime dependency on repository Markdown is introduced into Release builds.
- The live roadmap tracks implementation status; this document tracks findings and rationale, not a
  second operational board.
