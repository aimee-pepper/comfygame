import { combatTreeV2Authority } from "./combat-tree-v2-authority.generated.js";

export const combatNodeGlyphVersion = "combat-node-glyph-0.1.0";
const roles = Object.freeze(["root", "fundamentalA", "fundamentalB", "developmentA", "developmentB", "masteryA", "masteryB", "capstone"]);
export const combatTechniqueByNodeID = combatTreeV2Authority.techniqueIDByNode;

const referents = Object.freeze({
  heavy_hand: "descending mallet and compression line", follow_through: "hammer arc past cracked shield", overbear: "ram wedge through resisting bar", bracing_stance: "planted boots beneath weapon haft", stagger: "sideways displaced footprint", shatter: "split plate around impact wedge", momentum: "weighted wheel with motion tail", breaking_blow: "hammer through separated armour",
  keen_eye: "open eye with pointed pupil", weak_point: "hide patch with exposed seam", pry: "blade levering plate corner", steady_hand: "forefinger aligned to fixed target", exploit: "point entering afflicted crack ring", finish: "blade ending at low life line", anatomy: "specimen divided into three cuts", killing_stroke: "diagonal cut through target ring",
  quick_step: "paired footprints and speed notch", light_touch: "feather on gear rim", quicken: "action hand echo and pause bar", second_wind: "breath curl returning to heart", flurry: "primary and adjacent slash", first_strike: "blade before retaliatory thorn", cascade: "three linked motion chevrons", blur: "actor between offset echoes",
  thick_hide: "layered hide with living inner line", iron_skin: "torso fitted with metal plate", brace: "bent knee behind grounded bar", constitution: "generic affliction entering shortened hourglass", endurance: "half heart in broad foundation", ward: "open palm facing selected harm", unyielding: "near-empty heart stopped by peg", immovable: "rooted figure in armour ring",
  bulwark: "shield sheltering bearer and ally", watchful: "eye above interrupted opening arrow", draw_off: "hook pulling enemy target line", cover: "front figure sharing incoming arrow", shieldwall: "three overlapping shield tops", interpose: "figure stepping between ally and strike", rally: "fallen foe sending rising heart pulses", guardian: "front arch closing paths to allies",
  footwork: "three-step curve around attack", light_frame: "hollow body with lift notches", sidestep: "figure displaced from attack line", slippery: "ambush arrow glancing from footprint trail", fall_back: "footprints crossing rank lines", feint: "forward attack breaking to side arc", untouchable: "attack ticks outside hollow figure", ghost: "attack through offset hollow silhouette",
  tainted_edge: "blade with hanging poison droplet", apothecary_s_hand: "hand tipping vial into cup", envenom: "edge drawn through poison groove", virulence: "droplet with segmented duration tail", flense: "hook lifting textured covering", corrode: "poison eating armour notch", distiller: "still coil returning coating vial", blight: "droplet budding toward second target",
  sparkhand: "open hand emitting compact flame ray", insulation: "figure and emanation separated by layer", emanation_strike: "weapon carrying three-lobed selector", attunement: "aligned waves meeting in crest", snuff: "pinching fingers closing rays", quench: "hand lifting Burn Poison or Dazzle mark", conduction: "emanation bridging between targets", emanant: "figure radiating repeated emanation",
  quiet_step: "soft footprint and broken sound ring", low_profile: "crouched figure below sight line", conceal: "figure entering crescent cover", opportunist: "hidden crescent opening to attack point", ambush: "concealed figure attacking before action ring", vanish: "figure dissolving through expedition boundary", shadowed: "three party silhouettes below sight line", unseen: "covered figure at encounter-start line",
});

export const disciplineMotifs = Object.freeze({
  force: "wedge", precision: "point", swiftness: "wind-notch",
  fortitude: "block", protection: "arch", evasion: "offset",
  venom: "droplet", emanation: "rays", shadow: "crescent",
});

