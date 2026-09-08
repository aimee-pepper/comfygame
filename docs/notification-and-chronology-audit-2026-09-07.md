# Notifications and encounter chronology — consolidated Design handoff

7 September 2026. Direct Aimee direction relayed by PM: audit ALL notifications for excessive wording; cataclysm roughly one month ago. Source basis: Engineering delivered343,91b853f8, world-crash-and-notifications. This is a source audit and exact copy contract, not a claim the corrections are installed. Engineering owns implementation in consolidated batches. Recording delivery proceeds with the already-sent mining/Halloway corrections; do not wait for this remainder.

## Coverage and limitations

Companion `notification-chronology-source-inventory-2026-09-07.json` inventories292 checked-in Sources Swift/JSON inputs with hashes and554 notification/feedback anchors, including explicitly classified internal diagnostics. It resolves all29 runtime meetings, including23 generated promotions, and inventories all240 diary pages through the base corpus.156 temporal candidates across JSON and resolved meetings were screened. The inventory includes false-positive code anchors; it is an audit aid, not a claim that every source string is a notification or a rendered-width test.

Reviewed producer/consumer families:

| Surface | Authoritative producers / actual consumer | Disposition |
| --- | --- | --- |
| Timed field notices and expanded event history | GameStore.swift `WorldFieldNarration`; WorldRules.Event; GameActions+World.swift; WorldView.swift `WorldFieldFeedbackRow` | Short event projections below. Preserve event payloads, order, categories, timing and wrapping. |
| Adjacent traveler speech | GameStore.swift `TravellerAdjacentSpeechV1Registry` | All29 lines considered as character dialogue. Keep voice; no chronology conflict, no routine mechanics tutorial. |
| Mining, extraction, movement, site, survey, Attend | GameActions+EarlyMaterials.swift; ResourceExtractionRules.swift; WorldRules.swift; SeamlightRules.swift | Exact refusal-specific copy below. No advice for a different failure. |
| Combat action/result/affliction log | CombatRules.swift `encounter.note`, GameActions+Combat.swift, AnimalCompanionCombatRules.swift; EncounterView.swift | Keep actor/target/effect/amount/duration; shorten only rows below. Ordered log remains evidence. |
| Home/shopping/crafting/refit/packing feedback | BaseView; BlacksmithView; StationViews; ApothecaryView/Batch/BriarOilPreparation; Early* maker views; SpendingViews; TradingPostView; RecyclerView; LootDecisionView; FirepitView | Remove repeated tutorial and requirement laundry lists; retain actual refusal and review action. Exact replacements below. |
| Shared gear/trade/inscription/development refusals | Model/Inventory.swift, Model/TradingPost.swift; EquipmentInscriptionRules; CombatGraphRules; GameActions+Economy | Keep already concise branches; shorten stale/review repetitions and preserve shortfalls/destination facts. |
| Writing/Bind/Library/Return | PageRules; WritingDeskReviewModel; GameActions.swift; WritingDeskView/BindBar; LibraryRules; LibraryView; RootView | Preserve actual cost/ink counts and pre-spend refusal. Dedicated Unread Findings contract below. |
| Campaign loading/save/recovery/settings | BookbinderApp; CampaignAppCoordinator; SaveSlotCatalogue; CampaignStartView; SettingsView | Keep necessary recovery instructions, version compatibility and preservation facts. Do not turn genuine errors into misleading success or drop destructive-choice consequences. |
| Contextual explanations | TutorialRules, detail panels, Library prose, WorldDescriptionPanel Measured, action confirmations | These are not all transient notifications. Keep decision-critical context on existing surfaces; do not create new panels or globally truncate strings. |

Routine cue target: one short sentence, often3–10 words; not a hard length limit. A measured result may require names/numbers; a destructive decision may require a consequence. Do not remove information just to hit a character count. No runtime ellipsis, count-only replacement for unavailable details, raw IDs/floats, or toast concatenation of prose paragraphs. Never change event/state mechanics to simplify copy.

