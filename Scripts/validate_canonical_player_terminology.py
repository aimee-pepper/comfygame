#!/usr/bin/env python3
"""Authority-driven census of current human-visible terminology surfaces."""
from __future__ import annotations
import json, re, sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUTHORITY = ROOT / "docs/canonical-game-terminology.json"
FIXTURES = ROOT / "Scripts/canonical-player-terminology-fixtures.json"
RECEIPT = ROOT / "docs/generated/canonical-player-terminology-census.json"

def norm(value: str) -> str: return re.sub(r"\s+", " ", value).strip().lower()
def present(text: str, alias: str) -> bool:
    return re.search(rf"(?<![a-z]){re.escape(norm(alias))}(?![a-z])", norm(text)) is not None
def static_text(value: str) -> str:
    return re.sub(r"\$\{.*?\}", "", re.sub(r"\\\([^)]*\)", "", value), flags=re.S)
DISPLAY_TOKENS = ("Text(", "Label(", "Button(", "Section(", "Picker(", "Toggle(",
                  "navigationTitle(", "accessibilityLabel(", "accessibilityHint(",
                  "LabeledContent(", "Row(", "Card(title:", "confirmationDialog(", "alert(")
DISPLAY_RULE_FILES = {"TutorialRules.swift", "WorldInspectionRules.swift", "WorldRules.swift",
                      "RecyclerRules.swift", "PageRules.swift", "GameActions.swift",
                      "GameActions+World.swift", "GameActions+Economy.swift"}

def presentation_literals(path: Path) -> list[str]:
    text = re.sub(r"/\*.*?\*/", "", path.read_text(), flags=re.S)
    result = []
    for raw_line in text.splitlines():
        line = re.sub(r"//.*$", "", raw_line)
        matches = list(re.finditer(r'"((?:\\.|[^"\\])*)"', line))
        if not matches: continue
        values = []
        for match in matches:
            prefix = line[:match.start()]
            if re.search(r'(accessibilityIdentifier\(|systemImage:|\.tag\()\s*$', prefix):
                continue
            values.append(match.group(1))
        if path.name == "WritingDeskView.swift" and re.search(r"case \.(target|source|rune|qualifier)(?:,|:)", line):
            values = [value for value in values if value not in {"target", "source", "qualifier"}]
        if not values or "rawValue =" in line: continue
        rel = str(path.relative_to(ROOT))
        ui_surface = any(part in rel for part in ("Sources/Screens/", "Sources/App/", "Sources/Debug/"))
        displayed = any(token in line for token in DISPLAY_TOKENS)
        display_adapter = path.name == "Gambit.swift" and "return " in line
        player_content = path.name == "Page.swift" and any(key in line for key in ("provenance:", "promise:"))
        rule_copy = path.name in DISPLAY_RULE_FILES and any(key in line for key in
                    ("return \"", "case ", "mutate(\"", "mutateIf(\""))
        debug_copy = "Sources/Debug/" in rel and any(key in line for key in ("case ", "return \""))
        human_log = any(token in line for token in ("Logger.", "logger.", "print(", "debugPrint(", "mutate(\"", "mutateIf(\""))
        propagated_error = ("CustomStringConvertible" in text or "LocalizedError" in text) and any(
            token in line for token in ("var description", "errorDescription", "return \""))
        if ui_surface or displayed or display_adapter or player_content or rule_copy or debug_copy or human_log or propagated_error:
            result.extend(values)
    return result

