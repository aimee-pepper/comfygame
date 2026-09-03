import { copyFile, mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const playerWikiRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
);
const repositoryRoot = path.resolve(playerWikiRoot, '..');
const sourceDataPath = path.join(
  repositoryRoot,
  'GameWiki',
  'generated',
  'wiki-data.json',
);
const outputDataPath = path.join(playerWikiRoot, 'data', 'player-content.json');
const publicAssetRoot = path.join(playerWikiRoot, 'public', 'game-assets');
const siteBasePath = (process.env.NEXT_PUBLIC_BASE_PATH ?? '').replace(/\/+$/, '');

const source = JSON.parse(await readFile(sourceDataPath, 'utf8'));
const travellerSource = JSON.parse(
  await readFile(
    path.join(repositoryRoot, 'Sources', 'Content', 'Data', 'travellers.json'),
    'utf8',
  ),
);
const resourceSource = JSON.parse(
  await readFile(
    path.join(repositoryRoot, 'Sources', 'Content', 'Data', 'resources.json'),
    'utf8',
  ),
);
const itemSource = JSON.parse(
  await readFile(
    path.join(repositoryRoot, 'Sources', 'Content', 'Data', 'items.json'),
    'utf8',
  ),
);
const resourceConsumerAuthoritySource = await readFile(
  path.join(repositoryRoot, 'docs', 'resource-consumer-authority-map-current.md'),
  'utf8',
);
const researchSource = JSON.parse(
  await readFile(
    path.join(repositoryRoot, 'Sources', 'Content', 'Data', 'research.json'),
    'utf8',
  ),
);
const pressureTargetSource = JSON.parse(
  await readFile(
    path.join(repositoryRoot, 'Sources', 'Content', 'Data', 'pressure_targets.json'),
    'utf8',
  ),
);
const skillSource = JSON.parse(
  await readFile(
    path.join(repositoryRoot, 'Sources', 'Content', 'Data', 'skills.json'),
    'utf8',
  ),
);
const combatGraphSource = JSON.parse(
  await readFile(
    path.join(repositoryRoot, 'Sources', 'Content', 'Data', 'combat_tree_v2.json'),
    'utf8',
  ),
);
const gambitComponentSource = JSON.parse(
  await readFile(
    path.join(repositoryRoot, 'Sources', 'Content', 'Data', 'gambit_components.json'),
    'utf8',
  ),
);
const creatureSource = JSON.parse(
  await readFile(
    path.join(repositoryRoot, 'Sources', 'Content', 'Data', 'creatures.json'),
    'utf8',
  ),
);
const siteSource = JSON.parse(
  await readFile(
    path.join(repositoryRoot, 'Sources', 'Content', 'Data', 'sites.json'),
    'utf8',
  ),
);
const fullCastGuide = await readFile(
  path.join(repositoryRoot, 'docs', 'player-wiki-full-cast-current.md'),
  'utf8',
);
const namedCharacterPack = JSON.parse(
  await readFile(
    path.join(
      repositoryRoot,
      'AssetLab',
      'integration',
      'named-character-placeholders-v1',
      'manifest.json',
    ),
    'utf8',
  ),
);
const townBuildingRegistry = await readFile(
  path.join(
    repositoryRoot,
    'Sources',
    'VisualRuntime',
    'TownBuildingVisualRegistry.generated.swift',
  ),
  'utf8',
);
const townBuildingAssetByStationID = new Map(
  [...townBuildingRegistry.matchAll(/^\s*"([a-z_]+)": "([a-z0-9-]+)"/gm)].map(
    ([, stationID, assetName]) => [stationID, assetName],
  ),
);
const family = (id) =>
  source.visualAssets.families.find((entry) => entry.id === id);
const runtimeAsset = (familyID, semanticKey) =>
  family(familyID)?.assets.find(
    (asset) => asset.role === 'runtime' && asset.semanticKey === semanticKey,
  );

const safeFileName = (value) =>
  `${String(value).replaceAll(/[^a-zA-Z0-9_-]/g, '-')}.png`;
