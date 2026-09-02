const GROUND_TYPES = Object.freeze([
  "stone", "soil", "sand", "ice", "ash", "water", "deepWater", "rubble", "mud",
  "growth", "chasm", "groundcover",
]);
const COVERAGE_BANDS = Object.freeze(["none", "trace", "sparse", "present", "abundant", "dominant"]);
const WATER_TOPOLOGIES = Object.freeze([
  "standing", "flowing", "pool", "lake", "channel", "shelf", "island", "broken",
]);
const ILLUMINATION_BANDS = Object.freeze(["trueDark", "dim", "ordinary", "bright", "blazing"]);
const ILLUMINATION_SOURCE_CLASSES = Object.freeze(["sourceless", "constant", "cyclic"]);
const SUSPENDED_MEDIA = Object.freeze(["none", "smoke", "airborneAsh", "mist", "miasma"]);
const SUSPENDED_DENSITIES = Object.freeze(["none", "trace", "light", "heavy", "dense"]);
const PRECIPITATION_MEDIA = Object.freeze(["none", "rain", "snow", "mixedRainSnow"]);
const PRECIPITATION_INTENSITIES = Object.freeze(["none", "trace", "light", "heavy"]);
const MOTION_BANDS = Object.freeze(["calm", "moving", "strong"]);
const FLORA_HABITS = Object.freeze(["spreading", "clustered", "solitary"]);
const FLORA_FORMS = Object.freeze([0, 1, 2, 3]);
const FLORA_COLOR_PROVENANCE = Object.freeze(["authoredMix", "bindRandom"]);
const HANDS = Object.freeze(["crude", "plain", "refined"]);

const SOURCE_HASHES = Object.freeze({
  queue: {
    path: "docs/aimee-phone-audit-correction-queue-2026-08-24.md",
    sha256: "42aad7dd3df22dce7fa5aeb28f7c1cfd2c0f27ccb68a4ee53e3887abc4cf819d",
    provenance: "Aimee-owned queue supplied from the preserved shared checkout; untracked there and read-only here",
  },
  worldSplashReceiptV3: {
    path: "Sources/Model/WorldArrivalReceipt.swift",
    sha256: "87955c0856b160bc2a9c5119a7894ad8e9a41227f0b606c6ad336901b72e93ca",
  },
  nativePlaceholderRenderer: {
    path: "Sources/VisualRuntime/WorldArrivalRenderer.swift",
    sha256: "5dbe8f9de503c0c7b58d47a2cb2e8020f3bcff862df91bbdbb014ffd410a4aef",
  },
  worldArrivalView: {
    path: "Sources/Screens/WorldArrivalView.swift",
    sha256: "fbcf1c1bf766df33a3b98549b43628bc3a15686b99b1e84b5fb0acdbd0621632",
  },
  worldGrade2: {
    path: "Sources/VisualRuntime/WorldGrade2V1.swift",
    sha256: "b7319d145a768997983ef018a92320f37aa2db0cbab2f664cc394ba51e685ff4",
  },
  worldVisualReceipt: {
    path: "Sources/Model/WorldVisualReceipt.swift",
    sha256: "b262eacb665a888092ad3a80710be4ed9d44f93fc7b3b3d94650135c15f13685",
  },
  groundVocabulary: {
    path: "Sources/Model/WorldMap.swift",
    sha256: "7a42213d75f3772a02ff34799d5d557adcc12db93513176238697f5bc0df202c",
  },
  pageVocabulary: {
    path: "Sources/Model/Page.swift",
    sha256: "f771a53a6988bcf749ad53d7bbb0cb6750e3cfbcea29aaebe2ff46ea8f615e18",
  },
  floraVocabulary: {
    path: "Sources/Model/FloraTraits.swift",
    sha256: "40e04b8072012370d4ced622526e2abbb6520742af7411c4007d66baef964335",
  },
  generatorAuthority: {
    path: "docs/world-splash-generator-current.md",
    sha256: "248e000a5c1ff642378e3ee4718ed627d50f96f575fadb0b8ac83cb342b955a7",
  },
});

const movingDimensions = Object.freeze({
  visibleCrop: "320×360 logical pixels",
  authoredCanvas: "320×360 crop plus the already-approved plane-specific motion envelope",
  overscan: "Cover the frozen maximum excursion on every moving edge; SPLASH-01 does not restate or edit offsets",
});
const staticDimensions = Object.freeze({
  visibleCrop: "320×360 logical pixels",
  authoredCanvas: "320×360 logical pixels",
  overscan: "None required; Sky is static",
});

