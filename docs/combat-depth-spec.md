# Combat Depth — giving the player something to decide

**Status:** Claude's design. Numbers **[PLACEHOLDER]**.

**The problem.** Foes now vary genuinely — armament triangle, covering hardness and length, reach, sensory, conspicuousness, tier. The player has a Tuning-constant attack, one skill on a cooldown, and gear with **no damage type at all**. So a heavily armoured bulwark and a fast fragile drifter are fought identically: tap attack until someone falls.

Generated variety only matters if the player can respond to it. Right now they can't.

**Constraints this must respect:** turn-based, no timers, interruptible at every point, and it must not require constant attention — gambits exist so fights can run themselves.

---

<details open>
<summary><b>1. The core addition: damage types versus armour</b></summary>

**This is the one change that does the most, because it connects the material chain to combat.**

Foes already have `covering.hardness` and `covering.length`. Give player weapons a **damage type from the material they were made of**, and make the matchup matter:

| Type | Against hard covering | Against soft/thick covering | Character |
|---|---|---|---|
| **Pierce** | **Strong** — finds gaps, ignores a share of armour | Weak — passes through without doing much | Fang-derived |
| **Crush** | **Strong** — armour doesn't help against force | Weak — absorbed by padding | Tusk/stone-derived |
| **Rend** | Weak — can't get purchase | **Strong** — tears, and bleeds over turns | Claw-derived |

So: a *plated bulwark* wants pierce or crush; a *shaggy browser* wants rend. And **you learn which by fighting them**, or by reading the covering word the game already prints ("plate", "shell", "pelt").

**Why this is the right first move:** it makes the whole loop close. Kill a pierce-dominant creature → butcher a fang → craft a piercing weapon → it's good against the armoured things and wasteful against soft ones. Loot decisions become combat decisions become world-authoring decisions.

**It also gives a reason to carry more than one weapon**, which makes the satchel's "keep or leave it" pressure bite in a new place.

</details>

<details>
<summary><b>2. Reach and the opening exchange</b></summary>

`reach` exists on foes and does nothing.

**[PROPOSAL]** at the start of an encounter, whoever has the **greater reach strikes first**, once, before normal turn order. A far-reaching creature gets a free opening blow; a close-reach ambusher doesn't — unless it's cryptic, in which case *it* opens (already specced).

Give player weapons a reach value too, so a spear-analogue trades damage for the opening strike. Small rule, real decision, no new UI.

</details>

<details>
<summary><b>3. Positioning — front and back</b></summary>

**[PROPOSAL]** the party has two ranks. A party member is in front or behind.

- **Front** takes the attacks. **Back** is only reachable by far-reach foes or area delivery.
- Melee weapons only strike from the front; far-reach weapons strike from either.
- **Swapping ranks costs a turn.**

This is the cheapest way to make party composition mean something, and it makes `reach` and `delivery` matter on both sides. It also gives the gambit system something worth automating — *"if my health is below 40%, fall back"* is exactly the kind of rule that makes authoring feel clever.

**Keep it to two ranks.** A grid is a different game and won't fit a phone screen alongside everything else.

</details>

<details>
<summary><b>4. Status, from traits that already exist</b></summary>

Foes already carry the traits; nothing reads them in combat.

| Foe trait | Effect |
|---|---|
| `armament.rend` dominant | **Bleed** — damage over turns |
| `emanation` | **Elemental** — burn, freeze or shock, per its element |
| aposematic conspicuousness | **Toxic** — striking it in melee poisons you |
| high `covering.length` | **Absorbing** — reduces pierce specifically |

Player-side status comes from **materials**: a toxin-treated blade applies poison; a reagent-treated one applies burn. That gives Apothecary output a combat purpose and makes consumables meaningful.

**[PROPOSAL]** keep the status list short — bleed, poison, burn, freeze, shock — and make every one of them a *damage-over-turns* or *stat-shift* effect. No stuns, no skip-a-turn: losing your turn in a turn-based game feels worse than any amount of damage.

</details>

<details>
<summary><b>5. What the player actually chooses, after this</b></summary>

Per turn, roughly: **which weapon** (matchup against that foe's covering), **which target** (which foe first, given tiers and reach), **rank** (hold or fall back), **skill or item** (with the cooldown), and **whether to flee** (still costing stability).

That's a real decision space built almost entirely from traits and materials that already exist — no new content types, no new resources.

</details>

<details>
<summary><b>6. What this needs from elsewhere</b></summary>

1. **Weapons need a damage type and reach**, derived from the material they're made of. Blocked on crafting, but **found gear can carry them immediately** — sites already drop gear.
2. **Materials need their properties exposed**, so a fang makes a piercing weapon and a tusk a crushing one. `ButcheryRules` already produces the right materials; the property schema from `materials-crafting-spec.md` isn't built.
3. **The covering word should be visible before you commit** — the game already prints "plate"/"shell"/"pelt". That's the read that makes matchup a decision rather than a guess.

</details>

<details>
<summary><b>7. What I'd want challenged</b></summary>

1. **Is the matchup triangle too fiddly for a phone?** It's one more thing to check per fight. The mitigation is that the covering word is already printed and there are only three types.
2. **Two ranks — worth it, or is positioning scope creep?** It's the piece I'm least sure of. Everything else here reads traits that exist; ranks are a new concept.
3. **Should the player's own traits exist at all?** Companions are people, not generated creatures — but if gear gives them covering and armament values, the same combat maths runs on both sides and the code halves.
4. **Whether reach-strikes-first is too swingy** at low levels.
5. **No stuns** — I'm confident, but it does remove a classic tactical lever.

</details>
