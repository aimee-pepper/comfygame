# Defeat summary — actual cause

5 September 2026. Bounded implementation contract for Aimee's request, relayed by PM. Changes reporting only: no damage, turn order, survival, revival, defeat trigger, haul or exit-precedence changes.

## Current gap and intended result

`GameActions+Combat.swift` sends generic “You were carried home.” through synchronous, asynchronous and older combat conclusion paths. Capture the cause before `CombatRules.conclude` clears encounter state. `WorldRules` already has some cause-specific copy but picks it from the presence of events in the turn; that can misattribute defeat when multiple damage events occur. It must use the event that actually reduced health to zero.

The current rule is Binder incapacitation ends the excursion; companions can fall while the Binder continues. It is not necessary for the entire party to fall. Everyone remains revivable. Use **“Defeated by …”**, rather than declaring permanent death, and retain **“You were carried home.”** as the outcome line.

## Player copy

| Actual cause ending the excursion | Cause line |
| --- | --- |
| Fatal enemy attack with a name already disclosed to this player | Defeated by {known creature name}. |
| Fatal enemy attack without a disclosable name | Defeated by a creature. |
| Poison/toxin damage-over-time tick | Defeated by poison. |
| Burn damage-over-time tick | Defeated by burning. |
| Bleed damage-over-time tick | Defeated by bleeding. |
| Known damage-over-time event with no supported readable kind | Defeated by ongoing damage. |
| Implemented toxic-air damage event | Overcome by toxic air. |
| Dangerous-flora contact, including the current combined contact/entry-poison damage | Overcome by dangerous growth. |
| Explicit enemy retaliation event, disclosed name | Defeated by {known creature name}’s retaliation. |
| Retaliation without a disclosable source | Defeated by retaliation. |
| Unavailable or legacy cause | Cause of defeat unknown. |

The outcome line is “You were carried home.” Keep the existing return/retained-haul details. If there is room for only one sentence, combine the cause line and outcome without changing their meaning. Never name a hidden species, undiscovered identity, raw ID, guessed source or an enemy merely because it remains on screen. Use the existing safe disclosed display name; freeze it with the summary so later knowledge does not retroactively rewrite what was known then.

A fatal poison tick is poison even if an enemy originally applied it. Do not label it a final enemy blow. Source detail is optional only when the causal record and existing disclosure already support it. Dazzle cannot become a damage cause simply because it was active.

An individual companion reaching zero may receive “{companion} was incapacitated by {cause}.” in the existing combat feedback, using the same safe cause rules. It must not produce the Binder's return summary or imply party-wide defeat. Do not add a new permanent casualty history or companion-death mechanic.

## Exact event semantics

Record a cause only when that resolved damage event changes the relevant victim from HP > 0 to HP = 0 **after** mitigation, survival passives and any existing prevention. A hit that leaves 1 HP is not fatal. Zero-damage events and later ticks on an already downed victim cannot overwrite the cause. If an existing mechanic genuinely revives the victim during the same ongoing run, clear the previous incapacitation cause before a later independent defeat can record a new one.

Attach the minimal cause information at actual damage resolution: victim, event kind, supported status/environment subtype and safe source identity/name when available. Reuse existing event identities/ordering where available; no general combat event-log rewrite. Combat `hurt` currently serves retaliation, affliction ticks, normal enemy damage and cover allocations: pass explicit cause from those call sites rather than inferring it from an English log line. Intercepted/cover damage keeps the real attack source and actual harmed victim; never blame the protected ally.

For World damage, capture at the HP mutation for toxic-air hazard, ongoing dangerous-flora poison and dangerous-flora contact. The contact event currently aggregates contact and poison-entry damage; use the honest combined “dangerous growth” cause unless Engineering's existing resolution provides a distinct fatal subevent. Do not split damage or change order merely to produce more specific copy. “Any poison event occurred this turn” is not causal evidence.

In the current world turn, air damage can precede poison. If air crosses zero, a later poison event at zero must not relabel the result as poison. If air leaves positive HP and poison crosses zero, record poison. Multiple combat status ticks follow their actual existing order: the first health-crossing tick owns the cause.

Keep existing world-floor collapse, voluntary Return, Waystone, fleeing and victory resolution behavior. A non-health forced exit retains its own outcome/cause and must not become “killed by” the last enemy or last injury. Do not alter the current victory/defeat or collapse precedence while improving attribution.

Persist the cause with the existing durable return/defeat summary in the same candidate transaction as final health, combat conclusion and partial-haul exit. Success is published after save. Cover synchronous/async and any still-reachable legacy exit path. Reopening shows the same outcome and cause without replaying damage, refreshing enemy disclosure, charging currency or reducing haul again. Older summaries without a cause use the unknown fallback; do not backfill by guessing from remaining enemies or current statuses.

## Bounded acceptance cases for Engineering

- Known enemy hit takes Binder 2→0: that enemy is named; unknown identity uses generic creature. Same creature causing nonfatal damage does not become a later poison tick's cause.
- Enemy applies Poison, later tick takes Binder 1→0: poison cause, even if that enemy has died. Relauch retains it.
- Burn and Poison tick in sequence: whichever first crosses positive HP to zero owns the result; later tick cannot overwrite it.
- World air damage takes 1→0 then a flora-poison event occurs: toxic-air cause; reverse fatality condition yields poison.
- Combined harmful-plant contact crosses zero: dangerous growth, without inventing whether thorns or entry toxin supplied the last point.
- Survival passive prevents zero, or Dazzle is present during a fatal attack: no false status death; use the eventual actual fatal event.
- Companion falls while Binder remains standing: individual incapacitation feedback only; Binder falling can end the run while companions remain standing.
- Cover/retaliation uses real source and victim; protected ally is not blamed. Floor collapse/Return remains its own outcome.
- Missing old cause, stale quote, save failure and cold relaunch: honest fallback or unchanged durable summary; no duplicated exit or haul loss.

Design checked only the affected source semantics. Engineering owns implementation and its normal focused test/play route. This contract is not delivered behavior and requests no second phone verification by Design.
