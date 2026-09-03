# Rewritten World Clues

**Status:** complete proposed copy for Aimee review; not yet implemented in the game

These are the revised 137 location clues for all twenty-nine travellers. Every clue begins with a world
condition the player can picture after one reading. Character personality appears through warmth,
confidence, caution, humour or conversational rhythm—not through an unrelated personal story or a
list of words from the character's profession.

The puzzle remains deciding what kind of written world could produce the clue. The puzzle is never
deciphering what the clue is trying to say.

## What stays unchanged

- All 137 true location-clue page IDs, owners and clue numbers stay the same.
- All 137 traveller-signature conditions stay the same.
- Discovery order, page custody, traveller eligibility and world-generation rules stay the same.
- Clues do not reveal internal numbers, hidden sigils, undiscovered sites, resources or creatures.
- A single old Tovin page about Isolde is corrected below. It remains in Tovin's book, but becomes a
  normal whereabouts page instead of being the only cross-character `locationClue` in the game.

When Engineering integrates this copy, each traveller's signature passage and matching self-clue
page must receive the same exact sentence. No other field in the traveller catalogue changes except
the one explicitly corrected Tovin page below.

## One old page that is not a location clue

Tovin's page about Isolde was the only page in the entire catalogue whose author and location-clue
subject were different. There is no broader cross-character clue system to teach the player, and
Isolde already owns one clue for each of her two world conditions. The one-off classification only
made the catalogue harder to understand.

Keep the page in Tovin's book, but change its kind from `locationClue` to `whereabouts` and remove
its `clueIndex`. Its revised text is:

> Isolde taught me when my handwriting was worse than it is now. If you are looking for her, try
> high, stony ground. She likes a clear view of the line she is drawing.

This uses the game's established relationship-page structure, preserves the Tovin–Isolde history,
and leaves one clean rule: every location clue directly represents one condition of the traveller
who owns it.

## Opening travellers

### Vance

Vance is friendly and practical. He gives the useful fact first, then adds the sort of observation
someone might make while imagining how people could use the place.

| Page | World cue | Revised clue |
|---|---|---|
| `vance_where_0` | Very open land | The land is broad and open, with almost nothing blocking the horizon. Even a heavily loaded cart could cross it without much trouble. |

### Noll

Noll is quiet, blunt and deadpan. Their clues say what is present, what can be inferred and when the
answer is still uncertain.

| Page | World cue | Revised clue |
|---|---|---|
| `noll_where_0` | Hard ground | Most of the ground is hard stone, and broken edges stay sharp instead of crumbling. Useful pieces should come away cleanly. |
| `noll_where_1` | Material concentrated in narrow seams | Useful material gathers in a few narrow seams instead of being scattered everywhere. Easier to find, easier to leave the rest alone. |

### Halloway

Halloway is calm and reassuring without making a fuss. She helps the player feel capable while
being honest about the condition in front of them.

| Page | World cue | Revised clue |
|---|---|---|
| `halloway_where_0` | Strong heat | The hottest interval here is hot enough to warm stone and metal quickly. Mind your hands; the world is already doing part of the work. |
| `halloway_where_1` | Ground that can be reshaped | Much of the ground softens and changes shape when worked, then holds that shape as it settles. Patient hands could make something dependable from it. |

### Mara

Mara is curious and excitable. She thinks aloud and corrects herself without making uncertainty
sound like failure.

| Page | World cue | Revised clue |
|---|---|---|
| `mara_where_0` | Extremely bright intervals | At its brightest, the whole horizon turns almost white. Oh—that will make distant detail hard to judge, even when everything seems easy to see. |

### Edren

Edren is thoughtful and careful. He distinguishes what can be seen from what it might mean without
turning a clue into a lecture.

| Page | World cue | Revised clue |
|---|---|---|
| `edren_where_0` | Hard ground | Hard stone covers more of this world than loose earth. The surface should preserve marks well, though it will be slow work to disturb. |
| `edren_where_1` | Persistent cold | Even the mildest interval stays bitterly cold. Anything exposed here may be preserved—but so will your numb fingers, if you linger. |

### Isolde

Isolde is intense, exacting and encouraging. She tells the player where to look and may challenge a
first impression, but never hides the observation behind a lesson.

