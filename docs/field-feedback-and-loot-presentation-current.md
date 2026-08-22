# Field consequence and loot feedback — current

**Status:** Game Design implementation authority for the first explorable-world feedback slice. It
supersedes the generic “object-to-counter” motion in `core-loop-causal-presentation-plan-current.md`.
**Priority:** first-three-world causal presentation, after rules-owned consequence previews exist and
before adding broader seeker instruments.
**Owners:** Game Design owns disclosure, transaction and timing semantics; Asset Design owns cue/icon
grammar; Engineering owns rules-owned previews, native placement and animation lifecycle; Aimee owns
ordinary-phone visual acceptance.
**Updated:** 21 August 2026

## Outcome

The field should communicate what a known adjacent space will do **before** the player commits, and should
make successful collection feel spatially connected to the object without sending icons flying across the
screen or turning exploration into receipt management.

## Adjacent consequence cues

Evaluate exactly the four cardinal adjacent cells from one rules-owned preview after movement, visibility,
collapse and local-world-state changes.

| Consequence | Party-edge cue | Meaning |
|---|---|---|
| known direct damage/affliction | red outer crescent on that direction | entering or triggering that visible space will cause a known harmful effect |
| extra movement turns | three grey inner drag lines on that direction | entry costs more than one ordinary world turn |
| both | grey inner lines plus red outer crescent | both consequences apply |

Placement is relative to the map, not the screen controls: north cue above the party marker, east to its
right, south below and west left. The cue stays inside the party cell boundary/edge allocation and never
covers an adjacent resource, traveller, portal or target marker.

### Exact first-slice cue grammar

The native map tile is **16×16 logical pixels**. Consequence cues are independent transparent RGBA command
layers composited after the party marker's disc/identity but before its selection/interaction outline. They are
clipped to the party's own 16×16 tile; they never paint the neighbouring cell whose consequence they
describe. The party identity keeps an unobstructed central **6×6** reservation at `x 5...10, y 5...10`.

Asset supplies one north-facing source for each cue and exact 90-degree integer rotations for east, south
and west. Mirroring, subpixel transforms, blur filters and runtime vector strokes are prohibited. The
logical source pixels themselves create the soft/readable edge:

- **Known harm:** one shallow curved crescent in the direction-edge band, no longer than 10 pixels across
  or 4 pixels deep. For the north source, separated outer shoulders begin near `x 3...4` and `x 11...12`,
  step inward on the next row, and join as one short inner bow near `x 6...9`; a lighter inner core and
  darker outer pixels create the soft glow without blur. It must read as a curved side-arc, never as one
  straight row of red segments, a health bar or a complete tile border. The inner bow never enters the
  central 6×6 reservation.
- **Slow footing:** exactly **three disconnected three-pixel rays** in the direction-edge band. For the
  north source, one ray leans up-left, one points up, and one leans up-right; at least one transparent
  logical pixel separates every pair. Each ray uses a darker outer pixel and lighter inner pixel but never
  joins another ray. Cardinal rotation owns the other directions. This is the requested “three radiating
  grey lines”; a nested filled trapezoid, fan, arc or frame is a failed shape even if its occupied rows have
  different lengths.
- **Combined:** composite the unchanged harm and slow sources. Do not author a third combined bitmap and do
  not shift, recolour or delete pixels to make the pair fit.

The harm cue's literal-grayscale core must be brighter than the slow cue, but geometry—not hue—is the
primary distinction. Neither cue pulses, rotates or changes size in this checkpoint. Multiple directions
compose independently; four simultaneous combined directions remain legal and must retain four discrete
crescents plus twelve individually countable grey rays rather than merging into a ring or frame.
The cue layer contains no arrowhead, exclamation point, skull, plant silhouette, damage number or text.

The native game chooses palette values through the accepted map palette adapter. The proof uses one fixed
high-contrast review pair (warm harm red with pale core; cool middle-grey slow strokes) and shows that same
pair unchanged on dark stone, light sand, shallow water and dense-growth tiles. Asset does not recolour cues
per terrain because that would make severity look terrain-dependent.

### Disclosure

