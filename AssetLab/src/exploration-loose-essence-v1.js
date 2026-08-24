const FRAME_COUNT = 4;
const KEY_PREFIX = "loose_essence/ordinary/frame-";

function isNonnegativeSafeInteger(value) {
  return Number.isSafeInteger(value) && value >= 0;
}

/**
 * Pure conformance seam for the native Loose Raw Essence resolver.
 *
 * Only content identity, positive eligibility, current disclosure and the shared
 * presentation tick own selection. Extra metadata is intentionally ignored: it
 * must never become a coordinate-, seed-, run- or per-tile phase selector.
 */
export function resolveLooseEssenceStableKey(request) {
  const content = request?.content;
  if (
    content?.kind !== "wildDrop" ||
    content.resourceID !== "essence_raw" ||
    !Number.isSafeInteger(content.amount) ||
    content.amount <= 0
  ) return null;

  if (request.visibility === "full") {
    if (!isNonnegativeSafeInteger(request.presentationTick)) return null;
    return `${KEY_PREFIX}${request.presentationTick % FRAME_COUNT}`;
  }

  if (
    (request.visibility === "fringe" || request.visibility === "hidden") &&
    request.previouslyRevealed === true
  ) return `${KEY_PREFIX}0`;

  return null;
}

export const looseEssenceConsumerContract = Object.freeze({
  resourceID: "essence_raw",
  keyPrefix: KEY_PREFIX,
  frameCount: FRAME_COUNT,
  temporalSelector: "presentationTick-only",
  mapCanvas: Object.freeze([16, 19]),
  mapPivot: Object.freeze([8, 18]),
  layerOrder: Object.freeze([
    "terrain-and-south-wall",
    "stationary-loose-essence",
    "party",
    "selection-and-interaction",
    "alerts-and-HUD",
  ]),
  minimapKey: null,
  recolor: false,
  gameplayMutation: false,
});
