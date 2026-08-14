import { createHash } from "node:crypto";

export const worldGrade2V1Versions = Object.freeze({
  contractVersion: 1,
  resolverVersion: "world-grade-2-resolver-1.0.0",
  paletteCatalogueVersion: "world-grade-2-palette-1.0.0",
  rendererVersion: "world-grade-2-renderer-1.0.0",
  lightLayerVersion: "current-visibility-separate-1.0.0",
});
export const worldGrade2V1PaletteFamilies = Object.freeze({
  warmMineral: Object.freeze({ hue: 18, saturation: 1.28, value: 2 }),
  coolMineral: Object.freeze({ hue: -28, saturation: 1.18, value: -3 }),
  warmEarth: Object.freeze({ hue: 30, saturation: 1.22, value: 1 }),
  coolEarth: Object.freeze({ hue: -34, saturation: 1.2, value: -2 }),
  paleNeutral: Object.freeze({ hue: 8, saturation: 0.82, value: 8 }),
  darkNeutral: Object.freeze({ hue: 0, saturation: 0.9, value: -7 }),
});
export const worldGrade2V1AtmosphereFamilies = Object.freeze({
  clear: Object.freeze({ hue: 0, saturation: 1, value: 0 }),
  neutralSmoke: Object.freeze({ hue: 8, saturation: 0.8, value: -10 }),
  coolSmoke: Object.freeze({ hue: -10, saturation: 0.86, value: -8 }),
});
export const worldGrade2V1GroundOwnership = Object.freeze({
  stone: "material+atmosphere", soil: "material+atmosphere", sand: "material+atmosphere",
  ash: "material+atmosphere", rubble: "material+atmosphere", mud: "material+atmosphere",
  chasm: "void+atmosphere", water: "hydrology+atmosphere", deepWater: "hydrology+atmosphere",
  ice: "hydrology+atmosphere", growth: "ecology+atmosphere", groundcover: "ecology+atmosphere",
});