## Exact field projections

Paths below are relative to Sources. Placeholder braces denote the existing runtime value; retain existing plural handling and disclosed naming.

| Producer / branch | Replacement |
| --- | --- |
| Persistence/GameStore.swift `.harvested` | `Harvested {amount} {resource}.` Append ` Depleted.` only when exhausted. |
| `.earlyMaterialHit` | Keep `The trunk is partly cut.` for zero yield; otherwise `Gathered {amount} {material}.` Append ` Depleted.` only when true. |
| `.readPage` | `Diary page collected` Full exact prose remains in its existing Library diary page; do not discard event payload or learned reward. |
| `.readFoundWriting` | `Field writing read.` Full record remains on its existing Library shelf. |
| `.surveyed` | `Survey complete: {count} readings.` Exact values remain in WorldDescriptionPanel's existing **Measured** section. If any committed reading lacks that existing display, retain concise `{name}: {value}` for that reading until the existing projection is repaired; never silently lose a reading. |
| `.metTraveller` | `{name}, {calling}.` Omit blurb from notification; existing meeting retains character text. Unknown fallback `Someone is here.` |
| `.foundSite` | `Found {site name}.` Existing disclosed site details retain blurb. Unknown fallback `Found a structure.` |
| `.usedItem` | `Used {item}.` Do not assert every consumable heals. Actual result events retain their effects. |
| `.nightfall` / `.daybreak` | `Nightfall. Visibility reduced.` / `Daybreak. Visibility restored.` |
| `.searchedSite` | `Searching: {remaining} turn(s) left.` |
| `.siteOpened` | `{site name}: searched fully.` Missing name `Site searched fully.` |
| `.learnedSymbol` / `.learnedFocus` | `Learned {word}.` Preserve established display lookup and unknown fallback `Learned a word.` |
| `.learnedGambit` | `Learned Gambit: {name}.` |
| Content/TravellerModels.swift SchematicPresentation, both overloads | `Learned Schematic: {name}.` / `Learned a Schematic.` |
| `.satchelFull` | `Satchel full. {item} is waiting.` Keep the actual waiting state; no deletion implication. |
| `.dangerousFloraPoison` | `Poison: {damage} damage; {remaining} turn(s) left.` |
| dangerousFloraContactCopy | `{name}: {actual contact cause}. {damage} damage.` Append ` Poisoned.` only when applied. Keep actual cause; do not reveal a hidden profile. |
| `.animalTrustProgress` | `{name}: {current}/{required} patient turns.` |
| `.lostToCrumbling` | `{count} uncollected item(s) lost to crumbling.` Retain actual event count semantics; if count includes non-item sources use `uncollected find(s)` instead. |
| `.crossedThreshold(.collapsed)` and `.collapsed` | `World collapsing. Reach a portal.` |
| GameActions+World auto-path dangerous occupied tile | `Danger ahead. Step onto the tile deliberately.` |
| Auto-path slowed-ground + nearby danger branch | `{ground} ahead; danger nearby. Step deliberately.` Preserve disclosed ground and danger gates. |

All other field branches already express a brief event, result, or urgent cause: retain their facts and voice. Do not use `enemySighted`'s internal name to reinterpret its current notice/awareness semantics in this copy batch. Ejection causes remain cause-specific.

## Refusals and result feedback

Mining contract is delivered344 and retained347: disclosed wrongTool + owned adequate tool → `Select your {tool.displayName}.`; none → `Requires {Tool} Lv {minimumTier}+.`; hidden/missing/stale/exhausted → `Cannot mine here.`; actual priority interaction → `Finish this interaction first.`; out of reach → `Cannot reach this deposit.` Do not turn all quote failures into tool advice. Keep the encounter guard and success path.