| Page | World cue | Revised clue |
|---|---|---|
| `isolde_where_0` | High ridges and steep slopes | High ridges and steep slopes shape most of the view. Look again: what first seems level is only level beside something steeper. |
| `isolde_where_1` | Stone and packed ground dominate | Stone and packed ground cover most of this place. There is very little soft earth to hide a mark or blur an edge. |
### Sela

Sela is warm, relaxed and wry. She sounds like one traveller helping another, with no ceremony and
no autobiography where practical advice should be.

| Page | World cue | Revised clue |
|---|---|---|
| `sela_where_0` | Plentiful water | There is plenty of water along the route. You can choose a crossing instead of saving every drop for later. |
| `sela_where_1` | Open land and long views | You can see a long way in every direction. Nice for choosing a route; less nice if you were hoping not to be noticed. |
| `sela_where_2` | Thick plant growth | Plants grow thickly across much of the ground. Good—there is plenty of living cover here, though the going may be slower. |

## Early and middle travellers

### Bryn

Bryn is reserved and protective. Her clues are calm warnings that leave the player's decision in
their own hands.

| Page | World cue | Revised clue |
|---|---|---|
| `bryn_where_0` | Close terrain and short views | Close walls and sharp bends block long views along most paths. Watch one approach at a time, and do not assume the others are empty. |
| `bryn_where_1` | Firm, hard ground | Hard stone covers most of the ground and stays firm under a loaded step. The footing is dependable; use it. |
| `bryn_where_2` | Dense, heavy air | The air becomes unusually thick and heavy at its worst. Breathing will take more effort, so leave yourself room to stop. |

### Orsa

Orsa is welcoming and perceptive. She makes the clue feel like a shared observation rather than a
speech about hospitality.

| Page | World cue | Revised clue |
|---|---|---|
| `orsa_where_0` | Very abundant life | Plants and fresh animal tracks fill nearly every usable patch. Even recently cleared ground already shows new use; this world does not stay empty for long. |
| `orsa_where_1` | Sheltered spaces with short views | Ridges and sheltered hollows divide the land into small spaces with short views. Several have more than one way out, which is always a comfort. |
| `orsa_where_2` | Almost no moving air | The air is almost completely still, and smoke rises straight up. A sheltered fire would not trouble every nearby resting place. |

### Talin

Talin is energetic, competitive and decisive. She points out the fact, names the choice and may
challenge the player to act.

| Page | World cue | Revised clue |
|---|---|---|
| `talin_where_0` | Hard plates with clean edges | The ground breaks into hard plates with clean edges. Shallow strikes may glance away, so choose your angle. |
| `talin_where_1` | Very open approaches | Nothing here hides an approach. You will see trouble coming; deciding when to meet it is still up to you. |
| `talin_where_2` | Strong, edge-defining light | At the brightest interval, every edge stands out clearly. If you see an opening, take it before the light changes. |

### Nessa

Nessa is direct, compassionate and unsentimental. She makes hazards understandable without turning
the player into a patient or the clue into a case report.

| Page | World cue | Revised clue |
|---|---|---|
| `nessa_where_0` | Toxic air | The air leaves a bitter taste after the first breath. That means exposure has already begun, even if the smell still seems faint. |
| `nessa_where_1` | Abundant life in a toxic world | Plants grow densely, and animal signs are everywhere. Life is thriving here; some creatures may also be better adapted to the poison than you are. |
| `nessa_where_2` | Plentiful water of unknown safety | There is plenty of water here, but abundance does not make it safe to drink. Test it before you trust it. |
| `nessa_where_3` | Ground that reacts to moisture | Much of the exposed ground changes colour, vents or shifts when it gets wet. Until we know which reactions are harmful, keep your distance. |

### Corrin

Corrin is grounded, patient and firm. Her practical attention makes the world feel tangible without
turning every clue into a lesson about materials.

