# DEBUG bug reporting — current design

**Status:** DEBUG capture, form, durable visible local queue and immutable export installed through
`4d8da72`; direct transport destination/receipt remains unresolved
**Priority:** delivery/outbox state is the active post-save checkpoint. A real relay still requires
an approved external host; local reporting remains usable meanwhile
**Updated:** 11 Aug 2026

## Player outcome

Aimee can report a problem at the moment she sees it without leaving the game, reconstructing build
details or deciding whether it is important. A persistent floating DEBUG button captures the current
screen, opens a concise report form and places a durable report into an **Untriaged** queue. Game
Design and Engineering—not Aimee—assign priority and route the work.

## Interaction

1. A small movable **Report Bug** control floats above ordinary game content in DEBUG builds only.
   It respects safe areas, avoids system gestures and can be dragged to another screen edge; its
   position persists locally. It must not cover a required 44-point action after repositioning.
2. Tapping freezes a screenshot of the game **before** the report sheet obscures it.
3. A sheet shows the screenshot thumbnail, a required “What happened?” text box, an optional “What
   did you expect?” box, and automatic context disclosure.
4. **Submit** writes the report and screenshot atomically to a durable local outbox, immediately
   confirms **Saved to bug queue**, and never blocks returning to play on network availability.
5. Reports show `Unsent`, `Sending`, `Submitted` or `Needs attention`. Retry is explicit and
   idempotent; the same report ID can never create two queue entries.

No severity picker appears in Aimee's form. Optional lightweight tags such as **crash**, **layout**,
**text**, **balance** and **other** may help retrieval, but omission is valid and they do not imply
priority.

## Captured context

Every report receives a stable `BugReportID` and captures:

- UTC/local timestamp, app version, build/commit ID and report-schema version;
- current top-level screen and safe route identifier;
- screenshot dimensions/scale and an attached PNG;
- save schema version, campaign ID hash, expedition/run ID when present and active DEBUG tuning;
- current world seed/book ID, position, Stability and outcome/encounter IDs when relevant;
- recent bounded semantic action trail (for example the last 20 game actions), not raw touch logs;
- user text and transport state/remote reference.

Do not include player name, Apple account, filesystem paths, unrestricted save contents or secrets.
The sheet lists the captured categories and lets Aimee remove the screenshot before submission. A
separate **Attach diagnostic save** action, if ever added, requires explicit consent each time and
must redact/validate before transport.

## Screenshot boundaries

- Capture only the app's own active scene; never invoke installed-app or whole-device screen
  recording.
- Secure/system surfaces, keyboards and notification content outside the app are excluded.
- If capture fails, the text report remains submittable and records the failure honestly.
- The floating button and transient debug overlays may be hidden for the captured frame, but the
  underlying bug state must not be mutated or rerendered with different data.

## Queue and transport boundary

The app always owns a local durable outbox. The current transport direction is a small HTTPS bug-inbox
relay configured only for DEBUG builds. The phone sends the immutable report package to the relay;
the relay owns credentials for the shared triage destination and returns a stable remote reference.
The app never talks directly to GitHub or another issue tracker with a bundled personal token.

Until the relay is configured and an end-to-end receipt is proven, retain a one-tap system Share/
export fallback clearly labelled **Saved on this phone — not yet shared**. This is recovery, not the
definition of successful submission.

Do not embed a long-lived write token in the app binary. Transport is injected/configured for DEBUG,
uses idempotency key `BugReportID`, and failure never deletes the local package. The queue's triage
fields—priority, owner, status, duplicate-of and disposition—are downstream metadata; Aimee's source
report remains immutable.

### Relay contract — reversible implementation decision

- `POST /v1/bug-reports` over HTTPS only;
- request is `multipart/form-data`: one UTF-8 JSON report plus optional PNG screenshot;
- `Idempotency-Key` is the stable `BugReportID`; replay returns the original receipt and never creates
  a second queue entry;
- response contains schema version, stable remote reference and received timestamp;
- `2xx` with a valid receipt is the only transition to Submitted;
- timeout, offline state, malformed response, `4xx` or `5xx` preserves the local report and records a
  retryable/attention error without altering its player-authored text;
