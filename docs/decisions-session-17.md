# Decisions Log — Session 17 (2026-08-05)

Append to `docs/decisions-log.md`. Aimee's decisions, following `audit-nonstandard-assumptions.md`.

---

## 1. Characters get STATS. This was a real gap.

`CompanionState` is currently a name, a `maxHP` constant, a gambit list and equipped gear. **No level, no XP, no stats.** That came from a line in Claude's one-evening v0 brief (*"no leveling tonight; power comes from gear/upgrades"*) and silently became the design.

**Characters need stats and classes.** Variety should come from *who a character is*, not only from what they're holding.

### **[PROPOSAL]** Five stats, each mapping to something combat already does

Combat already computes damage, armour, initiative, evasion and detection from creature traits. Character stats should feed the same maths so both sides run one system.

| Stat | Feeds |
|---|---|
| **Might** | Damage, especially with crush weapons |
| **Finesse** | Damage with pierce and rend; evasion |
| **Fortitude** | Max HP; armour effectiveness; resistance to bleed/poison/burn |
| **Perception** | Detection radius; not being ambushed by cryptic creatures; Sight-type skills |
| **Focus** | Skill potency and cooldown; **gambit slots** |

**Focus governing gambit slots** ties the automation system to character growth — a sharper companion can hold a longer rule list, which is a nice expression of "literacy, not inventory."

### **[AIMEE]** Classes / specs

Decided in principle; the set is hers. The natural hook: **a companion's class is what they were before the sundering.** A smith, a scholar, a hunter, a delver — which already ties to session 12's "you don't research a smithy, you find a smith." Their trade determines both what they unlock at base *and* how they fight.

## 2. Characters LEVEL

**[PROPOSAL]** XP from **combat and discovery both** — encounters won, but also first sightings of a species, sites entered, pages recovered. A game whose progression is literacy shouldn't reward only killing, and it means a careful explorer advances as surely as a fighter.

## 3. Mobs level too — three ways

1. **They scale slowly with player level**, so the world doesn't fall behind.
2. **Higher instability → higher level mobs.**
3. **Higher greed → higher level mobs.**

The second and third mean the risk/reward already priced into instability and greed now shows up as *difficulty* as well as danger, which is a much more legible expression of it than hazard frequency alone.

## 4. Ranks — YES, build them

Front and back position, standard JRPG. Front takes the melee hits and deals full melee damage; back is protected but weakened in melee.

**Strike the "skip ranks" recommendation from `combat-depth-spec.md` §3 — it's wanted.** Note that with stats and classes landing, ranks become more valuable than they looked: a fragile high-Focus scholar behind a high-Fortitude front-liner is a real composition decision rather than a positional fiddle.

## 5. An emergency escape item

**A craftable/findable item that forces an immediate return home** — for when you're too low to risk hunting for a portal.

- **Expensive to craft, or slightly rare to find.**
- **[PROPOSAL]** it's a *controlled* exit, so it should keep the **full** haul — the same as reaching a portal. Its cost is the item itself. If it kept only a fraction it would be a worse version of passing out, and nobody would carry one.

This closes a real hole: right now a wounded player deep in a crumbling world has no option but to walk and hope.

## 6. NOBODY DIES

**Companions can never die.** They **pass out** and are **revived back in town**.

**If the Binder passes out, it's treated exactly like a world collapsing** — you're carried home and lose some of the loot gathered during the run.

## 7. NO PERMANENT LOSS — for now

**Remove permanent loss from the game entirely at this stage.** Revisit only when **difficulty modes** arrive, as an option for players who want a harsher game.

### The revised table

| Thing | Losable? | Change |
|---|---|---|
| **Un-banked haul** (resources, items, motes) | **Yes** — partially, on collapse or passing out | unchanged; this is run risk, not permanent loss |
| **Companions in the party** | **Never** — pass out, revived in town | tightened |
| **Companions assigned to unstable worlds** | **Never** | **changed** — was losable with warning |
| **Animal companions** | **Never** | **changed** — was losable |
| **Tethered worlds** | **Never** | **changed** — a displaced tether must not destroy the world; keep the seed, or make slots generous enough that displacement isn't forced |
| **Anchored worlds** | Never (dormancy, not destruction) | unchanged |
| **Knowledge** — runes, bestiary, pages, readings | **Never** | unchanged |
| **The base** | Never, except a chosen reality reset | unchanged |
| **Anything while the app is closed** | **Never** | unchanged |

**Consequence for the sustain economy:** companions in unstable anchored worlds were the thing that made holding a greedy world genuinely expensive. That cost now has to be paid another way — **[OPEN]**, but the obvious candidates are resource upkeep and dormancy, both of which already exist.

---

## Consequences for existing docs

- `companions-base-anchoring-spec.md` §6 — permanent-loss table **superseded** by §7 above.
- `combat-depth-spec.md` §3 — ranks are **wanted**; strike the "skip them" note in §7.2.
- `audit-nonstandard-assumptions.md` §1, §2, §8 — **resolved** by this session.
- Still open from that audit: **fleeing always succeeds** (§3), **cooldowns with no MP** (§4), **no stuns** (§5), **resources slot-free** (§7).
