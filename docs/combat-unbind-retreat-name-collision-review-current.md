# Combat Unbind / retreat collision — review packet

**Status:** reversible playtest naming and mechanics implemented in `ce9b1af`; Aimee's later naming
feel review remains open, but this is no longer a palette/combat-v2 blocker.
**Queue authority:** `Sources/Content/Data/playability-roadmap.json`.

## The collision

The live combat catalogue contains a baseline Binder damage technique:

- stable ID `unbind`;
- player name **Unbind**;
- “Pull at the seam holding a thing together”;
- direct damage on a cooldown.

The current combat action-palette design independently renames the ordinary **Flee** command to
**Unbind**. That command leaves the encounter, usually costs the displayed Stability and does not end
the expedition. The same palette would therefore offer an Unbind technique and an Unbind retreat
key with unrelated targets and consequences.

The live catalogue also retains **Rout** (`rout`), a cooldown technique that exits without Stability
loss. The true Shadow graph now assigns that distinct once-per-expedition benefit to **Vanish**.
Keeping both would make the new capstone-route utility partly redundant and preserve two authorities
for free retreat.

## Recommendation

Preserve **Unbind** as the Binder's signature damage technique. It expresses the protagonist's core
act on a creature or formed thing, and its existing name/prose are more distinctive than a generic
attack label.

Rename the ordinary encounter exit to **Withdraw**:

- primary palette key: **Withdraw**;
- confirmation: **Withdraw from this fight for N Stability**;
- outcome/log: **The party withdrew**;
- Vanish modifier: **Withdraw without losing Stability**.

“Withdraw” is accurate: the party leaves this fight but remains in the world. It does not imply that
the Binder destroyed the encounter, unbound the world or used their damage technique. The internal
compatibility outcome may remain `.flee`; player-facing language and accessibility use Withdraw.

Retire live `rout` ownership when combat v2 promotes. Decode legacy Rout cooldown/selection only to a
neutral migration receipt; do not silently grant Vanish, because Vanish is purchased Shadow
progression and once-per-expedition rather than a baseline cooldown. If a legacy save could own Rout
through a durable source, refund that exact source/point rather than inventing Vanish ownership.

## Alternative not recommended

Keeping retreat as **Unbind** would require renaming the signature damage technique and its stable ID
to something such as Unravel. That is mechanically workable, but it spends more identity/migration
cost on the action with the stronger established fiction. It also makes an internal `unbind` skill
mean “Unravel” unless another one-way migration is added.

Using **Flee** avoids the duplicate but carries a panicked/failure tone even when withdrawal is a
deliberate tactical choice. **Escape** has a similar problem and suggests the party was trapped.

## Implemented acceptance and remaining review

`ce9b1af` makes the ordinary UI and confirmation say **Withdraw**, preserves damage **Unbind**, makes
Vanish waive exactly one Withdraw cost per expedition through a saved receipt, and rejects decoded
legacy Rout as inert. The remaining review is whether the two player-facing words feel right, not
whether the application may expose two actions named Unbind or restore Rout as a second free exit.

Maintained acceptance:

1. No combat screen, action palette, VoiceOver label, confirmation or log contains two actions with
   the same player-facing name.
2. Baseline Unbind always previews/commits damage against a legal foe; Withdraw always previews the
   exact retreat consequence and never targets a foe.
3. Vanish modifies the Withdraw consequence once per expedition and persists its spent receipt.
4. `rout` is decode-only after migration and cannot appear beside Vanish or in a generated person's
   build plan/gambit.
5. Cancelling Withdraw costs nothing; accepting it settles exactly once through relaunch.

## Later feel-review question

Approve **Unbind = signature damage** and **Withdraw = leave combat**, or explicitly choose to keep
Unbind for retreat and rename the damage technique instead.
