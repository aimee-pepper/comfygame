# Remaining native list surfaces — playability audit

**Status:** current Game Design audit; implementation order follows the live roadmap rather than this
document.
**Reviewed:** 11 Aug 2026 against native `List`/`Form` uses.
**Purpose:** continue the settled correction that Bookbinder cannot feel like a stack of full-width
menus, without replacing lists where sequence or exact comparison is the mechanic.

## Result

Most remaining `List` declarations are not outstanding collection-layout failures. Many now live
inside an anchored detail/confirmation, a DEBUG screen or an ordered evidence surface. Three real
player-facing collection/action failures remain:

1. combat technique/item selection;
2. in-world Field Kit presentation;
3. maker profile and exact-stock pickers inside otherwise improved station flows.

These are separate contained checkpoints. They do not justify a broad rewrite, tutorial work or
reopening the six-across inventory decision.

## Must change

### 1. Encounter technique and item sheets

**Native evidence:** `EncounterView.SkillSheet` and `CombatItemSheet` remain full-screen `List`
surfaces. Items repeat once for every living ally.

**Current authority:** `combat-action-palette-current.md` / DRQ-147.

**Correction:** keep the stage visible; techniques use a compact pictorial palette; items use the
six-across carried tray; one rules-owned target step follows selection. An item appears once, never
once per ally. This remains after true-tree mechanics and DRQ-159/160 naming/ownership review; it
does not gate the graph itself.

### 2. In-world Field Kit

**Native evidence:** `WorldView.FieldKitSheet` is a full list of instrument rows followed by
consumable rows.

**Current authority:** `consumable-economy-field-kit-current.md` / DRQ-151.

**Correction:** use **Instruments / Supplies** tabs. Instruments are compact tool glyph tiles with
carried/available state; Supplies is the six-across exact carried-item tray. A selected tile opens
anchored effect/use detail and remains visible after cancellation. The sheet is a compact inventory,
not a second Storehouse and not prose under the D-pad/minimap.

In-run selection may use/inspect only the exact carried snapshot. Home loadout editing remains a
separate saved desired-quantity transaction.

### 3. Maker profile and stock selection

**Native evidence:** top-level specialist stations have improved, but `ArmouryTargetSheet` still
lists rebuild profiles as full-width rows, while `SamplePicker` lists every exact world-resource
sample. Similar preview/confirm screens use `List`, correctly, as detail tables.

**Current authority:** `maker-station-screen-grammar-current.md` / DRQ-143.

**Correction:** rebuild/profile choice is a three-column tile grid. Exact eligible stock is a
six-across resource/sample tray with grade/selected badges and an anchored source/property detail.
The persistent preview/requirements/shortfall/confirm region may remain a labelled vertical detail
table because comparison and transaction safety—not browsing—is its mechanic.

Do not convert every recipe requirement into a separate navigation destination. Selection updates
the same rules-owned preview in place.

## Lists/details that should remain

| Surface | Disposition | Why |
|---|---|---|
| Gambit editor | **Keep ordered list** | top-to-bottom priority is the mechanic; add drag handles/glyphs, not a grid |
| Combat log and conversation transcript | **Keep ordered list** | chronology and speaker/action order are evidence |
| Opened diary/page and detailed World History record | **Keep text-led detail** | prose/record sequence is the content; the landing collection is already a cover grid |
| Material Bin | **Keep sortable comparison list** | individual samples are compared by grade, provenance and property; it is not a family icon atlas |
| Item/resource/loot/Trading Post detail | **Keep compact labelled detail** | these are selected-object popovers/confirmations, not collection landing screens |
| Reforge/build/recycle/sell preview | **Keep labelled transaction table** | exact before→after, spend and consequence need ordered confirmation |
| Campaign-slot detail and destructive actions | **Keep compact detail/form** | one selected campaign, recovery state and destructive safety |
| Station foundation build sheet | **Keep compact detail/form** | one selected place and one atomic build decision |
| Settings, DEBUG Roadmap, balancing, text atlas, diagnostics and bug report | **Keep list/form** | developer/settings information density is intentional |
| TutorialCard | **No work** | tutorials are dead last and cannot become filler for this audit |

## Follow-up distinctions

- A SwiftUI `List` inside an edge-clamped anchored detail is not automatically a layout defect. The
  defect is using full-width prose rows as the primary way to browse a collection or choose among
  pictorial objects/actions.
- “Six across” applies to recognized physical objects/resources at ordinary phone width. Technique
  and recipe tiles use fewer columns so their glyph/name/state remain legible.
- Large Text may reduce columns. It must not restore one giant prose card per inventory object.
- Final item art is currently reserved by Aimee. Layout may use existing stable identities while
  preserving the adapter boundary; this audit does not authorize new AssetLab item art.

## Acceptance

1. The only ordinary full-width lists left in combat/world/maker selection are mechanically ordered
   evidence or transaction details.
2. Technique/item/Field Kit/profile/sample collections retain stage/context and selected position;
   cancellation does not navigate or scroll the player away.
3. Every object/action target is at least 44×44 points and anchored details clamp/flip at all edges.
4. VoiceOver reads collection identity/state before optional detail; item target choice is separate
   from item identity.
5. DEBUG and tutorial work cannot be used to claim these ordinary gameplay surfaces complete.
