#!/usr/bin/env python3
"""Validate the current physical crafting ComponentProfile/Schematic authority."""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / "docs" / "crafting-components-and-schematics-current.md"
text = DOC.read_text(encoding="utf-8")


def section(start: str, end: str) -> str:
    begin = text.index(start) + len(start)
    finish = text.index(end, begin)
    return text[begin:finish]


world_section = section("## 4. Complete ComponentProfile table — World domain",
                        "## 5. Complete ComponentProfile table — Creature domain")
creature_section = section("## 5. Complete ComponentProfile table — Creature domain",
                           "## 6. Exact reusable socket sets")
alias_section = section("## 6. Exact reusable socket sets",
                        "## 7. Complete physical schematic socket table")
schematic_section = section("## 7. Complete physical schematic socket table",
                            "## 8. Pointed Blade reference fixture")

family_pattern = re.compile(r"^\| `(world|creature)\.([a-z_]+)` \| ([^|]+) \|", re.M)
world_rows = [(f"{domain}.{family}", roles.strip())
              for domain, family, roles in family_pattern.findall(world_section)]
creature_rows = [(f"{domain}.{family}", roles.strip())
                 for domain, family, roles in family_pattern.findall(creature_section)]

assert len(world_rows) == 21, f"expected 21 World profiles, found {len(world_rows)}"
assert len(creature_rows) == 18, f"expected 18 Creature profiles, found {len(creature_rows)}"
all_rows = world_rows + creature_rows
families = {family for family, _ in all_rows}
assert len(families) == 39, "material family IDs must be unique"

nonphysical = {
    family for family, roles in all_rows
    if "ingredient only" in roles or "special recipe only" in roles or "legacy only" in roles
}

alias_names = re.findall(r"^- `([A-Z_]+)`: ", alias_section, re.M)
assert len(alias_names) == 16, f"expected 16 exact socket aliases, found {len(alias_names)}"
assert len(set(alias_names)) == len(alias_names), "socket alias names must be unique"

alias_refs = set(re.findall(r"(?:world|creature)\.[a-z_]+", alias_section))
unknown_alias_refs = alias_refs - families
assert not unknown_alias_refs, f"socket aliases reference unknown families: {sorted(unknown_alias_refs)}"
illegal_alias_refs = alias_refs & nonphysical
assert not illegal_alias_refs, f"nonphysical families entered socket aliases: {sorted(illegal_alias_refs)}"

schematic_pattern = re.compile(r"^\| `([a-z0-9_]+)` · (Blacksmith|Tannery|Armoury|Bowyer|Weaponsmith) \|", re.M)
schematics = schematic_pattern.findall(schematic_section)
assert len(schematics) == 21, f"expected 21 physical Schematics, found {len(schematics)}"
ids = [identifier for identifier, _ in schematics]
assert len(set(ids)) == len(ids), "Schematic IDs must be unique"

expected_station_counts = {
    "Blacksmith": 8,
    "Tannery": 3,
    "Armoury": 3,
    "Bowyer": 3,
    "Weaponsmith": 4,
}
for station, expected in expected_station_counts.items():
    actual = sum(1 for _, owner in schematics if owner == station)
    assert actual == expected, f"expected {expected} {station} Schematics, found {actual}"

for line in schematic_section.splitlines():
    if not line.startswith("| `") or "Schematic ID" in line:
        continue
    assert " P " in line, f"Schematic row lacks a primary socket: {line}"
    assert "any sample" not in line.lower(), f"open-ended sample eligibility is forbidden: {line}"

required_fixture_copy = [
    "`0.70 × 5 + 0.30 × 2 = 4.10`",
    "Forceful masterwork `+0.75`",
    "Heavy `−1 initiative`",
    "Insulated fine `+10 heat-ward points`",
    "power 4.75; initiative −1; heat ward +10",
]
for required in required_fixture_copy:
    assert required in text, f"Pointed Blade reference fixture is missing: {required}"

print(
    "Crafting component authority valid: "
    f"{len(world_rows)} World profiles, {len(creature_rows)} Creature profiles, "
    f"{len(alias_names)} aliases, {len(schematics)} Schematics."
)
