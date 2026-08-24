export const miningFeedbackContract = Object.freeze({
  schemaVersion: "resource-mining-feedback-v1",
  trigger: "newly-accepted-world-field-event-batch-v1/harvest/positive-harvested-event",
  sourceProfile: "resource-sprites-v1/field/8x8",
  committedBeforePresentation: true,
  oneSubjectPerDistinctResource: true,
  repeatedResourcePolicy: "sum-positive-amounts-first-occurrence-order",
  missingIdentityPolicy: "omit-subject-no-substitution",
  queuePolicy: "unique-batch-fifo-while-owning-world-remains-active",
  duplicatePolicy: "same-batch-id-never-replays",
  interruptionPolicy: "dismiss-or-expiry-advances-fifo;world-owner-exit-clears-all;no-gameplay-mutation-or-replay",
  relaunchPolicy: "persisted-counts-only-no-presentation-replay",
  amountPresentation: "one-exact-field-identity-plus-exact-total-label",
  clutterPolicy: "never-create-one-particle-per-unit",
  forbiddenImplications: [
    "delayed-resource-commit", "completion-increment", "tool-damage", "extraction-rank",
    "bonus-yield", "second-strike", "second-turn", "substitute-resource-art",
  ],
});

export const motionContract = Object.freeze({
  durationMS: 760,
  orderedSubjectStaggerMS: 130,
  startScale: 2,
  restScale: 1,
  path: "deterministic-quadratic-arc",
  origin: "selected-harvest-cell-centre",
  destination: "matching-existing-toolbar-identity-centre",
  end: "travelling-copy-removed-destination-acknowledged",
});

const batchFields = [
  "attemptID", "batchID", "createdAtMonotonicTime", "orderedEvents", "orderedNarrations",
  "sourceAction", "turnAfter", "turnBefore", "worldRunID",
].sort();

function exactObject(value, fields, error) {
  if (!value || typeof value !== "object" || Array.isArray(value)
    || Object.keys(value).sort().join("\u0000") !== [...fields].sort().join("\u0000")) {
    throw new Error(error);
  }
}

function safeNonnegative(value, error) {
  if (!Number.isSafeInteger(value) || value < 0) throw new Error(error);
}

export function normalizeWorldFieldBatch(raw) {
  exactObject(raw, batchFields, "invalid-world-field-batch-fields");
  if (typeof raw.batchID !== "string" || !raw.batchID
    || typeof raw.worldRunID !== "string" || !raw.worldRunID
    || typeof raw.sourceAction !== "string") throw new Error("invalid-world-field-batch-identity");
  safeNonnegative(raw.attemptID, "invalid-attempt-id");
  safeNonnegative(raw.turnBefore, "invalid-turn-before");
  safeNonnegative(raw.turnAfter, "invalid-turn-after");
  safeNonnegative(raw.createdAtMonotonicTime, "invalid-created-time");
  if (!Array.isArray(raw.orderedEvents) || !Array.isArray(raw.orderedNarrations)
    || !raw.orderedNarrations.every(value => typeof value === "string")) {
    throw new Error("invalid-world-field-batch-events");
  }
  return structuredClone(raw);
}

export function committedHarvestGroup(rawBatch, exactFieldIdentityIDs) {
  const batch = normalizeWorldFieldBatch(rawBatch);
  const exactIDs = exactFieldIdentityIDs instanceof Set
    ? exactFieldIdentityIDs : new Set(exactFieldIdentityIDs);
  if (batch.sourceAction !== "harvest") return null;
  const totals = new Map();
  let positiveHarvestEventCount = 0;
  for (const event of batch.orderedEvents) {
    if (!event || typeof event !== "object" || event.kind !== "harvested") continue;
    if (typeof event.resourceID !== "string" || !event.resourceID
      || !Number.isSafeInteger(event.amount) || event.amount <= 0
      || typeof event.exhausted !== "boolean") continue;
    positiveHarvestEventCount += 1;
    if (!totals.has(event.resourceID)) totals.set(event.resourceID, 0);
    totals.set(event.resourceID, totals.get(event.resourceID) + event.amount);
  }
  if (positiveHarvestEventCount === 0) return null;
  const subjects = [], omittedSubjects = [];
  for (const [resourceID, amount] of totals) {
    const subject = {resourceID, amount, profile: "field", logicalSize: 8};
    if (exactIDs.has(resourceID)) subjects.push(subject);
    else omittedSubjects.push({...subject, omission: "missing-exact-field-identity"});
  }
  return {
    batchID: batch.batchID,
    attemptID: batch.attemptID,
    worldRunID: batch.worldRunID,
    turnBefore: batch.turnBefore,
    turnAfter: batch.turnAfter,
    subjects,
    omittedSubjects,
    positiveHarvestEventCount,
    countOwnership: "already-committed-before-first-frame",
  };
}

export function emptyPresentationSession(worldRunID, committedCounts = {}) {
  if (typeof worldRunID !== "string" || !worldRunID) throw new Error("invalid-active-world-run");
  return {worldRunID, committedCounts: structuredClone(committedCounts), seenBatchIDs: [], current: null, queue: []};
}

export function deliverCommittedBatch(session, batch, exactFieldIdentityIDs) {
  const next = structuredClone(session);
  if (next.seenBatchIDs.includes(batch?.batchID)) return next;
  const group = committedHarvestGroup(batch, exactFieldIdentityIDs);
  if (!group || group.worldRunID !== next.worldRunID) return next;
  next.seenBatchIDs.push(group.batchID);
  if (group.subjects.length === 0) return next;
  if (next.current === null) next.current = group;
  else next.queue.push(group);
  return next;
}

