# App Launch and Loading — Current

**Status:** **failed physical-device acceptance on 11 Aug**. The production coordinator and progress
track exist in source, but Aimee's newly installed phone build still presents a long black wait and
no perceptible loading bar. Prior direct-store and source-only acceptances are historical, not proof
of the current installed experience.

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

**Canonical visual reference:** `AssetLab/artifacts/app-launch-proof-v0.2.png`, SHA-256
`360f02713f0bba9e84ddcf4ba37c35a22594738dbfd6f6732fa2b9da84b1e4d9`. It owns the fixed internal
248×340 composition and v0.2 mark. Native placement remains safe-area centering; AssetLab's fixture
absolute `frameY` is not a phone-placement constant.

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
3. Static and in-app surfaces align on Aimee's ordinary phone in its current appearance. Broader
   appearance/device/accessibility matrices wait until the application-wide UI direction is stable.
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

### Campaign-slot production-path correction — 11 Aug

The paragraph above described `AppLaunchCoordinator`, but production now enters through
`CampaignAppCoordinator` and `CampaignAppRootView`. That root rendered `LaunchSurface()` at its
default zero progress and called preparation without forwarding progress. The visual bar therefore
existed but was not functional in the app Aimee actually launched. The earlier “accepted” result is
historical evidence for the direct-store path, not proof of the later save-slot integration.

Current correction requirements are:

- one monotonic, generation-guarded production phase across legacy adoption, campaign inspection,
  writer acquisition, save load, reconciliation, necessary commit and ready;
- real progress descriptions forwarded to the visible bar and VoiceOver, never a timer;
- zero launch writes for an already normalized campaign, while genuine reconciliation commits once;
- DEBUG timings separated into shelf adoption/inspection and campaign load/reconcile/persist;
- stale callbacks, retry and slot switching cannot regress or cross-wire visible progress; and
- physical-device timing/transition evidence from the exact save-slot build before this defect is
  called accepted again.

The source patch later reached the installed line, but Aimee's 11 Aug physical retest still saw a
long black wait and no loading bar. Therefore neither the presence of `LaunchSurface` in source nor
coordinator tests close the defect. Diagnosis must identify whether the missing interval occurs in
the OS storyboard handoff, before SwiftUI's first frame, during campaign-shelf inspection or while
opening the selected campaign. The exact installed commit and phase timings accompany the next
acceptance evidence. A loading screen remains a truthful progress surface, not a substitute for
removing avoidable delay.

### Fixed first-frame composition — 11 Aug

The system launch frame, zero-progress SwiftUI frame and every advancing-progress frame use the same
248×340 composition with the same permanently reserved track. Progress changes only the fill width
inside that track; it may never insert a system control whose intrinsic size remeasures or recentres
the artwork. A centered first frame followed by a shifted title/mark when progress appears is a
launch regression even when the bar itself is functional. Current acceptance compares the artwork,
title, subtitle, track and frame coordinates at zero and nonzero progress on Aimee's ordinary phone,
then verifies the system→SwiftUI handoff on that exact installed build. Large Text and the wider
layout matrix are deferred with the broader UI redesign.

### Physical regression reopened — 11 Aug

Aimee installed the current build and again observed a long black **main-app startup** interval with
no visible loading bar. After she selects a save, that separate loader does function and advance, but
its splash composition is askew rather than aligned with the intended/static frame. This explicitly
reopens `launch-handoff` ahead of the next Combat Tree v2 consumer once the already-green graph
checkpoint is isolated. Preserve the working selected-save progress semantics; correct the uncovered
process-launch interval and the shared surface geometry rather than rebuilding the state machine.

The next checkpoint must prove, on the exact installed build:

1. what commit and bundle was actually launched;
2. timestamped OS static surface, first SwiftUI frame, shelf-ready and selected-campaign-ready events;
3. no black or unowned interval between process launch and the branded surface;
4. the working selected-save determinate progress remains honest and clearly perceptible;
5. static, initial SwiftUI and selected-save frames use the same aligned composition; and
6. the slowest measured phase has been reduced where safe, or truthfully remains covered and named.

Current diagnosis also found that installed bundle version `1` does not embed a Git/build identity,
so a manually installed phone build cannot be reconstructed honestly from the bundle afterward.
The next install records its clean source commit at install time and uses an explicit bumped bundle
version to invalidate this acceptance boundary. A generated signed-provenance experiment repeatedly
blocked the build and was cut before process infrastructure displaced the player-visible repair; it
returns with the later roadmap/build-metadata authority work. This observation does not by itself
prove that caching caused the black interval.

Read-only compiled-product inspection then proved `UILaunchStoryboardName=LaunchScreen` and the
compiled storyboard nibs are present. Fresh-bundle Simulator evidence renders that storyboard, then
one black transition frame, then the SwiftUI surface/chooser. Available captures place both static
and SwiftUI page frames on the safe-area midpoint, so the earlier full-frame-versus-safe-area-offset
hypothesis is rejected; do not patch a guessed vertical offset. Unique build identity/cache
invalidation is necessary for trustworthy phone evidence and may clear an obsolete launch snapshot,
but the observed fresh-bundle black transition remains a defect until eliminated or proven to be a
capture artifact.

### Instrumented acceptance checkpoint — 11 Aug

The next Debug build advances the sole XcodeGen-owned numeric bundle version beyond the obsolete
`1`. Its clean Git commit and build number are recorded externally with the install. Production
campaign loading logs the first SwiftUI launch-surface frame, every monotonic campaign phase, shelf
adoption/inspection, and selected-save load/reconcile/persist timings. The fixed canonical 248×340
composition and working selected-save progress semantics are unchanged. Generated signed provenance
is deliberately deferred to the later dynamic-authority audit.

This checkpoint does **not** close the fresh-bundle black transition. Source and compiled-product
evidence did not identify a supported host/window change that would keep UIKit's storyboard visible
after the OS relinquishes it, and a dark `systemBackground` would merely rename the same black gap.
Focused/full XCTest execution and exact cold-launch/save-open visual evidence remain blocked on the
failed Simulator/CoreDevice services, then on a clean committed install. Acceptance still requires
proving that the branded storyboard hands directly to the branded SwiftUI surface with no uncovered
frame.

### Perceptible initial handoff — 11 Aug

Build 232 removed the long uncovered black wait on Aimee's phone, but the initial branded surface
became only a momentary flicker because an already-normalized campaign shelf inspected almost
instantly. The production root now keeps only the **initial app-launch** surface visible for at least
one second from coordinator start. Real adoption/inspection still runs immediately and continues to
drive the honest progress state; the minimum does not delay selected-save opening, warm-ready scenes,
retry semantics or any save write. This is presentation dwell, not simulated work or a fake timer.