const entries = [];
for (const tree of combatTreeV2Authority.trees) for (const discipline of tree.disciplines) for (const [index, slug] of discipline.nodes.entries()) {
  const referent = referents[slug];
  if (!referent) throw new Error(`missing-combat-glyph-referent:${slug}`);
  const id = `combat.${tree.id}.${discipline.id}.${slug}`;
  entries.push(Object.freeze({ id, treeID: tree.id, disciplineID: discipline.id, slug, role: roles[index], referent, motifID: disciplineMotifs[discipline.id], techniqueID: combatTechniqueByNodeID[id] ?? null }));
}
export const combatNodeGlyphEntries = Object.freeze(entries);
const byID = new Map(entries.map((entry) => [entry.id, entry]));

function exact(request, keys) {
  if (!request || typeof request !== "object" || Array.isArray(request)) throw new Error("invalid-combat-glyph-request");
  if (JSON.stringify(Object.keys(request).sort()) !== JSON.stringify([...keys].sort())) throw new Error("invalid-combat-glyph-fields");
}

export function resolveCombatNodeGlyph(request) {
  exact(request, ["nodeID", "state", "selected"]);
  const entry = byID.get(request.nodeID);
  if (!entry) throw new Error(`unknown-combat-glyph-node:${request.nodeID}`);
  if (!["owned", "available", "blocked"].includes(request.state) || typeof request.selected !== "boolean") throw new Error("invalid-combat-glyph-presentation");
  return Object.freeze({ identity: entry, layers: Object.freeze({ frameState: request.state, selected: request.selected, techniquePip: entry.techniqueID !== null, capstoneFrame: entry.role === "capstone" }) });
}

export function resolveCombatActionGlyph(nodeID) {
  const entry = byID.get(nodeID);
  if (!entry) throw new Error(`unknown-combat-glyph-node:${nodeID}`);
  if (entry.techniqueID === null) throw new Error(`passive-node-has-no-action-glyph:${nodeID}`);
  return Object.freeze({ nodeID: entry.id, techniqueID: entry.techniqueID, centralPictogramID: entry.id });
}

export function placeholderCombatPictogramCommands(nodeID) {
  if (!byID.has(nodeID)) throw new Error(`unknown-combat-glyph-node:${nodeID}`);
  let seed=2166136261; for(const character of `combat-placeholder-v1:${nodeID}`){seed^=character.charCodeAt(0);seed=Math.imul(seed,16777619)>>>0;} const commands=[];
  for(let row=0;row<5;row+=1) for(let col=0;col<5;col+=1) { seed=(Math.imul(seed,1664525)+1013904223)>>>0; if(seed&0x80000000) commands.push(Object.freeze({op:"rect",x:2+col*4,y:2+row*4,w:3,h:3})); }
  commands.push(Object.freeze({op:"rect",x:1,y:22,w:22,h:1}));
  return Object.freeze(commands);
}

export const combatGlyphCollisionFamilies = Object.freeze([
  Object.freeze(["heavy_hand", "follow_through", "breaking_blow"]),
  Object.freeze(["quick_step", "quicken", "cascade", "blur"]),
  Object.freeze(["brace", "bulwark", "shieldwall", "guardian"]),
  Object.freeze(["footwork", "sidestep", "slippery", "fall_back"]),
  Object.freeze(["tainted_edge", "envenom", "virulence", "blight"]),
  Object.freeze(["sparkhand", "emanation_strike", "attunement", "emanant"]),
  Object.freeze(["conceal", "ambush", "shadowed", "unseen"]),
]);
export const combatGlyphCrossDisciplineCollisions = Object.freeze([
  Object.freeze(["combat.defense.fortitude.ward", "combat.craft.emanation.quench", "combat.craft.emanation.snuff"]),
  Object.freeze(["combat.defense.protection.cover", "combat.defense.protection.interpose", "combat.defense.protection.guardian"]),
  Object.freeze(["combat.offense.swiftness.second_wind", "combat.defense.protection.rally"]),
  Object.freeze(["combat.offense.precision.anatomy", "combat.craft.venom.flense"]),
  Object.freeze(["combat.craft.shadow.low_profile", "combat.craft.shadow.shadowed"]),
  Object.freeze(["combat.craft.emanation.emanation_strike", "combat.craft.emanation.conduction"]),
]);
