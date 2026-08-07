# Jargon Audit — words the player shouldn't have to guess

**Prompted by:** Aimee asking what a *rung* was. It's my coinage, it leaked from my specs into code comments and then into player-facing strings, and nobody ever defined it for her.

**Method:** searched quoted strings in `Sources/Screens/` and content data — what the player actually reads — rather than code identifiers, which can stay technical.

**Good news first: the interface is mostly clean.** Most of these words appear in variable names and comments, which is fine. Only a handful reach the screen.

---

## 1. Reaching the player and needing a change

| String | Where | Problem | Suggested |
|---|---|---|---|
| **"Said nothing: …"** listing `inertRungs` | World history | *Rung* is my invented word for one step on a qualifier ladder. The **string** is fine and good; the concept behind it has no name the player knows | Keep the string. **Rename the field** to `inertModifiers` so it can never surface as "rung" |
| **"more than one primary per subject"** | Writing desk | Two undefined words in six. **Primary** = the main source on a target; **subject** = the target | *"only one main cause per subject"* — or reuse whatever the palette already calls these |
| **"affects this target at all"** | Writing desk | **Target** is the pressure-model word. The palette is organised by them, so the player sees them constantly — but are they ever *named*? | Either name them plainly once (**subjects**, if that's the chosen word) or say *"changes anything here"* |

**The `primary`/`subject`/`target` tangle is the real finding.** Three words are in play for two concepts, and the interface mixes them. Worth picking one word for each and using it everywhere:

- The eight things a world has (illumination, thermal…) — **[AIMEE]** *target* · *subject* · *aspect* · something else
- The one main cause allowed per one of those — **[AIMEE]** *primary* · *main cause* · *anchor*

## 2. Reaching the player and defensible

| Word | Where | Verdict |
|---|---|---|
| **sigil** | "Tap a neighbouring sigil to join it" | **Keep.** It's the game's own vocabulary, it's introduced by the act of writing, and it's a real English word. This is naming, not jargon. |
| **peak / floor** | Readings in world history | **Keep**, but only visible at analysis tier 2+, by which point the player has earned the vocabulary. Worth checking they're labelled the first time. |
| **tier** | Buildings, foes | **Keep.** Standard. |

## 3. Not reaching the player — no action

`ladder`, `cluster`, `aspect`, `modality`, `opposed`, `greed`, `readings` all live in identifiers and comments only. Fine as internal language.

**One to watch:** *greed* and *opposed magnitude* are load-bearing concepts the player *will* eventually need words for, once analysis tier 4 shows instability attribution. Those need player-facing names before that ships — **[AIMEE]**, and they should be evocative rather than technical.

## 4. The rule worth adopting

**Any word invented in a spec must be either defined in the interface or renamed before it reaches it.** *Rung* failed that test twice — I coined it, used it in specs, it entered code comments, and it surfaced in a field name that feeds a player-facing string.

Cheapest guard: **when a spec invents a word, say in the spec whether it's internal-only or player-facing.** I haven't been doing that.