export function canonicalJSON(value) {
  if (value === null || typeof value !== "object") return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(canonicalJSON).join(",")}]`;
  return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${canonicalJSON(value[key])}`).join(",")}}`;
}
export const canonicalSHA256 = (value) => createHash("sha256").update(canonicalJSON(value), "utf8").digest("hex");
const exact = (value, keys, label) => { if (!value || typeof value !== "object" || Array.isArray(value) || JSON.stringify(Object.keys(value).sort()) !== JSON.stringify([...keys].sort())) throw new Error(`invalid-${label}-fields`); };
const bounded = (value, min, max, label) => { if (!Number.isFinite(value) || value < min || value > max) throw new Error(`invalid-${label}`); return value; };
const color = (value, label) => {
  if (value === null) return null;
  exact(value, ["srgb", "resolutionVersion", "provenance"], label);
  if (!Array.isArray(value.srgb) || value.srgb.length !== 3 || !value.srgb.every((channel) => Number.isInteger(channel) && channel >= 0 && channel <= 255) || typeof value.resolutionVersion !== "string" || !/^resolved-color-[1-9][0-9]*\.[0-9]+\.[0-9]+$/.test(value.resolutionVersion) || !["authoredMix", "bindRandom"].includes(value.provenance)) throw new Error(`invalid-${label}`);
  return Object.freeze({ srgb: Object.freeze([...value.srgb]), resolutionVersion: value.resolutionVersion, provenance: value.provenance });
};

export function resolveWorldGrade2V1(request) {
  exact(request, ["versions", "material", "atmosphere", "flora", "resolvedColors"], "world-grade-2-v1-request");
  if (canonicalJSON(request.versions) !== canonicalJSON(worldGrade2V1Versions)) throw new Error("world-grade-2-v1-version-mismatch");
  exact(request.material, ["identity", "paletteFamilyID", "transform"], "material");
  if (!["granite", "mixedMineral", "mixedEarth"].includes(request.material.identity) || !Object.hasOwn(worldGrade2V1PaletteFamilies, request.material.paletteFamilyID)) throw new Error("unknown-material-fact");
  exact(request.material.transform, ["hue", "saturation", "value"], "material-transform");
  const transform = Object.freeze({ hue: bounded(request.material.transform.hue, -64, 64, "material-hue"), saturation: bounded(request.material.transform.saturation, 0.7, 1.6, "material-saturation"), value: bounded(request.material.transform.value, -20, 20, "material-value") });
  exact(request.atmosphere, ["medium", "density", "paletteFamilyID"], "atmosphere");
  if (!["none", "smoke"].includes(request.atmosphere.medium) || !Object.hasOwn(worldGrade2V1AtmosphereFamilies, request.atmosphere.paletteFamilyID)) throw new Error("unknown-atmosphere-fact");
  if (request.atmosphere.medium === "none" && (request.atmosphere.density !== 0 || request.atmosphere.paletteFamilyID !== "clear")) throw new Error("invalid-clear-atmosphere");
  if (request.atmosphere.medium === "smoke" && !/Smoke$/.test(request.atmosphere.paletteFamilyID)) throw new Error("invalid-smoke-family");
  const density = bounded(request.atmosphere.density, 0, 100, "atmosphere-density");
  exact(request.flora, ["coveragePercent", "paletteRichness", "cast"], "flora");
  const coveragePercent = bounded(request.flora.coveragePercent, 0, 100, "flora-coverage"), paletteRichness = bounded(request.flora.paletteRichness, 0, 100, "flora-richness");
  if (!Array.isArray(request.flora.cast) || request.flora.cast.length > 4) throw new Error("invalid-flora-cast");
  const cast = request.flora.cast.map((species) => { exact(species, ["speciesID", "formID", "stature", "resolvedColor"], "flora-species"); if (typeof species.speciesID !== "string" || !/^[a-z][a-z0-9_-]{0,31}$/.test(species.speciesID) || !Number.isInteger(species.formID) || species.formID < 0 || species.formID > 3) throw new Error("invalid-flora-species"); return Object.freeze({ speciesID: species.speciesID, formID: species.formID, stature: bounded(species.stature, 0, 100, "flora-stature"), resolvedColor: color(species.resolvedColor, "flora-species-color") }); });
  if (new Set(cast.map((species) => species.speciesID)).size !== cast.length || ((cast.length === 0) !== (coveragePercent === 0))) throw new Error("flora-cast-coverage-mismatch");
  exact(request.resolvedColors, ["material", "atmosphere", "emitter", "floraTendency"], "resolved-colors");
  const resolvedColors = Object.freeze(Object.fromEntries(Object.entries(request.resolvedColors).map(([scope, value]) => [scope, color(value, `${scope}-color`)])));
  if (request.atmosphere.medium === "none" && resolvedColors.atmosphere !== null) throw new Error("clear-atmosphere-cannot-own-color");
  const rendererColors = Object.freeze({ material: resolvedColors.material, atmosphere: resolvedColors.atmosphere, emitter: resolvedColors.emitter });
  const descriptor = { versions: worldGrade2V1Versions, material: Object.freeze({ identity: request.material.identity, paletteFamilyID: request.material.paletteFamilyID, transform }), atmosphere: Object.freeze({ medium: request.atmosphere.medium, density, paletteFamilyID: request.atmosphere.paletteFamilyID }), flora: Object.freeze({ coveragePercent, paletteRichness, richness: Number((0.7 + 0.6 * paletteRichness / 100).toFixed(3)), cast: Object.freeze(cast) }), resolvedColors: rendererColors };
  return Object.freeze({ ...descriptor, canonicalDescriptorSHA256: canonicalSHA256(descriptor) });
}

const clamp = (n, min = 0, max = 255) => Math.max(min, Math.min(max, n));
const hexToRgb = (hex) => [1, 3, 5].map((index) => parseInt(hex.slice(index, index + 2), 16));
const rgbToHex = (rgb) => `#${rgb.map((n) => clamp(Math.round(n)).toString(16).padStart(2, "0")).join("")}`;
function rgbToHsl([r, g, b]) { r /= 255; g /= 255; b /= 255; const max = Math.max(r, g, b), min = Math.min(r, g, b), l = (max + min) / 2, d = max - min; let h = 0, s = 0; if (d) { s = d / (1 - Math.abs(2 * l - 1)); if (max === r) h = 60 * ((g - b) / d % 6); else if (max === g) h = 60 * ((b - r) / d + 2); else h = 60 * ((r - g) / d + 4); } return [(h + 360) % 360, s, l]; }
function hslToRgb([h, s, l]) { const chroma = (1 - Math.abs(2 * l - 1)) * s, x = chroma * (1 - Math.abs((h / 60) % 2 - 1)), m = l - chroma / 2; let v; if (h < 60) v = [chroma, x, 0]; else if (h < 120) v = [x, chroma, 0]; else if (h < 180) v = [0, chroma, x]; else if (h < 240) v = [0, x, chroma]; else if (h < 300) v = [x, 0, chroma]; else v = [chroma, 0, x]; return v.map((n) => (n + m) * 255); }
const mix = (a, b, t) => a.map((n, index) => n * (1 - t) + b[index] * t);
export function worldGrade2V1Color(hex, descriptor, { scope = "material", includeEmitter = false, groundType = null, speciesID = null } = {}) {
  if (scope === "material" && !Object.hasOwn(worldGrade2V1GroundOwnership, groundType)) throw new Error("unknown-ground-ownership");
  const family = worldGrade2V1PaletteFamilies[descriptor.material.paletteFamilyID], air = worldGrade2V1AtmosphereFamilies[descriptor.atmosphere.paletteFamilyID], materialGround = scope === "material" && worldGrade2V1GroundOwnership[groundType].startsWith("material"), graniteEligible = descriptor.material.identity === "granite" && ["stone", "rubble"].includes(groundType), hsl = rgbToHsl(hexToRgb(hex)), density = descriptor.atmosphere.density / 100;
  hsl[0] = (hsl[0] + (materialGround ? descriptor.material.transform.hue + family.hue : 0) + air.hue * density + 360) % 360;
  hsl[1] = clamp(hsl[1] * (materialGround ? descriptor.material.transform.saturation * family.saturation : 1) * (1 + (air.saturation - 1) * density) * (scope === "flora" ? descriptor.flora.richness : 1), 0, 0.92);
  hsl[2] = clamp(hsl[2] + ((materialGround ? descriptor.material.transform.value + family.value : 0) + air.value * density) / 100, 0.12, 0.9);
  const floraSpecies = scope === "flora" ? descriptor.flora.cast.find((species) => species.speciesID === speciesID) : null;
  if (scope === "flora" && !floraSpecies) throw new Error("unknown-flora-species-color");
  let rgb = hslToRgb(hsl), scoped = scope === "flora" ? floraSpecies.resolvedColor.srgb : scope === "material" && !graniteEligible ? null : descriptor.resolvedColors[scope]?.srgb;
  if (scoped) rgb = mix(rgb, scoped, scope === "flora" ? 0.32 : 0.38);
  scoped = descriptor.resolvedColors.atmosphere?.srgb; if (scoped && descriptor.atmosphere.medium !== "none") rgb = mix(rgb, scoped, 0.2 * density);
  scoped = includeEmitter ? descriptor.resolvedColors.emitter?.srgb : null; if (scoped) rgb = mix(rgb, scoped, 0.13);
  return rgbToHex(rgb);
}
export const recolorWorldGrade2V1Commands = (commands, descriptor, options) => commands.map((command) => command.color.startsWith("#") ? { ...command, color: worldGrade2V1Color(command.color, descriptor, options) } : { ...command });
export const worldGrade2V1Geometry = (commands) => commands.map(({ op, x, y, w, h }) => ({ op, x, y, w, h }));
export function worldGrade2V1FogRGBA({ revealed, width, height }) {
  if (typeof revealed !== "boolean" || !Number.isInteger(width) || width < 1 || !Number.isInteger(height) || height < 1) throw new Error("invalid-fog-request");
  return revealed ? null : Buffer.alloc(width * height * 4);
}
