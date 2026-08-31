# Bookbinder Player Wiki

This is the public, player-facing Bookbinder wiki. It is deliberately separate from `GameWiki`, which remains the internal design and implementation reference.

## Architecture

- The home page starts with player tasks and core systems.
- Resource, equipment, consumable, curio, person, and place indexes use compact comparison tables that link to individual pages.
- Visuals sit on the pages for the things they depict; there is no separate visual-assets section.
- Internal source paths, provenance, stable identifiers, roadmap status, and decision history are excluded from the player surface.
- `scripts/sync-content.mjs` creates a sanitized, read-only player snapshot from implemented content and copies only the related visuals used by these pages. It is not a runtime asset catalogue or source of gameplay truth.

## Local use

```sh
npm install
npm run dev -- --port 4179
```

The Player Wiki is then available at `http://127.0.0.1:4179/`. Run `npm test` for the focused architecture/content checks and `npm run build` for the production build.
