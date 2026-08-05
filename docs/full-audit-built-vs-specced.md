# Full Audit — built vs. specced (2026-08-05)

**This replaces `design-audit-session-5.md`'s scope.** That audit checked whether *decided rules* were honoured and reported high fidelity. It never compared **what's built against what's specced**, which is why a four-slot writing desk feeding an eight-target pressure model went unreported. This one covers both.

**Summary:** the rules that exist are implemented faithfully and well-tested (200 tests, no wall-clock, contradiction correctly catalogue-driven). But **the authoring interface is still the v0 placeholder**, and roughly half the specced game doesn't exist yet. The gap between those two facts is producing the incoherent worlds Aimee is seeing.

---

## 1. The central gap

**The writing desk is still the four-slot v0 taxonomy** (Terrain / Biome / Bounty / Quirk). `slots.json` still carries its own `PLACEHOLDER TAXONOMY — being replaced` note. The **page grid — footprints, packing, rotation, hands, instruments — does not exist in any form.** No footprint field on `Sigil`, no grid, nothing.

Meanwhile the **pressure model underneath is real**: 8 targets, sigil resolution, cross-target constraints, contradiction catalogue, description generation.

The two are bridged by `expandsTo` on old symbols — Verdant expands to root→vitality and bloom→vitality. That bridge works, but **four slots cannot cover eight targets**, so `PressureRules.resolve` rolls every unwritten target *from the whole source pool at random intensity*.

**Consequence:** most of every world is noise the player didn't write and can't control. That is the root cause of "the descriptions don't combine sensibly."

It also cascades: a rolled aphotic illumination caps a written Verdant's vitality to *Barren* via the cross-target constraint, and fires *Green in the dark*. Both behaviours are **correct** — they're just reacting to inputs the player never chose, because there aren't enough slots to choose them with.

---

## 2. System-by-system

| System | Specced in | Built | Notes |
|---|---|---|---|
| Pressure targets | pressure-model | ✅ 8/8 | All present and resolving |
| Pressure sources | pressure-model, rune spec (79) | ⚠️ **41/79** | Roughly half |
| Cross-target constraints | pressure-model | ✅ | Working — visible in the Barren case |
| Contradiction catalogue | contradiction-danger §1–2 | ✅ | Correctly catalogue-only, with the invariant test |
| Contradiction **penalty** | contradiction-danger §3 | ❌ **Not wired** | See bug 2 |
| Peace + danger runes | contradiction-danger §5 | ⚠️ Partial | All 7 exist with the stacking cap, but as **old-taxonomy quirk symbols**, not pressure sigils |
| World-description panel | Q18 | ✅ | Built, but see bugs 1 and 3 |
| **The page grid** | rune spec §2–3 | ❌ **Nothing** | No footprints, packing, rotation, hands |
| **Rune vocabulary** | rune spec (149) | ❌ | Old `symbols.json` only |
| Instruments / analysis tiers | session 8 | ❌ | Correct — session 8 not yet merged |
| Sites: placement + triggers | sites-system | ✅ | Genuinely working |
| Sites: ruins pay knowledge not currency | Q17 | ❌ | See bug 4 |
| **Creature traits** (covering cube, armament triangle, finish) | rune spec, biology research | ❌ **Nothing** | 3 hand-authored creatures with flat stats |
| Specimen tier / trait-keyed bestiary | session 3 Q4a | ❌ | `DiscoveryLog` keys by `CreatureID`, as an acknowledged placeholder |
| **Materials + properties + recipes** | materials-crafting | ❌ **Nothing** | No property schema; drops are flat tables |
| Crafting buildings | materials-crafting | ❌ | |
| **Diaries / pages / Library / hint pages** | session 7 | ❌ **Nothing** | The entire search loop |
| Travellers, clues | session 7 | ❌ | |
| Named places | session 5 Q12–13 | ❌ | |
| **Anchoring (3 routes)** | session 7 | ❌ | Code still cites it as open question Q-A |
| Companions / assignment / tavern | companions spec | ❌ | Provisional anyway |
| The Atlas / great work | session 9 | ❌ | Expected — brand new |
| Gambit grammar | Aimee's instruction | ✅ | 16 components, working |
| Research trees | Aimee's instruction | ✅ | 24 nodes, 4 branches |

---

## 3. Bugs

**1. The description reveals rolled content.** Generated from the fully-rolled world, so chance-filled slots are spoiled before departure. Violates a locked decision. The panel may describe **only what the player wrote**.

**2. Contradictions cost nothing.** `ContradictionRules.penalty` is written, tested, and **never read by the stability headline**. `BookProjection` sums only old-symbol `stabilityDelta` and attaches contradictions as a display-only field — hence *Green in the dark* alongside Stability 100. Contradiction spec §3 requires base + disclosed escalation.

**3. `holds ~9999 turns`** — a sentinel leaking into the UI.

**4. Q17 not actioned** — ruins still pay essence (Wayfarer's Camp 1, Binder's Workshop 4, Glacial Vault 3). Should be 0; landmarks and living sites keep theirs.

*(Not a bug: rolling unwritten targets is correct and stays. See §5 — the problem is the slot count, not the rolling.)*

---

## 4. What blocks what

- **The page grid blocks everything about authoring.** Until slots become a grid with many more sigils, the pressure model can't be driven properly and worlds will keep being mostly rolled.
- **Creature traits block materials, which block crafting.** Drops derive from trait vectors; nothing downstream can be built first.
- **Creature traits also block the specimen tier**, which the bestiary is a placeholder for.
- **The search loop is entirely independent** — diaries, pages, Library and hint pages need none of the above and could be built in parallel today.

---

## 5. Rolling unwritten targets is correct — the slot count is the problem

**Rolling stays as-is.** Unwritten targets *should* roll from the whole pool at random intensity; that's what makes leaving something open a genuine surprise, and it's a decided behaviour.

The issue is purely the ratio. **Four writable slots against eight targets** means nearly every world is mostly rolled, so the player can't feel authorship at all. Once the page grid lands and ten or fifteen sigils fit on a page, the same rolling code becomes exactly what it's meant to be: the parts you deliberately left open.

**No design change needed. The fix is the page grid.**

## 6. On the previous audit

The session-5 audit's method was wrong: it verified decided rules and treated that as coverage. Fidelity to rules is necessary but says nothing about whether the built game matches the designed one. Future audits should lead with the built-vs-specced table above, and flag *missing* systems as findings rather than assuming absence is scheduled work.