const compactCopy = (value) => value.replaceAll(/\s+/g, ' ').trim();
const playerResourceCopy = (value) => compactCopy(value)
  .replace(/No current Village construction recipe uses this resource\.?/g, 'Not currently used for Village construction.')
  .replace(/^Rank-(\d+) mineral node/, 'Mineral nodes requiring Extraction $1')
  .replace(/^Rank-(\d+) wet, soft Substrate node/, 'Wet, soft Substrate deposits requiring Extraction $1')
  .replace(/^Rank-(\d+) ductile\/volatile seam/, 'Ductile or volatile seams requiring Extraction $1')
  .replace(/^Rank-(\d+) rich ductile seam/, 'Rich ductile seams requiring Extraction $1')
  .replace(/^Rank-(\d+) very rich ductile seam/, 'Very rich ductile seams requiring Extraction $1')
  .replace(/^Rank-(\d+) hard seam/, 'Hard seams requiring Extraction $1')
  .replace(/^Rank-(\d+) ash\/geothermal seam/, 'Ash or geothermal seams requiring Extraction $1')
  .replace(/^Rank-(\d+) saline\/briny\/low-water deposit/, 'Saline, briny, or low-water deposits requiring Extraction $1')
  .replace(/^Rank-(\d+) hot volatile\/geothermal deposit/, 'Hot volatile or geothermal deposits requiring Extraction $1')
  .replace(/^Rank-(\d+) rich ductile\/volatile mineral/, 'Rich ductile or volatile deposits requiring Extraction $1')
  .replace(/^Rank-(\d+) extreme hard\/valuable unstable seam/, 'Extremely hard, valuable seams in unstable worlds requiring Extraction $1')
  .replace(/^Rank-(\d+) seam beside chasms in unstable worlds/, 'Seams beside chasms in unstable worlds requiring Extraction $1')
  .replace(/\bstaple trade\b/g, 'sold as a staple good')
  .replace(/\buncommon trade\b/g, 'sold as an uncommon good')
  .replace(/\brare sale\b/g, 'sold as a rare material')
  .replace(/\bprecious sale\b/g, 'sold as a precious material')
  .replace(/\blegacy Recycler\b/g, 'returned by recycling some older gear')
  .replace(/\bcurrent sites\b/g, 'some discovered sites')
  .replace(/\bcurrent site JSON also pays it\b/g, 'some discovered sites also award it')
  .replace(/\bexact units\b/g, 'individual pieces of material')
  .replace(/\bexact optical\/Light Core selection\b/g, 'optical materials and the Light Core ingredient')
  .replace(/\bcompatible exact stock\b/g, 'matching specialist materials')
  .replace(/\bcompatible high-grade exact stock\b/g, 'matching high-quality materials')
  .replace(/\bcompatible physical sockets\b/g, 'matching physical recipe parts')
  .replace(/\bphysical sockets\b/g, 'physical recipe parts')
  .replace(/\bcompatible individual material units in physical making\b/g, 'individual pieces of material that fit the recipe')
  .replace(/\bcompatible individual material units across physical makers\b/g, 'individual pieces of material at compatible crafting stations')
  .replace(/\bcompatible individual pieces of material in physical making\b/g, 'individual pieces of material that fit the recipe')
  .replace(/\bcompatible individual pieces of material across physical makers\b/g, 'individual pieces of material at compatible crafting stations')
  .replace(/\bcompatible exact edges\/points\b/g, 'a compatible Edge or Point')
  .replace(/\bcompatible specialist exact stock\b/g, 'matching specialist materials')
  .replace(/\bexact specialist stock\b/g, 'matching specialist materials')
  .replace(/\bscalar stock\b/g, 'ordinary counted stock')
  .replace(/\bscalar definition is creature-only\/no ordinary node\b/g, 'Obtained from creatures rather than an ordinary world deposit')
  .replace(/\bcreature outcomes\b/g, 'creature rewards')
  .replace(/\bReality-layer authored site\/cache\/permanent awards\b/g, 'Named sites, caches, and permanent rewards')
  .replace(/\bcontinuation precursor\b/g, 'refined into Essence for continued progression')
  .replace(/\bmaker progression\b/g, 'maker Research')
  .replace(/\bWayfarer organic bonus\b/g, "Wayfarer's Table harvest bonus")
  .replace(/\bpersonal compound formalization\b/g, 'creating a personal Compound')
  .replace(/\bnontradeable\b/g, 'cannot be traded')
  .replace(/\bordinary counted stock can only be sold\b/g, 'Can currently be sold but has no other use')
  .replace(/\bArmoury research totals (\d+)\b/g, 'Armoury Research uses $1 in total')
  .replace(/\bSpring, Hold, Satchel, Bargain, instruction and permanence research\b/g, 'Used by Spring, Hold, Satchel, Bargain, Gambit, and Permanence Research')
  .replace(/\bcompatible fittings\/bindings\/grips\b/g, 'can fill a matching Fitting, Binding, or Grip part')
  .replace(/\bcompatible fittings\b/g, 'can fill a matching Fitting part')
  .replace(/\bcompatible limbs\/hafts\/grips\b/g, 'can fill a matching Limb, Haft, or Grip part')
  .replace(/\bcompatible bindings\b/g, 'can fill a matching Binding part')
  .replace(/\bDepth pigment\b/g, 'provides Depth pigment')
  .replace(/\bSpring (\d+), pen work (\d+), seven instruments, four Page Lens tiers\b/g, '$1 for Spring upgrades, $2 for Penmanship, plus seven instruments and four Page Lens tiers')
  .replace(/\bWeaponsmith broaden\/masterwork (\d+) total\b/g, 'Weaponsmith upgrades use $1 in total')
  .replace(/\bFitted Layers (\d+)\b/g, 'Fitted Layers Research uses $1')
  .replace(/\bTannery\/Bowyer and many instruction, Focus, Bargain, Hold and Satchel nodes\b/g, 'Used by Tannery, Bowyer, Gambit, Focus, Bargain, Hold, and Satchel Research')
  .replace(/\bBowyer, Brush, Desk and Level research\b/g, 'Used by Bowyer, Brush, Writing Desk, and Level Research')
  .replace(/\bContinuous Settling (\d+), Compound Assembly (\d+)\b/g, 'Continuous Settling uses $1; Compound Assembly uses $2')
  .replace(/\bBowyer, Ink Mixing, Compounds, Fountain Pen, Vivometer\b/g, 'Used by Bowyer, Ink Mixing, Compound Assembly, Fountain Pen, and Vivometer Research')
  .replace(/^maker Research,/, 'Used by maker Research,')
  .replace(/\bVivometer (\d+), Long Glass (\d+)\b/g, 'Vivometer Research uses $1; The Long Glass uses $2')
  .replace(/\bChronometer (\d+), Fine Scale (\d+), Long Glass (\d+)\b/g, 'Chronometer Research uses $1, The Fine Scale uses $2, and The Long Glass uses $3')
  .replace(/\bChaining (\d+), Thermoscope (\d+), Barometer (\d+), Silvered Back (\d+)\b/g, 'Chaining uses $1, Thermoscope $2, Barometer $3, and Silvered Back $4');
