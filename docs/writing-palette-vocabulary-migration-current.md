# Writing palette grouping and vocabulary migration — current design

**Status:** Current presentation and migration design. No world mechanics change.  
**Scope:** Focus subgroups, player-facing terms and retirement of the old `source`/`symbol` taxonomy.

## Player-facing vocabulary

The settled terms are:

| Concept | Current term | Meaning |
|---|---|---|
| World's dial | **Subject** | Illumination, Thermal, Hydrology, Substrate, Relief, Vitality, Atmosphere, Cycle |
| Concrete cause acting on a subject | **Focus** | Sun, Ice, Rain, Granite, Hush |
| Reusable strength/count/negation word | **Modifier** | Great, Faint, Count, Negate |
| Several known atomic marks compressed into one | **Compound** | A learned or player-authored shorthand |
| Connection between complete statements | **Chain** | Spatial/semantic relationship, not a rune object |

Do not show “pressure source,” “symbol slot,” “primary symbol,” or old Terrain/Biome/Bounty/Quirk
language in current UI. “Rune” and “sigil” may remain ordinary fictional umbrella words, but not as
competing data categories.

## Palette subgroups

The Writing Desk remains organized first by subject. Three subjects receive meaningful directional
subgroups:

| Subject | First group | Second group |
|---|---|---|
| Illumination | **Light** | **Shadow** |
| Thermal | **Warming** | **Cooling** |
| Vitality | **Growing** | **Consuming** |

These are collapsible headings inside one subject bin, not new tabs. The first group opens by
default; a subgroup with no owned focuses remains hidden rather than showing an empty promise.
Search results preserve the subgroup label.

Grouping is explicit authored display metadata per attachable subject, not inferred from the sign of
one number. A focus can affect several subjects differently: Ash belongs under Shadow for
Illumination, Cooling for Thermal and Consuming for Vitality. Decomposing/suppressing vitality
characters display under Consuming; their detailed reading still names the actual character. A
genuinely mixed focus is placed according to the deliberate reason a player chooses it for that
subject and may appear in both groups only if it represents two distinct writable uses.

Hydrology, Substrate, Relief, Atmosphere and Cycle remain single lists for now. Generic
Increase/Decrease headings would add navigation without adding understanding; introduce subgroups
only when those subjects have player-language distinctions as strong as light/shadow.

Within a subgroup, sort owned focuses by:

1. broad before named before precise;
2. authored standardness, common to strange;
3. display name for stable ties.

Acquisition route and mechanical magnitude do not determine palette order.

## Data metadata

Each focus may author `paletteGroups`, keyed by subject ID, with values from:

- `light`, `shadow`;
- `warming`, `cooling`;
- `growing`, `consuming`.

Validation requires a legal group for every attachment to one of those three subjects. Attachments
to the other five omit the field. This is display metadata only: it never changes contributions,
greed, stability, eligibility or signature matching.

## Vocabulary migration

The current filenames and Swift types preserve an obsolete intermediate taxonomy. Migrate them as
one mechanical change:

| Old | Current |
|---|---|
| `pressure_sources.json` | `focuses.json` |
| JSON root `sources` | `focuses` |
| `PressureSourceDef` | `FocusDef` |
| `PressureSourceID` | `FocusID` |
| `pressureSource(...)` | `focus(...)` |
| `symbols.json` | `compounds.json` |
| JSON root `symbols` | `compounds` |
| `SymbolDef` | `CompoundDef` |
| `SymbolID` | `CompoundID` |

The old `symbols.json` content is not deleted as gameplay. Those entries are authored compounds and
remain available under honest names. The retirement is of the false category and filename, not of
the player's learned shorthand.

### Rename boundary

This is a **writing-domain semantic rename**, not a repository-wide word replacement. Rename only
identifiers whose type/meaning is the concrete cause attached to a writing Subject, or the old
precomposed writing mark category.

Keep `source` wherever it means:

- material/item provenance or sample origin;
- an event, reward, telemetry or transaction source;
- a physical light/heat/sound source in prose or analysis;
- a migration source value; or
- generic source/target programming vocabulary outside writing grammar.

Likewise, ordinary uses of “symbol” for an SF Symbol/icon, typography or mathematical notation are
not automatically `Compound`. Acceptance scans must classify occurrences by domain rather than
demanding that the English words disappear from the repository.

## Save and integration safety

- Stable raw IDs do not change. Old saves decode their focus/compound sets into the renamed types.
- During one migration window, the catalogue loader accepts old root keys as decode-only fallbacks;
  newly written bundled data and encoded saves use only current keys. The fallback has an explicit
  schema version and removal audit rather than becoming a permanent second authority.
- Any persisted enum/type-name wrappers migrate tolerantly rather than requiring save reset.
- Code comments and tests update in the same change so future work does not reintroduce “symbols” as
  a parallel vocabulary.
- Asset manifest roles use `focus` and `compound`. Existing asset IDs may alias old names until the
  asset lead completes the corresponding manifest migration.
- Do not combine this naming migration with balance edits. Before/after fixtures must produce
  identical books, pressure readings, projections, worlds and owned vocabulary.

## Acceptance checks

1. Sun appears under Illumination → Light and Thermal → Warming where attachable.
2. Ash appears under Illumination → Shadow, Thermal → Cooling and Vitality → Consuming.
3. A focus shown in multiple bins is one owned focus, not duplicated progression.
4. Compound saves made before migration reopen with identical expansions.
5. Repository search finds no player-facing use of the retired **writing taxonomy** outside
   archive/migration notes; legitimate provenance/event/source and icon/symbol language remains.
6. Empty subgroup headings do not occupy phone screen space.
7. A before/after seeded fixture proves identical expanded statements, readings, price, stability,
   world receipt and generated map—not merely successful save decode.
8. Old-key fallback decodes an old fixture, while newly encoded content/save output contains only
   the current writing-domain keys.