- endpoint and installation credential are injected through an untracked Debug configuration and
  stored in the device Keychain after provisioning. Neither appears in source, screenshots, report
  context or exported packages;
- relay validates body size, MIME type and report schema, strips unexpected fields, rate-limits the
  installation and owns all downstream service credentials;
- first downstream adapter may create a repository issue or inbox record, but the phone protocol does
  not change when the team changes queue providers.

This decision is reversible at the adapter boundary. It is specific enough for Engineering to finish
phone behavior and tests without choosing the team's permanent issue tracker prematurely. Deploying
or purchasing the relay is an external-state action and still requires Aimee's approval when an exact
host/provider is proposed.

### Scheduling decision — 10 Aug 2026

Do not delay capture/outbox work while debating a perfect service. Implement the screenshot, form,
context package, durable local Untriaged queue and explicit transport adapter immediately after the
resource-visual checkpoint. The adapter must support a test transport and one configured real
destination without changing the report schema. The phone checkpoint is not called “direct submit”
until Design/Engineering can actually receive the report; a local-only build must say **Saved on this
phone**. Selecting/configuring that real endpoint is part of this maximum-priority checkpoint, not a
reason to postpone the rest of it.

### Installed local checkpoint — 10 Aug 2026

`aa0d3b1` provides the floating DEBUG button, pre-form app screenshot, required text, optional
expected-result text/tag/screenshot removal, atomic local package/outbox, duplicate-ID rejection,
interrupted-send recovery and an honest Share fallback. The complete product suite passed 892/892,
the Release build excluded the reporter, and the DEBUG build was installed/launched on Aimee's phone.
This is useful now but is not yet the requested direct queue submission: no relay host or credential
has been approved/configured, so the UI correctly says **Saved on this phone — not yet shared**.

### Native gap audit after `4d8da72` — 11 Aug 2026

The installed slice meets the immediate capture/local-loss boundary. It does **not** yet satisfy the
complete reporter contract, and the next checkpoint should remain narrow:

1. **Real receipt:** no live transport is configured; Share is manual recovery, not direct submission.
2. **Closed — durable queue/export:** Aimee can browse saved packages and share one immutable,
   Unicode-safe `.bookbinderbug` export; report-specific atomic staging prevents overlapping saves.
3. **Transport transitions:** without a configured relay the local saver cannot durably advance
   `sending → submitted/needsAttention` against a receipt.
4. **Context completeness:** native capture records the roadmap checkpoint, app build, broad screen,
   save schema, run/seed/position, Stability, outcome, mutation count and one last action. It still
   lacks the promised precise route, campaign/slot hash, active tuning, encounter ID and bounded
   semantic action trail.

Do not expand this completion pass into general telemetry, save attachment or a full issue-tracker
client. Close the real receipt, honest outbox/retry and promised safe context; downstream triage stays
outside the phone.

## Triage contract

New reports enter **Untriaged**. At regular check-ins, Game Design and Engineering classify:

- **Blocker:** cannot continue the core test loop or risks save/property loss;
- **High:** major ordinary-loop correctness/readability issue with no reasonable workaround;
- **Medium:** meaningful defect or balance problem that does not stop the current checkpoint;
- **Low:** polish, rare edge or deferred breadth.

Priority may change with reproduction evidence. The Roadmap shows counts by triage state, not the
full report prose or screenshot. Duplicate reports retain their own observations and link to one
canonical issue.

## Acceptance

1. The control is reachable on every ordinary game screen, movable and absent from Release builds.
2. Screenshot represents the pre-sheet state and excludes the reporter control.
3. Required text, screenshot removal and Cancel behave correctly with keyboard/large text/VoiceOver.
4. Submit is atomic; force-quit at every boundary loses neither a confirmed report nor creates a
   duplicate.
5. Offline submission remains safely queued; retry with the same ID creates one remote entry.
6. Automatic context matches the visible build/world/screen and records missing context as absent,
   never guessed.
7. A received report can be ingested into the shared triage queue and linked back to its source ID.