const slugFor = (name) =>
  name.toLowerCase().replaceAll(/[^a-z0-9]+/g, '-').replaceAll(/(^-|-$)/g, '');
const conditionLabel = (condition) => {
  const target = compactCopy(condition.target ?? 'world');
  const key = condition.key ? ` ${compactCopy(condition.key)}` : '';
  const subject = `${target}${key}`;
  const limit = condition.minimum ?? condition.maximum;
  if (condition.measure === 'tag') return `${subject} is present`;
  if (condition.maximum !== undefined) return `${subject} at or below ${limit}`;
  if (condition.minimum !== undefined) return `${subject} at or above ${limit}`;
  return subject;
};
const readableID = (value) => String(value ?? '')
  .replaceAll(/[_-]/g, ' ')
  .replace(/^./, (letter) => letter.toUpperCase());
const researchBranchCopy = {
  instruction: 'Learn more Gambit targets, conditions, actions, and rule slots, then let the Binder follow written Gambits too.',
  hand: 'Learn two special World Writing Sigils from discoveries made in generated worlds.',
  hold: 'Increase Storehouse space and the amount your party can carry home.',
  lexicon: 'Learn new Focuses that can be used in World Writing.',
  bargain: 'Learn Sigils that trade greater danger or instability for a more stable world, plus Peace for the reverse choice.',
  penmanship: 'Improve Writing tools, prepared ink, Compounds, and the Scriptorium.',
  instruments: 'Learn field instruments that let Survey measure one part of a generated world.',
  spring: 'Improve Raw Essence refinement and the Essence received at home.',
  lens: 'Add clearer numerical and causal information to the World Writing preview.',
  tannery_wear: 'Unlock and improve flexible clothing and protection at the Tannery.',
  tannery_carry: 'Unlock Tannery work used by later satchel improvements.',
  tannery_keep: 'Unlock Tannery work used by later Storehouse improvements.',
  bowyer_craft: 'Unlock more Bowyer weapons and higher construction tiers.',
  armoury_craft: 'Unlock more Armoury constructions and higher construction tiers.',
  weaponsmith_craft: 'Unlock more Weaponsmith forms and higher construction tiers.',
};
const researchResultCopy = {
  tannery_wear_root: 'Unlocks Supple Coat, Working Gloves, and Working Boots at the Tannery.',
  bowyer_broaden: 'Unlocks Sling and Throwing Set and raises the Bowyer to its next crafting tier.',
  armoury_broaden: 'Unlocks Insulated Layer and Balanced Laminate and raises the Armoury to its next crafting tier.',
  weaponsmith_point_root: 'Unlocks the Fitted Point close-range piercing weapon at the Weaponsmith.',
  weaponsmith_broaden: 'Unlocks Fitted Edge and Fitted Maul and raises the Weaponsmith to its next crafting tier.',
  weaponsmith_masterwork: 'Lets exceptional Weaponsmith materials produce Tier 4 equipment.',
  armoury_masterwork: 'Lets exceptional Armoury materials produce Tier 4 equipment.',
  bowyer_masterwork: 'Lets exceptional Bowyer materials produce Tier 4 equipment.',
  tannery_carry_root: 'Unlocks the Tannery binding work required by advanced satchel improvements.',
  tannery_wear_tier_two: 'Unlocks Tier 2 flexible clothing and protection at the Tannery.',
  tannery_keep_root: 'Unlocks the Tannery lining and binding work required by advanced Storehouse improvements.',
  longer_instruction: 'Adds one Gambit slot to every companion.',
  longer_instruction_two: 'Adds another Gambit slot to every companion.',
  automate_self: 'Lets the Binder follow written Gambits automatically in combat.',
  deepen_spring: 'Increases the Essence received at home by one Spring tier.',
  essence_second_pass: 'Improves refinement so each Raw Essence becomes 3 Essence instead of 2.',
  essence_continuous_settling: 'Automatically refines only the Raw Essence kept from each new expedition return.',
  pen_brush: 'Unlocks the Brush as a finer World Writing hand.',
  pen_desk: 'Raises the Scriptorium by one tier and opens the next stage of Penmanship.',
  pen_ink_mixing: 'Unlocks prepared Cyan, Magenta, Yellow, and Depth ink.',
  pen_compounds: 'Unlocks Compound Assembly for turning a learned statement into a reusable Compound Sigil.',
  pen_chaining: 'Unlocks Chaining, which connects one written statement to another so a world can contain two kinds of land.',
  pen_press: 'Raises the Scriptorium by one tier and opens the next stage of Penmanship.',
  pen_fountain: 'Unlocks the Fountain Pen as the finest current World Writing hand.',
  bargain_root: 'Teaches the Swarm Sigil, which asks for more creatures in exchange for more Stability.',
  bargain_weather: 'Teaches the Storm Sigil, which asks for dangerous weather in exchange for more Stability.',
  bargain_ground: 'Teaches the Tremor Sigil, which asks for unstable ground in exchange for more Stability.',
  bargain_teeth: 'Teaches the Predation Sigil, which asks for fewer but stronger creatures in exchange for more Stability.',
  bargain_rot: 'Teaches the Blight Sigil, which asks for harmful growth in exchange for more Stability.',
  bargain_air: 'Teaches the Miasma Sigil, which asks for damaging air in exchange for more Stability.',
  bargain_peace: 'Teaches the Peace Sigil, which asks for a quieter world but provides less Stability.',
  lens_targets: 'Adds numerical pressure readings to the World preview for subjects you have measured in the field.',
  lens_attribution: 'Shows which parts of your Page contributed to each previewed world pressure.',
  lens_instability: 'Shows which written requests and contradictions are consuming the world’s Stability.',
  lens_living: 'Adds a preview of the kinds of life a written world is likely to support.',
};
const gambitComponentNameByID = new Map(
  gambitComponentSource.components.map((component) => [component.id, component.name]),
);
const researchBlurb = (node) => {
  if (researchResultCopy[node.id]) return researchResultCopy[node.id];
  if (node.id.startsWith('shelving_')) return 'Raises Storehouse capacity by one tier.';
  if (node.id.startsWith('satchel_')) return 'Raises the party’s field carrying capacity by one tier.';
  const grant = node.grants?.[0];
  if (!grant) return compactCopy(node.blurb);
  if (grant.kind === 'gambitComponent') {
    const name = gambitComponentNameByID.get(grant.id) ?? readableID(grant.id);
    return `Adds “${name}” to the Gambit parts you can use.`;
  }
  if (grant.kind === 'symbol') {
    const symbolNames = { verdigris_bloom: 'Verdigris Bloom', mote_vein: 'Mote Vein' };
    return `Teaches the ${symbolNames[grant.id] ?? readableID(grant.id)} Sigil for World Writing.`;
  }
  if (grant.kind === 'focus') return `Teaches ${node.name} as a Focus for World Writing.`;
  if (grant.kind === 'instrument') return `Teaches the ${node.name} at Crude precision so Survey can measure ${readableID(grant.id).toLowerCase()}.`;
  return compactCopy(node.blurb);
};
const resourceDefinitionByID = new Map(
  resourceSource.resources.map((resource) => [resource.id, resource]),
);
const itemDefinitionByID = new Map(
  itemSource.items.map((item) => [item.id, item]),
);
const implementedResourceConsumerTable = resourceConsumerAuthoritySource
  .split('## Complete resource-to-consumer map — IMPLEMENTED')[1]
  ?.split('## Implemented construction pattern')[0];
