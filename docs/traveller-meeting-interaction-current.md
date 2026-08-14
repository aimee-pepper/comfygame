# Traveller Meeting Interaction — Current

**Status:** implemented and pushed in native checkpoint `95d1778`. Ordered exchanges, explicit stable
IDs and terminal accepted/declined presentation are live without silently approving any draft prose
replacement. Isolde's candidate copy remains in `authored-text-audit-current.md` for Aimee's review.

## Defect that this contract corrected

`TravellerMeetingView` stores asked questions in a `Set<String>` and then redraws them by the
original authored `questions` array. Asking the third question and then the first therefore moves
the earlier exchange: the transcript is sorted back into content-file order instead of preserving
conversation order. The screen also prints `declined` beneath the buttons before the player declines,
while a successful recruit dismisses immediately and never lets the player read `accepted`.

Those are presentation/state defects, not evidence that a meeting should be a fixed transcript.

## Interaction contract

1. Show the opening once at the top of the local meeting transcript.
2. Each optional question is an independent choice. Selecting it appends exactly that question and
   its paired reply to the end of an ordered local transcript.
3. Previously appended entries never reorder, even if the underlying content array has another
   order. The selected choice disappears; unselected choices remain available.
4. The recruit offer and Leave decision may be chosen without exhausting optional questions.
5. Selecting the offer attempts the real recruit action. A blocked recruit leaves the decision
   surface active and presents the real reason. A successful recruit appends the authored `accepted`
   reply, freezes further choices and changes the final action to Continue.
6. Selecting Leave appends the authored `declined` reply, freezes further choices and changes the
   final action to Leave/Continue. Decline copy is never visible before that decision.
7. Continue dismisses only after the terminal reply has been shown. Recruitment state is committed
   before its reply; dismissal is not the source of truth.
8. Questions cost no world turn. Recruit/decline continue to follow their existing world-state
   semantics; no dialogue log is required in the campaign save for this first slice.

## Stable authored identity

Every exchange needs an explicit stable `id` independent of its player-facing `ask` text. Use a
traveller-scoped semantic ID such as `isolde.blank_board`, `isolde.teacher` and
`isolde.charcoal_hand`. Stable IDs support ordered state, tests, the authored-text atlas and copy
revision without changing review identity.

Content decoding may temporarily derive a diagnostic fallback ID for legacy bundled fixtures, but
production validation should require explicit unique IDs within each meeting. Duplicate IDs are a
catalogue error. The ID is development/content metadata and is not player-facing.

## Isolde copy boundary

Fix the interaction machinery using the currently shipped copy first. Aimee has challenged the
scene's writing, and Design has drafted three clearer independent replies in
`authored-text-audit-current.md`, but those exact replacements remain review drafts because Aimee
asked Design to discuss authored revisions rather than silently install them.

## Verification

1. Force three choices and select them in orders C→A→B and B→C; rendered transcript matches tap order.
2. Each question renders only its own paired reply exactly once.
3. Unselected questions never appear retroactively as spoken dialogue.
4. Decline copy is absent before Leave, visible after Leave, and readable before dismissal.
5. Accepted copy is absent before successful recruit, visible after success, and readable before
   dismissal; a capacity block shows neither accepted nor false success.
6. Reopening a declined traveller starts the local conversation over and does not mark them found.
7. VoiceOver reading order follows opening → ordered transcript → remaining questions → decision →
   terminal reply/Continue.
8. Atlas rows address every exchange by stable ID and can revise `ask`/`reply` without losing flags.
