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
- Informational copy uses roughly 75% plain, warm language and no more than 25% storybook flavour. A player should understand the practical meaning on the first read.
- Character dialogue and recovered book prose may keep each writer's distinctive voice. Directory labels, summaries, instructions, availability messages, tables, and rules must never hide their meaning behind that voice.
- Development shorthand such as “route published,” “custody,” “stale quote,” “receipt owner,” “retained identity,” and “committed result” is translated into the action a player sees: available in the game, stored or carried, review the changed preview, saved result, same selected item, and what happens after confirmation.
- Content that is accepted but not yet playable begins with a visible `Planned` label and describes the intended player experience. It is never phrased as a missing “published route.”
- `scripts/sync-content.mjs` creates a sanitized, read-only player snapshot from implemented content and copies only the related visuals used by these pages. It is not a runtime asset catalogue or source of gameplay truth.

## Local use

```sh
npm install
npm run dev -- --port 4179
```

The Player Wiki is then available at `http://127.0.0.1:4179/`. Run `npm test` for the focused architecture/content checks and `npm run build` for the production build.
