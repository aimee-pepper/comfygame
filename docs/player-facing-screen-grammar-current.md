# Player-facing screen grammar — current audit and correction order

**Status:** current UI authority for replacing the “series of lists” presentation; implementation is
playability-ordered rather than a single broad redesign.  
**Owner:** Game Design; Engineering owns native composition; Asset Design owns functional UI,
layout and accessibility grammar. Aimee owns final handmade pictorial identities under
`handmade-art-ownership-current.md`.  
**Updated:** 10 Aug 2026

## Player complaint and audit conclusion

Most Home screens historically used full-width rows/cards even when their contents were physical
objects, people, places or learned abilities. Changing those rows to two columns improved density but
did not change the interface language. The game should read as a set of **places, collections and
objects**, not nested settings menus.

The correction is not “remove every list.” Ordered prose, priority rules and diagnostic controls are
genuinely list-shaped. The rule is semantic:

> If the player is choosing **a thing**, show the thing first. If the player is reading **an order or
> argument**, preserve the order. If the player is moving **between places**, show spatial
> destinations.

## Settled component grammar

### Physical objects — six-across icon tray

Use for equipment, loot, consumables, resources, curios, shop stock and recyclable candidates.

- six square icons across at ordinary phone width;
- each remains an independent target of at least 44×44 points even if the visible art is smaller;
- quantity, equipped/location, eligibility and rarity use separate corner/frame shapes;
- no permanent item name beneath every icon;
- tap opens one compact detail/preview popover anchored to that icon with name, provenance, numbers
  and legal actions; ordinary item inspection does not navigate to a new screen;
- unknown objects use a restrained unknown silhouette and never leak their resolved family;
- grayscale and VoiceOver convey every state without relying on colour.

This grammar is already live for Storehouse Items/Waiting, equipment candidates and expedition loot
through `a77c9dd`. Resources and consumables must converge on the same contract rather than inventing
parallel grids.

#### Anchored item detail

- The popover points to or otherwise retains a clear visual relationship with the selected icon.
- Placement is collision-aware. It prefers above/below the item, then shifts inward so its complete
  body and arrow remain inside horizontal safe areas, navigation bars, fixed controls and the keyboard.
- Items on the bottom row or screen edges must never produce a clipped or off-screen popover; the
  container may choose the opposite edge or scroll the minimum amount needed before presenting.
- Only one item detail is open. Tapping another icon retargets it without pushing navigation; tapping
  outside or the explicit close control dismisses it and returns focus to the source icon.
- Destructive or state-changing actions remain explicitly labelled inside the detail and use their
  settled confirmation rules. Merely opening/dismissing detail changes nothing.
- The anchored form is the ordinary-phone interaction. Accessibility sizes may use a compact sheet
  when the same information and 44-point actions cannot fit without clipping; this fallback returns
  to the exact originating collection position.

### People and creatures — identity tiles

Use for Party, roster, Bestiary, traveller indexes and companion assignment.

- portrait/silhouette, name and one or two current-state badges;
- two or three columns depending on readable target size, never six anonymous faces;
- tap opens a dedicated person/species page with tabs;
- do not display equipment, gambits, stats and biography simultaneously on the collection surface.

Party and Bestiary have the first spatial shells. Library People will distinguish clues **about** a
person from pages **written by** them per `library-collection-accuracy-current.md`.

### Places and stations — destination board

Use for Base and anchored-world destinations.

- persistent illustrated destination tiles with construction/damage/attention state;
- the primary travel/work verb is attached to the place, not buried in a disclosure row;
- unavailable stations remain absent until known or appear as a truthful construction site—not a
  generic locked menu item.

Base has the first destination board. Trading Post uses the shared station identity but its stock is
a physical-object tray.

Primary transaction controls such as **Bind & Depart** use one rules-owned current evaluation for
both visible availability and commit. If eligibility changes after rendering, activation presents
the fresh exact refusal in place; it never flashes and silently returns unchanged. See Decision229.

The complete Base board contract is in `base-destination-board-current.md`: Home/Make/Study/Realms
tabs, three compact place tiles across at ordinary phone width, construction as a tile lifecycle,
explicit section-local order and one persistent compact Party/Bind & Depart bottom row. Party and
app utilities are not fictional station tiles. A single two-column scroll of every unlocked station
is transitional, not the intended long-campaign presentation.

