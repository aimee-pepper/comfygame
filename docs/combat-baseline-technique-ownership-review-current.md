# Combat baseline technique ownership — review packet

**Status:** reversible playtest ownership implemented in `ce9b1af`; Aimee's later feel review remains
open, but this is no longer an implementation blocker.
**Queue authority:** `Sources/Content/Data/playability-roadmap.json`. This review does not redirect
launch, encounter-scaling or combat-consumer work.

## Audit finding

The live catalogue's old two-person `binder` / `companion` owners were replaced by one temporary
baseline set. `CombatRules.skills(for:)` now gives every human actor all four of:

- Unbind — direct Binder-style seam damage;
- Mend — a twelve-point heal on a three-round cooldown;
- Sight — reveal ordinary combat information;
- Read — record/inspect a creature;

This made the skills reachable while the tree and instrument systems were incomplete, but it is not
a viable final roster rule. A five-person party receives five identical heals and five copies of the
Binder's signature action; generated and named people begin with knowledge practices that their
identity never established. The four universal actions also obscure whether a new tree route has
actually differentiated somebody.

## Recommendation

Restore the original complementary starting-pair ownership and make later ownership explicit:

| Technique | Current/future owner | Reason |
|---|---|---|
| **Unbind** | Binder innate | Signature Binder action; not a generic human technique |
| **Mend** | Quill innate | Preserves the founder's practical support role without making every recruit a healer |
| **Sight** | Binder temporarily; later the exact analysis instrument holder/user | Knowledge action, not a combat-tree node |
| **Read** | Quill temporarily; later the exact bestiary/analysis instrument holder/user | Knowledge action; Kestrel gambits may call it only when the actor can perform it |
| **Ground** | Ashe authored starting technique | Existing settled identity; unchanged |
| graph techniques | exact actor who owns their granting stable node | Never inferred from Binder/companion or Party slot |
| item actions | actor with the exact carried usable stack | Items do not become innate techniques |

Every conscious actor retains ordinary **Attack**, Items when available, and the ordinary retreat
command. Those are action categories, not entries in the learned-technique catalogue.

Quill need not remain in every expedition. Leaving Quill at Base deliberately trades away renewable
Mend access unless another authored source or consumable covers healing. That makes party composition
meaningful. It must be tested rather than silently compensated by giving every person Mend.

Sight and Read remain temporary identity-owned actions only until their real instrument consumer is
playable. At that checkpoint, access derives from the exact instrument/state, and the temporary
grants migrate away. “Instrument” cannot mean that every party member receives the action because
somebody at Base unlocked a research node.

## Generated and named arrivals

- A named traveller receives authored starting exceptions only when a current identity document
  says so (currently Ashe/Ground).
- A generated person receives their persisted legal combat-tree arrival plan and no hidden baseline
  copy of Binder, Quill or authored-traveller techniques.
- A calling lean grants exactly its stable node/effect; it cannot use generic `companion` ownership
  to add skills.
- Full respec changes graph ownership but never removes Binder/Quill/authored identity techniques or
  grants them to another person.

## Implemented acceptance and remaining review

`CombatActionOwnershipRules` is now the live identity/graph resolver. The obsolete universal baseline
grant is gone: Binder receives Unbind/Sight, roster-stable Quill receives Mend/Read, Ashe receives
Ground, and other named/generated people inherit none of those identities. `CombatRules.skills`
consumes that resolver, while `SkillDef.owner` remains legacy content input. Focused ownership tests
cover Binder, Quill, ordinary named people, generated nil-traveller people, Ashe and graph grants.

The later Aimee review is about feel and naming—especially whether a Quill-free expedition with
carried healing is a satisfying trade—not whether production may revert to five universal Mends or
Unbinds. If the playtest fails, add an explicit legitimate healing source; never restore identity
borrowing.

Maintained acceptance:

1. Binder, Quill, a named traveller, Ashe and a generated person each expose the exact expected
   technique set independent of roster/Party order.
2. A five-person party does not gain five Mends or five Unbinds unless five legitimate future sources
   explicitly provide them.
3. Quill-at-Base removes Mend from the expedition palette while healing items remain usable.
4. Kestrel's `unrecorded species → Read` gambit is ineligible when Kestrel cannot access Read; it does
   not borrow Quill's action across the Party.
5. Instrument acquisition moves Sight/Read access through one explicit migration without duplicate
   actions or lost bestiary state.
6. Respec, save/load and generated-person arrival preserve identity techniques separately from graph
   techniques.
7. Legacy `owner: binder/companion` fields become decode/content-migration input only; runtime asks
   stable actor identity, authored grants, graph ownership and equipment capability.

## Later feel-review question

Approve the Binder-Unbind/Sight and Quill-Mend/Read split, including the meaningful possibility of an
expedition without renewable Mend, or choose a different explicit source for general healing before
removing the universal temporary grant.
