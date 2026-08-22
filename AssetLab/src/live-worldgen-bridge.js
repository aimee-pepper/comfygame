import { copyFile, mkdir, readdir, rename, stat, unlink } from "node:fs/promises";
import { spawn } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const assetRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const repoRoot = dirname(assetRoot);
const cacheRoot = join(assetRoot, ".cache", "world-generator");
const executable = join(cacheRoot, "bookbinder-worldgen-bridge");

const requiredRules = [
  "Worldgen", "BookRules", "PressureRules", "TerrainRules", "FloraRules", "LifeRules",
  "SiteRules", "ContradictionRules", "LibraryRules", "ApexRules", "WorldConstraints",
  "ConsumableCraftingRules", "SmithRules", "CharacterRules", "ButcheryRules", "PageRules",
  "WorldGrade2BindAdapter", "DescriptionRules"
];

async function swiftFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(entries.map(async entry => {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) return swiftFiles(path);
    return entry.isFile() && entry.name.endsWith(".swift") ? [path] : [];
  }));
  return nested.flat();
}

export async function bridgeSources() {
  const shared = (await Promise.all(["Core", "Content", "Model"].map(name =>
    swiftFiles(join(repoRoot, "Sources", name))))).flat();
  const rules = requiredRules.map(name => join(repoRoot, "Sources", "Rules", `${name}.swift`));
  return [
    join(repoRoot, "Sources", "Tuning.swift"),
    join(repoRoot, "Sources", "VisualRuntime", "WorldGrade2V1.swift"),
    ...shared, ...rules,
    join(repoRoot, "Tools", "WorldGeneratorBridge", "DebugTuningProfile.swift"),
    join(repoRoot, "Tools", "WorldGeneratorBridge", "main.swift")
  ];
}

function run(command, args, { input } = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { cwd: repoRoot, stdio: ["pipe", "pipe", "pipe"] });
    const stdout = [], stderr = [];
    let outputSize = 0;
    child.stdout.on("data", chunk => {
      outputSize += chunk.length;
      if (outputSize > 20_000_000) child.kill("SIGKILL");
      else stdout.push(chunk);
    });
    child.stderr.on("data", chunk => stderr.push(chunk));
    child.on("error", reject);
    child.on("close", code => {
      if (code === 0) resolve(Buffer.concat(stdout));
      else reject(new Error(Buffer.concat(stderr).toString() || `${command} exited ${code}`));
    });
    child.stdin.end(input);
  });
}

let activeBuild;
export async function ensureWorldgenBridge() {
  if (activeBuild) return activeBuild;
  activeBuild = (async () => {
    await mkdir(cacheRoot, { recursive: true });
    const sources = await bridgeSources();
    const binaryTime = await stat(executable).then(value => value.mtimeMs).catch(() => 0);
    const sourceTimes = await Promise.all(sources.map(path => stat(path).then(value => value.mtimeMs)));
    if (!binaryTime || sourceTimes.some(time => time > binaryTime)) {
      await run("xcrun", ["swiftc", "-module-cache-path", join(cacheRoot, "module-cache"),
        "-Onone", "-DWORLD_GENERATOR_BRIDGE", "-o", executable, ...sources]);
    }
    const contentRoot = join(repoRoot, "Sources", "Content", "Data");
    for (const name of await readdir(contentRoot)) {
      if (!name.endsWith(".json")) continue;
      const destination = join(cacheRoot, name);
      const temporary = join(cacheRoot,
        `.${name}.${process.pid}.${Date.now()}.${Math.random().toString(16).slice(2)}.tmp`);
      try {
        await copyFile(join(contentRoot, name), temporary);
        await rename(temporary, destination);
      } catch (error) {
        await unlink(temporary).catch(() => {});
        throw error;
      }
    }
    return executable;
  })();
  try { return await activeBuild; }
  finally { activeBuild = undefined; }
}

export async function generateLiveWorld(request) {
  const bridge = await ensureWorldgenBridge();
  const bytes = await run(bridge, [], { input: Buffer.from(JSON.stringify(request)) });
  return JSON.parse(bytes.toString());
}

export async function liveSymbolCatalogue() {
  const data = JSON.parse(await import("node:fs/promises").then(fs =>
    fs.readFile(join(repoRoot, "Sources", "Content", "Data", "symbols.json"), "utf8")));
  return data.symbols.map(symbol => ({ id: symbol.id, name: symbol.name,
    category: symbol.category ?? symbol.kind ?? "Sigil" }));
}
