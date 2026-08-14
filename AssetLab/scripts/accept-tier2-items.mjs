import {readFile,writeFile} from "node:fs/promises";
import {tier2CatalogueItemIDs,tier2CatalogueItemIconCommands} from "../src/item-kit.js";
import {rasterHash} from "../src/regression.js";

const url=new URL("../fixtures/golden-v1.json",import.meta.url),baseline=JSON.parse(await readFile(url,"utf8"));
for(const id of tier2CatalogueItemIDs)baseline.hashes[`item/${id}/inventory`]=rasterHash(tier2CatalogueItemIconCommands(id),32,32);
baseline.hashes=Object.fromEntries(Object.entries(baseline.hashes).sort(([a],[b])=>a.localeCompare(b)));
await writeFile(url,`${JSON.stringify(baseline,null,2)}\n`);
console.log(`Accepted ${tier2CatalogueItemIDs.length} directly reviewed tier-2 item hashes only.`);
