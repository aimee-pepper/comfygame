#!/usr/bin/env python3
"""Fail closed on the human-authored AssetSources intake boundary."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import tempfile
from pathlib import Path, PurePosixPath


PACK = re.compile(r"^[A-Z][A-Za-z0-9]*-v[1-9][0-9]*$")
TOKEN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
SHA256 = re.compile(r"^[0-9a-f]{64}$")
HASH_STEM = re.compile(r"^[0-9a-fA-F]{32,}$")
COPY_SUFFIX = re.compile(r"(?: |\()\d+\)?(?=\.[^.]+$)")
RECEIPT_NAME = "aimee-authored-source-receipt.json"
SCHEMA_VERSION = "aimee-authored-source-receipt-v1"
ALLOWED_ROOT_FILES = {"README.md"}
ALLOWED_TEMPLATE_FILES = {
    "README.md",
    "aimee-authored-source-receipt-v1.schema.json",
    "aimee-authored-source-receipt-v1.template.json",
}
# Empty by design. Aimee may later approve one exact canonical intake fingerprint in review.
# This source-intake authority must never be reused as runtime/final-art approval.
APPROVED_AIMEE_AUTHORED_SOURCE_RECEIPT_SHA256: set[str] = set()


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_object(path: Path) -> tuple[dict[str, object] | None, str | None]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        return None, f"receipt is not readable JSON: {path}: {error}"
    if not isinstance(value, dict):
        return None, f"receipt must be a JSON object: {path}"
    return value, None


def length_prefixed_sha256(fields: list[str]) -> str:
    payload = b"".join(
        f"{len(field.encode('utf-8'))}:{field}".encode("utf-8") for field in fields
    )
    return hashlib.sha256(payload).hexdigest()


def canonical_receipt_fingerprint(receipt: dict[str, object]) -> str | None:
    sources = receipt.get("sources")
    if not isinstance(sources, list) or not all(isinstance(entry, dict) for entry in sources):
        return None
    fields = [
        "bookbinder-aimee-authored-source-intake-v1",
        str(receipt.get("schemaVersion", "")),
        str(receipt.get("packID", "")),
        str(receipt.get("provenanceClass", "")),
        str(receipt.get("author", "")),
        str(receipt.get("aimeeAuthorshipReceiptSHA256", "")),
        "true" if receipt.get("runtimeAuthority") is True else "false",
        "true" if receipt.get("gameplayAuthority") is True else "false",
        str(receipt.get("gameWikiDisclosure", "")),
    ]
    normalized = [
        tuple(str(entry.get(key, "")) for key in (
            "stableID", "variant", "path", "sourceFileSHA256"
        ))
        for entry in sources
    ]
    for entry in sorted(normalized):
        fields.extend(entry)
    return length_prefixed_sha256(fields)


def validate_pack(
    root: Path,
    pack: Path,
    approved_fingerprints: set[str] = APPROVED_AIMEE_AUTHORED_SOURCE_RECEIPT_SHA256,
) -> list[str]:
    errors: list[str] = []
    if not PACK.fullmatch(pack.name):
        return [f"non-semantic pack directory: {pack.relative_to(root)}"]
    receipt_path = pack / RECEIPT_NAME
    if not receipt_path.is_file():
        return [f"pack lacks explicit Aimee-authored receipt: {pack.relative_to(root)}"]
    receipt, error = load_object(receipt_path)
    if error:
        return [error]
    assert receipt is not None
    allowed_keys = {
        "$schema", "schemaVersion", "packID", "provenanceClass", "author",
        "aimeeAuthorshipReceiptSHA256", "runtimeAuthority", "gameplayAuthority",
        "gameWikiDisclosure", "sources",
    }
    extras = set(receipt).difference(allowed_keys)
    if extras:
        errors.append(f"receipt has unsupported fields {sorted(extras)}: {receipt_path}")
    exact = {
        "schemaVersion": SCHEMA_VERSION,
        "packID": pack.name,
        "provenanceClass": "human-authored-editable-source",
        "author": "aimee-pepper",
        "runtimeAuthority": False,
        "gameplayAuthority": False,
    }
    for key, expected in exact.items():
        if receipt.get(key) != expected:
            errors.append(f"receipt {key} must equal {expected!r}: {receipt_path}")
    receipt_hash = receipt.get("aimeeAuthorshipReceiptSHA256")
    if not isinstance(receipt_hash, str) or not SHA256.fullmatch(receipt_hash):
        errors.append(f"receipt lacks canonical Aimee authorship SHA-256: {receipt_path}")
    if receipt.get("gameWikiDisclosure") not in {"withheld", "disclosed"}:
        errors.append(f"receipt gameWikiDisclosure must fail closed: {receipt_path}")
    sources = receipt.get("sources")
    if not isinstance(sources, list) or not sources:
        errors.append(f"receipt must list at least one source: {receipt_path}")
        sources = []

    declared: set[str] = set()
    for entry in sources:
        if not isinstance(entry, dict) or set(entry) != {
            "stableID", "variant", "path", "sourceFileSHA256"
        }:
            errors.append(f"source entry has invalid fields: {receipt_path}")
            continue
        stable_id, variant, relative, expected_hash = (
            entry.get("stableID"), entry.get("variant"), entry.get("path"),
            entry.get("sourceFileSHA256"),
        )
        if not isinstance(stable_id, str) or not TOKEN.fullmatch(stable_id):
            errors.append(f"source stableID is not semantic: {entry!r}")
            continue
        if not isinstance(variant, str) or not TOKEN.fullmatch(variant):
            errors.append(f"source variant is not semantic: {entry!r}")
            continue
        if not isinstance(relative, str):
            errors.append(f"source path is missing: {entry!r}")
            continue
        expected_prefix = f"AssetSources/{pack.name}/{stable_id}/{variant}/source/"
        posix = PurePosixPath(relative)
        filename = posix.name
        if (posix.is_absolute() or ".." in posix.parts or not relative.startswith(expected_prefix)
                or len(posix.parts) != 6):
            errors.append(f"source path violates semantic intake layout: {relative}")
            continue
        if COPY_SUFFIX.search(filename) or HASH_STEM.fullmatch(Path(filename).stem):
            errors.append(f"source filename is not human-navigable: {relative}")
        if not TOKEN.fullmatch(Path(filename).stem):
            errors.append(f"source filename stem is not semantic: {relative}")
        if relative in declared:
            errors.append(f"duplicate source path in receipt: {relative}")
        declared.add(relative)
        absolute = root / relative
        if not absolute.is_file():
            errors.append(f"declared source is missing: {relative}")
        elif not isinstance(expected_hash, str) or not SHA256.fullmatch(expected_hash):
            errors.append(f"source lacks canonical SHA-256: {relative}")
        elif file_sha256(absolute) != expected_hash:
            errors.append(f"source byte hash does not match receipt: {relative}")

    actual = {
        path.relative_to(root).as_posix()
        for path in pack.rglob("*")
        if path.is_file() and path.name != RECEIPT_NAME
    }
    for relative in sorted(actual.difference(declared)):
        errors.append(f"unreceipted file in Aimee-authored intake: {relative}")
    for relative in sorted(declared.difference(actual)):
        if not (root / relative).is_file():
            continue
        errors.append(f"receipt/source accounting mismatch: {relative}")
    fingerprint = canonical_receipt_fingerprint(receipt)
    if fingerprint is None or fingerprint not in approved_fingerprints:
        suffix = f" (canonical fingerprint {fingerprint})" if fingerprint is not None else ""
        errors.append(
            f"Aimee-authored intake receipt is not explicitly approved: "
            f"{pack.relative_to(root)}{suffix}"
        )
    return errors


def project_exclusion_errors(root: Path) -> list[str]:
    errors: list[str] = []
    for relative in ("project.yml", "Bookbinder.xcodeproj/project.pbxproj"):
        path = root / relative
        if path.is_file() and "AssetSources" in path.read_text(encoding="utf-8"):
            errors.append(f"AssetSources must not be an app/Xcode resource: {relative}")
    return errors


def validate(
    root: Path,
    approved_fingerprints: set[str] = APPROVED_AIMEE_AUTHORED_SOURCE_RECEIPT_SHA256,
) -> list[str]:
    intake = root / "AssetSources"
    if not intake.is_dir():
        return ["AssetSources intake root is missing"]
    errors = project_exclusion_errors(root)
    root_files = {path.name for path in intake.iterdir() if path.is_file()}
    for name in sorted(root_files.difference(ALLOWED_ROOT_FILES)):
        errors.append(f"unexpected file at AssetSources root: AssetSources/{name}")
    templates = intake / "_templates"
    if not templates.is_dir():
        errors.append("AssetSources/_templates is missing")
    else:
        template_files = {path.name for path in templates.iterdir() if path.is_file()}
        if template_files != ALLOWED_TEMPLATE_FILES:
            errors.append("AssetSources/_templates does not match the reviewed scaffold")
    for child in sorted(intake.iterdir()):
        if child.is_dir() and child.name != "_templates":
            errors.extend(validate_pack(root, child, approved_fingerprints))
    return errors


def write_valid_pack(root: Path) -> Path:
    source = root / "AssetSources" / "Portraits-v1" / "sabine" / "cameo" / "source" / "sabine-cameo.png"
    source.parent.mkdir(parents=True)
    source.write_bytes(b"hand-authored-test-pixels")
    receipt = {
        "schemaVersion": SCHEMA_VERSION,
        "packID": "Portraits-v1",
        "provenanceClass": "human-authored-editable-source",
        "author": "aimee-pepper",
        "aimeeAuthorshipReceiptSHA256": "a" * 64,
        "runtimeAuthority": False,
        "gameplayAuthority": False,
        "gameWikiDisclosure": "withheld",
        "sources": [{
            "stableID": "sabine", "variant": "cameo",
            "path": source.relative_to(root).as_posix(),
            "sourceFileSHA256": file_sha256(source),
        }],
    }
    receipt_path = root / "AssetSources" / "Portraits-v1" / RECEIPT_NAME
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    return receipt_path


def self_test() -> None:
    def seed(root: Path) -> None:
        templates = root / "AssetSources" / "_templates"
        templates.mkdir(parents=True)
        (root / "AssetSources" / "README.md").write_text("intake\n")
        for name in ALLOWED_TEMPLATE_FILES:
            (templates / name).write_text("template\n")
        (root / "project.yml").write_text("sources:\n  - path: Sources\n")
        (root / "Bookbinder.xcodeproj").mkdir()
        (root / "Bookbinder.xcodeproj" / "project.pbxproj").write_text("Sources\n")

    with tempfile.TemporaryDirectory(prefix="bookbinder-asset-source-intake-") as directory:
        root = Path(directory)
        seed(root)
        receipt = write_valid_pack(root)
        payload = json.loads(receipt.read_text())
        fingerprint = canonical_receipt_fingerprint(payload)
        assert fingerprint is not None

        # A structurally valid self-assertion is still forged with the reviewed allowlist empty.
        forged_errors = validate(root)
        assert any("not explicitly approved" in error for error in forged_errors)
        # Only the exact content-bound fingerprint closes the intake gate.
        assert not validate(root, {fingerprint})

        payload["author"] = "generator"
        receipt.write_text(json.dumps(payload))
        assert validate(root, {fingerprint})
        payload["author"] = "aimee-pepper"
        payload["provenanceClass"] = "procedural"
        receipt.write_text(json.dumps(payload))
        assert validate(root, {fingerprint})
        payload["provenanceClass"] = "human-authored-editable-source"
        payload["runtimeAuthority"] = True
        receipt.write_text(json.dumps(payload))
        assert validate(root, {fingerprint})
        payload["runtimeAuthority"] = False
        payload["sources"][0]["sourceFileSHA256"] = "b" * 64
        receipt.write_text(json.dumps(payload))
        assert validate(root, {fingerprint})
        payload["sources"][0]["sourceFileSHA256"] = file_sha256(
            root / payload["sources"][0]["path"]
        )
        receipt.write_text(json.dumps(payload))
        source = root / payload["sources"][0]["path"]
        source.write_bytes(b"wrong-bytes-after-approval")
        assert any("byte hash does not match" in error for error in validate(root, {fingerprint}))
        (root / "project.yml").write_text("resources:\n  - AssetSources\n")
        assert validate(root, {fingerprint})

    with tempfile.TemporaryDirectory(prefix="bookbinder-asset-source-intake-") as directory:
        root = Path(directory)
        seed(root)
        (root / "AssetSources" / "Portraits-v1").mkdir()
        assert validate(root)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        print("AssetSources intake verifier self-test passed")
        return 0
    if not args.check:
        parser.error("choose --check or --self-test")
    root = Path.cwd()
    errors = validate(root)
    if errors:
        print("AssetSources intake check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("AssetSources intake check passed (0 authored packs; scaffold only)" if not any(
        child.is_dir() and child.name != "_templates" for child in (root / "AssetSources").iterdir()
    ) else "AssetSources intake check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
