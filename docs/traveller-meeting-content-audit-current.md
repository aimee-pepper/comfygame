# Traveller meeting content audit — current

**Status:** Design coherence pass complete; exact draft prose remains `Draft / needs Aimee review`.  
**Scope:** 21 meetings missing from the 29-person live catalogue, live-provisional Noll's replacement, plus
Auber's revision candidate: 23 review meeting objects across a 29-identity review union.  
**Not approval:** this pass removes contradictions and structural nonsense; it does not substitute for
Aimee's atlas-by-atlas taste review or promote text into the release catalogue.

## Corpus-wide correction

The shipped meeting UI places `meeting.offer` on the player's prominent recruitment button. Most
drafts accidentally wrote that line in the traveller's voice—“Your party… I can teach…”, followed by
the same traveller's accepted reply. Every current review draft now follows:

```text
traveller opening/replies → player-spoken offer → traveller accepted or declined reply
```

The corpus plan and atlas acceptance now require speaker-labelled transition review. String/schema
validity alone cannot catch this class of conversational error.

Noll is the twenty-ninth live traveller with a provisional DEBUG-labelled meeting. Their replacement
meeting is canonical review input beside Vance in the early-economy review file. The corpus therefore
contains 8 live meetings plus 23 review objects: 21 missing-live drafts, Noll's replacement and
Auber's alternate.
The original Noll identity-file version remains explicitly labelled historical rather than becoming
a second editable authority.

## Specific corrections made

| Traveller | Defect | Current correction |
|---|---|---|
| Vance | Offer still promised Recycler recovery after Vance/Noll station separation | Player invites Vance to buy surplus and maintain rotating, provenance-aware Trading Post stock only |
| Nessa | “Bring me the bodies” could reasonably read as a request for corpses | Player brings ingredients and names intended body/route/time |
| Rook | Opening said the creature was outside spear reach; optional reply said Rook could reach it | Creature is short of the crossing but inside Rook's reach, preserving the power asymmetry |
| Sabine | Clear tracks were treated as proof an animal wanted to be found | Track clarity gets physical alternatives; neither implies tolerance or consent |
| Noll/Halloway | Historical diary draft used he/him for Halloway | Current text uses Halloway's established she/her pronouns |
| Ashe | Traveller-voiced offer put “when I choose the cost” in the player's mouth | Player explicitly leaves the decision and cost with Ashe |

## Batch disposition

- **Early economy/hinge:** six current drafts (Bryn, Orsa, Vance, Noll, Talin, Nessa). Structurally
  coherent after speaker and ownership corrections; exact voice remains for Aimee.
- **Mature core:** Corrin, Dagg, Rook, Lys, Bracken and Fen. Practices and station boundaries remain
  distinct; Rook's spatial contradiction is fixed.
- **Specialists:** Wren, Kestrel, Maud, Marrick, Sabine and Grimmond. Offer voice is fixed; Sabine no
  longer anthropomorphizes track evidence.
- **Transformation/endgame:** Auber, Oda, Ashe, Perren and Nine. Physical openings and narrative
  restraint remain intact; all offers now read as the player's invitation.

## Remaining human-review questions

These are taste/content review, not blockers to schema or atlas generation:

The independent recommendation pass in `traveller-meeting-voice-differentiation-audit-current.md`
maps these questions to individual travellers and defines a paired atlas review order. It does not
promote or rewrite the exact review drafts.

1. Does each voice feel enjoyable rather than uniformly aphoristic across a long campaign?
2. Which individual lines are too compressed or self-consciously philosophical when read aloud on a
   phone?
3. Do the accepted replies create enough warmth/momentum after the more analytical optional replies?
4. Does Perren reveal the right amount of Sundering interpretation without sounding canonical?
5. Does Nine feel present and agentic without making memory loss her entire identity?

Atlas reviews remain per authored unit and exact hash. A batch-level design pass cannot mark every
opening/exchange/offer/terminal line Good, and later copy changes correctly stale prior reviews.

## Verification before promotion

1. Generated DEBUG corpus check is green and reports 23 review objects across 23 unique draft IDs,
   while the atlas row union is 29 identities; Auber live/revision render side by side and Noll has a
   visible review-only row.
2. Every meeting has three unique semantic exchange IDs and renders all six question orders.
3. Speaker-labelled preview reads every offer as plausible player speech and every terminal line as
   that traveller's response.
4. Trading Post/Recycler, station, pronoun and teaching references match current authorities.
5. Aimee explicitly reviews exact text units; only matching hashes can become Good/promoted.