const row = (id, name, description, semanticScopes, sourceFields, variants, sharingReuse,
  transparencyEdges, dimensionsOverscan = movingDimensions) => Object.freeze({
  id, name, description, semanticScopes, sourceFields, dimensionsOverscan, variants,
  sharingReuse, transparencyEdges,
  completionStatus: "Required asset family · no final artwork supplied",
});

const layers = Object.freeze([
  Object.freeze({
    id: "foreground", name: "Foreground", motion: "moves", motionLabel: "Moves · contract locked",
    rows: Object.freeze([
      row("foreground-ground-edge", "Nearest ground edge", "The close ground lip that anchors the scene.",
        ["terrainMass"],
        ["terrain.grounds", "terrain.dominantDryGround", "terrain.secondaryVisibleGrounds", "terrain.regions[].groundShares", "terrain.materialPresentation"],
        [`Ground: ${GROUND_TYPES.join(", ")}`, `Coverage: ${COVERAGE_BANDS.join(", ")}`, "Resolved material palette and recolor descriptor"],
        "Share palette roles and material texture grammar with all terrain depths; paint a distinct near silhouette.",
        "Transparent above the ground silhouette; calm, clean outer crop edges and no baked Sky."),
      row("foreground-water-edge", "Nearest water edge", "Close banks, ice lips and deep-water cuts.",
        ["waterStructure"],
        ["water", "terrain.regions[].waterShares", "terrain.materialPresentation"],
        ["Shallow, deep and frozen", `Topology: ${WATER_TOPOLOGIES.join(", ")}`, `Coverage: ${COVERAGE_BANDS.join(", ")}`],
        "Reuse water palette roles and topology grammar across depth planes; near contours need their own authored edge.",
        "Transparent away from water; banks cannot leave seams or imply false traversable ground."),
      row("foreground-relief", "Nearest relief face", "Close elevation steps and exposed south faces.",
        ["relief"],
        ["relief.elevationCounts", "relief.maximumElevation", "relief.southContactCounts", "relief.elevatedComponentSizes", "relief.shapeFlags", "terrain.regions[].elevationShares"],
        ["Elevation 0, 1, 2, 3", "South-contact depth 1, 2, 3", "Only defined shape label: flat"],
        "Reuse the selected ground material; never recolor an equal-height boundary into a wall.",
        "Transparent except genuine relief pixels; every moving extreme must stay inside the authored canvas."),
      row("foreground-deposits", "Nearest snow and Ash", "Surface dusting that sits on the closest ground.",
        ["surfaceDeposit"],
        ["deposits.snowCount", "deposits.snowCoverage", "deposits.settledAshCount", "deposits.settledAshCoverage", "terrain.regions[].depositShares"],
        ["Snow", "Settled Ash", "Snow + settled Ash", `Coverage: ${COVERAGE_BANDS.join(", ")}`],
        "One reusable overlay family per deposit, recolored only by its exact production palette.",
        "Transparent overlay with broken material edges; never hides the base ground read."),
      row("foreground-flora", "Nearest flora forms", "Readable close plant crowns from every placed species.",
        ["floraIdentity", "floraDistribution"],
        ["flora.species[].stableID", "flora.species[].renderIdentity", "flora.species[].placedTileCount", "flora.species[].coverage", "flora.species[].habit", "flora.species[].eligibleGrounds", "flora.species[].regionShares", "flora.aggregateCoverage"],
        [`Form ID: ${FLORA_FORMS.join(", ")}`, "Stature: 0…100", `Habit: ${FLORA_HABITS.join(", ")}`, `Color provenance: ${FLORA_COLOR_PROVENANCE.join(", ")}`, `Coverage: ${COVERAGE_BANDS.join(", ")}`, "Every placed species; no four-species cap"],
        "Reuse form masks and resolved-color slots across depths; keep each persisted species identity distinct.",
        "Transparent cutouts with no rectangular patch; silhouettes must survive literal grayscale."),
      row("foreground-precipitation", "Precipitation overlay", "Rain or snow crossing the nearest scene plane.",
        ["precipitation"],
        ["environment.precipitationMedium", "environment.precipitationIntensity", "environment.precipitationMotion"],
        [`Medium: ${PRECIPITATION_MEDIA.join(", ")}`, `Intensity: ${PRECIPITATION_INTENSITIES.join(", ")}`, `Motion band: ${MOTION_BANDS.join(", ")}`],
        "Share mark families between intensity levels; density changes may repeat or thin them without changing medium.",
        "Transparent overlay; no opaque veil, no new weather, and no animation values authored here."),
      row("foreground-entry-mark", "Entry Sigil in material", "The first disclosed mark worked into nearby ground.",
        ["entryMark"],
        ["entryMark.markID", "entryMark.rendererAssetKey", "entryMark.hand", "entryMark.origin", "entryMark.shapeID", "entryMark.cells", "entryMark.inkRecipe"],
        [`Hand: ${HANDS.join(", ")}`, "Any validated rendererAssetKey and shape footprint", "Open color or validated CMY + Depth ink recipe", "Optional: absent when the source Page has no marks"],
        "Reuse the existing mark silhouette vocabulary; material treatment belongs to this scene, not a pasted plaque.",
        "Negative space stays transparent to the owning ground; no solid square background."),
      row("foreground-site-opportunity", "Site-presence cue", "One coordinate-free hint that at least one site exists.",
        ["siteOpportunity"],
        ["explorationOpportunities.hasGeneratedSiteOpportunity"],
        ["false: no cue", "true: exactly one constant presence cue"],
        "One shared cue for every nonzero site count; never branch by site identity, count, category or location.",
        "Transparent isolated cue; must not resemble a known site, portal, traveller, creature or map coordinate."),
      row("foreground-resource-opportunity", "Exceptional resource traces", "Coordinate-free traces for eligible rare, precious or positively authored families.",
        ["resourceOpportunity"],
        ["explorationOpportunities.resources[].stableID", "explorationOpportunities.resources[].sourceCount", "explorationOpportunities.resources[].obtainableQuantity", "explorationOpportunities.resources[].causalMarkIDs"],
        ["One typed family per eligible ResourceID", "Exact source count", "Exact obtainable quantity", "Canonically ordered positive causal owners", "Ordinary non-qualifying resources: no cue"],
        "Share a restrained trace grammar; identity accent may vary only from the exact eligible ResourceID.",
        "Transparent, coordinate-free marks; no node position, yield, remaining harvest, route or hidden contents."),
    ]),
  }),
  Object.freeze({
    id: "midground-1", name: "Midground 1", motion: "moves", motionLabel: "Moves · contract locked",
    rows: Object.freeze([
      row("midground-1-ground", "Middle ground bank", "The first broad band beyond the foreground.",
        ["terrainMass"],
        ["terrain.grounds", "terrain.regions[].groundShares", "terrain.materialPresentation"],
        [`Ground: ${GROUND_TYPES.join(", ")}`, `Coverage: ${COVERAGE_BANDS.join(", ")}`, "4×3 coarse region distribution"],
        "Share palette and texture modules with other terrain depths; author a distinct middle-distance mass.",
        "Transparent above its horizon and at intentional cutouts; no baked flora, air or Sky."),
      row("midground-1-water", "Middle water structure", "Pools, channels, shelves and ice through the first middle band.",
        ["waterStructure"],
        ["water", "terrain.regions[].waterShares"],
        ["Shallow, deep and frozen", `Topology: ${WATER_TOPOLOGIES.join(", ")}`, "Body and channel sizes", "4×3 coarse region distribution"],
        "Reuse topology modules and palette roles; keep this depth independently addressable.",
        "Transparent outside water; no edge gaps at any approved displacement."),
      row("midground-1-relief", "Middle relief", "Elevation breaks and enclosure silhouettes in the first middle band.",
        ["relief"],
        ["relief", "terrain.regions[].elevationShares"],
        ["Elevation 0…3", "Elevated component sizes", "South-contact depth 1…3", "flat only when every tile is level 0"],
        "Reuse ground material palette and relief grammar, not foreground pixels.",
        "Transparent away from actual relief; no false sidewall at equal height."),
      row("midground-1-deposits", "Middle snow and Ash", "Deposit scatter visible across the first middle band.",
        ["surfaceDeposit"],
        ["deposits", "terrain.regions[].depositShares"],
        ["Snow", "Settled Ash", "Both", `Coverage: ${COVERAGE_BANDS.join(", ")}`],
        "Reuse the deposit overlay family at depth-appropriate density and scale.",
        "Transparent broken scatter; base terrain remains legible."),
      row("midground-1-flora", "Middle flora", "The main readable species layer and its distribution.",
        ["floraIdentity", "floraDistribution"],
        ["flora.species[]", "flora.aggregateCoverage", "terrain.regions[].floraShares"],
        [`Form ID: ${FLORA_FORMS.join(", ")}`, `Habit: ${FLORA_HABITS.join(", ")}`, "Every placed species", "Exact resolved color", "4×3 coarse region shares"],
        "Share species form masks and color slots; this plane can carry the densest flora read.",
        "Transparent around plants; no decorative border and no species omitted by count."),
    ]),
  }),
  Object.freeze({
    id: "midground-2", name: "Midground 2", motion: "moves", motionLabel: "Moves · contract locked",
    rows: Object.freeze([
      row("midground-2-ground", "Far-middle ground", "A second terrain band that carries mixed-world depth.",
        ["terrainMass"],
        ["terrain.grounds", "terrain.secondaryVisibleGrounds", "terrain.regions[].groundShares", "terrain.materialPresentation"],
        [`Ground: ${GROUND_TYPES.join(", ")}`, `Coverage: ${COVERAGE_BANDS.join(", ")}`, "4×3 coarse region distribution"],
        "Share exact palettes and material modules; author a distinct farther silhouette.",
        "Transparent above the terrain horizon; no baked Sky or atmosphere."),
      row("midground-2-water", "Far-middle water", "A second depth for connected water and ice structure.",
        ["waterStructure"],
        ["water", "terrain.regions[].waterShares"],
        ["Shallow, deep and frozen", `Topology: ${WATER_TOPOLOGIES.join(", ")}`, "Standing/flowing body ownership"],
        "Reuse topology and depth palette modules; keep the second middle depth separate.",
        "Transparent outside water; intentional overlap must not create repeated strips."),
      row("midground-2-relief", "Far-middle relief", "Distant raised components, cuts and enclosing rock.",
        ["relief"],
        ["relief", "terrain.regions[].elevationShares"],
        ["Elevation 0…3", "South-contact depth 1…3", "Connected elevated component sizes", "flat"],
        "Reuse relief rules and material palettes, not a resized near-plane bitmap.",
        "Transparent away from real silhouettes; no unsupported ridge, basin or shelf label."),
      row("midground-2-flora", "Far-middle flora", "Smaller but still identity-true plant masses.",
        ["floraIdentity", "floraDistribution"],
        ["flora.species[]", "flora.aggregateCoverage", "terrain.regions[].floraShares"],
        [`Form ID: ${FLORA_FORMS.join(", ")}`, `Habit: ${FLORA_HABITS.join(", ")}`, "Every placed species", "Exact resolved color"],
        "Reuse form/color modules with a depth-specific silhouette and density treatment.",
        "Transparent cutouts; no identity collapse into one generic foliage color."),
      row("midground-2-suspended-air", "Suspended-air veil", "Smoke, airborne Ash, mist or miasma carried between terrain bands.",
        ["suspendedAtmosphere"],
        ["environment.suspendedMedium", "environment.suspendedDensity", "environment.suspendedMotion", "terrain.materialPresentation.resolvedAtmosphereColor"],
        [`Medium: ${SUSPENDED_MEDIA.join(", ")}`, `Density: ${SUSPENDED_DENSITIES.join(", ")}`, `Motion band: ${MOTION_BANDS.join(", ")}`, "Resolved atmosphere color when present"],
        "One modular veil family per medium; density changes opacity/distribution without inventing another medium.",
        "Transparent and broken; ground/water silhouette must remain readable. No cloud or celestial inference."),
    ]),
  }),
  Object.freeze({
    id: "background", name: "Background", motion: "moves", motionLabel: "Moves · contract locked",
    rows: Object.freeze([
      row("background-ground", "Distant terrain mass", "The far landform that keeps the upper scene from becoming empty.",
        ["terrainMass"],
        ["terrain.grounds", "terrain.dominantDryGround", "terrain.secondaryVisibleGrounds", "terrain.regions[].groundShares", "terrain.materialPresentation"],
        [`Ground: ${GROUND_TYPES.join(", ")}`, `Coverage: ${COVERAGE_BANDS.join(", ")}`, "Resolved material palette", "4×3 coarse region distribution"],
        "Share material palette and terrain grammar; distant silhouette is authored separately.",
        "Intentional transparent Sky above the horizon is allowed; moving extremes cannot expose unpainted seams."),
      row("background-water", "Distant water mass", "Far pools, channels, shelves, islands and frozen water.",
        ["waterStructure"],
        ["water", "terrain.regions[].waterShares"],
        ["Shallow, deep and frozen", `Topology: ${WATER_TOPOLOGIES.join(", ")}`, "Connected bodies and component truth"],
        "Reuse water palette/topology modules; author far silhouettes and scale separately.",
        "Transparent away from water; no gap, wrap or repeated strip at motion extremes."),
      row("background-relief", "Distant enclosure", "Far elevation, broken mass and enclosing-rock profile.",
        ["relief"],
        ["relief", "terrain.regions[].elevationShares"],
        ["Elevation 0…3", "Elevated components", "South-facing exposure depth 1…3", "flat"],
        "Reuse exact material palette and relief rules; do not invent unsupported topology labels.",
        "Transparent above silhouette; required terrain coverage remains gap-free through the approved excursion."),
      row("background-flora", "Distant flora read", "Small species-true masses that keep ecology visible at distance.",
        ["floraIdentity", "floraDistribution"],
        ["flora.species[]", "flora.aggregateCoverage", "terrain.regions[].floraShares"],
        [`Form ID: ${FLORA_FORMS.join(", ")}`, `Habit: ${FLORA_HABITS.join(", ")}`, "Every placed species", "Exact resolved color"],
        "Reuse the same species identities and colors with an authored far-distance treatment.",
        "Transparent; no generic tree line and no hidden creature/site silhouettes."),
      row("background-suspended-air", "Distant atmosphere", "The far value and air field behind terrain.",
        ["suspendedAtmosphere"],
        ["environment.suspendedMedium", "environment.suspendedDensity", "environment.suspendedMotion", "terrain.materialPresentation.resolvedAtmosphereColor"],
        [`Medium: ${SUSPENDED_MEDIA.join(", ")}`, `Density: ${SUSPENDED_DENSITIES.join(", ")}`, `Motion band: ${MOTION_BANDS.join(", ")}`, "Resolved atmosphere color when present"],
        "Share medium-specific texture modules with the interstitial veil; keep far density independently composable.",
        "May be translucent; must not bake Sky bodies, precipitation, terrain or opportunity cues."),
    ]),
  }),
  Object.freeze({
    id: "sky", name: "Sky", motion: "static", motionLabel: "Static · contract locked",
    rows: Object.freeze([
      row("sky-illumination", "Static sky and illumination field", "The unmoving value field behind every other plane.",
        ["illumination"],
        ["environment.illuminationBand", "environment.illuminationSourceClass", "terrain.materialPresentation.resolvedAtmosphereColor"],
        [`Illumination: ${ILLUMINATION_BANDS.join(", ")}`, `Source class: ${ILLUMINATION_SOURCE_CLASSES.join(", ")}`, "Resolved atmosphere color when present"],
        "One full-coverage base family with typed value/palette variants; no celestial body is requested by build268.",
        "Opaque full crop, clean edges, no transparent gaps. No Sun, Moon, star or cloud identity may be inferred.",
        staticDimensions),
    ]),
  }),
]);

