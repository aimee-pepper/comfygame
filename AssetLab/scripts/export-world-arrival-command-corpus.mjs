import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { arrivalSceneCommands } from "../src/world-arrival-kit.js";
import { canonicalJSON, canonicalSHA256, corpusCommands, makeCorpusRecord, renderCorpusCommands, sha256 } from "../src/world-arrival-command-corpus.js";

const { createCanvas } = createRequire(import.meta.url)("@napi-rs/canvas");
const root = path.resolve(import.meta.dirname, "..");
const output = path.join(root, "integration/world-arrival-command-corpus-v1");
const fixtureRoot = path.join(root, "fixtures/world-arrival-v1");
const acceptedArtifact = path.join(root, "artifacts/world-arrival-v0.1/manifest.json");
const sourcePath = path.join(root, "src/world-arrival-kit.js");
const fixtureNames = fs.readdirSync(fixtureRoot).filter(name => name.endsWith(".json")).sort();
const fixtures = Object.fromEntries(fixtureNames.map(name => [name.slice(0, -5), JSON.parse(fs.readFileSync(path.join(fixtureRoot, name)))]));
const clone = value => structuredClone(value);
const base = fixtures.starter_open_meadow;
const cases = new Map();
const add = (id, receipt, metadata) => { if (cases.has(id)) throw new Error(`duplicate-corpus-case:${id}`); cases.set(id, { receipt, metadata }); };

for (const id of Object.keys(fixtures).sort()) add(`accepted/${id}`, clone(fixtures[id]), { family: "accepted-fixture", fixtureID: id });

const counterfactual = (id, edit, allowedScopes) => { const receipt = clone(base); edit(receipt); add(`scope-counterfactual/${id}`, receipt, { family: "scope-counterfactual", allowedScopes }); };
counterfactual("illumination", receipt => { receipt.illumination = { band: "ordinary", sourceClass: "cyclic" }; }, ["illumination"]);
counterfactual("suspended", receipt => { receipt.suspendedAtmosphere = { medium: "smoke", density: "trace", motion: "moving" }; }, ["suspended"]);
counterfactual("precipitation", receipt => { receipt.precipitation = { medium: "rain", intensity: "trace", motion: "moving" }; }, ["precipitation"]);
counterfactual("resource-band", receipt => { receipt.causalVisualFacts = [{ markID: "common_ore", visibleScope: "resource", contributionKind: "increased", resultBand: "present", withoutAuthoredBand: "absent" }]; }, []);
counterfactual("title-only", receipt => { receipt.sourcePage.title = "Title has no scene authority"; }, []);

const mutate = (id, family, edit, extra = {}) => { const receipt = clone(base); receipt.receiptID = `corpus-${id}`; edit(receipt); add(`${family}/${id}`, receipt, { family, ...extra }); };

for (const ground of ["stone", "soil", "sand", "ice", "ash", "rubble", "mud", "growth", "groundcover"]) {
  mutate(ground, "dominant-ground", receipt => { receipt.dominantGround = ground; receipt.materialDescriptor.identity = ground; }, { ground });
}
for (const relationship of ["none", "pools", "channels", "shelves", "islands"]) {
  mutate(relationship, "water-relationship", receipt => { receipt.waterRelationship = relationship; }, { relationship });
}
const lights = ["trueDark", "dim", "ordinary", "bright", "blazing"];
lights.forEach((band, index) => mutate(`${band}-${["sourceless", "cyclic", "constant"][index % 3]}`, "illumination", receipt => {
  receipt.illumination = { band, sourceClass: ["sourceless", "cyclic", "constant"][index % 3] };
}, { band, sourceClass: ["sourceless", "cyclic", "constant"][index % 3] }));

const suspendedCases = [
  ["none", "none", "calm"], ["smoke", "trace", "moving"], ["airborneAsh", "light", "strong"],
  ["mist", "heavy", "calm"], ["miasma", "dense", "moving"]
];
for (const [medium, density, motion] of suspendedCases) mutate(`${medium}-${density}-${motion}`, "suspended", receipt => {
  receipt.suspendedAtmosphere = { medium, density, motion };
}, { medium, density, motion });

const precipitationCases = [
  ["none", "none", "calm"], ["rain", "trace", "moving"], ["snow", "light", "strong"], ["mixedRainSnow", "heavy", "calm"]
];
for (const [medium, intensity, motion] of precipitationCases) mutate(`${medium}-${intensity}-${motion}`, "precipitation", receipt => {
  receipt.precipitation = { medium, intensity, motion };
}, { medium, intensity, motion });

