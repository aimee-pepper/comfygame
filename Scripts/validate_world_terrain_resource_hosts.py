#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUTH = ROOT / "docs/world-terrain-resource-host-authority.json"
RESOURCES = ROOT / "Sources/Content/Data/resources.json"

authority = json.loads(AUTH.read_text())
resources = json.loads(RESOURCES.read_text())

expected_grounds = {
    "stone", "soil", "sand", "ice", "ash", "water", "deepWater", "rubble", "mud",
    "growth", "chasm", "groundcover",
}
assert authority["schemaVersion"] == 1
assert set(authority["groundIDs"]) == expected_grounds
assert len(authority["groundIDs"]) == len(expected_grounds)
assert authority["surfaceDepositIDs"] == ["snow", "ash"]
assert authority["surfaceDepositsAreIndependent"] is True
deposits = authority["surfaceDeposits"]
assert [row["id"] for row in deposits] == authority["surfaceDepositIDs"]
assert {row["shapeFamily"] for row in deposits} == {"settledCover"}
assert len({row["palette"] for row in deposits}) == 2
assert all(set(row["eligibleBaseGroundExclusions"]) == {"water", "deepWater", "chasm"} for row in deposits)
composition = authority["surfaceDepositComposition"]
assert composition["order"] == "sourcePageOrder"
assert composition["variantIdentity"] == "depositID+sourceStableID+sourcePageOrder+visualSeed"
assert composition["underlyingGroundRemainsMechanicallyAuthoritative"] is True

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
    "directPickup", "realityPickup",
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
assert next(row for row in host_rows if row["resourceID"] == "mote")["placementKind"] == "realityPickup"
assert next(row for row in host_rows if row["resourceID"] == "essence_raw")["placementKind"] == "directPickup"

topology = authority["terrainTopology"]
assert topology["elevationMinimum"] == 0 and topology["elevationMaximum"] == 3
assert topology["maximumAdjacentElevationDelta"] == 1
assert 0 < topology["surfaceDepositCoverageCeiling"] < 1
assert topology["surfaceDepositCoverageCeiling"] == composition["combinedOpaqueCoverageCeiling"]

print(
    f"World terrain/resource authority: {len(expected_grounds)} grounds, "
    f"{len(authority['surfaceDepositIDs'])} independent deposits, "
    f"{len(host_rows)} exhaustive resource hosts; dispositions {dict(sorted(by_kind.items()))}"
)