- Mud/tall-growth slowdown can be inferred on first legitimate full visibility. Rubble currently blocks
  sight but costs one ordinary movement turn, so it does **not** produce a slow cue unless the movement
  rules themselves later change.
- A flora-harm crescent appears only after that campaign has been harmed by the exact flora
  species/defence, or a real earned recognition contribution identifies it.
- Hidden, fringe-only and unrevealed tiles never create cues.
- An undiscovered site/resource/creature does not become visible merely because its tile would have a
  consequence.
- Collapse/impassability uses the actual current tile truth; stale cues disappear in the same state update.

The cue is advisory. Use Tile/movement validates again atomically. A changed space may refuse with accurate
context without applying the stale predicted outcome.

#### Rules-owned preview shape

Engineering exposes one pure four-entry `AdjacentConsequencePreview` snapshot. The renderer and Look do not
query tiles independently:

```text
AdjacentConsequencePreview
  worldRunID
  inputStateHash
  playerPosition
  directions[exact N,E,S,W]
    direction + destination
    currentVisibility: full | fringe | hidden
    knownGroundID?
    blocker: boundary | crumbled | deepWater | chasm | solidObstruction | otherVisibleImpassable | none
    entryTurns? + extraTurns
    learnedConsequence: none | physicalEntryHarm | chemicalEntryHarm | activeEncounter
    floraKnowledgeKey?
    visibleContentSummary?
```

`inputStateHash` is SHA-256 of one canonically encoded v1 input receipt, never Swift `hashValue`. It contains
exact `runIndex`, `mapSeed`, player position, current night/torch/party-sight and resolved visibility-profile
values, frozen slow-ground/flora-hazard tuning, then N/E/S/W in that order with each destination's
in-bounds/current-visibility/ground/crumbled/cracking/flora/content stable identity, matching sessile enemy
identity and the matching learned Flora key if any. Hidden/fringe directions encode no semantic tile/content
identity after their visibility result. A preview whose current rebuilt hash or player position no longer
matches is discarded rather than patched. `currentVisibility != full` clears every semantic field after
visibility. A non-`none` blocker clears entry turns, consequence and content except its own legitimate
visible ground/blocker identity.

`worldRunID` is the typed v1 pair `runIndex + mapSeed`; the current save model has no separate run UUID and
the preview must not add a random one merely for presentation.

The v1 factory is `WorldRules.adjacentConsequencePreview(in: GameState)`, not a `WorldRun` helper with the
default `party: 0`. It derives the same party sight bonus and `VisibilityProfile` used by the live map, and
calls `WorldRules.movementCost(_:slowGroundExtraTurns:)` with the run's frozen tuning. The four currently
real blocker cases are boundary, crumbled, deep water and chasm. `solidObstruction` and
`otherVisibleImpassable` are reserved closed cases for future actual rules; v1 must not fabricate either
from ordinary tile content, because a resource, item, portal, site, writing or traveller does not currently
block movement.

The cue adapter uses only `extraTurns > 0` and `learnedConsequence != none`. Look formats all fields through
one closed copy table. Movement never accepts the preview as authorization: it calls the normal atomic step
rule again. This keeps one truthful source while preventing a stale preview from becoming a second movement
engine.

#### Exact flora-learning receipt

The current `WorldInspectionRules` trait check is not sufficient authority: it can describe a defended
plant from saved `isRevealed` terrain even when the plant is not currently fully visible, and it knows the
defence directly from generated traits before the player has learned it. B1.8a must replace that leak rather
than reuse it in a new red graphic.

Reality stores a tolerant versioned `FloraConsequenceKnowledge` set keyed by a rules-owned stable
`FloraKnowledgeKey`, never by display name, palette or map position. The exact v1 key is
`schemaVersion = 1 + worldSeed UInt64 + floraID InstanceID + defenceType`; the world seed prevents an
instance-ID collision in another world from inheriting knowledge. If a future flora identity schema
changes, old keys retain their version and do not silently match a different plant. A record carries only
the learned consequence family (`physicalEntryHarm`, `chemicalEntryHarm`, or `activeEncounter`) and the run
index first learned. It does not expose damage numbers, yield, metabolism or other hidden traits.

