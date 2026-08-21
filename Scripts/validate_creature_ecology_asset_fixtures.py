#!/usr/bin/env python3
"""Validate Creature ecology Asset proof fixtures against the material projection authority."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "docs" / "creature-ecology-asset-fixtures.json"
PROJECTION = ROOT / "docs" / "creature-material-projection-authority.json"


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def close_to_100(values: list[float]) -> bool:
    return abs(sum(values) - 100) < 0.0001


def project(entry: dict) -> list[str]:
    habitat = entry["habitat"]
    traits = entry["traits"]
    body = traits["bodyPlan"]
    appendages = traits["appendages"]
    covering = traits["covering"]
    armament = traits["armament"]
    result: list[str] = []

    hardness = covering["hardness"]
    length = covering["length"]
    coverage = covering["coverage"]
    insulation = length * coverage / 100

    if appendages["type"] == "feathered" and appendages["count"] > 0:
        result.append("feather")
    elif habitat == "aquatic" or body == "piscine":
        if coverage >= 15 and hardness >= 25:
            result.append("scale")
        elif coverage >= 15:
            result.append("hide")
    elif body == "segmented" and coverage >= 15 and hardness >= 55:
        result.append("chitin")
    elif body == "radial" and coverage >= 15 and hardness >= 55:
        result.append("shell")
    elif coverage >= 15 and hardness >= 55 and length >= 45:
        result.append("quill")
    elif coverage >= 15 and hardness >= 70:
        result.append("plate")
    elif coverage >= 15 and hardness >= 35:
        result.append("scale")
    elif coverage >= 50 and length >= 45:
        result.append("pelt")
    elif coverage >= 15:
        result.append("hide")

    if result and result[0] == "feather" and insulation >= 25:
        result.append("down")
    if appendages["type"] == "finned" and appendages["count"] > 0:
        result.append("fin")

    pierce = armament["pierce"]
    crush = armament["crush"]
    rend = armament["rend"]
    if pierce + crush + rend >= 30:
        if pierce >= crush and pierce >= rend:
            result.append("fang")
        elif crush >= rend:
            result.append("horn" if traits["cranialFeature"] == "horns" else "tusk")
        else:
            result.append("claw")

    if traits["boneDensity"] >= 20 and body != "amorphous":
        result.append("bone")

    if traits["isToxic"]:
        toxin_potency = round(0.70 * traits["coloration"]["patterning"] + 0.30 * traits["ornament"])
        if toxin_potency > 0:
            result.append("venom")
    if habitat == "aquatic" and insulation >= 45:
        result.append("oil")
    emanation = traits["emanation"]
    if emanation is not None and emanation["strength"] >= 25:
        result.append("ichor")
    return result


def main() -> None:
    fixtures = load(FIXTURES)
    projection = load(PROJECTION)

    assert fixtures["schemaVersion"] == 1
    assert projection["authorityID"] == "creature-material-projection-v1"
    assert fixtures["profiles"] == {
        "world": {"width": 16, "height": 16, "camera": "straightTopDown"},
        "encounterDetail": {"width": 48, "height": 48, "camera": "acceptedShallowSide"},
        "material": {"width": 32, "height": 32, "camera": "objectIcon"},
    }
    assert fixtures["qualityFrames"] == [
        "rough", "standard", "fine", "superior", "exceptional", "peerless"
    ]

    authority_families = [entry["id"] for entry in projection["families"]]
    assert fixtures["materialAtlasIDs"] == authority_families
    assert len(authority_families) == len(set(authority_families)) == 18

    species = fixtures["species"]
    assert len(species) == 7
    assert len({entry["id"] for entry in species}) == 7
    assert len({entry["speciesSeed"] for entry in species}) == 7
    assert {entry["habitat"] for entry in species} == {"terrestrial", "shore", "aquatic", "aerial"}

    for entry in species:
        traits = entry["traits"]
        assert close_to_100([
            traits["coloration"]["cyan"], traits["coloration"]["magenta"], traits["coloration"]["yellow"]
        ]), f"{entry['id']}: CMY must sum to 100"
        assert close_to_100([
            traits["finish"]["opacity"], traits["finish"]["shine"], traits["finish"]["schiller"]
        ]), f"{entry['id']}: finish must sum to 100"
        assert close_to_100(list(traits["sensory"].values())), f"{entry['id']}: sensory must sum to 100"
        assert 0 <= traits["appendages"]["count"] <= 8
        for value in (
            traits["size"], traits["build"], traits["boneDensity"], traits["ornament"],
            *traits["covering"].values(),
            traits["coloration"]["depth"], traits["coloration"]["patterning"],
            *traits["armament"].values(),
        ):
            if isinstance(value, (int, float)):
                assert 0 <= value <= 100, f"{entry['id']}: numeric input outside 0...100"
        actual = project(entry)
        assert actual == entry["expectedFamilies"], (
            f"{entry['id']}: expected {entry['expectedFamilies']}, projected {actual}"
        )

    print(
        "Creature ecology Asset fixtures valid: "
        f"{len(species)} species, {len(authority_families)} materials, dual camera profiles"
    )


if __name__ == "__main__":
    main()
