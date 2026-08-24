import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const auditPath = join(root, "AssetLab/integration/player-visible-identity-native-audit-v1/receipt.json");
const audit = JSON.parse(await readFile(auditPath));
const sha = bytes => createHash("sha256").update(bytes).digest("hex");
const bytesAt = path => readFile(join(root, path));

assert.equal(audit.schemaVersion, "player-visible-identity-native-audit-v1");
assert.equal(audit.status, "audit-and-native-handoff-only");
assert.equal(audit.nativeCodeModified, false);
assert.equal(audit.priority, "return-recap-first");

for (const pin of [...Object.values(audit.sourcePins), ...Object.values(audit.authorityPins)]) {
  assert.equal(sha(await bytesAt(pin.path)), pin.sha256, pin.path);
}

const resources = JSON.parse(await bytesAt(audit.authorityPins.resourceSprites.path));
const mobGear = JSON.parse(await bytesAt(audit.authorityPins.mobGear.path));
const gearMap = JSON.parse(await bytesAt(audit.authorityPins.gearMap.path));
const objects = JSON.parse(await bytesAt(audit.authorityPins.catalogueObjectMap.path));
const essence = JSON.parse(await bytesAt(audit.authorityPins.looseRawEssence.path));

assert.equal(resources.resources.length, 23);
assert.equal(mobGear.coverage.mobMaterialKinds.length, 16);
assert.equal(mobGear.coverage.gearFamilies.length, 24);
assert.equal(gearMap.coverage.acceptedCatalogueIDs, 75);
assert.equal(objects.coverage.catalogueIDs, 27);
assert.equal(essence.integrationReady, true);

const returnRecap = await bytesAt(audit.sourcePins.returnRecap.path).then(String);
const itemGrid = await bytesAt(audit.sourcePins.sharedItemTile.path).then(String);
const resolver = await bytesAt(audit.sourcePins.sharedCatalogueAndMaterialResolver.path).then(String);
const materialBranch = returnRecap.match(/case \.materialSample\(let material\):([\s\S]*?)case \.legacy/);
assert.ok(materialBranch, "Return Recap material branch must remain inspectable");
assert.match(materialBranch[1], /ItemIconTile/);
assert.doesNotMatch(materialBranch[1], /materialKind\s*:/, "R1 remains an integration seam on this native baseline");
assert.match(itemGrid, /if let materialKind/);
assert.match(itemGrid, /MaterialSamplePixelIdentity\(kind: materialKind/);
assert.match(resolver, /MobGearSpriteV1Registry\.mobDropAsset\(for: kind\)/);

const recapFamilies = Object.fromEntries(audit.returnRecap.map(row => [row.family, row]));
assert.equal(recapFamilies["resource-receipts"].classification, "already-integrated");
assert.equal(recapFamilies["gear-receipts"].classification, "already-integrated");
assert.equal(recapFamilies["material-sample-receipts"].classification, "A");
assert.equal(recapFamilies["catalogue-object-receipts"].classification, "B");
assert.equal(recapFamilies["page-and-writing-receipts"].classification, "B");
assert.equal(recapFamilies["legacy-receipts"].classification, "C");
assert.equal(audit.smallestBatches[0].id, "R1");
assert.equal(audit.smallestBatches[0].newArt, false);
assert.ok(audit.blocked.includes("spendable Essence"));
assert.ok(audit.blocked.includes("named travellers"));

console.log("player-visible-identity-native-audit-v1 PASS · Return Recap R1 closes 16 identities with existing art");
