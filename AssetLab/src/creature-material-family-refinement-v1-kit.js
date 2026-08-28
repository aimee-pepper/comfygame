export const MATERIAL_REFINEMENT_VERSION = "creature-material-family-refinement-v1.0.0";
export const MATERIAL_SIZE = Object.freeze({ width: 32, height: 32, pivot: [16, 28] });
export const REFINED_FAMILIES = Object.freeze(["feather", "fin", "scale", "oil", "shell", "horn", "venom"]);

const ink = "#261d19";
const rect = (x, y, w, h, color, alpha = 1) => Object.freeze({ op: "rect", x, y, w, h, color, alpha });
const pixel = (commands, x, y, color, alpha = 1) => commands.push(rect(x, y, 1, 1, color, alpha));
const run = (commands, y, x, width, color, alpha = 1) => { if (width > 0) commands.push(rect(x, y, width, 1, color, alpha)); };

function featherCommands() {
  const commands = [], shade = "#9b6948", body = "#d7aa68", light = "#f0d39a", shaft = "#efe2bd";
  for (let y = 5; y <= 25; y++) {
    const progress = 25 - y, center = 10 + Math.round(progress * .48), breadth = Math.max(1, Math.round(Math.sin((y - 4) / 22 * Math.PI) * 7));
    const notch = (y === 9 || y === 14 || y === 19) ? 2 : 0;
    run(commands, y, center - breadth - 1, breadth * 2 + 3, ink);
    run(commands, y, center - breadth, Math.max(1, breadth - notch), shade);
    run(commands, y, center + 1 + notch, Math.max(1, breadth - notch), body);
    if (y % 4 === 1 && breadth > 3) pixel(commands, center + breadth - 1, y, light);
  }
  for (let y = 4; y <= 28; y++) { const x = 10 + Math.round((25 - Math.min(y, 25)) * .48); pixel(commands, x, y, y < 24 ? shaft : ink); }
  run(commands, 27, 8, 5, ink); run(commands, 26, 9, 4, shaft);
  return commands;
}

function finCommands() {
  const commands = [], shade = "#326c78", ridge = "#24444b", body = "#58a6a3", light = "#9bd1bd", membrane = "#6eb7ad";
  const rows = [[7,21,4],[8,18,8],[9,16,11],[10,14,13],[11,12,15],[12,11,16],[13,10,17],[14,9,18],[15,8,19],[16,7,20],[17,7,20],[18,6,21],[19,6,21],[20,7,20],[21,7,20],[22,8,19],[23,8,19],[24,9,18],[25,10,17]];
  for (const [y, x, width] of rows) { run(commands, y, x - 1, width + 2, ink); run(commands, y, x, width, y < 15 ? membrane : body); }
  // Dark radial supports visibly fan from one thick attachment root. Their
  // shared origin is deliberately unlike a Feather's paired central vane.
  for (const [tx, ty] of [[22,8],[18,10],[14,12],[10,16],[7,20]]) {
    const verticalSpan = 23 - ty;
    for (let y = ty; y <= 23; y++) {
      const x = Math.round(tx + (26 - tx) * (y - ty) / verticalSpan);
      pixel(commands, x, y, y === ty || y === 23 ? ink : ridge);
    }
  }
  run(commands, 8, 25, 3, ink); run(commands, 9, 26, 2, ink); run(commands, 10, 26, 2, ink);
  run(commands, 11, 26, 2, ink); run(commands, 12, 26, 2, ink); run(commands, 13, 26, 2, ink);
  run(commands, 14, 26, 2, ink); run(commands, 15, 26, 2, ink); run(commands, 16, 26, 2, ink);
  run(commands, 17, 26, 2, ink); run(commands, 18, 26, 2, ink); run(commands, 19, 26, 2, ink);
  run(commands, 20, 26, 2, ink); run(commands, 21, 26, 2, ink); run(commands, 22, 26, 2, ink);
  run(commands, 23, 25, 3, ink); run(commands, 24, 22, 6, ink); run(commands, 24, 23, 3, light);
  return commands;
}

function singleScale(commands, ox, oy, body, light) {
  const rows = [[0,2,6],[1,1,8],[2,0,10],[3,0,10],[4,1,8],[5,2,6],[6,3,4],[7,4,2]];
  for (const [y, x, width] of rows) { run(commands, oy + y, ox + x - 1, width + 2, ink); run(commands, oy + y, ox + x, width, y < 2 ? light : body); }
  run(commands, oy + 3, ox + 2, 6, "#477884");
}
function scaleCommands() {
  const commands = [], body = "#5e9ca0", light = "#a7d0be";
  singleScale(commands, 5, 7, body, light); singleScale(commands, 14, 5, "#4f8c98", "#9bc9c4"); singleScale(commands, 19, 12, body, light); singleScale(commands, 8, 15, "#477f8b", "#91c3b8"); singleScale(commands, 15, 18, "#5b9695", "#a6cdb7");
  return commands;
}

