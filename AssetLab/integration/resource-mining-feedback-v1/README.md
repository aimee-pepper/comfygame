# Resource Mining Feedback v1 — native handoff

This additive receipt promotes the exact reviewed mining-only candidate without changing its
accepted manifest, evidence, field-sprite bytes, or M01–M10 semantics. Native consumes the
existing `ResourceSpriteV1Registry` **field** profile; this packet adds no resource artwork.

The integration authority is `promotion-receipt.json`. The proof route remains
`AssetLab/resource-mining-feedback-v1.html`, and the accepted candidate manifest remains pinned at
body `a8c0aaf64facadca00b0da1c83a1a8b6a1560d9a8de82e129515ba6aa5ba4abf`.

Engineering must preserve these boundaries:

- state and toolbar counts commit before presentation starts;
- one travelling exact field identity plus one exact total label per distinct ResourceID;
- repeat IDs coalesce at their first event position; distinct outputs keep rules order;
- Dismiss/expiry advances committed FIFO, while leaving the World owner clears its visuals;
- missing field art silently omits that subject; no substitute pictogram;
- `Use Tile` and existing World narration remain the only player-facing action/event copy;
- completion, cancellation, interruption and relaunch mutate no gameplay state.

Traveller speech and World Splash remain separate packets and are not dependencies.
