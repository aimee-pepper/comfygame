# Coordinated fleshy plant distribution — morphology3

8 September2026. **Accepted intended implementation contract; not delivered.** PM assigns this independent continuation of Aimee's plants-should-look-more-real direction. Exact ratios are Design/Asset first-pass tuning, not new choices attributed to Aimee. Engineering's creature-disclosure integration continues independently. Current phone361 retains the bounded morphology2/component6 correction delivered360.

## Evidence and scope

Reviewed existing360 matched needle ordinary, frond close and basal ordinary images, Engineering's source and Asset39b51c6c/bf6e813e diagnosis. No new capture or artwork. ModularFloraFormV2 currently leaves the full h fleshy stem above branches rooted at .4125h… .55h, uses a common c×.40 leaf-length cap and attaches branch-owned leaves at centerline points in the terminal30%. Retained frond width .06496 is smaller than its .0775 branch diameter. Retained needle/frond fixtures use rosette72-degree tilt, not the default50.4 degrees. The renderer is a generic frozen recipe consumer; it must not fix this with camera-facing shapes.

This coherent revision applies only to **fleshy + leaf-bearing blade/broad/needle/frond**, where the source has branches OR is unbranched with alternate/opposed/whorled growth. Unbranched basal rosettes remain exactly morphology2, including dimensions, contacts and poses. Growth-absent fleshy forms, all woody/fibrous/fungal/chemical forms, cap/spore correction and existing source validation remain unchanged. Branched rosette means a cluster on each existing branch; it does not turn the entire plant into a ground rosette.

## 1. Source dimensions and stem

Keep source h=.12+2.38×stature/100, c=.12+.43×stature/100 and r=.025+.075×max(woody,fibrous,fleshy)/100. Freeze no new anatomy, random choice or trait. For the scoped forms:

- Main stem height H=.70h; base diameter remains2r. Reuse actual flora.fleshy.stem revision1 with straight axial taper1→.45, zero bend.
- Leaf base length L=min(saved leafLength,.30h,.65c). This releases the old c×.40 bottleneck without exceeding saved length. Keep existing cohorts .80/1/.90 and membership: old g=item/2 for opposed, otherwise g=item; cohort=g mod3.
- Keep actual meshes and aspect mappings: blade[.20L,L,.012], needle[.012,L,.012], broad[.60L,L,.02], frond[.35L,L,.018], multiplied by their existing cohort factor. No frond widening or new export in this pass.

The shorter stem and stronger taper let the existing crown define the upper silhouette. h remains a source-derived layout reference, not a claim every rotated leaf vertex lies belowY=h. Actual evaluated mesh bounds stay authoritative; no camera-scale compensation or automatic rescaling of the whole finished plant.

## 2. Existing branches form one coordinated crown

Retain branching.none/sparse/repeated counts0/2/4, existing stable branch IDs and uniform azimuth phi=2πi/N. Dense fleshy branching remains invalid. For N>0 let u=i/(N−1):

1. Root height y=H×(.40+.55u), spanning the middle through upper stem. Seat at that height/azimuth on the actual evaluated supporting stem, with .001h inward overlap.
2. **branchAngle means inclination from parent+Y**, in degrees, for this new morphology only. Do not mutate the saved number or preserve the old mismatched .65c-rise/.55c-reach interpretation. Let theta be that saved20…65-degree angle.
3. Target radial reach R0=.55c×(1−.25u). Set rise=min(R0/tan(theta),h−y−L), reach=rise×tan(theta), length B=hypot(reach,rise). The existing domain guarantees positive nominal rise allowance: highest root=.665h and L≤.30h. Both components shorten together when the allowance binds, preserving the exact angle. This is a nominal centerline/leaf-length allowance, not a full rotated-mesh bound proof.
4. Base branch diameter D=min(r,.70×actual supporting-stem diameter at this root,.22B). Use the supporting cross-section along the attachment direction after taper, not coreWidth or a pre-taper bounding cylinder. The length cap prevents tiny/steep branches becoming thick disks. Reuse the same actual foliage stem mesh for these existing branch IDs, with taper1→.35 and zero bend.

Preserve source material role, existing owner chain, branch count and growth count per branch. No secondary branches, added tips, manufactured terminal leaves or population change. Explicitly map the existing mesh to scoped branch IDs in morphology3; its current importer admits base-pivot cylinder/valid axialProfile/foliage without a support-ID restriction. The216-triangle export and resource hash stay unchanged.

## 3. Arrangement and actual leaf seating

Retain source arrangement and angular sequence: opposed partners at phi=0/π plus existing pair×.20 rotation; alternate phi=item×2.399963; whorled/rosette phi=2πitem/count. Opposed partners share a node. Cohort allocation remains the original per-item grouping even where several groups share a node.

**Branch-owned growth:** alternate groups and opposed pair groups use t=.25+.65u over the actual branch length, where u=group/(groups−1). Whorled uses one same-height ring at t=.60; all saved members remain in that whorl. Branch-owned rosette uses one terminal cluster at t=.85, with its existing radial order. Do not spread a true whorl/rosette into an accidental spiral or invent an independent tier count.

**Unbranched scoped stems:** alternate/opposed nodes span .35H to yTop. Define top group's actual cohort length Ltop; yTop=H−min(.06H,.50Ltop×cos(.28π)). Use the same normalized group order. Whorled puts all members at that same upper node, using the smallest existing cohort length for Ltop; it does not fabricate multiple whorls. This keeps a short leader above the top leaves even for a source with genuinely short leaves. Basal rosettes are excluded and retain their current .20h support/.10support-height roots exactly.

