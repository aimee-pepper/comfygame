import crypto from "node:crypto";

export const WIDTH = 16;
export const HEIGHT = 19;
export const PIVOT = Object.freeze({ x: 8, y: 18 });
export const MINIMAP_SIZE = 7;

export const sourceIdentities = Object.freeze([
  { id: "entry_portal", kind: "portal", title: "Entry Portal", searchable: false, animation: "ambient-inward-seam", frames: 3 },
  { id: "exit_portal", kind: "portal", title: "Return Portal", searchable: false, animation: "ambient-outward-seam", frames: 3 },
  { id: "locked_cache", kind: "cache", title: "Locked Cache", searchable: false, animation: "static", frames: 1 },
  { id: "loose_world_page", kind: "writing", title: "Loose World Page", searchable: false, animation: "static", frames: 1 },
  { id: "diary_page", kind: "writing", title: "Diary Page", searchable: false, animation: "static", frames: 1 },
  { id: "found_writing", kind: "writing", title: "Found Writing", searchable: false, animation: "static", frames: 1 },
  { id: "hazard", kind: "hazard", title: "Known hazard", searchable: false, animation: "ambient-instability", frames: 3 },
  { id: "wayfarers_camp", kind: "site", title: "Wayfarer's Camp", searchable: true, animation: "static", frames: 1 },
  { id: "binders_workshop", kind: "site", title: "Binder's Workshop", searchable: true, animation: "static", frames: 1 },
  { id: "glacial_vault", kind: "site", title: "Glacial Vault", searchable: true, animation: "static", frames: 1 },
  { id: "spent_emanation_housing", kind: "site", title: "Spent Emanation Housing", searchable: true, animation: "static", frames: 1 },
  { id: "crystal_cavern", kind: "site", title: "Crystal Cavern", searchable: true, animation: "ambient-glint", frames: 2 },
  { id: "geyser_basin", kind: "site", title: "Geyser Basin", searchable: true, animation: "ambient-steam", frames: 3 },
  { id: "brood_warren", kind: "site", title: "Brood Warren", searchable: true, animation: "ambient-living", frames: 2 },
  { id: "the_tear", kind: "site", title: "The Tear", searchable: true, animation: "ambient-energy", frames: 3 },
  { id: "natural_anchor", kind: "site", title: "Atlas Seam", searchable: false, animation: "ambient-seam", frames: 3 },
]);

const rgba = hex => {
  const value = hex.replace("#", "");
  return [
    Number.parseInt(value.slice(0, 2), 16),
    Number.parseInt(value.slice(2, 4), 16),
    Number.parseInt(value.slice(4, 6), 16),
    value.length === 8 ? Number.parseInt(value.slice(6, 8), 16) : 255,
  ];
};

const palettes = Object.freeze({
  entry_portal: { d: "#30383d", s: "#59666a", l: "#9aa6a1", k: "#13242c", b: "#276b89", c: "#53bdd2", h: "#c9f3e5" },
  exit_portal: { d: "#30333d", s: "#5c606c", l: "#a4a8a2", k: "#17162a", b: "#294aa0", c: "#48b7d4", h: "#c5f3e6", p: "#8252d2" },
  locked_cache: { d: "#302823", s: "#5a6570", l: "#aeb7b4", w: "#7d4c2d", m: "#404a55", v: "#8d4ba5" },
  loose_world_page: { d: "#735039", l: "#cba873", h: "#ead7a5", g: "#bd8e31" },
  diary_page: { d: "#71503a", l: "#d0af78", i: "#4f4f91" },
  found_writing: { d: "#2c3034", s: "#5a6264", l: "#969d95", c: "#49b9c0", h: "#a8e7d7", b: "#7a4b31" },
  hazard: { d: "#302b31", s: "#5f535b", l: "#908089", o: "#803844", f: "#bb5260", h: "#e28c83" },
  camp: { d: "#352d28", b: "#66513d", c: "#a78255", l: "#d7bd7b", r: "#763f32", f: "#d86e35", k: "#27312b" },
  workshop: { d: "#302927", w: "#624435", l: "#9b6b45", p: "#d1aa70", m: "#686e68", h: "#afb2a5", i: "#d6c795" },
  vault: { d: "#27333a", b: "#426474", i: "#70a8b3", l: "#a9d7d6", h: "#e0f3e9", k: "#19232d" },
  housing: { d: "#2b2d30", m: "#555b5b", l: "#878d83", h: "#c2b990", c: "#8b5c35", r: "#57372d", k: "#171b1e" },
  crystal: { d: "#292b38", r: "#4f485e", p: "#7056a3", c: "#4eb3bc", l: "#8ce0d1", h: "#dcffdb", k: "#171b24" },
  geyser: { d: "#3a3734", r: "#6f6254", s: "#a79070", w: "#477f89", l: "#78bdbe", h: "#d1e2ce", m: "#b7c2b5" },
  warren: { d: "#33231e", e: "#704333", l: "#a7603e", f: "#c09556", g: "#677c35", h: "#a5b95a", k: "#171311" },
  tear: { d: "#252433", r: "#4f4656", v: "#6536b7", p: "#9356ec", c: "#35c4d2", h: "#a7f7e8", k: "#131324" },
  anchor: { d: "#34373a", s: "#646869", l: "#a5a89f", g: "#9a7437", h: "#d7bc67", c: "#5fbdd0", w: "#d4f3dc", k: "#1b2224" },
});

