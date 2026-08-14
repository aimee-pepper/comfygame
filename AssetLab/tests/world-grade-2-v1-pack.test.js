import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import { inflateSync } from "node:zlib";
import Ajv2020 from "ajv/dist/2020.js";
import { worldGrade2V1Versions, worldGrade2V1GroundOwnership, resolveWorldGrade2V1, worldGrade2V1Color, canonicalJSON, canonicalSHA256, worldGrade2V1Geometry, worldGrade2V1FogRGBA } from "../src/world-grade-2-v1.js";
const pack = new URL("../integration/world-grade-2-v1/", import.meta.url), sha = (value) => createHash("sha256").update(value).digest("hex");
function decodeRGBA(png) {
  assert.deepEqual([...png.subarray(0, 8)], [137,80,78,71,13,10,26,10]);
  let offset = 8, width, height, bitDepth, colorType; const idat = [];
  while (offset < png.length) { const length = png.readUInt32BE(offset), type = png.toString("ascii", offset + 4, offset + 8), data = png.subarray(offset + 8, offset + 8 + length); offset += 12 + length; if (type === "IHDR") { width = data.readUInt32BE(0); height = data.readUInt32BE(4); bitDepth = data[8]; colorType = data[9]; } else if (type === "IDAT") idat.push(data); else if (type === "IEND") break; }
  assert.equal(bitDepth, 8); assert.equal(colorType, 6); const bytesPerPixel = 4, stride = width * bytesPerPixel, raw = inflateSync(Buffer.concat(idat)), out = Buffer.alloc(width * height * 4); let source = 0;
  for (let y = 0; y < height; y += 1) { const filter = raw[source++]; for (let x = 0; x < stride; x += 1) { const current = raw[source++], left = x >= bytesPerPixel ? out[y * stride + x - bytesPerPixel] : 0, up = y > 0 ? out[(y - 1) * stride + x] : 0, upperLeft = y > 0 && x >= bytesPerPixel ? out[(y - 1) * stride + x - bytesPerPixel] : 0; let value; if (filter === 0) value = current; else if (filter === 1) value = current + left; else if (filter === 2) value = current + up; else if (filter === 3) value = current + Math.floor((left + up) / 2); else if (filter === 4) { const p = left + up - upperLeft, pa = Math.abs(p - left), pb = Math.abs(p - up), pc = Math.abs(p - upperLeft); value = current + (pa <= pb && pa <= pc ? left : pb <= pc ? up : upperLeft); } else throw new Error(`unsupported-png-filter:${filter}`); out[y * stride + x] = value & 255; } }
  return { width, height, rgba: out };
}
const manifest = JSON.parse(await readFile(new URL("manifest.json", pack), "utf8")), vectors = JSON.parse(await readFile(new URL("conformance-vectors.json", pack), "utf8")), requestSchema = JSON.parse(await readFile(new URL("request.schema.json", pack), "utf8")), descriptorSchema = JSON.parse(await readFile(new URL("descriptor.schema.json", pack), "utf8"));
assert.equal(manifest.integrationReady, true); assert.deepEqual(manifest.pipelineVersions, worldGrade2V1Versions); assert.equal(manifest.status, "frozen-production-integration-boundary");
const manifestBody = structuredClone(manifest); delete manifestBody.canonicalManifestSHA256; assert.equal(canonicalSHA256(manifestBody), manifest.canonicalManifestSHA256);
for (const record of Object.values(manifest.files)) assert.equal(sha(await readFile(new URL(record.file, pack))), record.sha256);
const ajv = new Ajv2020({ strict: true, allErrors: true }); ajv.addSchema(requestSchema); const validateRequest = ajv.getSchema(requestSchema.$id), validateDescriptor = ajv.compile(descriptorSchema);
assert.equal(vectors.vectors.length, manifest.vectorCount); assert.deepEqual(vectors.vectors.map((vector) => vector.id), manifest.vectorIDs);
for (const vector of vectors.vectors) {
  assert.equal(validateRequest(vector.request), true, JSON.stringify(validateRequest.errors));
  assert.equal(validateDescriptor(vector.descriptor), true, JSON.stringify(validateDescriptor.errors));
  const descriptor = resolveWorldGrade2V1(vector.request); assert.deepEqual(descriptor, vector.descriptor);
  assert.equal(canonicalSHA256(vector.request), vector.canonicalRequestSHA256); const descriptorBody = structuredClone(vector.descriptor); delete descriptorBody.canonicalDescriptorSHA256; assert.equal(canonicalSHA256(descriptorBody), vector.canonicalDescriptorSHA256);
  assert.equal(canonicalSHA256(vector.rectangleCommands), vector.rectangleCommandsSHA256); assert.equal(canonicalSHA256(worldGrade2V1Geometry(vector.rectangleCommands)), vector.geometrySHA256);
  const png = await readFile(new URL(vector.pngFile, pack)); assert.equal(sha(png), vector.pngSHA256); const decoded = decodeRGBA(png); assert.deepEqual([decoded.width, decoded.height], [vector.pixelWidth, vector.pixelHeight]); assert.equal(sha(decoded.rgba), vector.decodedRGBASHA256);
}
const twinA = vectors.vectors.find((vector) => vector.id === "identical-a"), twinB = vectors.vectors.find((vector) => vector.id === "identical-b"); assert.equal(twinA.canonicalDescriptorSHA256, twinB.canonicalDescriptorSHA256); assert.equal(twinA.decodedRGBASHA256, twinB.decodedRGBASHA256);
const floraScope = vectors.vectors.find((vector) => vector.id === "flora-scope"); assert.equal(floraScope.descriptor.flora.cast.length, 4); assert.equal(new Set(floraScope.descriptor.flora.cast.map((species) => canonicalJSON(species.resolvedColor))).size, 4); assert.equal(new Set(floraScope.rectangleCommands.slice(-4).map((command)=>command.color)).size,4);
const changedTendency=structuredClone(floraScope.request); changedTendency.resolvedColors.floraTendency={srgb:[240,20,20],resolutionVersion:"resolved-color-1.0.0",provenance:"bindRandom"}; assert.deepEqual(resolveWorldGrade2V1(changedTendency),floraScope.descriptor);
assert.deepEqual(Object.keys(worldGrade2V1GroundOwnership).sort(), ["ash","chasm","deepWater","groundcover","growth","ice","mud","rubble","sand","soil","stone","water"]); assert.ok(vectors.vectors.some((vector) => vector.id === "all-ground-ownership"));
assert.equal(worldGrade2V1GroundOwnership.chasm,"void+atmosphere"); assert.equal(worldGrade2V1Color("#292628",twinA.descriptor,{scope:"material",groundType:"chasm"}),worldGrade2V1Color("#292628",vectors.vectors.find((vector)=>vector.id==="far").descriptor,{scope:"material",groundType:"chasm"}));
const distances = vectors.similarity.slice(0, 4).map((entry) => entry.outputDistance); assert.deepEqual(distances, [...distances].sort((a, b) => a - b)); assert.equal(distances[0], 0); assert.equal(vectors.fog.invariant, true); assert.equal(vectors.fog.decodedRGBASHA256A, vectors.fog.decodedRGBASHA256B);
for (const forbidden of ["illumination", "vitality", "authoredInk", "authoredSigils", "currentlyVisible"]) { const invalid = structuredClone(twinA.request); invalid[forbidden] = forbidden === "illumination" ? 50 : {}; assert.equal(validateRequest(invalid), false, `${forbidden} must be schema-impossible`); assert.throws(() => resolveWorldGrade2V1(invalid)); }
for (const mutate of [
  (value) => { value.atmosphere = { medium:"none", density:20, paletteFamilyID:"clear" }; },
  (value) => { value.flora = { coveragePercent:20, paletteRichness:50, cast:[] }; },
  (value) => { value.flora.cast.push(structuredClone(value.flora.cast[0])); },
  (value) => { value.resolvedColors.flora = value.resolvedColors.floraTendency; },
]) { const invalid=structuredClone(twinA.request); mutate(invalid); assert.throws(()=>resolveWorldGrade2V1(invalid)); }
const fogA=worldGrade2V1FogRGBA({revealed:false,width:vectors.fog.width,height:vectors.fog.height}), fogB=worldGrade2V1FogRGBA({revealed:false,width:vectors.fog.width,height:vectors.fog.height}); assert.equal(sha(fogA),vectors.fog.decodedRGBASHA256A); assert.equal(sha(fogB),vectors.fog.decodedRGBASHA256B); assert.equal(worldGrade2V1FogRGBA({revealed:true,width:16,height:16}),null);
assert.ok(manifest.exclusions.some((value) => value.includes("Creature"))); assert.ok(manifest.exclusions.some((value) => value.includes("weapons"))); assert.ok(!canonicalJSON(twinA.request).toLowerCase().includes("illumination")); assert.ok(!canonicalJSON(twinA.request).toLowerCase().includes("vitality"));
console.log(`World-grade-2-v1 immutable pack passed: ${manifest.vectorCount} vectors · ${manifest.canonicalManifestSHA256}`);