if (!implementedResourceConsumerTable) {
  throw new Error('Resource consumer authority must retain its implemented table');
}
const resourceConsumerAuthorityByID = new Map(
  implementedResourceConsumerTable
    .split('\n')
    .filter((line) => /^\| .+ \|/.test(line) && !line.startsWith('| Resource') && !line.startsWith('|---'))
    .map((line) => line.split('|').slice(1, -1).map((cell) => compactCopy(cell)))
    .map(([resource, acquisition, buildings, recipes, other]) => {
      const id = resource.match(/`([^`]+)`/)?.[1];
      if (!id) throw new Error(`Resource consumer authority row has no stable resource id: ${resource}`);
      const values = (value) => (value === '—' ? [] : value.split(/;\s*/).map(playerResourceCopy));
      return [id, {
        acquisition: playerResourceCopy(acquisition),
        buildingConsumers: values(buildings),
        recipeConsumers: values(recipes),
        otherConsumers: values(other),
      }];
    }),
);
if (resourceConsumerAuthorityByID.size !== resourceSource.resources.length) {
  throw new Error('Resource consumer authority must cover every current resource exactly once');
}
const acquisitionLabel = (resource) => {
  switch (resource.extractionDisposition) {
    case 'mineral_node':
      return `World mineral node · Extraction rank ${resource.requiredExtractionRank ?? 0}`;
    case 'flora_primary':
      return 'Primary flora harvest';
    case 'flora_secondary':
      return 'Secondary harvest from qualifying flora';
    case 'creature_material_only':
      return 'Exact creature-material reward';
    case 'direct_pickup':
      return 'Direct world pickup';
    case 'reality_award':
      return 'Reality award';
    default:
      return 'Current source not published';
  }
};
const tradeStatus = (resource) => {
  if (resource.isRealityCurrency) return 'Reality currency · not traded';
  if (resource.tradeBand === 'nontradeable') return 'Not traded';
  return `${resource.tradeBand[0].toUpperCase()}${resource.tradeBand.slice(1)} trade band`;
};
const currentInherentTechniqueOwners = new Map([
  ['unbind', 'Binder'],
  ['sight', 'Binder'],
  ['mend', 'Quill'],
  ['read', 'Quill'],
  ['ground', 'Ashe'],
]);
const foeTargetTechniqueKinds = new Set([
  'damage',
  'armourIgnoring',
  'overbear',
  'bleed',
  'reveal',
  'taunt',
  'snuff',
  'read',
  'sunder',
  'execute',
  'ambush',
  'elemental',
]);
const allyTargetTechniqueKinds = new Set(['heal', 'cleanse', 'intercept']);
const techniqueTarget = (kind) =>
  foeTargetTechniqueKinds.has(kind)
    ? 'Choose a living foe'
    : allyTargetTechniqueKinds.has(kind)
      ? 'Choose a living ally'
      : 'No card target';
const graphTechniqueNodes = combatGraphSource.trees
  .flatMap((tree) => tree.disciplines)
  .flatMap((discipline) => discipline.nodes)
  .filter((node) => node.techniqueID);
const graphTechniqueByID = new Map(
  graphTechniqueNodes.map((node) => [node.techniqueID, node]),
);
const currentTechniqueIDs = new Set([
  ...currentInherentTechniqueOwners.keys(),
  ...graphTechniqueByID.keys(),
]);
const skillByID = new Map(skillSource.skills.map((skill) => [skill.id, skill]));
const combatTechniques = [...currentTechniqueIDs]
  .map((id) => {
    const graphNode = graphTechniqueByID.get(id);
    const skill = skillByID.get(id);
    if (id === 'blur' && graphNode) {
      return {
        name: graphNode.name,
        blurb: graphNode.blurb,
        effect: graphNode.effectCopy,
        target: 'No card target',
        cooldown: 'Once per encounter',
        availability: 'Learn the named Training node for that person',
        trainingRole: graphNode.role,
        trainingDepth: graphNode.depth,
      };
    }
    if (!skill) return null;
    return {
      name: skill.name,
      blurb: skill.blurb,
      effect: graphNode?.effectCopy ?? skill.blurb,
      target: techniqueTarget(skill.kind),
      cooldown: `${skill.cooldownRounds}-round cooldown`,
      availability: currentInherentTechniqueOwners.has(id)
        ? `Inherent to ${currentInherentTechniqueOwners.get(id)}`
        : 'Learn the named Training node for that person',
      trainingRole: graphNode?.role ?? null,
      trainingDepth: graphNode?.depth ?? null,
    };
  })
  .filter(Boolean)
  .sort((left, right) => left.name.localeCompare(right.name));
const gambitComponents = gambitComponentSource.components.map((component) => ({
  kind: component.kind,
  name: component.name,
  blurb: component.blurb,
}));

await mkdir(path.dirname(outputDataPath), { recursive: true });
await mkdir(path.join(publicAssetRoot, 'resources'), { recursive: true });
await mkdir(path.join(publicAssetRoot, 'items'), { recursive: true });
await mkdir(path.join(publicAssetRoot, 'terrain'), { recursive: true });
await mkdir(path.join(publicAssetRoot, 'writing'), { recursive: true });
await mkdir(path.join(publicAssetRoot, 'people'), { recursive: true });
await mkdir(path.join(publicAssetRoot, 'places'), { recursive: true });
await mkdir(path.join(publicAssetRoot, 'exploration'), { recursive: true });

async function publishAsset(asset, directory, fileName) {
  if (!asset?.sourcePath) return null;
  const sourcePath = path.join(repositoryRoot, asset.sourcePath);
  const destinationPath = path.join(publicAssetRoot, directory, fileName);
  await copyFile(sourcePath, destinationPath);
  return `${siteBasePath}/game-assets/${directory}/${fileName}`;
}

async function publishTravellerCameo(travellerID, slug) {
  const asset = namedCharacterPack.assets.find(
    (entry) =>
      entry.key?.travellerID === travellerID &&
      entry.key?.profile === 'compactCameo' &&
      !entry.key?.facing,
  );
  if (
    !asset ||
    asset.width !== 16 ||
    asset.height !== 16 ||
    !Array.isArray(asset.commands) ||
    asset.commands.some(
      (command) =>
        command.op !== 'rect' ||
        !Number.isInteger(command.x) ||
        !Number.isInteger(command.y) ||
        !Number.isInteger(command.w) ||
        !Number.isInteger(command.h) ||
        command.x < 0 ||
        command.y < 0 ||
        command.w < 1 ||
        command.h < 1 ||
        command.x + command.w > 16 ||
        command.y + command.h > 16 ||
        !/^#[0-9a-f]{6}$/i.test(command.color),
    )
  ) {
    return null;
  }
  const body = asset.commands
    .map(
      (command) =>
        `<rect x="${command.x}" y="${command.y}" width="${command.w}" height="${command.h}" fill="${command.color}"/>`,
    )
    .join('');
  const destination = `${slug}-cameo.svg`;
  await writeFile(
    path.join(publicAssetRoot, 'people', destination),
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" shape-rendering="crispEdges">${body}</svg>\n`,
    'utf8',
  );
  return `${siteBasePath}/game-assets/people/${destination}`;
}

