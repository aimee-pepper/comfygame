# Native phone UI rendered audit

Status: in progress — ordinary 368×800 pass complete for the routed Base surfaces on the previously installed Debug binary; first Accessibility XXXL baseline complete for shared high-risk layouts; active World lower controls are covered, while encounter, return, and remaining populated states remain.

This audit supersedes source-only UI confidence. A screen is not considered audited until its real SwiftUI implementation has been rendered at phone size, visually inspected, and its accessibility tree checked. Code structure and successful builds are supporting evidence only.

## Method

- Real Debug app and real campaign state on an iPhone 17 simulator rendering at exactly 368×800.
- Every new rendered row must record the exact installed commit/build provenance. Repository `HEAD` is not installed-binary provenance. Evidence collected before this rule is an older-installed-build baseline whose exact commit is unavailable; the second-Simulator binary is confirmed to predate Campaign checkpoint `af27316` and Bind refusal fix `a543796`.
- DEBUG-only route injection opens existing `AppRoute` destinations; it does not replace screen code, data, navigation containers, or Release behavior.
- Each surface is checked for visible hierarchy, clipping, unexplained empty space, touch ownership, label legibility, scrolling, and state consistency.
- DEBUG bug-report affordance is ignored as Release chrome, but collisions with it are retained as DEBUG usability findings.
- CoreSimulator service exits observed during the run are classified as tooling interruptions because they do not reproduce on Aimee's phone and did not yield an app-process crash report.

## Ordinary phone evidence

All paths below are lossless audit captures in `docs/ui-audit-evidence/368x800/`.

