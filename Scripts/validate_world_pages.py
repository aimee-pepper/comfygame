#!/usr/bin/env python3
"""Validate the authored World Page catalogue against live writing content."""

from __future__ import annotations

import json
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUTHORITY = ROOT / "docs" / "world-pages-authority.json"
SYMBOLS = ROOT / "Sources" / "Content" / "Data" / "symbols.json"
SHAPES = ROOT / "Sources" / "Content" / "Data" / "rune_shapes.json"


def load(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def rounded_cell_cost(cell_count: int) -> int:
    return math.floor(cell_count * 0.6 + 0.5)


def main() -> None:
    authority = load(AUTHORITY)
    symbols_data = load(SYMBOLS)
    shapes_data = load(SHAPES)

    symbols = {entry["id"]: entry for entry in symbols_data["symbols"]}
    shapes = {entry["id"]: entry for entry in shapes_data["shapes"]}
    width = authority["pageSize"]["width"]
    height = authority["pageSize"]["height"]
    errors: list[str] = []
    definition_ids: set[str] = set()

    for definition in authority["definitions"]:
        definition_id = definition["id"]
        if definition_id in definition_ids:
            errors.append(f"{definition_id}: duplicate definition ID")
        definition_ids.add(definition_id)

        occupied: set[tuple[int, int]] = set()
        mark_ids: set[int] = set()
        page_symbol_ids: set[str] = set()
        symbol_value = 0
        cell_count = 0

        for mark in definition["symbols"]:
            page_symbol_ids.add(mark["id"])
            mark_id = mark["markID"]
            if mark_id in mark_ids:
                errors.append(f"{definition_id}: duplicate mark ID {mark_id}")
            mark_ids.add(mark_id)

            symbol = symbols.get(mark["id"])
            if symbol is None:
                errors.append(f"{definition_id}: unknown symbol {mark['id']}")
            else:
                symbol_value += symbol["essenceCost"]

            shape = shapes.get(mark["shapeID"])
            if shape is None:
                errors.append(f"{definition_id}: unknown shape {mark['shapeID']}")
                continue
            if shape["hand"] != definition["hand"]:
                errors.append(
                    f"{definition_id}: {mark['shapeID']} belongs to {shape['hand']}, "
                    f"not {definition['hand']}"
                )

            origin_x, origin_y = mark["origin"]
            cell_count += len(shape["cells"])
            for delta_x, delta_y in shape["cells"]:
                cell = (origin_x + delta_x, origin_y + delta_y)
                if not (0 <= cell[0] < width and 0 <= cell[1] < height):
                    errors.append(f"{definition_id}: mark {mark_id} leaves page at {cell}")
                if cell in occupied:
                    errors.append(f"{definition_id}: marks overlap at {cell}")
                occupied.add(cell)

        expected_page_cost = 10 + symbol_value
        if definition["worldPageCost"] != expected_page_cost:
            errors.append(
                f"{definition_id}: World Page cost {definition['worldPageCost']} "
                f"!= base plus symbol value {expected_page_cost}"
            )

        if "copiedCost" in definition:
            expected_copied_cost = expected_page_cost + rounded_cell_cost(cell_count)
            if definition["copiedCost"] != expected_copied_cost:
                errors.append(
                    f"{definition_id}: copied cost {definition['copiedCost']} "
                    f"!= live formula {expected_copied_cost}"
                )

        candidate_unknowns = set(definition.get("candidateUnknownSymbolIDs", []))
        if not candidate_unknowns.issubset(page_symbol_ids):
            errors.append(f"{definition_id}: candidate unknowns are not all marks on the page")
        research_marks = {
            symbol_id
            for symbol_id in page_symbol_ids
            if symbols.get(symbol_id, {}).get("acquisition") == "research"
        }
        if candidate_unknowns != research_marks:
            errors.append(
                f"{definition_id}: candidate unknowns {sorted(candidate_unknowns)} "
                f"!= research-owned page marks {sorted(research_marks)}"
            )

    starters = [
        definition
        for definition in authority["definitions"]
        if definition["disposition"] == "starterUnique"
    ]
    if len(starters) != 3:
        errors.append(f"catalogue: expected exactly 3 starter pages, found {len(starters)}")
    for starter in starters:
        if not isinstance(starter.get("seed"), int):
            errors.append(f"{starter['id']}: starter seed must be frozen as an integer")
        if starter.get("seedStatus") != "revalidatedCurrentGenerator":
            errors.append(f"{starter['id']}: starter seed lacks current-generator receipt")
        receipt = starter.get("validationReceipt")
        if not isinstance(receipt, dict):
            errors.append(f"{starter['id']}: starter lacks a structured validation receipt")
        else:
            required_receipt = {
                "profile", "terrain", "flora", "ordinaryCreatureCount", "apexCount",
                "hostileFloraCount", "writingCount", "rawEssenceObtainable",
                "projectedCollapseTurn", "passableTiles", "reachablePassableTiles",
            }
            if set(receipt) != required_receipt:
                errors.append(f"{starter['id']}: validation receipt fields are not exact")
            if receipt.get("profile") != "ordinary":
                errors.append(f"{starter['id']}: starter validation profile must be ordinary")
            if not isinstance(receipt.get("terrain"), dict) or not receipt.get("terrain"):
                errors.append(f"{starter['id']}: validation receipt lacks terrain counts")
            if not isinstance(receipt.get("flora"), dict):
                errors.append(f"{starter['id']}: validation receipt lacks flora counts")
            if receipt.get("ordinaryCreatureCount") != 3:
                errors.append(f"{starter['id']}: starter must freeze exactly three ordinary creatures")
            if receipt.get("apexCount") != 0 or receipt.get("hostileFloraCount") != 0:
                errors.append(f"{starter['id']}: starter receipt contains opening spike content")
            if receipt.get("writingCount", 0) < 1:
                errors.append(f"{starter['id']}: starter receipt lacks guaranteed writing")
            if receipt.get("rawEssenceObtainable", 0) < 10:
                errors.append(f"{starter['id']}: starter receipt lacks continuation Essence")
            if receipt.get("projectedCollapseTurn", 0) < 45:
                errors.append(f"{starter['id']}: starter receipt lacks collapse runway")
            if receipt.get("passableTiles") != receipt.get("reachablePassableTiles"):
                errors.append(f"{starter['id']}: not every passable tile is reachable")
        if any(symbols[mark["id"]]["acquisition"] != "starter" for mark in starter["symbols"]):
            errors.append(f"{starter['id']}: starter page contains non-starter vocabulary")

    if errors:
        raise SystemExit("World Page authority failed:\n- " + "\n- ".join(errors))

    print(
        f"World Page authority valid: {len(definition_ids)} definitions, "
        f"{len(starters)} current-generator starters, {width}x{height} layouts."
    )


if __name__ == "__main__":
    main()
