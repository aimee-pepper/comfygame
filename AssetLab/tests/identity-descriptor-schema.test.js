import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import Ajv2020 from "ajv/dist/2020.js";
import { defaults, normalizeDescriptor, presets } from "../src/generator.js";
import { creatureLiveContract } from "../src/live-contract.js";

const readSchema = async (name) => JSON.parse(await readFile(
  new URL(`../schemas/${name}`, import.meta.url), "utf8"
));

const identitySchema = await readSchema("identity-descriptor.schema.json");
const renderHintsSchema = await readSchema("render-hints.schema.json");
const renderRequestSchema = await readSchema("render-request.schema.json");
const exportManifestSchema = await readSchema("export-manifest.schema.json");
const liveCreatureSchema = await readSchema("live-creature-identity.schema.json");
const liveFloraSchema = await readSchema("live-flora-identity.schema.json");
const floraIdentitySchema = await readSchema("flora-identity.schema.json");

// The existing export manifest intentionally permits string or integer pipeline versions.
const ajv = new Ajv2020({ strict: true, allowUnionTypes: true, allErrors: true });
for (const schema of [identitySchema, renderHintsSchema, liveCreatureSchema,
  liveFloraSchema, floraIdentitySchema, renderRequestSchema]) {
  ajv.addSchema(schema);
}
const validateIdentity = ajv.getSchema(identitySchema.$id);
const validateRenderHints = ajv.getSchema(renderHintsSchema.$id);
const validateRenderRequest = ajv.getSchema(renderRequestSchema.$id);
const validateExportManifest = ajv.compile(exportManifestSchema);

const fennec = normalizeDescriptor({ ...defaults, logicalID: "fennec-like", traits: presets["Dune long-ear"] });
const wingedSerpent = normalizeDescriptor({ ...defaults, logicalID: "winged-serpent", traits: presets["Membrane sky serpent"] });
for (const descriptor of [fennec, wingedSerpent]) {
  assert.equal(validateIdentity(descriptor), true, JSON.stringify(validateIdentity.errors));
  assert.equal(validateRenderRequest({ identityDescriptor: descriptor, profile: "world", pixelWidth: 16, pixelHeight: 16 }), true,
    JSON.stringify(validateRenderRequest.errors));
}

const invalidWingedBody = structuredClone(wingedSerpent);
invalidWingedBody.traits.bodyPlan = "winged";
assert.equal(validateIdentity(invalidWingedBody), false, "winged must not re-enter the axial body-plan vocabulary");

const legacyV4 = structuredClone(defaults);
legacyV4.schemaVersion = 4;
delete legacyV4.traits.bodyPlan;
delete legacyV4.traits.cranialFeature;
legacyV4.traits.topology = "winged";
legacyV4.traits.appendageType = "feathered";
assert.equal(validateIdentity(legacyV4), false, "the canonical v5 export boundary must reject legacy topology");
const migrated = normalizeDescriptor(legacyV4);
assert.equal(migrated.schemaVersion, 5);
assert.equal(migrated.traits.bodyPlan, "biped");
assert.equal(migrated.traits.cranialFeature, "none");
assert.equal(migrated.traits.appendageType, "feathered");
assert.equal("topology" in migrated.traits, false);
assert.equal(validateIdentity(migrated), true, JSON.stringify(validateIdentity.errors));

const { gameIdentity, renderHints, adapterDiagnostics } = creatureLiveContract(wingedSerpent);
assert.equal(validateRenderHints(renderHints), true, JSON.stringify(validateRenderHints.errors));
assert.equal(validateRenderHints({ schemaVersion: 1 }), true, "flora v1 render hints remain valid");
assert.equal(validateRenderHints({ schemaVersion: 2, bodyPlan: "winged", cranialFeature: "crest" }), false);
const creatureManifest = {
  manifestVersion: 3,
  identityKind: "creature",
  logicalID: wingedSerpent.logicalID,
  authoringDescriptor: wingedSerpent,
  gameIdentity,
  renderHints,
  adapterDiagnostics,
  pipelineVersions: { generator: 5 },
  outputs: [{ profile: "world", file: "winged-serpent.png", pixelWidth: 16, pixelHeight: 16,
    pivot: { x: 8, y: 8 }, pixelHash: "1ac43f01" }]
};
assert.equal(validateExportManifest(creatureManifest), true, JSON.stringify(validateExportManifest.errors));
assert.equal(validateExportManifest({ ...creatureManifest, renderHints: { schemaVersion: 1 } }), false,
  "creature exports must not validate with Flora render hints");

console.log("Asset Lab creature identity schema v5 tests passed.");