const floraRows = [
  { stableID: "corpus-a", formID: 1, coverage: "sparse", habit: "solitary", color: [52, 122, 98] },
  { stableID: "corpus-b", formID: 2, coverage: "present", habit: "clustered", color: [85, 168, 130] },
  { stableID: "corpus-c", formID: 3, coverage: "abundant", habit: "spreading", color: [115, 163, 93] },
  { stableID: "corpus-d", formID: 4, coverage: "present", habit: "mixed", color: [66, 112, 75] }
];
for (let count = 0; count <= 4; count++) mutate(`count-${count}`, "flora-boundary", receipt => { receipt.flora = floraRows.slice(0, count); }, { count, habits: floraRows.slice(0, count).map(row => row.habit) });

for (const scope of ["ground", "water", "flora", "resource", "light", "atmosphere"]) mutate(scope, "causal-scope", receipt => {
  receipt.causalVisualFacts = [{ markID: "plains", visibleScope: scope, contributionKind: scope === "resource" ? "increased" : "reshaped", resultBand: scope === "resource" ? "present" : "changed", withoutAuthoredBand: scope === "resource" ? "present" : "baseline" }];
}, { scope, imageAuthority: false });

mutate("entry-visible", "entry-disclosure", receipt => { receipt.entryDisclosure = { siteProfile: "settled-entry-site", status: "entryVisible" }; }, { disclosed: true });
mutate("entry-absent", "entry-disclosure", receipt => { receipt.entryDisclosure = null; }, { disclosed: false });

const maximal = clone(fixtures.starter_stone_hollow);
maximal.receiptID = "corpus-maximal-seed";
maximal.flora = floraRows.map(row => ({ ...row, coverage: "abundant" }));
maximal.suspendedAtmosphere = { medium: "miasma", density: "dense", motion: "strong" };
maximal.precipitation = { medium: "mixedRainSnow", intensity: "heavy", motion: "strong" };
maximal.entryDisclosure = { siteProfile: "settled-entry-site", status: "entryVisible" };
for (let seed = 0; seed < 32; seed++) { const receipt = clone(maximal); receipt.worldSeed = String(seed); add(`seed-matrix/${String(seed).padStart(2, "0")}`, receipt, { family: "seed-matrix", seed, purpose: "material-width/jitter/placement/max-command coverage" }); }

const orderedCases = [...cases.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([id, value]) => makeCorpusRecord(id, value.receipt, value.metadata));

function canvasRGBA(commands) {
  const canvas = createCanvas(160, 100), context = canvas.getContext("2d");
  for (const command of commands) { context.fillStyle = command.color; context.fillRect(command.x, command.y, command.w, command.h); }
  return new Uint8ClampedArray(context.getImageData(0, 0, 160, 100).data);
}

for (const record of orderedCases) {
  const acceptedRGBA = canvasRGBA(arrivalSceneCommands(record.receipt)), replayRGBA = renderCorpusCommands(record.arrivalSceneCommands);
  if (!Buffer.from(acceptedRGBA).equals(Buffer.from(replayRGBA))) throw new Error(`command-replay-pixel-mismatch:${record.id}`);
}

const sourceSHA256 = sha256(fs.readFileSync(sourcePath)), acceptedManifestSHA256 = sha256(fs.readFileSync(acceptedArtifact));
const commandCounts = orderedCases.map(record => record.arrivalSceneCommands.length), maxCommandCount = Math.max(...commandCounts);
const maxCases = orderedCases.filter(record => record.arrivalSceneCommands.length === maxCommandCount).map(record => record.id);
const materialWidths = [...new Set(orderedCases.filter(record => record.id.startsWith("seed-matrix/"))
  .flatMap(record => record.arrivalSceneCommands.filter(command => command.scope === "material" && command.height === 1).map(command => command.width)))].sort((a, b) => a - b);
const stonePathJitters = [...new Set(orderedCases.filter(record => record.id.startsWith("seed-matrix/"))
  .flatMap(record => record.arrivalSceneCommands.filter(command => command.scope === "ground" && command.height === 1 && command.y >= 53 && command.y < 90)
    .filter(command => command.width === (5 + Math.floor((command.y - 53) * .42)) * 2)
    .map(command => command.x - (80 - command.width / 2))))].sort((a, b) => a - b);
const seededPlacementSignatures = new Set(orderedCases.filter(record => record.id.startsWith("seed-matrix/"))
  .map(record => canonicalSHA256(record.arrivalSceneCommands.filter(command => ["ground", "material", "suspended", "precipitation"].includes(command.scope))))).size;
