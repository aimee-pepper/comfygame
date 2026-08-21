# Party and character surface — current

**Status:** Game Design implementation authority for ordinary Party navigation and its combat-tree entry.
It does not redefine combat-tree topology, equipment ownership or Gambit rules.
**Priority:** opening campaign UI correction alongside the production true-graph migration; before adding
late-game character administration surfaces.
**Owners:** Game Design owns information architecture and wording; Engineering owns native routes and exact
state; Asset Design owns compact identity/body/graph composition; Aimee owns phone acceptance.
**Updated:** 21 August 2026

## Party collection

The Party root is a compact two-column identity grid. All five ordinary departure positions must fit
within the usable 368×800 region without oversized full-width person buttons or arbitrary minimum-height
cards.

Each occupied tile shows:

- portrait/identity silhouette;
- name;
- current/max health;
- level;
- explicitly labelled rank (`Rank · Front`, `Rank · Middle` or `Rank · Back`);
- at most one consequential badge: point ready, equipment attention or passed out.

An empty position is one compact **Empty** tile. Party replacement/assembly remains its existing explicit
flow; tapping an empty tile does not invent a random recruit or silently move someone.

## Character detail tabs

Use exactly four stable tabs:

1. **Stats** — role summary, current/maximum health, level/XP, rank, derived stats and calling identity.
2. **Gear** — body/slot equipment and the six-across exact-source tray under existing ownership rules.
3. **Skills** — the character's actual combat skill trees and legal node purchase/respec surface.
4. **Gambit** — ordered combat actions/conditions; it remains a list because order is the mechanic.

There is no generic **Story** tab. A clearly labelled **Diary** action in the character header opens that
person's diary/dossier at Library → Diaries. Back returns to the same person and previously selected tab.
If no diary has been encountered, the action may open the honest empty/unknown dossier; it must not invent
biography or leak missing pages.

There is no **Combat** tab. The thing previously meant by that label is the combat skill tree, so its
player-facing name is **Skills**. Actual combat loadout details belong inside Skills/Gambit/Gear rather than
a fifth vague category.

## Skills tab composition

- Header: person identity, unspent combat points and tree selector **Offense / Defense / Craft**.
- Body: stable true graph from `combat-tree-v2` authority, preserving node positions while detail opens.
- Footer/key: `1 point per node · solid line prerequisite · dashed line alternate hybrid route`.
- Tapping a node opens anchored detail kept within screen edges. Learn/Respec uses typed legal
  transactions; successful changes mutate exact stable node ownership and point balance once.
- The production surface may not fall back to branch cards, `Learn next`, a linear list or a DEBUG-only
  explorer after migration.

## Meaning of an alternate cross-discipline prerequisite

Each tree contains three disciplines. Normally a later node opens through a parent in its own discipline.
Some authored nodes also accept **one specific node from a neighboring discipline as an alternative
parent**. This is an OR rule:

> own the solid-line same-discipline parent **OR** own any one named dashed-line alternative parent;
> then spend a point to learn the destination node.

It is not an additional AND requirement, a second point cost, a free learned node, a generic “own anything
next door” rule or permission to jump to a capstone.

Concrete Offense examples from the current graph:

- **Steady Hand** opens from its solid Precision parent **Weak Point**, or the dashed Force alternative
  **Overbear**.
- **Second Wind** opens from its solid Swiftness parent **Light Touch**, or the dashed Precision alternative
  **Pry**.
- **Bracing Stance** opens from its solid Force parent **Follow Through**, or the dashed Precision
  alternative **Pry**.

The graph shows the exact dashed connection and node detail says `Requires Weak Point OR Overbear`; it does
not use the phrase “cross-discipline prerequisite” as unexplained player copy.

Capstone discipline commitment remains governed by the accepted tree authority. An alternate parent helps
form a hybrid route but does not waive the same-discipline commitment required for that discipline's
identity/capstone.

## Gear tab

The character silhouette/slot diagram remains visible above a six-across icon tray. Each candidate is an
exact owned instance and carries a location badge: Stored, Overflow, Worn by Name or Carried. Carried gear
is read-only at Home until an explicit mid-expedition loadout rule exists.

Tapping a tray icon opens anchored detail positioned inside the viewport; it does not navigate to a full
new item page. A successful equip is an atomic exact-instance transfer and reports success before closing
detail. Stale/failed sources leave the view and inventories unchanged.

## Stats and role presentation

Stats should answer “what kind of person/build is this?” before exposing a ledger. Lead with:

- calling/role;
- current weapon/armour family silhouettes;
- attack/defence/craft tendencies produced by actual owned nodes and gear;
- health and rank.

Detailed numeric derivation may open from an anchored `Details` surface. Do not permanently list every
base, gear, skill and status term on the primary tab.

## Asset Design packet

1. Full 368×800 Party grid with five people, one point-ready badge and all rank labels.
2. Character Stats/Gear/Skills/Gambit shell proving tab stability.
3. Skills graph at native size with solid vs dashed connectors, owned/available/blocked/current-detail
   states and no node-label collision.
4. Gear body/slot plus six-across tray and edge/bottom anchored detail.
5. Color and grayscale/value sheets. Nodes/connectors cannot depend on color alone.

Asset Design must use the generated graph identity/layout inputs. It may not add a recommended path, story
tab, fourth tree, prerequisite type, unearned node or decorative statistic.

## Engineering checkpoints

1. Rename/detail route shell to the exact four tabs; add Diary deep-link/back restoration. No combat-rule
   changes.
2. Compact Party collection and retain the existing atomic party-position rules.
3. Integrate persisted arbitrary stable-node ownership and typed atomic legal purchases/migration.
4. Promote the accepted true-graph renderer as production Skills; remove/fence the ordinary linear
   `Learn next` surface.
5. Integrate exact alternate-parent display and anchored node detail from the rules-owned graph.
6. Integrate body/slot Gear layout and six-across exact-source tray without changing ownership semantics.
7. Capture a fresh character, hybrid-route character and five-person party on physical phone.

## Acceptance

1. All five party positions fit without scrolling solely caused by oversized person cards.
2. `Story` and ambiguous `Combat` do not appear; Diary and Skills routes behave exactly as above.
3. Diary back returns to the originating person/tab.
4. Dashed alternatives are OR requirements and never learn the destination for free.
5. A legal node purchase costs one point and survives relaunch; stale/illegal purchase costs nothing.
6. Production Skills is a real graph, not three disguised vertical lists.
7. Gear detail remains on screen for every edge/bottom icon and returns to the same scroll position.

## Explicit exclusions

- no relationship/affinity screen;
- no biography generator;
- no tutorial popup or guided first-point flow;
- no new combat tree or topology redesign;
- no mid-expedition equipment mutation;
- no automatic skill recommendations.
