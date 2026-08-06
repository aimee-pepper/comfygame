# Decisions Log — Session 16 (2026-08-05)

Append to `docs/decisions-log.md`. Aimee's decisions, from testing.

---

## 1. Items must stack — and materials stack by KIND, not by exact source

**Current behaviour is a bug in effect.** `ItemStack` *has* a `count` field and **nothing ever increments it**. Every pickup creates a new stack in a new slot, so two identical hides consume two of eight slots.

### The rule

**Merge on add.** Ordinary items with the same catalogue ID and identified state merge into one stack.

**Materials merge by material KIND.** All hides go into one hide stack regardless of grade or which animal they came from.

**The stack is expandable, and sortable inside.** Open a hide stack and you see the individual entries — their grades, their sources, their names — and can sort them.

### Why this and not strict separation

Materials carry a `MaterialSample`, so a *pale hide* from a groper and a *shaggy hide* from a browser are genuinely different objects. Keeping them in separate slots is truthful but unusable: a world with six species produces a dozen variants, and slot pressure would explode.

Binning by kind gives **slot pressure proportional to material kinds** (a manageable number) while **losing nothing** — every sample keeps its own grade, source and name inside the bin.

### Consequences

- **Slot cost is per kind.** Twelve hides of five different grades cost one slot.
- **Crafting picks from within the bin** — you choose which grade to spend, so a recipe can be satisfied cheaply or generously (feeding the overshoot-improves-quality rule in `materials-crafting-spec.md`).
- **Percentiles still work.** The bin knows its best and worst, so "finest pelt you've recovered" is a query.
- **The satchel uses the same rule in-world** — otherwise carrying is still miserable and the fix only helps at home.

### Open

1. **What the collapsed bin shows** — kind and count, presumably, but does it also show the best grade held? ("12 hides · finest: superb" is more useful than "12 hides".)
2. **Do ordinary items have a stack cap** (e.g. 99), or is it unbounded?

---

## 2. Storage needs far more expansion than three tiers

**Current:** `startingInventorySlots = 8`, Storehouse `maxTier = 3` → **20 slots total, ever.**

That's far too little, and it fights the hoarding pillar — "expand until you can hoard whatever you want mid-game" was the original design intent and three tiers can't get there.

### The decision

**A much longer ladder.** **[PLACEHOLDER: 8+ tiers]**, starting cheap and getting steeply expensive, so storage stays a worthwhile thing to invest in across the whole game rather than being maxed in the first hour.

### **[PROPOSAL]** Specialised storage as well as more of it

Beyond raw slot count, add storage that only holds one category — a **material vault**, a **curio cabinet**, a **library annex**. Late-game expansion then broadens rather than just enlarging, and it lets a player who hoards materials invest differently from one who hoards curios.

Not decided; flagged as an idea worth considering alongside the plain ladder.

### Note

With §1 in place, the required slot count drops a great deal — binning by kind means the ladder is expanding capacity for *variety*, not for volume. Both changes should land together, and the tier numbers should be set after stacking is in, not before.
