# Combat tree v2 consumer plan — current

**Status:** implementation-enabling sequence; semantics remain owned by
`combat-node-viability-current.md`.
**Purpose:** replace the legacy catalogue→unused-loadout illusion with a small number of shared,
observable rules primitives. This is not a license to activate a partially functioning v2 tree.

## Current-state finding

The legacy tree parser writes fields for most passives, but current production rules directly read
only the three field-concealment values (`encounterChance`, `sightedAtRange`,
`partySightedAtRange`) plus granted skills through separate paths. A field differing in a loadout
test is therefore not evidence that a node affects play.

The v2 runtime may land behind a DEBUG/dual-schema gate in the following slices. Player ownership,
purchase and migration switch only after all 72 stable IDs have a scenario consumer and the full
release gate in `combat-node-viability-current.md` passes.

## Shared consumer slices

### 1. Actor derivation and order

Build one `CombatDerivedStats` path used by encounter creation, preview and actual resolution:

- Heavy Hand, Keen Eye;
- Quick Step, Light Frame, Light Touch and Momentum;
- Thick Hide, Iron Skin, Bulwark and Shieldwall;
- Footwork, Insulation, Attunement and Immovable.

Formation bonuses aggregate strongest-once from stable party identity. Initiative changes after
entry use the same stable reorder operation and cannot interrupt the current action.

### 2. Direct-hit context

Every weapon/technique strike creates one typed context carrying actor, target, direct/carried/status
provenance, damage/delivery kind, rank held/moved, covering/armour before hit, concealment transition,
personal-turn receipt and retaliation permission. It owns:

- Follow Through, Bracing Stance, Weak Point, Steady Hand and Exploit;
- Breaking Blow, Killing Stroke and Feint;
- Tainted Edge, Sparkhand, Opportunist and Emanant;
- First Strike's `allowsRetaliation = false` exception.

Preview calls the same pure calculation with RNG ranges rather than claiming a critical roll.

### 3. Non-recursive consequence queue

Resolve direct hit first, then enqueue secondary consequences with explicit provenance. Carried or
copied consequences cannot enqueue themselves:

- Stagger, Flurry and Cascade;
- Second Wind and Rally;
- Virulence, Corrode, Blight and Conduction;
- Anatomy at the one expedition-level butchery receipt rather than per hit.

Stable foe/party order breaks documented ties. Each queue event identifies its contributing node in
DEBUG telemetry.

### 4. Mitigation, targeting and survival

Use one incoming-harm pipeline: legal target → redirection → miss/avoidance → matchup/Ward → armour
→ reduction → minimum damage → affliction payload → survival receipt. It owns:

- Constitution, Endurance, Unyielding and Ghost;
- Cover and Guardian;
- Brace, Ward, Sidestep, Draw Off and Interpose;
- Conceal, Snuff and Quench.

Area/environment/status events declare which stages they bypass. Redirection never recurses and a
miss never lands an affliction.

### 5. Technique and personal-turn receipts

Techniques remain explicit stable IDs and typed parameters; graph role never implies an action.
This slice owns:

- Overbear, Shatter, Pry and Finish;
- Quicken, First Strike and Blur;
- Fall Back;
- Envenom, Flense and Emanation Strike.

One shared action-expansion receipt prevents Quicken/Blur chaining. One opening-attack receipt
prevents repeated Ambush-style attacks. First Strike spends an ordinary action. Owed/skipped turns,
once-per-encounter use, selections and cooldowns survive relaunch.

### 6. Pre-contact field and encounter opening

Freeze the pre-action disclosure/opening authority specified in `combat-node-viability-current.md`.
This slice owns:

- Slippery and Watchful;
- Ambush and Unseen;
- Quiet Step, Low Profile and Shadowed;
- Vanish.

The existing three field-concealment reads migrate into this typed resolver rather than remaining
sign-only checks. Apex/scripted exceptions are explicit and never inferred from creature names.

### 7. Economy and external yield

Rules-owned previews and atomic transactions consume:

- Apothecary's Hand when the trained actor uses a beneficial item;
- Distiller when preparing a coating for that actor;
- Anatomy at butchery payout;
- Vanish at expedition exit.

These effects read stable expedition participants/actor identity, not whichever member currently
occupies a legacy roster index. Distiller changes positive world-resource quantities only; it never
discounts Essence or duplicates an output.

### 8. Typed permanent choices and legacy identity

Insulation and Emanant purchases atomically store Heat/Caustic/Light. Cancel spends no point. Legacy
ownership defaults once to Heat and is surfaced in DEBUG. Migrate `steady`→`quench` and
`elemental_strike`→`emanation_strike` across cooldowns, gambits and saved preferences; old IDs are
decode-only and never appear as duplicate actions.

## Slice gates

Each slice must prove:

1. at least one positive and one counterfactual scenario per included stable node;
2. preview and committed outcome use the same rules path;
3. five-member strongest-once aggregation and stable reorder behavior where applicable;
4. mid-action or mid-encounter save/relaunch for any new persisted receipt;
5. node contribution in DEBUG comparison without hidden-information leakage; and
6. no test whose only assertion is that a loadout field changed.

After all slices pass, run the full 72-node matrix, nine pure/nine hybrid observable-route fixtures,
legacy migration, generated-arrival plans, respec and native graph/device acceptance before changing
the default ownership schema.
