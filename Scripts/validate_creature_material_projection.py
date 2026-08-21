#!/usr/bin/env python3
"""Validate the exact Creature-material projection against current crafting content."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUTHORITY = ROOT / "docs" / "creature-material-projection-authority.json"
CRAFTING = ROOT / "docs" / "crafting-components-and-schematics-current.md"
ECOLOGY = ROOT / "docs" / "creature-ecology-and-materials-overhaul-current.md"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def main() -> None:
    data = json.loads(AUTHORITY.read_text())
    require(data["schemaVersion"] == 1, "Unexpected material projection schema")
    require(data["authorityID"] == "creature-material-projection-v1", "Wrong authority ID")

    families = data["families"]
    family_ids = [entry["id"] for entry in families]
    require(len(family_ids) == 18, f"Expected 18 Creature families, found {len(family_ids)}")
    require(len(set(family_ids)) == len(family_ids), "Duplicate Creature family ID")
    for entry in families:
        require(len(entry["capabilities"]) == 2, f"{entry['id']} must have exactly two capabilities")
        require(bool(entry["quantity"]), f"{entry['id']} lacks a quantity rule")

    primary = data["primaryCoveringRules"]
    require([entry["priority"] for entry in primary] == list(range(1, 11)),
            "Primary covering priority must be exact 1...10")

    produced = {entry["family"] for entry in primary}
    produced.update(entry["family"] for entry in data["additionalFamilies"])
    produced.update(data["armamentFamilies"][key]
                    for key in ("pierce", "rend", "crushWithHorns", "otherCrush"))
    produced.add(data["structuralFamily"]["family"])
    produced.update(entry["family"] for entry in data["specialFamilies"])
    require(produced == set(family_ids),
            f"Projection/output mismatch: missing={sorted(set(family_ids)-produced)} "
            f"extra={sorted(produced-set(family_ids))}")
    require(data["quality"]["encounterDangerSource"]
            == "boundWorld.sourceDangerBandBeforePartyOrDebugScaling",
            "Creature quality must not consume adaptive encounter scaling")

    crafting = CRAFTING.read_text()
    crafting_ids = set(re.findall(r"^\| `creature\.([a-z_]+)` \|", crafting, re.MULTILINE))
    require(crafting_ids == set(family_ids),
            f"Crafting ComponentProfile mismatch: missing={sorted(set(family_ids)-crafting_ids)} "
            f"extra={sorted(crafting_ids-set(family_ids))}")

    ecology = ECOLOGY.read_text()
    require("creature-material-projection-authority.json" in ecology,
            "Ecology doc must name the machine authority")
    for family_id in family_ids:
        require(re.search(rf"^\| {family_id.capitalize()} \|", ecology, re.MULTILINE) is not None,
                f"Ecology capability table lacks {family_id}")

    print("Creature material projection valid: "
          f"{len(primary)} primary rules, {len(family_ids)} families, exact crafting parity")


if __name__ == "__main__":
    main()
