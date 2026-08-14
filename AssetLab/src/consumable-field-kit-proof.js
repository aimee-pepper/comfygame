export const consumableFieldKitProofVersion = "consumable-field-kit-proof-0.1.0";

export const preparationFamilies = Object.freeze({
  treatments: Object.freeze(["salve_lesser", "salve", "salve_greater", "draught_clearing", "draught_quenching", "antidote_broad", "stonebark_tonic"]),
  coatings: Object.freeze(["venom", "firebrand", "briar_oil", "flashsalt"]),
  fieldwork: Object.freeze(["solvent", "lure", "stillwater", "waystone", "torch", "farsight_draught"]),
});

export const allPreparationIDs = Object.freeze(Object.values(preparationFamilies).flat());

function exact(value, keys, label) {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error(`invalid-${label}`);
  if (JSON.stringify(Object.keys(value).sort()) !== JSON.stringify([...keys].sort())) throw new Error(`invalid-${label}-fields`);
}

function nonnegative(value, label) {
  if (!Number.isSafeInteger(value) || value < 0) throw new Error(`invalid-${label}`);
  return value;
}

export function resolveFieldKit(request) {
  exact(request, ["capacity", "stock", "entries"], "field-kit-request");
  const capacity = nonnegative(request.capacity, "capacity");
  if (!Array.isArray(request.stock) || !Array.isArray(request.entries)) throw new Error("invalid-field-kit-arrays");
  const stock = new Map();
  for (const row of request.stock) {
    exact(row, ["itemID", "count"], "stock-row");
    if (!allPreparationIDs.includes(row.itemID) || stock.has(row.itemID)) throw new Error("invalid-stock-item");
    stock.set(row.itemID, nonnegative(row.count, "stock-count"));
  }
  const seen = new Set();
  const normalized = request.entries.map((entry) => {
    exact(entry, ["itemID", "desiredCount", "order"], "field-kit-entry");
    if (!allPreparationIDs.includes(entry.itemID) || seen.has(entry.itemID)) throw new Error("invalid-field-kit-item");
    seen.add(entry.itemID);
    return Object.freeze({ itemID: entry.itemID, desiredCount: nonnegative(entry.desiredCount, "desired-count"), order: nonnegative(entry.order, "entry-order") });
  }).sort((a, b) => a.order - b.order || a.itemID.localeCompare(b.itemID));
  let packedBins = 0;
  const rows = [];
  for (const entry of normalized) {
    const available = stock.get(entry.itemID) ?? 0;
    const wanted = entry.desiredCount > 0;
    const hasStock = available > 0;
    const hasCapacity = packedBins < capacity;
    const count = wanted && hasStock && hasCapacity ? Math.min(entry.desiredCount, available) : 0;
    if (count > 0) packedBins += 1;
    const exclusionReason = !wanted ? "not-selected" : !hasStock ? "no-stock" : !hasCapacity ? "capacity-full" : null;
    rows.push(Object.freeze({ itemID: entry.itemID, desiredCount: entry.desiredCount, availableCount: available, packedCount: count, stockShortageCount: Math.max(0, entry.desiredCount - available), unpackedCount: entry.desiredCount - count, exclusionReason }));
  }
  const selectedBins = rows.filter((row) => row.desiredCount > 0).length;
  const packed = rows.filter((row) => row.packedCount > 0);
  return Object.freeze({ capacity, selectedBins, packedBins, rows: Object.freeze(rows), packed: Object.freeze(packed), orderedEntries: Object.freeze(normalized) });
}

export function previewPreparation(request) {
  exact(request, ["itemID", "quantity", "stockRevision", "previewRevision", "destinationAvailable"], "preparation-preview");
  if (!allPreparationIDs.includes(request.itemID)) throw new Error("unknown-preparation");
  nonnegative(request.quantity, "prepare-quantity");
  nonnegative(request.stockRevision, "stock-revision");
  nonnegative(request.previewRevision, "preview-revision");
  if (typeof request.destinationAvailable !== "boolean") throw new Error("invalid-destination-fact");
  if (request.quantity < 1) return Object.freeze({ ok: false, reason: "quantity-required", canSubmit: false });
  if (request.stockRevision !== request.previewRevision) return Object.freeze({ ok: false, reason: "stock-changed", canSubmit: false });
  if (!request.destinationAvailable) return Object.freeze({ ok: false, reason: "storehouse-and-spillover-full", canSubmit: false });
  return Object.freeze({ ok: true, reason: null, canSubmit: true, quantity: request.quantity });
}