async function publishTownVisual(sourcePath, destination) {
  await copyFile(
    path.join(repositoryRoot, sourcePath),
    path.join(publicAssetRoot, 'places', destination),
  );
  return `${siteBasePath}/game-assets/places/${destination}`;
}

const castRows = [...fullCastGuide.matchAll(
  /^\| (\d+) \| ([^,|]+), ([^|]+?) \| ([^|]+) \| ([^|]+) \|$/gm,
)].map(([, order, name, calling, meetingContext, contribution]) => ({
  order: Number(order),
  name: compactCopy(name),
  calling: compactCopy(calling),
  meetingContext: compactCopy(meetingContext),
  contribution: compactCopy(contribution),
}));
const diarySections = new Map(
  [...fullCastGuide.matchAll(
    /^### \d+\. ([^—\n]+) — ([^\n]+)\n\n([\s\S]*?)(?=^### |^## Progression summary)/gm,
  )].map(([, name, pageLabel, body]) => [compactCopy(name), { pageLabel, body }]),
);
const travellerIDByName = new Map(
  travellerSource.travellers.map((traveller) => [traveller.name, traveller.id]),
);
const diaryTitleForKind = {
  locationClue: 'Where someone is',
  focus: 'A focus',
  ruin: 'Somewhere built',
  researchLead: 'A line of study',
  worldWorthWriting: 'A world worth writing',
  gambit: 'A gambit phrase',
  pattern: 'A pattern',
  account: 'An account',
  schematic: 'A schematic',
  turn: 'A turn',
  whereabouts: 'Word of someone',
};
const rewardForPage = (page) => {
  if (page.teachesFocus) return `Teaches Focus: ${page.teachesFocus}`;
  if (page.teachesGambit) return `Teaches Gambit: ${page.teachesGambit}`;
  if (page.teachesPattern) return `Teaches pattern: ${page.teachesPattern}`;
  if (page.teachesSchematic) return `Teaches schematic: ${page.teachesSchematic}`;
  if (page.researchNode) return `Research lead: ${page.researchNode}`;
  return null;
};
// The player-facing full-cast guide assigns Auber's carrier record to Grimmond's
// eleven-page book; preserve the existing authored source record verbatim.
const bookSupplementsByTraveller = new Map([
  ['grimmond', [{ id: 'auber_word_grimmond', after: 'grimmond_word_edren' }]],
]);
if (castRows.length !== 29 || diarySections.size !== 29) {
  throw new Error('Player Wiki full-cast guide must retain all 29 campaign entries');
}
const cast = await Promise.all(castRows.map(async (row) => {
  const diary = diarySections.get(row.name);
  const travellerID = travellerIDByName.get(row.name);
  if (!diary || !travellerID) {
    throw new Error(`Full-cast guide has no matching authored traveller for ${row.name}`);
  }
  const serviceLine = diary.body.match(
    /^\*\*(Service|Role):\*\* ([\s\S]*?)\. \*\*(?:Book|Diary) rewards?:\*\* ([\s\S]*?)\.\n\n/,
  );
  if (!serviceLine) {
    throw new Error(`Full-cast guide has no service or role line for ${row.name}`);
  }
  const sourcePages = [...travellerSource.pages.filter((page) => page.diary === travellerID)];
  const supplementPlans = bookSupplementsByTraveller.get(travellerID) ?? [];
  const supplements = supplementPlans.map((plan) => ({ ...plan, page: travellerSource.pages.find((page) => page.id === plan.id) }));
  if (supplements.some((supplement) => !supplement.page)) {
    throw new Error(`Full-cast book supplement is missing for ${row.name}`);
  }
  for (const supplement of supplements) {
    const insertionIndex = sourcePages.findIndex((page) => page.id === supplement.after);
    if (insertionIndex < 0) throw new Error(`Full-cast book supplement has no ordered anchor for ${row.name}`);
    sourcePages.splice(insertionIndex + 1, 0, supplement.page);
  }
  const diaryPages = sourcePages.map((page, index) => ({
    sequence: String(index + 1),
    sourceID: page.id,
    kind: page.kind,
    title: diaryTitleForKind[page.kind] ?? compactCopy(page.kind),
    prose: page.prose,
    reward: rewardForPage(page),
    worldHint: page.kind === 'locationClue',
  }));
  if (!diaryPages.length) throw new Error(`Full-cast guide has no authored diary source for ${row.name}`);
  return {
    slug: slugFor(row.name),
    name: row.name,
    calling: row.calling,
    order: row.order,
    meetingContext: row.meetingContext,
    contribution: row.contribution,
    roleLabel: serviceLine[1],
    role: compactCopy(serviceLine[2]),
    diaryReward: compactCopy(serviceLine[3]),
    diaryPageLabel: `${diaryPages.length} book ${diaryPages.length === 1 ? 'page' : 'pages'}`,
    diaryPages,
    assetURL: await publishTravellerCameo(travellerID, slugFor(row.name)),
  };
}));