Learning occurs only after a truthful event:

- physical or chemical growth records its exact key only after `walkInto` actually resolves nonzero harm
  and emits `scratchedByGrowth`; refusal or harmless contact records nothing. The write uses the exact
  destination flora value captured by the step transaction, not the event's display-name string;
- active-defence flora records `activeEncounter` when walking into that exact sessile creature actually
  begins its encounter—the write occurs at `beginEncounter(triggeredBy:)` only when the triggering enemy is
  `isSessile` and carries the matching `floraID`. The learned consequence is “entry starts a fight,” so
  dealing or receiving combat damage is not an additional requirement;
- an explicit earned flora-recognition contribution may write the same narrow record without contact, but
  it must name the exact key and family; generic Bestiary discovery or seeing a similar colour is not enough.

The run may cache the same learned key for immediate rendering, but Reality is the durable authority.
Existing saves decode an empty set; they do not infer knowledge from revealed tiles, species names or prior
generic encounters. Learning never awards XP by itself.

Every four-direction preview requires **current full visibility**, a currently present/passable adjacent
tile and fresh matching local state. Remembered `isRevealed` terrain may retain its known ground identity on
the map but cannot produce a harm cue or content line. A slow cue may use the fully visible ground's actual
entry cost without any flora knowledge. An impassable tile gets a blocker result, not a misleading slow or
harm cue, even if its stale underlying ground/plant once had those effects.

A learned `activeEncounter` key alone does not create a cue. The destination must currently contain the
matching fully visible sessile `WorldEnemy` with that `floraID`; an active-trait plant without a placed
combatant is not promised to start a fight. Likewise physical/chemical knowledge creates a cue only when
the currently present destination flora still resolves a nonzero matching entry harm. This keeps durable
knowledge separate from the current local consequence.

### Look

**Look → direction** spends no turn and returns one compact structured result:

1. known terrain/material identity;
2. passable or exact blocker;
3. exact current entry-turn cost;
4. known harm/affliction source and effect;
5. visible usable content, if any.

Refusal copy must be selected from the actual blocker. At minimum, deep water, chasm, collapsed/crumbled
ground, solid obstruction and out-of-bounds each have distinct plain-language copy. “The ground crumbled
away” is legal only when ground actually collapsed.

Look uses the same knowledge-gated preview as the cues. It may say “Entering will hurt the party,”
“Entering carries a lingering hazard,” or “Entering will start an encounter” only for the matching learned
consequence. Before that, it may describe the fully visible growth's nonsemantic appearance but cannot infer
its defence or say “may be harmful.”

### Look v1 copy table

Look presents one anchored compact card: heading first, then only applicable lines in this order—blocker or
turn cost, learned consequence, visible content. It never shows an empty label or raw enum.

| Preview fact | Exact v1 copy |
|---|---|
| boundary | **World boundary** · There is no tile there. |
| crumbled | **Crumbled ground** · Nothing remains to stand on. |
| deep water | **Deep water** · The party cannot enter it. |
| chasm | **Chasm** · There is no stable crossing here. |
| solid obstruction | **Blocked** · A solid obstruction stops the party. |
| other visible impassable | **[Visible ground name]** · The party cannot enter it. |
| ordinary passable | **[Visible ground name]** · 1 turn to enter. |
| slow passable | **[Visible ground name]** · [N] turns to enter · [N−1] extra. |
| learned physical flora | Entering will hurt the party. |
| learned chemical flora | Entering carries a lingering hazard. |
| learned active flora | Entering will start an encounter. |

Currently cracking ground may add **Cracks warn that it may crumble.** only when that crack state is fully
visible. Visible usable content retains its already legitimate name/status summary; Look does not search or
collect it. Unknown flora may add **Visible growth.** only—“thorn,” “chemical,” “coiled,” damage and defence
language are knowledge-gated. The anchored card flips/clamps inside the phone safe area just like the settled
item detail popover; it never expands the world-control stack or covers the selected party tile.

## Successful pickup animation

