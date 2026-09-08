# Creature bodies and material rewards — production contract

**6 September 2026 · Game Design first pass; not implemented.** Continues Aimee's existing Body → materials homework after the settled Hide and plain Bone slices. This completes the disposition of the current eighteen-family projection and the supported solid-part reward/collection contract. The companion anatomy/material extension now defines the remaining parts and narrow optional uses; the food/shelter and discovery contracts are specified separately. This base packet does not implement those systems or complete the whole creature play experience, and it does not authorize an automatic broad creature runtime rollout.

Read with [body/habitat](generated-creature-body-habitat-v1.md), [role coherence](creature-role-coherence-v1.md), [cold-water appendages](creature-cold-water-appendages-v1.md), [Bone](creature-bone-production-v1.md), [Bestiary knowledge](bestiary-knowledge-and-grouping-v1.md), and the four-band material hierarchy. Aimee's Sky/Water/Amphibious/Land arrangement and its seven body groups remain settled. No renewed Bestiary hold or new homework approval is introduced.


## Superseding implementation consolidation —8September

Follow [the consolidated solid-material packet](creature-solid-materials-implementation-v1-2026-09-08.md) for current source bindings and implementation. Delivered modular anatomy already declares bodySurface, independent wingCount and horn; existing modular rewards deliberately remain Hide/Bone-only. The older threshold list below describes generation history, not a reward-time classifier. Its cranialFeature Horn predicate and generic appendageCount binding are superseded. New source/quality/custody/trade and optional Forge alternatives are one system bundle; later shops and missing organs remain excluded. The preserved historical equations/intent below cannot override the newer packet.

## 1. Historical gap and retained boundaries

Current `CreatureMaterialProjectionRules` has eighteen families, inferred from a species trait vector; `CreatureMaterialRewardRules` grants exact projection quantities using the older generic quality model, with a separate supported narrow typed Hide branch. Bone's new actual-source/four-band producer is already specified separately. The new whole-shop contracts name real input families; an old enum name is not permission to feed an old property calculator.

The current `CreatureTraits` records body plan, cranial feature, appendage kind/count, covering, skeleton, natural attack axes, colour/Pattern, defence and emanation. It does **not** identify injection glands, recoverable oil tissue, pigment-bearing ichor, teeth, claws or tusks as independent anatomical parts. In particular `isToxic` describes the aposematic defence branch, not proof of injected venom. Insulation is covering length×coverage, not proof of oil or fat. Emanation strength is not proof of a body fluid.

Accepted preserved: actual source identity and colour/Pattern; four creature-material quality bands; ungraded world/flora stock; no ordinary animal carrying arbitrary ore, swords or keys as body parts; old saves/stock remain supported. Keep the existing narrow Hide success chance, quantities and custody, the plain Bone predicate/quantity/Anatomy contract, and existing XP/combat outcomes. New material rules require a separate future opt-in rather than reprojecting already saved bodies.

## 2. Body first, reward second

Create a versioned **anatomical material manifest** as part of newly generated species/body identity, after the accepted habitat-conditioned body/appendages and before placement/reward. It is a frozen description of actual existing body regions, not a second damage system or an inventory loot table. Each entry records region identity (body covering, named appendages or cranial horns), physical material identity, the measurements that support it, species quantity rule, and source colour owner. A body may have a covering, appendages and skeleton independently; the same tissue cannot be declared twice under different stock names.

Generation declares the physical covering structure below; the body description and eventual supported renderer must agree. Thresholds are first-pass choices about which structure the game's generator builds, not claims that a hardness reading proves real-world animal taxonomy. A renderer, reward handler, recipe or species nickname may not invent a different part afterward. Never guess a nearby or catalogued species to fill a missing part.

**New primary covering declaration**, in stable order, using finite0…100 species covering measurements:

1. Coverage<15: no recoverable primary covering. Existing positive appendages/skeleton remain independent.
2. Hardness≥55 and length≥45: **rigid protective spines**, not feather quills.
3. Segmented body and hardness≥55: **Chitin**, or **Chitin Plate** when hardness≥70; the same covering is not also generic Plate/Shell/Scales.
4. Radial body and hardness≥55: **Shell**, with no invented layered subtype.
5. Hardness≥70: **Armoured Scales**; the new body manifest explicitly supplies a rigid scaled covering, not a universal Plate item.
6. Hardness≥35: **Overlapping Scales**.
7. Coverage≥50 and length≥45: **Fur Pelt**.
8. Otherwise delegate supported soft skin/hide to its existing typed Hide/Skin owner. No generic second Hide award.