const rows = Object.freeze({
  entry_portal: [
    "................", "......ss........", "....ssllss......", "...slddddls.....",
    "..sldkkkkdls....", "..sdkkcckkds....", ".sldkcbhckdls...", ".sldkcbbckdls...",
    ".sldkkbbkkdls...", "..sdkcbbckds....", "..sldkcckdls....", "...sdkcckds.....",
    "...sddccdds.....", "..ssddccddss....", ".sllssccsslls...", ".sdddddddddds...",
    "..ssssssssss....", "....ssssss......", "................",
  ],
  exit_portal: [
    "................", "....ss....ss....", "...slls..slls...", "..sldds..sddls..",
    "..sdkkd..dkkds..", ".sldkcc..cckdls.", ".sdkcpk..kpckds.", ".sdkcck..kcckds.",
    ".sldkkc..ckkdls.", "..sdkcc..cckds..", "..sldkc..ckdls..", "...sdkc..ckds...",
    "...sddc..cdds...", "..ssddc..cddss..", ".sllddccddlls...", ".sdddddddddds...",
    "..ssssssssss....", "....ssssss......", "................",
  ],
  locked_cache: [
    "................", "................", "................", "....ssssss......",
    "...slllllls.....", "..slddddddds....", "..sdwwwwwwds....", ".sldwllllwdls...",
    ".sldwddddwdls...", ".sddwwwwwwdds...", ".sdmmmmmmmmms...", ".sdmmmvmmmmmms..",
    ".sdmmvvvmmmmms..", ".sdmmmvmmmmmms..", ".sddddddddddds..", "..sdddddddds....",
    "...ssssssss.....", "....ssssss......", "................",
  ],
  loose_world_page: [
    "................", "................", "................", "................",
    "................", ".....dddd.......", "....dllllld.....", "...dllhhhld.....",
    "..dllhggghld....", "..dlhgggggld....", "..dlhgggggld....", "..dllgggglld....",
    "...dllgllld.....", "....dllllld.....", ".....ddddld.....", "......ddddd.....",
    ".......ddd......", "................", "................",
  ],
  diary_page: [
    "................", "................", "................", "................",
    "................", ".......dd.......", ".....ddl........", "....dlllld......",
    "...dlliiild.....", "..dlliiilld.....", "..dliiillld.....", "..dliilllld.....",
    "...dilllld......", "...dllllld......", "....dldddd......", ".....ddd........",
    "................", "................", "................",
  ],
  found_writing: [
    "................", "................", "................", "................",
    "................", "....ddddd.......", "...dsssssdd.....", "..dslllllssd....",
    "..dslcccclsd....", "..dslcchclsd....", "..dslcccllsd....", "..dslllllssd....",
    "...dssssssd.....", "....ddddddd.....", ".....b..b.......", "....bb..bb......",
    "....b....b......", "................", "................",
  ],
  hazard: [
    "................", "................", "................", "................",
    "................", "................", "....dd..dd......", "...dsd.ddsd.....",
    "..dsslssdssd....", ".dsssoofssssd...", ".dssffofssssd...", "..dssfoffssd....",
    ".dsssooffssssd..", "..dsssfofsssd...", "...dsssoossd....", "....dssssdd.....",
    ".....dddd.......", "................", "................",
  ],
  wayfarers_camp: [
    "................", ".......l........", "......lcl.......", ".....lcccl......",
    "....lcccccl.....", "...lccbbbccl....", "..lccbbbbbccl...", "..lcbbdddbbcl...",
    ".lcbbdkkkdbbcl..", ".lcbbdkkkdbbcl..", ".lcbddkkkddbcl..", ".lcbbbbbbbbccl..",
    "..lccccccccl....", "..drr....rrd....", ".drffr..rffrd...", ".ddrrd..drrdd...",
    "..dddd..dddd....", "...dd....dd.....", "................",
  ],
  binders_workshop: [
    "................", "......hh........", ".....hmmh.......", "....hmmmmd......",
    "....mddddm......", "...mddwwddm.....", "...mdwllwdm.....", "..mddwppwddm....",
    "..mddwwwwddm....", ".mddddddddddm...", ".mwwwwwwwwwwm...", ".dwlwiiiilwwd...",
    ".dwwiiiiiiwwd...", "..ddwwwwwwdd....", "..dwlwddwlwd....", "..dwlwddwlwd....",
    "..ddd....ddd....", ".dddd....dddd...", "................",
  ],
  glacial_vault: [
    "................", ".......h........", "......hlh.......", ".....hlllh......",
    "....hliiilh.....", "...hliibbilh....", "..hliibbbbilh...", "..liibddddbiil..",
    ".liibdkkkkdbiil.", ".libdkkkkkkdbil.", ".libdkkkkkkdbil.", ".libdkkkkkkdbil.",
    ".liibdkkkkdbiil.", "..liibddddbiil..", "..bliibbiilb....", ".bbliibbilbbb...",
    ".bbbbbbbbbbbb...", "..bbb....bbb....", "................",
  ],
  spent_emanation_housing: [
    "................", "......hh........", ".....hllh.......", "....hmllmh......",
    "....mddddm......", "...mdkkkkdm.....", "...mdkrrkdm.....", "...mdkrrkdm.....",
    "...mdkkkkdm.....", "..mddddddddm....", "..mllmmmmllm....", "..mdkkkkkkdm....",
    "..mdkcccckdm....", "..mdkcccckdm....", "..mdkkkkkkdm....", ".mddmmmmmmddm...",
    ".dddddddddddd...", "..ddd....ddd....", "................",
  ],
  crystal_cavern: [
    "................", "................", "......rr........", "....rrddrr......",
    "...rddkkddr.....", "..rddkkkkddr....", "..rdkkkkkkdr....", ".rdkkkkkkkkdr...",
    ".rdkkkkkkkkdr...", ".rddkkkkkkddr...", "..rddkkkkddr....", "..rrddddddrr....",
    "....pc..p.......", "...pcc.plp......", "..pclcplclp.....", ".pclhclhclcp....",
    ".dpppppppppd....", ".ddddddddddd....", "................",
  ],
  geyser_basin: [
    "................", ".......m........", ".....m..m.......", "......mm........",
    "....m...m.......", ".....mmm........", "................", "................",
    "......hh........", "....hlwwlh......", "...lwwwwwwl.....", "..swwllllwws....",
    ".swwlwwwwlwws...", ".rwwwwwwwwwwr...", ".rrswwwwwwsrr...", "..rrrssssrrr....",
    "...rrrrrrrr.....", "....rrrrrr......", "................",
  ],
  brood_warren: [
    "................", "................", "................", ".....hh.........",
    "...hggggh.......", "..geelleeg......", ".geleeleleg.....", ".eledddddele....",
    ".eldkddkdle.....", ".eldkkdkkdle....", ".eldddkkdle.....", ".eeldkkdllee....",
    "..eeldkdlee.....", ".eleedddelle....", ".eeleeeeleee....", ".eeeeeeeeeee....",
    "..eeee..eeee....", "...ee....ee.....", "................",
  ],
  the_tear: [
    "................", ".......r........", "......rv........", "......vpr.......",
    ".....rphv.......", ".....vpcr.......", "....rvchv.......", "....vphpr.......",
    "...rvchv........", "...vphpr........", "....vchvr.......", "....rphpr.......",
    ".....vchv.......", "....rvphpr......", ".....vchv.......", "....rrvprr......",
    "...rrddddrr.....", "....dddddd......", "................",
  ],
  natural_anchor: [
    "................", ".......l........", "......lsl.......", ".....lsdsl......",
    ".....sddds......", "......scs.......", "......cwc.......", ".....c.c........",
    "....c...c.......", "...c.....c......", "..lsc...csl.....", ".lsdsl.lsdsl....",
    ".sddds.sddds....", ".sdcws.swdcs....", ".sddds.sddds....", "..sss...sss.....",
    "...s.....s......", "................", "................",
  ],
});

