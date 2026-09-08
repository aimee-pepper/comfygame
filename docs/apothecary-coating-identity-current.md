# Apothecary coating identity

**Current authority — reconciled 7 September 2026:** the complete Apothecary production contract supersedes the former isolated Briar Oil/Venom adapters and first-slice ingredient table. Engineering reports the full batch and excursion-long lifecycle delivered322. Use `apothecary-whole-shop-production-v1.md` in the Design worktree for the complete producer, learning, batch, value and migration rules, and the public crafting-shop overhaul for player-facing current recipes. Do not restart the old adapter queue.

## The four preparations

| Stable item ID | Name | Affliction on a qualifying hit | Current recipe; zero Essence |
|---|---|---|---|
| `venom` | Venom | Poison | 1 Toxic Sap, 1 Plant Fibre |
| `firebrand` | Firebrand | Burn | 1 Sulfur, 1 Resin |
| `briar_oil` | Briar Oil | Bleed | 2 Plant Fibre, 1 Resin |
| `flashsalt` | Flashsalt | Dazzle | 1 Quartz, 1 Sulfur, 1 Salt |

No hidden third property sample or minimum material rarity is part of these recipes. Supported legacy stock keeps its explicit compatibility route; that does not restore an obsolete recipe as the new material contract.

## Lifecycle and affliction boundary

An applied coating belongs to its chosen eligible physical weapon and exactly one world excursion. It survives hits, misses, encounters, travel, backgrounding and reopening within that excursion. It expires when the excursion ends. Applying it spends the preparation once; hitting does not spend it again. Channelworks remains a separate, ineligible weapon system.

A qualifying strike applies the named affliction through the existing typed registry. Affliction duration, severity, cures, non-standing targets and max/reapplication semantics remain separate from coating lifetime. If the hit defeats or passes out the target, do not create an affliction on that non-standing target; the coating remains on its weapon for the rest of the excursion.

Burn, Poison, Dazzle and Bleed remain the four afflictions. No Freeze or Shock is added. Rimeoil and Stormsalt remain retired display names; decode-only compatibility does not reintroduce them in player copy.

## Handoff and verification boundary

Validate actual whole-shop inputs and atomic output/spending, exact weapon/world ownership, repeated qualifying hits and persistence across encounters/reopening, followed by expiry at Return. Missing inputs, stale selections, cancellation and failed saving must not spend or grant partial results. Use existing delivery evidence rather than requesting another phone pass for this documentation correction.

The old successful-strike consumption, separate reactive/flexible sample requirements and 9/11/11/13-Essence findings are historical evidence from August and the temporary September bridge. They are not current implementation instructions. The dated full-shop audit preserves why they changed.