### Why local rise is the default

A long object-to-satchel/counter flight creates visual clutter, crosses unrelated cells and implies that
the animation's destination owns the transaction. A short local rise preserves the cause—“I picked up the
thing here”—and lets the HUD quantity update independently. It is also robust when the compact carried
summary changes layout.

### Exact motion

On a successful committed pickup:

1. Update the authoritative quantity/ownership immediately. Animation never delays or owns the mutation.
2. Spawn the collected family/instance icon at the center of the source tile. If the source graphic was
   consumed, the feedback icon replaces it in the same frame so there is no blank flash.
3. Over **450 ms**, raise the icon **1.5 tile heights** along the screen's vertical axis.
4. Hold full opacity for the first 180 ms, then fade to zero over the remaining 270 ms.
5. A restrained scale `0.90 → 1.05 → 0.95` is permitted; rotation, bounce, sparkle explosion and a
   screen-length trail are not.
6. Display `×N` beside the icon only when one transaction awarded more than one unit.
7. Pulse the corresponding compact carried counter once when its value changes, but draw no connecting
   line and do not move the feedback icon toward it.

The motion is nonblocking. The player may move or open another valid surface; the feedback may finish or
be cancelled without affecting the receipt. It never spends an extra world turn and never plays on a
refused or duplicated transaction.

### Edge and quantity behavior

- If a 1.5-tile rise would leave the map viewport, shorten the rise to the largest wholly visible distance.
  Do not reverse it downward or let it cover the world HUD.
- Same-family units committed by the direct action produce one icon with aggregate `×N`. v1 has exactly one
  presentation identity per `stepPickup` or `harvest` transaction; it has no multi-kind burst grammar.
- An unidentified object uses its legitimate unknown silhouette; the animation cannot reveal its name.
- Reduced-motion presentation uses a 250 ms local opacity/scale confirmation with no translation. This is
  part of correct motion behavior, not a separate broad accessibility redesign.

### Contexts

- **World resource node/flora:** play at the harvested tile.
- **Loose item/page:** play at the recovered tile.
- **Creature victory:** no local pickup animation in v1. Complete Creature materials remain aggregated in
  the combat result/Expedition Return collection rather than spraying body-part icons over the map.
- **Site multi-loot:** no local pickup animation in v1. The anchored site-result tray owns the multi-object
  breakdown; a later compact site confirmation requires its own reviewed transaction/composition contract.
- **Home crafting/trade:** use destination-local result feedback, not this field animation.

## Asset Design packet

The first Asset milestone is **cues only**. It must provide reusable logical sources, not screenshots with
the cue painted into terrain. Provide one integrated native-scale sheet containing:

1. party marker with north/east/south/west harm cues;
2. north/east/south/west drag cues;
3. combined harm+drag on two different directions at once;
4. cues on dark, light, water-edge and growth-heavy visible backgrounds;
5. cue-free hidden/fringe cells;
6. the legal worst case of four simultaneous combined directions around one party marker;
7. a collision overlay proving the central 6×6 party reservation and all four 16×16 tile bounds;
8. color and literal-grayscale/value proof at native scale and true 400% nearest-neighbour scale.

The visual test must be inspected on the same ordinary-phone scale as the native map. A contact sheet at a
larger design scale is insufficient because edge collisions and value contrast are the risk.

The separate pickup-feedback milestone remains held until this cue grammar is accepted. It will then add
the first exact 16px world-resource/item/page/unknown-object feedback identities and 0/180/450 ms frames
already specified below without changing the accepted cue sources. Creature materials do not spray out of
the map after combat; they remain aggregated object stacks in the combat result and Expedition Return.

### Cue proof acceptance gate

The cue checkpoint remains `integrationReady:false` and stops after Game Design review. Automated evidence
must prove exact 16×16 bounds, binary transparent/opaque source ownership (any apparent softness comes from
authored value pixels, not filters), exact 90-degree rotations, pairwise-distinct grayscale signatures,
unchanged component hashes in every combined state, no pixel in the central 6×6 reservation, and no pixel
outside the party tile. The 368×800 proof must include north/east/south/west, two-direction mixed,
four-direction combined, hidden/fringe cue-free and all four background fixtures. No native/PBX/golden,
pickup animation or gameplay work is authorized by this Asset milestone.