| Page | World cue | Revised clue |
|---|---|---|
| `corrin_where_0` | Fast production of new growth | Fresh shoots stand beside old cuts and feeding marks. This world is producing new growth quickly, so several ages of growth are visible at once. |
| `corrin_where_1` | A deep, active food chain | Feeding marks, predator tracks and scavenger trails overlap in the same patches. A whole food chain is active here, not just one useful species. |
| `corrin_where_2` | Strong moving air | Strong winds bend broad leaves and flexible stems again and again. Watch what springs back; repeated strain tells you more than one gust. |
| `corrin_where_3` | Water spread across most routes | Films, puddles and shallow crossings cover nearly every route. Anything carried close to the ground will stay wet for most of the journey. |

### Dagg

Dagg is exuberant, brave and honest about his own mistakes. His reactions are open and his advice
gets simpler when the danger is real.

| Page | World cue | Revised clue |
|---|---|---|
| `dagg_where_0` | Very hard ground | The ground is hard and unyielding under every step. Good. At least this world tells you exactly what will happen when you hit it. |
| `dagg_where_1` | Steep climbs and hidden drops | Steep climbs and sudden drops break up most routes, and many landings are hidden from above. Slow down—the ground will not arrive sooner because you rushed. |
| `dagg_where_2` | Conditions that swing between calm and extreme | Conditions swing from long quiet stretches to sudden extremes. Prepare for both; the calm is part of the pattern. |
| `dagg_where_3` | Strong gusts with still intervals | Strong gusts tear through the world, then fall still without warning. Use the still intervals. Yes, I can be patient when it matters. |

### Rook

Rook is watchful, restrained and fair. Their clues are spare warnings, not philosophical tests.

| Page | World cue | Revised clue |
|---|---|---|
| `rook_where_0` | Extremely open land | The land is so open that an approaching creature should be visible from far away. You will have warning, if you keep watch. |
| `rook_where_1` | Almost completely flat land | The ground is almost flat, with no rise high enough to hide what is coming. Keep your eyes up; surprise has fewer places to stand. |
| `rook_where_2` | Broad bodies of standing water | Most water sits in broad lakes and pools instead of running through narrow channels. Plan to go around each one or commit to the crossing. |
| `rook_where_3` | Almost no moving air | The air is still enough that even grass tips hold their place. A small disturbance will show at a distance. |

### Lys

Lys is enthusiastic and intellectually playful. She can enjoy a pattern without asking the player
to decode an archival metaphor.

| Page | World cue | Revised clue |
|---|---|---|
| `lys_where_0` | Ruined and repeatedly rebuilt terrain | Ruined walls, old foundations and worked stone have been broken and rebuilt across the ground. More than one period of construction is still visible. |
| `lys_where_1` | Highly regular world changes | Light, weather and other changes return on a reliable schedule. Once you have watched one full cycle, you can compare the next against it. |
| `lys_where_2` | Light that never fully disappears | The light never disappears completely. Even at the darkest interval, marks and paths should remain visible. |
| `lys_where_3` | Almost no moving air | The air is so still that a loose page would remain open to the same line. Any new movement should be easy to notice. |

## Later specialists and fighters

### Bracken

Bracken is gruff, dependable and quietly tender. He gives plain warnings and reassurances without
making the landscape wear a suit of armour in every sentence.

| Page | World cue | Revised clue |
|---|---|---|
| `bracken_where_0` | Extremely hard ground | The ground is extremely hard; a tool may skid before it bites. Keep a firm grip and expect the impact to travel back through your hands. |
| `bracken_where_1` | Strong heat | At the hottest interval, metal fittings and other rigid pieces will expand. Leave them room, or the weakest point will split. |
| `bracken_where_2` | Strong cold | At the coldest interval, fittings contract and joints tighten. Check anything meant to move before you rely on it. |
| `bracken_where_3` | Steep ledges and slopes | Steep ledges and sloping routes keep shifting your weight. Gear that feels fine on level ground may catch or slide here. |
| `bracken_where_4` | Dense, heavy air | The air grows dense enough to press into every gap. If a strap, seal or seam is weak, you will feel it quickly. |

### Fen

Fen is calm, laconic and quietly mischievous. They say enough to make the clue useful, then stop.