def main() -> int:
    authority = json.loads(AUTHORITY.read_text())
    fixture = json.loads(FIXTURES.read_text())
    concepts = {term["concept"]: term for term in authority["terms"]}
    aliases: dict[str, list[str]] = defaultdict(list)
    for concept, term in concepts.items():
        for alias in term["retire"]: aliases[norm(alias)].append(concept)
    global_phrases = [norm(value) for value in authority["presentationRules"]["globalPhrases"]]
    for phrase in global_phrases:
        aliases[phrase].append("presentationPolicy")
    for alias in aliases: assert present(alias, alias)
    def violates(path: str, value: str, alias: str) -> bool:
        low = norm(static_text(value))
        if any(present(low, phrase) for phrase in global_phrases): return True
        if alias in {"mark", "marks"}:
            return bool(re.search(r"\b(page|writing|placed|erase|move|sigil)s?\b.{0,35}\bmarks?\b|\bmarks?\b.{0,35}\b(page|writing|sigil)s?\b", low))
        if alias in {"target", "source", "qualifier"} and any(name in path for name in
                ("WritingDesk", "PageGrid", "WorldArrival", "world-writing")):
            return True
        if alias == "node":
            return bool(re.search(r"\b(research|combat|constellation|resource) node\b|\bnode (prerequisite|detail|consumer|density)\b", low))
        if alias == "profile":
            return bool(re.search(r"\b(construction|gear|armoury|raw essence|tuning) profile\b|\bprofile.{0,20}(construction|gear)\b", low))
        if alias == "receipt":
            return bool(re.search(r"\b(saved|scaling|test|visual|return|arrival|expedition|roadmap|layout|production) receipt\b|\breceipt (detail|identity)\b", low))
        if alias == "frozen":
            return bool(re.search(r"\bfrozen (receipt|record|ownership|result|inputs|state|page|writing|cost|scaling)\b", low))
        if alias == "legacy":
            return bool(re.search(r"\blegacy (item|page|save|gear|receipt|verdict|campaign|rules|credit|masterwork)\b", low))
        if alias == "base":
            return bool(re.search(r"\b(return|go|back|at|in|to|reset) (the )?base\b|\bbase (hub|town|village|screen)\b", low))
        if alias == "reality":
            return bool(re.search(r"\breality (layer|state|currency|progress)\b|\breset.{0,20}reality\b", low))
        if alias in {"returned", "progress", "party total"}:
            return bool(re.search(r"\b(people|travellers|xp|party) (returned|progress|total)\b|\b(returned|progress)\s*/\s*(none|party total)\b", low))
        return False

    for value in fixture["fail"]:
        assert any(present(value, alias) and violates("fixture/presentation", value, alias) for alias in aliases), value
    for value in fixture["pass"]: assert not any(present(value, alias) for alias in aliases), value
    for row in fixture["ambiguityPass"]:
        assert present(row["literal"], row["alias"]), row
        assert not violates("fixture/ordinary", row["literal"], norm(row["alias"])), row

    exception_rows = fixture["exceptions"]
    exceptions = {(row["path"], row["literal"], norm(row["alias"])): row for row in exception_rows}
    assert len(exceptions) == len(exception_rows), "duplicate exception"
    grouped = {concept: {"canonicalVisible": 0, "retired": {"semanticAllowed": 0, "approved": 0, "violation": 0}}
               for concept in concepts}
    occurrences, scanned = [], []

    def inspect(path: Path, value: str, swift: bool = False) -> None:
        rel, visible = str(path.relative_to(ROOT)), static_text(value) if swift else value
        for concept, term in concepts.items():
            if present(visible, term["canonical"]): grouped[concept]["canonicalVisible"] += 1
        for alias, owners in aliases.items():
            if not present(visible, alias): continue
            key = (rel, value, alias)
            status = "approved" if key in exceptions else "violation" if violates(rel, value, alias) else "semanticAllowed"
            for concept in owners:
                if concept in grouped: grouped[concept]["retired"][status] += 1
            row = {"path": rel, "literal": value, "alias": alias, "classification": status}
            if status == "approved": row["rationale"] = exceptions[key]["rationale"]
            occurrences.append(row)

    swift_paths = sorted((ROOT / "Sources").rglob("*.swift"))
    wiki_paths = [ROOT / "GameWiki/public/app.js", ROOT / "GameWiki/generated/wiki-data.json"]
    doc_paths = [ROOT / "docs/game-wiki-content-contract-current.md"]
    for path in swift_paths:
        scanned.append(str(path.relative_to(ROOT)))
        for value in presentation_literals(path): inspect(path, value, True)
    raw_value_patterns = {
        "Combat Skill state": r"(?:state|nodeState|state\([^\n]+\))\.rawValue",
        "Combat Skill refusal": r"(?:refusal\s*=\s*reason|PurchaseRefusal\.[A-Za-z]+)\.rawValue",
        "saved dodge result": r"resolution\.rawValue",
        "Focus picker": r"inkEligibleSourceID[^\n]*rawValue",
        "campaign phase": r"campaignPhase\?\.rawValue",
        "Stability state": r"(?:band|stabilityBand)\.rawValue",
        "World tuning preset": r"(?:rawEssenceProfile|encounterScalingProfile|openingEncounterEnvelope)\.rawValue",
        "Subject picker fallback": r"pressureTarget\([^\n]+\)\?\.name\s*\?\?\s*[^\n]*rawValue",
    }
    raw_value_violations = []
    for path in swift_paths:
        rel, source = str(path.relative_to(ROOT)), path.read_text()
        if not any(part in rel for part in ("Sources/Screens/", "Sources/Debug/")): continue
        for label, pattern in raw_value_patterns.items():
            for match in re.finditer(pattern, source):
                raw_value_violations.append({"path": rel, "kind": label, "expression": match.group(0)})
    for probe in ("Text(state.rawValue)", 'refusal = reason.rawValue',
                  'Text("Result \\(attempt.resolution.rawValue)")',
                  'Text("\\(band.rawValue)")',
                  'Text(tuning.rawEssenceProfile.rawValue)',
                  'pressureTarget(id)?.name ?? id.rawValue'):
        assert any(re.search(pattern, probe) for pattern in raw_value_patterns.values()), probe
    content_paths = sorted(path for path in (ROOT / "Sources/Content/Data").glob("*.json")
                           if path.name != "design-homework.json")
    visible_json_fields = {"name", "title", "label", "subtitle", "blurb", "description",
                           "detail", "gate", "message", "promise", "provenance", "text", "body", "copy"}
    def inspect_content(value, key=""):
        if isinstance(value, dict):
            for child_key, child in value.items(): inspect_content(child, child_key)
        elif isinstance(value, list):
            for child in value: inspect_content(child, key)
        elif isinstance(value, str) and key in visible_json_fields:
            inspect(current_content_path, value)
    for current_content_path in content_paths:
        scanned.append(str(current_content_path.relative_to(ROOT)))
        inspect_content(json.loads(current_content_path.read_text()))
    app_path = wiki_paths[0]
    assert app_path.exists(), app_path
    scanned.append(str(app_path.relative_to(ROOT)))
    for value in re.findall(r'(["`])((?:\\.|(?!\1).)*)\1', app_path.read_text(), flags=re.S):
        inspect(app_path, value[1])
    for path in doc_paths:
        assert path.exists(), path
        scanned.append(str(path.relative_to(ROOT)))
        for line in path.read_text().splitlines():
            stripped = line.strip()
            # Authority tables/backticked retired examples define the migration; they are not rendered copy.
            if stripped and not stripped.startswith("|") and "`" not in stripped:
                inspect(path, stripped)
    wiki_data = wiki_paths[1]
    assert wiki_data.exists(), wiki_data
    scanned.append(str(wiki_data.relative_to(ROOT)))
    wiki = json.loads(wiki_data.read_text())
    visible_fields = {
        "terminology": ("name", "summary", "domain", "whereItAppears"),
        "stations": ("name", "blurb", "summary", "purpose"), "travellers": ("name", "calling", "summary"),
        "items": ("name", "blurb", "summary", "description"),
        "symbols": ("name", "summary", "playerKind", "acquisition", "writability", "disclosure", "expansion", "attachesTo"),
        "resources": ("name", "summary", "drivenBy", "requires", "favours", "currentUses"),
        "search": ("name", "category", "disposition")
    }
    for collection, fields in visible_fields.items():
        assert collection in wiki, f"missing generated visible collection {collection}"
    def inspect_rendered_value(value):
        if isinstance(value, str):
            inspect(wiki_data, value)
        elif isinstance(value, list):
            for child in value: inspect_rendered_value(child)
        elif isinstance(value, dict):
            for child in value.values(): inspect_rendered_value(child)
    for collection, fields in visible_fields.items():
        for row in wiki.get(collection, []):
            for field in fields:
                inspect_rendered_value(row.get(field))

    used = {(row["path"], row["literal"], row["alias"]) for row in occurrences
            if row["classification"] == "approved"}
    assert not set(exceptions) - used, f"stale exceptions: {sorted(set(exceptions) - used)}"
    violations = sorted((row for row in occurrences if row["classification"] == "violation"),
                        key=lambda row: (row["path"], row["literal"], row["alias"]))
    receipt = {
        "schemaVersion": 2, "authority": str(AUTHORITY.relative_to(ROOT)),
        "scope": {
            "swift": "all Sources/**/*.swift discovered; UI/App/DEBUG literals plus display adapters, player content, localized rule copy, accessibility copy, Logger and mutation trails; comments/interpolated identifiers and exact non-visible identifier/icon/tag arguments excluded",
            "contentJSON": "player-facing name/title/blurb/description/detail/gate/message/promise/provenance fields",
            "wiki": [str(path.relative_to(ROOT)) for path in wiki_paths],
            "currentDocumentation": [str(path.relative_to(ROOT)) for path in doc_paths],
            "documentationAuthorityDeclarations": "canonical terminology authority and tables/backticked retired examples excluded",
            "wikiGeneratedVisibleFields": visible_fields,
            "historicalDocumentation": "archive/session/history documents excluded by path"
        },
        "scannedFileCount": len(scanned), "scannedPaths": sorted(scanned),
        "exceptions": exception_rows, "concepts": grouped,
        "approvedContextFixtures": fixture["ambiguityPass"],
        "rawValueDisplayAudit": {"policy": "model/combat/catalogue raw values require a player-copy adapter; exact local UI-label enums and secondary Internal ID fields remain allowed", "violations": raw_value_violations},
        "retiredOccurrences": sorted(occurrences, key=lambda row: (row["path"], row["literal"], row["alias"])),
        "unapprovedOccurrences": violations
    }
    rendered = json.dumps(receipt, indent=2, ensure_ascii=False) + "\n"
    if "--check" in sys.argv:
        if not RECEIPT.exists() or RECEIPT.read_text() != rendered:
            print("canonical terminology census is stale", file=sys.stderr); return 1
    else:
        RECEIPT.parent.mkdir(parents=True, exist_ok=True); RECEIPT.write_text(rendered)
    if violations or raw_value_violations:
        for row in violations: print(f"{row['path']}: {row['literal']} [{row['alias']}]", file=sys.stderr)
        for row in raw_value_violations: print(f"{row['path']}: {row['expression']} [{row['kind']}]", file=sys.stderr)
        return 1
    print(f"Canonical terminology census: {len(concepts)} concepts, {len(scanned)} files, "
          f"{len(exception_rows)} exact exceptions, 0 unapproved occurrences.")
    return 0

if __name__ == "__main__": raise SystemExit(main())
