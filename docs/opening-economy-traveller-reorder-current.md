# Opening economy traveller reorder — current design

**Status:** current authored-order decision; Noll/Recycler native playtest promotion is approved by
Decision 182, while exact prose and Field Separation Kit remain independently reviewable.  
**Updated:** 11 Aug 2026

## Decision

The first three intended people found are:

1. **Vance — Trader/Appraiser — Trading Post**
2. **Noll — Salvager — Recycler** *(stable reversible identity; they/them)*
3. **Halloway — Blacksmith**

These three share the earliest **story arrival band**, not a universal person-by-person gate. Every
person still requires a complete signature match. When several from this band match, recovered
location clues and causally matching player-written conditions break the tie, then authored order.
No later-band match can displace a simultaneous opening-economy match. `traveller-world-pacing-current.md`
owns the one-person cap, blind frontier and exact deterministic selection. Quill is already at Base
and is not counted as somebody found.

## Why this opening is stronger

The first expeditions already create resources, unwanted objects and found gear. Trading Post gives
surplus a flexible destination; Recycler gives finished surplus a materially different destination;
then Blacksmith makes retained resources and equipment actionable. The opening therefore teaches
**sell versus reclaim versus keep/make** through use, before asking the player to hoard for a long
station chain.

This also supports the corrected Essence loop: optional spending becomes visible early, but neither
station may consume so much Essence that it prevents the next authored world.

## Role split

### Vance owns the Trading Post only

Vance remains a trader and appraiser concerned with circulation, price, provenance and unequal need.
He buys/sells identified transferable holdings, rotates capped ordinary stock and appraises sale
bands. He does not operate the Recycler or determine material recovery.

His existing Amber teaching, voice and relationship network remain strong. References saying he
understands recoverable material because he followed objects through owners are narrowed: he knows
what an object's history does to value, not how to disassemble it honestly.

### Noll owns Recycler only — approved reversible identity

Noll reads an object as a sequence of joins: what can be separated, what has been transformed past
recovery, and which claimed origin would be a lie. They are patient with material and impatient with
sentiment used to conceal waste. Their tension is that dismantling can preserve usefulness while
destroying the only whole form in which a history was legible.

They are not a merchant, smith or generic scavenger:

- **Vance** decides whether something should circulate and at what price.
- **Noll** decides what can honestly be recovered from a finished thing.
- **Halloway** makes, repairs and reforges things intended to remain whole.

Working blurb:

> Knows where an object will part before touching it. Keeps a ledger of the pieces that should not
> have been separated.

Working relationship anchors: Vance (price versus recoverability), Halloway (repair versus
unmaking), Corrin (organic layers and exact provenance), Lys (the whole object as record).

Noll's current reversible diary teaching is the `field_separation_kit` pattern specified in
`traveller-identity-noll-recycler-current.md`: a single-use, tier-1-efficiency field dismantle with
the ordinary exact preview and recovery routes. It adds portable convenience without gating or
improving baseline Recycler correctness. It creates no world focus or intermediate scrap currency.

## Opening signatures and diaries

### Vance — one-condition opening signature

Use **Relief openness >= 68** provisionally:

> “A load can cross the horizon here without the land inventing a toll.”

This preserves his strongest existing route/circulation clue and is deliberately writable from
starter vocabulary. His former concentrated Substrate/Vitality conditions become non-location world
observations; they no longer gate recruitment. His six-page opening packet has one location page,
Amber, Orsa, a repaired-object history, a scarcity/world observation and the Binder's Workshop site.

### Noll — two-condition opening signature

Provisional, starter-writable profile:

| Condition | Threshold | Passage |
|---|---:|---|
| Substrate hard-form share | >= 35 | “Broken pieces keep their edges here. A join can be found again after the whole has failed.” |
| Substrate dispersion | <= 40 | “Useful matter keeps to seams instead of disappearing evenly into the ground.” |

The complete six-page packet is in `traveller-identity-noll-recycler-current.md`: two locations;
Vance and Halloway relationship pages; one world worth writing; and the reversible Field Separation
Kit pattern. The teaching does not block recruitment or first station usefulness.

### Halloway

Halloway retains the existing two-condition signature and complete six-page packet. Rewrite only
cross-order references that falsely assume Mara/Edren must already have been found.

## Station availability and costs

Both economy stations must perform one honest action immediately after construction and must not be
priced as midgame buildings.

- **Trading Post provisional build:** 10 Essence, no specific world resource. Vance supplies the first
  table/ledger; this is establishment, not a full trade hall.
- **Recycler provisional build:** 15 Essence, no specific world resource. Noll supplies their core
  tools; later upgrades ask for world resources.
- **Blacksmith:** retains its existing early construction bundle pending the resource-ID/reachability
  migration.

Essence-only opening costs are deliberate: requiring particular resources before Trading Post/Recycler
exist can make the route depend on random worlds and recreate the shortage these stations solve.
They remain DEBUG/playtest values. Construction is still a separate visible decision after
recruitment, not automatic station creation.

Recycler tier 0 must be useful on ordinary eligible found gear through authored salvage profiles;
crafted-receipt recovery remains equally valid when crafted gear later exists. Exact preview and
confirmation are baseline safety, never diary-gated.

## Revised authored order

| Order | Traveller | Phase | Conditions |
|---:|---|---|---:|
| 1 | Vance | opening | 1 |
| 2 | Noll | opening | 2 |
| 3 | Halloway | opening | 2 |
| 4 | Mara | opening | 1 |
| 5 | Edren | opening | 2 |
| 6 | Isolde | startOfMid | 2 |
| 7 | Sela | mid | 3 |
| 8 | Bryn | early-mid | 3 |
| 9 | Orsa | early-mid | 3 |
| 10–30 | Talin through Tam | retain current relative order, shifted by one | existing | existing |

The full roster table in `roster-progression-current.md` is the schema authority. The roster remains
expandable; adding Noll does not consume a final slot.

## Required validation

1. Fresh-campaign selection considers matching Vance, Noll and Halloway before any later band;
   evidence may change their internal order without allowing a later story cluster to displace them.
2. Blank/under-specified accidental matches do not make the intended order meaningless.
3. Vance and Noll signatures are writable with starter hand/vocabulary and never require Amber or
   Noll's `field_separation_kit` teaching.
4. Each built station is immediately useful with first-expedition holdings and does not require its
   own output/input economy to construct.
5. Sell-versus-recycle previews distinguish gold, bulk resources and exact property-bearing samples;
   no item can be sold and recycled in one interrupted transaction.
6. Existing Vance content migrates from combined ownership without losing his diary, relationship or
   reviewed prose history; obsolete exact-text reviews become stale where wording changes.
7. The opening-order simulation uses the one-traveller selector and evidence score from
   `traveller-world-pacing-current.md`; no first world produces a recruitment crowd or blind
   early-mid/later find, and multiple known clues influence the automatic result without a target UI.
