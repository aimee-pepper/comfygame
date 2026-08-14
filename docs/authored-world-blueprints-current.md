# Authored world blueprints — current

**Status:** implementation contract for Band 6+, deliberately not an opening priority  
**Date:** 14 August 2026  
**Depends on:** accepted ordinary generation, encounter scaling, sites, World Pages and save versioning

## Purpose

An authored world blueprint lets a unique World Page promise a particular place or story event.
It is not a second world engine. It supplies constraints and authored facts to the ordinary generator,
then receives the same validation, rendering, persistence and expedition lifecycle as any other world.

Use a blueprint only when topology or placement carries meaning that sigils and a frozen seed cannot
express. A picturesque random world is not sufficient reason to author one.

## Definition contract

Every blueprint has:

- a stable `blueprintID` and content version;
- the World Page definition IDs allowed to invoke it;
- a 6×6 authored page receipt, including mark layout, hand and any canonical ink receipt;
- a map policy: `fixed`, `constrained`, or `seededWithOverrides`;
- explicit required and forbidden terrain/content facts;
- stable authored object IDs for story sites, exits, encounters and interactables;
- allowed variation ranges, each named rather than hidden in a seed;
- a completion/failure contract and any one-time campaign receipts;
- a minimum compatible save format and generator version;
- validation fixtures proving reachability, collapse runway, disclosure and encounter bounds.

The generated world stores the exact blueprint/content/generator versions and resolved authored facts.
History renders that frozen receipt; it never reconstructs an old visit from the newest definition.

## Three topology policies

### Fixed

Every playable cell and required object is authored. Cosmetic variants may change only where the
definition permits them. Reserve this for set-piece places whose spatial sequence is the story.

### Constrained

The generator may choose the map, but must satisfy authored relations such as “the cairn is beyond the
chasm,” “the exit remains reachable without combat,” or “exactly one apex guards the central site.”
This should be the default blueprint policy because it preserves world variation.

### Seeded with overrides

A frozen ordinary-generation seed supplies the world and a small override list adds or replaces exact
facts. Use this for the smallest interventions. If the override list starts describing most of the map,
promote the definition to constrained or fixed instead of accumulating patches.

## Non-negotiable safety

- A blueprint passes the same passability, content-host, collapse-runway and encounter-scaling gates as
  procedural worlds. “Authored” never means exempt.
- Required story content cannot share a failure-prone retention route with ordinary loot.
- Fog and minimap disclosure remain ordinary unless the story explicitly grants knowledge.
- Unknown runes and undiscovered facts never leak through title, preview, cost, accessibility or History.
- A unique consumed page and its campaign receipt commit atomically with departure.
- Failed generation consumes neither Essence nor the page and creates no story receipt.
- Relaunch cannot duplicate a unique grant, departure, reward or completion.

## Version evolution

Blueprint content may migrate additively while its meaning remains intact. If a generator or topology
change makes an old blueprint world dishonest to reconstruct, follow `save-compatibility-policy-current.md`:
advance the save format, identify incompatible saves before load, keep them exportable/deletable, and
retain only the newest gameplay implementation.

## First implementation slice, when Band 6 is reached

Implement one constrained blueprint with one unique World Page, one required site and one allowed
variation axis. Do not begin with a bespoke campaign chain. Acceptance requires generation receipts,
atomic consumption, relaunch, History, fog/minimap behavior, loss/failure handling and phone play.

Only after that vertical slice is accepted should fixed maps or branching story receipts be added.

