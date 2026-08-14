import assert from "node:assert/strict";
import {
  defaults, cloneDescriptor, normalizeDescriptor, creatureCommands, terrainCommands,
  floraCommands, canonicalJSON, hash, paletteFor, traitDefinitions,
  compatibilityWarnings, populationDescriptors, presets, anatomySummary
  , commandBounds, rebalanceAllocation, safeFilePart
} from "../src/generator.js";

const first = creatureCommands(defaults, "world");
const second = creatureCommands(cloneDescriptor(defaults), "world");
assert.equal(safeFilePart(" ../Moss / Bloom?! "),"Moss-Bloom");
assert.equal(safeFilePart("...","flora"),"flora");
assert.deepEqual(first, second, "same descriptor and profile must produce the same commands");
assert.equal(hash(first), hash(second), "deterministic commands must hash equally");

const changed = cloneDescriptor(defaults);
changed.speciesSeed += 1;
assert.notEqual(hash(creatureCommands(changed, "world")), hash(first), "species seed should affect output");
const specimen = cloneDescriptor(defaults);
specimen.specimenSeed += 1;
assert.notEqual(hash(creatureCommands(specimen, "world")), hash(first), "specimen seed should affect bounded cosmetic variation");
assert.notEqual(hash(creatureCommands(defaults, "fight")), hash(first), "profiles should differ");

const malformed = normalizeDescriptor({ seed: -5, traits: { size: 999, appendageType: "wheels" } });
assert.equal(malformed.speciesSeed, 0);
assert.equal(malformed.traits.size, 100);
assert.equal(malformed.traits.appendageType, defaults.traits.appendageType);

assert.equal(canonicalJSON({ b: 2, a: 1 }), '{"a":1,"b":2}');
assert.equal(terrainCommands("soil", 12).length, terrainCommands("soil", 12).length);
assert.ok(floraCommands(defaults).length > terrainCommands("soil", defaults.speciesSeed).length);
assert.deepEqual(paletteFor(defaults), paletteFor(cloneDescriptor(defaults)));

const geometryHash = commands => hash(commands.map(({ color, ...geometry }) => geometry));
const bodyPlan = traitDefinitions.find(definition => definition.key === "bodyPlan");
const cranialFeature = traitDefinitions.find(definition => definition.key === "cranialFeature");
const worldBodyPlans = new Set();
const fightBodyPlans = new Set();
for (const value of bodyPlan.options) {
  const candidate = cloneDescriptor(defaults);
  candidate.traits.bodyPlan = value;
  worldBodyPlans.add(geometryHash(creatureCommands(candidate, "world")));
  fightBodyPlans.add(geometryHash(creatureCommands(candidate, "fight")));
}
assert.equal(worldBodyPlans.size, bodyPlan.options.length, "every body plan needs a distinct world silhouette");
assert.equal(fightBodyPlans.size, bodyPlan.options.length, "every body plan needs a distinct fight silhouette");

const cranialSilhouettes = new Set();
for (const value of cranialFeature.options) {
  const candidate = cloneDescriptor(defaults);
  candidate.traits.cranialFeature = value;
  cranialSilhouettes.add(geometryHash(creatureCommands(candidate, "fight")));
}
assert.equal(cranialSilhouettes.size, cranialFeature.options.length,
  "every cranial feature needs a distinct fight silhouette");

for (const trait of ["pierce", "crush", "rend", "coveringHardness", "coveringLength", "patterning", "ornament", "emanationStrength"]) {
  const low = cloneDescriptor(defaults), high = cloneDescriptor(defaults);
  low.traits[trait] = 0; high.traits[trait] = 100;
  assert.notEqual(hash(creatureCommands(low, "fight")), hash(creatureCommands(high, "fight")), `${trait} needs visible fight influence`);
}

const incompatible = cloneDescriptor(defaults);
incompatible.traits.appendageType = "none";
incompatible.traits.appendageCount = 8;
assert.ok(compatibilityWarnings(incompatible).some(warning => warning.includes("ignored")));
const population = populationDescriptors(defaults, 24);
assert.equal(population.length, 24);
assert.equal(new Set(population.map(candidate => candidate.specimenSeed)).size, 24);
assert.equal(new Set(population.map(candidate => candidate.traits.bodyPlan)).size, bodyPlan.options.length);
assert.ok(new Set(population.map(candidate => candidate.traits.cranialFeature)).size > 1);
const specimens = populationDescriptors(defaults, 24, "species");
assert.equal(new Set(specimens.map(candidate => candidate.speciesSeed)).size, 1);
assert.equal(new Set(specimens.map(candidate => candidate.specimenSeed)).size, 24);
assert.equal(new Set(specimens.map(candidate => canonicalJSON(candidate.traits))).size, 1);

