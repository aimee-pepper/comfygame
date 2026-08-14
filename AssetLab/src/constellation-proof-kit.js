export const constellationProofVersion = "constellation-proof-0.1.0";
export const constellationNode = Object.freeze({
  id: "extra_gambit_slot",
  name: "The Long Instruction",
  icon: "list.number",
  effect: "Adds one Gambit rule slot to every current and future person in this campaign.",
  maxRank: 1,
  costs: Object.freeze([3]),
});
export const constellationRealityExplanation = "The Constellation changes Reality itself, rather than one building or one person.";

function exact(request, keys) {
  if (!request || typeof request !== "object" || Array.isArray(request)) throw new Error("invalid-constellation-request");
  if (JSON.stringify(Object.keys(request).sort()) !== JSON.stringify([...keys].sort())) throw new Error("invalid-constellation-fields");
}
function stateInput(request, keys) {
  exact(request, keys);
  if (!Number.isSafeInteger(request.rank) || ![0, 1].includes(request.rank) || !Number.isSafeInteger(request.motes) || request.motes < 0) throw new Error("invalid-constellation-state");
}
const frozenPair = (rank, motes) => Object.freeze({ rank, motes });

export function constellationState(request) {
  stateInput(request, ["rank", "motes"]);
  if (request.rank === 1) return Object.freeze({ state: "bought", rank: "1/1", action: null });
  const missing = Math.max(0, constellationNode.costs[0] - request.motes);
  return Object.freeze({ state: missing ? "shortfall" : "affordable", rank: "0/1", action: missing ? null : "Fix in place", missing });
}

export function previewConstellationPurchase(request) {
  stateInput(request, ["rank", "motes", "expectedRevision", "currentRevision"]);
  if (!Number.isSafeInteger(request.expectedRevision) || request.expectedRevision < 0 || !Number.isSafeInteger(request.currentRevision) || request.currentRevision < 0) throw new Error("invalid-constellation-preview");
  const before = frozenPair(request.rank, request.motes);
  if (request.rank === 1) return Object.freeze({ ok: false, reason: "already-bought", before, after: before });
  if (request.expectedRevision !== request.currentRevision) return Object.freeze({ ok: false, reason: "stale", before, after: before });
  if (request.motes < constellationNode.costs[0]) return Object.freeze({ ok: false, reason: "insufficient-motes", before, after: before });
  return Object.freeze({ ok: true, reason: "preview", before, after: frozenPair(1, request.motes - constellationNode.costs[0]) });
}