| Page | World cue | Revised clue |
|---|---|---|
| `fen_where_0` | Extremely open land | The land is open almost all the way to the horizon. Nothing nearby would interrupt a long shot. |
| `fen_where_1` | Strong moving air | The wind is strong enough to bow a drawn string sideways. Account for it. |
| `fen_where_2` | Living growth gathered into separate stands | Living growth gathers in a few separate stands, with broad clear gaps between them. The open lanes run a long way. |
| `fen_where_3` | Water concentrated in a few large bodies | Water gathers in a few large bodies instead of many small channels. Their edges are easy to see and plan around from a distance. |
| `fen_where_4` | Highly regular world changes | Light, wind and other conditions repeat on a reliable schedule. Wait for the same interval and you can make a fair comparison. |

### Wren

Wren is quick, charming and restless. His humour can lighten a clue, but it never makes the player
chase the useful information through verbal feints.

| Page | World cue | Revised clue |
|---|---|---|
| `wren_where_0` | Very open land | The ground is open enough to keep several routes in sight at once. Choose one, but remember where the others went. |
| `wren_where_1` | Strong, shifting wind | Strong winds shift direction before the last gust has finished. Keep more than one route open; the best one may change while you are moving. |
| `wren_where_2` | Water spread across most routes | Shallow water cuts across nearly every route. You can cross it, but every crossing takes attention. Tedious little toll. |
| `wren_where_3` | Dense plant growth | Dense growth covers nearly every patch of ground, including places that look recently cleared. Mark your return route; open paths will be easy to lose. |
| `wren_where_4` | Conditions that swing between calm and extreme | The same ground feels different when conditions swing from calm to extreme. A route that works in the quiet may fail during the rush, so keep another option. |

### Kestrel

Kestrel is patient, unsentimental and careful about evidence. She distinguishes observation from
inference without making the clue sound like a report.

| Page | World cue | Revised clue |
|---|---|---|
| `kestrel_where_0` | Fast production of new growth | Fresh shoots grow beneath older feeding marks. The plants are recovering quickly enough to support repeated grazing. |
| `kestrel_where_1` | Very abundant life | Many different tracks cross this ground. One creature cannot explain all of them, so do not settle on the first tidy story. |
| `kestrel_where_2` | A deep, active food chain | Grazing trails overlap with predator tracks, and scavengers follow both. Several layers of the food chain are active here. |
| `kestrel_where_3` | Close terrain and short views | Close ridges, walls and bends hide the ground beyond them. Not seeing a creature past the turn does not mean it has gone. |
| `kestrel_where_4` | Very clear air | Fine tracks and small disturbances remain visible at a distance. Good for spotting evidence; not the same as understanding it. |

### Maud

Maud is candid, sharp and fair. She may challenge a first assumption, but she never makes the
player guess what she actually observed.

| Page | World cue | Revised clue |
|---|---|---|
| `maud_where_0` | Hard ground | Much of the ground is hard enough to hold a sharp edge instead of crumbling. Useful, provided you choose the right shape for the job. |
| `maud_where_1` | Ground that can be reshaped | Other parts bend and keep the new shape rather than springing back or breaking. Good material for pieces that need to be adjusted. |
| `maud_where_2` | Steep climbs and ledges | Steep climbs, drops and ledges change your reach from one step to the next. A weapon that feels long on one ledge may feel short on the next. |
| `maud_where_3` | Almost no moving air | The air is almost completely still. A balance test here will not be disturbed by wind, which saves us one excuse. |
| `maud_where_4` | Highly regular world changes | Light and weather return on a reliable schedule. Test an alteration at the same interval and you can judge the change fairly. |

### Marrick

Marrick is organised, consultative and responsible. He helps a group share useful information
without turning every observation into a briefing.

| Page | World cue | Revised clue |
|---|---|---|
| `marrick_where_0` | Firm, hard ground | The ground is hard enough to hold firm beneath several people at once. If the route allows it, a group can move without each step shifting under them. |
| `marrick_where_1` | Moderately open land | The land is open enough to keep a group in sight, but not so open that every signal is lost in distance. A useful middle ground. |
| `marrick_where_2` | Strong moving air | Strong wind reaches everyone across the open ground. Exposure is shared, but the effort will not be equal; check who is tiring first. |
| `marrick_where_3` | Very little temperature change | Temperature changes very little between intervals. That gives the whole group one less condition to adjust to. |
| `marrick_where_4` | Highly regular world changes | Light, weather and other conditions return on a reliable schedule. A group can practise against the same timing and know what changed. |
| `marrick_where_5` | Plentiful water | There is plenty of water along the route. No one person needs to carry the whole group's supply. Let us keep it that way. |

