import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import {
  MATERIAL_SIZE,
  REFINED_FAMILIES,
  refinedMaterialCommands,
  silhouetteKey,
} from "../src/creature-material-family-refinement-v1-kit.js";

const { createCanvas, loadImage } = createRequire(import.meta.url)("@napi-rs/canvas");
const assetLab = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const repo = path.resolve(assetLab, "..");
const source = path.join(assetLab, "source", "mob-gear-sprites-v1", "refined-mob-drops");
const pack = path.join(assetLab, "integration", "mob-gear-sprites-v1");
const artifact = path.join(assetLab, "artifacts", "world-material-pixel-correction-v1");
const receiptRoot = path.join(assetLab, "integration", "world-material-pixel-correction-v1");
const check = process.argv.includes("--check");
const sourceOnly = process.argv.includes("--source-only");
const parentCommit = "3aa44270a7930a2af52a3551200cc3060b988f81";
const sourceCheckpoint = "b3a33170314998c76909f8a2f2aeeb5d038882e8";
const sourceTree = "a8b3a8c2c66a101442a6372addeac3899c072cae";
const expectedSourceHashes = Object.freeze({
  feather: "d31cf1718b4169b8507ccaa80989f5bbc4366b328ae941d428979a000c270106",
  fin: "a2d7bd7a527023b1f1b5aff6d7aaa0846c7db62e077d9d5ac4bcf9ec26344c8f",
  scale: "be24a9b22bde4c49d39eadc2db16b1d3d330fa54428ffdb397a26f75087aaef2",
  oil: "f58235660562332dea4ec3a0156abe9f8da2fdda5622432dfbdd5ba6d66551d4",
  shell: "f10c6620c026f6aeb8b67b04ec6f46ac8ced850a776b05ccc0045fd30831a7d2",
  horn: "f3d72915f3c04fb3b9c140474909a75204043dc8152d65f04054ab59978a0914",
  venom: "b0c328438e9c82497bb04f54dacb9e02adbb7d86d2b8a916e455cf7e184e5cb2",
});
const preservedHashes = Object.freeze({
  plate: "c3a5b2b4daf166f5db8c255685f437c28733e5f6a8240f6bf3f1ef8a7e0ceec4",
  quill: "758bc8a1b19d1b19cfb4a534f582479ed12d16fc118e7ed18905257bb405e7da",
  pelt: "8c2d704229244ded55f615efd693877ca7469ed6a27e37d0ff2155c357bd6b11",
  down: "d1acb8d28f21f59b2bf11ab9248293312e2ab3596f8774762ec8b293f9604a18",
  hide: "dbf8dc993d7b9df36545c41cc2332b05c9d708d2e670355b6ec67fc52b1ff892",
  chitin: "ea7a03f2fda06bac2e3719fd98beccabc56820be24a06110c0968fb429f7957a",
  fang: "4986e8ef9f39889d8bbfc0f673349b923b05d3c808d74b09366e97df4d1ec0a0",
  tusk: "caf6346bf6fb2f208309855fb25d92354db22c6abe45f9b4027c5b47e56fccfc",
  claw: "ab7628b908c228da8bf485eda5c8e425a729a29506e991c0e4c805b3bddc8ded",
  bone: "5ae5fc492c76b99bcde84e930571f80009cb33a397fbfaa221d16826a726ff7d",
  ichor: "0bab25df7fdf7a6754a3e3061a6a5e1fbd66fd9929b330877cb89e04939a4136",
  timber: "2c4dda26823c06c313a298d9b66a120cd2d0613a2e676e5c4b9784fa014b5c51",
  fibre: "8714db06732384d09efb1a7c026f3af0c26d3d7d645e24009ece94d06518078e",
  pulp: "b590044e7a56f0e3722cba7d2beea1a9cb98f7a3d4d46ed6cd4c8b27c4f41aab",
  toxin: "373e41191f5e04b9c409deacb246e3bef319dc7ed16476c60aaea199c4c9368c",
  reagent: "15662477bdb4f538e40424ea6fd3322732832ea4b4c68200c46d06a33046de8e",
});

const sha = bytes => crypto.createHash("sha256").update(bytes).digest("hex");
const canonical = value => Array.isArray(value)
  ? `[${value.map(canonical).join(",")}]`
  : value && typeof value === "object"
    ? `{${Object.keys(value).sort().map(key => `${JSON.stringify(key)}:${canonical(value[key])}`).join(",")}}`
    : JSON.stringify(value);
