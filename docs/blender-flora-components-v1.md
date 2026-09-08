# Blender flora components v1 — woody leaf and branch

7 September 2026. **Implementation brief within settled morphology v2. Import seam required before final Asset production.** PM relayed Aimee’s request to advance reusable Blender flora components. This implements the accepted Blender-authoring/runtime-assembly workflow; it does not select new biology, generation probabilities or gameplay.

## Authority and actual consumer

Use `procedural-life-form-batch-v2.md` for frozen forms, ordered roots, cohorts, display attachments and budgets. This optional imported-component seam supersedes that completed batch’s primitive-only restriction only for the named admitted roles, under Aimee’s newer Blender workflow; `shared-3d-life-readability-v1.md` for disclosure; Aimee’s Blender authoring instruction for production. Current source inspected in Engineering’s field-notification-copy worktree, delivered346 source8f9c2c8c:

- `Sources/Rules/ModularFloraFormV2.swift` freezes support, branch, growth and display geometry from existing traits.
- `Sources/Model/RuntimeAssemblyRecipe.swift` contains primitive shape/size/pivot, rigid poses, repetitions, material facts and optional axial profiles. It has no imported component reference.
- `Sources/Rules/RuntimePrimitiveMesh.swift` supplies the CPU geometry used by `RuntimeAssemblyRenderer`, `RuntimeBodySurface` and associated bounds/contact code. `RuntimeAxialMesh` owns centreline, tangent, taper and marked-tip semantics.
- `Sources/VisualRuntime/RuntimeAssemblyRenderer.swift` reconstructs that recipe in the existing Settings → Owner Tools → 3D Trials → Ordinary expedition view. Resource-node USDZ import is a separate consumer and does not establish flora support.

Asset independently confirmed the same gap in `woody-blender-component-seam-2026-09-07.md`, checkpoint3c2cbb66. Its normalized frame,192/216-triangle ceilings, exact profile evaluation and UV orientation are accepted by this brief. Engineering must name and implement the shared imported-geometry seam before final component exports are accepted. Literal geometry belongs to Asset in Blender. Engineering owns loading, shared deformation, validation, recipe persistence and native integration.

## First production pair

These are component keys, not species names or new material identities. Revision1 is frozen with the reference; subsequent asset changes require an explicit revision rather than replacing the appearance of old saved plants.

| Component | Exact admitted consumer and visual deficiency | Authored geometry and material role | Existing runtime dimensions |
|---|---|---|---|
| `flora.woody.broad-leaf`, revision1 | Woody + broad growth, each existing `growth-*` cohort member. Thin ellipsoids lack a readable leaf outline. | One broad leaf with a coherent tip, base and restrained fold/edge contour; no twig, flower, fruit, thorn or attached extra leaves. One `foliage` role. | Base-pivot local size `[0.60L, L, 0.02]` times the existing cohort factor; `L=min(leafLength, 0.25h, 0.65c)` for broad woody growth. |
| `flora.woody.branch`, revision1 | Existing broad-growth woody `branch-*` support in this first admission. A plain cylinder lacks authored branch character. | One straight neutral rest branch, joined base/end cross-sections and a readable restrained surface/outline; no baked branchlets, leaves, root mound or extra logical support. One `wood` role. | Existing `[r, branchLength, r]`, existing branch pose/base offset, axial startScale1/endScale0.55 and existing projected bend magnitude0.03. Apply these exactly once. |

Keep the current definitions `h=0.12+2.38(stature/100)`, `r=0.025+0.075(max tissue/100)`, `c=0.12+0.43(stature/100)`. The brief supplies no new proportion controls. Asset owns the contour within these dimensions; elongated/wide source variation and cohort scale remain runtime-owned.

## Attachment frame and export

Output one editable `.blend` source with clearly named component collections and one UTF-8 JSON mesh per component. Blender is the source of vertices, faces, UVs and rest normals. Optional USDZ is a review artifact until Engineering establishes equivalent shared CPU extraction; a renderer-only USDZ replacement is insufficient.

**Normalized export frame:** metres/unit scale1; local +Y runs base→tip, +X is width, +Z is depth. Base/contact origin `(0,0,0)`, longitudinal extent `Y=0…1`, transverse envelope `X/Z=-0.5…+0.5`. Apply Blender object transforms on export. The imported mesh is subsequently scaled by the existing recipe `Part.size`; never encode final plant height, world position, branch angle or cohort scale into the source file. Leaf thickness comes from its existing Z size; preserve a closed/readable thin form within that envelope without adding a new opacity mode.

The JSON schema must carry component ID, revision, schema version, positions (float3), normals (float3), UVs (float2), triangle indices and one declared material role. Arrays are finite, indices valid, attribute lengths agree, and bounds/triangle counts derive from actual exported geometry. For Pattern compatibility, leaf UV.v=`1-t` matches the replaced ellipsoid direction; branch UV.v=`t` matches the axial profile. Keep that orientation on both leaf faces. Asset owns sensible U placement/UV seams; do not bake the source Pattern into a texture or flip the V convention per instance. The export audit includes the source/export hashes and measured bounds. Engineering owns the concrete loader/API names, but the required payload and frame are fixed by this brief. No absolute project paths or export-machine identifiers enter saved recipes.