export const semanticVocabulary = Object.freeze({
  coverageBands: COVERAGE_BANDS,
  groundTypes: GROUND_TYPES,
  waterTopologies: WATER_TOPOLOGIES,
  regionGrid: Object.freeze({columns: 4, rows: 3}),
  elevations: Object.freeze([0, 1, 2, 3]),
  southContactDepths: Object.freeze([1, 2, 3]),
  reliefShapeFlags: Object.freeze(["flat"]),
  surfaceDeposits: Object.freeze(["snow", "settledAsh"]),
  flora: Object.freeze({
    formIDs: FLORA_FORMS, statureRange: Object.freeze([0, 100]), habits: FLORA_HABITS,
    colorProvenance: FLORA_COLOR_PROVENANCE,
    eligibleGrounds: Object.freeze(["stone", "soil", "sand", "ice", "ash", "rubble", "mud"]),
    completePlacedSpeciesCensus: true,
  }),
  illumination: Object.freeze({bands: ILLUMINATION_BANDS, sourceClasses: ILLUMINATION_SOURCE_CLASSES}),
  suspendedAtmosphere: Object.freeze({media: SUSPENDED_MEDIA, densities: SUSPENDED_DENSITIES, motionBands: MOTION_BANDS}),
  precipitation: Object.freeze({media: PRECIPITATION_MEDIA, intensities: PRECIPITATION_INTENSITIES, motionBands: MOTION_BANDS}),
  entryMark: Object.freeze({optional: true, hands: HANDS, inkChannels: Object.freeze(["cyan", "magenta", "yellow", "depth"]), channelRange: Object.freeze([0, 100])}),
  siteOpportunity: Object.freeze({values: Object.freeze([false, true]), nonzeroSiteIdentityCollapsed: true}),
  resourceOpportunity: Object.freeze({
    eligible: "authored rare or precious ResourceID, or exact family with a positive bind-time causal owner",
    fields: Object.freeze(["stableID", "sourceCount", "obtainableQuantity", "causalMarkIDs"]),
    coordinatesExcluded: true,
  }),
});

