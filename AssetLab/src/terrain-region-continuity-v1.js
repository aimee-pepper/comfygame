import crypto from "node:crypto";
import { directions, styleGrounds, contourProfiles, macroRoleAt } from "./dynamic-terrain-style-v0.2-kit.js";

export const schemaVersion = "terrain-region-continuity-v1";
export const boundaryRole = "materialBoundary";
export const visibilityStates = Object.freeze(["full", "fringe", "remembered"]);
export const boundaryRank = Object.freeze(Object.fromEntries(styleGrounds.map((g, i) => [g, i])));
export const opposite = Object.freeze({ north: "south", east: "west", south: "north", west: "east" });

const exact = (value, keys, label) => {
  if (!value || Array.isArray(value) || typeof value !== "object" || Object.keys(value).sort().join() !== [...keys].sort().join()) {
    throw Error(`invalid-${label}-fields`);
  }
};

export function normalizeRegionTileRequest(raw) {
  exact(raw, ["schemaVersion", "ground", "point", "visualSeed", "featureVariant", "cardinalNeighbors", "edgeContourIDs", "visibility", "motionPhase"], "region-request");
  exact(raw.point, ["x", "y"], "point");
  exact(raw.cardinalNeighbors, directions, "neighbors");
  exact(raw.edgeContourIDs, directions, "contours");
  if (raw.schemaVersion !== schemaVersion || !styleGrounds.includes(raw.ground) || !Number.isSafeInteger(raw.point.x) || !Number.isSafeInteger(raw.point.y) || !Number.isSafeInteger(raw.visualSeed) || raw.visualSeed < 0 || !Number.isSafeInteger(raw.featureVariant) || raw.featureVariant < 0 || raw.featureVariant > 3 || !visibilityStates.includes(raw.visibility) || !Number.isSafeInteger(raw.motionPhase) || raw.motionPhase < 0 || raw.motionPhase > 3) throw Error("invalid-region-request");
  for (const d of directions) {
    if (!["same", "unknown", ...styleGrounds].includes(raw.cardinalNeighbors[d])) throw Error("invalid-region-neighbor");
    if (!Number.isSafeInteger(raw.edgeContourIDs[d]) || raw.edgeContourIDs[d] < 0 || raw.edgeContourIDs[d] > 3) throw Error("invalid-region-contour");
  }
  return Object.freeze(structuredClone(raw));
}

export function contourOwner(ground, neighbor) {
  if (neighbor === "same" || neighbor === "unknown" || neighbor === ground) return false;
  if (!styleGrounds.includes(neighbor)) throw Error("invalid-boundary-neighbor");
  return boundaryRank[ground] < boundaryRank[neighbor];
}

function edgeDepth(i, id) { return 1 + contourProfiles[id][i]; }
function inEdge(direction, x, y, id) {
  return direction === "north" ? y < edgeDepth(x, id)
    : direction === "south" ? y >= 16 - edgeDepth(x, id)
      : direction === "west" ? x < edgeDepth(y, id)
        : x >= 16 - edgeDepth(y, id);
}

export function materialBoundaryMask(raw) {
  const request = normalizeRegionTileRequest(raw);
  const mask = new Uint8Array(256);
  if (request.visibility !== "full") return mask;
  for (const d of directions) {
    const neighbor = request.cardinalNeighbors[d];
    if (!contourOwner(request.ground, neighbor)) continue;
    const id = request.edgeContourIDs[d];
    for (let y = 0; y < 16; y++) for (let x = 0; x < 16; x++) {
      if (!inEdge(d, x, y, id)) continue;
      const inward = d === "north" ? y + 1 : d === "south" ? y - 1 : d === "west" ? x + 1 : x - 1;
      const index = y * 16 + x;
      mask[index] = ((x + y + request.point.x + request.point.y) & 3) === 0 ? 2 : 1;
      if (inward >= 0 && inward < 16 && ((x * 3 + y * 5 + id) & 7) === 0) {
        const ix = d === "west" || d === "east" ? inward : x;
        const iy = d === "north" || d === "south" ? inward : y;
        mask[iy * 16 + ix] = 1;
      }
    }
  }
  return mask;
}

export function coordinatedRoleTile(raw, roleMaps) {
  const request = normalizeRegionTileRequest(raw);
  const map = roleMaps[request.ground];
  if (!map || map.length !== 4096) throw Error("missing-ground-role-map");
  const roles = new Uint8Array(256);
  for (let y = 0; y < 16; y++) for (let x = 0; x < 16; x++) roles[y * 16 + x] = macroRoleAt(map, request.point, x, y, request.featureVariant);
  return roles;
}

export function applyBoundaryRole(baseRGBA, mask, palette) {
  if (baseRGBA.length !== 1024 || mask.length !== 256 || !Array.isArray(palette) || palette.length !== 2) throw Error("invalid-boundary-composite");
  const out = new Uint8ClampedArray(baseRGBA);
  for (let i = 0; i < 256; i++) if (mask[i]) out.set([...palette[mask[i] - 1], 255].slice(0, 4), i * 4);
  return out;
}

export function smallAccentPoint(point, visualSeed) {
  const digest = crypto.createHash("sha256").update(`${visualSeed}:${point.x}:${point.y}`).digest();
  return Object.freeze({ x: 3 + digest[0] % 10, y: 3 + digest[1] % 10 });
}

export function canonicalJSON(value) { return JSON.stringify(sort(value)); }
function sort(value) { if (Array.isArray(value)) return value.map(sort); if (value && typeof value === "object") return Object.fromEntries(Object.keys(value).sort().map(k => [k, sort(value[k])])); return value; }
export const sha256 = bytes => crypto.createHash("sha256").update(bytes).digest("hex");
