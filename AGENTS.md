# Bookbinder Agent Instructions

## Fixed UI Configuration — Direct Aimee Override

Bookbinder is designed, implemented, reviewed, and tested for one fixed UI configuration only: native
368×800 at the standard/default text setting, unless Aimee explicitly replaces that target.

- Do not perform, assign, queue, recommend, or require accessibility-specific work.
- Do not implement or audit Dynamic Type variants, accessibility or XXL text sizes, adaptive layouts for
  alternate size categories, VoiceOver behavior, Reduce Motion behavior, or multi-configuration UI matrices.
- Do not run light/dark, text-size, device-size, orientation, or other configuration matrices unless Aimee
  explicitly names those configurations for the specific task.
- Do not broaden this fixed target without a new direct instruction from Aimee.

## Generated Final-Art Provenance — Direct Aimee Override

New final-product raster or pixel art created by an agent must begin as output from the approved
image-generation tool. A deterministic exporter may crop, mask, palette-reduce, nearest-neighbour scale,
pack, or hash that generated raster, but it may not invent the depicted silhouette or pixels.

- Hand-authored `PixelCommand`/rectangle arrays, JavaScript or MJS drawing commands, CSS/SVG/canvas shapes,
  procedural diagrams, manually plotted pixels, and screenshots of those forms are **not generated art**.
- Those techniques may exist only as functional placeholders when explicitly marked `finalArt: false`. They
  may not be described, assigned, reviewed, promoted, or integrated as final-product candidates.
- Do not ask Asset or Game Design to create or freeze a command-native “literal identity” as final art.
  Game Design may define semantic constraints and a disclosure-safe prompt; final pixels still come from the
  image-generation pipeline.
- A final native registry must carry an image-generation receipt, source-raster hash, production-raster hash,
  and Aimee approval-receipt hash. Without all four, stop at HOLD; do not infer or manufacture provenance.
- Aimee may directly supply or personally hand-author assets. Those assets remain human-authored—not
  generated—and use a separate Aimee-supplied provenance receipt plus semantic editable source paths. Agents
  must never relabel them as generated or hide their editable source behind a hash-only catalogue.
- Existing functional placeholders and the exact frozen legacy registry are compatibility baselines only.
  They are not precedents for new final art and may not gain new IDs.
- Do not open or surface batches of asset previews in the PM pane unless Aimee explicitly requests them.
- Asset remains paused from creating, promoting, or integrating final art after Aimee's 30 August 2026 STOP
  until she supplies a corrected generated-asset brief. Read-only provenance, inventory, and organization work is
  allowed when explicitly assigned.

## Human-Readable Repository Organization — Direct Aimee Override

Hashes are integrity receipts, not the human filing system.

The repository itself must remain navigable in Finder and Xcode. Do not introduce a global game-repository
asset catalogue or exporter. Aimee has separately requested comprehensive visual-asset coverage in GameWiki;
those wiki pages consume semantic repository paths and pack-local manifests, and never substitute for semantic
folders and filenames in the actual game repository.

- Use stable semantic names for packs, source files, branches, worktrees, checkpoints, and reports. Put full
  hashes inside manifests or machine receipts; ordinary status copy uses the semantic checkpoint plus a short
  hash unless Aimee asks for full provenance.
- Content-addressed runtime blobs may retain hash filenames only behind a semantic manifest key. Do not place
  hash-only files directly in human review/source directories.
- Never create copy-suffixed files such as `manifest 2.json` or `sprite 3.png`. Regenerate deterministically or
  use an explicit semantic revision directory.
- Keep editable sources, generated runtime output, review evidence, and temporary build/export artifacts in
  separate directories. Temporary evidence is not committed unless a frozen contract explicitly requires it.
- New generated Swift/JSON must be reproducible from a named generator with a `--check` gate; do not hand-edit
  generated payloads or embed new opaque blobs without a semantic source manifest.
- Before handing off any checkpoint, run `python3 Scripts/verify_repository_organization.py --check` and include
  the passing result in the checkpoint evidence. A failure is a HOLD, not a naming suggestion.
- Keep only bounded active worktrees. After a checkpoint is integrated, rejected, or explicitly archived,
  propose a verified cleanup receipt rather than leaving it indefinitely registered. Never delete a worktree
  or evidence without resolving ownership and obtaining authorization when the action is destructive.