#### Consequence Cues v0.1 visual disposition

**Accepted by Game Design as the frozen cue-only candidate; native integration remains unaccepted.** Direct
review covered the 368×800 colour and literal-grayscale phones, four cardinal sources at true 400%, mixed
two-direction and legal four-direction stress states, four representative terrain backgrounds, full versus
fringe/hidden disclosure, and the 16×16/central-6×6 collision proof.

The harm source reads as one shallow stepped crescent rather than a bar or frame. The slow source reads as
exactly three disconnected directional rays rather than a filled fan. In the legal worst case, four harm
crescents and twelve slow rays remain discrete; the composition is intentionally dense but does not become
a continuous tile border. Both meanings survive literal grayscale while the party identity remains clear.

Freeze canonical body SHA-256
`1d648b34d10e015e8e49f1dbc1bc7b90327f15b092f317431c50572769e272d2` and manifest-file SHA-256
`793d74eff6b16f426c2fa163ba4dbca56237ddecc8734bd6a88e0136dd75f519`. The exact accepted Asset boundary is
frozen in commit `e448553c1c1f095a01b4274aea812faa76955110`. The checkpoint remains
`integrationReady:false`; this acceptance authorizes Asset to checkpoint only the declared five-path cue
boundary. It does not authorize native/PBX/golden work, pickup animation, seeker instruments or another
Asset milestone.

### Next Asset milestone: local pickup motion v0.1

This is a **motion/composition proof plus five exact first-slice identities**, not a replacement item atlas
and not native implementation. It may begin only after the accepted cue checkpoint is clean. It reuses
accepted identity authorities wherever the exact 16px consumer already exists and authors a dedicated
16px pickup form where a 32px inventory identity cannot be reduced truthfully.

#### Exact first-slice identity set

| Stable proof key | Legitimate source | Required 16px read |
|---|---|---|
| `pickup.resource.quartz` | accepted `resourceInventoryIconCommands("quartz")` | pale angular crystal cluster; not its whole node/substrate |
| `pickup.resource.essence_raw` | accepted `resourceInventoryIconCommands("essence_raw")` | the exact Raw Essence carried identity; not Mote or a fabricated node |
| `pickup.item.blade_chipped` | accepted identified `blade_chipped` 32px catalogue identity | dedicated 16px chipped blade/guard mass preserving the catalogue object's dominant axis; no automatic bitmap reduction |
| `pickup.writing.page` | accepted physical-page/loose-page language | one folded recovered sheet; no traveller portrait, owner name or rune meaning in the pixels |
| `pickup.object.unknown` | accepted unidentified-curio wrapped-parcel resolver | the same opaque parcel for every still-unidentified supported object |

These five sources are production-reusable logical RGBA assets, each with binary alpha, a stable pivot and
pairwise-distinct occupied-pixel signature in literal grayscale. Quantity, quality, rarity, value, owner,
eligibility and destination are not baked into any sprite. `×N` is live text adjacent to the transient icon,
not part of its bitmap. A known object lacking an exact pickup identity skips this optional animation and
emits a diagnostic; it never borrows an unrelated silhouette. An actually unidentified object may use only
`pickup.object.unknown`.

Creature materials are deliberately absent from this 16px set. Ordinary combat already owns a result
surface and Expedition Return aggregates them by exact family+quality. The map must not fire one animation
per Hide/Bone/Feather or imply that every creature produces the same generic remains. A later accepted
creature-material atlas may supply result/Return tiles without changing pickup motion.

#### Exact compositor request

```text
LocalPickupFeedbackRequest v1
  transactionReceiptID
  worldRunID
  sourceTileCoordinate
  sourcePointInMapViewport
  mapViewportBounds
  reducedMotion
  group
    presentationIdentityKey
    quantity
    knownness: known | unidentified
```