Habitat never substitutes for a covering declaration: a water resident is not automatically scaled, and a feathered appendage does not erase its separate body covering. For a new-policy source, the existing Hide adapter must read the manifest's actual soft-covering branch rather than silently running the old feather-first/water-first family classifier as a second authority. Its accepted material measurements, subtype rules,70% recovery and reward safeguards remain unchanged. If the old adapter cannot validate that shared source, reconcile the actual adapter before enabling that combination; do not double-award, flatten a Pelt to Hide or fabricate a compatible legacy projection. Old non-opted-in bodies remain untouched.

Feathered appendages supply **Flight Feathers** only for an actual supported Sky/winged body; otherwise they supply **Contour Feathers**, without implying flight. Their body covering remains its own region. Membrane appendages supply **Membrane** from their actual sheet region. A finned appendage is recorded as an anatomical fin, but **no generic Fin item** is introduced: its useful membrane/rigid part needs an explicit part-material and measurement mapping before it can yield typed material. Finned does not prove a detached rigid weapon or a particular skin subtype.

A declared Horn requires actual `cranialFeature == horns`, a non-amorphous body and meaningful dominant Crush armament (total≥30, existing stable dominance order). This is the retained useful-weapon boundary, not an assumption that every decorative cranial feature is a useful Horn. Pierce/Rend/Crush alone never creates a Fang/Claw/Tusk entry. A future tooth/claw/tusk-bearing morphology must explicitly identify the part and its physical capabilities before those typed rewards are enabled.

The [remaining anatomy/material extension](creature-anatomy-material-extensions-v1.md) now supplies the required new jaw/claw/Down/sheet/fluid records and conditional typed consumers. The base policy alone still cannot invent them. Its proposed extension must be explicitly enabled with an actual producer; no legacy inference is restored.

## 3. Complete current-family disposition

Category → actual type → meaningful subtype → quality → source remains the public hierarchy. New names below are first-pass physical material definitions, not Earth-species classifications. No new subtype is created solely for a rarity band.

| Old projected family | New actual identity / proposed typed ID | Exact disposition |
| --- | --- | --- |
| Hide | Existing Smooth Skin/Supple Hide/Tough Hide IDs | Existing typed contract; no second generic covering roll |
| Bone | Bone / `creature.bone` | Existing plain Bone contract; no Hollow/Dense invention |
| Pelt | Fur Pelt / `creature.pelt.fur` | New manifest's fur covering, one recovered pelt-material family |
| Scale | Overlapping Scales / `creature.scales.overlapping` | New manifest's scaled covering; no guessed Fish/Lizard taxonomy |
| Plate | Armoured Scales / `creature.scales.armoured`, or Chitin Plate / `creature.chitin.plate`, or actual Shell | Resolved by real covering/body structure; never universal Plate or a second overlapping yield |
| Chitin | Chitin / `creature.chitin` or its plate subtype above | Actual segmented cuticle; plate is a subtype, not another harvest |
| Shell | Shell / `creature.shell` | Actual declared shell; no inference of internal Bone or layered shell |
| Quill | Protective Spines / `creature.spines.protective` | Existing long, hard covering becomes its own physical type; not feather quills or writing nibs |
| Feather | Flight Feathers / `creature.feather.flight`; Contour Feathers / `creature.feather.contour` | Actual feathered appendages; flight only with supported Sky anatomy |
| Down | Extension-only typed source | Needs an explicit separate soft down layer; insulation alone is insufficient and cannot duplicate Feathers |
| Fin | No generic inventory token | Needs the actual recoverable sheet/rigid-part mapping, not an assumed fin-shaped crafting resource |
| Horn | Horn / `creature.horn` | Actual cranial horn plus retained useful Crush boundary |
| Fang | Extension-only typed source | Needs an actual tooth-bearing part and measured capability, not Pierce dominance |
| Claw | Extension-only typed source | Needs an actual claw-bearing part and measured capability, not Rend dominance or limbs alone |
| Tusk | Extension-only typed source | Needs an actual tusk-bearing part and measured capability, not default Crush |
| Oil | Extension-only typed source | Needs an actual recoverable oily tissue/secretion; aquatic insulation is insufficient |
| Venom | Extension-only typed source | Needs actual recoverable venom anatomy/delivery; contact toxicity or warning Pattern is insufficient |
| Ichor | Extension-only typed source | Needs an actual defined body fluid with its relevant chemistry; emanation does not establish fluid or pigment |

