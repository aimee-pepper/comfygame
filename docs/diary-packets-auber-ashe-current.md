# Current Design — Auber and Ashe Diary Packets

**Status:** Authoritative twelve-page late books. Each location page has one signature condition;
each teaching page grants exactly one validated reward.

## Auber — 12 pages

| ID | Kind / unlock | Prose |
|---|---|---|
| `auber_where_0` | location: Hydrology salinity >=45 | “What dries here remains in the next water. Separation changes the carrier that follows.” |
| `auber_where_1` | location: Hydrology dispersion <=30 | “Water gathers into distinct bodies. A mixture needs an edge before its layers can be compared.” |
| `auber_where_2` | location: Hydrology standing form >=60 | “Most wetness stays long enough to settle. Patience separates some things and merely postpones others.” |
| `auber_where_3` | location: Thermal range >=45 | “Heat and cold take turns carrying different parts. Neither interval tells the whole composition.” |
| `auber_where_4` | location: Substrate volatile form >=50 | “The seam answers heat and water by changing. Responsiveness is useful until the vessel is the thing it changes.” |
| `auber_where_5` | location: Substrate dispersion <=35 | “The workable matter keeps to narrow seams. Precision can spare the ground or simply make taking more efficient.” |
| `auber_where_6` | location: Atmosphere clarity <=45 | “Vapour keeps the farther edge uncertain. What leaves the vessel remains part of the process even when nobody collects it.” |
| `auber_where_7` | location: Cycle amplitude >=65 | “Each interval alters the mixture enough to begin another separation. Repetition is not purification by itself.” |
| `auber_brine` | focus; `brine` | “Brine is a carrier made consequential by what it holds. Concentration reveals a property and magnifies every cost attached to it.” |
| `auber_word_nessa` | whereabouts; `nessa` | “Nessa asks what an extract does to this body, now. I ask what had to be concentrated first. A safe dose needs both questions.” |
| `auber_word_grimmond` | whereabouts; `grimmond` | “Grimmond brings material out of a load-bearing place. My vessels remove one part from another. The residue is where both crafts confess.” |
| `auber_word_oda` | whereabouts; `oda` | “Oda gives the concentrated effect a route and boundary. If my output makes her housing harder to read, purity has made the instrument worse.” |

Arc: legibility -> concentrated usefulness -> purity rejected as a moral synonym.

## Ashe — 12 pages

| ID | Kind / unlock | Prose |
|---|---|---|
| `ashe_where_0` | location: Thermal tag `geothermal` present | “Heat rises through my feet before the sky changes. The body notices direction even when the instrument reports only amount.” |
| `ashe_where_1` | location: Thermal range >=45 | “The interval reaches my joints before the scale finishes moving. Endurance is information, not permission.” |
| `ashe_where_2` | location: Illumination tag `sourceless` present | “Light remains without a visible sky-source. Absence of a lamp does not make the sensation imaginary.” |
| `ashe_where_3` | location: Substrate volatile form >=50 | “The ground answers pressure instead of merely holding it. I recognise the reply because mine is also mistaken for obedience.” |
| `ashe_where_4` | location: Atmosphere tag `toxic` present | “The harmful trace stays in the breath after its cause disappears. Danger does not owe anyone a dramatic entrance.” |
| `ashe_where_5` | location: Atmosphere motion >=55 | “The air brings the effect from several directions. A body cannot face every source, but it can name what that costs.” |
| `ashe_where_6` | location: Vitality produced >=35 | “Growth continues beneath conditions called hostile. Survival proves capacity, not comfort.” |
| `ashe_where_7` | location: Cycle amplitude >=65 | “The same forces return at another intensity. A predictable burden is still a burden each time.” |
| `ashe_teach_foe_emanating` | gambit; `subject_foe_emanating` | “An emanating foe is already expressing force beyond the strike you can see. Answer the active release, not the category someone assigned its body.” |
| `ashe_word_oda` | whereabouts; `oda` | “Oda begins with the housing and asks where failure travels. I begin with the person and ask who was allowed to call endurance containment.” |
| `ashe_account_praised_endurance` | account | “They praised the warning after I absorbed what I had warned them about. Before that, the same words were called sensitivity.” |
| `ashe_site_spent_housing` | site; `spent_emanation_housing` | “The housing is empty, but the stone around it still carries the release. An instrument can finish its task before a place finishes receiving it.” |

Arc: bodily evidence -> endurance exploited as availability -> autonomous, chosen intervention.

## Mechanical boundaries

- `subject_foe_emanating` is true only while the foe has a currently active emanation producer/state
  recognised by combat. Creature identity or visual theme alone is insufficient.
- Ashe's starting technique **Ground** is not taught by the diary and is specified separately in
  `ashe-ground-technique-current.md`.
- Auber's Brine page teaches the world-writing focus only. It grants no Distillery output or recipe.
- `spent_emanation_housing` is a site-definition lead, not guaranteed placement. Its reversible
  profile is in `spent-emanation-housing-site-current.md`; defer the page only until that exact ID
  exists in the live site catalog rather than renaming or loosening it silently.
- All relationship pages are non-gating redundancy; unknown target IDs remain deferred.
