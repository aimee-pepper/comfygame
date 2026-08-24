import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

const root=path.resolve(import.meta.dirname,".."),sha=file=>crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
const receipt=JSON.parse(fs.readFileSync(path.join(root,"integration/resource-mining-feedback-v1/promotion-receipt.json"),"utf8"));
assert.equal(receipt.status,"asset-approved-for-native-integration");assert.equal(receipt.integrationReady,true);assert.equal(receipt.scope,"resource-mining-feedback-only");assert.equal(receipt.approvals.gameDesignFunctional,"approved");assert.equal(receipt.approvals.assetVisual,"approved");
const pins=receipt.candidatePins,paths={manifestFileSHA256:"artifacts/resource-mining-feedback-v1/manifest.json",contactSheetSHA256:"artifacts/resource-mining-feedback-v1/review-contact-sheet.png",routeSHA256:"resource-mining-feedback-v1.html",styleSHA256:"resource-mining-feedback-v1.css",liveRouteSHA256:"resource-mining-feedback-v1-live.js",contractSHA256:"src/resource-mining-feedback-v1.js",exporterSHA256:"scripts/export-resource-mining-feedback-v1.mjs",focusedTestSHA256:"tests/resource-mining-feedback-v1.test.js"};
for(const [pin,file] of Object.entries(paths))assert.equal(sha(path.join(root,file)),pins[pin],file);
const manifest=JSON.parse(fs.readFileSync(path.join(root,paths.manifestFileSHA256),"utf8"));assert.equal(manifest.canonicalBodySHA256,pins.canonicalBodySHA256);assert.equal(manifest.sourceIdentityPack.fieldAssets?Object.keys(manifest.sourceIdentityPack.fieldAssets).length:0,23);assert.deepEqual(receipt.nativeConsumption.sourceLogicalSize,[8,8]);assert.equal(receipt.nativeConsumption.filtering,"nearest-neighbor");assert.equal(receipt.nativeConsumption.motion.durationMS,760);assert.equal(receipt.nativeConsumption.motion.orderedSubjectStaggerMS,130);assert.deepEqual(receipt.nativeConsumption.motion.scale,[2,1]);assert.match(receipt.nativeConsumption.dismissOrExpiry,/advance exactly one/);assert.match(receipt.nativeConsumption.worldOwnerExit,/clears current and queued presentation only/);assert.match(receipt.nativeConsumption.playerCopy,/Use Tile/);assert.ok(receipt.excluded.includes("traveller-bubble"));assert.ok(receipt.excluded.includes("world-splash-parallax"));
console.log("resource mining feedback promotion v1 passed");
