import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
import { schemaVersion, normalizeRegionTileRequest, contourOwner, materialBoundaryMask, smallAccentPoint } from "../src/terrain-region-continuity-v1.js";

const root=path.resolve(import.meta.dirname,".."),out=path.join(root,"artifacts/terrain-region-continuity-v1"),exporter=path.join(root,"scripts/export-terrain-region-continuity-v1.mjs"),hash=b=>crypto.createHash("sha256").update(b).digest("hex");
execFileSync(process.execPath,[exporter],{stdio:"inherit"});const first=new Map(fs.readdirSync(out,{recursive:true}).filter(p=>fs.statSync(path.join(out,p)).isFile()).map(p=>[p,hash(fs.readFileSync(path.join(out,p)))]));execFileSync(process.execPath,[exporter],{stdio:"inherit"});for(const [p,h] of first)assert.equal(hash(fs.readFileSync(path.join(out,p))),h,p);
const req=(ground="stone",neighbor="soil",visibility="full")=>normalizeRegionTileRequest({schemaVersion,ground,point:{x:4,y:7},visualSeed:9,featureVariant:0,cardinalNeighbors:{north:neighbor,east:"same",south:"same",west:"unknown"},edgeContourIDs:{north:2,east:1,south:0,west:3},visibility,motionPhase:0});
assert.equal(contourOwner("stone","soil"),true);assert.equal(contourOwner("soil","stone"),false);assert.equal(contourOwner("stone","same"),false);assert.ok(materialBoundaryMask(req()).some(Boolean));assert.ok(!materialBoundaryMask(req("stone","stone")).some(Boolean));assert.ok(!materialBoundaryMask(req("stone","soil","fringe")).some(Boolean));assert.ok(!materialBoundaryMask(req("stone","soil","remembered")).some(Boolean));
assert.deepEqual(smallAccentPoint({x:5,y:8},11),smallAccentPoint({x:5,y:8},11));for(const p of [{x:0,y:0},{x:99,y:-12}]){const a=smallAccentPoint(p,44);assert.ok(a.x>=3&&a.x<=12&&a.y>=3&&a.y<=12)}
for(const mutate of [r=>({...r,extra:1}),r=>({...r,visibility:"hidden"}),r=>({...r,cardinalNeighbors:{...r.cardinalNeighbors,north:"fog"}})])assert.throws(()=>normalizeRegionTileRequest(mutate(structuredClone(req()))));
const manifest=JSON.parse(fs.readFileSync(path.join(out,"manifest.json")));assert.equal(manifest.integrationReady,false);assert.equal(manifest.status,"candidate-not-approved");assert.equal(manifest.acceptedPins.terrainProductionPackBody,"ecb748ba46582bd432e7eba7cfc5494fd8ea8badcf3a8652d24c7a533d8e8336");assert.equal(manifest.acceptedPins.southWallCommit,"ae12dd5f");assert.equal(manifest.corpus.caseCount,121);assert.equal(manifest.contract.sameMaterial,"no seam/no boundary");
const accepted=JSON.parse(fs.readFileSync(path.join(root,"artifacts/dynamic-terrain-style-v0.2/manifest.json")));assert.equal(manifest.acceptedPins.productionAggregateSHA256,accepted.productionAggregateSha256);
const corpus=JSON.parse(fs.readFileSync(path.join(out,"native-adapter-conformance.json")));assert.equal(corpus.cases.length,121);assert.equal(new Set(corpus.cases.map(c=>c.id)).size,121);assert.ok(corpus.cases.every(c=>c.accent.x>=3&&c.accent.x<=12&&c.accent.y>=3&&c.accent.y<=12));assert.ok(corpus.cases.some(c=>c.materialBoundarySHA256!==hash(Buffer.alloc(256))));
for(const n of ["phone-old-current-corrected-368x800.png","phone-visibility-368x800.png","equal-height-vs-south-wall-400pct.png","macro-11x11-redraw-a-2x.png","macro-11x11-redraw-b-2x.png"])assert.ok(manifest.outputs.some(x=>x.name===`evidence/${n}`),n);
assert.equal(first.get("evidence/macro-11x11-redraw-a-2x.png"),first.get("evidence/macro-11x11-redraw-b-2x.png"));
console.log("terrain region continuity v1 passed");
