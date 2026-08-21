#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ITEMS = ROOT / "Sources/Content/Data/items.json"
AUTHORITY = ROOT / "docs/gear-catalogue-disposition-authority.json"

items = json.loads(ITEMS.read_text())["items"]
authority = json.loads(AUTHORITY.read_text())
gear = {item["id"]: item for item in items if item.get("kind") == "gear"}

ordinary = [item_id for line in authority["ordinaryFoundLines"] for item_id in line]
apex = authority["wildApexOnly"]
component = [entry["id"] for entry in authority["componentAuthoredFound"]]
retired = [entry["id"] for entry in authority["retiredFromNewAcquisition"]]
classified = ordinary + apex + component + retired

assert len(gear) == 75, f"expected 75 live Gear IDs, found {len(gear)}"
assert len(classified) == len(set(classified)), "a Gear ID appears in more than one disposition"
assert set(classified) == set(gear), (
    f"catalogue mismatch: missing={sorted(set(gear) - set(classified))}, "
    f"unknown={sorted(set(classified) - set(gear))}"
)
assert len(ordinary) == 44
assert len(apex) == 8
assert len(component) == 12
assert len(retired) == 11

bands = {"rough", "standard", "fine", "superior", "exceptional", "peerless"}
schematics = {
    "pointed_blade", "cutting_blade", "hand_maul", "long_spear", "shield", "helm",
    "rigid_guard", "field_pick", "supple_coat", "working_gloves", "working_boots",
    "armoury_rigid_shell", "armoury_insulated_layer", "armoury_balanced_laminate",
    "longbow", "sling", "throwing_set", "weaponsmith_fitted_point",
    "weaponsmith_fitted_edge", "weaponsmith_fitted_maul", "weaponsmith_fitted_polearm"
}
for entry in authority["componentAuthoredFound"]:
    assert entry["qualityBand"] in bands
    assert entry["components"], f"{entry['id']} has no frozen component/fixed receipt"
    if entry["receiptMode"] == "schematic":
        assert entry["schematicID"] in schematics, f"unknown schematic for {entry['id']}"
    else:
        assert entry["receiptMode"] in {"fixed-found", "fixed-special"}
        assert entry.get("fixedIdentity"), f"{entry['id']} needs a fixed identity"
    for part in entry["components"]:
        assert part["band"] in bands
        assert part["family"].startswith(("world.", "creature."))

assert all(gear[item_id].get("tradingPostDisposition") == "sellable" for item_id in ordinary)
assert all(gear[item_id].get("tradingPostDisposition") == "protected" for item_id in apex)
assert authority["qualityMigration"] == {
    "legacyTier1": "standard",
    "legacyTier2": "fine",
    "legacyTier3": "superior",
    "legacyTier4": "exceptional",
    "roughMigratedGearIsInvented": False,
    "peerlessMigratedGearIsInvented": False,
    "preserveExactEffectivePowerAsLegacyCredit": True,
    "legacyRarityLabelsArePlayerFacingAfterMigration": False,
}

print(
    "Gear catalogue disposition valid: "
    f"{len(ordinary)} ordinary + {len(apex)} apex + {len(component)} component-authored "
    f"+ {len(retired)} decode-only = {len(classified)} Gear IDs."
)
