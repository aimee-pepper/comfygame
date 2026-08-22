#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUTH = ROOT / "docs/world-terrain-resource-host-authority.json"
RESOURCES = ROOT / "Sources/Content/Data/resources.json"
TERRAIN_MANIFEST = ROOT / "AssetLab/integration/terrain-production-pack-v1/runtime/manifest.json"
NATIVE_PACK = ROOT / "Sources/VisualRuntime/TerrainProductionPack.swift"
WORLDGEN = ROOT / "Sources/Rules/Worldgen.swift"

authority = json.loads(AUTH.read_text())
resources = json.loads(RESOURCES.read_text())
terrain_manifest = json.loads(TERRAIN_MANIFEST.read_text())
native_pack_source = NATIVE_PACK.read_text()
worldgen_source = WORLDGEN.read_text()

expected_grounds = {
    "stone", "soil", "sand", "ice", "ash", "water", "deepWater", "rubble", "mud",
    "growth", "chasm", "groundcover",
}
assert authority["schemaVersion"] == 1
assert set(authority["groundIDs"]) == expected_grounds
assert len(authority["groundIDs"]) == len(expected_grounds)
assert authority["surfaceDepositIDs"] == ["snow", "settledAsh"]
assert authority["surfaceDepositsAreIndependent"] is True
deposits = authority["surfaceDeposits"]
assert [row["id"] for row in deposits] == authority["surfaceDepositIDs"]
assert {row["shapeFamily"] for row in deposits} == {"settledCover"}
assert len({row["palette"] for row in deposits}) == 2
assert all(set(row["eligibleBaseGroundExclusions"]) == {"water", "deepWater", "chasm"} for row in deposits)
composition = authority["surfaceDepositComposition"]
assert composition["order"] == ["snow", "settledAsh"]
assert composition["variantIdentity"] == "worldVisualSeed+tileCoordinate+depositID+phase"
assert composition["persistedShape"] == {"snow": "boolean", "settledAsh": "boolean"}
assert composition["coveragePerResolvedAmplitude"] == 0.12
assert composition["underlyingGroundRemainsMechanicallyAuthoritative"] is True

# The rules authority, accepted terrain-layers-v2 runtime ABI and native request
# adapter must use one exact pair of field names. `ash` remains the authored
# source Stable ID and base GroundType; it is never the settled deposit ABI ID.
runtime_deposits = terrain_manifest["runtimeContract"]["surfaceDeposits"]
assert terrain_manifest["runtimeContract"]["requestSchemaVersion"] == "terrain-layers-v2"
assert runtime_deposits["keys"] == authority["surfaceDepositIDs"]
assert runtime_deposits["order"] == authority["surfaceDepositIDs"]
assert "var snow: Bool" in native_pack_source
assert "var settledAsh: Bool" in native_pack_source
assert 'exactKeys(deposits, ["snow", "settledAsh"])' in native_pack_source
assert 'deposits["ash"]' not in native_pack_source

catalogue_ids = {entry["id"] for entry in resources["resources"]}
host_rows = authority["resourceHosts"]
host_ids = [entry["resourceID"] for entry in host_rows]
assert len(host_ids) == len(set(host_ids)), "duplicate resource host row"
assert set(host_ids) == catalogue_ids, (
    f"resource host coverage mismatch missing={sorted(catalogue_ids - set(host_ids))} "
    f"extra={sorted(set(host_ids) - catalogue_ids)}"
)

valid_kinds = {
    "mineralNode", "floraPrimary", "floraSecondary", "creatureMaterialOnly",
    "directPickup", "realityAwardOnly",
}
for row in host_rows:
    assert row["placementKind"] in valid_kinds, row
    for clause in row.get("clauses", []):
        base = clause.get("baseGroundIDs", [])
        adjacent = clause.get("adjacentAnyGroundIDs", [])
        assert base and set(base) <= expected_grounds, row
        assert set(adjacent) <= expected_grounds, row
        minimum = clause.get("minimumElevation", 0)
        maximum = clause.get("maximumElevation", 3)
        assert 0 <= minimum <= maximum <= 3, row

by_kind = {}
for row in host_rows:
    by_kind[row["placementKind"]] = by_kind.get(row["placementKind"], 0) + 1

assert next(row for row in host_rows if row["resourceID"] == "resin")["placementKind"] == "floraSecondary"
assert next(row for row in host_rows if row["resourceID"] == "ichor")["excludedFromOrdinaryWorldYieldTable"] is True
assert next(row for row in host_rows if row["resourceID"] == "mote") == {
    "resourceID": "mote", "placementKind": "realityAwardOnly",
    "hostRule": "existingCacheAndMythicAwards",
}
assert next(row for row in host_rows if row["resourceID"] == "essence_raw")["placementKind"] == "directPickup"
assert next(row for row in host_rows if row["resourceID"] == "essence_raw")["hostRule"] == \
    "reachablePassableTerrainPrePlacement"

assert "abundance * Double(candidates[index].hosts.count)" in worldgen_source
assert "let tile = map[point]" in worldgen_source
assert "let base = tile.baseGround" in worldgen_source
assert "switch resource.rawValue" in worldgen_source
adapter = worldgen_source.split("static func resourceHostAllows", 1)[1].split(
    "static func travellerCausalityReadings", 1)[0]
covered_ids = set(re.findall(r'"([a-z0-9_]+)"', "\n".join(
    line for line in adapter.splitlines() if line.lstrip().startswith("case ")
)))
mineral_ids = {row["resourceID"] for row in host_rows if row["placementKind"] == "mineralNode"}
assert mineral_ids <= covered_ids, f"Swift host adapter omits {sorted(mineral_ids - covered_ids)}"
assert "baseIs(.soil) && low && touches(.water, .deepWater, .mud)" in adapter
assert "tile.elevation >= 2 || touches(.chasm)" in adapter
assert "touches(.chasm)" in adapter and "touches(.ash, .chasm)" in adapter

topology = authority["terrainTopology"]
assert topology["elevationMinimum"] == 0 and topology["elevationMaximum"] == 3
assert topology["maximumAdjacentElevationDelta"] == 1
assert topology["entryComponent"] == "largestPassableCardinalComponent"
assert topology["entryPreference"] == "largestComponentDryEdgeThenShallowEdgeElseDryNearestBoundaryThenShallowNearestBoundary"
assert topology["standingBodiesRemainCardinallySeparate"] is True
assert topology["flowingFailurePolicy"] == "failBeforePlacementAndSpendNeverRepaintAsStanding"
assert topology["minimumReachablePassableFraction"] == 0.85
assert topology["reachabilityRepairComponentOrder"] == "largestStrandedFirst"
assert topology["reachabilityRepairRouteOrder"] == [
    "minimumBlockingTiles", "minimumPathLength", "stableCoordinate"]
assert topology["deepWaterRepair"] == "softenOnlyChosenRouteToWater"
assert topology["chasmRepair"] == "fillOnlyChosenRouteWithStone"
assert topology["failurePolicy"] == "failBeforePlacementAndSpend"
assert topology["repairDiagnostics"] == [
    "reachableFraction", "softenedDeepWaterTiles", "filledChasmTiles"]
assert 0 < topology["surfaceDepositCoverageCeiling"] < 1
assert topology["surfaceDepositCoverageCeiling"] == composition["combinedOpaqueCoverageCeiling"]

print(
    f"World terrain/resource authority: {len(expected_grounds)} grounds, "
    f"{len(authority['surfaceDepositIDs'])} independent deposits, "
    f"{len(host_rows)} exhaustive resource hosts; dispositions {dict(sorted(by_kind.items()))}"
)
