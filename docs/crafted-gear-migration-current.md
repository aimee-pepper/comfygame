# Crafted gear instance and reforge migration

**Status:** Implementation-facing migration contract. It specializes
`gear-crafting-families-current.md` without changing the settled shop hierarchy. Numerical reforge
strength is under active correction review: `reforge-progression-audit-current.md` supersedes this
file's future-facing 0.2×3 recommendation if Aimee approves DRQ-065. Existing paid power and the
legacy construction/credit migration remain invariant.

## Problem being migrated

Live gear is an `ItemStack` or `EquippedPiece` containing a catalogue ID, integer `upgradeLevel` and
occasional `wildGrowth`. Combat currently treats `catalogue tier + upgradeLevel + wildGrowth` as an
integer tier. That makes repeated Blacksmith work indistinguishable from specialist construction and
allows an ordinary item to cross tier 3/4 gates.

The new model must preserve old saves' actual strength and identity without retaining that rule for
new work.

## Durable instance profile

Stored and equipped gear use the same optional profile:

- stable instance ID;
- catalogue fallback ID and authored unique-rule ID, if any;
- recipe family ID, optional for found/legacy gear;
- construction tier 1–4;
- reforge rank 0–3;
- non-growing legacy power credit, normally zero;
- wild-growth progress, only for the existing authored item that uses it;
- slot, damage kind and reach frozen from the constructed/found piece;
- derived insulation and reactivity;
- immutable consumed-sample provenance and recipe version;
- specialist construction profile, when applicable;
- display provenance/qualifier.

Equipping, unequipping, swapping, collapse recovery and storage must round-trip this complete profile.
`EquippedPiece` may not be a lossy projection of the inventory object.

## Old-save migration

For each legacy piece, calculate its pre-migration smith power before changing fields:

`legacySmithPower = catalogueTier + upgradeLevel`

Then migrate:

1. `constructionTier = clamp(legacySmithPower, 1...4)`;
2. `reforgeRank = 0`;
3. `legacyPowerCredit = max(0, legacySmithPower - 4)`;
4. retain `wildGrowth` separately and unchanged;
5. retain catalogue identity, authored apex behavior and equipped owner/slot;
6. mark recipe family/profile absent unless it can be inferred one-to-one without inventing history.

This deliberately grandfathers old Blacksmith work into the tier it previously achieved. It does
not pretend that a pre-migration blade was made by a specialist, and it never removes power a player
already paid for. Legacy credit above tier 4 remains visible as **Legacy masterwork +N**, cannot be
increased, and is not construction-tier eligibility for recipes or shop gates.

Do not cap, refund or silently downgrade old upgrades. Do not fabricate consumed-material provenance.

## Future power calculation

For ordinary physical gear:

`effectivePower = constructionTier + legacyPowerCredit + 0.2 × reforgeRank`

The flat three-rank ceiling supersedes historical Q35's rarity-based +1/+2/+3/+5 upgrade ceiling.
Rarity remains part of found-item identity and starting catalogue tier; it no longer decides how far
Halloway may reforge a piece inside that tier.

Add `wildGrowth` only where its authored unique rule already applies. Carry fractional effective
power through combat calculation and round once at the existing final integer boundary; never round
each piece first, or all three reforge ranks may become mechanically inert. UI may show a concise
one-decimal rating plus **Tier N · Reforged r/3**.

Construction tier alone controls station/profile creation, rebuild eligibility, specialist recipe
gates, natural tier labels and station caps. Effective power controls combat contribution. Legacy
credit does not unlock tier-4 recipes, and reforge rank never changes construction tier.

## Rebuild and reforge behavior

- Reforge consumes the stated property-qualified stock and essence, raises rank by one, and preserves
  every other instance fact. At rank 3 the piece is finished at the Blacksmith.
- Specialist rebuild consumes the old physical piece plus chosen inputs, replaces construction tier
  and construction profile, resets reforge rank to zero, and preserves stable instance identity,
  authored name/history and any unique rule only when the recipe explicitly allows that base.
- Rebuilding a legacy masterwork requires an explicit warning because replacing its construction
  clears `legacyPowerCredit`; show before/after effective power and never select it by default.
- Apex weapons cannot be silently rebuilt into ordinary families; their rule-breaking behavior is
  the reason they exist. Reforging them within tier remains allowed.
- Channelworks housings keep their separate core/attunement profile and do not pass through physical
  specialist rebuild recipes.

## Storage and selection

Gear stacks merge only when the complete gameplay profile matches. Instance provenance or different
reforge rank keeps pieces distinct. Material bins remain kind-based and are unaffected.

Craft preview defaults to the weakest valid distinct samples, but exact player selection is the
authority. It shows all consumed inputs, grade, natural tier, station cap, derived properties,
name/provenance and wasted grade. No craft occurs when output lacks storage capacity; use the
existing recoverable waiting-pile behavior where appropriate.

## Migration verification

Require fixtures for:

1. stored and equipped legacy gear at every catalogue tier and old upgrade range 0–5;
2. exact pre/post combat power, including values above tier 4 and existing wild growth;
3. equip → unequip and save → load preserving the full profile;
4. three reforges producing three real monotonic combat changes without changing construction tier;
5. specialist rebuild warning and explicit loss of legacy credit;
6. apex and Channelworks exclusions;
7. no invented recipe/provenance on legacy items;
8. tolerant decoding by older bare-ID and object-form fixtures.
