# Combat v2 — small ownership and naming review batch

**Status:** reversible playtest ownership implemented in `ce9b1af`; Aimee feel review remains open  
**Queue authority:** `Sources/Content/Data/playability-roadmap.json`; this review is not a consumer or
promotion prerequisite  
**Does not include:** tutorials, numerical tree tuning or glyph aesthetics

The graph topology and grant identities are stable. The 11 August consumer audit now has **19 of 20**
granted actions implementation-ready; Shatter remains the explicit DRQ-197 effect review, and
Distiller is a separate passive-economy review. The two identity choices below were promoted as
reversible playtest placeholders and implemented in `ce9b1af`, so they do not block those consumer
or palette slices. They are not final approval on Aimee's behalf and remain batched for later feel
review.

## Recommendation 1 — preserve Unbind as the Binder's attack; call retreat Withdraw

Use:

- **Unbind** — the Binder's signature direct damage technique;
- **Withdraw** — the ordinary confirmed retreat command available to the party;
- **Vanish** — the Shadow mastery that makes one confirmed Withdraw per expedition cost no
  Stability.

Retire legacy `rout` one-way as decode/migration input. Do not grant Vanish because an old save knew
Rout; Vanish requires its exact graph node. Logs, buttons and VoiceOver should say **Withdraw** for
retreat, while combat damage continues to say **Unbind**.

Why: Unbind is distinctive fiction—pulling at the seam holding a thing together—while “withdraw” is
a clear deliberate tactical verb that does not imply panic or magical unbinding. Preserving two
Unbind actions would be more confusing than preserving an internal migration alias.

## Recommendation 2 — explicit starting ownership, not four universal techniques

Use:

| Technique | Owner |
|---|---|
| Unbind | Binder innate |
| Mend | Quill innate |
| Sight | Binder temporarily, then exact analysis instrument |
| Read | Quill temporarily, then exact bestiary/analysis instrument |
| Ground | Ashe authored innate |
| Tree techniques | actor owning the exact stable granting node |
| Item actions | actor using the exact carried stack |

Every conscious actor still has ordinary Attack, eligible Items and Withdraw. Those are action
categories, not learned techniques.

The current universal grant creates five Mends and five Unbinds in a full party, makes generated
people inherit Binder/Quill identity, and conceals whether tree builds matter. Remove it at the
combat-v2 migration boundary; do not create another generic `companion` owner.

### Expedition without Mend

Leaving Quill at Home deliberately removes renewable cooldown healing until another explicit future
source exists. This is viable because:

- every expedition begins fully healed and Home restores the party;
- Lesser Salve, Salve and Greater Salve already provide carried healing;
- Quill is available from the start rather than a random late healer; and
- the player chooses whether another party role is worth losing renewable Mend.

The game must not silently compensate with a universal heal. Instead, the departure/Party preview
shows **No renewable healing in this party** when Quill and every future legitimate Mend source are
absent, plus the number of carried healing-item uses. This is decision information, not a warning
modal and not a tutorial.

If phone play shows that no-Mend parties are effectively invalid even with salves, solve that through
an explicit additional healer/node/item economy—not by restoring four universal identity actions.

## Acceptance for the playtest placeholder

1. Damage Unbind and retreat Withdraw have distinct buttons, logs, VoiceOver labels and stable
   transactions; Vanish modifies only Withdraw.
2. Binder, Quill, an ordinary named traveller, Ashe and a generated person expose different exact
   technique sets independent of Party/roster order.
3. A five-person party has only legitimate Unbind/Mend sources.
4. Quill-at-Home removes Mend and displays the honest departure fact; salves remain usable.
5. Sight/Read later transfer to exact instruments without duplicates or lost bestiary knowledge.
6. `rout`, `binder`/`companion` skill ownership and temporary universal grants are migration input,
   never new writable authority.
7. Respec changes graph techniques only and cannot move identity techniques between people.

## Later review questions

1. Approve **Unbind** for signature damage and **Withdraw** for retreat?
2. Approve Binder Unbind/Sight and Quill Mend/Read, including the deliberate possibility of a party
   without renewable Mend?
