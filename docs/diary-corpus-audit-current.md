# Current Design — Diary Corpus Audit

**Status:** corpus-complete for 28 designed travellers; Tam remains an explicit endgame hold. This
document audits structure and implementation safety, not numerical page-drop balance.

## Coverage

| Cohort | Travellers | Final page totals | Authority |
|---|---|---|---|
| Implemented six | Mara, Edren, Halloway, Isolde, Sela, Tovin | 6, 7, 6, 7, 7, 14 | `implemented-six-diary-packets-current.md` plus live catalog |
| Early–mid | Bryn, Orsa, Vance, Talin | 7 each | `diary-packets-early-mid-current.md` |
| Midgame | Nessa, Corrin, Dagg, Rook, Lys | 8, 8, 8, 8, 9 | `diary-packets-midgame-current.md` |
| Five-condition | Bracken, Fen, Wren, Kestrel, Maud | 8, 8, 9, 9, 9 | `diary-packets-five-condition-current.md` |
| Formation | Marrick | 10 | `diary-packet-marrick-current.md` |
| Late specialists | Sabine, Grimmond, Oda | 10, 11, 12 | `diary-packets-seven-eight-current.md` |
| Late embodied/process | Auber, Ashe | 12 each | `diary-packets-auber-ashe-current.md` |
| Interpretive endgame | Perren, Nine | 12, 13 | `diary-packets-perren-nine-current.md` |

This is **251 target pages across 28 books**. The expansion packet tables contain 204 unique page IDs.
The implemented-six handoff adds fourteen unique IDs around existing live pages; their remaining IDs
remain owned by the live catalog. Tam has no packet because writing it now would conceal unresolved
endgame design behind polished prose.

## Structural audit results

| Invariant | Result | Evidence |
|---|---|---|
| One location page per signature condition | Pass | Packet row counts match the signature counts for all 22 expansion travellers; implemented six retain their audited pairing |
| One singular mechanical teaching per book | Pass | Focus, gambit, pattern and schematic pages name one reward ID; narrative pages do not bundle rewards |
| No duplicate authored expansion page IDs | Pass | 204 table IDs scanned; 204 unique |
| No duplicate IDs including implemented-six additions | Pass | 218 authored/addition IDs scanned; 218 unique |
| Own reward never required by signature | Pass | Every signature document has an explicit reward-dependency boundary |
| Relationships do not gate discovery | Pass | Every packet requires them to be redundant and validation-gated |
| Unknown references cannot silently no-op | Pass | Packet rules require deferral or catalog failure |
| Recruitment and diary completion remain separate | Pass | Shared packet rules preserve the settled discovery loop |
| Late book length adds story, not extra locks | Pass | Counts above signature length are focus/relationship/site/account pages |
| Perren/Nine avoid hidden chronology/true-self reveal | Pass | Their packet has explicit narrative-structure constraints |

## Implementation readiness bands

### Ready with existing generic schema

- location clues, known focuses, known sites, worthwhile-world pages and validated whereabouts pages;
- ordinary account/turn prose once the page-kind enum has a non-reward narrative value;
- existing-six additions listed as `add now` in their authority document.

### Ready once semantic reward IDs land

- gambit teachings for Bryn, Talin, Dagg, Rook, Wren, Kestrel, Marrick and Ashe;
- Maud's singular fitting pattern;
- Oda's singular emanation-housing schematic.

The reward page must grant the named component and nothing else. A semantic ID may map to an existing
stable code ID only when the player-facing meaning is identical and the mapping is recorded.

### Strictly deferred

- any relationship page whose target traveller definition is absent;
- Ashe's `spent_emanation_housing` until its current placeholder definition exists in the live catalog;
- any later focus whose pressure-source profile has not passed the mechanical vocabulary audit;
- Tam's entire book.

## Remaining corpus risks

1. **Drop pacing:** the one-writing-per-world guarantee and per-diary eight-world fallback need a
   full-corpus simulation. The fallback advances one eligible diary page at a time, never all stale
   books simultaneously.
2. **Late accidental matches:** signatures with seven to nine conditions need generated-fixture
   measurement, especially Perren's survivability and Nine's Drift/Tide combination.
3. **Page-kind display:** `gambit`, `pattern`, `schematic`, `account` and `turn` need clear Library
   labels without pretending every prose page is a research lead.
4. **Focus fixtures:** all eighteen focus profiles now exist across the two current profile docs;
   the later twelve still need single-focus and representative compound generation fixtures.
5. **Forward-reference rollout:** validation must support authoring a complete future book while
   exposing only pages whose current references resolve.

## Tam boundary

Tam is retained as traveller 29 but intentionally excluded. A packet begins only after the Great
Work's endgame operation, Reality reset purpose/reward, and Glass-versus-quartz role are settled. No
temporary focus, act or diary prose should become content authority before that pass.