The request is created only from a committed successful transaction receipt. The compositor receives no
uncommitted item candidate, hidden tile descriptor, destination counter or eventual identification result.
Duplicate `transactionReceiptID` is ignored. Animation state is ephemeral and is never decoded back into
ownership; relaunch may omit an unfinished animation because the committed quantity is already authoritative.

`transactionReceiptID` is a typed v1 tuple of exact `runIndex + mapSeed + turnsTakenBeforeAction +
actionKind + sourceTileCoordinate`. v1 action kinds are `stepPickup` and `harvest`; site search and combat
results do not masquerade as direct field pickup. A successful action advances the run and removes/reduces
its exact source, so this tuple is unique inside that run without random IDs or wall-clock time. The same
receipt aggregates the quantity of that action's one presentation identity before animation. Current
`stepPickup` and `harvest` transactions do not produce several presentation identities, so v1 must not
invent multi-kind bursts or `+N kinds` handling. If a later committed action can legitimately yield several
identities, it requires a separately reviewed request version and composition proof. The receipt need not
persist after presentation, but Rules must emit it with the committed result so the View never reconstructs
it from display prose.

#### Exact layout and frames

- Resolve the feedback origin at the committed source tile's on-screen centre. Its trajectory is screen-up,
  not map-north, so a rotated device/map never changes the meaning.
- At `0 ms`, draw the exact 16px logical icon centred on the source. At `180 ms`, it has moved `0.6` tile
  height, remains fully opaque and may reach scale `1.05`. At `450 ms`, it has moved exactly `1.5` tile
  heights unless clamped, scale is `0.95`, and opacity is zero.
- Use linear position interpolation and one smooth opacity ease only. No bounce, rotation, particle,
  sparkle, trail, beam or counterward motion.
- Clamp the entire icon plus quantity label inside the **map viewport**, not merely the phone safe area.
  Shorten the upward travel when the source is near the top; never reverse or slide sideways to make room.
- Draw transient pickup feedback above map terrain/content/party/cues/selection, but clip it to the map
  viewport and below Look, tutorial, bug-report and system overlays. It never moves controls or the map.
- Same-identity units in one receipt aggregate before presentation. One award of nineteen Quartz units is
  one Quartz icon plus `×19`, not nineteen sprites. Exactly one icon and optional quantity label exist in a
  v1 animation.
- Under Reduce Motion, hold the icon at the source for `250 ms`, using only `0.90 → 1.00` scale and
  `1.0 → 0.0` opacity. No translation occurs.

#### Required evidence and stop gate

Asset supplies one deterministic manifest, the five native/true-400% colour and literal-grayscale sources,
and exact 368×800 proofs for: ordinary Quartz; Raw Essence; Chipped Blade; recovered page; unidentified
parcel; Quartz `×19`; one ordinary identity at `0/180/450 ms`; one top-edge `×N` pickup at `0/180/450 ms`;
Reduced Motion; and a collision scene containing accepted consequence cues plus fixed world controls. The
top-edge proof must keep the complete icon and live quantity label inside the map viewport at every frame;
it shortens travel rather than clipping or entering the HUD/header gap. A frame strip must show source
content disappearing without a blank flash at `0 ms`. Every icon and label stays inside the map viewport,
no cue source pixels change, and hidden/fringe content never creates a request.

The checkpoint stops for Game Design review with `integrationReady:false`. It authorizes no native/PBX/
golden work, no broad catalogue redraw, no Creature-material atlas, no combat-result/Return redesign and no
gameplay transaction implementation.

#### Local Pickup Motion v0.1 visual disposition

**Accepted as the frozen Asset candidate; native integration remains unaccepted.** Direct visual review
covered all five native/400% identities, ordinary and top-edge `0/180/450 ms` frames, Quartz `×19`, Reduced
Motion, no-blank-flash and accepted-cue/fixed-control collision in colour and literal grayscale. The request
contains exactly one aggregated identity. At the extreme top edge the entire 2× icon-plus-live-label bounds
stay within the map by shortening travel to zero when necessary; the feedback fades locally without
clipping, reversing or entering the HUD.

