#!/usr/bin/env python3
"""Validate recovered-teaching coverage against the live Workshop grant catalogue."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RESEARCH = ROOT / "Sources/Content/Data/research.json"
AUTHORITY = ROOT / "docs/recovered-teachings-current.md"


def fail(message: str) -> None:
    raise SystemExit(f"Recovered-teaching authority invalid: {message}")


research = json.loads(RESEARCH.read_text())
text = AUTHORITY.read_text()

rows = [line for line in text.splitlines() if line.startswith("|") and "`teaching." in line]
teaching_ids = [re.search(r"`(teaching\.[a-z0-9_.]+)`", row).group(1) for row in rows]
if len(teaching_ids) != 38 or len(set(teaching_ids)) != 38:
    fail(f"expected 38 unique teaching IDs, found {len(teaching_ids)} / {len(set(teaching_ids))} unique")

reward_matches = []
for row in rows:
    match = re.search(r"(?:Gambit|focus|symbol|capability) `([a-z0-9_]+)`", row)
    if not match:
        fail(f"missing typed reward in row: {row}")
    reward_matches.append(match.group(1))

expected = set()
for node in research["nodes"]:
    if node.get("branch") not in {"instruction", "hand", "lexicon", "bargain"}:
        continue
    for grant in node.get("grants", []):
        kind = grant.get("kind")
        if kind in {"gambitComponent", "focus", "symbol"}:
            expected.add(grant["id"])
        elif kind == "effect" and grant.get("effect") == "automateSelf":
            expected.add("automate_self")
        elif kind == "effect" and grant.get("effect") == "gambitSlot":
            pass
        else:
            fail(f"unclassified removed-Workshop grant: {node['id']} {grant}")

actual = set(reward_matches)
if actual != expected:
    fail(f"reward mismatch; missing={sorted(expected - actual)} extra={sorted(actual - expected)}")
if len(reward_matches) != len(actual):
    fail("a reward is assigned to more than one primary teaching")

diary_exclusive = {
    "scarp", "ruin", "gold_ore", "hush", "pond", "drift", "hive", "amber", "chitin",
    "thorn", "bone", "silk", "coral", "mercury", "brine", "echo", "mirror", "dream",
}
if actual & diary_exclusive:
    fail(f"Diary-exclusive focus leaked into generic pool: {sorted(actual & diary_exclusive)}")

for required in ("45%", "at most one teaching", "never replace", "third", "survives collapse"):
    if required.lower() not in text.lower():
        fail(f"missing pacing/persistence authority phrase: {required}")

print(
    "Recovered-teaching authority valid: "
    f"{len(teaching_ids)} teachings cover {len(expected)} live knowledge/automation grants; "
    "2 legacy Gambit-slot grants intentionally excluded."
)
