import { createRequire } from "node:module";
import { createHash } from "node:crypto";
import { mkdir, writeFile } from "node:fs/promises";
import {
  defaults, normalizeDescriptor, presets, creatureCommands, renderCommands, hash
} from "../src/generator.js";

const { createCanvas } = createRequire(import.meta.url)("@napi-rs/canvas");
const fixtures = [
  ["fennec-like", "Dune long-ear"],
  ["winged-serpent", "Membrane sky serpent"]
].map(([id, preset]) => {
  const descriptor = normalizeDescriptor({...defaults, logicalID: id, traits: presets[preset]});
  return {
    id, descriptor,
    worldCommands: creatureCommands(descriptor, "world"),
    fightCommands: creatureCommands(descriptor, "fight")
  };
});

const canvas = createCanvas(720, 360);
const context = canvas.getContext("2d");
context.imageSmoothingEnabled = false;
context.fillStyle = "#171614";
context.fillRect(0, 0, canvas.width, canvas.height);

function label(value, x, y, size = 18, color = "#eee8dc") {
  context.fillStyle = color;
  context.font = `bold ${size}px system-ui`;
  context.fillText(value, x, y);
}

function renderProfile(commands, size, scale, x, y) {
  const scratch = createCanvas(size, size);
  renderCommands(scratch.getContext("2d"), size, size, commands);
  context.fillStyle = "#25231f";
  context.fillRect(x - 4, y - 4, size * scale + 8, size * scale + 8);
  context.drawImage(scratch, x, y, size * scale, size * scale);
}

label("CREATURE VISUAL-DIVERSITY FOUNDATION · SCHEMA 5", 24, 32, 20, "#d6be7c");
label("Body plan, cranial feature and appendage type are independent visual-only axes", 24, 56, 13, "#aaa397");
for (const [index, fixture] of fixtures.entries()) {
  const x = 24 + index * 352;
  const traits = fixture.descriptor.traits;
  label(fixture.id, x, 92, 20);
  label(`${traits.bodyPlan} · ${traits.cranialFeature} · ${traits.appendageCount} ${traits.appendageType}`, x, 114, 12, "#c7bdab");
  renderProfile(fixture.worldCommands, 16, 7, x, 140);
  renderProfile(fixture.fightCommands, 48, 3, x + 160, 124);
  label("world · 16px", x, 278, 12, "#aaa397");
  label("encounter · 48px", x + 160, 278, 12, "#aaa397");
}
label("Placeholder geometry only · no flight, reach, sense or combat rule is inferred", 24, 332, 13, "#d6be7c");

const png = canvas.toBuffer("image/png");
const report = {
  evidenceRole: "assetlabVisualOnlyCreatureDiversityFoundation",
  integrationReady: false,
  schemaVersion: 5,
  fixtureCount: fixtures.length,
  constraints: [
    "visual-only morphology",
    "body plan independent from appendage type",
    "cranial feature does not imply a sensor mechanic",
    "flight, reach and combat behavior are not inferred"
  ],
  fixtures: fixtures.map((fixture) => ({
    id: fixture.id,
    bodyPlan: fixture.descriptor.traits.bodyPlan,
    cranialFeature: fixture.descriptor.traits.cranialFeature,
    appendageCount: fixture.descriptor.traits.appendageCount,
    appendageType: fixture.descriptor.traits.appendageType,
    worldCommandHash: hash(fixture.worldCommands),
    fightCommandHash: hash(fixture.fightCommands)
  })),
  artifact: {
    file: "creature-diversity-foundation-v0.1.png",
    pixelWidth: canvas.width,
    pixelHeight: canvas.height,
    sha256: createHash("sha256").update(png).digest("hex")
  }
};

const output = new URL("../artifacts/", import.meta.url);
await mkdir(output, {recursive: true});
await writeFile(new URL(report.artifact.file, output), png);
await writeFile(new URL("creature-diversity-foundation-v0.1.json", output), `${JSON.stringify(report, null, 2)}\n`);
console.log(JSON.stringify(report, null, 2));
