const slug = value => String(value ?? "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

const explicitVariantKeys = ["variant", "state", "profile", "hand", "facing", "frame", "frameIndex", "angle", "orientation", "rows", "columns"];

export function visualVariant(value, trail = []) {
  const parts = explicitVariantKeys
    .filter(key => value?.[key] !== undefined && value?.[key] !== null && value?.[key] !== "")
    .map(key => `${slug(key)}-${slug(value[key])}`);
  return parts.join("-") || "default";
}

const basenameWithoutExtension = path => String(path).replaceAll("\\", "/").split("/").at(-1).replace(/\.[^.]+$/, "");

export function extractPNGReferences(value) {
  const records = [];
  const visit = (node, trail = [], inheritedDisclosed = true, inheritedSemanticIdentity = null, inheritedVariant = "default") => {
    if (Array.isArray(node)) {
      node.forEach((item, index) => visit(item, [...trail, String(index)], inheritedDisclosed, inheritedSemanticIdentity, inheritedVariant));
      return;
    }
    if (!node || typeof node !== "object") return;
    const explicitlyHidden = node.identified === false || node.hidden === true || node.disclosed === false
      || node.visibility === "hidden" || node.disclosure === false || node.disclosure === "hidden";
    const disclosed = inheritedDisclosed && !explicitlyHidden;
    const ownSemanticIdentity = node.stableKey ?? node.key ?? node.id ?? inheritedSemanticIdentity;
    const localVariant = visualVariant(node);
    const effectiveVariant = localVariant === "default" ? inheritedVariant : localVariant;
    const pathCandidates = [
      [node.path, null], [node.file, null], [node.assetPath, null], [node.sourcePath, "source"],
      [node.referencePath, "reference"], [node.evidencePath, "evidence"]
    ].filter(([candidate]) => typeof candidate === "string" && /\.png$/i.test(candidate));
    for (const [rawPath, forcedRole] of new Map(pathCandidates.map(candidate => [`${candidate[0]}\0${candidate[1]}`, candidate])).values()) {
      const assetsByKeyIndex = trail.indexOf("assetsByKey");
      const inferredSemanticKey = trail.filter(part => !/^\d+$/.test(part)).join("/");
      const fileSemanticKey = basenameWithoutExtension(rawPath);
      const explicitSemanticKey = node.stableKey ?? node.key ?? node.id ?? (assetsByKeyIndex >= 0 ? trail[assetsByKeyIndex + 1] : null) ?? inheritedSemanticIdentity;
      const semanticKey = explicitSemanticKey != null
        ? (inferredSemanticKey && !inferredSemanticKey.endsWith(String(explicitSemanticKey)) ? `${inferredSemanticKey}/${explicitSemanticKey}` : explicitSemanticKey)
        : (/^\d+$/.test(trail.at(-1) ?? "") && !/^[0-9a-f]{32,}$/i.test(fileSemanticKey) ? fileSemanticKey : inferredSemanticKey || "opaque-asset");
      const contextTokens = trail.map(token => String(token).toLowerCase());
      const role = forcedRole ?? (contextTokens.some(token => /^(source-?references?|references?)$/.test(token)) ? "reference"
        : contextTokens.some(token => /^(evidence|proofs?|contact-?sheets?|review-?evidence)$/.test(token)) ? "evidence"
        : /^(source|sources|editable-?sources?)$/.test(contextTokens[0] ?? "") ? "source"
        : "runtime");
      records.push({
        semanticKey: String(semanticKey), rawPath, role, variant: effectiveVariant, disclosed,
        integrityIndexOnly: /^(assets|files|images|pngs)\/\d+$/i.test(trail.join("/")) && explicitSemanticKey == null,
        context: trail.join("/"),
        declaredSHA256: forcedRole === "source" ? node.sourceSHA256 ?? node.sourceFileSHA256 ?? null : node.fileSHA256 ?? node.sha256 ?? node.pngSHA256 ?? null,
        decodedRGBASHA256: node.decodedRGBASHA256 ?? node.rgbaSHA256 ?? node.pixelSHA256 ?? null,
        width: node.width ?? node.pixelWidth ?? null,
        height: node.height ?? node.pixelHeight ?? null
      });
    }
    for (const [key, child] of Object.entries(node)) visit(child, [...trail, key], disclosed, ownSemanticIdentity, effectiveVariant);
  };
  visit(value);
  return records;
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
  const vocabularyTileMatch = context.match(/(?:^|\/)vocabularytiles\/tile\/(source|compound)\/([^/]+)/i);
  if (sourceMatch && hiddenLexemeIDs.has(`source:${sourceMatch[1]}`)) return { disclosed: false, reason: "gameplay-disclosure" };
  if (compoundMatch && hiddenLexemeIDs.has(`compound:${compoundMatch[1]}`)) return { disclosed: false, reason: "gameplay-disclosure" };
  if (vocabularyTileMatch && hiddenLexemeIDs.has(`${vocabularyTileMatch[1].toLowerCase()}:${vocabularyTileMatch[2]}`)) return { disclosed: false, reason: "gameplay-disclosure" };
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