const ensure = file => fs.mkdirSync(path.dirname(file), { recursive: true });
const write = (file, bytes) => {
  if (check) {
    if (!fs.existsSync(file) || !fs.readFileSync(file).equals(bytes)) {
      throw new Error(`deterministic drift: ${path.relative(repo, file)}`);
    }
  } else {
    ensure(file);
    fs.writeFileSync(file, bytes);
  }
};
const record = (base, file, bytes, extra = {}) => ({
  file: path.relative(base, file), sha256: sha(bytes), bytes: bytes.length, ...extra,
});
const writeBytes = (base, relative, bytes, extra = {}) => {
  const file = path.join(base, relative);
  write(file, bytes);
  return record(base, file, bytes, extra);
};
const writeCanvas = (base, relative, canvas, extra = {}) =>
  writeBytes(base, relative, canvas.toBuffer("image/png"), {
    width: canvas.width, height: canvas.height, ...extra,
  });
const rect = (context, color, x, y, width, height, alpha = 1) => {
  context.globalAlpha = alpha;
  context.fillStyle = color;
  context.fillRect(x, y, width, height);
  context.globalAlpha = 1;
};
const label = (context, value, x, y, size, color, weight = 600, align = "left") => {
  context.fillStyle = color;
  context.font = `${weight} ${size}px system-ui`;
  context.textAlign = align;
  context.fillText(value, x, y);
  context.textAlign = "left";
};
const render = commands => {
  const canvas = createCanvas(MATERIAL_SIZE.width, MATERIAL_SIZE.height);
  const context = canvas.getContext("2d");
  context.imageSmoothingEnabled = false;
  for (const command of commands) {
    rect(context, command.color, command.x, command.y, command.w, command.h, command.alpha);
  }
  return canvas;
};
const grayscale = sourceCanvas => {
  const output = createCanvas(sourceCanvas.width, sourceCanvas.height);
  const context = output.getContext("2d");
  context.drawImage(sourceCanvas, 0, 0);
  const image = context.getImageData(0, 0, output.width, output.height);
  for (let index = 0; index < image.data.length; index += 4) {
    const value = Math.round(image.data[index] * .2126
      + image.data[index + 1] * .7152 + image.data[index + 2] * .0722);
    image.data[index] = image.data[index + 1] = image.data[index + 2] = value;
  }
  context.putImageData(image, 0, 0);
  return output;
};

const sourceRecords = {};
for (const id of REFINED_FAMILIES) {
  const commands = refinedMaterialCommands(id);
  const canvas = render(commands);
  const bytes = canvas.toBuffer("image/png");
  if (sha(bytes) !== expectedSourceHashes[id]) throw new Error(`source byte drift: ${id}`);
  const file = path.join(source, `${id}.png`);
  write(file, bytes);
  sourceRecords[id] = {
    file: path.relative(repo, file),
    sha256: sha(bytes),
    decodedRGBASHA256: sha(Buffer.from(canvas.getContext("2d").getImageData(0, 0, 32, 32).data)),
    commandSHA256: sha(Buffer.from(canonical(commands))),
    silhouetteSHA256: sha(Buffer.from(silhouetteKey(commands))),
    width: 32,
    height: 32,
  };
}
if (sourceOnly) {
  console.log(JSON.stringify({ sourceCheckpoint, sourceRecords }, null, 2));
  process.exit(0);
}

const packManifestFile = path.join(pack, "manifest.json");
const packManifestBytes = fs.readFileSync(packManifestFile);
const packManifest = JSON.parse(packManifestBytes);
const rows = Object.fromEntries(packManifest.profiles.mobDropInventory.sprites.map(row => [row.id, row]));
if (Object.keys(rows).length !== 23) throw new Error("shared pack must contain all 23 material families");
for (const [id, expected] of Object.entries({ ...preservedHashes, ...expectedSourceHashes })) {
  if (rows[id]?.sha256 !== expected) throw new Error(`shared pack hash mismatch: ${id}`);
}

