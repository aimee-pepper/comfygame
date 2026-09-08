# Explore navigation block — stateful top/bottom anchoring

8 September 2026. **Accepted intended behavior; implementation pending.** Aimee directs the bottom navigation panes to move to the top of the viewframe when the character approaches within two tiles of being underneath them, then stay there until the character approaches the top panes within two tiles. PM resolved the exact native scope below under delegated authority. Including the utility strip and expanding the constant map rectangle are PM's implementation interpretation, not additional quotations or personal decisions attributed to Aimee.

This finalized contract replaces the unpublished feedback-only draft at this same path. Its filename is retained for existing handoff links; its authority is the navigation block described here. No new preference, trial, Home redesign or camera mode.

## Exact moving set and constant viewport

Move **carriedStrip + controls(run)** as one block in WorldView. Preserve their internal order at either anchor: the satchel/Field Kit/turn utility strip immediately above controls; controls retains the entire HStack containing DirectionPad and the right-hand minimap with Use Tile/Look. Preserve existing buttons, sizing, actions, disclosure and input admission. These are currently siblings below the map; moving only WorldFieldFeedbackRow does not fulfill the instruction.

At integration, remove this block's former below-map reservation once and render it as an overlay inside one constant full Explore rectangle below the fixed Explore/Stability header, Party strip and any Seamward guidance. The gained space exposes additional rows with the existing square tile scale, cardinal mapping and WorldMapFrameRequestAuthority follow/clamp policy. It is not a zoom. Thereafter changing anchors never resizes that rectangle, reverses VStack siblings to reframe the map, or changes camera policy. Top means the top of this Explore rectangle, not the status bar or screen top.

WorldFieldFeedbackRow remains a separate context/place/source-action and transient narration/event presentation. Place it inward from the navigation block with the existing 4pt separation: above bottom navigation, below top navigation. Preserve actual pane widths, measured heights and identity; its dimensions are not the navigation block dimensions. Expanded context/Read all opens inward, preserves scrolling and the existing 260pt maximum, and is capped further to available space. Do not count missing event panes or transparent gutters as painted obstacles.

LootDecisionCard and tutorial presentations remain separate with existing input priority and lifetime. Measure their occupied rectangles too. Resolve placement inside the same viewport so they do not collide with navigation or its inward feedback; constrain/scroll existing expandable content before changing any fixed control footprint. Do not dismiss loot, remove required actions, hide the character, or introduce camera movement to claim success. If actual target measurements leave no lawful collision-free layout, retain a stable anchor and report the exact rectangles/constraint to PM before inventing a new behavior. This local layout blocker must not stop main3D or diary work.

Asset's source-fit reference at the actual 402pt width gives nominal controls height 168pt (96pt minimap + 12pt gap + 44pt action row + 16pt vertical padding) and carried strip height 56pt (44pt minimum + 12pt padding), about 224pt combined. These are review expectations, not production threshold constants; measure growth and actual painted/hittable rectangles. Preserve the current button sizes and internal arrangement rather than compressing the block to evade overlap.

## Geometry authority

Use one named coordinate space for the clipped Explore viewport V. Obtain actual player bounds from the SAME snapshot, actorSupport/actorLevel, camera and scale used by OrthographicWorldPrototypeView. The current model fits a 0.38 × 1.0 × 0.38 scene box; project its bounding-box corners to form screen rect A. Include visible body, not shadow, target base or equipment UI. Do not substitute global map row, a tile center, or contextOverlapsPlayer's old flat approximation.

T is one tile's projected vertical height at that actor support plane, derived from the same projection without reading an undisclosed neighboring height. With the current square-ground projection this is tileSide. Use the actual follow/clamped viewport origin: edge travel changes the player's screen position naturally; do not change following to manufacture a trigger.

Measure every painted or hittable navigation/utility rectangle and the inward feedback/detail rectangles. Use actual intersections with V, including panel backgrounds; ignore transparent container gutters. The navigation block remains present regardless of notification expiry. Separately include loot/tutorial rectangles in layout collision and player-occlusion checks; they must not silently become navigation controls or acquire new dismissal behavior.

Evaluate actor, tile and panel geometry from one valid layout revision. Keep the last anchor if geometry is missing, nonfinite, zero-sized or stale. Production must expose actual actor and panel geometry: MiningAnchorReceipt tile targets and DEBUG probes alone do not provide it.