function rowSprite(id) {
  const sourceRows = rows[id];
  if (sourceRows.length !== HEIGHT || sourceRows.some(row => row.length !== WIDTH)) {
    throw new Error(`invalid authored row dimensions for ${id}: ${sourceRows.map(row => row.length).join(",")}`);
  }
  const out = new Uint8ClampedArray(WIDTH * HEIGHT * 4);
  const paletteKey = {
    wayfarers_camp: "camp",
    binders_workshop: "workshop",
    glacial_vault: "vault",
    spent_emanation_housing: "housing",
    crystal_cavern: "crystal",
    geyser_basin: "geyser",
    brood_warren: "warren",
    the_tear: "tear",
    natural_anchor: "anchor",
  }[id] ?? id;
  const palette = palettes[paletteKey];
  for (let y = 0; y < HEIGHT; y += 1) {
    for (let x = 0; x < WIDTH; x += 1) {
      const symbol = sourceRows[y][x];
      if (symbol === ".") continue;
      const color = palette[symbol];
      if (!color) throw new Error(`unknown ${id} palette symbol ${symbol}`);
      out.set(rgba(color), (y * WIDTH + x) * 4);
    }
  }
  return out;
}

const clone = bytes => new Uint8ClampedArray(bytes);
const clear = (bytes, points) => points.forEach(([x, y]) => bytes.fill(0, (y * WIDTH + x) * 4, (y * WIDTH + x + 1) * 4));
const paint = (bytes, points, color) => points.forEach(([x, y]) => bytes.set(rgba(color), (y * WIDTH + x) * 4));

