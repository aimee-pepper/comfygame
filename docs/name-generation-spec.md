# Name Generation — creatures, flora, materials

**Status:** Claude's design. Numbers and word lists **[PLACEHOLDER]**. Fills a gap Claude Code flagged (`52d0c15`) and that Claude left open when specifying "composed descriptive names."

**The problem.** `CreatureIdentity.name` returns a single class word — *bulwark*, *ambusher*, *creature*. So every armoured thing in the game shares a name, and anything unmatched is called "creature." The same gap exists for flora and for materials, all three of which are now procedurally generated.

**Why it matters more than it sounds.** Names are how the bestiary becomes a collection, how a clue can mention a creature, how loot reads as coming from somewhere, and how a player says "the pale thing from the mercury world" and means something specific. A generated world whose contents are all called *creature* is a spreadsheet.

---

<details open>
<summary><b>1. The shape: qualifier + kind</b></summary>

**Two parts, both derived from traits.**

```
[qualifier] + [kind]     →   "ashen bulwark" · "blind courser" · "gilded browser"
```

- **Kind** is the identity class already computed — the noun. Stable, small, authored.
- **Qualifier** is drawn from the creature's **most distinctive trait** — the adjective. Large vocabulary, and it's what makes two bulwarks different.

**Why not fully generated names** (*Krellith*, *Vashtu*): they carry no information, they don't help a player reason, and a clue that says "she wrote about the krellith" is useless unless you've met one. Descriptive names *teach* — read "blind courser" and you know it's fast and hunts without eyes.

</details>

<details>
<summary><b>2. Choosing the qualifier — most distinctive, not most extreme</b></summary>

**The rule: pick the trait furthest from that world's own mean, not from the global mean.**

On a world where everything is armoured, "armoured" says nothing. What's distinctive there might be that this one is *small*. This makes names automatically informative **in context**, and it means the same trait vector can be named differently in two different worlds — which is correct, because distinctiveness is relative.

**[PROPOSAL]** compute each trait's deviation from the world cast's mean, take the largest, and draw the qualifier from that axis's word bands.

### Qualifier bands **[PLACEHOLDER vocabulary]**

| Axis | Low | High |
|---|---|---|
| size | *lesser · slight · dwarf* | *great · vast · monstrous* |
| build | *lithe · slender* | *heavy · hulking* |
| covering | *bare · naked* | *shaggy · mantled · plated* |
| coveringHardness | *soft · yielding* | *ironbound · scaled · carapaced* |
| boneDensity | *hollow · light* | *leaden · dense* |
| reach | *stub · close* | *long · reaching* |
| armament | *meek · unarmed* | *fanged · barbed · savage* |
| conspicuousness | *drab · ashen · pale · dim* | *bright · gaudy · banded* |
| ornament | — | *gilded · crowned · plumed* |
| vision | *blind · dim-eyed* | *keen · wide-eyed* |
| nonVisualSense | — | *whiskered · sounding · questing* |
| emanation | — | *burning · frozen · charged* |

</details>

<details>
<summary><b>3. When two things would share a name</b></summary>

Inevitable with a small cast. **[PROPOSAL]** if a world's cast produces a collision, the second one takes its **next-most-distinctive** trait instead. So a world with two shaggy browsers gets *shaggy browser* and *pale browser*.

Never number them. "Browser 2" is a spreadsheet.

</details>

<details>
<summary><b>4. Flora — same shape, different nouns</b></summary>

```
[qualifier] + [kind]     →   "thorned bramble" · "lantern crust" · "leaden reed"
```

**Kinds** from identity regions: *bramble · canopy · succulent · mat · bloom · crust · reed · thicket*.

**Qualifier axes:** stature (*creeping · towering*), tissue (*sappy · fibrous · woody · brittle*), defence (*thorned · bitter · venomous · grasping*), metabolism (*sunfed · rot-fed · stone-fed*), coloration.

**Metabolism qualifiers are worth their weight** — *stone-fed crust* tells you the world it came from, which is exactly the informational job names should do.

</details>

<details>
<summary><b>5. Materials — three parts</b></summary>

Materials need to carry **grade** as well, since a fine pelt and a monstrous pelt are different treasures.

```
[grade] + [qualifier] + [kind]     →   "fine ashen pelt" · "monstrous ironbound plate"
```

- **Kind** — the material identity (plate, quill, pelt, hide, fang, timber, ingot…).
- **Qualifier** — **inherited from the source creature or plant**, not recomputed. A pelt from a *shaggy browser* is a *shaggy pelt*. This is what makes loot feel like it came from somewhere.
- **Grade** — from the grade scalar: *crude · plain · fine · superb · monstrous*.

**The inheritance is the point.** Kill a *pale groper*, get a *pale hide*. Later, a recipe wants flexibility and you reach for it and remember where it came from. That connection is doing real work for the hoarding pillar.

</details>

<details>
<summary><b>6. Sites, and named places</b></summary>

Sites are **authored** and keep authored names — they're set-pieces and shouldn't be procedurally titled.

**[OPEN]** whether *worlds themselves* get names. Currently they don't. A generated world could be named from its own most-distinctive pressures (*the frozen dark · the gilded shallows*), which would help enormously once anchored worlds accumulate and you need to tell them apart. Named places already have authored names, so a generated name would need to read as clearly different in kind.

</details>

<details>
<summary><b>7. Build notes</b></summary>

- Pure and deterministic — same traits plus same world cast produce the same name, so a name never changes under a player.
- **Derived, never stored.** Consistent with "store the observation, derive the meaning" — vocabulary can be expanded later and old specimens get better names for free.
- One shared implementation across all three domains; only the noun sets and axis-word tables differ.

</details>

<details>
<summary><b>8. What I'd want challenged</b></summary>

1. **Distinctiveness relative to the world, not globally** — it's the interesting choice and the more expensive one. It means a name is only meaningful in context, and the same animal met in two worlds could be named differently.
2. **Two words enough?** Three (*small shaggy browser*) is more precise and much clumsier.
3. **Whether kinds should be this plain.** *Bulwark* and *courser* are good; *creature* as a fallback is not — the fallback should compose from two qualifiers instead (*blind leaden thing*).
4. **Whether worlds get names** (§6).
5. **Whether the word lists are yours to write** — these are voice, not mechanism, and the placeholder vocabulary above is mine.
</details>