## Thresholds and opposite-edge hysteresis

Keep a transient bottom/top anchor keyed to the active run. On first entry start bottom, then perform one valid initial evaluation before admitting input. Preserve chosen anchor through movement, middle-of-map travel, notification arrival/expiry, reader dismissal and temporary encounter presentation while that Field owner lives. Cold recreation can repeat deterministic initialization; a new run resets it. No saved-game mechanic or preference.

Use the actual navigation/utility and inward-feedback rectangles at the current anchor, considering only rectangles whose horizontal footprint intersects A. Coordinates increase downward:

- Bottom: clearance = rectangle.minY − A.maxY. Approach begins at clearance ≤ 2T.
- Top: clearance = A.minY − rectangle.maxY. Approach begins at clearance ≤ 2T.

Equality triggers; negative clearance indicates overlap. No horizontal overlap supplies no trigger for that rectangle. Including inward feedback prevents navigation from moving while its attached layout still covers the player. Independent modal/loot occupancy remains a placement constraint, not a second autonomous anchor controller.

When the current anchor's approach condition is met and the opposite candidate is clear of its own two-tile zone, switch once. Consume that geometry observation. Disarm reversal until a subsequent valid snapshot is clear of the new anchor's entire approach zone, then rearm. Leaving the old zone or entering the middle does not return the block to bottom.

If both candidate anchors' approach zones contain the actor, **retain the current anchor deterministically**. Do not flip on repeated layout passes, choose a third anchor, zoom or move the camera. Resume an ordinary switch only when the current approach condition holds and the opposite candidate becomes clear. Large control blocks and expanded feedback can make this case real; distinguish proximity from actual painted overlap. Actual overlap that cannot be resolved within the existing geometry goes to PM with the measured constraint. One stable authority controls the entire moving set.

Use production measured control heights throughout. There is no 78pt navigation-height assumption or fixed illustrative viewport. Rendering and anchor movement spend no turn and invoke no gameplay action.

## Held input and content custody

Before changing frames, cancel all uncommitted held interactions owned by the moving block: D-pad direction/repeat, Field Kit/satchel/turn controls, minimap, Use Tile and Look, plus moved feedback controls. Cancel retained map gestures whose target becomes covered or moves. Use existing PhoneControlAdmission and quote cancellation; stop scheduled repeats under the old touch. Finger release at an old location cannot activate a new target. New interaction requires a fresh touch against current geometry. Already committed movement/work remains committed, with no refund, duplication or replay.

Preserve exact notification/event/page IDs, fade lifetime and queue order. Diary Read now keeps its committed page ID; moving or expanding a pane does not read/acknowledge a page or restart a notification. Existing detail state and scroll position survive subject to ordinary expiry. Fixed headers and unrelated controls retain their own admission behavior.

Preserve lawful tile planning, selected source, Look/Use Tile semantics, opacity/disclosure, full-sight and remembered facts, forecast, source reach, harvesting, combat and knowledge. Screen placement grants no extra sight or reach.

## Integration and bounded verification

Engineering owns production actor projection, anchor state, input cancellation and measured layout. Asset reviews placement from Engineering's same native evidence; no new artwork or Design capture. Exact consumer: WorldView carriedStrip + controls(run) overlay and separate inward WorldFieldFeedbackRow inside the normal Explore viewport. Output is native layout, not a raster asset. Review at the actual target iPhone/default text/current ordinary appearance and record the actual device and native viewport.

Order: main3D checkpoint (installed357, supplied receipt verified) → diary collected/Read now → navigation anchoring. Other independent work continues. Current delivered layout remains unchanged until Engineering supplies delivery evidence; this document is not a delivery receipt.

Focused checks cover both threshold directions/equality, retaining top through the middle and event expiry, both-candidate proximity without oscillation, actual large navigation footprint, absent feedback/gutters, elevation and following/clamped edges, loot/tutorial collision, inward expansion, first-entry placement and stale measurements. Exercise held D-pad repeat and release during a switch, minimap/map gestures and exact diary/event identity. One bounded native route at the actual target demonstrates both anchors, readable feedback and usable controls without changing tile scale or reframing on flips. Reuse its evidence for Asset review; no configuration matrix, new trial, duplicate Design run or phone-launch dependency.
