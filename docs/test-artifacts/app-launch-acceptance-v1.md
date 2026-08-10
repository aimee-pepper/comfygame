# App launch acceptance — native v1

Recorded 2026-08-09 on the iPhone 17 / iOS 26.2 simulator, Debug build.

- Cold process launch: first meaningful SwiftUI frame 711.2 ms from the eager app-init epoch. Background preparation was 503.7 ms (load 388.0, reconciliation 0.3, committed persistence 115.4). The native launch storyboard covers the interval before that frame.
- Subsequent process launch: first meaningful frame 464.9 ms. Background preparation was 262.3 ms (load 187.4, reconciliation 0.1, persistence 74.9). The static and in-app surfaces use the same 248×340 frame, copy, and v0.2 paired-page mark, preventing a visual flash/jump.
- Delayed cold-launch test setup (`--debug-launch-delay`) held the real in-app loading state for eight seconds and then transitioned to the loaded game. Lossless visual evidence: `app-launch-loading-v1.png`.
- `PersistenceTests.testLaunchCoordinatorPublishesOnlyPreparedStateAndWarmReadyDoesNotFlash` verifies an already-ready scene never enters loading.
- `PersistenceTests.testLaunchTimeoutSerializesRetryWriters` verifies timeout disables retry until the existing writer finishes, then retry proceeds with maximum concurrent writers equal to one.
- `PersistenceTests.testLaunchCoordinatorShowsFailureAndTimeoutWithRetryPath` verifies eventual recovery after timeout and a recoverable failure with truthful detail. The failure surface exposes Try again only when safe and Copy diagnostics without constructing fallback game state.
- `PersistenceTests.testFirstFrameClockIncludesElapsedLaunchWork` verifies the eager epoch includes pre-frame delay.
- `PersistenceTests.testStaticLaunchMarkUsesTheAcceptedPairedPageGeometry` locks the storyboard to the v0.2 paired masses, extended spine, bottom bars, and asymmetric notches.
- The loading surface is one combined accessibility element labelled “Bookbinder. Opening the Atlas.”; its decorative mark is hidden. There is no motion or progress animation, so Reduce Motion requires no alternate behavior.

The Debug launch log intentionally repeats its evidence one second after readiness so simulator log capture does not miss very fast launches.
