# AssetSources

This directory is the human-facing intake root for visual source files authored by Aimee.
It is designed for Finder and Xcode browsing; hashes belong in receipts, never in filenames.

## Path convention

Place a source only at:

```text
AssetSources/<Pack-vN>/<stable-id>/<variant>/source/<semantic-name>.<ext>
```

- `<Pack-vN>` is a semantic pack name ending in `-v` and a positive version number.
- `<stable-id>`, `<variant>`, and `<semantic-name>` use lowercase letters, digits, and hyphens.
- A pack has exactly one `aimee-authored-source-receipt.json` at its root.
- The receipt lists every source file and its SHA-256. See `_templates/`.

Do not put generated runtime derivatives, review evidence, temporary exports, hash-named files,
or copy-suffixed files here. Deterministic, procedural, rectangle-command, canvas, or vector output
is not generated final art and cannot be classified as Aimee-authored merely by being copied here.
Existing files with ambiguous provenance must remain where they are until authority is resolved.

## Authority boundary

This root is editable source intake, not a runtime resource, gameplay catalogue, approval record, or
promotion mechanism. `project.yml` and the generated Xcode project must not package it. A valid
receipt establishes only explicit Aimee authorship of the listed source bytes; runtime promotion
still requires the separate content-bound provenance and approval gates.

GameWiki may read entries whose receipt explicitly sets `gameWikiDisclosure` to `disclosed`, but
that view is derived and read-only. It never becomes gameplay or source authority.

Run both checks after adding a pack:

```sh
python3 Scripts/verify_asset_source_intake.py --check
python3 Scripts/verify_repository_organization.py --check
```