**Additional existing anatomical sheet:** membrane appendages may produce `creature.skin.membrane` only when the manifest contains the real sheet region and complete material measurements. No wing/fin membrane is inferred from water habitat, gliding role, body softness or a nearby source. This records a supported existing appendage type, not a new flight mechanic.

For every extension-only family, the base policy alone outputs zero. The new anatomy/material extension supplies its contract; output remains zero until that extension and its actual producer are implemented and enabled. Retain the observed creature's actual attacks, toxic defence and emanation; removing a false material inference must not remove a real combat ability. Old legitimate stock/recipes remain under their exact legacy rules. This policy owns each branch completely: do not fall through to old generic Oil/Venom/Ichor/Fang/Claw/Tusk/Down/Fin awards after the new branch says unavailable.

## 4. Measurement, quality, quantity and colour

Validate the species manifest and actual specimen together. The part must exist on both, belong to this source region and retain actual finite measurements; mismatched new-policy generation is corrected before encounter admission, not silently repaired on reward. Freeze source world/book/species/specimen/encounter IDs, region/part identity, actual traits and validated Coloration, policy versions, pre-party/pre-debug source Danger and the existing Anatomy receipt. Exact source values are retained even when an icon or RGB rendering is not yet available.

| Ready part | Actual measurement pair for quality | Base quantity from species, before Anatomy |
| --- | --- | --- |
| Fur Pelt | covering insulation, covering coverage | size band |
| Overlapping / Armoured Scales | covering protection, covering coverage | size band |
| Chitin / Chitin Plate | covering hardness, covering protection | size band |
| Shell | covering hardness, covering protection | size band |
| Protective Spines | covering hardness, covering length | size band, in portions rather than literal spine count |
| Flight / Contour Feathers | appendage extent, source finish lustre | appendage quantity |
| Horn | Crush armament, bone density | 2 if species armament total≥65, otherwise1 |
| Membrane | actual sheet coverage, actual sheet flexibility | appendage quantity; unavailable without those real sheet measurements |

Covering protection = hardness×coverage/100; insulation = length×coverage/100. Appendage extent = appendageCount/8×100. Finish lustre uses the existing bounded source finish authority; don't add unrelated quality bonuses. A new membrane's sheet measurements are a **named producer dependency**, not permission to copy body-covering values into missing appendage tissue fields. The same explicit-part discipline applies to the held families.

**Quality:** unrounded part expression = mean of the listed actual pair. Score = round-half-up(.75×expression + .25×saved source Danger value); Danger0/1/2/3/4/5 maps20/35/50/65/80/95. Poor0–24, Common25–59, Rare60–84, Exceptional85–100; normal stat multipliers.75/1/1.25/1.5 apply only in an actually authorized crafting role. No earlier rounding, six-band remap, material finish bonus or specimen-name multiplier.

**Species quantity:** size band = min(4,max(1,1+floor(species size/25))). Appendage band = min(4,max(1,ceil(species appendageCount/2))); appendage quantity = clamp(round-half-up((size band+appendage band)/2),1,4), only with an actual positive eligible appendage count. These retain the existing quantity scale, but every output is a useful crafting portion, not a false count of literal horns or wings. Existing Anatomy applies once per positive family quantity: q+max(1,floor(.35q));1/2/3/4 becomes2/3/4/5. Zero stays zero. Bone keeps its separate1–3 size/34 rule and Hide its separate accepted recovery rule; no common70% roll is added to the new positive solid-part rewards.

