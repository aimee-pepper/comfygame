# Current Playtest Triage — 9 Aug 2026

**Status:** 9 Aug triage snapshot and still-current issue interpretation; it no longer owns live
implementation order. `Sources/Content/Data/playability-roadmap.json` is the operational board.
Screenshots and the original observations are retained in the Design Lead task.

## Priority against the existing queue

| Order | Issue | Priority and scheduling | Current direction |
|---|---|---|---|
| 1 | Tutorial distorted the world layout and the map clipped a fractional bottom row | **Fixed and accepted 9 August after reopening.** Lossless phone evidence shows all 11×11 whole cells/full bottom border; tutorial is an overlay; Aimee visually accepted restored controls. Full suite 810/0. | Preserve `world-map-phone-overlay-v2.png` and `world-map-phone-controls-v2.png`; whole-pixel cell sizing, overlay independence, D-pad left/minimap right/Portal below are regression contracts. |
| 2 | Prolonged black screen on app launch | **Fixed and accepted 9 August.** Native v1 records cold/warm timings, matching static/in-app pages, honest timeout/failure recovery, serialized writers, VoiceOver transitions and ordered no-black-gap evidence; full suite 816/0. | Preserve `app-launch-loading-current.md` and `docs/test-artifacts/app-launch-acceptance-v1.md`; optimize measured phases without removing truthful state or save safety. |
| 3 | Native top-down terrain/flora and explore-first minimap disclosure | **Implemented and pushed 9 August (`a7a99bc`).** Exact published terrain/flora vectors, canonical manifest, deterministic seed/grade adapters, literal fog, pixel rastering, DEBUG fallback and all-POI/crypsis gates are fixture-covered. | Preserve `top-down-map-asset-integration-current.md`; future art changes require a new versioned contract rather than approximate native drift. |
| 4 | Isolde meeting choices reorder a prewritten transcript and terminal replies appear at the wrong time | **Correctness fix implemented and pushed 9 August (`95d1778`).** | Preserve ordered stable-ID exchanges and readable terminal replies. Current Isolde copy remains until Aimee reviews its revision candidate. |
| 5 | Authored dialogue/clue atlas and review flags | **Implemented tool; derived-union census correction queued.** | DEBUG-only browser covering every live/draft traveller meeting node and live diary page, with Good / Needs revision / Unreviewed, optional notes, filters and export. Four review documents supply 21 missing-live drafts plus review-only Noll; atlas rows must derive the 29-identity live∪draft union rather than omit Noll. |
| 6 | General encounter and apex difficulty | **Scaling is ready to test; apex contact correction queued.** | Test the additive-power profile in `encounter-scaling-playtest-current.md`. Independently, adjacency must never aggro an apex; only deliberate entry onto its occupied tile starts combat (Decision169). |
| 7 | Reduced detection / encounter avoidance | **Medium feature after scaling.** Existing Shadow promises are correctness; the new Scent Mask remains paired with DRQ-044 review. | Use `field-awareness-avoidance-current.md`: readable unaware→alert→pursuing state, nonstacking Shadow nodes, persistent hesitation and existing Lure as the risky opposite. |

New tutorial-content implementation is now lowest priority while Aimee is the sole tester. The
tutorial overlay/layout defect in row 1 is not tutorial content: it is a live world-screen regression
and remains P1.

## Authored-text audit: completed first pass

### Isolde meeting

The underlying scene has a usable idea: Isolde is rehearsing the physical discipline of a writing
hand on a blank board. The current presentation destroys that idea by displaying all three questions
and replies as though the player asked them in sequence. The lines also rely too heavily on the
player immediately understanding “the hand goes first.”

Recommended revision boundary:

- retain the blank board, bone stylus, exacting teacher voice and charcoal recognition;
- make each question produce a genuinely self-contained reply;
- let the charcoal branch be the clearest progression branch, because it establishes why Isolde and
  the Scriptorium matter;
- keep recruitment available regardless of which optional question was asked; questions reveal
  character and context rather than acting as a hidden correct-answer test;
