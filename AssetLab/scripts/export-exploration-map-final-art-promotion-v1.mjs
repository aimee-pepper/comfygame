import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const outputDirectory = path.join(root, "AssetLab/integration/exploration-map-final-art-promotion-v1");
const outputPath = path.join(outputDirectory, "promotion-receipt.json");
const sha256 = bytes => crypto.createHash("sha256").update(bytes).digest("hex");

const definitions = [
  {
    id: "exploration-map-identities-v1",
    sourceCommit: "d3dce437a3c33dae3316d13de7625d5dc9fe9c8f",
    manifestPath: "AssetLab/integration/exploration-map-identities-v1/runtime/manifest.json",
    expectedBody: "f28a55db110b92b9b0e82b8faca28392322551aac0fd8caa588ee3b283127c67",
    expectedAssetAggregate: "32ada00ca207d6eac6d8eee1de4917cfb6da03cc968d218a0b2b3b4ff197e990",
  },
  {
    id: "exploration-loose-items-v1",
    sourceCommit: "33aac2dc9254ecbd4d3e256ee4efdd390d56482d",
    manifestPath: "AssetLab/integration/exploration-loose-items-v1/runtime/manifest.json",
    expectedBody: "6491f2954f2a4593a5d8f1e566410ec7acd9300627e6a7dcd780d6a9b18764c2",
    expectedAssetAggregate: "475680934cd1318ec9ad3789def022c77bf139412329462d576084c4774786b5",
  },
  {
    id: "exploration-catalogue-objects-v1",
    sourceCommit: "bfd49d52bb3814c708161c4fe0256631dfadcb95",
    manifestPath: "AssetLab/integration/exploration-catalogue-objects-v1/runtime/manifest.json",
    expectedBody: "b3478c3dcf6d6e43fbdfdf5c6e90bc877fdbd287231c03516eccd0df1e2beeaf",
    expectedAssetAggregate: "9731e732f698580965faf8ecf9bdc0494b21d68746b4b19ec0f432cf4c6ad70a",
  },
];

const packs = {};
for (const definition of definitions) {
  const absoluteManifest = path.join(root, definition.manifestPath);
  const manifestBytes = fs.readFileSync(absoluteManifest);
  const manifest = JSON.parse(manifestBytes);
  if (manifest.schemaVersion !== definition.id
      || manifest.canonicalBodySHA256 !== definition.expectedBody
      || manifest.runtimeAssetAggregateSHA256 !== definition.expectedAssetAggregate) {
    throw new Error(`candidate-provenance-drift:${definition.id}`);
  }
  if (manifest.status !== "candidate-unapproved" || manifest.integrationReady !== false) {
    throw new Error(`candidate-status-must-remain-immutable:${definition.id}`);
  }
  const runtimeDirectory = path.dirname(absoluteManifest);
  const approvedStableKeys = Object.keys(manifest.assetsByKey).sort();
  for (const key of approvedStableKeys) {
    const asset = manifest.assetsByKey[key];
    const bytes = fs.readFileSync(path.join(runtimeDirectory, asset.path));
    if (sha256(bytes) !== asset.sha256) throw new Error(`asset-byte-drift:${definition.id}:${key}`);
  }
  packs[definition.id] = {
    sourceCommit: definition.sourceCommit,
    sourceManifestPath: definition.manifestPath,
    sourceManifestSHA256: sha256(manifestBytes),
    sourceCanonicalBodySHA256: manifest.canonicalBodySHA256,
    runtimeAssetAggregateSHA256: manifest.runtimeAssetAggregateSHA256,
    runtimePNGCount: manifest.coverage.runtimePNGs,
    stableKeyCount: approvedStableKeys.length,
    approvedStableKeys,
    production: manifest.production,
    requestABI: manifest.requestABI,
    visibilityContract: manifest.visibilityContract,
    animationContract: manifest.animationContract,
    layerContract: manifest.layerContract,
  };
}