### Recipes, techniques and research — compact choice tiles into detail

Use for Blacksmith families, Apothecary recipes, combat skills and research subjects.

- two to four columns depending on information density; six is reserved for already-recognizable
  physical inventory;
- tile shows family glyph, output/technique identity and readiness;
- tap opens requirements, comparison, preview and confirm;
- dependency order may become a tree/branch inside detail, but the landing screen is not a long list
  of every node and requirement.

`maker-station-screen-grammar-current.md` defines the reusable native flow: station verb tabs,
three-column recipe/profile tiles, six-across exact-object stock, one persistent result/requirements/
stock/commit detail and rules-owned readiness/cost. Blacksmith is the first checkpoint.

### Ordered logic and authored text — lists remain correct

Lists are retained when sequence is the mechanic:

- Gambit priority order and drag/reorder;
- conversation transcript;
- diary prose within an opened book/page;
- world-history chronology and comparison evidence;
- combat log;
- DEBUG atlas, tuning controls and diagnostics.

These surfaces still use tabs, filters and progressive disclosure where their lists grow. “Lists are
valid here” does not permit full-width cards containing unrelated actions.

## Screen audit and implementation order

| Priority | Surface | Current shape | Required correction |
|---|---|---|---|
| **P0 blocker** | Trading Post | New implementation in flight | Six-across stock/sell tray; tapped preview/confirm/result; gold and stock-refresh context persist outside item names |
| **P1 installed verification** | Storehouse Items / Waiting | Six-across in `a77c9dd` | Device test quantities, location badges, large text and full-detail access |
| **P1 installed verification** | Equipment and expedition loot | Six-across in `a77c9dd` | Device test exact worn/stored/waiting identity and compact target reachability |
| **P1** | Library | Two-column identity tiles, then prose cards | Add Diaries/People dual index and page-kind icon grid; keep opened prose text-led |
| **Queued resource UI pass** | Storehouse Resources | Dense vertical rows that manufacture scrolling | Shared six-across resource silhouettes; quantity badge on every tile; tap detail names properties, provenance and uses; ordinary 23-resource collection is browsed as a compact icon atlas rather than a ledger; do not promote this layout correction over current blockers |
| **P1** | Field satchel resources | Compact horizontal quantity strip | Reuse the same resource silhouettes and detail resolver without making the world HUD a second Storehouse |
| **P1** | Consumables / combat items | Full-width action rows | Six-across recognized-item tray; choosing one opens legal target step without duplicating its full description |
| **P1** | In-world Field Kit | Full-width instrument and supply rows | Instruments/Supplies tabs; compact tool tiles plus six-across carried supplies and anchored use/detail; exact carried snapshot only |
| **P1** | Blacksmith and specialist makers | Long recipe/result lists | Family tiles → recipe detail → material tray → preview/confirm; preserve comparison as a detail table |
| **P1** | Apothecary | Recipe rows | Compact recipe tiles grouped by purpose; ingredient and effect prose on tap |
| **P1 after immediate checkpoints** | Item detail navigation | Full-screen/new-screen detail for a tapped inventory icon | Replace with collision-aware anchored popover; preserve explicit actions and exact grid position |
| **P2** | Combat action selection | Modal skill/item lists and implicit ally target | Use `combat-action-palette-current.md`: in-stage technique/item grids, one explicit target grammar, DRQ-159-approved confirmed retreat and actor-scoped Direct/Gambits; logs stay ordered text |
| **P2** | Anchored realms / assignments | One full-width card per realm plus unfiltered person menu; unchecked settlement can dormant all | Use `anchorage-portfolio-assignment-current.md`: Atlas/Work/Deliveries, realm and person tiles, before→after posting consequences and explicit per-realm settlement choices |
| **P1 correctness / P2 presentation** | Firepit / Tavern | Roster rows call every non-party person “around the fire”; party selection can leave realm assignment intact | Use `community-party-tavern-current.md`: fixed departure positions, location-grouped community tiles, atomic displacement preview and persisted visitor tiles |
| **P2** | World history | Chronological full-width record cards; comparison tutorial-owned | Use `world-history-collection-comparison-current.md`: compact frozen covers, explicit two-record selection and shared comparison detail; chronology remains a sort, not the item shape |
| **Keep** | Gambit editor | Priority list | Sequence is the mechanic; strengthen rule glyphs and drag/readability rather than grid conversion |
| **Keep** | Traveller meeting | Ordered transcript + choices | Preserve transcript order and independent branches; choices may be compact buttons, never reordered history |
| **Keep** | DEBUG screens | Lists/forms | Developer information density is appropriate; correctness and search outrank game-like decoration |