Every scoped leaf root is on its **actual owner surface**, not rootPose's centerline. Query the owner in its local evaluated frame, including its actual mesh and taper; attach it through the unchanged owner transform once. At the designated axial height cast along outward radial N and inset .001h. Missing/nonfinite contact refuses the candidate visibly to Engineering: no centerline fallback, moved source part, guessed ellipsoid or deleted leaf. An attached Part must be evaluated as a local owner mesh for this query; a helper that filters attached parts out cannot be passed the untouched world-attached Part.

Define owner tangent T and outward radial N in the owner-local anatomical frame. Keep arrangement tilt alpha=.40π for branch-owned rosette, otherwise .28π. Set leaf+Y=cos(alpha)T+sin(alpha)N. For flat blade/broad/frond growth set leaf+X=normalize(T×N), leaf+Z=X×Y. Build that frame once; do not apply the old signed tilt/yaw a second time. Breadth runs around the owner while length extends outward/up its local frame. Needles retain a narrow radial presentation with the same outward longitudinal direction; their stable cross-section roll may use that frame too. Nothing billboards toward the camera, world north or a light.

## 4. Dependent sockets, custody and versions

Rebuild branch/growth/socket transforms consistently before freezing. Existing blossom/fruiting display stays on the same first growth owner and follows its new first-repetition frame using the existing relative socket rule and existing extent/count. Do not leave a display at stale world coordinates or invent a terminal flower. Growth-absent display rules and fungal spore contact remain exact360. This does not claim a new detailed flower/fruit attachment grammar. Thorn roots retain their source count/height rule and are reseated against the scoped new stem with the existing contact overlap; no newly floating fallback.

Freeze **flora morphology3/component6** only for newly written books after the consolidated implementation passes. Extend the accepted pair validation explicitly; never reinterpret morphology2 or older component values. Runtime recipe formRevision2, source structure1, family1, creature form2 and surface2 stay unchanged. New morphology3 uses the already admitted component6 set, including the newly mapped existing branch role; no component resource or revision is replaced. Old nil/1/2 books, unfinished worlds, recorded observations and offscreen memory reconstruct their exact older forms.

No change to source stature/tissue/defence, names, colour/Pattern/Finish, material identity/quality, harvest quantities, prices, recipes, occupancy, reach, source distribution or knowledge. Larger visible leaves do not grant extra fibre or different loot. No new RNG streams, per-frame composition, world edits or camera fitting. Preserve64 parts/128 instances/128 sockets/16,384 triangles and validate actual instantiated mesh totals, including216-triangle branches; do not silently reduce repetition to fit.

## 5. Retained arithmetic and focused acceptance

Retained source: h2.024/r.0775/c.464, branchAngle45, repeated4, rosette8, savedL.30. Before: H2.024, branchroots.8349…1.1132, highest branch tip1.4148, L.1856, largest frond width.06496. New nominal values:

| Branch | RootY | Reach/rise at45° | Length | Base diameter after all caps |
| --- | --- | --- | --- | --- |
| 0 | .566720 | .255200 | .360907 | .077500 |
| 1 | .826467 | .233933 | .330832 | .072783 |
| 2 | 1.086213 | .212667 | .300756 | .062749 |
| 3 | 1.345960 | .191400 | .270680 | .051809 |

H becomes1.4168, highest branch tip1.53736, L.30 and largest frond width.105 with unchanged .35aspect. Root span widens while the bare leader shortens; tapered branch diameter at a rosette node is roughly.03468… .02318 before exact mesh evaluation. Source counts remain32 leaves, not added foliage. Arithmetic is design evidence, not native geometry or perceptual acceptance. Checked432 source/angle/count combinations for positive nominal dimensions and1,296 including tissue-radius extrema for nominal owner radius versus overlap; actual mesh/contact validation remains required. Small sources stay small, short-leaf sources stay short, rear leaves may still occlude and source-owned neutral colours stay neutral.

Engineering extends existing focused tests for angle/pose/source count, arrangement nodes and cohorts, owner-surface contacts, role/budget validation, first-display/thorn transform custody, and old/new book/observed-memory round-trip. Source-absent exclusions and short-stature/angle envelope use existing test constructors; no new player trial or biological census. Reuse the same retained needle/frond/basal fixtures for one affected before360/after3 close+ordinary native comparison; the unchanged basal is a control. Add an existing unbranched alternate/opposed/whorled source only where needed to demonstrate that changed branch of the policy, not a new random-world search. Asset reviews those same outputs at actual target/default/current appearance with the actual capture device recorded. No Design duplicate capture, mesh reauthoring or configuration matrix. Do not wait on a phone launch or claim final realism from a bounded pass.

## What existing geometry can and cannot establish

This accepted batch corrects crown placement, support/branch proportions, leaf base embedding, meaningful saved-length expression and anatomical broad-face orientation using existing source facts. It can make existing needles and lobed fronds more distinguishable; it cannot guarantee every source is distinguishable at ordinary scale or fill every plant with foliage.

**Unsettled future grammar, not assigned or adopted:** independently variable secondary branching, multiple stems, storage/cactus organs, separate needle fascicles or compound leaflet counts, multiple independent whorl tiers, detailed reproductive organs and purposeful dead/bare leaders would require additional source-owned structures and dependent material/knowledge decisions. Existing frond contour lobes remain one member, not separately harvested leaflets. This batch does not infer those features, turn every fleshy plant into a cactus or every frond source into a complete fern, or add lifecycle/food/nesting simulation. These are future design topics, not an Aimee approval queue or blockers for this correction.
