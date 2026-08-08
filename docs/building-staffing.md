# Staffing a Building

> *"we should make it so that keeping a character in their building vs taking them with you in your party grants a discount in that building, but taking them in the party gives them xp to level their shop with rather than just spending gold and resources."*

**This is the best answer yet to a question the design had been avoiding: why would you ever bench a trade companion?**

---

## 1. The tension

**A trade companion can be in exactly one of two places, and both are worth something.**

| | **Posted to their building** | **In your party** |
|---|---|---|
| **You get** | **A discount** on everything that building does | **Their levelling XP feeds the building** |
| **Which means** | Cheaper *now* | Better *later* |
| **The building** | Runs at its current tier, more cheaply | **Rises a tier without you paying for it** |

**Neither is the right answer**, which is what makes it a decision. A smith at the forge makes your reforging cheap. A smith in the field makes your forge *better*.

## 2. Why this is good

**It gives postings a real cost.** Assignment has been a flat choice with no downside — five party slots, everyone else idle somewhere. Now benching someone is *buying a discount*, and taking them is *investing in their trade*.

**It makes a building's tier something you can earn two ways.** Currently a tier is bought with gold and resources. Now it can also be **earned by the person whose building it is going out and doing things** — which is a much better story than a shop that improves because you paid it.

**And it puts trade companions in fights.** Otherwise the party is nine fighters and five slots, and the fifteen tradespeople never leave the base. **A smith who has been to eleven worlds has a better forge**, and that's a reason to bring her.

## 3. How it works — [PROPOSAL]

### Posted to their building — the discount

- **[PLACEHOLDER] 20–30% off** everything that building does: crafting, research nodes in its branch, its services.
- **Scales with their level**, so a well-levelled specialist posted at home is a large saving.
- **Applies only to their own building.** A smith at the forge doesn't discount the Apothecary.

### In your party — the building levels alongside them (Aimee)

**Their earning is not taxed.** They level exactly as they would anywhere — no share diverted, no slower growth for being someone's keeper.

**Instead, the building rises with them, slowly.** A building's tier is a function of two independent things:

```
building tier  =  what you have paid for  +  a slow function of its keeper's level
```

**So a keeper who has been out in the world has a better building, and has lost nothing for it.** That's a cleaner mechanic than a split — nobody is choosing between their own growth and their shop's, and there's no bookkeeping about what fraction went where.

**Paying is always available** and always immediate. The keeper's level is a second, slower track that arrives whether or not you spend.

### What "posted" means

**A word I introduced without defining** — the same failure as *rung*. A companion is in exactly one of **three places**:

| Posting | Where they are | What you get |
|---|---|---|
| **Party** | With you, in worlds | They fight, they level, **their building rises with them** |
| **Home** | At their own building | **A discount** on everything it does |
| **World** | Working an anchored world | Passive harvest over runs |

**"Posted" has meant *"assigned somewhere that isn't the party."*** If a plainer word is wanted — **stationed**, **kept**, or simply **assigned** — it should be chosen now, before it reaches the interface.

## 3a. Levels, trees, and what a companion can become

### Maximum level follows the combat trees — settled (Aimee)

> ***"they need to reach the end of each tree on any one branch per tree."***

**One branch to the end, in each of the three trees.** A fully-levelled companion has **three completed branches out of nine**, and max level is whatever number of points that takes.

**Builds stay distinct forever** — 27 combinations, no convergence, and a party of five can never cover all nine branches. **Who you bring stays a decision at every point in the game.**

Full detail in `combat-trees.md` §7.

### Wild companions arrive at your level (Aimee)

> *"wild companions are found at the same level as the player character I think? which means their skill trees should be partially filled already."*

**Yes, and it solves a real problem:** a wild companion found at level 14 who arrives at level 1 is worthless, so late-game finds would be pointless.

- **Found at the player's current level**, with the corresponding points **already spent**.
- **Spent coherently, not randomly** — **[PROPOSAL]** each has a hidden lean, and their points follow it, so a wild companion arrives as a recognisable *build* rather than a scattering. You meet a skirmisher, not a bag of points.
- **[AIMEE]** whether the player can **respec** them. *(Leaning yes — otherwise a wild companion is a lottery on someone else's choices, and you've never liked lotteries in this game.)*

**Named travellers are a separate question** — they may arrive at a fixed level appropriate to their phase, since when you meet them is deduced rather than chanced.

## 4. Consequences worth noticing

**It's an option, never a requirement.** A building's tier can always be bought outright with gold and materials, exactly as now. The XP path is **a second way to get there**, not a replacement — a player who never rotates anyone is spending resources instead of time, and that's a legitimate way to play.

**It gives fighters a clearer identity by contrast.** A fighter has no building, so they're always earning only their own levels. **A trade companion in the party is worth *more* than their combat contribution; a fighter is worth exactly what they do in the fight.** That's a fair trade and it means fighters should simply be better fighters.

**And it's a soft answer to the "why recruit everyone" question.** Fifteen tradespeople and five party slots means most are always home — but *which* five are out is now a rolling decision about which buildings you want improving.

## 5. Open

1. **Discount size** — **[AIMEE: TBD, balanced per building.]** A discount at the Blacksmith and one at the Library aren't worth the same, so it can't be one number.
2. ~~The XP share~~ — **settled:** there is no share. They level fully; the building rises alongside.
3. **Settled:** a building can always be levelled by paying. The keeper's level is an additional slow track, never the only route.
6. ~~Max level~~ — **settled:** three complete branches, one per tree. The remaining unknown is **branch depth**, which sets the actual number.
4. **Whether animals can be posted** — probably to worlds only.
5. ~~Whether the Firepit and Tavern behave differently~~ — **settled (Aimee): the Tavern *is* the upgraded Firepit.** One building, two tiers. So the Tavernkeeper doesn't build something new; she **upgrades what you already have**, which is a better arrival than another door on the base screen.

   **Consequence:** the Firepit needs no keeper and gives no discount at tier 1 — it's the one building that exists before anyone. Once it's a Tavern, Orsa can be posted to it like anyone else.
