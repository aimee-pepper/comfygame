# Game Design and UX assessment — current

**Status:** lead assessment and product-direction authority; not an implementation queue by itself  
**Updated:** 20 August 2026  
**Evidence boundary:** current source/content authorities, `origin/main` at `66f728f`, the clean
installed-candidate branch `2d2e7ce`, immutable AssetLab records and retained phone artifacts. The
Simulator service was unavailable during this pass, so this does not pretend to be a fresh hands-on
runtime review.

## Honest overall take

Bookbinder has a genuinely excellent game at its centre: **write a world, enter the consequences of
your language, learn how reality works, and write more deliberately next time**. That is distinctive,
coherent and capable of supporting a long campaign. The data model and procedural causality are far
more mature than most prototypes at this stage.

The current product does not yet deliver that promise with the same strength. It is a broad,
technically impressive integration prototype whose first hour is still less finished than several
systems the player will not reach for weeks. Too much of the experience reads as operating an app or
inspection tool: choose from cards, read a ledger, open another menu, confirm a transaction. Recent
UI and asset work is moving in the right direction, but it is split among approved screenshots,
isolated candidates, native branches, installed builds and unresolved reviews.

The biggest risk is no longer “can the simulation work?” It can. The risk is that the simulation's
most magical idea remains buried beneath workflow, incomplete feedback, uniform prose and unfinished
early progression.

## What is strong

### 1. Writing has real causality

Sigils are not cosmetic spell words. They resolve into pressures that affect terrain, life,
resources, sites, stability, travellers and history. The 6×6 page also gives writing a physical
shape without falsely making placement mean something it does not. This is the project's clearest
competitive identity and should remain the centre of every major loop.

**Protect it:** whenever adding a system, ask whether it gives the player a new reason to write a
particular world or a new way to understand the world they wrote. If it does neither, it should not
displace core-loop work.

### 2. Discovery respects the player

The Dictionary's `??` entries, clues that point toward world facts without naming runes, progressive
analysis and persistent history support deduction instead of front-loaded explanation. Starting and
wild World Pages can teach by example without turning the opening into a tutorial sequence.

**Protect it:** opacity should conceal interpretation, not basic facts or controls. A clue may say
“the soil stays waterlogged” and let the player infer Hydrology; it should not make the player decode
an aphorism before they can even identify the sought property.

### 3. The world has coherent material logic

Creature traits drive combat and remains; flora, resources and terrain derive from the written
world; exact instances retain provenance. This makes eventual planning and hoarding meaningful in a
way a generic loot table cannot.

**Exploit it:** rewards should repeatedly reconnect to origin—what world produced this, what did the
creature or plant imply, and what new world can this material help write or survive?

### 4. The long campaign has promising human structure

The traveller order, individual stations and diary cross-references can make progression feel like
assembling a community rather than unlocking a technology menu. The best station designs change a
field decision because a person taught or prepared something, even when that person travels with
you.

**Protect it:** every station needs one distinct first payoff and one owner-shaped reason to exist.
Do not let the Base become a collection of rooms whose only difference is the noun on their shop.

### 5. Correctness foundations are unusually strong

Stable identity, tolerant decode, idempotent receipts, deterministic generation and focused
validators reduce the chance that a long campaign becomes untrustworthy. That investment is
valuable for this particular game because the player is meant to care about provenance and history.

**Use it selectively:** correctness work should follow player-visible risk. It supports the game;
it is not a substitute for making the loop enjoyable.

## What is weak or unfinished

### 1. The first three worlds are not yet a finished vertical slice

Campaign selection, Home, Writing Desk, World exploration and Return Recap each have substantial
work, but not one shared accepted presentation. Encounter scaling is only partly playtest-accepted.
This means the most repeated path is still being judged screen by screen instead of as one game loop.

**Correction:** make one milestone called **The First Three Worlds**. It ends only when a fresh save
can choose a starter page or write freely, survive Normal encounters, understand the world, return,
inspect rewards and afford the next authored bind three times without DEBUG help.

### 2. The core fantasy is underexpressed moment to moment

The underlying simulation is rich, but the player often sees grids, numbers, prose cards and generic
icons. Worlds can feel like recoloured boards rather than places caused by a written page. Loot can
feel like receipt rows rather than tangible evidence brought home.

**Correction:** prioritize causal feedback over decorative polish:

- entry splash and world palette visibly echo the strongest authored and emergent pressures;
- terrain/flora/resource silhouettes reflect relative world diversity while similar worlds stay
  related;
- brief world-relevant notes and blocked-movement text name the actual local fact;
- return presentation groups recognizable objects and resources, then explains their provenance on
  tap;