function applyLooted(id, bytes) {
  const out = clone(bytes);
  switch (id) {
  case "wayfarers_camp":
    clear(out, [[2,14],[3,14],[4,14],[2,15],[3,15],[4,15]]);
    paint(out, [[2,15],[3,16],[4,15]], palettes.camp.d);
    break;
  case "binders_workshop":
    clear(out, [[4,11],[5,11],[6,11],[4,12],[5,12],[6,12]]);
    paint(out, [[4,12],[5,12],[6,12]], palettes.workshop.d);
    break;
  case "glacial_vault":
    paint(out, [[7,9],[8,9],[7,10],[8,10],[7,11],[8,11]], palettes.vault.d);
    clear(out, [[7,12],[8,12]]);
    break;
  case "spent_emanation_housing":
    paint(out, [[6,12],[7,12],[8,12],[9,12],[6,13],[9,13]], palettes.housing.d);
    clear(out, [[7,13],[8,13]]);
    break;
  case "crystal_cavern":
    clear(out, [[4,13],[3,14],[4,14],[11,14],[3,15],[11,15]]);
    paint(out, [[5,15],[10,15]], palettes.crystal.r);
    break;
  case "geyser_basin":
    clear(out, [[3,12],[3,13],[4,13]]);
    paint(out, [[3,13],[4,14]], palettes.geyser.r);
    break;
  case "brood_warren":
    clear(out, [[3,6],[4,6],[2,7],[3,7],[4,7]]);
    paint(out, [[3,7],[4,8]], palettes.warren.d);
    break;
  case "the_tear":
    clear(out, [[7,6],[6,8],[7,10]]);
    paint(out, [[7,6],[6,8],[7,10]], palettes.tear.v);
    break;
  default:
    throw new Error(`looted state is not legal for ${id}`);
  }
  return out;
}

function applyFrame(id, state, bytes, frame) {
  const out = clone(bytes);
  const table = {
    entry_portal: [
      [[7,6],[8,8],[7,11]], [[8,6],[7,9],[8,12]], [[7,7],[8,10],[7,12]],
    ],
    exit_portal: [
      [[5,6],[10,7],[7,14]], [[5,8],[10,6],[8,14]], [[5,7],[10,9],[7,13]],
    ],
    hazard: [
      [[7,9],[6,11],[8,13]], [[8,9],[7,11],[9,13]], [[7,10],[8,11],[7,13]],
    ],
    crystal_cavern: [
      [[7,13],[6,15]], [[8,13],[9,15]],
    ],
    geyser_basin: [
      [[7,1],[5,4]], [[6,2],[8,4]], [[8,2],[6,5]],
    ],
    brood_warren: [
      [[7,3],[3,6],[12,7]], [[8,3],[4,6],[11,7]],
    ],
    the_tear: [
      [[7,5],[6,9],[7,13]], [[6,6],[7,10],[6,14]], [[7,7],[6,11],[7,14]],
    ],
    natural_anchor: [
      [[7,7],[5,10],[9,10]], [[7,8],[6,10],[8,10]], [[7,9],[5,11],[9,11]],
    ],
  };
  const points = table[id]?.[frame];
  if (!points) return out;
  const color = {
    entry_portal: palettes.entry_portal.h,
    exit_portal: palettes.exit_portal.h,
    hazard: palettes.hazard.h,
    crystal_cavern: palettes.crystal.h,
    geyser_basin: palettes.geyser.h,
    brood_warren: palettes.warren.h,
    the_tear: palettes.tear.h,
    natural_anchor: palettes.anchor.w,
  }[id];
  paint(out, points, color);
  if (state === "looted" && id === "the_tear") clear(out, [[7,6]]);
  return out;
}

