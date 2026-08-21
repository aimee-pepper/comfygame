# Bookbinder Internal Wiki

Private, repo-local reference generated from Bookbinder's source authorities. It is not a public site and
must not become a second design authority.

## Regenerate

```sh
cd GameWiki
npm run generate
```

`npm run check` fails when an input file, input schema, source registry, or generated output has changed
without regeneration. `npm test` checks provenance, search coverage, routes, and deterministic generation.
`npm run build` creates the local static site in `GameWiki/dist/`; `npm run serve` serves it at
`http://127.0.0.1:4178`.

Current pages prefer `*-current.md` authorities. Decision logs and archived documents appear only under
Decisions / History and never override current pages.