- the Writing projection previews tendencies and uncertainty, not an exhaustive spreadsheet.

### 3. Combat is functional before it is compelling

The rules have real depth and a strong graph authority, but the production experience still lacks a
fully accepted early difficulty curve and a complete native expression of meaningful build choice.
For a new save, one bad grouping can currently dominate the player's impression of the entire game.

**Correction:** finish level/party scaling before deeper nodes. Then make the first three earned
points produce a visible fork with different tactics, not merely different numbers. A fight should
quickly answer: who is threatened, what can reach whom, what changed, and why did this world produce
this opponent?

### 4. Authored character breadth must stay reachable

The live catalogue now resolves one meeting for all 29 recruitable travellers through the retained
eight-meeting catalogue baseline plus the 23-entry generated authored corpus, with Noll and Auber as
intentional replacements. This closes the former missing-live-content gap without making advance Atlas
approval a release gate.

**Current correction:** preserve campaign reachability and review these meetings in play. Encounter order,
signature eligibility and at-most-one traveller per world—not missing meeting data—now determine when Aimee
sees the content. Preserve stable IDs and revise exact copy after reports rather than reopening a separate
promotion project.

### 5. Voice and clue clarity still threaten player trust

The corpus has improved, but the historical default voice is polished, elliptical and faintly
adversarial. When many characters share it, nobody feels human; when clues use it, deduction becomes
guessing the author's metaphor. Nine can remain fully lofty. The rest need the settled range of
practicality, warmth, humour, bluntness and abstraction.

**Correction:** every location clue begins with one readily visualized world fact. Character voice
may interpret it afterward. Meetings and diaries should be promoted and revised band by band using
`full-cast-voice-authority-current.md`, not held for one giant final prose pass.

### 6. The interface still overuses containers and navigation

Six-across object trays, identity tiles and spatial destinations are the right semantic grammar, but
many native surfaces still rely on large cards, full-width rows and separate detail screens. Some
recent mockups improved appearance while inventing behavior, which creates rework instead of UX
progress.

**Correction:** use the object itself as the control. Physical things are icons with anchored detail;
people are identity tiles into tabbed pages; places are destinations; ordered text remains a list.
Limit ordinary scrolling when the finite primary set fits. Keep primary actions next to the evidence
needed to choose them.

### 7. The roadmap makes progress harder to perceive

Dozens of items are labelled `readyToTest`, while visual approval, source completion, shared
integration, device installation and actual acceptance are different facts. A separate clean branch
is on the phone while the shared checkout is 41 commits behind `origin/main` and contains unrelated
dirty packets. That is a process defect with direct product cost: leads can act on the wrong version
of the game.

**Correction:** use the receipt vocabulary in `cross-lead-delivery-contract-current.md`; only one
item is “test now.” Before any assignment, reconcile origin, installed provenance, dirty ownership
and current approval. No lead begins a new feature from a stale shared checkout.

## Product direction

### Near term — make the game believable

1. Reconcile and close Campaign/Home/Writing/World/Return as one native first-loop chain.
2. Complete the remaining encounter-scaling acceptance matrix for levels and party sizes the player
   can currently reach.
3. Prove three fresh-save expeditions, including a failure/emergency return, continuation Essence,
   correct writing/people/loot/XP and understandable blocked terrain/collapse text.
4. Make the already-built Trading Post/Recycler/Storehouse loop visually tangible and reliable; do
   not expand specialist economy yet.

### Next — make the first progression arc satisfying

1. Ship opening-trio meetings and pacing in ordinary play.
2. Finish Band-2 object identity and compact Library/Storehouse/equipment interaction.
3. Expose the first meaningful combat fork and the three starter World Pages.
4. Continue world-colour and entry-splash work only where it consumes real generator facts.

### Later — deepen, then broaden

1. Brush and Ink Mixing, Mara/Edren/Sela contributions and the Band-3 cast.
2. One complete combat route plus sustainable Apothecary/Tannery preparation.
3. Specialist shops and alternative builds.
4. Late stations, anchoring and simulation breadth only when a real campaign can reach them.
5. Tutorials remain dead last, after the mechanics and layouts they would teach are stable.

## The standard for “good enough to advance”

Advance a band when the player can complete its loop, understand the important result, make at least
one meaningful choice and want to repeat it. Do not require final art, exhaustive accessibility or
perfect balance. Do require an intentional ordinary-phone presentation, truthful feedback, no
blocker and one installed build Aimee has actually played.

If the next proposed task does not shorten or enrich that playable path, it waits.