const startingTownAssetURL = await publishTownVisual(
  'AssetLab/integration/starting-town-home-v1/town-starting-home-v1-phone-v2.png',
  'starting-town-home.png',
);
const districtAssetURL = await publishTownVisual(
  'Sources/Content/TownVisuals/town-empty-v1.png',
  'town-district.png',
);

const resources = [];
for (const resource of source.resources) {
  const definition = resourceDefinitionByID.get(resource.id) ?? {};
  const consumerAuthority = resourceConsumerAuthorityByID.get(resource.id);
  if (!consumerAuthority) {
    throw new Error(`Resource consumer authority is missing ${resource.id}`);
  }
  const asset = runtimeAsset(
    'resource-sprites-v1',
    `resources/profiles/inventory/${resource.id}`,
  );
  resources.push({
    id: resource.id,
    slug: resource.slug,
    name: resource.name,
    summary: resource.summary,
    drivenBy: resource.drivenBy,
    requires: resource.requires,
    favours: resource.favours,
    tradeBand: resource.tradeBand,
    isRealityCurrency: resource.isRealityCurrency,
    acquisition: consumerAuthority.acquisition || acquisitionLabel(definition),
    tradeStatus: tradeStatus(definition),
    currentUses: resource.currentUses,
    consumerAuthority,
    assetURL: await publishAsset(asset, 'resources', safeFileName(resource.id)),
  });
}