## Asset boundary

The item grid cannot depend on SF Symbols as final identity. Each tangible family needs a small,
stable pictorial silhouette recognizable without its label. Generated variation may alter material,
finish and quality inside that authored family silhouette; it must not turn every instance into a
new icon the player has to relearn.

Minimum order after the Trading Post proof:

1. common equipment and merchant stock;
2. all 23 world resources and Raw Essence;
3. consumable families and unidentified curio restraint;
4. recipe-family glyphs for maker stations;
5. combat technique glyphs only after the action palette is specified.

## Interaction and accessibility invariants

1. Six visible icons do not mean six narrow tap targets; each target remains 44×44 points.
2. Tapping a selected tile again never performs a destructive action. Sell/recycle/craft/equip require
   an explicit labelled action in detail or confirm.
3. Detail dismisses back to the same tab, filter and scroll position.
4. A state change updates the tile and detail atomically; stale detail cannot act on a replacement
   instance.
5. VoiceOver names object, quantity, location, eligibility and selection before available actions.
6. Large text may reduce columns rather than clip names or actions; the ordinary six-across target is
   not a mandate under accessibility sizes.
7. Empty states explain the next player action and do not present a decorative grid of unknown slots.
8. **Do not manufacture scrolling.** At ordinary phone size, a finite primary collection that can fit
   in the available viewport must fit without clipping or scrolling. Tiles divide the measured usable
   space after navigation, tabs and safe areas; they do not keep an arbitrary oversized minimum
   height that pushes the final row beyond the screen.
9. Scrolling is reserved for genuinely variable or detailed content. A normal five-person Party hub
   must show all five member tiles simultaneously on 368×800, with names and essential state intact.
   Large Text may reflow or scroll rather than shrinking text below accessibility requirements.
10. Storehouse Resources uses the same ordinary six-column target geometry as Storehouse Items.
    Resource quantity is visible on the icon; name, properties, acquisition notes and uses appear on
    tap. The resource collection may scroll when its full catalogue genuinely exceeds the viewport,
    but must not spend one full-width row per resource.
11. Existing tutorial prompts are hovering overlays, never layout children or safe-area insets.
    Showing one cannot change the underlying page/map frame, fixed controls or scroll geometry.
    Large Text may enlarge and scroll the overlay itself without reflowing the page beneath it.
12. A transient page tool owns only the page interaction in which it was selected. Connect and
    Disconnect clear their pending endpoint/error on an off-page interaction, page change,
    navigation or dismissal; returning never preserves a hidden mode. Cancelling the mode does not
    prevent an intentional tab, navigation or palette action from proceeding.
13. A fixed primary-action footer may remain reachable, but it cannot consume the screen at the
    expense of the content needed to make that decision. At accessibility sizes, horizontal summary
    rows reflow into one- or two-column semantic groups before their text becomes narrow vertical
    strips. Header labels and trailing explanations may stack. The action keeps a 44pt target and
    concise cost/state; explanatory prose belongs in the scrollable decision content or a compact
    footnote, not a permanently oversized footer.

## Checkpoint discipline

Do not commission a whole-app visual rewrite while core loops are moving. Convert one semantic family,
prove it on 368×800, grayscale and large text, then reuse the component. The Trading Post is the first
complete economy proof. Library accuracy and resource trays are the next player-trust corrections;
maker stations follow because their current lists are usable but visually poor rather than blocking.

Every phone proof records whether the ordinary state fits without unnecessary scrolling. “All controls
are technically reachable by scrolling” is not acceptance when the same content can fit legibly in one
viewport.
