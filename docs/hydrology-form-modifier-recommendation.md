# Hydrology Form Modifier — Recommendation

**Status:** revised Game Design recommendation — cut the modifier from the first writable grammar;
the live inert **Phase: Frozen / Solid / Liquid / Vaporous** palette stays hidden. Revisit only if
play proves source selection cannot express a needed water-form choice.

## Revised disposition — do not implement this modifier yet

The live source catalogue already exposes the simulation's four forms through concrete causes:

- Standing: Pond, Lake, Marsh, Sea, Brine and Coral;
- Flowing: River and Geyser;
- Frozen: Ice, Snow and Glacier;
- Airborne: Rain and Mist.

Choosing the source is therefore already the meaningful water-form decision. A second modifier
mostly permits strained remappings such as **Standing Rain**, **Airborne Lake** or **Flowing Ice**,
then asks constraints/readback to explain why the chosen source stopped behaving like itself. It
adds an optional `Sigil` field, palette branch, page-cell cost, compound rule, migration path and
History explanation without filling a demonstrated authorship gap.

Current recommendation:

1. permanently retire the old Phase labels rather than migrating them;
2. do not replace them with writable Water Form in the first qualifier grammar;
3. let Lake/River/Ice/Rain-family source choice own form, with Thermal constraints still able to
   transform the resolved world; and
4. if play later needs deliberate form conversion independent of source, design one explicit
   compound/transformation operation with an honest contradiction/Stability cost rather than a
   universal free redirector.

The remainder of this document preserves the previously developed implementation candidate so the
reasoning is not lost. It is superseded by the disposition above and supplies no implementation
authority.

## Superseded implementation candidate

Rename the qualifier category from **Phase** to **Water form** and replace its four choices with the
simulation's exact forms:

| Choice | Player meaning | Simulation target |
|---|---|---|
| **Standing** | Water held in bodies or pools | `hydrology.forms.standing` |
| **Flowing** | Water travelling along or out of terrain | `hydrology.forms.flowing` |
| **Frozen** | Water held as ice/snow/glacier and unavailable to life | `hydrology.forms.frozen` |
| **Airborne** | Water carried through atmosphere as rain/mist/cloud | `hydrology.forms.airborne` |

“Solid” is not a second useful water form beside Frozen, “Liquid” cannot distinguish standing from
flowing, and “Vaporous” is too narrow for rain/cloud. The replacement uses words already found in
world simulation, clues and description rules, so the writing palette stops teaching a parallel
taxonomy.

## Modifier semantics

- Water form is available only when the selected focus makes a **positive Hydrology magnitude or
  form contribution**. It is hidden/disabled for a focus with no Hydrology effect and cannot turn a
  Hydrology-reducing focus into a source.
- It redirects that focus's positive Hydrology form weight to the selected form before the normal
  constraint pass. It does not change the focus's Hydrology magnitude, dispersion, salinity, tags or
  secondary contributions.
- It applies to the selected focus instance only. It does not globally convert every water source on
  the page.
- Thermal and Atmosphere constraints still act afterward. In ordinary resolution, freezing may
  convert standing/flowing water to Frozen and extreme heat may move eligible water Airborne. The
  modifier is a request, not immunity from the world's other conditions.
- If a later explicit contradiction grammar lets the Binder insist against conversion, that is a
  separate authored operation with Stability cost. Water form alone never creates the exception.
- The authored focus remains visible in the readback: **Standing Rain** may resolve strangely or be
  corrected by the simulation, but the History explains requested form, resolved form and the
  constraint that changed it rather than silently rewriting the page.

### Saved representation

If approved, assembled page composition adds an optional `waterForm` to the individual `Sigil`.
That is the exact selected-focus instance the modifier belongs to. Do not store a page-global form,
infer it from adjacency during later resolution, or mutate the pressure-source catalogue entry.
Compound-expanded and randomly rolled sigils default to nil unless their authored source
contribution already supplies its ordinary form.

The qualifier still occupies its ordinary page cells and therefore participates in ink/page-space
cost. `BoundBook.composition` freezes the selected form at bind so an existing world cannot change
when the palette or qualifier catalogue changes. Desk preview and world resolution consume the same
assembled sigils.

Legacy Phase rune IDs remain decodable but inert. `frozen` could map linguistically, while `liquid`
and `solid` are ambiguous in the new four-form model; consequently migration must not partially
reinterpret old books. Preserve their original readable marks/warning and leave `waterForm` nil.

## Distribution rule

The live resolver measures form weight in the same units as that sigil's positive resolved
Hydrology peak. Therefore, for one compatible sigil, suppress its ordinary contribution-form label
and add that sigil's positive resolved Hydrology `peak` to the selected form. If its positive
Hydrology contribution had no explicit form, add that same `peak`; do **not** add a unit weight of 1,
which would make an equally strong generic source almost irrelevant beside an authored source.
Other sigils combine normally, then form weights normalize once before the existing fixed-order
constraint pass.

This avoids inventing a percentage slider in the phone palette while allowing the same focus to ask
for a different water expression.

## UI and copy

- Label the category **Water form**, not Phase.
- Present it only beneath a selected compatible Hydrology focus.
- Preview: “Direct this focus toward Standing water.”
- Resolved readback when unchanged: “Its water gathers in standing bodies.”
- Resolved readback when constrained: “You asked this source to stand, but the cold held its water
  frozen.”
- Do not present form selection as a guarantee or hide a contradiction/Stability consequence.

## Verification before enabling

1. Each choice changes only the selected focus's Hydrology form contribution.
2. Magnitude, dispersion, salinity, tags and other targets are byte/value-identical before the
   constraint pass.
3. Cold conversion and airborne/no-atmosphere behavior remain consistent with the settled pressure
   model and contradiction rules.
4. Multiple Hydrology focuses can carry different Water form modifiers on one page and combine
   deterministically.
5. Invalid legacy Phase values decode with a warning and remain hidden; old saves do not gain an
   invented form.
6. Desk, bind, History and description use one resolved form result and explain any conversion.

## Live-code audit notes — 9 Aug 2026

- The simulation already uses exactly standing/flowing/frozen/airborne and thermal conversion runs
  after unconstrained form normalization.
- Current writable-page assembly stores intensity, scale and count on `Sigil`; Phase is correctly
  hidden and deliberately omitted. An approved implementation therefore needs the explicit optional
  saved field above rather than reactivating inert Phase by name alone.
- Current form accumulation weights each positive contribution by its resolved peak. The earlier
  “standard weight 1” recommendation was dimensionally inconsistent and is superseded.
- `WorldConstraints` currently freezes standing/all and flowing/half below the freezing floor, and
  moves 60% of standing water airborne above the evaporation peak. Atmosphere does not directly
  rewrite water forms, so verification must not claim a no-atmosphere conversion rule that does not
  exist.