export const splashInventory = Object.freeze({
  schema: "bookbinder.world-splash-five-layer-inventory.v1",
  status: "candidate-not-approved",
  integrationReady: false,
  assetBytesIncluded: 0,
  scope: "SPLASH-01 planning and asset inventory only",
  sourceCheckpoint: "cdbb96e0a6fda5433982ae2c9ffe2b8d272faaf8",
  sourceTree: "f5f98500daa72e39fea1a7e620f9a3922071b52d",
  reviewViewport: Object.freeze({width: 368, height: 800}),
  sceneVisibleCrop: Object.freeze({width: 320, height: 360}),
  sourceHashes: SOURCE_HASHES,
  displayOrder: Object.freeze(["Foreground", "Midground 1", "Midground 2", "Background", "Sky"]),
  compositingOrderBackToFront: Object.freeze(["Sky", "Background", "Midground 2", "Midground 1", "Foreground"]),
  motionContract: Object.freeze({
    locked: true,
    moving: Object.freeze(["Foreground", "Midground 1", "Midground 2", "Background"]),
    static: Object.freeze(["Sky"]),
    timingEasingOffsetsEditableHere: false,
    parameterAuthority: "Existing approved motion receipt; SPLASH-01 records layer ownership only",
  }),
  layers,
  semanticVocabulary,
  excludedFromAssetSelection: Object.freeze([
    "receiptID, worldSeed and canonical hashes",
    "finalDescription and description grammar",
    "causal prose beyond typed positive resource ownership",
    "source Page labels beyond the optional first entry mark footprint",
    "first-map coordinates beyond semantic continuity validation",
    "travellers, meetings, creatures, apexes, combat, loot, hidden hazards and undiscovered Sigils",
    "site identity, count, category, coordinate, contents and route",
    "resource coordinates, source instance IDs, per-source yields and remaining harvests",
    "Sun, Moon, stars and cloud identity: build268 has no typed WorldSplashReceiptV3 field for them",
  ]),
  boundaries: Object.freeze({
    nativeProductionFilesChanged: 0,
    gameplayOrSchemaFilesChanged: 0,
    generatedAssetFiles: 0,
    finalArtClaimed: false,
    visualApprovalClaimed: false,
    motionParametersReopened: false,
  }),
});