| Surface | Evidence | Disposition | Concrete finding |
|---|---|---|---|
| Campaigns | `campaigns-ordinary.jpg`, `campaigns-empty-second-simulator.jpg`, `campaign-detail-second-simulator.jpg`, `campaign-delete-confirm-second-simulator.jpg` | revise | Empty state and detail ownership pass. Two-column faces are dense and `New Game` visually resembles a disabled control. Delete is correctly detail-owned and names the campaign/date/location, but the destructive button is visually ordered before Cancel despite the settled Cancel-first/default hierarchy. |
| Base Home | `base-home-ordinary.jpg` | pass | Compact context row, station grid, and persistent Party / Bind & Depart pair are clear. |
| Writing Desk | `writing-desk-ordinary.jpg`, `writing-desk-ordinary-2.jpg` | fail | Grid plus nested palettes overfill the viewport; palette choices clip below the phone, and primary departure ownership is not visible without ambiguous nested scrolling. Tutorial overlay further obscures the composing surface. |
| Party | `party-ordinary.jpg` | pass with populated-state follow-up | Satchel and people read clearly; large unused space is truthful for a two-person party. |
| Storehouse | `storehouse-items-ordinary.jpg`, `storehouse-resources-ordinary.jpg`, `storehouse-ordinary-2.jpg`, `storehouse-populated-second-simulator.jpg`, `storehouse-populated-dark-second-simulator.jpg`, `storehouse-populated-grayscale.jpg` | pass with P1 grayscale collision follow-up | Empty and fully populated 54/54 states fit the six-across grid. The semantic tree exposes every stored identity with name, tier, rarity, location, and quantity where applicable. Dark appearance preserves tile borders and icons. Literal grayscale preserves rarity through corner marks/line style, but several related weapon/tool silhouettes become close enough that identity depends heavily on detail/VoiceOver; retain the existing item collision review as P1. DEBUG reporter obscures cells but is not Release chrome. |
| Workshop | `workshop-ordinary.jpg` | pass | Five research families fit as compact cards without list-row bloat. |
| Essence Spring | `essence-spring-ordinary.jpg` | pass | Refine/Study/Unlearn hierarchy and exact disabled transaction are readable. |
| Library | `library-ordinary-2.jpg` | pass with populated-state follow-up | Four vocabulary tabs and empty state are clear. |
| Bestiary | `bestiary-ordinary.jpg` | pass with populated-state follow-up | Empty explanation and persistent search are clear; populated comparison/detail still needs render evidence. |
| World History | `world-history-ordinary.jpg` | pass with populated-state follow-up | Empty archive and persistent search are clear; populated two-column comparison already has separate fixture evidence but still needs live-state capture. |
| Settings | `settings-ordinary.jpg` | revise | Grouping is readable, but mixed chevron directions make navigation semantics look inconsistent; DEBUG bug control intrudes on Appearance in Debug. |
| Blacksmith | `blacksmith-ordinary-2.jpg`, `blacksmith-shield-detail-ordinary.jpg` | pass | Three-column Make grid and anchored transaction detail are compact and legible. |
| Trading Post | `trading-post-ordinary.jpg` | pass with populated-state follow-up | Buy/Sell ownership and truthful unresolved stock state are clear. |
| Recycler | `recycler-ordinary.jpg` | revise | Truthful empty state, but it reads as two paragraphs floating at the top rather than a deliberate task/empty hierarchy. |
| Apothecary | `apothecary-ordinary.jpg`, `apothecary-populated-second-simulator.jpg`, `apothecary-selected-second-simulator.jpg`, `apothecary-selected-dark-second-simulator.jpg`, `apothecary-selected-grayscale.jpg` | pass | Empty, 17-known, and selected-recipe states are readable. Three-column cards retain names and Ready/Needs stock status; the semantic tree follows visual row order and names every preparation/readiness state. Selection adds a persistent outline and exposes one `Prepare` action after the exact cost, surviving Dark and grayscale. Remaining recipes continue through ordinary vertical scrolling. |
| Firepit | `firepit-ordinary.jpg` | pass | Coming / At Home grouping and Send Home action read clearly. |
| Scriptorium | `scriptorium-ordinary.jpg` | pass | Currency, current hand, Art tier, and two sibling research families are compact. |
| Survey Post | `survey-post-ordinary.jpg` | pass | Measurement, pack, and Field Instruments hierarchy are distinct and readable. |
| Anchorage | `anchorage-ordinary.jpg` | pass | Requirements, deficits, disabled craft action, and empty realm state are understandable. |
| Distillery | `distillery-ordinary.jpg` | pass | Separate crystallise/core recipes and unavailable provenance are clear. |
| Channelworks | `channelworks-ordinary.jpg` | pass | First-fixture dependency and disabled construction are clear, albeit intentionally sparse. |
| Tannery | `tannery-ordinary.jpg` | pass with scroll follow-up | Construction choices and station research are clear; lower content intentionally continues in the scroll. |
| Bowyer | `bowyer-ordinary.jpg` | pass | Three distinct construction choices and one research family fit cleanly. |
| Armoury | `armoury-ordinary.jpg` | pass | Rebuild intent, legacy toggle, and research family are clear. |
| Weaponsmith | `weaponsmith-ordinary.jpg` | pass | Close-form choices, polearm dependency, and research family are clear. |
| Wayfarer's Table | `wayfarers-table-ordinary.jpg` | pass | Sparse screen is truthful and the two permanent route benefits are legible. |
| Constellation | `constellation-ordinary-2.jpg` | pass | One live star, wallet, shortfall, and Reality explanation are appropriately sparse. |

## Cross-screen findings

## Accessibility XXXL evidence

| Surface | Evidence | Disposition | Concrete finding |
|---|---|---|---|
| Campaigns | `settings-large-text.jpg`, `campaigns-large-text-top-second-simulator.jpg`, `campaigns-large-text-card-second-simulator.png` | pre-fix baseline; `af27316` unaccepted | The older installed build shows oversized, unequal controls, truncated supporting copy, and a campaign card that consumes nearly a full viewport. Because this binary predates `af27316`, these captures neither accept nor reject the equal-button checkpoint. |
| Party | `party-large-text.jpg` | fail | Satchel wraps into a broken three-line fragment and carried/stored count truncates; cards themselves remain understandable. |
| Essence Spring | `essence-spring-large-text.jpg` | fail | Three currency chips collapse into vertical one-character columns and obscure their values/labels. |
| Workshop | `workshop-large-text.jpg` | fail | The same three-chip collapse occurs; research content begins below a severely oversized purse. |
| Blacksmith | `blacksmith-large-text.jpg` | fail | Station identity, balances, and recipe names fragment across tiny columns; the grid is not usable at this size. |

