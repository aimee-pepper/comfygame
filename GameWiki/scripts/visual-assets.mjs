const slug = value => String(value ?? "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

const explicitVariantKeys = ["variant", "state", "profile", "facing", "frame", "frameIndex", "angle", "orientation"];

export function visualVariant(value, trail = []) {
  const parts = explicitVariantKeys
    .filter(key => value?.[key] !== undefined && value?.[key] !== null && value?.[key] !== "")
    .map(key => `${slug(key)}-${slug(value[key])}`);
  if (parts.length) return parts.join("-");
  const numericIndex = trail.findLastIndex(part => /^\d+$/.test(String(part)));
  return numericIndex >= 0 ? `${slug(trail[numericIndex - 1] ?? "variant")}-${slug(trail[numericIndex])}` : "default";
}

export function visualRecordIdentity({ familyID, role, semanticKey, variant = "default" }) {
  const family = slug(familyID) || "family";
  const recordRole = slug(role) || "record";
  const semantic = slug(semanticKey) || "asset";
  const explicitVariant = slug(variant) || "default";
  const route = `asset-record/${family}/${recordRole}/${semantic}/${explicitVariant}`;
  return {
    route,
    sourceRoute: `${family}/${recordRole}/${semantic}/${explicitVariant}`,
    previewURL: `visual-assets/${family}/${recordRole}/${semantic}/${explicitVariant}.png`
  };
}

export function assertUniqueVisualRoutes(records) {
  const routes = new Map();
  for (const record of records) {
    const previous = routes.get(record.route);
    if (previous) throw new Error(`Visual route collision: ${record.route} (${previous} and ${record.sourcePath ?? record.semanticKey})`);
    routes.set(record.route, record.sourcePath ?? record.semanticKey);
  }
}

export function visualDisclosureDecision(record, hiddenLexemeIDs = new Set()) {
  if (record.integrityIndexOnly) return { disclosed: false, reason: "integrity-index-only" };
  if (record.disclosed === false) return { disclosed: false, reason: "gameplay-disclosure" };
  const context = String(record.context ?? "");
  const sourceMatch = context.match(/(?:^|\/)mark\/source\/([^/]+)/i);
  const compoundMatch = context.match(/(?:^|\/)mark\/compound\/([^/]+)/i);
  if (sourceMatch && hiddenLexemeIDs.has(`source:${sourceMatch[1]}`)) return { disclosed: false, reason: "gameplay-disclosure" };
  if (compoundMatch && hiddenLexemeIDs.has(`compound:${compoundMatch[1]}`)) return { disclosed: false, reason: "gameplay-disclosure" };
  return { disclosed: true, reason: null };
}

export function partitionVisualRecords(records, hiddenLexemeIDs = new Set(), forcedReason = null) {
  const disclosed = [];
  const withheldCounts = {};
  for (const record of records) {
    const decision = forcedReason ? { disclosed: false, reason: forcedReason } : visualDisclosureDecision(record, hiddenLexemeIDs);
    if (decision.disclosed) disclosed.push(record);
    else withheldCounts[decision.reason] = (withheldCounts[decision.reason] ?? 0) + 1;
  }
  return { disclosed, withheldCounts };
}

export function publicVisualRecord(record) {
  const { semanticKey, role, variant, route, sourceRoute, previewURL, width, height, integrity } = record;
  return { semanticKey, role, variant, route, sourceRoute, previewURL, width, height, integrity };
}
