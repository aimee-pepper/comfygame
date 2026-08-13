# First authored-text review batch — Isolde and Sabine

**Status:** approved for live promotion and review through play; Atlas remains a revision tool
**Priority:** first atlas content batch because both defects were observed directly in play  
**Scope:** three Isolde optional replies and Sabine's seven location clues; interaction ordering is
already fixed separately.

## 1. Isolde's independent replies

Keep the current opening, player questions, offer and terminal responses. Replace only the replies:

| Stable exchange | Recommended reply |
|---|---|
| `isolde.blank_board` | “The board is for resistance, not ink.” She draws the line again, slower. “If the hand cannot keep its course here, giving it charcoal only records the mistake.” |
| `isolde.teacher` | “For forty years. Mostly to people who wanted to write faster.” A short laugh. “They had to learn smaller first. Smaller takes longer.” |
| `isolde.charcoal_hand` | She looks at you for the first time. “Then every mark has had to carry too much.” She sets the board down. “Show me your hands.” |

Why: each answer now responds directly to the tapped question, explains one physical fact and remains
intelligible alone. The original “hand goes first,” “smaller takes twice as long,” and “saying about
two things at once” lines stack three unexplained metaphors before the player knows the exercise.
This revision preserves Isolde's severity and dry humour rather than making her generically warm.

The already-implemented transcript contract remains mandatory: replies append in tap order and
never reveal/reorder unchosen exchanges.

## 2. Sabine's seven location clues

Replace the complete set together; approving only the screenshot line would leave the same
conclusion-first problem in the other six.

| Stable page | Recommended prose |
|---|---|
| `sabine_where_0` | Bite the new shoots down at dusk and they stand above the old cut by morning. This place can answer feeding without pretending nothing was taken. |
| `sabine_where_1` | Every shelter is occupied, and fresh tracks stop at the entrances before turning away. More creatures live here than one keeper could gather. |
| `sabine_where_2` | Small grazers crowd the new growth. Larger tracks circle them, and scavengers follow what the hunt leaves behind. Feed one creature here and three others change their route. |
| `sabine_where_3` | The same hollows are pressed flat each night while nearby ground goes untouched. Return often enough and absence becomes part of the pattern. |
| `sabine_where_4` | Hoofprints, paws and dragging tails reach the water by different banks. No creature has to pass another's shelter to drink. |
| `sabine_where_5` | There is open ground enough to approach and cover near enough to refuse. I could work here without making nearness the only safe choice. |
| `sabine_where_6` | The same calls begin at the same interval, and the same paths fill soon after. They can learn when I return; that does not mean they must come. |

Why: each page starts with observable world evidence that points toward its hidden condition before
Sabine interprets it. `sabine_where_2` now communicates a deep food web without asking the player to
decode “Every appetite rests inside another.” Across the set, Sabine remains concerned with care,
routine and refusal, but no clue reads like an ethical thesis detached from a world.

## Review choices

For each section choose **Approve exact set**, **Needs another pass**, or list individual lines to
hold. Isolde may be reviewed per exchange. Sabine should be judged as a complete sequence even if an
individual line is held.

After approval, Engineering changes only the matching stable units in `travellers.json`, retains the
prior prose in Decision/Git history, regenerates atlas hashes normally and runs:

1. arbitrary Isolde tap-order/paired-reply tests;
2. Sabine stable page-ID/condition/clue-index parity;
3. exact atlas stale-review behavior;
4. phone and Large Text wrap review of every changed unit.
