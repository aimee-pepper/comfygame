const PLOT_IDS = Object.freeze(["upperLeft", "upperRight", "lowerLeft", "lowerRight"]);

function assertExactKeys(value, keys, label) {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error(`${label} must be an object`);
  const actual = Object.keys(value).sort();
  const expected = [...keys].sort();
  if (actual.length !== expected.length || actual.some((key, index) => key !== expected[index])) {
    throw new Error(`${label} has unexpected fields`);
  }
}

function assertNonemptyString(value, label) {
  if (typeof value !== "string" || !value.trim()) throw new Error(`${label} must be a nonempty string`);
}

function assertAssetRecord(record, label, pathKey) {
  assertExactKeys(record, [pathKey, "pixelWidth", "pixelHeight", "sha256"], label);
  assertNonemptyString(record[pathKey], `${label}.${pathKey}`);
  if (!Number.isSafeInteger(record.pixelWidth) || record.pixelWidth < 1 ||
      !Number.isSafeInteger(record.pixelHeight) || record.pixelHeight < 1) throw new Error(`${label} dimensions must be positive integers`);
  if (!/^[0-9a-f]{64}$/.test(record.sha256)) throw new Error(`${label}.sha256 must be lowercase SHA-256`);
}

function deepFreeze(value) {
  if (value && typeof value === "object" && !Object.isFrozen(value)) {
    Object.freeze(value);
    for (const child of Object.values(value)) deepFreeze(child);
  }
  return value;
}

export function validateTownBuildingManifest(manifest) {
  assertExactKeys(manifest, ["schemaVersion", "generatorVersion", "integrationReady", "backdrop", "startingBackdrop", "pageCapacity", "plots", "acceptedLayers", "promptStyle"], "manifest");
  if (manifest.schemaVersion !== 1 || manifest.generatorVersion !== "town-building-generator-1.0.0") throw new Error("unsupported generator version");
  if (manifest.integrationReady !== true) throw new Error("the accepted town layer manifest must be integration ready");
  assertAssetRecord(manifest.backdrop, "backdrop", "path");
  assertExactKeys(manifest.startingBackdrop, ["path", "pixelWidth", "pixelHeight", "sha256", "hotspots"], "startingBackdrop");
  const { hotspots, ...startingAsset } = manifest.startingBackdrop;
  assertAssetRecord(startingAsset, "startingBackdrop", "path");
  if (!Array.isArray(hotspots) || hotspots.length !== 6 || new Set(hotspots).size !== hotspots.length || hotspots.some((id) => typeof id !== "string" || !id)) {
    throw new Error("startingBackdrop.hotspots must contain six unique IDs");
  }
  if (!Array.isArray(manifest.plots) || manifest.pageCapacity !== 4 || manifest.plots.length !== 4) throw new Error("the v1 town board requires four plots");
  const ids = manifest.plots.map((plot) => plot.id);
  if (ids.some((id, index) => id !== PLOT_IDS[index])) throw new Error("plot order is frozen");
  for (const plot of manifest.plots) {
    assertExactKeys(plot, ["id", "x", "y", "buildingWidth"], `plot ${plot.id}`);
    for (const key of ["x", "y", "buildingWidth"]) {
      if (!Number.isFinite(plot[key]) || plot[key] <= 0 || plot[key] >= 1) throw new Error(`plot ${plot.id}.${key} must be normalized`);
    }
  }
  if (!manifest.acceptedLayers || typeof manifest.acceptedLayers !== "object" || Array.isArray(manifest.acceptedLayers)) throw new Error("acceptedLayers must be an object");
  for (const [id, layer] of Object.entries(manifest.acceptedLayers)) {
    assertNonemptyString(id, "accepted layer ID");
    assertExactKeys(layer, ["file", "sha256"], `accepted layer ${id}`);
    assertNonemptyString(layer.file, `accepted layer ${id}.file`);
    if (!/^[0-9a-f]{64}$/.test(layer.sha256)) throw new Error(`accepted layer ${id}.sha256 must be lowercase SHA-256`);
  }
  const styleKeys = ["perspective", "palette", "lighting", "background", "constraints"];
  assertExactKeys(manifest.promptStyle, styleKeys, "promptStyle");
  for (const key of styleKeys) assertNonemptyString(manifest.promptStyle[key], `promptStyle.${key}`);
  return deepFreeze(structuredClone(manifest));
}

export function paginateTownStations(stations, capacity = 4) {
  if (!Array.isArray(stations) || !Number.isSafeInteger(capacity) || capacity < 1) throw new Error("invalid pagination input");
  const ids = new Set();
  for (const station of stations) {
    if (!station || typeof station.id !== "string" || !station.id.trim() || ids.has(station.id)) throw new Error("station IDs must be unique nonempty strings");
    ids.add(station.id);
  }
  return Object.freeze(Array.from({ length: Math.ceil(stations.length / capacity) }, (_, index) => Object.freeze(stations.slice(index * capacity, (index + 1) * capacity))));
}

export function acceptedTownLayer(manifest, stationID) {
  if (typeof stationID !== "string" || !stationID) throw new Error("station ID is required");
  return manifest.acceptedLayers[stationID] ?? null;
}

export function townLayerFileName(stationID) {
  if (typeof stationID !== "string" || !/^[a-z0-9]+(?:_[a-z0-9]+)*$/.test(stationID)) {
    throw new Error("station ID must be lowercase snake case");
  }
  return `building-${stationID.replaceAll("_", "-")}-v1.png`;
}

export function validateTownLayerPNG(bytes) {
  if (!(bytes instanceof Uint8Array) || bytes.byteLength < 33) throw new Error("town layer must be PNG bytes");
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (signature.some((value, index) => bytes[index] !== value)) throw new Error("town layer must be a PNG");
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const chunk = String.fromCharCode(...bytes.slice(12, 16));
  if (chunk !== "IHDR") throw new Error("town layer PNG must begin with IHDR");
  const width = view.getUint32(16);
  const height = view.getUint32(20);
  const bitDepth = bytes[24];
  const colorType = bytes[25];
  if (width !== 627 || height !== 627) throw new Error("town layer must be exactly 627×627");
  if (bitDepth !== 8 || colorType !== 6) throw new Error("town layer must be 8-bit RGBA with transparency");
  return Object.freeze({ width, height, bitDepth, colorType });
}

export function townBuildingPrompt(manifest, station, plotID) {
  if (!station || typeof station.id !== "string" || typeof station.name !== "string" || typeof station.blurb !== "string") throw new Error("station must have exact id, name and blurb");
  if (!PLOT_IDS.includes(plotID)) throw new Error(`unknown plot ${plotID}`);
  const plot = manifest.plots.find((candidate) => candidate.id === plotID);
  if (!plot) throw new Error(`manifest is missing plot ${plotID}`);
  const style = manifest.promptStyle;
  return [
    `Create one ${station.name} for the Bookbinder town.`,
    `Function: ${station.blurb}`,
    `Placement: ${plotID} construction plot.`,
    style.perspective + ".",
    style.palette + ".",
    style.lighting + ".",
    style.background + ".",
    style.constraints + ".",
    `Native composition center: x ${plot.x.toFixed(2)}, y ${plot.y.toFixed(2)} of the town board; target displayed width ${plot.buildingWidth.toFixed(2)} of the board.`,
    "Output a square transparent-ready sprite at 627×627; keep the complete silhouette inside the central 78%, place the ground contact near 82% height, and leave transparent breathing room so native scaling never clips roof, smoke, steps or side props."
  ].join(" ");
}

export const townPlotIDs = PLOT_IDS;