## Late travellers

### Sabine

Sabine is animated, affectionate and fiercely protective of choice. Her delight may be vivid, but
every animal or habitat clue remains understandable on its own.

| Page | World cue | Revised clue |
|---|---|---|
| `sabine_where_0` | Fast production of new growth | New shoots rise beside older feeding marks. Oh, that is lovely—the plants are recovering fast enough to support repeated grazing. |
| `sabine_where_1` | Extremely abundant animal life | Every shelter shows fresh tracks, and more tracks turn away at the entrances. This world is crowded with animals; we should not expect every one to make room for us. |
| `sabine_where_2` | A deep, active food chain | Small grazers feed in the new growth, larger tracks circle them, and scavengers follow the remains. Disturb one route here and several others may change. |
| `sabine_where_3` | Animal life gathered into a few places | The same hollows are pressed flat each night while nearby ground goes untouched. Animals are returning to a few favoured resting places. |
| `sabine_where_4` | Plentiful water | Hoofprints, paws and dragging tails reach the water from different banks. There are enough approaches that animals can drink without crowding the same path. |
| `sabine_where_5` | A balance of open ground and cover | There is open ground for a careful approach and nearby cover for a creature that wants distance. Good. Choice needs more than one safe place. |
| `sabine_where_6` | Highly regular world changes | The same calls begin at the same time, and the same paths fill soon after. Animals here follow a reliable routine; learn it without assuming they will welcome you into it. |

### Grimmond

Grimmond is dour, reliable and protective. He names what worries him, gives the safer interpretation
and occasionally permits himself a grim joke.

| Page | World cue | Revised clue |
|---|---|---|
| `grimmond_where_0` | Very low light | Even at its brightest, the lower rock faces remain hard to read. Do not inspect what you cannot see well enough to trust. |
| `grimmond_where_1` | Stone and packed earth dominate | Stone and packed earth make up almost all of this place. The material between valuable seams is still holding the ground together. Treat it accordingly. |
| `grimmond_where_2` | Material concentrated in a narrow seam | The richest material lies in a narrow seam. Easy to follow. Stopping before you weaken the ground is the harder part. |
| `grimmond_where_3` | Hard ground around useful seams | Hard stone surrounds each useful seam and carries the weight above it. Removing the valuable material will change that support. |
| `grimmond_where_4` | Close walls and blocked routes | Walls and close turns block one route after another. Any opening you cut here will leave less material holding somewhere else. Cheery place. |
| `grimmond_where_5` | Deep drops, high faces and steep shafts | Deep drops, high faces and steep shafts divide the ground. Every route has weight above it and open space below; mind both. |
| `grimmond_where_6` | Thin air | The air is thin enough that breathing becomes difficult before the stone gives way. If your body starts paying for the plan, stop. |

### Oda

Oda is earnest, literal and direct. She uses technical language only when ordinary words would make
a dangerous condition less precise.

| Page | World cue | Revised clue |
|---|---|---|
| `oda_where_0` | Ground that holds its shape under force | Much of the ground holds its shape under pressure. It could support a fixed housing without shifting beneath it. |
| `oda_where_1` | Ground that reacts to pressure | Other areas shift, vent or change shape when pressure is applied. Do not call the ground stable until you know where that reaction travels. |
| `oda_where_2` | Close walls and narrow passages | Close walls and narrow passages enclose most routes. Sound stays nearby and returns as echoes instead of carrying away. |
| `oda_where_3` | Almost no moving air | The air is almost completely still. Anything released into it will remain near the point of release. That is useful information, not reassurance. |
| `oda_where_4` | Toxic air that lingers | A harmful trace remains in the air after its visible source is gone. If you cannot see the source, the danger has not ended. |
| `oda_where_5` | Strong heat | At the hottest interval, heat gathers around joints and enclosed spaces. Check the first place that becomes painful; it may be where the design is failing. |
| `oda_where_6` | Light that never fully disappears | Some light remains between the brightest intervals instead of disappearing completely. The world never becomes fully dark. |
| `oda_where_7` | Highly regular world changes | Light, weather and other changes return on a reliable schedule. Repeat a test at the same interval and you can tell a stable result from luck. |