| Exact source / current discriminator | Replacement |
| --- | --- |
| ResourceExtractionRules `.underEquipped` | `Requires Extraction {required}; party has {current}.` This is the legacy Extraction stat, not the early Pick level. |
| ResourceExtractionRules `.outOfReach` | `Move onto or beside this resource.` |
| ResourceExtractionRules `.stale` | `Resource or Field Pick changed. Review again.` |
| WorldRules Attend `.notVisible` | `The animal is out of sight.` |
| Attend `.outOfRange` | `Move within two tiles.` |
| Attend `.malformedIndividual` | `This animal's record is unavailable.` Keep refusal; do not fabricate identity. |
| WorldRules sample mismatch | `This sample does not meet the animal's need.` |
| WorldRules incomplete trust | `This animal does not trust you yet.` |
| WorldRules unfinished lesson route | `Follow the lesson path, or Return Home.` Preserve existing actual allowed routes. |
| WorldRules full recruitment capacity | `No room at your fire. Make space first.` |
| WorldRules survey stale | `Field Kit changed. Review the survey.` |
| WorldRules site invalid authored contents | `This site cannot be searched right now.` Internal reason retained in diagnostics only. |
| BaseView buildFailure | `Foundation requirements changed. Review again.` Existing foundation detail retains builder, stock, Essence and space requirements. |
| BlacksmithView stale gear/stock/tier/cost | `Gear, stock, tier or cost changed. Review again.` |
| BlacksmithView stale station/pattern/stock/tier/cost | `Crafting requirements changed. Review the preview.` |
| BlacksmithView stale stock or failed save; EarlyTanneryView equivalent | `Stock changed or saving failed. Review again.` |
| EarlyCarryView purchase failure | `Purchase changed or saving failed. Review again.` |
| EarlyFieldMaterialsView harvest failure | `Source changed or saving failed. Nothing gathered.` |
| EarlyGarmentRefitView | Keep `The piece or stock changed. Review again.` |
| EarlyForgeGearView quote failure | First actual failing condition only: `Requires Forge Lv {minimum}.`, `Missing {quantity} {material}.`, or `Change at least one component.` Use actual frozen quote validation, not guessed error. |
| EarlyBowyerGearView quote failure | Actual failing condition: `Build the Bowyer first.`, `Missing {quantity} {material}.`, or `Change at least one component.` |
| EarlyWeaponsmithGearView quote failure | Actual failing condition: `Build the Weaponsmith first.`, `Missing {quantity} {material}.`, `Change a component or fitting.`, or `Learn Fitted Polearm first.` Do not show Polearm prerequisite for another recipe. |
| EarlyBowyer/Forge/Weaponsmith commit failures | `Stock changed or saving failed. Review again.` Retain distinction from earlier invalid-input quote. |
| BriarOilPreparationView review nil | Exact failed requirement: `Select {count} eligible world resources.`, `Missing {quantity} {Fibre/Resin}.`, `Build the Apothecary first.`, or `Learn Briar Oil first.` Keep authoritative check order. |
| Briar Oil commit failure | `Stock changed or saving failed. Nothing prepared.` |
| ApothecaryBatchView commit failure | `Stock changed or saving failed. Review again.` Success quantity/name remains. |
| ApothecaryView Lesser Salve confirmation | `Prepared 1 Lesser Salve. Stored in Storehouse.` Only say stored for actual stored destination; preserve Waiting destination when applicable. Field Kit planning stays on its existing screen/tutorial. |
| ApothecaryView required-stock failure | `Recipe stock changed. Review again.` |
| ApothecaryView failed preparation save | `Could not save preparation. Review stock.` |
| ApothecaryView reagent selection | `Select one animal material; requires 1 Reagent.` |
| ApothecaryView stale animal resource | `Material or Reagent unavailable. Choose again.` |
| RuleBuilderView addFailure | `Rule or selected parts unavailable. Review again.` |
| StationViews core requirements changed | `Sample, catalyst, Crystals or space changed. Review again.` Keep established Essence Crystals label if context doesn't supply it. |
| StationViews fixture failure | `Heat core or Storehouse space changed. Review again.` |
| StationViews Anchor Frame | `Stock, Essence or space changed. Review Anchor Frame.` |
| StationViews revisit | Actual failure: `Return Home before revisiting.` or `This realm is dormant.` Other/stale → `Realm unavailable. Review again.` |
| StationViews realm/Essence changed | `Realm or Essence changed. Review again.` |
| StationViews instrument upgrade | `Stock or Essence changed. Review requirements.` |
| StationViews waiting collection | `Waiting pile or Storehouse changed. Review again.` Pile-only branch keeps only that cause. |
| SpendingViews Raw Essence | `Raw Essence changed. Review the amount.` |
| SpendingViews Mastery | `Motes or Mastery rank changed. Review cost.` |
| GameActions.swift mixed-ink shortfall | `Ink: {available}/{needed} applications. Prepare more or use Ash.` Keep actual matching-mixture count; do not silently switch ink. |
| WritingDeskView ink default selection | `Next eligible focus uses this mixture.` Ash equivalent `Next focus uses Ash.` |
| WritingDeskView applied | `Mixture applied. Pigment is spent on successful Bind.` |
| WritingDeskView stale ink preparation | `Stock changed. Nothing spent. Review again.` |
| Inventory gear/component stale | `Gear changed. Review again.` / `Materials changed. Review again.` Preserve slot/owner/shortfall and Waiting-space branches unchanged. |
| EquipmentInscriptionRules stale gear/quote | `Gear changed. Review the Inscription.` / `Inscription costs changed. Review again.` |
| CombatGraphRules stale | `Character changed. Review again.` Keep prerequisites and point shortfall. |
| LootDecisionView stale | `Satchel changed. Review current items.` |
| SaveSlotCatalogue stale recovery | `Campaign changed. Nothing altered. Inspect again.` Other recovery/version/destructive-choice copy remains: useful consequences are not excess. |
| SettingsView campaign-return failure | `Could not open Campaigns. Current campaign unchanged.` Keep retry action. |

