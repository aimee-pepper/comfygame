const failed=(source,issues)=>({status:"failed",source,issues,designVersion:"draft-0"});
const pending=source=>({status:"pending",source,issues:["Native behavior audit has not been completed yet."],designVersion:"draft-0"});

export const nativeConformance={
  campaigns:failed("CampaignStartView.swift + CampaignStartPresentationTests.swift",["Native valid-save taps load immediately; the mock adds a persistent selection step and bottom rail.","The mock invents health metadata; native shelf facts are level, location, progression, last played, progress-book count and save validity."]),
  home:failed("BaseView.swift + StartingTownHomeScene.swift",["The current primary label claims a named world is bound, but native opens Writing Desk.","Make, Study and Realms states are not represented yet."]),
  "writing-desk":{status:"verified",source:"WritingDeskView.swift:99-167, 222-430, 479-980 + ui-writing-candidate.test.js",issues:[],designVersion:"native-2"},
  storehouse:failed("StationViews.swift",["Native modes are Items, Resources, Field Kit and Waiting; the mock invents Gear and Sort."]),
  workshop:failed("StationViews.swift",["Native Workshop is resource context plus ResearchTree; the mock invents fabrication projects."]),
  party:failed("PartyRosterView.swift",["The mock invents formation roles and omits the native member pager and Gear/Training/Stats/Gambits structure."]),
  "essence-spring":failed("StationViews.swift + SpendingViews.swift",["Native Refine, Study and Unlearn modes and dynamic conversion are not represented."]),
  constellation:{status:"verified",source:"StationViews.swift:1557-1637 + SpendingViews.swift:183-299 + ConstellationPresentationTests.swift",issues:[],designVersion:"native-1"},
  library:failed("LibraryView.swift",["Native tabs are Diaries, People, Runes, Notes and History; the mock invents categories and root actions."]),
  bestiary:failed("BestiaryView.swift",["Native root is a searchable two-column Kinds met grid; Overview/Specimens exist only inside a species sheet."]),
  research:failed("ResearchViews.swift + ResearchTreeLayout.swift",["The mock uses placeholder graph data and invented tabs/actions instead of station-owned branch hubs and exact prerequisite DAGs."]),
  "world-history":failed("WorldHistoryView.swift",["Search/filter/sort/compare controls and detailed record/comparison states do not match native interaction."]),
  blacksmith:failed("BlacksmithView.swift",["Native Make, Reforge and Learn workflows are incomplete in the mock."]),
  "trading-post":failed("TradingPostView.swift",["The mock bypasses native anchored quantity/price sheets and exact Buy/Sell eligibility."]),
  recycler:failed("RecyclerView.swift",["The mock invents tabs and omits eligibility, protected reasons and destructive confirmation."]),
  tannery:failed("BlacksmithView.swift",["The mock invents Stretch/Cut/Stored; native uses Wear, Construct and Research."]),
  bowyer:failed("BlacksmithView.swift",["The mock invents Maintain and a tension control; native uses Far reach, Construct and Research."]),
  armoury:failed("BlacksmithView.swift",["The mock omits exact target selection, legacy warning, sample selection and Research."]),
  weaponsmith:failed("BlacksmithView.swift",["The mock invents family/profile controls; native uses recipes, gated polearms and Research."]),
  scriptorium:failed("StationViews.swift",["Capability gating and Runebook transactions are missing; ink preparation belongs at Writing Desk."]),
  "survey-post":failed("StationViews.swift",["Native owns measurement disclosure, trip packing, instrument improvement and ResearchTree; the mock invents a graph and Study rail."]),
  apothecary:failed("ApothecaryView.swift",["The mock invents category tabs and omits the learned-recipe workflow and Scent Mask source selection."]),
  reliquary:{status:"verified",source:"StationViews.swift:210-227 + Tuning.swift:932 + SiteTests.swift:297-311",issues:[],designVersion:"native-1"},
  "wayfarer-s-table":{status:"verified",source:"StationViews.swift:229-250 + BaseState.swift:242-245 + Tuning.swift:925-931",issues:[],designVersion:"native-1"},
  anchorage:failed("StationViews.swift",["The mock invents a realm orbit and global actions while omitting Anchor Frame and per-realm lifecycle controls."]),
  distillery:failed("StationViews.swift",["The mock invents tabs and gauges and omits attunement cards, sample/catalyst selection and readiness."]),
  channelworks:failed("StationViews.swift",["The mock invents route planning; native owns one conduit housing and Build another."]),
  firepit:failed("FirepitView.swift",["The mock invents seats, Binder membership and global transfer actions."]),
  gear:failed("GearView.swift",["The mock omits candidate locations, worn-by-other, empty, take-off and carried refusal states."]),
  world:{status:"verified",source:"WorldView.swift:89-141, 438-501 + WorldTests.swift:920-963 + ui-world-candidate.test.js",issues:[],designVersion:"native-2"},
  encounter:failed("EncounterView.swift",["Native actions are Attack, Techniques, Item and Withdraw; Confirm, Pass and Remedy are invented."]),
  "loot-decision":failed("LootDecisionView.swift",["The mock skips the carried-item selection step and irreversible Leave confirmation."]),
  "return-recap":failed("RootView.swift",["Native recap is one comprehensive scroll; Recovered/Lost tabs and History action are invented."]),
  settings:{status:"verified",source:"SettingsView.swift:14-183 + Theme.swift:9-31 + ContentTests.swift:146-172",issues:[],designVersion:"native-1"}
};

export function conformanceFor(screenID){return nativeConformance[screenID]??pending("Native source not yet assigned");}
