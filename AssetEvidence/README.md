# AssetEvidence

This is the human-readable home for non-runtime visual review evidence and generated test artifacts.
It is not an editable-art source root, runtime resource, gameplay authority, or final-art approval
surface. Hashes live in receipts, never in navigation filenames.

Evidence paths use:

```text
AssetEvidence/<family>/<version>/<variant>/review/<semantic-name>.<ext>
```

Each populated variant has one `evidence-receipt.json` beside `review/`. Receipts classify exact
bytes as `review-evidence`, `reference`, `candidate-output`, `generated-test-artifact`, or `blocked`.
Classification and acceptance are separate. `accepted: true` requires a content-bound canonical
fingerprint in the deliberately empty reviewed allowlist. The fingerprint binds the semantic route,
classification, disclosure, fixed-false authority boundaries, complete sorted authority/producer
paths, evidence roles, paths, and exact byte hashes; provenance claims cannot be swapped after review.

AssetEvidence is excluded from app resources. It cannot establish source authorship, runtime
inclusion, gameplay approval, or final-art acceptance. GameWiki may show disclosed records only as
a derived read-only view and never becomes evidence or gameplay authority.

Run:

```sh
python3 Scripts/verify_asset_evidence.py --check
python3 Scripts/verify_repository_organization.py --check
```