For generic Boolean/nil quote failures that cannot identify a specific condition today, use `Requirements changed. Review the selection.` until the existing validation result is carried to the existing message surface. Never assert a single cause without evidence; do not introduce new rules/UI to obtain it. Do not claim nothing spent/saved unless the corresponding transaction guarantees that result. The component/material counts and actual shop level come from current authoritative requirements, not these example placeholders.

## Combat log

Keep most combat lines: concise actor/action/quantity and duration information is necessary, and multiple actual effects may legitimately create several ordered entries. Keep coating excursion duration; no deprecated one-strike coating copy. Keep internal god-mode warning in its debug context, never remove diagnostic evidence as ordinary copy cleanup.

| CombatRules.swift current branch | Replacement |
| --- | --- |
| Inspect `You take {foe} in properly. You'll know it again.` | `Observed {foe}.` Existing knowledge effect unchanged. |
| protection reduced `{skill}. {foe} is {taken} less protected than it was.` | `{skill}: {foe} loses {taken} protection.` |
| actor misses with swing/finds-nothing variants | `{actor} misses {foe}.` Correct Binder grammar; retain dodge/cover event distinctions. |
| damage reduction `{source} reduces the harm from {amount} to {reduced}.` | `{source}: damage {amount} → {reduced}.` |
| heal result | `{source}: {target} recovers {amount} health.` Retain healer attribution if healer differs from source/target and the existing log requires it: `{healer}'s {source}: {target} +{amount} health.` |
| contact retaliation | `{foe}: {retaliation} contact damage.` Preserve actual retaliation cause. |
| foe misses target finds-nothing variant | `{foe} misses {target}.` |
| companion down | `{name} is down; recovers at Home.` |

Do not collapse multi-target amounts, selected status removal, round expiry, skill source, XP/level gains or waiting loot into an opaque “Done.”

## Chronology: finding, correction and recurrence prevention