- do not show the declined line before the player chooses Leave.

Provisional clearer reply direction for the first question (not settled authored copy):

> “The board is for resistance, not ink.” She draws the line again, slower. “If the hand cannot keep
> its course here, giving it charcoal only records the mistake.”

### Sabine diary

`sabine_where_2` currently reads:

> Every appetite rests inside another. Feeding one body alters a relationship, not merely a bowl.

It encodes trophic depth, but it reads as an abstract maxim without a concrete image. The same issue
affects much of Sabine's seven-page location sequence: it repeatedly states an ethical conclusion
(`care`, `trust`, `obedience`, `leash`) before giving the player enough observable world evidence.

Recommended corpus rule: each location clue should lead with something the Binder could see in the
target world, then allow one short Sabine inference. The page must still make sense when shown alone
in expedition loot.

Provisional replacement direction for `sabine_where_2` (not settled authored copy):

> Small grazers crowd the new growth. Larger tracks circle them, and scavengers follow what the hunt
> leaves behind. Feed one creature here and three others change their route.

This communicates a layered food web and the consequence of feeding without requiring the player to
decode “every appetite rests inside another.” The remaining six Sabine location pages need the same
concrete-image pass as a set, not isolated synonym replacement.

### Whole-corpus result

A mechanical scan of all 233 live pages does not decide prose quality, but it exposes a useful review
cluster. The most abstraction-dense location clues are concentrated in **Sabine, Marrick, Oda, Ashe,
Kestrel and Nine**. Recurring constructions include “X is evidence, not Y,” “X does not mean Y,” and
ethical conclusions using *consent, obedience, consequence, relationship,* or *interpretation*
without a preceding concrete event. These constructions are appropriate occasionally and often work
better in relationship/reflection pages; repeated across location clues they obscure the world the
player is meant to write.

The manual pass is now complete across all 233 pages and all seven live meeting objects; exact
routing and the 18 page-revision candidates live in `authored-text-audit-current.md`. This audit is
not authority to bulk-rewrite copy. Each recommended revision remains visible in the atlas for
Aimee's approval, and the other 21 travellers are labelled Missing rather than reviewed.

## DEBUG authored-text atlas contract

For every traveller, expose:

- identity, authored order and campaign phase;
- meeting opening, every selectable question paired with its exact reply, offer, accepted and
  declined copy, including stable node IDs;
- every diary page in intended authored order with kind, `about`, clue index, unlock/dependency,
  mechanical target in development language and exact player-facing prose;
- current validation warnings: missing target, forward-reference gate, duplicate/near-duplicate
  prose, missing branch response and rendered markdown/token issues;
- review state **Unreviewed / Good / Needs revision**, optional note, reviewer timestamp and corpus
  version/hash;
- filters for character, text type, review state and validation warning, plus Copy/Export report.

The atlas must render text through the same formatting path as the player UI. Flags belong in a
separate debug review file or export, never inside a save and never in release UI.

## Encounter scaling direction for specification

The live ordinary-foe level formula already uses party level, Stability and greed, but encounter
creation currently supplies only the Binder and one legacy companion when choosing party level. It
does not honestly represent the full active party. Correctness comes before adding difficulty:

1. derive the level reference from all active travel-party members (recommend the rounded upper
   half/median-high level rather than the single maximum, so one veteran cannot punish new members);
2. add modest party-size pressure primarily through enemy count/composition and enemy action economy,
   not large HP inflation;
3. retain a hard phone-readable foe cap and use stronger/variant foes when the cap is reached;
4. give apex encounters a separate, clearly higher floor and multiplier after ordinary scaling;
5. expose all coefficients and a generated encounter preview in DEBUG tooling before tuning them.

Working target for later simulation, not a settled number: solo is baseline; each additional active
party member adds roughly half an ordinary-foe budget, with composition choosing how to spend it.
Apex should be balanced as an optional deliberate challenge for the current party and must preserve
visible approach, no ambush and the ability to Unbind.