### Auber

Auber is polished, hospitable and sensory without becoming ornate. A useful detail may make the clue
vivid, but never obscure it.

| Page | World cue | Revised clue |
|---|---|---|
| `auber_where_0` | Salty water | When the water dries, it leaves the same white mineral crust along every shore. The salt is not confined to one pool. |
| `auber_where_1` | Water gathered into separate bodies | Water gathers in separate, well-defined bodies instead of spreading through the ground. Each has a clear edge, which makes them easier to compare. |
| `auber_where_2` | Broad bodies of standing water | Most water rests in broad, still pools long enough for sediment to settle. Give it time and some of what it carries will separate on its own. |
| `auber_where_3` | Large changes between heat and cold | This world swings between deep cold and strong heat. The change will move different parts of a mixture at different times, so one interval is not enough. |
| `auber_where_4` | Ground that reacts to heat or water | Much of the ground changes colour, shape or state when heated or wet. Any vessel set here must withstand the same reaction. |
| `auber_where_5` | Material concentrated in narrow seams | Useful material is concentrated in narrow seams. Careful work can take what is needed without tearing through all the ground around it. |
| `auber_where_6` | Haze or vapour that obscures distance | Vapour obscures the farther ground while nearby shapes remain clear. What disappears into the haze has not necessarily left the area. |
| `auber_where_7` | Conditions that change sharply | Conditions change sharply from one interval to the next. A mixture prepared here may behave differently each time; repetition alone will not make the result pure. |

### Ashe

Ashe is warm, candid and unwilling to minimise danger. Bodily observations appear only when they
give the player useful information.

| Page | World cue | Revised clue |
|---|---|---|
| `ashe_where_0` | Heat rising from the ground | Heat rises through the ground before the sky changes. You may feel it through your feet first, so treat warmth below you as an early warning. |
| `ashe_where_1` | Large changes between heat and cold | The world swings sharply between heat and cold. Your body may feel the change before an instrument finishes recording it; listen to both. |
| `ashe_where_2` | Light with no visible source | Light remains even though no sun, lamp or other source is visible. The illumination is real; its cause is still unknown. |
| `ashe_where_3` | Ground that reacts to pressure | The ground shifts, cracks or changes shape when pressure is applied. A surface can react without being safe to stand on. |
| `ashe_where_4` | Toxic air that lingers | A harmful trace remains in each breath after its visible cause disappears. Do not wait for a dramatic sign before leaving it. |
| `ashe_where_5` | Strong moving air | Moving air carries the effect from more than one direction. You cannot face every source at once, so limit how long you stay exposed. |
| `ashe_where_6` | New growth produced under harsh conditions | New growth continues to appear despite the harsh conditions. That proves life can grow here; it does not prove the conditions are harmless. |
| `ashe_where_7` | Conditions that swing between mild and extreme | Heat, light, wind and other conditions swing between mild and extreme. Even when the worst interval is predictable, enduring it still takes a toll. |

### Tovin

Tovin is earnest, anxious and increasingly direct. A moment of hesitation may sound like him, but
the world information always remains clear.

| Page | World cue | Revised clue |
|---|---|---|
| `tovin_where_0` | Very low light | Even at its brightest, this world remains very dark. Move slowly; darkness does not make obstacles disappear. |
| `tovin_where_1` | Fungal growth | Fungal growth spreads without sunlight and covers much of the dark ground. It does not need the brighter intervals to thrive. |
| `tovin_where_2` | Stone and packed earth dominate | Stone and packed earth dominate the world, from the ground underfoot to the walls around it. There is very little soft earth. |
| `tovin_where_3` | Close terrain and short views | Everything is close: walls, turns, the next obstruction. I do not like it. Keep track of the way back. |
| `tovin_where_4` | Salty water | Wherever the water withdraws, it leaves a white mineral line. There is a great deal of salt in it. |
| `tovin_where_5` | Persistent cold | Even the mildest interval stays bitterly cold. Do not wait for a warmer cycle; it is not coming. |
| `tovin_where_6` | Almost no moving air | The air is almost completely still. Even the loose corner of this page does not move. |
| `tovin_where_7` | Highly regular world changes | Every interval arrives on the same reliable schedule. Once you know the pattern, you can plan around it. |

