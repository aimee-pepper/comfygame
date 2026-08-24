export const travellerSpeechContract = Object.freeze({
  schemaVersion: "traveller-adjacent-speech-v1",
  sourceReceipt: "build-time-effective-traveller-meeting-corpus",
  trigger: "accepted-step-or-auto-travel-final-presented-state-new-cardinal-adjacency",
  visibility: "full-revealed-intact-exact-traveller-only",
  sameTileOwner: "TravellerMeetingView",
  queueOrder: ["north", "east", "south", "west"],
  sessionScope: "transient-shown-traveller-ids-per-loaded-world-run",
  interaction: "noninteractive-hit-test-transparent",
  mutation: "none",
  integrationReady: false,
});

export const bubbleVisualTokens = Object.freeze({
  maxWidth: 284,
  minimumWidth: 176,
  edgeInset: 8,
  mapTop: 64,
  mapBottom: 492,
  anchorGap: 13,
  nameRole: {family: "Tiny5", size: 15, lineHeight: 16},
  speechRole: {family: "system", size: 17, lineHeight: 21},
  padding: {top: 10, right: 12, bottom: 12, left: 12},
  enterMS: 180,
  holdMS: 4_800,
  exitMS: 160,
  enterOffsetY: 6,
  fill: "#11201ff2",
  innerFill: "#1a2c29f5",
  borderDark: "#07100f",
  borderLight: "#b9cfb8",
  nameInk: "#f0cf7d",
  speechInk: "#fff7e3",
});

export const expectedSpeechRows = Object.freeze([
  ["ashe", "opening:last-direct-speech", "“That is permission for this moment, from that direction.”"],
  ["auber", "opening:last-direct-speech", "“This is the interesting half. Nobody asks to taste this one.”"],
  ["bracken", "opening:last-direct-speech", "“The wearer was less fortunate.”"],
  ["bryn", "opening:last-direct-speech", "“I'm keeping this one open until they're clear.”"],
  ["corrin", "opening:last-direct-speech", "“The shoulder that has to meet it eight hundred times is less theoretical.”"],
  ["dagg", "exchange:dagg.one_strike:first-direct-speech", "“Because I moved the slab.”"],
  ["edren", "opening:last-direct-speech", "\"Mind where you tread. There's a floor about eight inches down and I've nearly got the edge of it.\""],
  ["fen", "opening:last-direct-speech", "“It stretched. Fine for a sling, poor for a bow.”"],
  ["grimmond", "opening:last-direct-speech", "“It'll still crush you.”"],
  ["halloway", "opening:last-direct-speech", "\"Don't crowd it. It's shy.\""],
  ["isolde", "opening:last-direct-speech", "\"Don't speak for a moment. I'm nearly at the bottom.\""],
  ["kestrel", "opening:last-direct-speech", "“That is not yet the animal.”"],
  ["lys", "opening:last-direct-speech", "“Only the account of how one became the other.”"],
  ["mara", "opening:last-direct-speech", "\"Don't move. You're the first fixed point I've had in a long while.\""],
  ["marrick", "opening:last-direct-speech", "“The sixth couldn't reach their place. We kept calling that a successful formation.”"],
  ["maud", "opening:last-direct-speech", "“That is the first measurement the metal could not give me.”"],
  ["nessa", "opening:last-direct-speech", "“Different instructions. The old labels nearly made that expensive.”"],
  ["nine", "opening:last-direct-speech", "“So is the revision.”"],
  ["noll", "exchange:noll.join_left:first-direct-speech", "“I haven't finished checking why it failed.”"],
  ["oda", "opening:last-direct-speech", "“Approach corridor held. Marker four did not. Please stand exactly where you are while I determine which result matters.”"],
  ["orsa", "opening:last-direct-speech", "“I repaired it, but I don't trust its opinion of taller guests.”"],
  ["perren", "opening:last-direct-speech", "“So is the decision about which relationship the repetition is allowed to prove.”"],
  ["rook", "opening:last-direct-speech", "“It could not know what the line meant. That failure is mine.”"],
  ["sabine", "opening:last-direct-speech", "“Sorry. The twigs are doing excellent work, but they are terrible at introductions.”"],
  ["sela", "opening:last-direct-speech", "\"Oh, good. Company. Keep up.\""],
  ["talin", "opening:last-direct-speech", "“The gap closes before I can recover.”"],
  ["tovin", "opening:last-direct-speech", "\"You wrote this. I can tell by the light — it's got somebody's opinion in it.\""],
  ["vance", "opening:last-direct-speech", "“Good start. Not much of a sales pitch.”"],
  ["wren", "opening:last-direct-speech", "“They can't. So we're using their route first.”"],
].map(([travellerID, sourceKey, text]) => Object.freeze({travellerID, sourceKey, text})));

