# Trading Post and Vance — AssetLab handoff

**Status:** Asset-side proposed semantic fixture accepted; native economy rules absent.  
**Stable identities:** `trading_post`, `vance`. There is no `exchange` station alias.  
**AssetLab contract version:** `trading-post-ui-1.0.0`.  
**Reviewed artifact:** `AssetLab/artifacts/trading-post-vance-proof-v0.2.png`.  
**Artifact SHA-256:** `f4f9a41d1a0b114e30bcd433406d45486e00415fe0163629c8dd9a9f8078cf8f`.

## Safe to reuse

- `distinctStationCommands("trading_post")` is the accepted authored station identity.
- `characterCommands("vance", { profile: "baseSide" })` is the authored village-side Vance cameo.
  The proof uses identical commands outside and at the counter; the station never changes Vance's
  anatomy, palette or carried identity.
- The phone grammar is Buy/Sell peer tabs, six item icons per row, tapped detail, protected items
  visible without a tempting price, and Preview → Confirm → Result states.
- This is the physical-object grammar from `player-facing-screen-grammar-current.md`: there are no
  permanent names beneath tray icons, selecting an icon cannot mutate it, and accessibility text may
  reduce the column count rather than clip the detail/actions. Vance remains a person cameo, not a
  six-across object tile; the Trading Post remains a place identity, not a stock card.
- Gold Coins must be named separately from Gold Ore. Resource purchases route to `ResourcePool`, not
  Storehouse inventory.
- Cancel is non-mutating. Only the future rules-owned confirm operation may mutate wallet, stock and
  holdings atomically.

## Not safe to consume as game data

Every wallet amount, price, stock line, eligibility result, lock/favorite state, refresh sequence,
outcome ID and result in the v0.2 proof is visibly labelled a proposed fixture. AssetLab's
`proposedTradingPostResult` does not perform or claim a transaction. Do not copy fixture values,
hashes or pseudo-identities into a save model.

## Required game-owned resolver boundary

Before native integration can call the screen truthful, Engineering must provide a closed DTO from
rules-owned state with:

- exact `stationID = trading_post` and `keeperID = vance` ownership;
- Gold Coins wallet balance and wallet revision;
- stock schema/refresh version, opaque stable line IDs, remaining quantities and stock revision;
- typed row identity (`ResourceID`, material bin/index plus complete receipt, ordinary item stack, or
  stable gear instance) rather than one shared string;
- rules-produced buy/sell eligibility and a closed player-facing reason code;
- unit price, selected quantity, exact total, destination/capacity result and before/after values;
- favorite/lock, identification, equipped ownership and authored transferability from live state;
- opaque preview token covering the exact selection and relevant wallet/stock/inventory revisions;
- cancel, stale-preview and atomic committed-result cases with no partial mutation.

Unknown or missing metadata must resolve conservatively to Cannot act. UI code must never recompute
price or eligibility from color, rarity, display name, catalogue order or the AssetLab fixture.

## Acceptance checkpoint

On a fresh campaign: find and recruit Vance, build the Trading Post, sell one eligible holding, cancel
one sale, reject one protected holding with its exact reason, close/reopen without reroll, resolve one
expedition to refresh once, and verify wallet/holdings/stock after save-reload. Run color, literal
grayscale, accessibility-large text and VoiceOver order. Do not alter Simulator lifecycle/window state;
reuse the existing window only when native QA begins.