### Perren

Perren is charismatic, rhetorical and skeptical of easy certainty. He may question an inference
after naming the observable fact, never instead of naming it.

| Page | World cue | Revised clue |
|---|---|---|
| `perren_where_0` | Strong light and deep shadow together | Bright light and deep shadow sit side by side across this world. That contrast is a real condition; it does not tell us which side is the truer one. |
| `perren_where_1` | Heat and cold together | Heat and cold press into the same interval. Both are present, and choosing only one would hide half the condition. |
| `perren_where_2` | Dense growth and suppression together | Dense growth and bare, suppressed patches appear together. The empty ground was shaped by what grows beside it; it was not always empty by default. |
| `perren_where_3` | Ruined and repeatedly rebuilt terrain | Ruined walls and repeatedly broken structures cover the ground. One period of building has been laid directly over another. |
| `perren_where_4` | Close walls and narrow corridors | Close walls and narrow corridors restrict both sight and travel. When a route offers only one visible choice, ask what the walls have hidden. |
| `perren_where_5` | Material spread widely and evenly | The same worked material is spread widely and evenly. A sample from one place may match another, but choose from more than one before calling it representative. |
| `perren_where_6` | Haze that obscures distance | Haze hides distant ground while nearby objects remain clear. It removes context before it removes the thing itself, so do not judge the far shape alone. |
| `perren_where_7` | Highly regular world changes | The same interval returns on a reliable schedule. Once the pattern is known, an expected event is evidence of repetition—not a revelation. |
| `perren_where_8` | Salty water | Retreating water leaves a bright white mineral line along every bank. The line shows where the water has been, not where it must return. |

### Nine

Nine is gentle, curious and capable of direct answers. Their unusual associations appear only after
the player has received the useful world fact.

| Page | World cue | Revised clue |
|---|---|---|
| `nine_where_0` | Highly irregular world changes | The next interval rarely arrives when the last one suggests it should. Plan for change rather than relying on a schedule. |
| `nine_where_1` | Conditions that change dramatically | The world changes dramatically from one interval to the next. Record both states; neither one describes the whole place alone. |
| `nine_where_2` | Light with no visible source | A little light remains without any visible source. We can use what it shows even before we understand where it comes from. |
| `nine_where_3` | Very little temperature change | Temperature stays within a narrow range even while other conditions change. It is a reliable reference point in an otherwise changing world. |
| `nine_where_4` | Water spread across most routes | Water reaches nearly every route in films, puddles and shallow crossings. Use its wide spread as a landmark, not any single shoreline. |
| `nine_where_5` | Material spread widely and evenly | The same material is spread widely and evenly across the world. If the surface changes, that familiar distribution can still help you recognise where you are. |
| `nine_where_6` | Moderately open land | The land is neither cramped nor completely open. A clear horizon stays within visible bounds, which is enough to check your position without losing nearby detail. |
| `nine_where_7` | Fast production of new growth | New growth stands beside older damage. The world is producing life again without hiding what happened before. |
| `nine_where_8` | Almost no moving air | The air is so still that a loose marker remains where it was placed. If it moves, something nearby moved it. |

## Integration acceptance

After Engineering updates the catalogue:

1. The catalogue still contains exactly 29 travellers and 137 signature conditions, with exactly
   137 matching `locationClue` pages after the one Tovin page is reclassified.
2. Every traveller's ordered self-clue prose exactly matches the corresponding ordered signature
   passage.
3. `tovin_about_isolde` retains its stable page ID, Tovin as its diary owner and Isolde as its
   subject; its kind becomes `whereabouts` and its obsolete `clueIndex` is removed.
4. All other stable page IDs, owners, subjects, clue indices, conditions, preferences, teachings and
   rewards are byte-for-byte unchanged.
5. Existing saves decode recovered page IDs without migration or loss.
6. A recovered clue displays the exact revised text in the Library, People book and any Field Notes
   replay that reads the catalogue.
7. Traveller eligibility and deterministic world placement are unchanged when the same world and
   save are evaluated before and after this prose-only update.
8. No clue reveals an internal threshold, a required sigil or an undiscovered world identity.