const directions = Object.freeze([
  {direction: "north", dx: 0, dy: -1},
  {direction: "east", dx: 1, dy: 0},
  {direction: "south", dx: 0, dy: 1},
  {direction: "west", dx: -1, dy: 0},
]);

const samePoint = (a, b) => a?.x === b?.x && a?.y === b?.y;
const pointKey = point => `${point.x},${point.y}`;
const cardinallyAdjacent = (a, b) => Math.abs(a.x - b.x) + Math.abs(a.y - b.y) === 1;

export function exactEligibleTraveller(tile, worldRunID) {
  return tile?.worldRunID === worldRunID
    && tile.visibility === "full"
    && tile.isRevealed === true
    && tile.isCrumbled === false
    && tile.content?.kind === "traveller"
    && typeof tile.content.travellerID === "string"
    && tile.content.travellerID.length > 0;
}

export function eligibleNewlyAdjacent({
  action, beforePlayer, afterPlayer, finalTiles, worldRunID, activeWorldRunID,
  owner = "world", activeEncounter = false, activeMeeting = false, returning = false,
  shownTravellerIDs = [], receiptTravellerIDs = [],
}) {
  if (!action || action.accepted !== true || action.finalPresented !== true
    || !["step", "auto-travel"].includes(action.kind) || action.teleportLike === true
    || owner !== "world" || activeEncounter || activeMeeting || returning
    || worldRunID !== activeWorldRunID || samePoint(beforePlayer, afterPlayer)
    || (action.kind === "step" && !cardinallyAdjacent(beforePlayer, afterPlayer))) return [];
  const tilesByPoint = new Map(finalTiles.map(tile => [pointKey(tile.point), tile]));
  const shown = new Set(shownTravellerIDs), receipted = new Set(receiptTravellerIDs);
  const result = [];
  for (const {direction, dx, dy} of directions) {
    const point = {x: afterPlayer.x + dx, y: afterPlayer.y + dy};
    const tile = tilesByPoint.get(pointKey(point));
    if (!exactEligibleTraveller(tile, worldRunID)) continue;
    const id = tile.content.travellerID;
    if (shown.has(id) || !receipted.has(id) || cardinallyAdjacent(beforePlayer, point)) continue;
    result.push({travellerID: id, direction, point: structuredClone(point), worldRunID});
  }
  return result;
}

export function emptyTravellerSpeechSession(worldRunID) {
  if (typeof worldRunID !== "string" || !worldRunID) throw new Error("invalid-world-run-id");
  return {worldRunID, shownTravellerIDs: [], current: null, queue: []};
}

function beginNext(next) {
  if (next.current !== null || next.queue.length === 0) return next;
  next.current = next.queue.shift();
  if (!next.shownTravellerIDs.includes(next.current.travellerID)) {
    next.shownTravellerIDs.push(next.current.travellerID);
  }
  return next;
}

export function enqueueNewlyAdjacent(session, eligible, speechRows) {
  const next = structuredClone(session), byID = new Map(speechRows.map(row => [row.travellerID, row]));
  const already = new Set([
    ...next.shownTravellerIDs,
    ...(next.current ? [next.current.travellerID] : []),
    ...next.queue.map(item => item.travellerID),
  ]);
  for (const candidate of eligible) {
    const source = byID.get(candidate.travellerID);
    if (!source || candidate.worldRunID !== next.worldRunID || already.has(candidate.travellerID)) continue;
    next.queue.push({...candidate, sourceKey: source.sourceKey, text: source.text});
    already.add(candidate.travellerID);
  }
  return beginNext(next);
}

