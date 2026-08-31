#!/usr/bin/env python3
"""Validate non-runtime AssetEvidence receipts and their exact bytes."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import tempfile
from pathlib import Path, PurePosixPath

TOKEN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
VERSION = re.compile(r"^v[0-9]+(?:\.[0-9]+)*$")
SHA = re.compile(r"^[0-9a-f]{64}$")
HASH_STEM = re.compile(r"^[0-9a-fA-F]{32,}$")
COPY_SUFFIX = re.compile(r"(?: |\()\d+\)?(?=\.[^.]+$)")
CLASSES = {"review-evidence", "reference", "candidate-output", "generated-test-artifact", "blocked"}
ROLES = {"render", "metadata", "interactive-proof", "test-report"}
APPROVED_ACCEPTED_EVIDENCE_FINGERPRINTS: set[str] = set()

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def fingerprint(receipt: dict[str, object]) -> str | None:
    files = receipt.get("files")
    if not isinstance(files, list) or not all(isinstance(item, dict) for item in files):
        return None
    fields = ["bookbinder-accepted-evidence-v1"]
    for key in ("schemaVersion", "family", "version", "variant", "classification",
                "gameWikiDisclosure"):
        fields.append(str(receipt.get(key, "")))
    for item in sorted(files, key=lambda value: str(value.get("path", ""))):
        fields.extend(str(item.get(key, "")) for key in ("path", "role", "sha256"))
    payload = b"".join(f"{len(value.encode())}:{value}".encode() for value in fields)
    return hashlib.sha256(payload).hexdigest()

def safe_repo_path(root: Path, value: object) -> bool:
    if not isinstance(value, str): return False
    path = PurePosixPath(value)
    return not path.is_absolute() and ".." not in path.parts and (root / value).is_file()

def validate(root: Path, approved: set[str] = APPROVED_ACCEPTED_EVIDENCE_FINGERPRINTS) -> list[str]:
    errors: list[str] = []
    evidence = root / "AssetEvidence"
    if not evidence.is_dir(): return ["AssetEvidence root is missing"]
    for project in (root / "project.yml", root / "Bookbinder.xcodeproj/project.pbxproj"):
        if project.is_file() and "AssetEvidence" in project.read_text(encoding="utf-8"):
            errors.append(f"AssetEvidence must not be an app resource: {project.relative_to(root)}")
    receipts = sorted(evidence.glob("*/*/*/evidence-receipt.json"))
    declared: set[str] = set()
    for receipt_path in receipts:
        try: receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
        except Exception as error:
            errors.append(f"invalid receipt JSON: {receipt_path}: {error}"); continue
        if not isinstance(receipt, dict): errors.append(f"receipt is not an object: {receipt_path}"); continue
        family, version, variant = receipt_path.relative_to(evidence).parts[:3]
        exact = {
            "schemaVersion": "asset-evidence-receipt-v1", "family": family,
            "version": version, "variant": variant, "sourceAuthorship": False,
            "runtimeAuthority": False, "gameplayAuthority": False,
            "finalArtAcceptance": False,
        }
        for key, value in exact.items():
            if receipt.get(key) != value: errors.append(f"receipt {key} must equal {value!r}: {receipt_path}")
        if not TOKEN.fullmatch(family) or not VERSION.fullmatch(version) or not TOKEN.fullmatch(variant):
            errors.append(f"non-semantic evidence route: {receipt_path}")
        if receipt.get("classification") not in CLASSES: errors.append(f"invalid classification: {receipt_path}")
        if receipt.get("gameWikiDisclosure") not in {"withheld", "disclosed"}: errors.append(f"invalid disclosure: {receipt_path}")
        for key in ("authorityPaths", "producerPaths"):
            values = receipt.get(key)
            if not isinstance(values, list) or (key == "authorityPaths" and not values):
                errors.append(f"invalid {key}: {receipt_path}"); continue
            for value in values:
                if not safe_repo_path(root, value): errors.append(f"missing/unsafe {key}: {value}")
        files = receipt.get("files")
        if not isinstance(files, list) or not files: errors.append(f"receipt has no files: {receipt_path}"); continue
        for item in files:
            if not isinstance(item, dict): errors.append(f"invalid file entry: {receipt_path}"); continue
            value, role, expected = item.get("path"), item.get("role"), item.get("sha256")
            prefix = f"AssetEvidence/{family}/{version}/{variant}/review/"
            if not isinstance(value, str) or not value.startswith(prefix) or len(PurePosixPath(value).parts) != 6:
                errors.append(f"file is outside semantic review path: {value}"); continue
            name = PurePosixPath(value).name
            if HASH_STEM.fullmatch(Path(name).stem) or COPY_SUFFIX.search(name): errors.append(f"nonsemantic evidence filename: {value}")
            if role not in ROLES: errors.append(f"invalid evidence role: {value}")
            if not isinstance(expected, str) or not SHA.fullmatch(expected): errors.append(f"invalid evidence hash: {value}")
            absolute = root / value
            if not absolute.is_file(): errors.append(f"missing evidence: {value}")
            elif expected != sha(absolute): errors.append(f"evidence hash mismatch: {value}")
            if value in declared: errors.append(f"duplicate evidence path: {value}")
            declared.add(value)
        accepted = receipt.get("accepted")
        if accepted not in {True, False}: errors.append(f"accepted must be boolean: {receipt_path}")
        fp = fingerprint(receipt)
        if accepted is True and (fp is None or fp not in approved):
            errors.append(f"accepted evidence lacks reviewed fingerprint: {receipt_path} ({fp})")
    actual = {path.relative_to(root).as_posix() for path in evidence.glob("*/*/*/review/*") if path.is_file()}
    for value in sorted(actual - declared): errors.append(f"unreceipted evidence: {value}")
    for value in sorted(declared - actual): errors.append(f"receipt points outside evidence set: {value}")
    return errors

def self_test() -> None:
    with tempfile.TemporaryDirectory(prefix="bookbinder-evidence-") as directory:
        root=Path(directory); (root/"AssetEvidence/a/v1/b/review").mkdir(parents=True)
        (root/"AssetEvidence/_templates").mkdir(parents=True)
        (root/"AssetEvidence/README.md").write_text("evidence")
        (root/"project.yml").write_text("sources: []")
        (root/"Bookbinder.xcodeproj").mkdir(); (root/"Bookbinder.xcodeproj/project.pbxproj").write_text("Sources")
        authority=root/"docs/a.json"; authority.parent.mkdir(); authority.write_text("{}")
        file=root/"AssetEvidence/a/v1/b/review/report.json"; file.write_text("{}")
        receipt={"schemaVersion":"asset-evidence-receipt-v1","family":"a","version":"v1","variant":"b","classification":"generated-test-artifact","accepted":False,"sourceAuthorship":False,"runtimeAuthority":False,"gameplayAuthority":False,"finalArtAcceptance":False,"gameWikiDisclosure":"withheld","authorityPaths":["docs/a.json"],"producerPaths":[],"files":[{"path":"AssetEvidence/a/v1/b/review/report.json","role":"test-report","sha256":sha(file)}]}
        rp=root/"AssetEvidence/a/v1/b/evidence-receipt.json"; rp.write_text(json.dumps(receipt))
        assert not validate(root)
        receipt["accepted"]=True; rp.write_text(json.dumps(receipt)); assert validate(root)
        fp=fingerprint(receipt); assert fp and not validate(root,{fp})
        file.write_text("changed"); assert validate(root,{fp})

def main() -> int:
    parser=argparse.ArgumentParser(); parser.add_argument("--check",action="store_true"); parser.add_argument("--self-test",action="store_true"); args=parser.parse_args()
    if args.self_test: self_test(); print("AssetEvidence verifier self-test passed"); return 0
    if not args.check: parser.error("choose --check or --self-test")
    errors=validate(Path.cwd())
    if errors:
        print("AssetEvidence check failed:",file=sys.stderr)
        for error in errors: print(f"- {error}",file=sys.stderr)
        return 1
    print("AssetEvidence check passed; accepted-evidence allowlist is empty")
    return 0
if __name__ == "__main__": raise SystemExit(main())

