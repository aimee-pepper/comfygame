# Diary collection notification and Read now — bounded correction

8 September2026. **Direct Aimee instruction, not delivered:** do not say “Diary page read” on collection; say collected and offer Read now before the notification fades. This supersedes the .readPage copy row in notification-and-chronology-audit-2026-09-07.md. It is a notification/reader route correction, not a diary/reward redesign.

## Current facts and exact identity

Installed355 WorldRules.enterTile diaryPage branch calls WorldRules.readPage(DiaryPageID). That routine records the page permanently through LibraryState.recordPage, grants its existing page-kind knowledge, and emits .readPage(id); the successful first pickup awards discovery XP, clears the source tile and saves through the normal action owner. GameStore’s message switch currently renders “Diary page read.” The internal method/event name does not prove the player opened its prose.

Use that committed event’s exact DiaryPageID, not the most recent Library page, page title, traveller guess or another notification’s ID. The action payload should retain owning batch/event identity as well as the page ID. The existing GameStore worldFieldEventQueue/WorldFieldEventBatchV1 owns notification lifetime; preserve its stable retirement/deduplication and priority behavior.

## Player behavior

Display **Diary page collected** with **Read now** while that page’s notification is visible. Preserve the existing fade duration and ordinary overlay layout; do not pause the game awaiting a response or require another collection interaction. If multiple collection events are queued, each action opens its own page and never a later item.

On a valid click, resolve the exact owned page via library.hasFound(id) and ContentCatalog.diaryPage(id), then use the existing page reader/prose consumer (LibraryDiaryEntryPresentationRules and DiaryPageProseCard in LibraryView.swift) through a normal-game presentation owner. Engineering may provide a narrow adapter for the Field parent identity; do not push the wrong Library hierarchy or create a second prose implementation. Opening, closing and rereading cost no turn, resource or additional teaching reward. Closing returns to the same Field/campaign state. Once opened, the reader is independent of the notification’s subsequent expiry.

If it fades without a click, the page remains in the Library; there is no loss or timeout on knowledge. A retired notification cannot open a different page. Failed/uncommitted collection cannot expose an actionable durable pickup. Unknown legacy content retains its existing owned-page record and later Library fallback rather than crashing or substituting another page.

## Collection, viewing and learning remain distinct

Keep current pickup-time page-kind grants, prerequisite changes and first-discovery XP exactly where they are. Read now is not WorldRules.readPage again. Do not postpone existing grants until reading, reroll them, reverse them on dismissal or award them twice. Existing foundWriting and recoveredTeaching learning flows remain unchanged.

Collection records ownership; it does not claim actual reading. The existing Library attention helper GameStore.checkLibraryContent acknowledges only identities actually rendered. The new notification alone must not call it. If the opened prose participates in that attention system, acknowledge only its exact diaryPage ID once actually presented, through the existing save owner. Do not bulk-check the traveller’s pages or mark the whole event batch read. Preserve old attention/knowledge records; “checked” attention is not a new proof of reading or a new reward prerequisite. Any existing label that treats this pickup as a prose read must become collected; no new read gate is implied.

The current auto-grant behavior is a known implementation fact, not permission to redesign it. If Engineering finds an actual conflicting settled read-dependent reward rule, preserve current behavior and route the exact conflict to PM. Do not ask Aimee directly or stop unrelated production.

## Bounded verification and ordering

Focused checks: exact committed page ID, two distinct queued pages, duplicate/replayed event safety, fade without click retains Library ownership, successful Read now/close retains world turn/stock/knowledge, unchanged one-time pickup rewards, and failed-save/stale notification handling. One native ordinary-target/default/current-appearance receipt confirms the action fits the existing event pane and opens the correct reader. No new campaign or configuration matrix; no duplicate Design run. This player fix coordinates with normal3D integration after the urgent Securing action persistence defect. No new user approval is needed.
