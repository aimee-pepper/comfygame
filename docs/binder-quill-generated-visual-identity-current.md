# Binder, Quill and generated-person visual identity — current boundary

**Status:** implementation-ready persistence boundary; Binder appearance choices and Quill's exact
authored descriptor remain reviewable content.
**Owner:** Game Design owns identity meaning and persistence. Aimee owns final character descriptors
and pixels. Engineering owns save migration, adapters and renderer integration; AssetLab may retain
functional placeholder/conformance support only.
**Scope:** closes the three real human-character gaps left after acceptance of the 28 named
travellers. It does not reopen those 29 identities or authorize portraits.

**Current execution note:** Aimee has reserved character artwork from further AssetLab execution.
The persistence/schema boundary remains current, but exact Binder options and Quill pixels are paused
until she explicitly reopens or supplies that art direction.

## Why these are three different identities

The game must never use `traveller == nil`, roster position, a world seed or a temporary fallback to
decide who a person is.

| Person kind | Identity source | May reroll? | Current visual decision |
|---|---|---:|---|
| Binder | campaign-owned player appearance | no | player-selected from bounded authored parts; no canonical face |
| Quill | one authored founder descriptor | no | fixed identity, separately reviewed; never a generated-person seed |
| Generated person | persisted generated-person record | no | bounded descriptor resolved once from a durable identity seed |
| Named traveller | exact `TravellerID` | no | existing accepted 29-person catalogue; unchanged here |

Tamed animals remain creature identities and cannot enter any human fallback path.

## Durable record boundary

Every human party member resolves through one closed identity union:

```text
HumanVisualIdentity
  binder(BinderAppearance)
  quill(QuillAppearanceVersion)
  named(TravellerID)
  generated(GeneratedPersonID, GeneratedAppearance)
```

`BinderAppearance` stores the selected authored part IDs and personal palette IDs, plus its schema
version. `GeneratedAppearance` stores both the original identity seed and the fully resolved,
versioned descriptor. The resolved descriptor is authority after creation; changing a generator in a
future build cannot change an existing person. Quill stores the authored descriptor version used by
the save so an art migration is explicit rather than an accidental reroll.

Facing, rank, passed-out pose, equipment, selected/current state, environmental grade and combat
status are render inputs layered onto identity. They are not identity fields.

## Binder boundary

The Binder represents the player and therefore has no authored canonical face, body or gendered
silhouette. New Game includes a compact **Appearance** step using bounded authored options rather
than a randomize-only button. At minimum it exposes:

- body/build silhouette;
- hair or head treatment, including a no-hair option;
- outer garment mass;
- personal palette family;
- one small asymmetry/accent choice.

Options use visual thumbnails and neutral labels. They do not carry stats, calling, rarity, combat
lean or world-generation effects. The preview must show straight-top-down map and combat profiles;
neither implies a portrait. A default is allowed, but it is explicitly a selected preset stored in
the campaign—not a canonical Binder appearance or a hidden seed.

Changing appearance after campaign creation is a later review question. It is not required to make
the first persisted identity safe, and Engineering must not silently regenerate the Binder while
that decision is open.

## Quill boundary

Quill is a specific founder and ordinary human party member, not the generic shape used when another
identity fails. Their exact authored descriptor needs one focused Asset/Design review. Until it is
accepted, native code keeps the existing Quill fallback and emits the existing structured
`missing-persisted-appearance` diagnostic at the adapter boundary.

The review must prove Quill distinct from:

- the Binder's complete selectable range;
- all 29 accepted named travellers;
- the bounded generated-person combinations;
- the map traveller, wild-drop, portal and ordinary creature grammars in grayscale.

Quill's name, starting-party role or combat build cannot be encoded as a literal pen, feather or
profession costume. Their identity should read as a person first.

## Generated-person boundary

Resolve appearance once when the durable generated person is first created, before world recurrence,
Tavern arrival, refusal or recruitment. All later appearances reuse that exact descriptor.

- Name, pronouns, voice, want, calling, build plan and current world are prohibited appearance seeds.
- Appearance cannot disclose want quality, willingness to join, combat strength or rarity.
- Generated people reserve the exact descriptor combinations used by the named cast and Quill.
- A collision-free structural combination is still required to differ in silhouette, not merely
  color.
- Legacy records receive a deterministic, campaign-stable migration descriptor derived from their
  new persistent person ID and a frozen migration salt. The result is stored immediately.
- Missing/invalid identity fails closed with a diagnostic and neutral existing fallback; it never
  borrows Tovin, Quill, the Binder or a random named traveller.

## Smallest implementation order

1. Add the closed persistent identity union and stable generated-person ID without changing pixels.
2. Migrate legacy Quill and any generated people deterministically; save the resolved values.
3. Freeze a reviewed Quill descriptor and a bounded Binder appearance option set.
4. Connect the existing accepted named/generated/map render contracts through the identity union.
5. Add New Game's Binder Appearance step only when the save-slot flow owns an atomic draft campaign.

This ordering prevents visual fallback debt without making character art block current encounter,
economy or world-color work.

## Acceptance gates

1. Reorder, station assignment, realm posting, Party changes and save/load preserve exact identities.
2. Creating or revisiting a generated person never changes their descriptor across world/Tavern/
   recruitment transitions or generator-version changes.
3. Two campaigns may choose different Binder appearances; each remains stable through every save
   slot and expedition state.
4. Quill never resolves through `traveller == nil` alone and cannot collide with a generated ID.
5. Named traveller output is pixel-identical to the accepted 29-person catalogue for the same grade,
   facing and state.
6. Missing, unknown and malformed union cases diagnose and fail closed without substituting another
   person's identity.
7. Native-scale color and grayscale sheets prove Binder-range/Quill/named/generated separation in all
   four map facings, plus combat and passed-out states.
8. VoiceOver and save-slot metadata never describe physical features the player did not select or
   that the game has not authored.

## Explicit non-goals

- portraits, face close-ups or dialogue busts;
- procedural anatomy inferred from mechanics;
- equipment changing a person's stable identity;
- appearance rarity, unlock costs or gameplay bonuses;
- reopening the accepted 29 named-traveller descriptors.
