#!/usr/bin/env python3
"""Generate the native combat-graph catalogue from Design authority plus live node content.

Topology and stable IDs belong to docs/combat-tree-v2-authority.json. Names, copy, numeric effects,
and technique grants remain authored in Sources/Content/Data/combat_trees.json. Keeping this as a
generated join prevents either side from becoming a second hand-maintained combat tree.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUTHORITY = ROOT / "docs/combat-tree-v2-authority.json"
LEGACY_CONTENT = ROOT / "Sources/Content/Data/combat_trees.json"
OUTPUT = ROOT / "Sources/Content/Data/combat_tree_v2.json"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def load(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def generate() -> dict:
    authority = load(AUTHORITY)
    if authority.get("schemaVersion") != 2:
        raise ValueError("combat-tree-v2 authority must use schemaVersion 2")
    effect_copy_path = ROOT / authority["effectCopyArtifact"]
    effect_copy_artifact = load(effect_copy_path)
    if effect_copy_artifact.get("combatAuthority") != str(AUTHORITY.relative_to(ROOT)):
        raise ValueError("effect-copy artifact names the wrong combat authority")
    authority_hash = sha256(AUTHORITY)
    if effect_copy_artifact.get("combatAuthoritySHA256") != authority_hash:
        raise ValueError("effect-copy artifact is stale against combat authority")
    effect_source_path = ROOT / effect_copy_artifact["sourceMarkdown"]
    if effect_copy_artifact.get("sourceMarkdownSHA256") != sha256(effect_source_path):
        raise ValueError("effect-copy artifact is stale against its source Markdown")
    effect_copy = effect_copy_artifact["effectCopyByNode"]
    technique_ids = authority["techniqueIDByNode"]
    purchase_choices = authority["purchaseChoicesByNode"]
    legacy = load(LEGACY_CONTENT)
    trees_by_id = {tree["id"]: tree for tree in legacy["trees"]}
    legacy_branch_ids = {
        branch["id"] for tree in legacy["trees"] for branch in tree["branches"]
    }
    authority_discipline_ids = {
        discipline["id"] for tree in authority["trees"] for discipline in tree["disciplines"]
    }
    legacy_to_v2 = authority.get("legacyDisciplineIDMigration", {})
    if len(set(legacy_to_v2.values())) != len(legacy_to_v2):
        raise ValueError("legacyDisciplineIDMigration must be one-to-one")
    if not set(legacy_to_v2).issubset(legacy_branch_ids):
        raise ValueError("legacyDisciplineIDMigration names an unknown legacy discipline")
    if not set(legacy_to_v2.values()).issubset(authority_discipline_ids):
        raise ValueError("legacyDisciplineIDMigration names an unknown v2 discipline")
    v2_to_legacy = {new: old for old, new in legacy_to_v2.items()}
    roles = authority["rolesByFormerIndex"]
    depths = authority["depthsByFormerIndex"]
    same_parent_role = authority["sameDisciplineParentByRole"]

    generated_trees = []
    seen_ids: set[str] = set()
    for authored_tree in authority["trees"]:
        legacy_tree = trees_by_id[authored_tree["id"]]
        legacy_branches = {branch["id"]: branch for branch in legacy_tree["branches"]}
        disciplines = []
        for discipline in authored_tree["disciplines"]:
            legacy_id = v2_to_legacy.get(discipline["id"], discipline["id"])
            if legacy_id not in legacy_branches:
                raise ValueError(
                    f"{authored_tree['id']}/{discipline['id']}: no legacy branch '{legacy_id}'"
                )
            branch = legacy_branches[legacy_id]
            if len(branch["nodes"]) != len(discipline["nodes"]):
                raise ValueError(f"{legacy_id}: authority/content node count differs")

            stable_ids = [
                f"combat.{authored_tree['id']}.{discipline['id']}.{slug}"
                for slug in discipline["nodes"]
            ]
            id_by_role = dict(zip(roles, stable_ids))
            nodes = []
            for index, (slug, legacy_node) in enumerate(zip(discipline["nodes"], branch["nodes"])):
                stable_id = stable_ids[index]
                if stable_id in seen_ids:
                    raise ValueError(f"duplicate stable node id {stable_id}")
                seen_ids.add(stable_id)
                parent_role = same_parent_role[roles[index]]
                if parent_role is None:
                    same_parents = []
                elif isinstance(parent_role, list):
                    same_parents = [id_by_role[role] for role in parent_role]
                else:
                    same_parents = [id_by_role[parent_role]]
                nodes.append({
                    "id": stable_id,
                    "slug": slug,
                    "legacyBranchID": legacy_id,
                    "formerIndex": index + 1,
                    "role": roles[index],
                    "depth": depths[index],
                    "name": legacy_node["name"],
                    "blurb": legacy_node["blurb"],
                    "legacyEffect": legacy_node["effect"],
                    "legacyTechniqueID": legacy_node.get("grantsSkill"),
                    "techniqueID": technique_ids.get(stable_id),
                    "purchaseChoices": purchase_choices.get(stable_id, []),
                    "effectCopy": effect_copy.get(stable_id),
                    "sameDisciplineParents": same_parents,
                    "hybridAlternativeParents": authored_tree["hybridAlternativeParents"].get(stable_id, []),
                })
            disciplines.append({
                "id": discipline["id"],
                "legacyBranchID": legacy_id,
                "name": branch["name"],
                "icon": branch["icon"],
                "blurb": branch["blurb"],
                "nodes": nodes,
            })
        generated_trees.append({
            "id": authored_tree["id"],
            "name": legacy_tree["name"],
            "icon": legacy_tree["icon"],
            "blurb": legacy_tree["blurb"],
            "disciplines": disciplines,
        })

    if len(seen_ids) != 72:
        raise ValueError(f"expected 72 stable combat nodes, got {len(seen_ids)}")
    if set(effect_copy) != seen_ids:
        raise ValueError("effect-copy artifact must cover exactly all 72 combat nodes")
    if not all(isinstance(value, str) and value.strip() for value in effect_copy.values()):
        raise ValueError("every combat node must have nonempty Effect copy")
    if not set(technique_ids).issubset(seen_ids):
        raise ValueError("techniqueIDByNode names an unknown combat node")
    if len(technique_ids) != 20 or len(seen_ids - set(technique_ids)) != 52:
        raise ValueError("combat techniques must resolve to exactly 20 grants and 52 nulls")
    return {
        "_note": "GENERATED schema-2 topology, canonical technique IDs and exact Effect copy. Legacy fields are decode/migration payload only.",
        "schemaVersion": authority["schemaVersion"],
        "graphVersion": authority["graphVersion"],
        "authoritySHA256": authority_hash,
        "effectCopySHA256": sha256(effect_copy_path),
        "effectCopySourceMarkdownSHA256": effect_copy_artifact["sourceMarkdownSHA256"],
        "capstoneGate": authority["capstoneGate"],
        "trees": generated_trees,
    }


def rendered() -> str:
    return json.dumps(generate(), indent=2, ensure_ascii=False) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail when generated output is stale")
    parser.add_argument("--write", action="store_true", help="rewrite generated output")
    args = parser.parse_args()
    expected = rendered()
    current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else ""
    if args.check:
        if current != expected:
            print(f"{OUTPUT.relative_to(ROOT)} is stale; run {Path(__file__).relative_to(ROOT)} --write")
            return 1
        return 0
    if args.write or not OUTPUT.exists():
        OUTPUT.write_text(expected, encoding="utf-8")
        return 0
    parser.error("choose --check or --write")


if __name__ == "__main__":
    raise SystemExit(main())