These failures share one cause: ordinary multi-column/card layouts keep their fixed column counts while Dynamic Type expands content. Increasing font size without changing topology is not accessibility support. Required behavior is an explicit accessibility reflow: currency/status rows become one-per-row or horizontally scrollable named cards; three-column grids become one column or a topology-preserving detail list; compact summary copy moves into detail rather than scaling or clipping.

## VoiceOver order/actions — populated surfaces

The native semantic snapshots are treated as structural VoiceOver evidence; they do not prove speech pacing or rotor grouping.

### Storehouse 54/54

- Order begins with the visible six-across grid in row-major order after the Items/Resources/Waiting tabs.
- Each target announces exact player identity, tier, rarity, `Stored`, and quantity for stacks such as Chitin/Reagents.
- All 54 item targets are independently reachable; opening one remains the sole path to detail. No icon-only target appears.
- P1: 54 separate targets produce a long traversal with no observed filter/group shortcut beyond tabs. Validate rotor/group navigation before accessibility acceptance.

### Apothecary 17 known

- Order is visual row-major through every preparation, each announced as `Name, Ready` or `Name, Needs stock`.
- Selected Lesser Salve retains its visual focus outline; after scrolling, its exact cost precedes a separately reachable `Prepare` button with stable identifier `apothecary.craft.salve_lesser`.
- No hidden/unavailable action is exposed for Venom's `Needs stock` card.
- P2: preparation cards do not include family/category in the accessibility label; current unique names make this nonblocking.

## Writing Desk — rendered frame and state evidence

Evidence: `writing-desk-tutorial-present-ordinary-second-simulator.jpg`, `writing-desk-tutorial-absent-ordinary-second-simulator.jpg`, `writing-desk-write-large-text-second-simulator.jpg`, and `writing-desk-world-large-text-second-simulator.jpg` on the same 368×800 second simulator. No process, window, save, or native source was changed. These are findings against the older installed binary only, not evidence against newer source or unstaged Writing Desk work.

Measured rendered frames:

- The page frame remains approximately `x 26…342, y 107…473`, or 316×366, in ordinary and Accessibility XXXL renders.
- The ordinary category strip is approximately `x 11…357, y 478…522`, or 346×44. Palette content begins around y532, leaving about 268 points of vertically scrollable phone space.
- The tutorial card is approximately `x 11…357, y 220…367`, or 346×147. It covers about 40% of the visible page height without reflowing the page. Because it is explicitly dismissible and the page remains intact beneath it, classify this as P2 tutorial composition rather than a core authoring blocker.
- At Accessibility XXXL the category control expands to approximately `x 11…357, y 478…599`, or 346×121, because `Compounds` wraps and the menu chrome grows. Palette content begins around y614, leaving about 186 points; the first palette card is visibly clipped at the bottom.

Findings:

- Installed-build P1: Large Text Write preserves the page but gives almost half of the remaining lower viewport to category chrome, then clips the palette content. A provenance-pinned current build must be rendered before prescribing or closing a correction.
- Installed-build P0 accessibility finding: Large Text World breaks projection copy into narrow clipped columns and lets Bind & Depart dominate the lower surface. The primary projection text is not readable at the supported size; this is not yet a verdict on newer source work.
- Connect/Disconnect `off` is evidenced by the blank page. The `on` states are not passed: these actions appear only after a placed rune is held, and the current runtime accessibility tree exposes neither the drag ghost nor a coordinate-addressable placed-mark operation. This is an explicit rendered-evidence gap, not an inferred pass.
- The transient frame immediately after changing Dynamic Type showed the prior pane before settling; it was excluded from classification as a transition artifact.

## Campaigns — pre-checkpoint baseline only

Evidence: `campaigns-large-text-top-second-simulator.jpg` and `campaigns-large-text-card-second-simulator.png`, reached in the same process through Settings → Save games at Accessibility XXXL. The second Simulator still ran an older installed build; these captures predate source checkpoint `af27316` and therefore cannot accept or reject its equal-button correction.

