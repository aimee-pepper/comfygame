# App Launch and Loading — Current

**Status:** implementation-ready launch-quality boundary; visual proof may refine art without
changing behavior. Prompted by physical-device playtest reporting a prolonged black screen.

## Goal

The player sees a meaningful Bookbinder frame immediately after launching the app. Avoidable startup
work is removed; unavoidable initialization has a calm, honest loading state. A loading screen is
not permission for startup time to grow unnoticed.

## Two surfaces, one composition

1. **System launch surface:** static and available before Swift/game initialization. It must never be
   black by accident and cannot depend on generated world data, save decoding or animation.
2. **In-app loading surface:** pixel/layout-aligned with the static surface so handoff does not flash.
   It remains only while real initialization is incomplete and can present error/recovery UI if that
   work fails.

Visual direction: the Bookbinder name within the established page/book-edge/Atlas-frame language,
plus restrained **Opening the Atlas…** copy on the in-app state. No canonical Binder face, random
world, undiscovered site, apex, progress fiction or animated flourish is required. It must not imply
that a new world is generated on every app launch.

## Engineering requirements

- Measure cold and warm launch separately in DEBUG on the target simulator and, when permissions
  permit, physical device. Record process start, first system surface, first in-app frame, save load
  completion and first interactive screen.
- Move avoidable parsing/generation/regression work off the launch-critical main-thread path. Do not
  delay first frame for AssetLab, debug corpus scanning or world generation that can happen later.
- Use a real state machine: `launching → loadingSave → ready` with `failed(reason)`. A migrated save
  may add an honest migration step internally without inventing a player-facing percentage.
- Show a percentage/progress bar only if every initialization unit is bounded and reports real
  progress. Otherwise use static copy or a subtle system activity indicator after the first frame.
- If loading fails or exceeds the defined watchdog, show a recoverable error with Retry and a safe
  route to diagnostics. Never remain indefinitely on the decorative surface.
- Warm launches that are immediately ready transition directly without a conspicuous loader flash.
- VoiceOver announces “Opening the Atlas” once and then announces Ready or the actionable error;
  decorative imagery is hidden. Reduce Motion disables optional transition animation.

## Acceptance gate

1. Cold launch never presents an unexplained black frame between the OS launch surface and app UI.
2. Before/after timing evidence identifies the actual bottleneck and shows first meaningful frame;
   optimization and visual coverage are reported separately.
3. Static and in-app surfaces align at representative compact/large portrait safe areas, light/dark
   appearance and grayscale.
4. Empty/new, ordinary existing, large campaign and tolerant legacy saves all reach the correct
   destination; malformed/failing initialization reaches Retry rather than hanging.
5. No world generation, hidden identity or save-dependent art is required to render the loader.
6. Launch tests and the full suite are green; a device/simulator video or ordered screenshot pair
   proves the black interval is gone.

## Implementation review gate — 9 Aug

The first native draft establishes the right async/state-machine direction but is not accepted until
these correctness issues close:

- The process/launch timestamp must be eagerly captured before the first frame. A lazy static first
  read by the frame callback produces a near-zero self-measurement rather than launch latency.
- Timeout and Retry cannot create overlapping detached preparations or save-file writers. A stale
  timed-out attempt must not write after a replacement attempt starts; if synchronous I/O cannot be
  interrupted, Retry waits for or serializes behind that worker.
- The static storyboard and in-app binding mark/frame must actually match. The first draft gives the
  SwiftUI mark a bottom bar/serif treatment absent from the storyboard, causing a visible handoff.
- The accepted v0.2 mark is not a generic outlined rectangle: `AssetLab/src/launch-kit.js` owns
  paired page masses, nested edge/ink/page layers, an extended central spine and asymmetric torn
  notches. Translate one shared relative token set into both storyboard constraints and SwiftUI;
  simplified-but-different approximations do not satisfy the no-jump gate.
- Failure recovery includes a safe diagnostics/details route as well as Retry, without constructing
  a fake fallback store or mutating the save.

Acceptance tests deliberately delay first frame to prove the timestamp includes the delay, and force
timeout→retry around a controlled writer to prove maximum concurrent save writers remains one.

### Design review disposition — 9 Aug

Direct inspection of the native evidence and both implementations confirms that the static
storyboard and SwiftUI loading surface now share the accepted v0.2 paired-page mark: the same 74×58
page masses, nested edge/ink/page layers, central spine, bottom bars and asymmetric notches. The
visual direction is accepted. Final launch acceptance still requires the cold/warm, delayed,
timeout/eventual-ready, recoverable-failure and VoiceOver evidence matrix in the acceptance gate
above; this disposition does not waive those behavioral proofs.

### Final native v1 acceptance — 9 Aug

**Accepted.** `docs/test-artifacts/app-launch-acceptance-v1.md` now records cold/warm phase timings,
the delayed real-loading transition, warm-ready suppression, serialized timeout/retry writers,
recoverable failure with diagnostics, eager first-frame timing and structural storyboard parity.
`app-launch-transition-v1.mp4` is the ordered system-static → matching in-app loading → Home capture;
`app-launch-loading-v1.png` is the lossless in-app frame. Ready and actionable failure now emit
one-shot VoiceOver announcements, while an immediately ready warm scene stays quiet. The focused
coordinator tests and full suite pass at 816/0, and commits `f541067` plus `b6e7bc8` are pushed.

This closes the launch-hang defect. Future launch optimization uses the recorded phase timings and
must not remove the recovery/save-serialization boundary merely to lower a headline number.

### Real progress bar — 11 Aug

The opening frame now reserves one identical 192×4 progress track in the static storyboard and the
in-app surface. The in-app fill advances only at four bounded launch milestones emitted by the real
preparation path: reading the campaign, reconciling the catalogue, committing the normalized save,
and ready. It is phase completion rather than a time estimate, exposes the current phase to
VoiceOver, and introduces no invented percentage or background work. Warm-ready scenes still skip
the loader entirely; timeout and failure retain the existing serialized recovery behavior.