**Colour and Pattern:** default to the actual specimen's full saved Cyan/Magenta/Yellow/Depth/Patterning, as the existing Bone/Hide source contract does. If an explicit part-specific appearance exists, retain that exact part assignment plus its parent appearance and provenance; never recolour the source or invent a part override on collection. No white Bone, brown Pelt, white Feather or neutral Shell fallback. Preserve non-RGB colour facts when final rendering is pending; old genuinely unknown colour stays unknown. Mixed crafting uses exact selected portions/regions, not a colour averaged from every creature in a stack. Quality name/border styling is separate from material appearance.

## 5. Collection, knowledge, custody and real uses

Positive, eligible new solid-part rewards settle once on the existing successful ordinary-victory reward path for each actual defeated specimen. No extra combat roll, knife, Scythe, harvesting turn, carcass timer, butchery fee or new encounter is added. Escape, non-defeat, repeated settlement, removed specimen and failed save produce no new reward. Existing Return/defeat loss partitions and expedition-frozen Anatomy remain authoritative. This does not add hunting/taming/slaughter or change whether an animal companion can drop materials.

New typed raw parts are slot-free creature materials. Group by exact physical type/subtype and quality, retaining selectable actual source/colour/Pattern/measurement lots underneath; visible equivalent grouping must not erase non-equivalent sources. Do not also award a generic legacy sample or item-slot copy. Trade and selected consumption allocate exact real units once; an unavailable crafting adapter refuses without spending. Full output handling uses existing material custody, not disappearance or auto-sale.

**First-pass raw trade values for the new solid types:** Poor2/Common4/Rare8/Exceptional16 nominal sale per portion; nominal buy twice sale, only where an existing authorized merchant actually offers stock. Existing Hide/Bone and legacy prices stay under their accepted policies. This uniform starting table avoids hidden bonuses for an intimidating name or colour; distinct crafting value must come from an actual named component role. No new merchant inventory, guaranteed buyer or free buyback loop is created.

| Consumer boundary | What this batch actually authorizes |
| --- | --- |
| Reward → carried material → Return → Storehouse → existing raw-material sale | Complete for the ready covering/feather/horn types above, with source identity and four-band prices |
| Bone in Forge/Bowyer/Weaponsmith/Armoury | Already specified in those complete shop contracts; do not repeat or broaden it |
| Skin/Hide → Leather | Existing eligible types remain. New Membrane uses the companion extension's real sheet measurements and explicit1 Membrane +1 Salt Tannery adapter; unavailable until implemented |
| Fur/Scales/Chitin/Shell/Spines/Feathers/Horn in equipment | The [solid equipment extension](creature-solid-equipment-extensions-v1.md) now defines exact protective panels, Pelt lining and Horn supports, with Spines/Feathers deliberately raw-sale-only. These conditional proposals are not implemented or universal substitutes |
| Distillery Heat | Complete new recipe uses Resin. Oil's missing anatomy does not block it |
| Distillery Caustic / Apothecary Venom preparation | Complete recipes use Toxic Sap. No phantom creature Venom/Ichor or generic Toxin is needed |
| Scriptorium Magenta | Dyer's Root remains the complete new source. A luminous creature does not yield ink-ready Ichor |
| Feathers/Quills in writing | Not automatic pigment or Brush/Fountain ingredients; those complete recipes remain unchanged |

The ready raw-material sale path is a real bounded consumer, but it is not a claim that all these materials already have enjoyable crafting uses. Do not enable a broad new reward catalogue merely to fill bags with future promises. Engineering/PM should integrate the exact desired material group with its real consumer and player-facing disclosure, rather than making every new family live at once. The solid equipment extension now closes that first-pass role disposition; producer/consumer integration and natural incidence remain visible in the creature checklist, not another request for Aimee to price individual parts.

Bestiary keeps the approved habitat/body arrangement and existing encounter/Read knowledge. No cast-derived hidden species counts or new victory requirement for already recorded specimen measurements. An actually recovered material may be associated with that known species through its real reward receipt. Exact quantity, colour and quality belong to the recovered specimen, not a promise for every future specimen. A held or unobserved part is not shown as an obtainable reward. The companion `creature-disclosure-player-journey-v1.md` now specifies likely-material/distant-sighting knowledge; it remains unimplemented. Use its actual observation/reward owners, not a sorting or inventory-projection shortcut.

