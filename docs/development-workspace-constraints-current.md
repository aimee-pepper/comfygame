# Development workspace constraints — current

Status: current team operating constraint, set by Aimee on 10 August 2026.

## Simulator window

Aimee keeps the iPhone Simulator in a deliberate position so she can see it alongside her other
windows. Design, Engineering and Asset work must not close, reopen, boot, shut down, replace, move,
or otherwise alter Simulator suites or Simulator window state.

- Reuse an already-running simulator as-is for non-lifecycle commands only.
- Do not run `simctl boot`, `bootstatus` when it may boot a device, `shutdown`, or GUI launch/open
  commands during routine QA.
- If no suitable simulator is already running, pause simulator-dependent visual QA and report that
  fact at the next check-in rather than launching one.
- Installing or launching the game on Aimee's physical phone remains a separate explicit checkpoint
  and must not interrupt an active playtest expedition.