- Pre-fix P0 baseline: Continue is a very wide capsule while New Game becomes a large rounded/circular mass, so the two peer actions do not share a coherent control grammar. Re-render exact `af27316` or later before assigning the current checkpoint a disposition.
- New Game's supporting sentence truncates to `Create a separate c…` despite the control occupying roughly 210 points of height.
- After one 55% upward scroll, the single campaign card uses almost the full viewport for Campaign 1 / Ready / Level 1 / Home / progression / date. The screen preserves semantics but loses compact shelf scanning.
- Runtime semantics still expose Continue and New Game as two correctly named buttons. In this pre-fix baseline the problem is layout and information density, not missing labels; `af27316` still requires its own installed render.

## Storehouse literal-grayscale collision families

The 54/54 grayscale sheet does not justify a universal item-art rewrite, but it does identify concrete families that require silhouette-level review at the native six-across size:

- Fine close edges: Bone Awl, Raking Edge, Binder's Edge, and Hairsplitter converge on narrow pointed/angled masses.
- Heavy heads and tools: Field Maul, Banded Mace, Anvilfall, Settled Argument, Bent Pick, Balanced Pick, Corebreaker, and Willing Edge share compact haft/head constructions; color and small interior marks carry too much identity.
- Broad edge/hook weapons: Chipped Blade, Keen Blade, Ripping Hook, Long Grievance, Barbed Edge, Living Hook, Quiet Knife, and Bloodletter form a dense blade/hook collision cluster in grayscale.
- Progression equipment families remain deliberately related but several adjacent tiers lean on value/detail more than outer mass: Split Board→Banded Buckler→Tower Guard→Unarguable; Padded Cap→Ridged Helm→Visored Casque→Crown; Padded Guard→Banded Guard→Vaultplate→Standing Wall; Wrapped Hands→Studded Gloves→Gauntlets of Hold→Sure Hands; Worn Boots→Shod Boots→Longstriders→Unhurried.

This is a P1 recognition finding only. Aimee's handmade item-art boundary remains authoritative; the audit records collision risk and does not prescribe replacement art.

## Dark appearance and literal grayscale

Evidence uses the current second simulator in Dark appearance without relaunching. Literal grayscale copies use the Generic Gray Gamma 2.2 profile rather than a simulated colour-blind palette.

- Base (`base-dark-second-simulator.jpg`, `base-home-grayscale.jpg`): section picker, station tiles, currencies, and Party/Bind hierarchy remain distinct. Large empty space is state-owned, not contrast loss.
- Storehouse (`storehouse-populated-dark-second-simulator.jpg`, `storehouse-populated-grayscale.jpg`): borders, focus/state marks, quantity badges, and compact bodies remain visible. Related same-slot bodies are a P1 identity-collision review, not a layout failure.
- Apothecary (`apothecary-selected-dark-second-simulator.jpg`, `apothecary-selected-grayscale.jpg`): card grouping, selected outline, readiness text/mark, exact cost, and Prepare ownership remain clear. The faint gray `Needs stock` state is still text-backed.

## Active-world second-simulator evidence

Evidence: `world-active-second-simulator.jpg`, `world-look-second-simulator.jpg`, and `world-field-kit-empty-second-simulator.jpg`, rendered at 368×800 on the separately running iPhone 17 Pro simulator after Aimee restarted both Simulator windows.

Closed from the prior lower-half report:

- The minimap has a square footprint rather than a squeezed rectangle.
- The satchel / Field Kit strip consumes the available width instead of leaving an unexplained black bar.
- Interact and Look retain readable text labels and independent wide targets.
- Look changes to an explicit bordered `Cancel Look` target without losing the Interact label.
- Empty Field Kit opens as a readable medium-height sheet with distinct Instruments and Consumables sections.

Resolved camera investigation:

- Saved run facts for this exact capture: map 18×18; player and entry at `(16,17)`; fixed viewport 11×11; clamped camera origin `(7,7)`, covering `(7…17, 7…17)`; 19 revealed tiles with bounding box `(13…17, 14…17)`.
- The origin is mathematically correct: `clamp(player - floor(11/2), 0…7)` produces `(7,7)`. The party is near the lower-right because the entry itself is at the south-east boundary.
- Every black cell in the square viewport is an in-map unrevealed tile. The viewport contains no out-of-map/background region, and revealed tiles retain the fixed cell scale.
- Therefore the prior P0 camera candidate is withdrawn. Retain a P1 presentation/generation-start question: a boundary entry plus only 19 initially revealed tiles makes most of the primary canvas read as featureless black and visually weights the known world into one corner. Any correction must preserve fixed tile scale and spatial consistency; do not auto-zoom or frame to the revealed bounds.

New P1 accessibility finding:

- The runtime accessibility snapshot exposes Field Kit, four movement controls, Interact, Look/Cancel Look, and the DEBUG reporter, but no terrain/tile inspection targets or current-party-position summary. The visual map is effectively absent from the semantic tree in this state. Verify whether the map canvas intentionally supplies a separate adjustable/custom action; if not, VoiceOver users cannot inspect the disclosed world even though the surrounding controls are labelled.

## Population and return-state attempt

The second-simulator campaign was populated only through existing DEBUG harness actions: `Grant every piece of gear`, `Prepare instrument crafting`, and `Prepare the Apothecary`. No save file, game rule, or native source was edited.

- Storehouse populated successfully and is covered above.
- Party remains a truthful two-person state and is already covered by `party-ordinary.jpg`; the harness does not add roster members.
- Apothecary preparation now has populated visual and semantic evidence. A selected recipe transaction remains a narrower follow-up, not a screen-level blocker.
- Trading Post and Recycler cannot be truthfully populated from the currently reachable harness/station state on this campaign. They remain evidence gaps rather than inferred passes.
- Library and World History require a completed return to become populated.

Resolved audit-tooling incident blocking the return evidence:

- The accessibility driver misrouted the reported Bind element reference to the Write tab; exact save inspection showed an eligible blank page, 500 Essence, no active run, seed issue count zero and no bind action in the mutation trail. Production binding was never invoked, so this is not evidence of a P0 binding failure.
- Source still had an independent silent stale-refusal path. Engineering checkpoint `a543796` gives every current refusal an exact rules-owned reason with 29/29 focused and 1,153/1,153 full tests green; that newer source was not installed for these captures. Run-return evidence remains uncollected rather than product-blocked.

### P0 — must be corrected or proven before calling the UI complete

1. Writing Desk Large Text is broken in the older installed build. A provenance-pinned current candidate must be rendered before prescribing or closing a correction.
2. Large Text failures are evidenced on the older installed build across multiple shared components. Each newer source checkpoint still requires its own exact-build render; existing AssetLab proofs are not substitutes for native renders.

World lower controls are closed by the second-simulator render. Camera origin/clamping is also verified correct; the remaining World concern is P1 starting placement/fog composition, not a P0 viewport defect.

### P1 — important follow-up states

- Install and render Campaign checkpoint `af27316` at ordinary and Accessibility XXXL before disposition.
- Render populated Bestiary, Library, History, Trading Post, Recycler, and remaining Party/detail states. Populated Storehouse and Apothecary are covered.
- Normalize navigational chevrons and other direction cues in Settings.
- Give Recycler a deliberate empty-task composition rather than ungrouped paragraphs.

### P2 — polish after functional evidence

- Several truthful sparse stations have large blank regions. Do not fill these with decorative art automatically; revisit only if the empty space harms action discovery in populated states.
- DEBUG bug-report placement collides with content on several screens. This is not a Release blocker, but the DEBUG affordance should edge-clamp away from controls and text.

## Not yet covered

- Encounter and combat action/detail states.
- Run-return recap and anchorage settlement sheets.
- Populated/detail variants noted above.
- Exact-build re-render of newer Campaign and other responsive-layout checkpoints at Accessibility Large / largest supported Dynamic Type.
- Structured VoiceOver reading order and action labels.
- Dark appearance and literal grayscale sampling beyond Base, Storehouse and Apothecary.

No whole-app completion claim is valid until those rows have rendered evidence.
