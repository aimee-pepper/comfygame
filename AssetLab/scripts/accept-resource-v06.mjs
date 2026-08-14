import {readFile,writeFile} from "node:fs/promises";
import {resourceCatalogue,resourceWorldCommands} from "../src/resource-kit.js";
import {rasterHash} from "../src/regression.js";

const url=new URL("../fixtures/golden-v1.json",import.meta.url),baseline=JSON.parse(await readFile(url,"utf8"));
for(const resource of resourceCatalogue.filter(item=>!["realityCurrency","wildDrop"].includes(item.acquisitionKind))){const {id}=resource,environment=resource.sourceClass==="unstableSubstrate"?"unstable":"stone";baseline.hashes[`resource/${id}/remaining`]=rasterHash(resourceWorldCommands(id,{environment}),16,16);baseline.hashes[`resource/${id}/exhausted`]=rasterHash(resourceWorldCommands(id,{environment,state:"exhausted"}),16,16);}
baseline.hashes=Object.fromEntries(Object.entries(baseline.hashes).sort(([a],[b])=>a.localeCompare(b)));await writeFile(url,`${JSON.stringify(baseline,null,2)}\n`);console.log("Accepted reviewed Resource v0.6 hashes only.");