### Reversible simulation profile

Use this only as the first DEBUG/simulation profile, not a shipped balance declaration:

- **Party level reference:** sort the levels of `base.partyMembers` and use the upper median. This
  includes the Binder and every valid active traveller, resists one over-levelled carry, and does not
  let several developed companions disappear behind the legacy `activeCompanion` accessor.
- **Ordinary encounter budget:** `1.0 + 0.5 × (partyCount - 1)` ordinary-foe equivalents before
  world danger. Spend whole equivalents on additional nearby foes up to the three-foe readability
  cap; deterministic half-budget alternation or a stronger specimen spends the remainder.
- **World danger:** retain Stability and greed contributions to foe level. Do not count them again by
  multiplying the group budget unless testing shows the current expression is too weak.
- **Apex level floor:** at least upper-median party level +2 after world scaling.
- **Apex durability:** begin testing at `1 + 0.35 × (partyCount - 1)` HP, capped at 2.4×. Apply this
  after the apex's trait-derived identity so it remains recognisably that creature.
- **Apex tempo:** a lone apex needs action economy, not only a larger health bar. Test one action slot
  for parties of 1–2, two for 3–4 and three for 5. Prefer distinct legal targets/actions per round;
  never let the same high-damage action repeat three times without a readable rule.
- **Apex offence:** start with only a modest party-size modifier (10% per additional member, capped
  at 40%) because extra actions already increase pressure. Avoid one-hit defeat as the main answer.

The DEBUG encounter preview should show party count/levels, chosen upper median, Stability and greed
level contributions, ordinary budget and spend, apex floor, HP/offence multipliers, action slots and
the final derived combatants. Sliders must include ordinary party-size budget, apex level offset,
durability, offence and action-slot thresholds, with Reset to current profile.

## Reduced detection and encounter avoidance direction

This is not a wholly new system. The approved Shadow branch already promises **Quiet Step, Low
Profile, Vanish, Shadowed and Unseen**, and the live catalogue/loadout includes
`encounterChance`, `sightedAtRange`, `partySightedAtRange`, `freeFlee` and the concealment capstone.
Combat consumes some of this vocabulary, but ordinary world detection does not currently consume
the notice fields. First priority is therefore to make the existing skill promises true; items then
provide alternate temporary access rather than competing mechanics.

This fits the game if it creates preparation and route choices rather than deleting exploration.
Use one readable **notice modifier** consumed by the existing detection-radius calculation:

- a Shadow skill can reduce ordinary creature notice range while exploring;
- a crafted scent-masking consumable can prevent animals from waking for a short number of world
  turns, but does not affect hostile flora or non-animal threats;
- light/noise/conspicuous equipment can create trade-offs rather than a permanent universal cloak;
- an explicit field action or consumable may let the player disengage before contact at a cost;
- apexes remain visible, stationary and opt-in; avoidance never makes their location unknowable.

Detection effects must be shown in the HUD/tile targeting preview and must not produce invisible
coin-flip aggro. Multiple sources should use a cap rather than stack to permanent immunity.

**Reversible interpretation of legacy `encounterChance -0.25`:** do not silently cancel one quarter
of otherwise identical bumps. Re-express Quiet Step as a deterministic field advantage—prefer one
extra grace/hesitation turn the first time an ordinary mobile animal would wake, while Low Profile
and Shadowed reduce notice radius. Adjacent contact, attacking, loud interactions and already-awake
pursuit still work normally. This keeps “fewer encounters trigger” true through player-readable
position and timing rather than an invisible coin flip. Confirm exact migration with Aimee after the
first debug visualization.

The later authoritative pass deliberately keeps the first slice smaller: existing Shadow nodes,
one reviewed **Scent Mask** consumable and the already-authored **Lure**. Softstep footwear and a
separate thrown-lure item are not current; add neither as catalogue symmetry. See
`field-awareness-avoidance-current.md` for the exact nonstacking and sensory-channel rules.