Freeze canonical body SHA-256
`a2475bbbc4bab0eb4ee90f0ca562bf04ed2cffd565aa7eaa21e2656f92eaa9c7`, manifest-file SHA-256
`aacdd08ed66e80131847873852454b68d3981b46ad7b79696d6cb8675af31375`, and exact Asset commit
`2d2992bc94224f11ea3901a29a392f45d59b0386`. `integrationReady` remains false; Engineering must consume
the eventual typed committed receipt and may not infer ownership or identity from the animation.

## Engineering checkpoints

1. Add the exact pure `AdjacentConsequencePreview` snapshot from current rules and campaign knowledge; no
   renderer inference and no parallel tile queries in Look.
2. Reuse that preview for Look copy and cue state; add exact contextual impassable reasons.
3. Integrate static cue shapes at the four party edges and prove no fog/content disclosure.
4. Add local pickup feedback driven by successful transaction receipts, with dedupe/relaunch protection.
5. Add same-identity quantity aggregation and whole-icon-plus-label map-edge clamping.
6. Capture actual-phone combined-cue and top-edge pickup evidence; Aimee accepts/tunes visibility before
   later seeker instruments begin.

### B1.8a Engineering proof matrix

The native cue/Look checkpoint is not complete with renderer screenshots alone. Its focused gates contain
all of these exact cases:

1. party-aware visibility differs from the `party: 0` default, and the preview follows the live party-aware
   full/fringe result;
2. ordinary stone, sand, water and rubble report one turn and no slow cue; mud and tall growth report the
   run's exact configured total/extra turns and do show the three-ray cue;
3. boundary, crumbled tile, deep water and chasm return four distinct blockers/copy, clear harm/slow/content
   and spend no turn;
4. a fully visible physical/chemical plant has no warning before learning; an actual nonzero
   `scratchedByGrowth` transaction records the exact key; a later matching present plant in the same world
   warns, while another world with a colliding flora ID does not;
5. harmless/refused contact, generic discovery, display-name similarity and saved revealed terrain never
   write knowledge;
6. an active-trait plant without a matching placed sessile enemy produces no encounter warning; contact
   with the exact sessile enemy records at encounter start; a later currently present matching enemy warns;
7. removing the plant/enemy or changing the destination to an impassable/hidden/fringe state removes the
   cue despite durable knowledge;
8. old saves decode empty knowledge; save/relaunch preserves legitimately learned keys without inferring
   new ones;
9. the canonical N/E/S/W input receipt is byte-stable across dictionary/set insertion order, changes when
   any legitimate input changes, and stale hashes are discarded; movement still revalidates the current
   destination atomically;
10. Look uses this preview rather than the legacy trait-leaking `WorldRules.inspect`, advances no turn,
    mutates no reveal/knowledge/content, and dismisses its armed mode when the player taps outside the world
    page or navigates away;
11. the anchored Look card flips/clamps at all four phone edges, does not resize the world/control layout,
    and shows only the ordered lines owned by the closed copy table; and
12. accepted cue body/manifest hashes remain exact through native adapter conformance; actual 368×800
    colour/grayscale proof includes the legal four-direction combined stress state with fixed controls.

## Acceptance

1. Every cue corresponds to the current rules-owned result for that exact direction.
2. Known harmful flora cues appear after legitimate learning and not before.
3. Slow+harm remains readable together on all four directions without covering adjacent content.
4. Look and failed movement name deep water, chasm and collapse distinctly.
5. Pickup ownership is committed exactly once even if animation is cancelled, navigation changes or the
   app relaunches.
6. Nineteen units of one directly collected world resource produce one local `×19` feedback, not nineteen
   animations; nineteen Hides remain one aggregated Creature-material stack in result/Return rather than a
   combat-map spray.
7. Top-edge pickup remains within the map viewport.
8. Field feedback does not expose unidentified content, clear fog, alter minimap POIs or create extra
   counters.

## Explicit exclusions

- no full-screen loot rain;
- no icon flying to the top of the screen;
- no haptics/audio dependency for understanding;
- no seeker instrument in this checkpoint;
- no new hazard types merely to populate the cue grammar;
- no animation-driven game mutation.
