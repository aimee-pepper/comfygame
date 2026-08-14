# Diary Teaching Registry — Implementation Audit

**Status:** Current implementation boundary  
**Date:** 11 August 2026  
**Authority:** `diary-teaching-registry-current.md` owns reward identity; this audit records what is
actually live and the smallest honest promotion paths.

## Live coverage

The live 29-traveller catalogue currently grants **26** singular diary teachings:

- 18 world-writing focuses;
- 7 gambit subjects;
- Maud's `maud_fitting_pattern`.

That is not the complete 29-reward registry. Three designed entries have distinct dispositions:

| Owner | Designed reward | Live state | Disposition |
|---|---|---|---|
| Talin | `subject_foe_armour_above` | Page and gambit component absent | **Promote with typed armour-threshold support** |
| Noll | `field_separation_kit` | Deliberately absent; tests enforce absence | **Hold for Aimee's interaction/playtest review** |
| Oda | `emanation_housing` | No schematic field, registry or saved knowledge exists | **Promote with the Channelworks progression checkpoint** |

The live corpus count of 18 focus + 7 gambit + 1 pattern is therefore accurate. Documents must not
describe all 29 rewards as implemented merely because their ownership has been designed.

## Talin promotion contract

Add the already-authored page `talin_teach_armour` and semantic component
`subject_foe_armour_above`. Its prose remains controlled by `diary-packets-early-mid-current.md`.

The subject evaluates the relevant living foe's **current armour points** against a player-selected
absolute mark. First marks are 1, 3 and 5 as settled in `gambit-stat-thresholds-current.md`. It is not
an HP percentage, base/catalogue armour, damage prediction, target chooser or automatic Pierce
selection. The ordinary gambit editor must expose the compatible marks and unit.

Required evidence:

1. the page grants the component exactly once and survives save/load;
2. current armour above/equal/below each mark produces correct strict `>` truth;
3. armour changed during combat is read live;
4. the component composes with ordinary actions and target selection;
5. the page cannot be selected before its reward ID validates.

## Noll hold boundary

Do not add `noll_field_separation_kit`, a research alias or a hidden recipe to make the 29-count look
complete. Baseline Recycler access and Noll's arrival are independent and must remain fully usable.
The proposed kit still needs a player decision on whether one-use field dismantling earns its packed
slot, turn and confirmation cost. Existing saves gain nothing while it is held.

## Oda schematic contract

`emanation_housing` unlocks the **later Contact and Projection housing recipes** at the Channelworks.
It does not gate:

- recruiting Oda or constructing the Channelworks;
- the one authored damaged Heat Conduit restored by that construction;
- the repeatable basic Conduit recipe once its ordinary core dependency is met; or
- a bundle of weapons, cores, attunements or research nodes.

This makes the teaching useful without contradicting the settled dependency-safe arrival in
`channelworks-system-current.md`: Oda's station has an immediate Conduit verb before Auber, while
her recovered knowledge opens the wider reach-family route.

Implement a generic typed schematic path rather than an Oda-only Boolean:

- `teachesSchematic: SchematicID?` on a diary page;
- a validated schematic registry containing `emanation_housing`;
- durable `knownSchematics` in Library knowledge with tolerant empty decode;
- idempotent page acquisition through the shared teaching transaction;
- Channelworks recipe visibility/readiness reading the stable schematic ID.

Do not treat station unlock state, ownership of the restored fixture or possession of a Channelworks
weapon as proof that the schematic was learned. Those are different receipts. Old saves with Oda's
teaching page already recovered should reconcile the schematic once; merely having built the station
must not invent diary knowledge.

Required evidence:

1. unknown -> known happens once on page acquisition and survives relaunch;
2. old recovered-page saves reconcile once; old station-only saves do not;
3. starter restoration and basic Conduit remain available without the schematic;
4. Contact/Projection are unavailable before and available after the schematic, subject to their
   ordinary station tier/material requirements;
5. no weapon, core or recipe output is granted by learning alone;
6. shuffled content order and repeat page acquisition are stable.

## Generic validation correction

The content validator must accept a registry of typed pattern and schematic IDs. It must not retain
a one-off allow-list that recognizes only `maud_fitting_pattern`. Every diary page may carry at most
one teaching/reveal field, and unknown IDs fail before the page enters world selection.

## Handoff order

1. Promote Talin with the next coherent gambit-component checkpoint.
2. Add Oda's generic schematic receipt alongside the Channelworks restoration/progression checkpoint.
3. Leave Noll's optional kit held; it is not a prerequisite for either change.

