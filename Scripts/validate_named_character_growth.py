#!/usr/bin/env python3
"""Validate the authored named-character growth-pair authority."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
STATS = {"might", "finesse", "fortitude", "perception", "wit"}


def load(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def main() -> None:
    authority = load(ROOT / "docs" / "named-character-growth-authority.json")
    travellers = load(ROOT / "Sources" / "Content" / "Data" / "travellers.json")
    expected_ids = {entry["id"] for entry in travellers["travellers"]} | {"quill"}
    entries = authority["fixedCharacters"]
    actual_ids = [entry["id"] for entry in entries]
    errors: list[str] = []

    if len(actual_ids) != len(set(actual_ids)):
        errors.append("fixedCharacters contains duplicate IDs")
    if set(actual_ids) != expected_ids:
        errors.append(
            f"fixed character IDs differ: missing={sorted(expected_ids - set(actual_ids))}, "
            f"extra={sorted(set(actual_ids) - expected_ids)}"
        )

    for entry in entries:
        pair = {entry["primary"], entry["secondary"]}
        if not pair.issubset(STATS):
            errors.append(f"{entry['id']}: invalid stat in growth pair")
        if entry["primary"] == entry["secondary"]:
            errors.append(f"{entry['id']}: primary and secondary must differ")

    binder = authority["binder"]
    if set(binder["allowedStats"]) != STATS or not binder["requiresDistinctPair"]:
        errors.append("Binder choice must expose exactly five stats and require a distinct pair")

    if errors:
        raise SystemExit("Named-character growth authority failed:\n- " + "\n- ".join(errors))

    print(f"Named-character growth authority valid: {len(entries)} fixed identities plus Binder choice.")


if __name__ == "__main__":
    main()
