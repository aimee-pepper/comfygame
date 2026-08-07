# Handoff — 7 docs. Nothing here has landed yet.

Verified against commit `0a84023` ("Write books on the page"). Sessions 1–9 of the decisions log are in the repo; **everything below is new to you.**

## ⚠️ Three corrections to the page grid you just built

The grid landed before session 10 reached you. Three things need changing:

1. **The page NEVER grows.** `Tuning.Page.startingWidth/Height` implies a growth model — there isn't one. `writing-system-rune-spec.md` §3 previously said "expanded by permanent unlocks"; **that was Claude's invention and it was wrong**, and it contradicts the instrument ladder. Corrected spec is in this bundle. One fixed page, forever; progression is writing *smaller* on it. Suggest renaming to `Page.width/height` so nothing reintroduces growth later.
2. **Placed runes must be pick-up-and-moveable.** Currently tap-to-place and tap-to-rub-out only. Arranging should be **exploratory and free** — moving a placed rune costs nothing, and you can shuffle the page as much as you like before binding.
3. **A rune that won't fit should GLOW RED and not be counted** — not be greyed out and disabled in the palette. You should be able to reach for it and see it refuse, rather than have it quietly unavailable.

Also: **the page must fit on one screen, no scrolling.** 6×6 is fine if it fits comfortably on device with the projection visible.

## New decision docs

| File | Contents |
|---|---|
| `decisions-session-8.md` | **"Opacity was Mystcraft's failure" is struck from all docs** — opacity is the joy; explanation must not be front-loaded · secondaries are **discovered, not printed on runes** · **analysis is a third progression axis** · **instruments**: field instruments measure worlds you stand in, the page lens predicts and only shows what you've already measured, readings are **permanent knowledge** |
| `decisions-session-9.md` | **The Atlas** — it anchored the realms, was stolen and destroyed, and that caused the sundering. Rebuilding it **is** the great work · progress measured in **realms re-anchored** · **the cult** · **FINALITY RULE (a pillar): nothing the player has completed can ever be reversed** |
| `decisions-session-10.md` | The three page-grid corrections above, plus: **compound glyphs are assembled in a popup** inside the page-writing menu, and **assembly is unlocked in the skill tree** |

## Audits

| File | Contents |
|---|---|
| `full-audit-built-vs-specced.md` | **Replaces `design-audit-session-5.md`'s scope.** That audit only checked decided rules and missed that half the specced game doesn't exist. This one has the built-vs-specced table, five bugs, and the dependency order. |
| `audit-claude-invented-assumptions.md` | Things the designer Claude **stated as fact that Aimee never decided**, tiered by how much rests on them. The page-size error was one of these. Tier 3 items should be re-tagged as proposals in the docs. |

## Updated

| File | Change |
|---|---|
| `writing-system-rune-spec.md` | §3 corrected: fixed page, one screen, runes moveable. **Replaces the repo copy.** |
| `narrative-systems-spec.md` | §5 marked superseded by session 9. |

## Bugs from the audit, in priority order

1. **The description reveals rolled content** — chance-filled slots are spoiled before departure. Violates a locked decision.
2. **Contradictions cost nothing** — `ContradictionRules.penalty` is written, tested, and never read by the stability headline. Hence *Green in the dark* alongside Stability 100.
3. **`holds ~9999 turns`** — sentinel leaking into the UI.
4. **Q17 not actioned** — ruins still pay essence (1 / 4 / 3). Should be 0; landmarks and living sites keep theirs.

Note on rolling unwritten targets: **that behaviour is correct and stays.** The problem was only ever that four slots couldn't cover eight targets — which the page grid fixes.