Canon: the cataclysm happened roughly one month ago at the game's opening. This is approximate story context, not an exact30-day calendar system or a statement that no campaign time passes. Do not justify post-cataclysm years through unapproved time dilation.

**Halloway**: base `Sources/Content/Data/travellers.json`, meeting question `halloway.kept_fire`, asks “You've kept a fire going out here?” and replies “Nine years of it.” Replace ONLY that initial quoted sentence with **“Since everything broke.”** Keep her tending action and forge metaphor. This corrects implied post-cataclysm duration without adding a new date that ages during play. No additional lore choice blocks it.

**Why missed, supported by actual records:** `docs/authored-text-audit-current.md` marks Halloway Good and explicitly praises fire/forge identity. Its five-point rubric covers standalone sense, concrete world evidence, mechanical usefulness, voice and economy; chronology is absent. `docs/full-cast-voice-authority-current.md` likewise says Halloway retained. That shows the live line survived a voice/content audit; it does not prove an earlier complete chronology audit was performed or that a correction was delivered then. No evidence found of a runtime years substitution causing this bug.

**Actual runtime resolution:** ContentCatalog.loadPromotedTravellers loads base JSON, then overlays23 meetings decoded from base64 in DraftMeetingCorpus.generated.swift, generated from four named traveler-meetings review documents. Only Noll/Auber are allowed to replace existing base meetings. Halloway is not overlaid. TravellerMeetingView directly renders selected exchange.reply; neighboring speech comes from a separate29-line registry. A raw Swift grep alone misses the encoded23; a review-doc-only correction can miss the base six. Both sources, plus their resolved union, must be considered on future text changes.

Keep these legitimate cases:

- Isolde's **forty years teaching** are explicitly her earlier career, not years stranded since the cataclysm.
- Mara's **four hundred sightings** explicitly says **not days**; no calendar duration is implied.
- Halloway feeling cold “a long time,” Mara's “long while,” brief waiting and Ashe's today/yesterday are compatible with weeks. No numerical retiming needed.
- Old structures, repeated repairs, preexisting books, inherited tools and a winter spent making an item are pre-cataclysm/object history unless the text explicitly says otherwise.
- Perren/Nine observations of intervals are not a blanket permission to add decades to anyone's post-cataclysm waiting. Their existing reveal restrictions remain.

No additional explicit post-cataclysm years/months conflict found in the resolved29 meetings,240 diary-page corpus, adjacent-speech registry, relevant encounter/combat text and other content duration candidates. This is a source result, not a guarantee against future procedural copy. Future audit receipts should state exact input hashes, resolved catalog paths and affected stable IDs; distinguish historical audit praise from actual correction/delivery. Preserve old docs as historical evidence but add explicit supersession near conflicting current claims.

## New direct Library decision: Unread Findings

Name supersedes “Unread Teachings.” Library root has **Unread Findings** with count of all valid recovered unread lessons, including prerequisite-blocked. Return **Read findings** opens it directly after existing Return/Home completion. Initial scope remains recovered teachings, not every Bestiary/history unread badge.

Each entry has its frozen lesson title, actual readiness or exact missing prerequisite, and stable teaching identity. Opening existing detail attempts the existing free atomic read. Decrement count/remove from unread only after successful persisted learn or already-read receipt. Keep detail visible with “Learned.” Back returns to remaining list; empty copy **No unread findings.** Failed persistence/invalid record stays unread with truthful failure; don't mislabel every failure a missing Subject.

Do not duplicate unread lessons under Field Notes. Learned teaching records stay readable in Field Notes, and learned words remain in Dictionary. Normal anonymous notes stay in their existing collections. No new extra Read button, cost, reward, or broad Library redesign.

Wildfire now learns via Library → Unread Findings → Wildfire → detail.onAppear; learned records remain in Field Notes. For connected-opening policy, EarlyTeachingRules accepts any known attached Subject: **Hydrology, Thermal, or Vitality**; a genuinely blocked lesson names those alternatives, not a requirement for all three. **Legacy guard:** the supplied preserved campaign has openingPolicy=nil and does not require a Wildfire Subject; its Ready label is valid. Preserve the existing policy/earlyWritingTargets eligibility. The generic Library shortcut is the route defect; do not introduce a prerequisite to old saves. Engineering caught and corrected this overbroad Design wording before delivery.