export function finishCurrentPresentation(session) {
  const next = structuredClone(session);
  next.current = next.queue.shift() ?? null;
  return next;
}

export function cancelMiningPresentation(session, reason) {
  if (!["dismiss", "expiry", "navigation", "encounter", "return-home", "run-change"].includes(reason)) {
    throw new Error("invalid-mining-cancellation-reason");
  }
  if (reason === "dismiss" || reason === "expiry") return finishCurrentPresentation(session);
  const next = structuredClone(session); next.current = null; next.queue = []; return next;
}

export function coldRelaunchSession(worldRunID, committedCounts) {
  return emptyPresentationSession(worldRunID, committedCounts);
}

export function subjectProgress(groupProgress, subjectIndex, subjectCount) {
  if (!Number.isFinite(groupProgress) || groupProgress < 0 || groupProgress > 1) {
    throw new Error("invalid-group-progress");
  }
  safeNonnegative(subjectIndex, "invalid-subject-index");
  if (!Number.isSafeInteger(subjectCount) || subjectCount < 1 || subjectIndex >= subjectCount) {
    throw new Error("invalid-subject-count");
  }
  const staggerFraction = subjectCount === 1 ? 0 : Math.min(.28, subjectIndex * .16);
  return Math.max(0, Math.min(1, (groupProgress - staggerFraction) / (1 - staggerFraction)));
}

export function motionSample({source, destination, groupProgress, subjectIndex = 0, subjectCount = 1}) {
  for (const point of [source, destination]) {
    if (!point || !Number.isFinite(point.x) || !Number.isFinite(point.y)) throw new Error("invalid-motion-point");
  }
  const t = subjectProgress(groupProgress, subjectIndex, subjectCount);
  const one = 1 - t;
  const control = {
    x: source.x + (destination.x - source.x) * .42,
    y: Math.min(source.y, destination.y) - 54 - subjectIndex * 8,
  };
  return {
    x: one * one * source.x + 2 * one * t * control.x + t * t * destination.x,
    y: one * one * source.y + 2 * one * t * control.y + t * t * destination.y,
    scale: motionContract.startScale + (motionContract.restScale - motionContract.startScale) * t,
    opacity: t >= 1 ? 0 : Math.min(1, t * 5 + .55),
    acknowledged: t >= 1,
  };
}

function batch({batchID, attemptID, events, narrations = [], sourceAction = "harvest", turnBefore = 12, turnAfter = 13}) {
  return {
    batchID, worldRunID: "world-run-mining-proof", attemptID, sourceAction, turnBefore, turnAfter,
    orderedEvents: events, orderedNarrations: narrations, createdAtMonotonicTime: 1_000 + attemptID,
  };
}

const harvested = (resourceID, amount, exhausted = false) => ({kind: "harvested", resourceID, amount, exhausted});
const blocked = reason => ({kind: "blocked", reason});

export const proofFixtures = Object.freeze({
  M01: {label: "one primary", counts: {ore: 12}, batch: batch({batchID: "mining-m01", attemptID: 1, events: [harvested("ore", 3)], narrations:["Harvested 3 iron ore."]})},
  M02: {label: "primary + secondary", counts: {timber: 14, resin: 3}, batch: batch({batchID: "mining-m02", attemptID: 2, events: [harvested("timber", 5), harvested("resin", 2)], narrations:["Harvested 5 timber.","Harvested 2 resin."]})},
  M03: {label: "same identity coalesced", counts: {ore: 17}, batch: batch({batchID: "mining-m03", attemptID: 3, events: [harvested("ore", 3), harvested("ore", 2)], narrations:["Harvested 3 iron ore.","Harvested 2 iron ore."]})},
  M04: {label: "final pull", counts: {quartz: 9}, batch: batch({batchID: "mining-m04", attemptID: 4, events: [harvested("quartz", 1, true)], narrations:["Harvested 1 quartz. This deposit is depleted."]})},
  M05: {label: "refused / no yield", counts: {ore: 9}, batch: batch({batchID: "mining-m05", attemptID: 5, events: [blocked("Nothing here to harvest.")], narrations:["Nothing here to harvest."]})},
  M06a: {label: "FIFO first", counts: {ore: 12, quartz: 9}, batch: batch({batchID: "mining-m06-a", attemptID: 6, events: [harvested("ore", 3)], narrations:["Harvested 3 iron ore."]})},
  M06b: {label: "FIFO second", counts: {ore: 12, quartz: 9}, batch: batch({batchID: "mining-m06-b", attemptID: 7, events: [harvested("quartz", 1)], narrations:["Harvested 1 quartz."], turnBefore: 13, turnAfter: 14})},
  M07: {label: "count committed at frame one", counts: {ore: 12}, batch: batch({batchID: "mining-m07", attemptID: 8, events: [harvested("ore", 3)], narrations:["Harvested 3 iron ore."]})},
  M08: {label: "interrupted presentation", counts: {ore: 12}, batch: batch({batchID: "mining-m08", attemptID: 9, events: [harvested("ore", 3)], narrations:["Harvested 3 iron ore."]})},
  M09: {label: "cold relaunch", counts: {ore: 12}, batch: null},
  M10: {label: "missing exact identity", counts: {future_resource: 1}, batch: batch({batchID: "mining-m10", attemptID: 10, events: [harvested("future_resource", 1)], narrations:["Harvested 1 something."]})},
});
