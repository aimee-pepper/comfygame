# Exploration map final-art promotion v1

Status: **Aimee-approved for native integration**. `integrationReady:true` applies only to the exact stable
keys enumerated by `promotion-receipt.json` from these immutable candidate commits:

- `d3dce437a3c33dae3316d13de7625d5dc9fe9c8f` — sites, generic hazard, portals,
  locked cache, loose World Page, diary/found writing and simplified minimap categories;
- `33aac2dc9254ecbd4d3e256ee4efdd390d56482d` — 75 exact catalogue gear identities plus
  `minimap/item`;
- `bfd49d52bb3814c708161c4fe0256631dfadcb95` — 27 exact catalogue object identities and the
  opaque unknown-curio disclosure identity.

The source manifests remain byte-identical candidate provenance. This additive receipt is the approval
authority; it does not regenerate or alter any PNG. Engineering consumes each source runtime directory as
`manifest.json + assets/**`, resolves only an enumerated stable key, and draws the complete premade PNG with
nearest-neighbour filtering.

## Native rules

- Map art is 16×19 logical pixels, pivot (8,18), bottom-anchored to the 16×16 terrain surface.
- Full visibility resolves the exact persisted identity/state. Only the exact premade ambient-frame families
  advance on the existing shared presentation clock.
- Remembered uses frame 0 of the same exact identity/state. Hidden performs no lookup and no draw.
- Searchable sites use persisted `PlacedSite.isLooted`; natural anchor has ordinary state only. No fabricated
  open, depleted, damage, spread, extinguish or search state exists.
- Static loose items never animate. The two current curio IDs alone may use `catalogue-item/unknown-curio`
  while unidentified.
- Simplified minimap keys reveal category only: portal, page, site, resource, item, cache or hazard.
- Layer order is terrain/south wall → stationary content → party/consequence cues → selection/interaction →
  alerts/HUD.
- Unknown keys and blocked identities fail closed. Named travellers, ordinary/apex creatures, Binder and
  Quill remain blocked with no generic fallback.

The receipt embeds all 154 approved stable keys, their source manifest hashes, runtime aggregates, request
ABIs, state/frame rules, visibility contracts and layer contracts.
