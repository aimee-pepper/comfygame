#!/usr/bin/env python3
"""Generate the compiled starter World Page registry from its design authority."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
AUTHORITY = ROOT / "docs/world-pages-authority.json"
TARGET = ROOT / "Sources/Model/Page.swift"
BEGIN = "    // BEGIN GENERATED STARTER WORLD PAGES — Scripts/generate_world_pages.py"
END = "    // END GENERATED STARTER WORLD PAGES"
EXPECTED_IDS = ["starter_open_meadow", "starter_rainwashed_shore", "starter_stone_hollow"]
ID_NAMES = ["openMeadowID", "rainwashedShoreID", "stoneHollowID"]


def fail(message: str) -> None:
    raise ValueError(message)


def load_and_validate() -> tuple[dict, list[dict], str]:
    raw = AUTHORITY.read_bytes()
    authority = json.loads(raw)
    if authority.get("schemaVersion") != 1 or authority.get("status") != "designAuthority":
        fail("authority must be schemaVersion 1 with designAuthority status")
    if authority.get("pageSize") != {"width": 6, "height": 6}:
        fail("starter runtime supports exactly the authoritative 6x6 page size")
    pricing = authority.get("pricing", {})
    if pricing.get("worldPageRule") != "resolvedBookCostMinusCellInkCost":
        fail("worldPageRule must remain resolvedBookCostMinusCellInkCost")
    starters = [entry for entry in authority.get("definitions", [])
                if entry.get("disposition") == "starterUnique"]
    if [entry.get("id") for entry in starters] != EXPECTED_IDS:
        fail("authority must contain exactly the three ordered starterUnique definitions")
    required = {"id", "title", "disposition", "provenance", "hand", "symbols",
                "copiedCost", "worldPageCost", "seed", "seedStatus", "promise"}
    for entry in starters:
        missing = required - entry.keys()
        if missing:
            fail(f"{entry.get('id')} missing fields: {sorted(missing)}")
        if entry["seedStatus"] != "sampledCandidate" or entry["hand"] != "crude":
            fail(f"{entry['id']} must be a sampledCandidate written in crude hand")
        if not all(isinstance(entry[key], str) and entry[key] for key in
                   ("id", "title", "provenance", "promise")):
            fail(f"{entry['id']} has an empty or non-string authored field")
        if not all(isinstance(entry[key], int) and entry[key] > 0 for key in
                   ("copiedCost", "worldPageCost", "seed")):
            fail(f"{entry['id']} costs and seed must be positive integers")
        if entry["worldPageCost"] >= entry["copiedCost"]:
            fail(f"{entry['id']} pre-inscribed price must be below copied price")
        symbols = entry["symbols"]
        if not isinstance(symbols, list) or not symbols:
            fail(f"{entry['id']} must contain at least one frozen symbol")
        mark_ids: set[int] = set()
        occupied_origins: set[tuple[int, int]] = set()
        for symbol in symbols:
            if set(symbol) != {"id", "markID", "shapeID", "origin"}:
                fail(f"{entry['id']} symbol fields are not exact")
            origin = symbol["origin"]
            if (not isinstance(symbol["id"], str) or not symbol["id"]
                    or not isinstance(symbol["shapeID"], str) or not symbol["shapeID"]
                    or not isinstance(symbol["markID"], int)
                    or not isinstance(origin, list) or len(origin) != 2
                    or not all(isinstance(value, int) and 0 <= value < 6 for value in origin)):
                fail(f"{entry['id']} has an invalid frozen symbol")
            if symbol["markID"] in mark_ids or tuple(origin) in occupied_origins:
                fail(f"{entry['id']} has duplicate mark identity/origin")
            mark_ids.add(symbol["markID"])
            occupied_origins.add(tuple(origin))
    return authority, starters, hashlib.sha256(raw).hexdigest()


def swift_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def generated(starters: list[dict], digest: str) -> str:
    lines = [BEGIN, f'    static let authoritySHA256 = "{digest}"']
    for name, entry in zip(ID_NAMES, starters):
        lines.append(f"    static let {name}: WorldPageDefinitionID = {swift_string(entry['id'])}")
    lines += [
        "",
        "    /// Reserved, explicit physical identities. They do not depend on inventory insertion order or",
        "    /// the general item allocator and therefore remain byte-stable across relaunch and migration.",
        "    static let starterInstances: [WorldPageInstance] = zip(",
        "        [InstanceID(rawValue: 0x5750_0000_0000_0001),",
        "         InstanceID(rawValue: 0x5750_0000_0000_0002),",
        "         InstanceID(rawValue: 0x5750_0000_0000_0003)],",
        "        starterDefinitions",
        "    ).map { WorldPageInstance(id: $0.0, definition: $0.1) }",
        "",
        "    static let starterDefinitions: [WorldPageDefinition] = [",
    ]
    for index, (name, entry) in enumerate(zip(ID_NAMES, starters)):
        lines.append(f"        definition(id: {name}, title: {swift_string(entry['title'])},")
        lines.append(f"                   provenance: {swift_string(entry['provenance'])},")
        marks = entry["symbols"]
        for mark_index, mark in enumerate(marks):
            prefix = "                   marks: [" if mark_index == 0 else "                           "
            suffix = "]" if mark_index == len(marks) - 1 else ""
            lines.append(f"{prefix}({swift_string(mark['id'])}, {mark['markID']}, "
                         f"{swift_string(mark['shapeID'])}, {mark['origin'][0]}, {mark['origin'][1]}){suffix},")
        lines.append(f"                   copiedCost: {entry['copiedCost']}, worldPageCost: {entry['worldPageCost']}, "
                     f"seed: {entry['seed']},")
        comma = "," if index < len(starters) - 1 else ""
        lines.append(f"                   promise: {swift_string(entry['promise'])}){comma}")
    lines += ["    ]", END]
    return "\n".join(lines)


def replaced_source(source: str, block: str) -> str:
    if source.count(BEGIN) != 1 or source.count(END) != 1:
        fail("Page.swift must contain exactly one generated marker pair")
    start = source.index(BEGIN)
    finish = source.index(END, start) + len(END)
    return source[:start] + block + source[finish:]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true",
                        help="fail if validation or generated Swift freshness differs")
    args = parser.parse_args()
    try:
        _, starters, digest = load_and_validate()
        source = TARGET.read_text()
        expected = replaced_source(source, generated(starters, digest))
        if args.check:
            if expected != source:
                print("Page.swift starter World Pages are stale; run Scripts/generate_world_pages.py",
                      file=sys.stderr)
                return 1
        else:
            TARGET.write_text(expected)
    except (OSError, json.JSONDecodeError, ValueError) as error:
        print(f"world page generation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
