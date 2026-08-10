# Current Design — Later Diary Focus Pressure Profiles

**Status:** Approved directional placeholders for implementation and debug-menu tuning. These twelve
profiles complete the non-held diary-focus set after the implemented six. They use only the eight live
pressure targets; there is no `Strange` target.

Values are deliberately moderate. A diary focus should open a distinctive writing route without
single-handedly solving its owner's hunt or replacing compound writing.

## Orsa — Hive

- Attaches to: **Vitality**
- Vitality: `peak +24`; `trophicDepth +12`, `dispersion -32`
- Tags: `colonial-life`, `recurring-shelter`
- Meaning: life concentrated around a repeatedly used shared structure. It does not guarantee a hive
  site, insects, social harmony or tame creatures.

## Vance — Amber

- Attaches to: **Vitality** or **Substrate**
- Vitality: `peak +6`; `dispersion -18`; tag `preserved-organic`
- Substrate: `peak +10`; `dispersion -12`; form `hard`; tag `inclusion-bearing`
- Cycle secondary: `peak 0`; `regularity +10`; tag `slow-change`
- Meaning: living traces removed from ordinary circulation and held as inclusions. It preserves
  relation imperfectly; it is not a generic stasis effect or guaranteed trade good.

## Corrin — Chitin

- Attaches to: **Vitality**
- Vitality: `peak +20`; `trophicDepth +18`, `dispersion -8`
- Substrate secondary: `peak +7`; form `hard`; tag `jointed-organic`
- Tags: `armoured-life`, `molting`
- Meaning: abundant jointed protection on living bodies. It does not directly grant Chitin world
  resources; creature/material allocation remains downstream.

## Nessa — Thorn

- Attaches to: **Vitality**
- Vitality: `peak +18`; `trophicDepth +6`, `dispersion -12`
- Tags: `defended-flora`, `contact-hazard`
- Meaning: producer life whose defence makes contact consequential. It does not create a new poison
  status, guarantee a harvest, or make every plant hostile.

## Bracken — Bone

- Attaches to: **Substrate** or **Vitality**
- Substrate: `peak +18`; `dispersion -16`; form `hard`; tag `osseous`
- Vitality secondary: `peak -6`; `trophicDepth +10`; tags `remains`, `past-mortality`
- Meaning: bodily support accumulated into the ground after death at scale. It does not promise a
  mass grave, monster species, harvest node or narrative explanation.

## Fen — Silk

- Attaches to: **Vitality** or **Substrate**
- Vitality: `peak +14`; `trophicDepth +10`, `dispersion +8`; tag `spinning-life`
- Substrate secondary: `peak +6`; form `ductile`; tags `fibrous`, `tension-bearing`
- Meaning: continuous flexible load made by living processes. It supports cordage/material outcomes
  without guaranteeing a particular creature or ranged weapon resource.

## Sabine — Coral

- Attaches to: **Vitality** or **Hydrology**
- Vitality: `peak +26`; `trophicDepth +14`, `dispersion -24`; tags `aquatic-colony`, `living-structure`
- Hydrology: `peak +10`; `dispersion -10`; form `standing`; tag `shallow-habitat`
- Substrate secondary: `peak +8`; form `hard`; tag `biogenic`
- Meaning: many small lives building persistent aquatic structure. Colony remains ecology, not command
  or automatic companionship.

## Grimmond — Mercury

- Attaches to: **Substrate**
- Substrate: `peak +24`; `dispersion -30`; form `volatile`; tags `liquid-metal`, `chaining`, `toxic`
- Hydrology secondary: `peak +4`; `dispersion -12`; tag `contaminated-seam`
- Meaning: concentrated metal that moves through and connects low seams. `volatile` means responsive
  in the live substrate taxonomy; it does not mean explosive or introduce fluid-substrate simulation.

## Auber — Brine

- Attaches to: **Hydrology**
- Hydrology: `peak +18`; `salinity +42`, `dispersion -22`; form `standing`; tags `brine`, `concentrated`
- Vitality secondary: `peak -8`; tag `salt-stressed`
- Meaning: concentrated saline water as an altered carrier. Unlike Salt, Brine adds water while making
  that water less broadly usable.

## Lys — Echo

- Attaches to: **Cycle**
- Cycle: `peak +4`; `regularity +24`, `amplitude +8`; tags `recurring`, `context-shifted`
- Atmosphere secondary: `peak +3`; `clarity -5`; tag `reverberant`
- Meaning: a recurrence changed by the world that returns it. It does not duplicate a site, recover
  dialogue verbatim or add an audio puzzle system.

## Perren — Mirror

- Attaches to: **Illumination** or **Substrate**
- Illumination: `peak +12`, `floor +8`; tags `reflected`, `reversing`
- Substrate secondary: `peak +10`; `dispersion -14`; form `hard`; tag `reflective-surface`
- Atmosphere secondary: `peak 0`; `clarity +10`; tag `exact-looking`
- Meaning: returned light that appears exact while reversing and framing. It never identifies truth,
  removes false clues, or reveals cult alignment.

## Nine — Dream

- Attaches to: **Cycle** or **Illumination**
- Cycle: `peak +2`; `regularity -22`, `amplitude +18`; tags `oneiric`, `associative`
- Illumination: `peak +8`, `floor +8`; tag `sourceless`
- Atmosphere secondary: `peak +2`; `clarity -12`; tag `felt-before-explained`
- Meaning: strong associative change whose logic is felt before it is explained. It does not create
  memories, prove events occurred, or add a dream-instance/minigame layer.

## Cross-profile validation

1. Every source binds only to listed live targets and every secondary occurs automatically.
2. Tags describe generation inputs; a tag is not a guaranteed site, resource, species or story event.
3. Thorn/Chitin/Hive/Coral/Silk alter Vitality differently: defence, jointed protection,
   concentration, aquatic colony, and distributed tension remain distinguishable in readings.
4. Bone, Mercury and Mirror use live Substrate forms pragmatically. UI prose must describe the
   material honestly instead of exposing taxonomy compromises such as Mercury's `volatile` bucket.
5. Echo, Dream and Drift remain distinct: recurring return, associative irregular change, and uneven
   passage respectively.
6. Debug sliders may tune magnitudes but must preserve signs, principal aspects, tags and contrasts.
7. Before landing, generate single-focus and representative compound fixtures and verify no source is
   inert from baseline/clamping or overwhelmingly satisfies a late signature alone.