The inherited21August `recovered-teachings-current.md` explicitly separates collecting a preserved attributable record from opening it to learn, at no Essence/turn cost. This is Design authority, **not proof of Aimee's explicit approval of that earlier step**. Her current dedicated-section request authorizes the route/presentation correction; no removal or auto-learn-all decision is inferred.

## Hide/source detail: ready copy direction, exact grouping resolved from Engineering receipt

Engineering owns read-only inspection of the actual Common Supple Hide8+2 groups. **Latest direct Aimee decision:** same material identity and quality share one visible stack despite nuanced property/colour differences. Preserve exact underlying source/color/custody records and quantities; no destructive averaging or recoloring.

Collapsed stack: item name, quality and aggregate quantity only. On opening its existing detail: relevant **Flexibility / Hardness / Insulation / Density / Lustre / Reactivity** values where applicable to that material, and actual color swatch/ordinary color description. Use existing stat scale with sensible display precision; don't invent a stat or map raw covering length/coverage to an unrelated gameplay bonus. Only show disclosed creature/source names; otherwise **Unknown source**. No receipt IDs, world seeds, CMY floats, or “rendering pending.” Unknown old color → **Colour not recorded**; never guess it. Use same property/color formatting in Return and Storehouse. Engineering's actual phone-state receipt resolves the differences below; this is not an equivalence-merge bug.

Collateral source correction: `travellers.json` diary `pages/178` describes Mercury running from a seam. The earlier narrow mineral registry/Apothecary review omitted this diary. The approved solid host/silver-face node still fits a mined seam; “no liquid pool” defines the node depiction, not a denial of Mercury's narrative behavior. No new liquid mechanics, poison gameplay or refining step follows from that prose.

## Delivery and next work

343 encounter crash is closed by Aimee's physical confirmation. Mining/Halloway and temporary2D policy are now delivered344 per Engineering receipt; new-world behavior has internal verification, not physical play acceptance. Unread Findings and the Hide grouping/detail correction are delivered345 from source523d7051069dc2cfa5a1c9400a94ac498616d9e2, per the Engineering phone-345 receipt. Field/Schematic/auto-path copy is subsequently delivered346, source8f9c2c8cc1daaf58e665eb401c055576b5eb4a7c. Survey preserves concise name:value readings where the lens-gated Measured surface would omit them; crumbling counts uncollected finds. Action/shop/refusal/combat copy is delivered347, source92bfc4e7869ce2f9698481c0ad1e68eb76a0b5be/tree dc7711a16452c8e9b7d082326c1a0532603efed3, installed/readback2026-09-08T03:07:04.793054Z with ordinary launch verified. Nine distinct focused checks passed; healing copy reports the actual capped amount and untyped maker failures use the approved fallback. The separate pre-existing hostility verification gap was closed on8September by repairing its invalid test setup. The focused test now passes, including actual saved-state reopening; production hostility rules and installed354 are unchanged. The notification delivery was not a hostility gameplay fix. Later shops are not reopened for mechanical work; their existing feedback is in the all-notification copy audit only. No new Aimee homework beyond any substantive lore conflict actually found; none blocks the chronology correction. PM receives failures and any required owner engagement. Design does not duplicate native/phone/deployment checks.


### Actual Hide8+2: final presentation contract

Engineering supplied read-only current phone-state measurements (run13 returned). Both groups have common source quality and Supple Hide material; generic scalar qualityBand1/Standard must not override the source Common label. Group8 has coverage40, hardness15, length20, flexibility51, coveringProtection6 and FOUR frozen colour variants of2units each. Group2 has coverage50, hardness10, length10, flexibility49.50000000000001, coveringProtection5 and ONE colour variant of2units.