export function canonicalStringify(value) {
  if (Array.isArray(value)) return `[${value.map(canonicalStringify).join(",")}]`;
  if (value && typeof value === "object") {
    return `{${Object.keys(value).sort().map(key => `${JSON.stringify(key)}:${canonicalStringify(value[key])}`).join(",")}}`;
  }
  return JSON.stringify(value);
}

export async function sha256(value) {
  const bytes = new TextEncoder().encode(typeof value === "string" ? value : canonicalStringify(value));
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map(byte => byte.toString(16).padStart(2, "0")).join("");
}

export async function makeCandidateReceipt() {
  const canonicalBody = canonicalStringify(splashInventory);
  return Object.freeze({
    schema: "bookbinder.world-splash-five-layer-inventory-receipt.v1",
    status: "candidate-not-approved",
    integrationReady: false,
    canonicalBodySHA256: await sha256(canonicalBody),
    sourceCheckpoint: splashInventory.sourceCheckpoint,
    sourceTree: splashInventory.sourceTree,
    viewport: splashInventory.reviewViewport,
    sceneVisibleCrop: splashInventory.sceneVisibleCrop,
    layerCount: layers.length,
    rowCount: layers.reduce((sum, layer) => sum + layer.rows.length, 0),
    assetBytesIncluded: 0,
    motionContract: splashInventory.motionContract,
    layers: layers.map(layer => ({
      id: layer.id, name: layer.name, motion: layer.motion,
      rows: layer.rows.map(({id, name, semanticScopes, sourceFields, dimensionsOverscan,
        variants, sharingReuse, transparencyEdges, completionStatus}) => ({
        id, name, semanticScopes, sourceFields, dimensionsOverscan, variants,
        sharingReuse, transparencyEdges, completionStatus,
      })),
    })),
    sourceHashes: SOURCE_HASHES,
    boundaries: splashInventory.boundaries,
  });
}

