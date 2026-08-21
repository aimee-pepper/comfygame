#!/usr/bin/env python3
"""Validate the closed v1 Creature habitat and morphology authority."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUTHORITY = ROOT / "docs" / "creature-habitat-authority.json"
ECOLOGY = ROOT / "docs" / "creature-ecology-and-materials-overhaul-current.md"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def main() -> None:
    data = json.loads(AUTHORITY.read_text())
    expected_habitats = ["terrestrial", "shore", "aquatic", "aerial"]
    expected_plans = {"quadruped", "biped", "serpentine", "segmented", "radial", "piscine", "amorphous"}
    expected_appendages = {"none", "membrane", "feathered", "finned", "limbed"}

    require(data["schemaVersion"] == 1, "Unexpected habitat schema")
    require(data["authorityID"] == "creature-habitat-v1", "Wrong habitat authority ID")
    require(data["habitats"] == expected_habitats, "Habitat order/cases drifted")
    require(data["minimumComponentTileCount"] == 2, "A one-tile puddle cannot be a habitat")
    require(0 < data["repeatHabitatMultiplier"] <= 1, "Invalid repeat-habitat multiplier")

    for habitat in expected_habitats:
        body = data["bodyPlanWeights"][habitat]
        require(set(body) == expected_plans, f"{habitat} body-plan cases drifted")
        require(sum(body.values()) == 100, f"{habitat} body-plan weights must sum to 100")
        appendage = data["appendageWeightTransforms"][habitat]
        require(set(appendage) == expected_appendages, f"{habitat} appendage cases drifted")
        require(any(value > 0 for value in appendage.values()), f"{habitat} has no appendage route")

    require(data["bodyPlanWeights"]["aquatic"]["piscine"] > 0,
            "Aquatic habitat must support piscine bodies")
    require(data["appendageWeightTransforms"]["aquatic"]["finned"] > 0,
            "Aquatic habitat must support fins")
    require(data["appendageWeightTransforms"]["aerial"]["feathered"] > 0
            and data["appendageWeightTransforms"]["aerial"]["membrane"] > 0,
            "Aerial habitat must support both flight identities")
    require(data["tileSets"]["aquatic"].endswith("ShallowAndDeepWater"),
            "Aquatic habitat must include shallow and deep water")
    require(data["gameplayRNG"].startswith("unchanged"), "Ecology must not perturb gameplay RNG")

    ecology = ECOLOGY.read_text()
    require("creature-habitat-authority.json" in ecology,
            "Ecology doc must name the habitat machine authority")
    print("Creature habitat authority valid: 4 habitats, 7 body plans, "
          "5 appendage cases, shallow+deep water")


if __name__ == "__main__":
    main()
