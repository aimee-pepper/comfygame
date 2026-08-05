# Questions for Design — from Claude Code

Ambiguities hit while building. Each one has a **conservative interpretation already shipped**, so
nothing is blocked; answering just tells me whether to keep or change it. Answers belong in
`decisions-log.md` (newest entries win).

Format: question → what I shipped → where it lives in code.

---

## Milestone 1 (2026-08-04)

### Q1. Which layer owns the encounter-flag registry (the bestiary)?
The brief requires "encountered" flags per creature/resource type from milestone 1, but doesn't say
which persistence layer holds them.

**Shipped:** the **Reality** layer — knowledge is Pokédex-like, and a future base reset taking away
"you have seen this creature" feels like erasing the player's history rather than the character's
possessions.

**If the answer is Base:** move `discovery` from `RealityState` to `BaseState`. Nothing else changes.
`Sources/Model/Discovery.swift`, `Sources/Model/RealityState.swift`.

---

### Q2. The starter collection is labelled 10 symbols but lists 11.
`design-brief-v0.md` heads the list "Starter collection (10 symbols)" and then names eleven:
3 terrain (Plains, Caverns, Archipelago) + 3 biome (Verdant, Ashen, Frostbound) + 3 bounty (Sparse
Ore, Rich Ore, Teeming Life) + 2 quirk (Dim Sky, Gilded Veins).

**Shipped:** all **11** named symbols — dropping one to hit the count would silently remove content
you named explicitly.

**If it should be 10:** say which one starts locked and I'll flip its `acquisition` to `research`.
`Sources/Content/Data/symbols.json`.

---

### Q3. What does a station "tier" count?
The brief says the Storehouse starts at 8 slots, "+4 per Storehouse upgrade (3 tiers tonight)".

**Shipped:** tier = **upgrades purchased**, so tier 0 is the built, un-upgraded station.
Storehouse 0→3 gives 8 / 12 / 16 / 20 slots, i.e. three purchasable upgrades.

**Alternative reading:** "3 tiers" means three states total (8 / 12 / 16, two upgrades).
`Sources/Content/Data/stations.json`, `Tuning.Economy`.

The same question applies to the Essence Spring, where the brief says "Tier 1 built-in; Tier 2
upgrade purchasable". Shipped as: tier 0 = the built-in trickle, tier 1 = the one purchasable
upgrade. Amounts are PLACEHOLDER (3 and 7 essence per return).

---

### Q4. Do Motes bank straight into the Reality layer?
Motes are the Reality-layer currency but they're picked up inside a world, which means a mote sits
in a run's satchel — a Worlds-layer object — until banked.

**Shipped:** on banking, motes go to `reality.motes` while everything else goes to `base.resources`.
An unbanked mote lost in a collapse is lost like any other haul.

**Open sub-question:** should motes be exempt from collapse loss, given they're the permanent-layer
currency and the brief's sources for them (locked caches, Mythic drops) are already rare? Related to
Q-F in `open-questions.md`, which I'm not touching.
`Sources/Debug/HarnessActions.swift` (`bank`).

---

### Q5. Working title and bundle identifier.
**Shipped:** target/product `Bookbinder`, bundle ID `com.aimeepepper.bookbinder`, display name
"Bookbinder". The brief says rename freely — say the word and it's a one-line change in
`project.yml` plus `xcodegen generate`. (Renaming the bundle ID resets the save file on device,
since Documents is per-bundle-ID.)

---

### Q6. Is there a cap on the run satchel?
Resources are stackable and slot-free, but *items* found in a world need somewhere to go, and the
brief only gives an inventory size for the Storehouse at base.

**Shipped:** the run satchel carries its own item capacity, currently copied from base capacity at
depart time. A full satchel refusing loot mid-run is a real design moment (do you drop something?),
so this shouldn't stay accidental.
`Sources/Model/WorldsState.swift` (`WorldRun.satchelItems`).

---

## Milestone 2 (2026-08-04)

### Q7. How much does the preview reveal about slots left to chance? **(the interesting one)**
Two locked rules pull against each other. "Legibility before commitment" says show the player what
they're buying. "Empty slots are random-filled — under-specification is a surprise" says don't.

**Shipped:** an unfilled slot turns every headline number into a **range**. A book with all four
slots empty reads "Stability 53–100 · holds ~17–104 turns · tier 1–4 · cost 19–28". Fill a slot and
the ranges narrow; fill them all and they collapse to exact numbers. You always know the bounds
you're signing up for; you don't know where inside them you'll land. The harvest/inhabitant mixes
show *expected* shares rather than ranges, because a column of ranged percentages is unreadable.

A test (`BookRulesTests.testEveryPossibleRandomFillLandsInsideTheProjectedRange`) checks 200 seeds
to prove no actual bind can escape the range the player was shown.

**The sub-question I'd most like answered:** the player is currently **charged for symbols they
didn't choose**. "Cost scales with total symbol value" reads as including random fills, and the
bind button quotes the worst case up front — but "you must be able to afford up to 28 for a book
you didn't specify" may feel like a tax on under-specification, which is meant to be playful. The
alternative is that random fills are free, which makes leaving slots empty strictly cheaper and
turns under-specification into the budget option.
`Sources/Rules/BookProjection.swift`, `Sources/Screens/PreviewPanel.swift`.

---

### Q8. What does the Reality unlock's 5th book slot actually hold?
"+1 symbol slot in books" is one of the three Constellation nodes, but the slot taxonomy is exactly
four kinds (Terrain / Biome / Bounty / Quirk). A fifth slot has to be *something* — a second quirk?
a free choice of any kind? a new kind entirely?

**Shipped:** nothing. `RealityState.bonusBookSlots` exists and is not yet read by the book model,
which still has exactly four slots. The node is unpurchasable until milestone 5, so this isn't
blocking — but the answer changes `BookDraft` from a fixed four-key structure into an ordered list,
which is easier to do before there are saves in the wild.
`Sources/Model/BaseState.swift` (`BookDraft`), `Sources/Model/RealityState.swift`.
