# The Merchant & the Recycler

**Status:** Claude's design from Aimee's brief. **[PLACEHOLDER]** numbers.

> **Superseded:** Current implementation authority is `trading-post-recycler-current.md`. Vance owns
> the independent **Trading Post** (`trading_post`) with rotating merchant stock; Noll owns the
> independent Recycler. The upgrade/Exchange model below is historical.

**The brief:** a merchant or trader for converting and selling resources, so a player can offload things eating inventory space. **The recycler is an upgrade to the merchant.**

---

<details open>
<summary><b>1. Where the merchant comes from</b></summary>

Session 12: **you don't research a shop, you find a trader.** So the merchant is a **Trader** — an eleventh class for the companions spec, found out in the worlds like everyone else, who unlocks the ability to build the **Exchange** at base.

**Trader as a class**, filling out the row:

| Class | Stat lean | In a fight | Unlocks / field skill |
|---|---|---|---|
| **Trader** | Perception, Focus | Back rank; support and consumables | **The Exchange** — selling, buying, later the Recycler. Field skill: appraises grade on sight |

*Appraises on sight* is a nice fit — a Trader in the party tells you what a material is worth before you decide whether to carry it home.

</details>

<details>
<summary><b>2. Currency — GOLD, convertible with essence (Aimee)</b></summary>

**Gold is the merchant's currency.** Separate from the essence ladder — but not sealed off from it.

### The two-way door

| Direction | Availability |
|---|---|
| **Junk → gold** | Always. The main reason the Exchange exists. |
| **Essence → gold** | Always. |
| **Gold → essence** | **Only when the rotating stock carries essence.** |

This is better than either option I offered. The economies stay distinct, so selling junk can't directly pump research — but the wall has a door, and the door is **sometimes closed**. Finding essence in the trader's stock becomes a windfall you plan around rather than a reliable pump.

### **[PROPOSAL]** The rates should discourage the loop

- **Essence sells poorly.** Converting refined essence to gold should feel like waste, because it is.
- **Essence buys expensively** when stocked. It's a windfall, not a shortcut.

Together those mean the door exists without becoming the optimal route: you use it when you're flush with gold and short on essence, not as a habit.

### Gold the currency and Gold the resource

**Gold already exists as a resource** — ductile mineral, high richness. Rather than renaming either, **coin is made of it**: a gold-rich world literally mints money.

**[PROPOSAL]** so gold ore sells far better than other minerals, or refines into coin directly at the Exchange. That makes **"write a gold world"** a specific economic play — a legitimate reason to compose for a substrate that isn't otherwise useful, which is exactly what a resource should do.

</details>

<details>
<summary><b>3. What the Exchange does</b></summary>

### Selling
- **Any material or item**, priced by **kind, grade and computed rarity** — the rarity system already exists.
- **Sell from inside a bin** (session 16), so you can dump the crude hides and keep the superb one. This is the feature that makes it actually solve the inventory problem.
- **[PROPOSAL] Bulk-sell by grade band** — "sell all crude and plain hides" — because selling forty things one at a time is not a game.

### Buying
- **[PROPOSAL] Staples only.** Common and uncommon materials, rotating stock, never the rare tiers. Anything a world can only give you should still have to be taken from a world — otherwise the entire pressure vocabulary is bypassable with money.
- Stock **[PROPOSAL]** refreshes on run completion, never wall-clock.

### Prices
- **[PROPOSAL]** buy price meaningfully above sell price, so the Exchange isn't an arbitrage engine.
- **Rare materials sell well** — that's the point of finding them, and choosing to sell one should feel like a real loss.

</details>

<details>
<summary><b>4. The Recycler — the upgrade</b></summary>

**Breaks items down into their component materials** rather than selling them for currency.

The clean division of labour:
- **Blacksmith reforges** — makes a piece *better*
- **Recycler reclaims** — turns a piece you don't want *back into parts*
- **Exchange sells** — turns anything into currency

**This resolves the open salvage question** (`materials-crafting-spec.md` §9.2). I'd previously proposed salvage as the Blacksmith's; **Aimee's placement is better** — reforging and reclaiming are opposite operations and shouldn't share a station.

**[PROPOSAL] Recycling returns a fraction** of what the piece was made from, at its original grade. So recycling a superb blade returns superb material, less of it. That keeps grade meaningful and makes recycling a genuine alternative to selling: currency now, or the right material later.

**[PROPOSAL]** the fraction improves with further Exchange upgrades, so recycling starts wasteful and becomes efficient.

</details>

<details>
<summary><b>5. Why this matters beyond convenience</b></summary>

Session 16 fixed the *storage* problem (binning by kind). This fixes a different one: **what to do with things you'll never use.**

Right now a hoard only ever grows. With an Exchange, every material carries a live question — *use it, keep it, sell it, or break it down* — and that question is exactly the "found it, kept it, found its purpose" pillar with a cost attached. Keeping something now means giving up something else.

**And it gives the Trader a reason to be in your party**, since appraisal-on-sight turns "is this worth carrying home" into an informed decision at the moment it matters.

</details>

<details>
<summary><b>6. What I'd want challenged</b></summary>

1. **The essence↔gold rates** (§2) — the door has to exist without becoming the optimal route.
2. **Staples-only buying.** It protects the world-writing loop, but a player short of one common material to finish a recipe may find it maddening rather than motivating.
3. **Whether the Exchange should buy *gear*** as well as materials, or only the Recycler handles gear.
6. **Gold ore minting directly into coin** — evocative, but it makes one resource structurally different from the other twenty-two.
4. **Bulk-sell by grade band** — convenient, but it makes it very easy to sell something you meant to keep.
5. **Trader as a class** — eleven classes may be past the point where each is distinct.
</details>