for (const [profile, size] of [["world", 16], ["fight", 48]]) {
  for (const candidate of population) {
    const bounds = commandBounds(creatureCommands(candidate, profile));
    assert.ok(bounds.minX >= 0 && bounds.minY >= 0 && bounds.maxX <= size && bounds.maxY <= size, `${profile} output must remain inside its canvas`);
  }
}

const allocation = cloneDescriptor(defaults).traits;
rebalanceAllocation(allocation, "vision", ["vision", "mechano", "chemo", "thermo"], 80);
assert.equal(allocation.vision + allocation.mechano + allocation.chemo + allocation.thermo, 100);
assert.equal(allocation.vision, 80);
const normalizedAllocation = normalizeDescriptor({ ...defaults, traits: { ...defaults.traits, cyan: 100, magenta: 100, yellow: 100 } });
assert.equal(normalizedAllocation.traits.cyan + normalizedAllocation.traits.magenta + normalizedAllocation.traits.yellow, 100);

const transparent = cloneDescriptor(defaults), opaque = cloneDescriptor(defaults);
transparent.traits.opacity = 0; opaque.traits.opacity = 100;
assert.ok(creatureCommands(transparent, "fight").some(command => command.color.includes(" / ")));
assert.notEqual(hash(creatureCommands(transparent, "fight")), hash(creatureCommands(opaque, "fight")));

for (const definition of traitDefinitions) {
  // Exact sensory allocation is intentionally disclosure-neutral in exported pixels. The
  // authoring values remain in the descriptor for later analysis UI, not anatomy badges.
  if (["vision", "mechano", "chemo", "thermo"].includes(definition.key)) continue;
  const values = definition.options ?? [definition.min, definition.max];
  const visible = new Set();
  for (const value of values) {
    const candidate = cloneDescriptor(defaults);
    if (["emanationLight","emanationHeat","emanationCaustic"].includes(definition.key)) candidate.traits.emanationStrength = 80;
    if (definition.key === "coveringCoverage") {
      candidate.traits.coveringHardness = 80;
      candidate.traits.coveringLength = 80;
    }
    candidate.traits[definition.key] = value;
    visible.add(hash([creatureCommands(candidate, "world"), creatureCommands(candidate, "fight")]));
  }
  assert.ok(visible.size > 1, `${definition.key} must visibly influence at least one profile`);
}

for (const [name, traits] of Object.entries(presets)) {
  const candidate = normalizeDescriptor({ ...defaults, logicalID: name, traits });
  assert.equal(candidate.logicalID, name);
  assert.ok(creatureCommands(candidate, "world").length > 0);
  assert.ok(creatureCommands(candidate, "fight").length > 0);
  assert.ok(anatomySummary(candidate).includes(candidate.traits.bodyPlan));
}

const longEar = normalizeDescriptor({ ...defaults, logicalID:"dune-long-ear", traits:presets["Dune long-ear"] });
const wingedSerpent = normalizeDescriptor({ ...defaults, logicalID:"membrane-sky-serpent", traits:presets["Membrane sky serpent"] });
assert.equal(longEar.traits.bodyPlan,"quadruped");
assert.equal(longEar.traits.cranialFeature,"longEars");
assert.equal(wingedSerpent.traits.bodyPlan,"serpentine");
assert.equal(wingedSerpent.traits.cranialFeature,"crest");
assert.equal(wingedSerpent.traits.appendageType,"membrane","wings must remain independent of axial topology");
assert.notEqual(geometryHash(creatureCommands(longEar,"world")),geometryHash(creatureCommands(wingedSerpent,"world")));
assert.notEqual(geometryHash(creatureCommands(longEar,"fight")),geometryHash(creatureCommands(wingedSerpent,"fight")));
assert.ok(creatureCommands(longEar,"fight").some(command=>command.h>=7),"long-ear fixture needs a tall cranial silhouette");
assert.ok(creatureCommands(wingedSerpent,"fight").some(command=>command.w>=8&&command.h===3),"winged serpent needs a membrane span");

const migratedWinged = normalizeDescriptor({schemaVersion:4,traits:{topology:"winged",appendageType:"feathered"}});
assert.equal(migratedWinged.schemaVersion,5);
assert.equal(migratedWinged.traits.bodyPlan,"biped");
assert.equal(migratedWinged.traits.appendageType,"feathered");
assert.equal("topology" in migratedWinged.traits,false);

console.log("Asset Lab generator tests passed.");