const receipt = {
  schemaVersion: "exploration-map-final-art-promotion-v1",
  status: "aimee-approved-for-native-integration",
  integrationReady: true,
  approvalAuthority: "Aimee",
  approvalDate: "2026-08-23",
  sourceCommits: definitions.map(row => row.sourceCommit),
  promotionPolicy: {
    additiveReceiptOnly: true,
    candidateManifestsRemainImmutableProvenance: true,
    assetBytesChanged: false,
    runtimeImageGeneration: false,
    runtimeLookup: "exact stable key to complete premade PNG",
    filtering: "nearest-neighbour",
    unknownOrBlockedIdentity: "fail closed with no sprite lookup",
  },
  approvedVisibleFamilies: [
    "nine exact live sites with persisted unlooted/looted states where authorized",
    "generic persisted hazard",
    "entry and return portals",
    "locked cache",
    "loose World Page",
    "diary page",
    "found writing",
    "all 75 exact current catalogue gear identities",
    "all 27 exact current treasure, curio, consumable and key identities",
    "opaque unknown-curio disclosure identity",
    "simplified portal, page, site, resource, item, cache and hazard minimap identities"
  ],
  blockedVisibleFamilies: [
    { family: "named-travellers", policy: "blocked-no-lookup", reason: "no accepted final named-character art" },
    { family: "ordinary-and-apex-creatures", policy: "blocked-no-lookup", reason: "no accepted final generic trait-renderer art" },
    { family: "Binder", policy: "blocked-no-lookup", reason: "no accepted persisted Binder appearance model" },
    { family: "Quill", policy: "blocked-no-lookup", reason: "no accepted final Quill sprite" },
  ],
  nativeConsumption: {
    mapCanvas: [16, 19],
    mapPivot: [8, 18],
    tileSurface: [16, 16],
    minimapCanvas: [7, 7],
    mapLayerOrder: [
      "terrain-and-south-wall",
      "stationary-content",
      "party-identity-and-consequence-cues",
      "selection-and-interaction",
      "alerts-and-HUD"
    ],
    visibility: {
      full: "exact persisted identity/state; only authorized premade ambient frames advance",
      remembered: "same exact identity/state at frame 0",
      hidden: "no lookup and no draw"
    },
    frameSelection: {
      clock: "existing shared presentation clock",
      full: "presentationTick modulo exact key frame count",
      remembered: "frame 0",
      reducedMotion: "frame 0",
      persistedGameplayStateChanges: false,
      runtimeGeneratedPixels: false
    },
    minimapDisclosure: {
      categoriesOnly: true,
      keys: [
        "minimap/portal/ordinary",
        "minimap/page/ordinary",
        "minimap/site/ordinary",
        "minimap/resource/ordinary",
        "minimap/item",
        "minimap/cache/ordinary",
        "minimap/hazard/ordinary"
      ],
      forbidden: ["site subtype", "site loot state", "catalogue item subtype", "resource subtype"]
    }
  },
  packs,
};

receipt.coverage = {
  approvedStableKeys: Object.values(packs).reduce((sum, pack) => sum + pack.stableKeyCount, 0),
  runtimePNGs: Object.values(packs).reduce((sum, pack) => sum + pack.runtimePNGCount, 0),
  catalogueIDs: 102,
  exactSites: 9,
  minimapCategories: 7,
};
receipt.canonicalBodySHA256 = sha256(Buffer.from(JSON.stringify(receipt)));
fs.mkdirSync(outputDirectory, { recursive: true });
fs.writeFileSync(outputPath, `${JSON.stringify(receipt, null, 2)}\n`);
console.log(JSON.stringify({
  body: receipt.canonicalBodySHA256,
  file: sha256(fs.readFileSync(outputPath)),
  stableKeys: receipt.coverage.approvedStableKeys,
  runtimePNGs: receipt.coverage.runtimePNGs,
}, null, 2));