Leaf geometry is scaled and placed at each existing growth root using its actual tangent frame, arrangement angle and tilt. Preserve the three current cohorts0.80/1/0.90, opposed-pair membership and exact saved repetition counts. Do not attach an authored crown containing multiple leaves to one source leaf. The display socket follows the same first growth instance as today; imported leaf bounds must not independently relocate it.

The branch JSON is a **rest mesh**. No baked1→0.55 taper or0.03 bow: runtime applies the exact existing axial profile once. Every vertex uses the existing centreline/tangent deformation, and normals are transformed or recomputed consistently. `rootPose`, tip sockets, child root positions, visible branch geometry and bounds/contact must all describe this same result. A bent visible mesh with straight or old primitive contact geometry is a rejection. Keep current terminal30% growth-root distribution and ordered branch bases; authoring does not relocate them to an aesthetically convenient point.

## Minimal Engineering seam

1. Add an optional validated component ID/revision to the frozen part representation and a bundled normalized-mesh library. New eligible recipes may select these two roles; existing saved recipes with no reference reconstruct unchanged. The preview and authoritative builder use the same admitted revision. Storage/schema field names remain Engineering’s responsibility.
2. Resolve authored geometry through the **shared CPU geometry path**, before common size/profile/repetition handling. Rendering, material/UV preparation, bounds, contact, marked tips and triangle accounting must use the same admitted mesh. The library must not become a second body/plant generator.
3. Preserve recipe tint, roughness, source Pattern and material responsibilities. Blender materials cannot bake green/brown, replace source colour, add glow, introduce leaves on bare forms or grant new finishing behavior. `wood` remains unpatterned where the existing recipe says so; `foliage` keeps existing part-local patterning. The slot label alone does not create an extra colour source. Complete opacity/Schiller and cross-part pattern continuity remain separate work.
4. Preserve cache isolation and independently transformed repeated instances. Unknown/missing revisions or malformed geometry must be diagnosed through existing rendering-failure handling, without mutating saved biology, silently dropping a part or adding a player-facing trial. Do not substitute a newer asset revision into an older recipe.
5. Keep existing64-part,128-instance,128-socket and16,384-triangle hard caps. First leaf≤192 triangles; first branch≤216, including backs, caps and any authored detail. No unreferenced vertex payload. Validate actual imported counts times repetitions before allocation. Do not raise caps or erase source groups to fit art.

## Bounded acceptance and handoff

First use Asset’s existing retained woody specimen and native view, not a new world search or menu. The exact target is iPhone16Pro,402×874pt/1206×2622px, default text, its current ordinary appearance. Required outputs: editable Blender source, two revisioned JSON meshes, export manifest/audit, and1206×2622 PNG captures of that specimen at ordinary map scale plus a close view. A reference render outside the app is useful for authoring but does not establish native correctness.

Engineering verifies the new shared seam with real exported geometry: base/tip frame and scale, source-selected tint/Pattern, bent branch plus actual child roots, existing paired/alternate cohorts, display ownership, maxima with all retained source groups, and nil-reference/old-recipe reconstruction. Reuse existing representative cases and normal persistence checks; no configuration matrix, new campaign, anatomical census or independent Design rerun. Asset judges the actual leaf/branch silhouettes and their contact/readability in that same consumer. Phone integration and Aimee visual acceptance remain separate from internal mesh/import evidence.

**Readiness handoff:** Engineering supplies its actual consumer/protocol and one admitted normalized export before Asset finalizes this pair. Asset may prepare the editable Blender collections and authoring layout meanwhile; no finished asset family is declared ready against a nonexistent importer. PM sequences the importer after current urgent work. No additional Aimee decision is required.

## Sequential Asset work after the first seam is ready

These continue the already-declared morphology. Begin each only when its concrete role is admitted by the same importer; use the existing recipe’s counts, frame, dimensions and material facts. Complete and preserve one bounded role before starting the next.

1. Finish the broad woody leaf and neutral woody branch together; verify their actual assembled connection.
2. Woody main support: reuse the normalized axial pipeline for `support`, with its existing size,1→0.70 taper, no bend and existing branch/growth sockets. No roots, extra branches or terrain footprint.
3. Fibrous blade growth: one narrow blade using existing `[0.20L,L,0.012]`, base pivot and `foliage` role. Preserve unbranched upper-support or declared basal-rosette roots; no woody tissue or new harvest type.
4. Needle growth, then frond growth as separate components: use the existing narrow axial needle and frond `[0.35L,L,0.018]` roles/dimensions and declared family allowlists. Neither may replace an absent growth state or turn one frond into extra source members. The needle requires its actual cylinder budget≤48 triangles; frond retains≤192.

Fleshy pads, fungal caps/shelves and chemical plates are subsequent existing roles, but their centred-pivot/surface-contact consumer details must be confirmed before assigning their literal final output. This list supplies continuity without bypassing those real dependencies or reopening settled flora design.