const scopeDiffPairs = [
  { id: "flora", before: "accepted/starter_open_meadow", after: "accepted/near_flora", allowedScopes: ["flora"] },
  { id: "illumination", before: "accepted/starter_open_meadow", after: "scope-counterfactual/illumination", allowedScopes: ["illumination"] },
  { id: "suspended", before: "accepted/starter_open_meadow", after: "scope-counterfactual/suspended", allowedScopes: ["suspended"] },
  { id: "precipitation", before: "accepted/starter_open_meadow", after: "scope-counterfactual/precipitation", allowedScopes: ["precipitation"] },
  { id: "resource-band", before: "accepted/starter_open_meadow", after: "scope-counterfactual/resource-band", allowedScopes: [] },
  { id: "title-only", before: "accepted/starter_open_meadow", after: "scope-counterfactual/title-only", allowedScopes: [] }
];
const byID = new Map(orderedCases.map(record => [record.id, record]));
const scopePixelHash = (commands, scope) => sha256(renderCorpusCommands(commands.filter(command => command.scope === scope).map((command, sourceOrder) => ({ ...command, sourceOrder }))));
const diffReport = scopeDiffPairs.map(pair => {
  const before = byID.get(pair.before).arrivalSceneCommands, after = byID.get(pair.after).arrivalSceneCommands;
  const scopes = [...new Set([...before, ...after].map(command => command.scope))];
  const changedScopes = scopes.filter(scope => scopePixelHash(before, scope) !== scopePixelHash(after, scope)).sort();
  if (changedScopes.some(scope => !pair.allowedScopes.includes(scope))) throw new Error(`scope-diff-leak:${pair.id}:${changedScopes.join(",")}`);
  return { ...pair, changedScopes };
});

const corpus = {
  schemaVersion: 1,
  identity: "world-arrival-command-corpus-v1",
  integrationReady: false,
  canvas: { width: 160, height: 100 },
  commandABI: { op: "rect-v1", fields: ["op", "x", "y", "width", "height", "rgba", "scope", "sourceOrder"] },
  pins: {
    compositorFile: "AssetLab/src/world-arrival-kit.js",
    compositorSHA256: sourceSHA256,
    compositorCommit: "9b60e8516f08806d40c38ed2a4307746c13d1c8c",
    acceptedManifestFile: "AssetLab/artifacts/world-arrival-v0.1/manifest.json",
    acceptedManifestSHA256,
    latestReceiptCommit: "72b840d3e1de2b8c32aebfc0e876d61c69448a92"
  },
  coverage: {
    caseCount: orderedCases.length,
    acceptedFixtureCount: Object.keys(fixtures).length,
    closedBoundaries: {
      dominantGround: ["stone", "soil", "sand", "ice", "ash", "rubble", "mud", "growth", "groundcover"],
      waterRelationship: ["none", "pools", "channels", "shelves", "islands"],
      illuminationBand: ["trueDark", "dim", "ordinary", "bright", "blazing"],
      illuminationSourceClass: ["sourceless", "cyclic", "constant"],
      suspendedMedium: ["none", "smoke", "airborneAsh", "mist", "miasma"],
      suspendedDensity: ["none", "trace", "light", "heavy", "dense"],
      precipitationMedium: ["none", "rain", "snow", "mixedRainSnow"],
      precipitationIntensity: ["none", "trace", "light", "heavy"],
      motion: ["calm", "moving", "strong"], floraCount: [0, 1, 2, 3, 4],
      floraHabit: ["solitary", "clustered", "spreading", "mixed"], entryDisclosure: ["null", "entryVisible"]
    },
    seedMatrix: { seeds: [...Array(32).keys()], materialWidths, stonePathJitters, seededPlacementSignatures, maxCommandCount, maxCases },
    families: Object.fromEntries([...new Set(orderedCases.map(record => record.metadata.family))].sort().map(family => [family, orderedCases.filter(record => record.metadata.family === family).length]))
  },
  scopeDiffPairs: diffReport,
  cases: orderedCases
};
corpus.canonicalBodySHA256 = canonicalSHA256(corpus);

fs.rmSync(output, { recursive: true, force: true });
fs.mkdirSync(output, { recursive: true });
fs.writeFileSync(path.join(output, "corpus.json"), JSON.stringify(corpus, null, 2) + "\n");
const sample = orderedCases.find(record => record.id === "accepted/starter_open_meadow");
const report = [
  "# World Arrival command corpus v1", "",
  `- Cases: ${orderedCases.length}`,
  `- Maximum command count: ${maxCommandCount} (${maxCases.join(", ")})`,
  `- Seeded material widths exercised: ${materialWidths.join(", ")}`,
  `- Seeded Stone Hollow path jitters exercised: ${stonePathJitters.join(", ")}`,
  `- Unique seeded placement signatures: ${seededPlacementSignatures}`,
  `- Canonical body: ${corpus.canonicalBodySHA256}`, "",
  "## Scope-contained counterfactuals", "",
  ...diffReport.map(row => `- ${row.id}: ${row.before} → ${row.after}; changed ${row.changedScopes.join(", ") || "none"}`), "",
  "## Ordered command sample", "",
  `Case: ${sample.id}`, "```json", JSON.stringify(sample.arrivalSceneCommands.slice(0, 8), null, 2), "```", ""
].join("\n");
fs.writeFileSync(path.join(output, "sample-report.md"), report);
console.log(`${corpus.identity} ${corpus.canonicalBodySHA256} · ${orderedCases.length} cases · max ${maxCommandCount} commands`);