## 6. Ecological and progression consequences

Body/habitat generation precedes the manifest. Keep accepted connected-water requirements, actual flight across allowed ground/water, shore/amphibious compatibility, fixed individual budget and the narrowly water-conditioned cold appendage tendency. Water does not imply Scales/Oil; cold does not guarantee Pelt/Down; feathered non-fliers do not acquire Sky access. Rooted and amorphous forms do not grow an internal skeleton or cranial weapon merely to fill a reward row. Harmless/weak armament does not establish grazing; piercing damage does not establish a predatory diet or fangs.

Several actual parts may coexist in different regions, but total eligible tissue must not be counted twice as Hide/Pelt or Plate/Scales/Chitin, or Fin/Membrane/Bone without separate actual structures. No food, breeding, nesting, weather-immunity, meat/cooking, deep-water fishing or boats are introduced by this reward contract. The separate food/habitat/shelter contract now specifies its first-pass generation relationships; implementation and broader ecology remain open. A material source across inaccessible deep water is not an obtainable recipe route; accepted exploration and encounter access must exist before a recipe points to it. No free remote kill/harvest or hidden map reveal is added to solve that gap.

Ordinary world-resource and gear/curio rolls must not be relabelled as animal anatomy. Any removal of legacy incidental rewards belongs to the explicitly opted-in reward change and must preserve already saved encounter outcomes. The separate historical territory-find proposal is not automatically enabled here and creates no new Aimee approval gate. No replacement rare-find roll is needed for this bounded material contract. XP, Apex-authored trophies and explicit guardian/non-animal rewards keep their existing owners, with no duplicate ordinary-butcher award.

## 7. Focused implementation examples and remaining work

These are design examples, not executed native receipts:

- Segmented, hardness80/coverage80/length20: one Chitin Plate covering, not Chitin plus Plate plus Shell. Actual protection64 gives expression72; Danger2 produces score67 Rare. Species size60 gives3 portions; Anatomy gives4.
- Water-dwelling, hardness20/coverage90/length60: a declared Fur Pelt is valid under the new body grammar; no automatic Scales or Oil. Actual insulation54 gives expression72, Danger2 score67. Existing body/habitat admission still must support that specimen.
- Sky feathered appendages count4, species size60: Flight Feathers, base3 portions; a separately declared hard body covering remains its own region. Actual extent50/lustre60 and Danger2 yield score54 Common. No automatic Down or Hollow Bone.
- The same feathered appendages on an admitted Land body: Contour Feathers, no flight claim. Actual habitat access and role remain unchanged.
- Dominant Pierce without an actual tooth-bearing part: no typed Fang. `isToxic` without venom anatomy: no typed Venom. Heat/light emanation without a fluid: no typed Ichor. These creatures retain their real combat effects.
- A recorded cranial Horn with meaningful dominant Crush and total70 gives2 portions; actual Crush60/BoneDensity60 and Danger2 yield score58 Common. Decorative crest or assumed tusk yields none.
- Same subtype/quality, different source colours: retain individually selectable lots through grouping, Return and sale; no borrowed colour or duplication on reload.
- Existing old world: old projection and settled outcomes remain intact. New malformed manifest: reject before encounter admission; do not repair it from an old generic family.

Engineering should extend its existing focused source/reward/custody tests and one bounded native material route when implementing a group. No new evaluator/catalogue framework, visual matrix, speculative Asset commission, Design native recheck or phone-delivery poll is requested.

**Specified next, not implemented:** [remaining anatomy and material extensions](creature-anatomy-material-extensions-v1.md) now defines teeth/claws/tusks, Down, fin/membrane records and fluid chemistry, with narrow equipment/preparation consumers. The separate discovery and food/shelter contracts also remain unimplemented. **Still unfinished:** implementation of the now-specified [solid equipment roles](creature-solid-equipment-extensions-v1.md), natural source prevalence, broader ecology and combined exploration/crafting feel. None blocks the complete Resin/Toxic Sap/Dyer's Root routes or reopens settled Hide/Bone work. Aimee's three creature goals remain unchecked with concrete partial progress.
