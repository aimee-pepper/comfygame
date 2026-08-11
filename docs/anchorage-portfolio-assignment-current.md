# Anchorage portfolio and assignment — current design

**Status:** implementation-ready interaction layer over current anchoring and production rules.  
**Owner:** Game Design owns portfolio, decision and consequence presentation; Engineering owns stable
realm/person identities and atomic mutations; Asset Design owns realm-cover and state grammar.  
**Does not add:** worker specialities, risk rolls, offline production, permanent loss or a realm cap.

## Audit result

The live Anchorage renders every realm as one full-width card containing status, route, sustain,
every assigned companion, an unfiltered assignment menu, revisit and reactivation. This is workable
for one realm and structurally poor for a long Atlas.

The settlement sheet also begins with every realm unchecked while **Confirm settlement** is enabled.
Confirming that untouched state makes every due realm dormant. That is a destructive default hidden
inside a neutral-looking checklist.

The corrected experience treats realms as destinations and assignment as an opportunity-cost choice.

## Anchorage structure

The station has three tabs:

1. **Atlas** — compact realm destinations and revisit/reactivation.
2. **Work** — selected renewable work, production progress and people posted across realms.
3. **Deliveries** — completed per-realm trays and collection.

Tabs are views over the same realm state, not separate systems. An attention badge derives from due
settlement, paused/full work or collectible delivery and clears only when that state clears.

### Atlas portfolio

Use two realm tiles across at ordinary phone width. Each tile shows:

- frozen world-cover identity shared with World History;
- player name plus permanent `World N` subtitle;
- Active or Dormant state using shape and text;
- sustain `covered` or exact projected shortfall;
- posted-person count and one delivery/paused attention mark;
- primary action: **Revisit** when active, **Review reactivation** when dormant.

Tap the tile opens one realm detail with **Overview / Work / People** sections. Route used to anchor
the realm is historical detail, not portfolio-level hierarchy. A realm may be renamed to 1–32
trimmed visible characters; duplicates are allowed because `World N` remains visible, and an empty
or control-only name restores the generated fallback. Names never become stable identity.

Dormancy preserves the same tile and cover. It does not move the realm to a separate forgotten list.
Filters **All / Active / Dormant / Attention** may appear once the portfolio exceeds six realms.

## Work selection

The Work tab implements the existing narrow production contract:

- each realm begins at **Maintain only**;
- one discovered eligible renewable source may be selected as Current work;
- preview shows sustain paid first, surplus Worldwork per outcome, current progress/threshold,
  expected next completion and tray capacity;
- unavailable/depleted source pauses visibly and never redirects itself;
- changing source preserves entry-specific partial progress and commits no output immediately.

Sources are compact resource tiles, not a picker of internal IDs. Unknown, finite, unique or
undiscovered sources never appear as locked options.

## Person assignment

Selecting **Post someone** opens person identity tiles with their current location and consequence
preview. Candidates include every recruited human eligible for realm posting, including people at
Home, in another realm or currently selected for the next party; animals follow their separate
capability rules and are not implied by this screen.

Opening a candidate shows:

- visible Worldwork label/rating and exact contribution;
- current location;
- target realm's sustain/harvest before → after;
- whether the person leaves the active party;
- the exact Home keeper/station benefit suspended, if any;
- confirmation text that current realm work has no injury or permanent-loss risk.

Confirm atomically removes that stable person from Party/Home/another realm and posts them here.
The target's production preview then updates. Cancel, stale person/location or dormant target changes
nothing. **Return Home** likewise removes only this posting; it never silently adds the person to the
active party.

There is no arbitrary worker cap. Additional workers remain meaningful only through sustain and one
selected production source, while their loss from Party/Home supplies the opportunity cost. If play
shows that piling workers is always correct, tune production thresholds or add diminishing surplus
conversion before inventing job classes.

## Settlement is an explicit decision matrix

After the ordinary expedition recap, every active realm with a remaining shortfall receives one
required decision:

- **Sustain · N Essence**
- **Let rest** — becomes dormant; posted people return Home safely.

No choice is preselected. **Confirm settlement** remains disabled until every due realm has an
explicit choice. Thus opening and confirming the sheet cannot accidentally dormant the whole Atlas.

The sticky footer shows:

- Essence available;
- selected payment;
- Essence remaining;
- ordinary authored-bind runway after payment;
- count of realms that will rest.

If selected payment is unaffordable, confirm is disabled and the exact shortfall is named. The player
may revise choices; the game never silently chooses which realm rests. One atomic outcome-receipt
transaction pays selected realms, dormants the rest, returns their workers, settles production and
records all consequences. Relaunch reopens the unresolved decisions without ticking again.

## Reactivation

Opening a dormant realm shows exact Essence cost, preserved work progress/deliveries and what resumes.
Reactivation is an explicit confirmed atomic action. It does not restore prior workers, collect the
tray, advance work or immediately charge another settlement obligation. People are reposted
deliberately after reactivation.

## Delivery collection

Deliveries groups only realms with nonempty trays. Each tile shows resource identity, exact quantity,
source realm and available Storehouse/spillover capacity. **Collect all that fits** previews where
each output goes; full capacity leaves the remainder in its exact tray. There is no discard or
automatic sale/recycle. Collection is idempotent and cannot duplicate an outcome receipt.

## Identity and migration

Realm and worker references use stable IDs. `runIndex` and roster indices remain legacy migration
evidence/display facts, never new assignment identity. Migration must reconcile duplicate locations
to one authoritative placement, preferring an active expedition/party, then one realm, then Home,
while reporting the repair in DEBUG.

The portfolio's selected tab/filter/realm are UI preferences. Settlement choices are durable pending
transaction state because force-quit must not reinterpret them.

## Acceptance

1. One, six and twelve-realm fixtures remain browseable without one giant card per realm; dormant
   realms retain their identity and position.
2. Assignment preview truthfully shows Party/Home/other-realm displacement and before→after
   sustain/harvest; stale/cancel paths are zero mutation.
3. Stable-person reorder and save/load cannot move the wrong worker.
4. No-touch settlement cannot confirm. Every due realm requires Sustain or Let rest, and payment plus
   dormancy commits exactly once per outcome.
5. Insufficient Essence never silently changes selected realms or spends a partial payment.
6. Dormancy/reactivation preserve realm map, work progress and deliveries; workers return safely and
   are never auto-reposted.
7. Delivery collection handles partial capacity without loss, duplication or auto-conversion.
8. At 368×800 and large text, realm tiles, detail, candidate consequences, decision matrix and sticky
   totals are reachable; VoiceOver announces state, attention, cost, displacement and result without
   relying on colour.

