# Equipment Inscription System — current design

**Status:** enchanting concept requested by Aimee; the first-slice profile below is Game Design's
implementation-ready recommendation for review  
**First inscription:** `seamward`, made from a Seamlight  
**Owner:** the Scriptorium, after its ordinary Hands and Ink foundations  
**Roadmap position:** Band 3.4; it does not pre-empt encounter scaling or the earlier Seamlight
consumable

## Player promise

Inscription is Bookbinder's equipment-enchantment system. The player writes one durable magical
instruction onto one exact physical piece of gear. The instruction travels with that piece through
storage, equipping, reforging and save/relaunch.

The first recipe turns a Seamlight into a permanent emergency-navigation enchantment:

> **Seamward** — When the world begins collapsing, this piece wakes and guides the party toward the
> nearest usable portal.

Player-facing language uses **Inscribe**, **Inscription** and the individual inscription name rather
than generic “enchanting,” while Settings/debug/schema may call the feature equipment inscriptions.

## Recommended first-slice scope

- Eligible slots are **Body** and **Keepsake**. Keepsake is the game's accessory slot.
- One exact gear instance may hold at most one inscription.
- An inscription belongs to the gear's stable instance ID, never its catalogue ID.
- Any active departing party member may wear the piece. Its expedition effect is frozen at departure
  so later Home equipment changes cannot rewrite an active world.
- Two copies of the same party-level inscription do not stack or strengthen one another.
- Gear worn by somebody left at Home contributes nothing.
- Reforging and ordinary equip/store/overflow transfers preserve the inscription exactly.
- Rebuilding into a different exact piece does not copy it. Trading or recycling acts on the
  enchanted exact piece and must name the inscription before confirmation.
- The Scriptorium may erase an inscription with a destructive confirmation. Erasure returns no
  Seamlight, ink or Essence. Replacing one first requires erasure; it is never silently overwritten.

This slice adds no random enchantment rolls, enchantment levels, sockets, duplicate stacking,
disenchantment loot table, weapon enchantments or generated affixes.

## Authored-data model

Every inscription is an authored definition. A consumable does not automatically become a legal
enchantment merely because it has an effect.

```text
EquipmentInscriptionDefinition {
  id: InscriptionID
  name: String
  sourceItemID: ItemID
  allowedSlots: Set<GearSlot>
  scope: wearer | party | expedition
  trigger: authored typed trigger
  effect: authored typed effect
  essenceCost: Int
  inkApplications: Int
  rulesVersion: Int
}

EquipmentInscriptionReceipt {
  definitionID: InscriptionID
  sourceItemID: ItemID
  rulesVersion: Int
  inkRecipe: InkRecipe?       // nil means Ash
}

GearInstanceProfile.inscription: EquipmentInscriptionReceipt?
```

The receipt stores the exact prepared color recipe when colored ink is used. Color changes the
inscribed line/glow only; it never changes potency, trigger or pathfinding. Ash is always a legal
neutral inscription and uses the effect's normal light color rather than turning the effect black.

At departure, rules derive a frozen `ExpeditionInscriptionReceipt` from exact equipped pieces and
record the contributor's party identity, gear stable instance ID, inscription ID and rules version.
World rules consume only that frozen receipt.

Tolerant decode gives old gear `inscription = nil`. Unknown future inscription IDs remain visible as
an inert retained inscription receipt rather than being guessed, erased or activated.

## Inscription transaction

At the Scriptorium, an **Inscriptions** surface appears only after the Brush and Ink preparation
foundation exists.

1. Select one exact stored or worn eligible Body/Keepsake piece.
2. Select one known authored inscription.
3. Show the resulting exact piece, trigger, source item, ink and Essence before/after.
4. Confirm once.
5. In one atomic transaction, revalidate the gear identity/location and costs; consume inputs; append
   the receipt to the same gear instance; return it to the same location.

Stale gear, changed stock, an occupied inscription slot or insufficient cost causes zero mutation.
Installing Seamward costs:

- `1 Seamlight`;
- `1 ink application` (Ash is permitted and unlimited; a chosen prepared color consumes one exact
  matching application); and
- `10 Essence`.

The permanent upgrade therefore arrives after the ordinary consumable has already been useful, and
does not require a rare late-game building.

## Seamward rules

Seamward uses the same deterministic shortest-walkable-path and fog-neutral visual grammar as
`seamlight-current.md`, with these differences:

- It is dormant during normal exploration and does not point toward undiscovered portals.
- It wakes automatically on the first collapse-phase turn; activation consumes no item and no turn.
- It remains active through the rest of that expedition and save/relaunch.
- If several active pieces carry Seamward, one party-level guidance receipt is used; brightness and
  pulse rate do not stack.
- On a portal it produces the same complete bright ring and never returns Home automatically.
- If no portal is reachable, the cue remains absent and the event log says **The Seamward finds no
  answering seam.** No persistent reveal is written.

This distinction preserves both items: a carried Seamlight can guide deliberate portal-seeking at
any time, while Seamward is permanent emergency insurance specifically for a collapsing world.

## Interface and asset boundary

- Scriptorium: compact eligible-gear tray, inscription choices and one consequence/confirmation
  panel; do not use a full-width list wall.
- Gear: a small inscription badge on the item icon; anchored item details name its trigger and source.
- Expedition: no new screen. Seamward uses the Seamlight directional arc asset only during collapse.
- Color: prepared ink may tint the core of the line, but a redundant pale outer glow preserves
  readability across world palettes. No new gameplay meaning is assigned to color.

## Expansion rules

Future inscriptions may be authored only when their trigger, scope, stacking and source economy are
explicit. They should convert an established consumable or learned magical instruction into a
narrow equipment commitment, not become a generic passive-stat catalogue. Waystone is explicitly
ineligible: permanent automatic full-haul extraction would erase the world-escape loop.

## Acceptance

1. Stored, worn and overflow gear preserve the exact inscription receipt and stable gear identity
   across equip transfer, reforge and relaunch.
2. Exact-item install is atomic for stale source, occupied slot, insufficient inputs and full storage.
3. Only Body/Keepsake are eligible; weapons and every other slot fail without mutation.
4. Seamward is silent before collapse, activates once without spending a turn, and guides correctly
   after route-changing collapse and relaunch.
5. Multiple Seamwards do not stack; inactive/Home wearers do not contribute.
6. Neither installation nor activation reveals a portal, route, nearby content or minimap POI.
7. Erasure is explicitly confirmed, removes only the selected exact inscription and returns no costs.
8. Trade, recycle, gear details and return receipts retain or truthfully disclose the inscription.