const items = [];
for (const item of source.items) {
  const definition = itemDefinitionByID.get(item.id) ?? {};
  const asset =
    runtimeAsset('exploration-loose-items-v1', `catalogue-item/${item.id}`) ??
    runtimeAsset(
      'exploration-catalogue-objects-v1',
      `catalogue-item/${item.id}/identified`,
    );
  items.push({
    id: item.id,
    slug: item.slug,
    name: item.name,
    type: item.type,
    category: item.category,
    summary: item.summary,
    rarity: item.rarity,
    gear: item.gear,
    consumable: item.consumable,
    tradingPostDisposition: item.tradingPostDisposition,
    recyclerDisposition: item.recyclerDisposition,
    salvageProfileID: definition.salvageProfileID ?? null,
    merchantStockAccess: definition.consumableMerchantStockAccess ?? null,
    ordinaryMerchantGear: Boolean(
      definition.gear &&
      definition.gearCatalogueDisposition?.classification === 'ordinaryFound' &&
      !definition.gear.breaks,
    ),
    assetURL: await publishAsset(asset, 'items', safeFileName(item.id)),
  });
}

// The Player Wiki publishes only the live, named encounter profiles. It intentionally
// has no per-save discovery state: the mounted Bestiary remains the record of what a
// particular campaign has encountered.
const creatures = creatureSource.creatures.map((creature) => ({
  id: creature.id,
  slug: slugFor(creature.name),
  name: creature.name,
  tier: creature.tier,
  maxHP: creature.maxHP,
  attack: creature.attack,
  sightRadius: creature.sightRadius,
  isNocturnal: Boolean(creature.isNocturnal),
  requires: (creature.requires ?? []).map(conditionLabel),
  favours: (creature.favours ?? []).map(conditionLabel),
}));

// A site directory explains only current authored profiles. It does not expose a
// particular world's rolled contents or whether a campaign has already found one.
const sites = siteSource.sites.map((site) => ({
  id: site.id,
  slug: slugFor(site.name),
  name: site.name,
  blurb: site.blurb,
  category: site.category,
  conditions: (site.conditions ?? []).map(conditionLabel),
  placement: site.placement?.rule ?? 'anywhere',
  minimumDistanceFromEntry: site.placement?.minimumDistanceFromEntry ?? null,
  searchTurns: site.contents?.searchTurns ?? 0,
  yields: Object.entries(site.contents?.yields ?? {}).map(([resourceID, quantity]) => ({ resourceID, quantity })),
  itemIDs: site.contents?.items ?? [],
  teaches: site.contents?.teaches ?? [],
  guardianID: site.contents?.guardian ?? null,
  isNaturalAnchor: Boolean(site.isNaturalAnchor),
}));

const travellers = [];
for (const traveller of source.travellers.filter(
  (entry) => entry.meetingStatus === 'live',
)) {
    const authoredTraveller = travellerSource.travellers.find(
      (entry) => entry.id === traveller.id,
    );
    travellers.push({
      id: traveller.id,
      slug: traveller.slug,
      name: traveller.name,
      calling: traveller.calling,
      summary: traveller.summary,
      authoredOrder: traveller.authoredOrder,
      storyArrivalBand: traveller.storyArrivalBand,
      campaignPhase: traveller.campaignPhase,
      station: traveller.station,
      pageCount: traveller.pageCount,
      clueCount: traveller.clueCount,
      teaching: traveller.teaching,
      hints: authoredTraveller?.signature?.map((entry) => entry.passage) ?? [],
      diaryPages: travellerSource.pages
        .filter((page) => page.diary === traveller.id)
        .map((page) => ({
          kind: page.kind,
          prose: page.prose,
          reward: rewardForPage(page),
        })),
      assetURL: await publishTravellerCameo(traveller.id, traveller.slug),
    });
}

const homeStationIDs = new Set([
  'writing_desk',
  'workshop',
  'storehouse',
  'essence_spring',
  'firepit',
]);
const stations = await Promise.all(source.stations
  .filter(
    (station) =>
      station.disposition === 'settled' &&
      station.lifecycle !== 'removedCompatibility',
  )
  .map(async (station) => {
    const assetName = townBuildingAssetByStationID.get(station.id);
    const assetURL = assetName
      ? await publishTownVisual(
          `Sources/Content/TownVisuals/${assetName}.png`,
          `${station.slug}.png`,
        )
      : null;
    return {
    id: station.id,
    slug: station.slug,
    name: station.name,
    blurb: station.blurb,
    status: 'implemented',
    route: station.route ?? null,
    destinationKind: station.destinationKind ?? null,
    purpose: station.purpose ?? null,
    zone: station.zone,
    lifecycle: station.lifecycle,
    keeper: station.keeper,
    keeperID: station.keeperID,
    unlockedAtStart: station.unlockedAtStart,
    startingTier: station.startingTier,
    catalogueMaxTier: station.catalogueMaxTier,
    buildCost: station.buildCost,
    buildBlurb: station.buildBlurb,
      assetURL,
      contextAssetURL: homeStationIDs.has(station.id)
        ? startingTownAssetURL
        : districtAssetURL,
    };
  }));

