# Living Worlds — creatures acting on each other during a run

**Status:** Claude's design. Numbers **[PLACEHOLDER]**.

**The gap.** Trophic depth is currently a **generation-time number** — it shapes what spawns and then nothing eats anything. During a run, creatures exist and fight the player and otherwise ignore each other. The food web is scaffolding for the generator, not something that happens.

That's a large part of why worlds feel like dioramas.

**The approach: rules, not simulation.** Populations don't deplete, predators don't starve, nothing is modelled over time. Creatures act on each other **using traits they already have**, on the world turns that already tick. No new state beyond what's in the save.

**Player hunger is explicitly out** (Aimee): it's a nagging timer-shaped pressure, it fights interruptibility, and instability already does the "you can't stay forever" job better.

---

<details open>
<summary><b>1. The rules</b></summary>

All of these run on the existing world-turn AI pass, and all read traits that already exist.

### Predation
A creature engages another creature when **all** hold:
- Its `armament` total meaningfully exceeds the target's **[PLACEHOLDER: by ≥25]**
- Its `size` meaningfully exceeds the target's, **or** its armament advantage is large
- It can **detect** the target — `sensory.vision` within range in daylight, or non-visual sensing regardless of light or sight-blocking terrain

Resolution is the ordinary combat rules, run headless. **[PROPOSAL]** resolve instantly rather than over rounds, so a fight between two creatures doesn't tie up the world for turns.

### Fleeing
A creature moves **away** from any detected creature that satisfies the predation test against it — before that creature closes. Weak things scatter.

### Carcasses
A kill leaves a **carcass tile** that yields the loser's materials at reduced quantity **[PLACEHOLDER: 50%]**, and decays after a while **[PLACEHOLDER: N turns]**.

Two consequences worth having: you can harvest a fight you didn't join, and a world with active predation is visibly *productive* — there are carcasses on the ground.

### Grouping
- **Herd** (low armament, high count-tendency): moves toward others of its species; stays clustered.
- **Solitary** (high armament): avoids others of its species, spreading apex creatures across the map.

That single distinction produces recognisably different world textures without any pathfinding cleverness.

</details>

<details>
<summary><b>2. What this gives the player</b></summary>

**A tactical decision that doesn't exist today.** You see a predator converging on a grazer. Intervene, or wait and take what's left? Waiting costs turns and the predator is stronger afterwards; intervening means fighting something that isn't yet distracted.

**Legible ecology.** You *watch* what eats what and learn a world's structure by observation rather than being told — the same discovery principle as secondaries and instruments.

**Worlds that differ in motion, not just contents.** A herd world moves in clumps. An apex world has three big things prowling apart. A world with no predators is placid, and that placidity is itself information.

**Cover starts to matter for someone other than you.** Cryptic creatures ambush *other creatures* in overgrown terrain, so a dense world genuinely plays differently.

</details>

<details>
<summary><b>3. What is deliberately NOT built</b></summary>

- **No population depletion.** Killing the predators doesn't cause a grazer boom. It's unobservable in a run and it invites players to stand still.
- **No starvation.** Creatures don't need to eat to persist.
- **No reproduction.**
- **No long-run ecosystem drift**, including in anchored worlds — the cast is fixed (session 15).

All of these need time the runs don't have, and can only be seen by *not playing*.

</details>

<details>
<summary><b>4. Cost and risk</b></summary>

**Cost is low** — one extra pass in the existing turn loop, comparing traits that already exist, plus a carcass tile content case.

**Risks:**
1. **Enemy attrition before you arrive.** If creatures kill each other freely, a world could be half-empty by the time you cross it. **[PROPOSAL]** predation only resolves within the player's awareness radius, so unobserved parts of the map stay as generated. Cheaper *and* it means what you see is what happened.
2. **Player finds fights already won.** Mitigated by the same radius rule.
3. **Turn-cost creep.** Every extra AI decision is latency on a phone. Keep the predation test to trait comparisons — no pathfinding.

</details>

<details>
<summary><b>5. What I'd want challenged</b></summary>

1. **Is instant resolution right**, or should creature-vs-creature fights play out over turns so you can intervene mid-fight? (Mid-fight intervention is a better *moment*; instant is far cheaper and can't strand a fight in progress across a force-quit.)
2. **The awareness-radius rule** solves attrition but means the world is partly "not real" until observed. Fine for a phone game; some people find it hollow.
3. **Should carcasses attract scavengers?** Evocative, and it's one more rule — but it starts down the simulation road.
4. **Should the player be able to *cause* predation** — lure something into something else? Lovely if it emerges, expensive if it needs designing.
</details>
