# Curio identification and permanent knowledge — current design

**Status:** Current structure; recognition threshold and Storehouse price are playtest values.  
**Scope:** Curios, Storehouse identification, Solvent, use-to-identify and Reality knowledge.

## Core rule

Identification applies to one physical curio; recognition applies to the curio family forever.
Both are useful stages:

1. The first identified example reveals and transforms that one item.
2. After **two independently resolved examples** of the same curio family, its identity becomes known
   in Reality.
3. Once known, all existing and future examples of that family reveal immediately and cost nothing
   to identify.

Two is the placeholder threshold. One would collapse identification into a single purchase; three or
more would turn a small mystery into repetitive tax. The threshold is debug-exposed, but permanent
knowledge and free duplicate recognition are current.

Knowledge is keyed by the unidentified curio family ID and records its revealed item ID, observation
count, first-resolution run index and whether recognition is complete. It never resets or decreases.

## Resolution routes

Each of these resolves one example and adds one observation:

| Route | Cost | Where | Result |
|---|---|---|---|
| **Storehouse study** | Current 5 essence placeholder | Base | One curio transforms safely |
| **Solvent** | One Solvent + one world turn | World | One carried curio transforms safely |
| **Use in a valid context** | The curio itself; ordinary action/turn cost | World or combat | Its effect happens and its identity is learned |

The routes are alternatives. Solvent buys certainty in the field; the Storehouse buys certainty at
home; use buys knowledge by accepting the object's actual consequence.

## Use-to-identify

An unidentified curio shows **Try it** only when its hidden result has a valid, attributable use in
the current context.

- A hidden healing or coating item may be tried on an eligible party member or weapon. The resulting
  effect occurs, the item is consumed, and its family receives an observation.
- A hidden world item may be tried only where its effect can operate. The world turn and any normal
  danger are paid.
- A hidden key may be tried at a compatible locked cache. If compatible, it reveals as the key and
  opens the cache in the same committed action. Away from a cache, there is no meaningful use.
- An item with no valid target does not consume, transform or add knowledge. The UI explains that
  there is no way to test it here.

The confirmation describes uncertainty without leaking the result: **“Try this on Mara? It will be
used, and whatever it does will happen.”** Potentially destructive effects must still obey the game's
ordinary safety boundaries; v1 curios do not contain permanent-loss or irreversible character harm.

## When recognition completes

Completion is atomic with the resolving action. The just-resolved object follows its normal outcome,
then every matching unidentified stack in Base inventory, active-run satchel, pending loot and other
durable owned containers is normalized to the revealed catalog item. Future drops enter already
revealed. Normalization preserves counts and instance-specific fields and re-bins safely.

Knowledge does not retroactively identify a curio the player no longer owns, and it does not grant an
item. It changes what the player understands when another example appears.

## System boundaries

- Vance's appraisal may estimate the unidentified family's value band but cannot reveal the result.
- The Trading Post cannot buy unidentified curios. Once recognized, resulting ordinary items follow
  normal eligibility; keys and narrative objects remain protected.
- Solvent remains valuable after recognition because other unknown families can exist; do not create
  a unique Solvent recipe for each curio.
- Curio knowledge is separate from compound-component identification. Both live in Reality because
  knowledge is final, but their evidence and reveal rules differ.
- Material properties are visible on recovered samples and do not use this curio counter.

## Content requirements

Every curio definition needs:

- a stable unidentified family ID;
- one stable revealed item ID;
- teaser name and prose that hint without stating the answer;
- valid-use contexts for use-to-identify;
- safety and bulk-action flags inherited from the revealed item.

Additional curios should form a mixed catalogue of consumables, tools, keys and modest utilities.
They should not all be disguised versions of recipes the player already mass-produces, or the
identification loop becomes clerical.

## Implementation invariants

1. Every resolution path calls the same knowledge-recording operation.
2. Recognition completion and owned-stack normalization save atomically.
3. Old saves decode absent knowledge as empty; already-revealed items remain revealed but are not
   guessed backward into observations.
4. Recognition never becomes unknown again, including across any future Reality transition.
5. Failed or contextless attempts consume nothing and award no observation.
6. Tests cover stacked curios, the threshold-crossing copy, satchel/base copies together, a key used
   at a cache, and force-quit recovery at the committed action boundary.