const scheduledStations = await Promise.all(source.stations
  .filter((station) => station.disposition === 'provisional')
  .map(async (station) => ({
    id: station.id,
    slug: station.slug,
    name: station.name,
    blurb: station.blurb,
    status: 'scheduled',
    route: station.route ?? null,
    destinationKind: station.destinationKind ?? null,
    purpose: station.purpose ?? null,
    zone: station.zone,
    lifecycle: station.lifecycle,
    keeper: station.keeper,
    keeperID: station.keeperID,
    unlockedAtStart: station.unlockedAtStart,
    startingTier: station.startingTier,
    catalogueMaxTier: station.catalogueMaxTier,
    buildCost: station.buildCost,
    buildBlurb: station.buildBlurb,
    assetURL: null,
    contextAssetURL: null,
  })));

const terrain = [];
for (const asset of family('terrain-production-pack-v1')?.assets.filter(
  (asset) => asset.role === 'runtime' && asset.semanticKey.includes('/macro/'),
) ?? []) {
  const name =
    asset.semanticKey.match(/macro\/(.+?)-semantic/)?.[1] ?? asset.semanticKey;
  terrain.push({
    name,
    assetURL: await publishAsset(asset, 'terrain', safeFileName(name)),
  });
}

const writingAsset = family('writing-parchment-v1')?.assets.find(
  (asset) => asset.semanticKey === 'runtime/writing.parchment.handmade-v1',
);
const writingAssetURL = await publishAsset(
  writingAsset,
  'writing',
  'writing-parchment.png',
);
const writingVisuals = await Promise.all([
  [
    'tool',
    'Writing tool',
    'A retained Writing Desk tool',
    'parts/tools/brush/asset',
    'writing-tool-brush.png',
  ],
  [
    'mark',
    'Mark',
    'A retained Writing Desk mark',
    'lookups/marks/mark/source/bloom/brush/0/roles/rgba/bloom',
    'writing-mark-bloom.png',
  ],
  [
    'link',
    'Link',
    'A retained Writing Desk link',
    'lookups/links/link/brush/horizontal/asset',
    'writing-link-brush-horizontal.png',
  ],
].map(async ([id, label, alt, semanticKey, fileName]) => ({
  id,
  label,
  alt,
  assetURL: await publishAsset(
    runtimeAsset('writing-desk-production-pack-v1', semanticKey),
    'writing',
    fileName,
  ),
})));

const explorationVisuals = await Promise.all([
  ['entryPortal', 'entry_portal/ordinary/frame-0', 'entry-portal.png'],
  ['unsearchedSite', 'wayfarers_camp/unlooted/frame-0', 'site-unsearched.png'],
  ['searchedSite', 'wayfarers_camp/looted/frame-0', 'site-searched.png'],
].map(async ([name, semanticKey, fileName]) => [
  name,
  await publishAsset(
    runtimeAsset('exploration-map-identities-v1', semanticKey),
    'exploration',
    fileName,
  ),
]));

const playerContent = {
  schemaVersion: 1,
  resources,
  items,
  creatures,
  sites,
  travellers,
  cast,
  stations,
  scheduledStations,
  researchBranches: researchSource.branches
    .map((branch) => ({
      id: branch.id,
      name: branch.name,
      blurb: researchBranchCopy[branch.id] ?? branch.blurb,
      order: branch.order,
      stationID: branch.station ?? null,
    }))
    .sort((left, right) => left.order - right.order),
  researchNodes: researchSource.nodes.map((node) => ({
    id: node.id,
    branch: node.branch,
    name: node.name,
    blurb: researchBlurb(node),
    cost: {
      essence: node.cost?.essence ?? 0,
      resources: node.cost?.resources ?? {},
    },
    requires: node.requires ?? [],
    needsStationTier: node.needsStationTier ?? 0,
    needsInstruments: node.needsInstruments ?? 0,
    needsLifetimeRawRefined: node.needsLifetimeRawRefined ?? 0,
    constructionBundledWith: node.constructionBundledWith ?? null,
  })),
  combatTechniques,
  gambitComponents,
  pressureTargets: pressureTargetSource.targets
    .map((target) => ({
      id: target.id,
      name: target.name,
      blurb: target.blurb,
      highLabel: target.highLabel,
      lowLabel: target.lowLabel,
      order: target.order,
    }))
    .sort((left, right) => left.order - right.order),
  terminology: source.terminology.map((term) => ({
    id: term.id,
    slug: term.slug,
    name: term.name,
    summary: term.summary,
    domain: term.domain,
    aliases: term.aliases,
  })),
  terrain,
  writingAssetURL,
  writingVisuals,
  explorationVisuals: Object.fromEntries(explorationVisuals),
};

await writeFile(
  outputDataPath,
  `${JSON.stringify(playerContent, null, 2)}\n`,
  'utf8',
);
console.log(
  `Synced ${resources.length} resources, ${items.length} items, ${cast.length} published cast pages, and ${stations.length} current places.`,
);
