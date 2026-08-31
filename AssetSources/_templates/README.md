# Pack-local receipt template

Copy `aimee-authored-source-receipt-v1.template.json` to the semantic pack root as
`aimee-authored-source-receipt.json`, replace every angle-bracket placeholder, and validate it.
The template is intentionally invalid until Aimee's exact authorship receipt and source hashes are
present. Its schema is `aimee-authored-source-receipt-v1.schema.json`.

The receipt is non-gameplay metadata. Filling in its author and hash fields does not authorize it.
The validator computes a content-bound fingerprint from the exact semantic paths and source bytes;
the pack fails closed until Aimee explicitly approves that fingerprint in the reviewed intake
allowlist. Intake approval does not approve, promote, integrate, or bundle final runtime art.
