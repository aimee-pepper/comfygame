# Campaign native visual reference

These PNGs are exact 368x800 browser captures of the immutable approved Campaign
snapshot. They are visual authority for composition, spacing, typography, book/shelf
geometry, and action placement.

Authority:

- Approval ledger: `AssetLab/reviews/ui-gallery-reviews.json`
- Screen: `campaigns`
- Design version: `restored-a5f2512`
- Snapshot SHA-256: `d260cc9dff5fc247d6d74e400e1a8c067cd5874a3db14cf92438d81ebb83f12a`
- Approved stylesheet: `AssetLab/reviews/approved-styles/9233681ef38da5e862baf8536daab1376172ef8870cc3e1487cabc5d6649efb8.css`
- Stylesheet SHA-256: `9233681ef38da5e862baf8536daab1376172ef8870cc3e1487cabc5d6649efb8`

Reference states:

- `campaign-approved-default-368x800.png`
- `campaign-approved-selected-368x800.png`
- `campaign-approved-delete-confirm-368x800.png`

Native truth overrides fixture copy. Do not implement the fixture's health values or
release-visible schema numbers. Compact native cards must use only current
`CampaignSlotSummary` truth: exact save name and validity, level, location,
progress-book count, and last-played time. Progression and recovery detail remain in
the details surface.

Preserve existing behavior: at most eight slots, whole-card direct Load for valid
saves, invalid cards opening Details, long-press Details, newest-valid Continue,
Export unchanged, and confirmed Delete. The selected treatment in the reference
marks the newest-valid Continue campaign; it does not introduce a new selection step.
