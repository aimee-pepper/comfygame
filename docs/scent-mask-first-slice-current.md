# Scent Mask — first-slice candidate

**Status:** implementation-ready reversible candidate; duration and material floor remain playtest
tuning  
**Owner:** Nessa's Apothecary; existing Shadow nodes remain the skill route  
**Purpose:** give a prepared-item route to avoiding ordinary animal encounters without deleting
creatures, hiding apexes or spending refined Essence

## Recipe and availability

At Apothecary tier 0, infer **Scent Mask** once the player has both:

- **1 Reagent**; and
- **1 ordinary-or-better animal world resource** (`grade >= 25`) of any butchered animal kind:
  plate, quill, pelt, down, hide, chitin, fang, tusk, claw, bone or ichor.

Preparing one mask consumes the selected exact world-resource instance plus one Reagent and costs
**0 Essence** and 0 Motes. Its source is shown in preview—**Fine pelt · from …**—but does not alter
mask strength in v1. Flora-derived timber/fibre/pulp/toxin/reagent cannot satisfy the animal-sample
slot merely because a property value matches.

This intentionally requires a small typed recipe extension rather than a generic reactivity check.
The fiction is a carrier prepared from a trace of real animal material; the game should not pretend
that arbitrary reactive stone has an animal scent. `MaterialKind` already owns the closed animal /
flora distinction, so do not infer origin from the display source string.

`MaterialSample` remains the internal type for this provenance-bearing world resource; player-facing
copy never creates a separate “sample” inventory category.

The current reversible duration is **12 world turns**. A mask can be applied only while Masked scent
is inactive; the Field Kit disables another with **Already masked · N turns remain**. This avoids
hidden duration loss and indefinite pre-stacking. Duration advances only when a world action
actually advances a turn and freezes outside an active expedition.

## Effect

The mask uses the exact sensory comparison in `field-awareness-avoidance-current.md`:

1. compute the ordinary detection radius with all channels;
2. compute it again with chemo removed, without renormalizing anything;
3. when chemo is the deciding channel, the first otherwise-immediate pursuit in that continuous
   contact becomes one visible alert opportunity;
4. remaining in range on the following action still produces pursuit.

It does not protect against direct sight, mechano/thermo detection, ordinary adjacency, attacking,
loud harvesting, an already-alert/pursuing creature or combat already in progress. It has no effect
on active flora, guardians, apexes or creature-on-creature ecology. Multiple party members do not
create multiple masks; this is one timed party field state.

Quiet Step does not stack a second hesitation on the same contact. Evaluate Scent Mask first so the
consumable does not burn Quiet Step's once-per-creature expedition receipt. Leaving the creature's
full ordinary radius ends that continuous mask contact; approaching again while the timed mask
remains may earn another chemo-only alert opportunity. Quiet Step's own per-creature use remains
spent for the expedition.

## Interaction and presentation

- Scent Mask belongs to **Fieldwork** at the Apothecary and **Supplies** in the Field Kit.
- The six-across object tile shows owned/desired/carried quantity; selected detail shows duration,
  current applicability and **Animals relying on scent hesitate; other senses and close contact do
  not.**
- Using it is one explicit field action and consumes one item only after the timed state is installed
  successfully. Cancel, inactive-world use, stale stack and already-masked use consume nothing.
- HUD shows the remaining turns and a redundant scent-wave status mark. Next-step preview names
  **Scent masked: this animal would become alert** only for a legitimately disclosed animal and
  must not leak a hidden creature.
- Bug-report context records source item instance, start/expiry turn and the all/without-chemo radii
  for each transition; ordinary UI never exposes raw channel values.

## Why this recipe is early enough to test

Reagent is a named ordinary world resource rather than a late Reality currency, and any ordinary
butchered animal can supply the second slot. The recipe therefore asks the player to have encountered
wildlife before giving them a reusable preparation against future wildlife, without requiring rare
Ichor, a particular species or a new generic “scent” resource. Nessa still gates production, so the
existing Shadow branch remains the earlier skill investment route.

If phone telemetry shows that Reagent or Nessa arrives after avoidance has ceased to matter, change
availability or the named carrier—not the sensory/contact semantics. Do not solve reachability by
charging Essence, accepting a flora-derived world resource in the animal slot or making the Trading Post generate masks
without authored stock metadata.

## Acceptance

1. Every animal `MaterialKind` qualifies at grade 25; every flora kind and grade 24.999 fails.
2. Preview and commit consume the exact selected world-resource instance and one Reagent atomically, never another
   equal-looking bin; full Storehouse routes the output through ordinary spillover.
3. Crafting costs zero Essence/Motes, and missing/stale/cancel states mutate nothing.
4. Use creates exactly 12 turn advances, cannot stack/refresh while active, and survives relaunch.
5. Chemo-only, mixed-channel, direct-sight, adjacency, alert, pursuing, flora, guardian and apex
   fixtures match the matrix above.
6. Scent Mask plus Quiet Step produces one alert opportunity, not two, and does not consume Quiet
   Step when the mask supplied it.
7. Hidden creatures never appear in preview/debug-safe player copy; disclosed creatures show a
   truthful reason.
8. New bind/revisit packs only the saved exact desired quantity and unused masks return under the
   protected pre-departure supply rule.