export function stableKey(id, state, frame) {
  return `${id}/${state}/frame-${frame}`;
}

export function enumerateSprites() {
  const sprites = [];
  for (const identity of sourceIdentities) {
    const states = identity.searchable ? ["unlooted", "looted"] : ["ordinary"];
    const base = rowSprite(identity.id);
    for (const state of states) {
      const stateBytes = state === "looted" ? applyLooted(identity.id, base) : base;
      for (let frame = 0; frame < identity.frames; frame += 1) {
        sprites.push({
          key: stableKey(identity.id, state, frame),
          identity: identity.id,
          kind: identity.kind,
          state,
          frame,
          frameCount: identity.frames,
          animation: identity.animation,
          width: WIDTH,
          height: HEIGHT,
          pivot: PIVOT,
          rgba: applyFrame(identity.id, state, stateBytes, frame),
        });
      }
    }
  }
  return sprites;
}

const minimapRows = Object.freeze({
  portal: ["..sss..", ".sllds.", "sldkdls", "sdkckds", "sldkdls", ".sddds.", "..sss.."],
  page: ["..ddd..", ".dllld.", "dlhhld.", "dlhgld.", "dlhhld.", ".dddd..", "......."],
  cache: [".sssss.", "sllllls", "sdwwwds", "sdmvmds", "sddddds", ".sssss.", "......."],
  hazard: ["..o.o..", ".offfo.", "ofdhfdo", ".ffoff.", "..fof..", "...f...", "......."],
  site: ["...l...", "..lsl..", ".lsdsl.", "lsdddsl", ".sddds.", ".ss.ss.", "......."],
  // Exact accepted resource minimap grammar (#eee5d5 highlight over #d8bd82 body),
  // centered without scaling inside this pack's 7×7 category canvas.
  resource: [".......", "...h...", "..bb...", "..bb...", ".......", ".......", "......."],
});

export function enumerateMinimapSprites() {
  return Object.entries(minimapRows).map(([identity, sourceRows]) => {
    const out = new Uint8ClampedArray(MINIMAP_SIZE * MINIMAP_SIZE * 4);
    const palette = {
      portal: palettes.entry_portal,
      page: palettes.loose_world_page,
      cache: palettes.locked_cache,
      hazard: palettes.hazard,
      site: palettes.anchor,
      resource: { b: "#d8bd82", h: "#eee5d5" },
    }[identity];
    sourceRows.forEach((row, y) => [...row].forEach((symbol, x) => {
      if (symbol === ".") return;
      const color = palette[symbol];
      if (!color) throw new Error(`unknown minimap ${identity} symbol ${symbol}`);
      out.set(rgba(color), (y * MINIMAP_SIZE + x) * 4);
    }));
    return {
      key: `minimap/${identity}/ordinary`,
      identity,
      kind: "minimap",
      state: "ordinary",
      frame: 0,
      frameCount: 1,
      animation: "static",
      width: MINIMAP_SIZE,
      height: MINIMAP_SIZE,
      pivot: { x: 3, y: 3 },
      rgba: out,
    };
  });
}

export function lookupSprite(manifest, request) {
  const exactKeys = ["identity", "state", "visibility", "presentationTick", "reduceMotion"];
  if (!request || Object.keys(request).sort().join("|") !== [...exactKeys].sort().join("|")) return null;
  if (!["full", "remembered", "hidden"].includes(request.visibility)) return null;
  if (typeof request.reduceMotion !== "boolean" || !Number.isSafeInteger(request.presentationTick) || request.presentationTick < 0) return null;
  if (request.visibility === "hidden") return null;
  const identity = sourceIdentities.find(row => row.id === request.identity);
  if (!identity) return null;
  const states = identity.searchable ? ["unlooted", "looted"] : ["ordinary"];
  if (!states.includes(request.state)) return null;
  const frame = request.visibility === "full" && !request.reduceMotion
    ? request.presentationTick % identity.frames
    : 0;
  return manifest.assetsByKey[stableKey(identity.id, request.state, frame)] ?? null;
}

export const sha256 = value => crypto.createHash("sha256").update(value).digest("hex");
