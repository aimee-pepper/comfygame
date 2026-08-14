export const worldHistoryProofVersion = "world-history-proof-0.1.0";
export const legacyCover = Object.freeze({ schemaVersion: 0, worldVisualDescriptorVersion: "legacy-neutral", paletteFamilyID: "neutralPaper", atmosphereMarkID: null, ecologyMarkID: null });

function exact(value, keys, label) {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error(`invalid-${label}`);
  if (JSON.stringify(Object.keys(value).sort()) !== JSON.stringify([...keys].sort())) throw new Error(`invalid-${label}-fields`);
}

export function normalizeCover(value) {
  if (value == null) return legacyCover;
  exact(value, ["schemaVersion", "worldVisualDescriptorVersion", "paletteFamilyID", "atmosphereMarkID", "ecologyMarkID"], "world-cover");
  if (value.schemaVersion !== 1 || ![value.worldVisualDescriptorVersion, value.paletteFamilyID].every((field) => typeof field === "string" && field.length > 0 && field.length <= 64)) throw new Error("invalid-world-cover-value");
  for (const field of ["atmosphereMarkID", "ecologyMarkID"]) if (value[field] !== null && (typeof value[field] !== "string" || value[field].length < 1 || value[field].length > 64)) throw new Error("invalid-world-cover-mark");
  return Object.freeze({ ...value });
}

export function resolveComparison(first, second, disclosedRelations) {
  if (!disclosedRelations || typeof disclosedRelations !== "object" || Array.isArray(disclosedRelations)) throw new Error("invalid-disclosed-relations");
  for (const [key, value] of Object.entries(disclosedRelations)) if (!/^[a-z][a-z0-9_.-]{0,63}$/.test(key) || !["higher", "lower", "overlapping"].includes(value)) throw new Error("invalid-disclosed-relation");
  for (const record of [first, second]) {
    exact(record, ["id", "runIndex", "semanticRequests", "measurements"], "comparison-record");
    if (typeof record.id !== "string" || record.id.length < 1 || record.id.length > 80 || !Number.isSafeInteger(record.runIndex) || record.runIndex < 0 || !record.semanticRequests || typeof record.semanticRequests !== "object" || Array.isArray(record.semanticRequests) || !record.measurements || typeof record.measurements !== "object" || Array.isArray(record.measurements)) throw new Error("invalid-comparison-record-value");
    for (const [key, value] of Object.entries(record.semanticRequests)) if (!/^[a-z][a-z0-9_.-]{0,63}$/.test(key) || typeof value !== "string" || value.length < 1 || value.length > 120) throw new Error("invalid-semantic-request");
    for (const key of Object.keys(record.measurements)) if (!/^[a-z][a-z0-9_.-]{0,63}$/.test(key)) throw new Error("invalid-measurement-subject");
  }
  if (first.id === second.id) throw new Error("comparison-requires-two-records");
  const [earlier, later] = first.runIndex < second.runIndex ? [first, second] : [second, first];
  if (earlier.runIndex === later.runIndex) throw new Error("duplicate-run-index");
  const sharedMeasurementKeys = Object.keys(earlier.measurements).filter((key) => Object.hasOwn(later.measurements, key)).sort();
  if (JSON.stringify(Object.keys(disclosedRelations).sort()) !== JSON.stringify(sharedMeasurementKeys)) throw new Error("disclosed-relation-subject-mismatch");
  const requestKeys = [...new Set([...Object.keys(earlier.semanticRequests), ...Object.keys(later.semanticRequests)])].sort();
  const requests = requestKeys.map((key) => {
    const before = earlier.semanticRequests[key] ?? null;
    const after = later.semanticRequests[key] ?? null;
    const state = before === null ? "added" : after === null ? "removed" : before === after ? "unchanged" : "changed";
    return Object.freeze({ key, earlier: before ?? "Not written", later: after ?? "Not written", state });
  });
  const measurementKeys = [...new Set([...Object.keys(earlier.measurements), ...Object.keys(later.measurements)])].sort();
  const measurements = measurementKeys.map((key) => {
    const before = earlier.measurements[key] ?? null;
    const after = later.measurements[key] ?? null;
    for (const value of [before, after]) if (value !== null) {
      exact(value, ["display"], "disclosed-measurement");
      if (typeof value.display !== "string" || value.display.length < 1 || value.display.length > 80) throw new Error("invalid-disclosed-measurement");
    }
    const relation = before && after ? disclosedRelations[key] ?? null : null;
    if (before && after && relation === null) throw new Error("missing-earned-measurement-relation");
    return Object.freeze({ key, earlier: before?.display ?? "Not measured in this record", later: after?.display ?? "Not measured in this record", direction: relation ?? "unavailable" });
  });
  return Object.freeze({ earlierID: earlier.id, laterID: later.id, requests: Object.freeze(requests), measurements: Object.freeze(measurements) });
}