**Superseded two-row suggestion — latest direct Aimee instruction controls:** present ONE **Common Supple Hide ×10** stack. Do not show separate8/2 stacks or property/colour summaries in the collapsed list. These differences do not justify splitting the same material and quality.

Tap/open the existing stack detail to expand its exact variants and quantities. That detail can show Flexibility51/49.5, Hardness15/10, Coverage40%/50%, Covering length20/100 vs10/100 and Covering protection6/100 vs5/100. Covering protection is not finished armour defense. Show actual colour swatches with each variant's quantity inside the expanded detail. No new colour-naming thresholds or invented species.

Presentation key: canonical material identity (including supported material subtype, e.g. Supple Hide) + authoritative quality within the existing inventory/custody/destination context. The backing8/2 and four-plus-one colour records remain exact. Count each owned unit once; do not combine Storehouse stock with waiting/carried stock into a false usable total. Display rounding never merges underlying values. Existing crafting and exact lot consumption keep using preserved variants; if an action needs a specific variant, resolve it through the existing expanded selection, not an invented average. Apply the same aggregation to Return and Storehouse material lists. This aggregation/detail contract is delivered345 and retained347, using the supplied exact-stock and native receipts.

###344 delivery receipt

`docs/phone-344-delivery-2026-09-07.md` in recording-2d-node-policy: sourceefeab33303eff0a2bd1a2d1994ca1ae9548aa404/treeeced7872c5ad8310a41ae35748c1eb9388c61b92, installed/readback2026-09-08T00:58:43.838086Z, ordinary launch87955 retained.6/6 cumulative internal checks plus actual north movement/turn1/reopen PASS. Old worlds/stock retained, new ordinary2D exclusion and private3D exception, explicit Iron pre-spend refusal, Salt preserved, concise mining/Halloway correction included. No phone gameplay/reset. All-six3D artwork remains separate, Unread Findings and source details next. No repeat Design checks.

## Hostility verification closure — test-only repair

Engineering checkpoint `35c30b29700ca26da71275f657060c8be3fa8de3`, receipt `docs/animal-hostility-fixture-repair-2026-09-08.md` in animal-hostility-fixture, closes the reported gap. The test removed a companion from encounter order/slots while retaining its frozen gear/participant receipts, so exact save validation correctly refused the candidate. The earlier missing-file/fresh-store explanation was incomplete. The repair builds the intended Binder-only party before production encounter construction, validates/writes/loads real state and aligns the Binder turn. Original forced-miss/ordinary exact-target hostility/trust, status-only Snuff and healing exclusions remain; attack and status results survive actual disk reopen. Focused1PASS. No companion rule/assertion relaxation, validation bypass, production change or new phone build/launch; installed354 is unchanged. PM has closure; no Design duplicate test or Aimee engagement.

## Superseding diary instruction —8September

Collection now requires “Diary page collected” plus exact-page “Read now” while the notification is visible. Follow [the bounded contract](diary-collected-read-now-v1-2026-09-08.md). Preserve pickup-time learning/XP, later Library ownership and actual-rendered attention semantics; no new reading prerequisite. Current355 copy remains until Engineering delivers this correction.

## Forecast approximation wording —8September

PM inspected the existing main-campaign3D native-entry image and WorldView forecast producer: `~\(Int(projectedTurns)) turns until collapse` can look like a negative number in the pixel font. This repeats the previously resolved tilde/negative misreading; no numerical bug is established.

**Intended literal:** `About \(Int(projectedTurns)) turns left`. Example: **About 588 turns left**. Preserve projectedTurns, Int conversion, availability/threshold branches and the existing fixed-target header. Do not add abs/clamp, change collapse rules, investigate forecast arithmetic or reopen the prior audit. Engineering has this small correction for sensible current integration; main3D gear/delivery priorities remain. Use its existing ordinary-target receipt rather than a separate Design/native run. Current tilde wording remains until delivered.