const images = {};
for (const id of Object.keys(rows)) images[id] = await loadImage(path.join(pack, "mob-drops", rows[id].file));
const backgrounds = Object.freeze({
  light: { page: "#ead29d", surface: "#daba78", edge: "#4d382b", text: "#241d18", muted: "#796b5e" },
  dark: { page: "#17171a", surface: "#28272b", edge: "#7a6658", text: "#f0e5d3", muted: "#b7aa9e" },
});
function contactSheet(theme, literalGrayscale = false) {
  const palette = backgrounds[theme];
  const canvas = createCanvas(368, 800);
  const context = canvas.getContext("2d");
  context.imageSmoothingEnabled = false;
  rect(context, palette.page, 0, 0, 368, 800);
  label(context, "WORLD MATERIAL PIXEL CORRECTION", 16, 28, 13, palette.text, 800);
  label(context, "Seven exact identities · native 16px carried slot", 16, 49, 10, palette.muted);
  rect(context, palette.surface, 12, 70, 344, 58);
  context.strokeStyle = palette.edge; context.lineWidth = 2; context.strokeRect(12, 70, 344, 58);
  REFINED_FAMILIES.forEach((id, index) => {
    const image = images[id];
    const x = 22 + index * 47;
    context.drawImage(image, x, 82, 16, 16);
    label(context, "1", x + 19, 96, 10, palette.text, 600);
    label(context, id, x + 8, 116, 7, palette.text, 600, "center");
  });
  label(context, "AUTHORING PIXELS · 32×32 TRANSPARENT", 16, 164, 10, palette.muted, 700);
  REFINED_FAMILIES.forEach((id, index) => {
    const column = index % 4, row = Math.floor(index / 4);
    const x = 18 + column * 88, y = 186 + row * 116;
    for (let py = 0; py < 64; py += 8) for (let px = 0; px < 64; px += 8) {
      rect(context, ((px + py) / 8) % 2 ? "#c7c3ba" : "#eee9df", x + px, y + py, 8, 8);
    }
    context.drawImage(images[id], x, y, 64, 64);
    label(context, id, x + 32, y + 82, 9, palette.text, 700, "center");
    label(context, rows[id].sha256.slice(0, 8), x + 32, y + 99, 7, palette.muted, 500, "center");
  });
  label(context, "COLLISION CHECK · DISTINCT WITHOUT LABELS", 16, 438, 10, palette.muted, 700);
  const groups = [["feather", "quill", "down"], ["scale", "plate", "chitin", "shell"],
    ["oil", "venom", "ichor"], ["horn", "tusk", "bone"]];
  groups.forEach((group, groupIndex) => {
    const y = 466 + groupIndex * 70;
    label(context, `${groupIndex + 1}`, 18, y + 25, 9, palette.muted, 700);
    group.forEach((id, index) => context.drawImage(images[id], 42 + index * 65, y, 48, 48));
  });
  label(context, literalGrayscale ? "LITERAL GRAYSCALE" : `${theme.toUpperCase()} COMPOSITION`,
    352, 784, 8, palette.muted, 700, "right");
  return literalGrayscale ? grayscale(canvas) : canvas;
}

const evidence = {
  light: writeCanvas(artifact, "world-carried-materials-light-368x800.png", contactSheet("light")),
  dark: writeCanvas(artifact, "world-carried-materials-dark-368x800.png", contactSheet("dark")),
  grayscale: writeCanvas(artifact, "world-carried-materials-grayscale-368x800.png",
    contactSheet("light", true), { literalGrayscale: true }),
};
const manifest = {
  schema: "bookbinder.world-material-pixel-correction-v1.manifest",
  status: "corrected-candidate-not-Aimee-approved",
  integrationReady: false,
  provenance: {
    parentCommit,
    sourceCheckpoint,
    sourceTree,
    sourceCandidateCanonicalBodySHA256: "b5dd9a6ce521f75c960cd7ede852ea71d08a9b6aa1639fd358a6c215c616b454",
    sharedPack: {
      file: path.relative(repo, packManifestFile),
      sha256: sha(packManifestBytes),
      canonicalBodySHA256: packManifest.canonicalBodySHA256,
    },
  },
  families: [...REFINED_FAMILIES],
  sourceRecords,
  preservedExistingMaterialHashes: preservedHashes,
  evidence,
  runtime: {
    resolver: "CraftMaterialUnitPixelIdentity -> MobGearSpriteV1Registry",
    authoredSize: [32, 32],
    worldCarriedSlot: [16, 16],
    interpolation: "nearest-neighbour",
    exactPixelCoverageCount: 23,
    sfSymbolFallbackCountForMaterialFamilyID: 0,
  },
  boundary: {
    changedMaterialFamilies: 7,
    preservedMaterialFamilies: 16,
    WorldHeaderChanged: false,
    SeamwardLayoutChanged: false,
    SurveyPostChanged: false,
    simulatorUsed: false,
  },
};
manifest.canonicalBodySHA256 = sha(Buffer.from(canonical(manifest)));
const manifestBytes = Buffer.from(`${JSON.stringify(manifest, null, 2)}\n`);
write(path.join(receiptRoot, "manifest.json"), manifestBytes);
const receipt = {
  schema: "bookbinder.world-material-pixel-correction-v1.deterministic-receipt",
  status: manifest.status,
  integrationReady: false,
  manifestSHA256: sha(manifestBytes),
  canonicalBodySHA256: manifest.canonicalBodySHA256,
  sourceAggregateSHA256: sha(Buffer.from(REFINED_FAMILIES.map(id => `${id}:${sourceRecords[id].sha256}`).join("\n"))),
  evidenceAggregateSHA256: sha(Buffer.from(Object.values(evidence).map(row => `${row.file}:${row.sha256}`).join("\n"))),
  check: "NODE_PATH=<workspace AssetLab/node_modules> node AssetLab/scripts/export-world-material-pixel-correction-v1.mjs --check",
};
write(path.join(receiptRoot, "deterministic-receipt.json"), Buffer.from(`${JSON.stringify(receipt, null, 2)}\n`));
console.log(JSON.stringify({ manifestSHA256: sha(manifestBytes), ...receipt }, null, 2));