function oilCommands() {
  const commands = [], edge = "#5e4a2c", membrane = "#978d4e", pool = "#c9bc65", light = "#f1e6a0";
  const rows = [[11,11,10],[12,8,16],[13,6,20],[14,5,22],[15,5,23],[16,4,24],[17,4,25],[18,5,23],[19,5,22],[20,6,20],[21,8,16],[22,11,10],[23,14,5]];
  for (const [y, x, width] of rows) { run(commands, y, x - 1, width + 2, ink); run(commands, y, x, width, membrane, .78); }
  run(commands, 15, 8, 18, pool, .72); run(commands, 16, 7, 20, pool, .76); run(commands, 17, 7, 19, pool, .8); run(commands, 18, 9, 15, "#b5a955", .84);
  run(commands, 13, 11, 10, light, .88); run(commands, 14, 10, 7, light, .92); run(commands, 21, 11, 9, edge);
  pixel(commands, 6, 15, ink); pixel(commands, 27, 17, ink); pixel(commands, 8, 20, edge);
  return commands;
}

function shellCommands() {
  const commands = [], shade = "#9d5c48", body = "#d3835b", light = "#f0c28e", ridge = "#6d4336";
  const rows = [[7,14,4],[8,11,10],[9,9,14],[10,7,18],[11,6,20],[12,5,22],[13,4,24],[14,4,24],[15,4,24],[16,5,22],[17,5,22],[18,6,20],[19,7,18],[20,8,16],[21,9,14],[22,11,10],[23,13,6],[24,14,4]];
  for (const [y, x, width] of rows) { run(commands, y, x - 1, width + 2, ink); run(commands, y, x, width, y < 13 ? light : body); }
  // Concentric growth bands plus radial ribs keep the fragment shell-specific.
  for (const [y, x, width] of [[11,8,16],[15,5,22],[19,8,16],[22,12,8]]) run(commands, y, x, width, ridge);
  for (const [targetX, targetY] of [[6,14],[10,9],[16,7],[22,10],[27,14]]) {
    for (let step = 0; step <= 13; step++) { const x = Math.round(16 + (targetX - 16) * step / 13), y = Math.round(24 + (targetY - 24) * step / 13); pixel(commands, x, y, step % 3 ? shade : light); }
  }
  run(commands, 24, 12, 8, ink); run(commands, 23, 14, 4, "#f4d3a7");
  return commands;
}

function hornCommands() {
  const commands = [], shade = "#70553d", body = "#a9855c", light = "#ddc08c", ridge = "#49372b";
  // A ridged keratin cone with a visible cut base, not the accepted smooth ivory tusk.
  for (let step = 0; step < 20; step++) {
    const y = 25 - step, center = 9 + Math.round(step * .72), half = Math.max(1, 5 - Math.floor(step / 5));
    run(commands, y, center - half - 1, half * 2 + 3, ink); run(commands, y, center - half, half * 2 + 1, step < 7 ? shade : body);
    if (step % 5 === 2) run(commands, y, center - half, half * 2 + 1, ridge);
    if (step > 8) pixel(commands, center, y, light);
  }
  // Open cut base with an inner keratin ring.
  run(commands, 25, 4, 11, ink); run(commands, 26, 5, 10, ink); run(commands, 27, 6, 8, ink); run(commands, 25, 6, 7, light); run(commands, 26, 7, 6, "#5a4031"); run(commands, 27, 8, 4, shade);
  return commands;
}

function venomCommands() {
  const commands = [], edge = "#3c3b28", gland = "#788c43", light = "#bdcf6a", deep = "#59682f", toxin = "#9bb455";
  const rows = [[9,19,4],[10,17,7],[11,15,9],[12,13,11],[13,11,13],[14,10,14],[15,9,15],[16,8,16],[17,8,16],[18,8,15],[19,9,14],[20,9,13],[21,10,12],[22,11,10],[23,12,8],[24,14,5]];
  for (const [y, x, width] of rows) { run(commands, y, x - 1, width + 2, ink); run(commands, y, x, width, y < 14 ? deep : gland); }
  // Pinched organic outlet and short duct; no bottle cap or container body.
  run(commands, 7, 22, 6, ink); run(commands, 8, 20, 8, ink); run(commands, 9, 20, 6, toxin); pixel(commands, 28, 7, ink); pixel(commands, 29, 6, ink);
  run(commands, 14, 13, 7, light); run(commands, 15, 11, 8, light); run(commands, 16, 11, 5, light); pixel(commands, 20, 19, toxin); pixel(commands, 13, 21, toxin); pixel(commands, 17, 22, deep);
  return commands;
}

const builders = Object.freeze({ feather: featherCommands, fin: finCommands, scale: scaleCommands, oil: oilCommands, shell: shellCommands, horn: hornCommands, venom: venomCommands });

export function refinedMaterialCommands(id) {
  const builder = builders[id];
  if (!builder) throw new Error(`unsupported-refined-material:${id}`);
  return Object.freeze(builder().map(Object.freeze));
}

export function commandBounds(commands) {
  const minX = Math.min(...commands.map(command => command.x)), minY = Math.min(...commands.map(command => command.y));
  const maxX = Math.max(...commands.map(command => command.x + command.w)), maxY = Math.max(...commands.map(command => command.y + command.h));
  return Object.freeze({ x: minX, y: minY, width: maxX - minX, height: maxY - minY });
}

export function silhouetteKey(commands) {
  const pixels = new Set();
  for (const command of commands) for (let y = command.y; y < command.y + command.h; y++) for (let x = command.x; x < command.x + command.w; x++) pixels.add(`${x},${y}`);
  return [...pixels].sort().join("|");
}
