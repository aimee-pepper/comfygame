# Community, party assembly and Tavern visitors — current design

**Status:** P1 minimum placement safety implemented; stable-ID migration and full screen contract queued.  
**Owner:** Game Design owns player choices/presentation; Engineering owns stable identity, exclusive
placement and visitor receipts; Aimee owns final person/visitor tile art, while Asset Design may
validate placeholder state/layout only.
**Extends:** `tavern-random-companions-current.md`, `party-member-identity-progression-current.md` and
`anchorage-portfolio-assignment-current.md`.

## Implemented compatibility boundary

The current roster-index save schema now enforces one effective placement: taking a realm worker
atomically removes their posting and recalculates production; returning a traveller sends them Home;
the Firepit distinguishes Home from realm postings and previews realm/station consequences before
confirming. Decode deterministically repairs contradictory legacy projections with Party first, then
the lowest active realm ID, then Home.

This is deliberately not represented as the final stable identity migration. Combat, equipment,
encounters, staffing, generated people and animals must all cross that boundary together under
`party-member-identity-progression-current.md`; roster indices remain the compatibility key until
that coherent migration lands.

## Audit result at handoff

The current Firepit is compact but still models people incorrectly:

- every roster member not in the active party appears under **Around the fire**, including people
  posted to anchored realms;
- taking someone into the active party adds their roster index but does not remove an anchored-realm
  assignment, allowing one person to travel and produce remotely at once;
- all people are rows, and the future Tavern visitor experience has no live spatial home;
- dormant dead copy still claims “five is as many as you can keep,” contradicting the uncapped roster.

Party size is five including the Binder. Community size is not capped.

## Firepit and Tavern structure

The same destination grows in place:

- **Firepit:** **Departing / Community** tabs.
- **Tavern after Orsa:** **Departing / Community / Visitors** tabs.

### Departing

Show five fixed party positions: the Binder plus four companion positions. Filled positions use
person identity tiles; empty positions are quiet **Choose someone** targets. This surface answers only
who will enter the next expedition. Rank, gear, Gambits and full stats remain on Party.

Below the positions, eligible people appear in a compact two-column identity grid with name, calling,
level and current-location badge. Tap opens an anchored person detail and **Take with you**; it never
adds a person on the first tap.

### Community

The full recruited community is grouped by actual exclusive location:

- **At Home** — available and station keepers/builders currently posted Home;
- **Traveling** — selected active party;
- **In realms** — realm name shown;
- later explicit assignment locations only when their real systems exist.

Groups use person tiles and filters/search once the roster exceeds twelve. A person appears exactly
once. The tab is not a duplicate Party screen: detail links to Party for build/loadout and to the
relevant station/realm for assignment.

### Visitors

After Orsa, up to the settled three persisted seats appear as visitor tiles. Each shows stable visual
identity, name/pronouns, short build phrase and one want-family mark. Tap opens:

- first-met provenance and current qualitative clue;
- exact persisted want and whether it is currently satisfiable;
- exact selected resource/sample for consuming wants;
- knowledge/place/record evidence for non-consuming wants;
- recruitment result and where the person will be At Home.

**Welcome them** commits want fulfillment and stable-person recruitment atomically. Inspecting,
declining or rotating a seat never erases the met person. Named diary travellers do not enter this
surface.

## One authoritative location

Every recruited human has exactly one current placement:

```text
PersonPlacement = home | activeParty | anchoredRealm(RealmID) | futureTypedAssignment(...)
```

The active party and realm worker arrays become projections/migration inputs, not independent truths.
All movement actions validate the stable person ID and source placement, then atomically set one new
placement.

### Taking someone

The detail previews consequences before confirmation:

- from Home keeper: station benefit/discount suspended;
- from a realm: exact realm sustain and harvest before → after;
- from another future assignment: named consequence owned by that system;
- active party full: choose one current companion to return Home in the same confirmation.

Confirm performs one transfer. A person taken from a realm cannot remain in its worker projection.
Returning someone from the party sends them Home; it does not guess a previous posting.

### Direct party replacement

When all four companion positions are filled, **Take with you** becomes **Replace…** and asks which
current companion returns Home. The preview names both changes. This is one atomic transaction, so a
stale target or source cannot leave the party over capacity or lose either person.

No drag-and-drop is required. Position order is party display order, not combat initiative or rank;
reordering positions has no hidden mechanical effect.

## Generated visitor arrival build

Visitor build summaries read the explicit stable-node graph plan in
`generated-companion-arrival-builds-current.md`. They show final intended lane identities and actual
currently owned nodes. They never infer a build by obsolete branch depth or promise a hybrid route
the ordinary graph rejects.

## Migration and reconciliation

For legacy contradictory placement, reconcile once in this order:

1. active expedition party if a run exists;
2. active party selection at Home;
3. one active anchored realm, lowest stable realm creation order only as deterministic repair;
4. Home.

Remove all losing duplicate projections, record the repair in DEBUG and preserve the person. Roster
array order is never identity. Quill, named travellers and generated people retain their distinct
namespaced IDs.

## Acceptance

1. Five-person party positions fit at 368×800 without oversized rows or unnecessary scrolling.
2. Every recruited person appears exactly once in Community under their true location.
3. Taking a realm worker atomically removes that posting and previews the exact production change;
   taking a Home keeper previews the suspended benefit.
4. Full-party replacement is atomic and never exceeds four companions plus Binder.
5. Returning a traveler goes Home and does not silently restore an old assignment.
6. Three visitor seats persist across relaunch, change only on a new expedition outcome and never
   delete met people.
7. Every consuming want uses an explicit exact selection and stale/cancel paths spend/recruit
   nothing; evidence wants consume nothing.
8. Named travellers never enter random visitor generation, while generated stable identities cannot
   collide with Quill or one another.
9. Large text, grayscale and VoiceOver convey location, party position, visitor/want state,
   displacement consequence and confirmation without colour or tile position alone.
