# Current Design — Implemented-Six Diary Focus Profiles

**Status:** approved placeholder mechanical profiles for engineering. Names, owners and conceptual
purposes are settled; numeric values and secondary magnitudes remain debug-menu/playtest tuning.

These focuses must use the live pressure targets. `Strange` is a source family in older vocabulary
documents, not a pressure target, so **Ruin does not attach to Strange**.

## Profiles

### Mara — Scarp

- Attaches to: **Relief**
- Primary contribution: Relief `peak +28`
- Aspects: `openness -25`, `verticality +38`
- Character: `sheer`
- Tags: `broken-ground`, `unclimbable`
- Meaning: a high, abrupt face rather than a generally mountainous world.

### Edren — Ruin

- Attaches to: **Relief**
- Relief contribution: `peak +8`; `openness -12`, `verticality +8`
- Substrate secondary: `peak -10`; `dispersion +24`
- Character: `worked-and-weathered`
- Tags: `broken-ground`, `worked-ground`, `ruined`
- Meaning: terrain marked by construction, collapse and exposed remnants.

`ruined` is a semantic hook for later site weighting; the pressure source does **not** guarantee a
ruin site. Actual ruins remain discrete sites with their own eligibility rules. This keeps Edren's
word useful without collapsing “what a world is” into “what a world contains.”

### Halloway — Gold ore

- Attaches to: **Substrate**
- Primary contribution: Substrate `peak +42`
- Aspects: `dispersion -35`
- Character/form: `concentrated`, `ductile`
- Tags: `valuable`, `precious`, `ore-bearing`
- Meaning: a concentrated precious vein. It is narrower and more locatable than the general Gold
  source, not simply a numerically stronger synonym.

### Isolde — Hush

- Attaches to: **Atmosphere**
- Primary contribution: Atmosphere `peak -5`
- Aspects: `motion -40`, `clarity +8`
- Character: `stilled`
- Tags: `calm-air`
- Meaning: suppresses atmospheric motion. It must remain the strongest direct way to lower motion;
  it does not stop Cycle or time.

### Sela — Pond

- Attaches to: **Hydrology**
- Primary contribution: Hydrology `peak +14`
- Aspects: `dispersion -30`, `salinity 0`
- Form: `standing`
- Vitality secondary: `peak +8`
- Character: `small-standing`
- Meaning: modest, concentrated standing water. It is intentionally smaller than Lake and should
  be useful when a signature needs water without making the whole world lacustrine.

### Tovin — Drift

Use the existing live profile unchanged:

- Attaches to: **Cycle**
- Cycle: `peak -18`; `regularity -35`, `amplitude +10`
- Atmosphere secondary: `peak +6`; `motion +10`
- Tags: `arrhythmic`

Move its acquisition from research to Tovin's diary. Drift means uneven passage, not general speed.

## Acquisition rule

Each focus is learned from its owner's authored diary page and is not duplicated in ordinary
research. The generic diary-teaching schema may carry the focus ID; acquiring the page grants the
focus through the normal vocabulary unlock path.

## Tuning rule

The numbers above are implementation-safe placeholders. Preserve each profile's directional identity
when tuning: Scarp stays sheer, Ruin stays worked/broken rather than a site guarantee, Gold ore stays
concentrated, Hush stays the strongest motion reducer, Pond stays small and standing, and Drift stays
irregular.

