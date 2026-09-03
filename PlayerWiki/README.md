# Bookbinder Player Wiki

This is the public, player-facing Bookbinder wiki. It is deliberately separate from `GameWiki`, which remains the internal design and implementation reference.

## Architecture

- The home page starts with player tasks and core systems.
- Subject directories follow one progressive-disclosure standard: a brief introduction, a compact icon-and-name index, a medium-detail comparison, then rules shared by the whole category.
- The compact index and medium comparison both link to the same canonical detail pages. They are useful alternate routes, not duplicate essays.
- A category-wide rule appears once on its category page and is linked where relevant. A second route may point to that owner, but must not maintain a competing copy.
- Every detail page is the complete canonical record for its subject. Any fact summarized in an index or comparison must also appear on that subject’s detail page, together with its remaining acquisition, use, state, custody, progression, and boundary facts.
- Directory summaries never replace detail. A player who opens one resource, item, person, place, recipe family, creature, site, action, condition, technique, terrain, Flora profile, or world condition must be able to learn everything the Wiki publishes about that subject without returning to its directory.
- Desktop directory pages use the available viewport width with modest edge gutters and left-anchored navigation. The sidebar and article have independent vertical scroll regions; narrow screens return to one ordinary document flow.
- Visuals sit on the pages for the things they depict; there is no separate visual-assets section.
- Internal source paths, provenance, stable identifiers, roadmap status, and decision history are excluded from the player surface.
- `scripts/sync-content.mjs` creates a sanitized, read-only player snapshot from implemented content and copies only the related visuals used by these pages. It is not a runtime asset catalogue or source of gameplay truth.

## Local use

```sh
npm install
npm run dev -- --port 4179
```

The Player Wiki is then available at `http://127.0.0.1:4179/`. Run `npm test` for the focused architecture/content checks and `npm run build` for the production build.