export function expireTravellerBubble(session) {
  const next = structuredClone(session); next.current = null; return beginNext(next);
}

export function clearTravellerPresentation(session, reason) {
  if (!["accepted-world-action", "meeting", "encounter", "return", "navigation", "run-change",
    "traveller-removed", "traveller-crumbled", "visibility-loss"].includes(reason)) {
    throw new Error("invalid-traveller-presentation-clear-reason");
  }
  const next = structuredClone(session); next.current = null; next.queue = [];
  return next;
}

export function bubblePlacement({anchorX, anchorY, bubbleWidth, bubbleHeight, stageWidth = 368,
  mapTop = bubbleVisualTokens.mapTop, mapBottom = bubbleVisualTokens.mapBottom,
  blockedRects = []}) {
  for (const value of [anchorX, anchorY, bubbleWidth, bubbleHeight, stageWidth, mapTop, mapBottom]) {
    if (!Number.isFinite(value)) throw new Error("invalid-bubble-placement-number");
  }
  const inset = bubbleVisualTokens.edgeInset;
  const clampX = x => Math.max(inset, Math.min(stageWidth - inset - bubbleWidth, x));
  const overlaps = box => blockedRects.some(rect => box.x < rect.x + rect.width
    && box.x + box.width > rect.x && box.y < rect.y + rect.height && box.y + box.height > rect.y);
  const candidates = [
    {placement: "above", x: clampX(anchorX - bubbleWidth / 2), y: anchorY - bubbleHeight - bubbleVisualTokens.anchorGap},
    {placement: "below", x: clampX(anchorX - bubbleWidth / 2), y: anchorY + bubbleVisualTokens.anchorGap},
  ];
  let box = candidates.find(candidate => candidate.y >= mapTop && candidate.y + bubbleHeight <= mapBottom
    && !overlaps({...candidate, width: bubbleWidth, height: bubbleHeight}));
  if (!box) {
    const y = Math.max(mapTop, Math.min(mapBottom - bubbleHeight,
      anchorY < (mapTop + mapBottom) / 2 ? anchorY + bubbleVisualTokens.anchorGap
        : anchorY - bubbleHeight - bubbleVisualTokens.anchorGap));
    box = {placement: y > anchorY ? "below-clamped" : "above-clamped", x: clampX(anchorX - bubbleWidth / 2), y};
  }
  return {
    ...box,
    width: bubbleWidth,
    height: bubbleHeight,
    tailX: Math.max(12, Math.min(bubbleWidth - 12, anchorX - box.x)),
    tailDirection: box.y > anchorY ? "up" : "down",
    anchor: {x: anchorX, y: anchorY},
    hitTestTransparent: true,
  };
}

export function speechMotionSample(progress) {
  if (!Number.isFinite(progress) || progress < 0 || progress > 1) throw new Error("invalid-speech-motion-progress");
  const eased = 1 - (1 - progress) ** 3;
  return {opacity: eased, translateY: bubbleVisualTokens.enterOffsetY * (1 - eased)};
}

export const proofCensus = Object.freeze([
  ["T01", "accepted cardinal step → exact Mara bubble"],
  ["T02", "adjacent-to-adjacent movement → no repeat"],
  ["T03", "leave/re-enter same loaded run → no repeat"],
  ["T04", "blocked / Deep Water / no path / selection → none"],
  ["T05", "full intact exact traveller only"],
  ["T06", "same-tile arrival remains TravellerMeetingView-owned"],
  ["T07", "adversarial neighbours queue North / East / South / West"],
  ["T08", "expiry advances; accepted action clears; zero mutation"],
  ["T09", "encounter / return / navigation / run change cancel"],
  ["T10", "cold relaunch while adjacent → none"],
  ["T11", "auto-travel evaluates final presented position only"],
  ["T12", "29 exact source rows and fail-closed corpus gate"],
  ["T13", "Oda / Tovin complete wrap without truncation"],
  ["T14", "later full meeting and recruitment remain unchanged"],
  ["T15", "same action / corpus / run → identical output"],
].map(([id, statement]) => Object.freeze({id, statement})));
