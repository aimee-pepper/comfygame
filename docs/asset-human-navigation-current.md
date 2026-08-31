# Visual asset human navigation — current organization audit

**Audited revision:** `92bd529016a67b57c19891ed1657cadcf12ea598`
**Scope:** repository organization only; no art, runtime, project, schema, or GameWiki authority change.

## Finder and Xcode paths for humans

- Future explicitly approved hand-authored editable sources belong under
  `AssetSources/<pack-vN>/<stable-id>/<variant>/source/<semantic-name>.<ext>`. The pack receipt is
  provenance metadata, not runtime or final-art approval. The reviewed-source allowlist is empty.
- Non-runtime review evidence belongs under
  `AssetEvidence/<family>/<version>/<variant>/review/<semantic-name>.<ext>`. Evidence acceptance,
  source authorship, runtime authority, gameplay authority, and final-art acceptance remain separate.
- Current integration candidates, regardless of production method, remain under
  `AssetLab/integration/<family>/`. Production method is proven only by the exact receipt/authority;
  it is never inferred from folder location or file format. A human artist should not edit an
  `assets/<sha>` blob or infer approval from the word `integration`.
- App-consumed promoted pack manifests are at `RuntimePacks/<Pack-vN>/manifest.json`. Humans navigate
  by that semantic manifest; `assets/<sha>` is content-addressed integrity storage and is never renamed.
- `GameWiki` is a disclosed, read-only derived view. It is neither the source tree, promotion gate,
  gameplay authority, nor runtime asset locator.

## Map-slice authority audit

`AssetLab/scripts/export-map-slice.mjs`, `AssetLab/tests/map-slice-export.test.js`,
`Tests/WorldTests.swift`, `docs/top-down-map-asset-integration-current.md`, and the current decision
record all select `AssetLab/integration/map-slice-v1/manifest.json` as the semantic manifest path.

The two tracked manifests are not byte duplicates:

- `manifest.json`: file SHA-256
  `a6fc22dcba0673aaa656c3a22ba6b76145b2f851965cf5eea1ca599af1757329`, canonical-body SHA-256
  `6d0c21206a983d024a4b948fe7008a2be89676e5c934efa3f84bc8b194fd7996`, 195 outputs. It suppresses
  impossible chasm elevation and is the later pre-golden candidate. Existing authority says it
  supersedes the 198-output pack but remains pending integrated visual review before native pinning.
- `manifest 3.json`: file SHA-256
  `5bb8992c4f9468018c0c9c575eebd4e281759481c4b459d321ee06ab48c7e9bd`, canonical-body SHA-256
  `5b23f9e3eec4a424e99dc564c5a0080f280f284114997c350c76d7d2b89a3102`, 198 outputs. Its only
  semantic difference is the three now-impossible `terrain-chasm-elevation-{1,2,3}` records.

Neither manifest refers to a copy-suffixed filename. Both resolve all their declared outputs without
duplicate output paths. Therefore `manifest 3.json` and the 92 copy-suffixed PNGs are organization
debt, not alternate runtime lookup names. Existing authority selects `manifest.json`; however, no
existing authority permits deleting the older receipt or its duplicate files. Cleanup remains held
for an explicit disposition: retain the 198-output manifest as semantic evidence, or remove it and
its 92 byte-identical copies after reference closure is independently approved.

All copy-suffixed PNGs below are byte-identical to the unsuffixed filename obtained by removing the
terminal ` 2` or ` 3`. The listed SHA-256 is shared by each copy/base pair.

### Exact copy-suffix inventory

- `content-empty 3.png` — `50b068e07b4bf235705c19b77da49fdbbc7e98ddc0a46f1c6659cca98c963904`
- `content-hazard 2.png` — `7cd637881c9007cd4f7c74c451274f3869262c41738bfcf1c9e85daedf634fa7`
- `content-lockedCache 2.png` — `89f09bec67aa8d64fa38c65cb7c8750b5b38dbb9b8ce9f6624bacee1c2ab9e18`
- `content-node 3.png` — `d38ddaf43319aeae6f1f1f1867c07707b8efb8d5094a0a75a1be58e0fef5e046`
- `content-wildDrop 2.png` — `1bb08428875745bc273dab0f036f4732000ddb86e62916ff98842b9e71fc1ff4`
- `flora-phase0-flora 2.png` — `312ddd98d6c05b95b70f22772f9b0632ff1e06397126828db8a874ea34fe186d`
- `manifest 3.json` — `5bb8992c4f9468018c0c9c575eebd4e281759481c4b459d321ee06ab48c7e9bd`
- `overlay-crack 2.png` — `e5c04ab577b143ce4bf61f6f49878c0bb6f38d6a50e8c7ac25824ad25c6eec99`
- `terrain-ash-15 2.png` — `d71650bd99d442cd0f87b6a17fce171c159c60794bdc2939728c756d27c532b0`
- `terrain-ash-elevation-3 2.png` — `defa7e3f83df5f285cf10993ca07a1ca0b46ffb8c394ad873161269fde9cda1f`
- `terrain-ash-feature-2 2.png` — `e6c7c9d6d8bf3031d4cdb6befc330f59de95b245b099c7caef0498b86c7a537c`
- `terrain-ash-feature-3 2.png` — `f7a518d1339b409a35cd7062866a5d6187abd2b1ad1112492fb5f5e2499905b1`
- `terrain-ash-grade-warm-dry 2.png` — `9f5f4075dec769b92bb2c88e439fb092768c2d610d1b94a149f15be2d8327efc`
- `terrain-chasm-15 2.png` — `0b7f0dbfa4fc83b9ac3ba2550ff5cdad64525e26becde36223059d16851d2559`
- `terrain-chasm-4 3.png` — `801fd5919ae8f923111836dc17b94c6de0698b8a67313b2f0837bb77dc73a0fe`
- `terrain-chasm-8 2.png` — `41618829a3487838103958fa577e581596f4598384470bcf21ebf83e5216cd1e`
- `terrain-chasm-9 2.png` — `d5c3d9ef65f6880f2ec7351fdb25a6b227d0c183de1d11cdb35e39b89fcd6309`
- `terrain-chasm-feature-2 2.png` — `01e3f9b60b489bcefe5854665f51606157c77880184ad744bb01e370dc113e3e`
- `terrain-chasm-grade-cool-living 2.png` — `5481032e581243614efdcc9c2652d681a6e8ece29ae07ffa7b5f53bce2647bd0`
- `terrain-deepWater-0 2.png` — `d47220738adaba4afe0993a5884c777012847c1ebadddeb7a30e0b556e0d9f65`
- `terrain-deepWater-1 2.png` — `b6d581cc317ce99cb2709c4fe47d7f4bae9d33551f5d9765619a6c96ac79e33b`
- `terrain-deepWater-10 3.png` — `250efe8bcf3d187244fe15604eafd85d5a9c353ce6ea675b81d164ffe4647a00`
- `terrain-deepWater-11 3.png` — `067262e183ab5b70324075b1dc9c377c88040c01f94e6d15870d1671e687b083`
- `terrain-deepWater-14 3.png` — `b59a243332285342bfe2d20c2a13f70cd45830a3f412aa1b30513e4a3a140376`
- `terrain-deepWater-15 3.png` — `2c1db478c1db4180618b2dab3dea84dca5b9bf7f51baa7f8d3c89ad23f7d6a7d`
- `terrain-deepWater-2 2.png` — `64d039358e873b26440f3eb24b5668a3e359d7dba8b217cc74827e37b02ab991`
- `terrain-deepWater-3 2.png` — `ec2b219e5c7a9889fb788dbe29399a66f1c8fa14291b73cddbe488a040a95823`
- `terrain-deepWater-8 2.png` — `f9aa4df679559086c4ac7ea3ad029798c38ba06a07abe1ce21772cb416732d4a`
- `terrain-deepWater-9 3.png` — `322b15f57e4e1d34ffefccd803a084830627db47a01a09869f742e7f0b9e1631`
- `terrain-deepWater-elevation-2 2.png` — `341ca89974fba7890cb27889a07a334f42886e8f8d898b3d5166f86107dcd06f`
- `terrain-groundcover-crumbled 2.png` — `f53f3cb685a2ab6184754de58740fc1e142d4cc8e94cd0aee2f770b0cc193fa7`
- `terrain-groundcover-elevation-2 2.png` — `34f80f49b417071a466670c23a6b86433dc8ce8db987c055b4abd77aad87597c`
- `terrain-groundcover-elevation-3 2.png` — `7093f6bdf44875c1f4806b567140440becfb6b71793c62e4880d9845cbec739f`
- `terrain-groundcover-feature-2 2.png` — `eb245f5293301f2bce1b315ea046b52333a3084e3fde79972c5b774cb6c0f2e7`
- `terrain-groundcover-feature-3 2.png` — `bca013dad8bb36b52289bbed08e8931721b08653db361fab23ffa70665676738`
- `terrain-groundcover-grade-cool-living 2.png` — `d614b383974dda66f057946b4cc6ece0db805c0945f9e7f2be40fdd2e0a0b8b3`
- `terrain-growth-15 3.png` — `dd5d4f59fb0f824dd1189f2b7d18bbf80f5d6a9d3b8f127ca9c0f829042c42cb`
- `terrain-growth-crumbled 2.png` — `b894ce79c9836ac3779c446774d335b1bede54de7cbf80afa642a3836bbc64e7`
- `terrain-growth-elevation-2 2.png` — `7b5a5f81798fc8f80fee6b0346b2ed8a3a03460c6eaf6ce857af1175b42ab4ef`
- `terrain-growth-feature-3 2.png` — `3c8d7f17d9a58165586775854ca6ef5fcdbc415784a099726d340dcd57f73945`
- `terrain-ice-0 2.png` — `54ee312ff7bc7fddc4f397f99c6da772050a44dbc7fc66fa3205b3dea0306865`
- `terrain-ice-11 2.png` — `19d762426bf84b36103b4b87e989d8fc8cb3cea219d9296704f7a7dc281c9cc2`
- `terrain-ice-13 2.png` — `70723423e63adb3c26d10994ac5736d30a175f32c8dda0aac0fa0ff9bc3b26df`
- `terrain-ice-15 2.png` — `ed67d4f1b414dacc1529c3ad10aececb6cefa3d240ddaac2b3ddcac2d691a2df`
- `terrain-ice-4 3.png` — `edf38d4c289a56b90a753401440baf5d2c3bb7a9bd90a1186e23362d9b044335`
- `terrain-ice-8 2.png` — `add81ab23873dc7719a377e432ad7a88b18cc4bd2a9f9630b4486695f731910d`
- `terrain-ice-9 2.png` — `e10f9867e538752e7226766355a629e0d43ac5abe24137b12cbadd39a2d49c32`
- `terrain-ice-elevation-1 2.png` — `048c1eb77835df7b217ddadda1345e2dfbb7d80081ea5ec6c0a820d6b2083ae2`
- `terrain-ice-elevation-3 2.png` — `8a36dda8349bc206fa351833d19fed99b83946b4312626405c2dd342f677addc`
- `terrain-ice-feature-1 2.png` — `7f6208c1fb2630c0d0644f349cc017e750838aa566a01df1e297b525bd2e5984`
- `terrain-ice-feature-2 2.png` — `22bca1dbb1ee0c7bfdf0bb8a7cbe331ce675250517466a63ef8801f94667c805`
- `terrain-ice-feature-3 2.png` — `7c54e655210f1c7865a980683a725012cbc0de967b67ff104fb739306d29252a`
- `terrain-ice-grade-cool-living 2.png` — `c7faf8bfb2847dbf37743165e5b213295bb3160749939f50bca467b57b2ffe1c`
- `terrain-ice-grade-warm-dry 2.png` — `8450e2511cf2af1570fd5fa31d50a787ab23c6e21534049dce133594c02a222f`
- `terrain-mud-elevation-3 2.png` — `a9323849aed667d9b685c5eb057985be2fce65f47988d4754145a9d0509b7ae7`
- `terrain-mud-feature-1 2.png` — `7f3c299819b9c1c357976609bfdff7ae8789bd1ca02bcf20a77f2737074a3d36`
- `terrain-mud-feature-3 2.png` — `9283be76c5c3cb0b9de3d41b6fe9e21ecbe51b1443bc8a19010fd5114b5537b0`
- `terrain-mud-grade-warm-dry 2.png` — `bc27614eeca8a6ca218785a3d5a52746748f2e04be395e209236f4fa6b8a8bab`
- `terrain-rubble-elevation-2 2.png` — `14853ca2c1928c4b2a9f6567502bd024358be0e154f49f12d0e031450c721012`
- `terrain-rubble-feature-1 2.png` — `31cf46324251812421b343b657f1b795e9a3af610eaad2f4abb87fafbfd579cc`
- `terrain-rubble-feature-2 2.png` — `8429812a4e26b8182772f0648c2a3c0d88e03aac55ddd7f88e481470d1bcc091`
- `terrain-rubble-feature-3 2.png` — `2b25f24d0b7b00fd9e64cecb873064f6aaabe367c2cff22bf66f22854cd42240`
- `terrain-rubble-grade-cool-living 2.png` — `64b102666bb08bb8d13ba0fe71b3dfaf67fdcfab9759de2886f8fbdfb00a2c20`
- `terrain-rubble-grade-warm-dry 2.png` — `aa0e6d5f336e5ed900f09e8de836f4ff6033c795ef86a8fb5827514743f1a539`
- `terrain-sand-15 2.png` — `54f4cb2c99c6d02e6c612f6988e8e9f6170608b920a7b1fa23659bed6d65aa4a`
- `terrain-sand-feature-1 2.png` — `8029b51422938a3debe1a093fb0a976b2fa51dfd96b36bd431e821e0696459fb`
- `terrain-sand-feature-2 2.png` — `f353f033acddaaba6466f973ce072bff48ceb7b0e4f62f1c7f66acfe06aef18e`
- `terrain-sand-feature-3 2.png` — `097ab5633ffa8233a41a42607abe0027d9c8c70628c6371cb07aa4db6bdbdf3a`
- `terrain-sand-grade-cool-living 2.png` — `e72ca3041a50e083ac590cb66b71b03ff32a5f017838deb406674634f13561db`
- `terrain-soil-15 3.png` — `695eeb01fddc343bdd8b29e92ffbc7dcd1fa6974dead080cc4ec314ef1c22809`
- `terrain-soil-crumbled 2.png` — `10362e57f0070ec20de284fb60c3389e2b242423027f93580951c607af9f5036`
- `terrain-soil-elevation-1 2.png` — `51d934708221140acb60efbda7f1423a036b93a1be37ccf02640026c59c8079c`
- `terrain-soil-elevation-3 2.png` — `5b923aa0c9352d650092266d75d8f7692a4288f882ba3178e3b3f9949baf6f3a`
- `terrain-soil-feature-1 2.png` — `6c18e4a2013be54a061d7d3da37e155b2b5cd686fa21b6fd9f33209b138ba293`
- `terrain-soil-feature-3 2.png` — `988df749eb337ba08ec9db54353aedb9d6e9e48a931dfe2e5d7b8e33083324bd`
- `terrain-soil-grade-warm-dry 2.png` — `f66899ed352b3ca9175e08066b9f9cfcffa607b8459d02c86607fb15019f261b`
- `terrain-stone-15 2.png` — `7a595205cd9be6f35cb7d150e513abc4a08b95405efbf45ad3c462dbf4fc8708`
- `terrain-stone-crumbled 2.png` — `9a4500b31aaba8f92bbf5635cb94f8c704933627782800204f1916925c8b9059`
- `terrain-stone-elevation-2 2.png` — `b11228f1eeaf2f841b51e94caab5364e42f8c5fb47436e7c232479e3267b3e30`
- `terrain-stone-elevation-3 2.png` — `86a7303e27836dc2bf0f0781458ba8625778f9a6d134b28d3818f7be64f19c9a`
- `terrain-stone-feature-1 2.png` — `2607240e4aa71d7e064bf95feb40d608384af8eefc2c4c4501728bc6502a0de1`
- `terrain-stone-grade-warm-dry 2.png` — `7d5e321d8dcea53748b9e57803e99b65eaa336363582107517d57d50f560848b`
- `terrain-water-11 2.png` — `bedeb65a3e64e19947a030e7afec9c7d67dac39ef2c09b8480cc0cce2a0eb1f1`
- `terrain-water-12 2.png` — `12be429576273301f49744b82224eb73d16a29dee2b9f196b19dc4ea6b933b4d`
- `terrain-water-13 3.png` — `58f5b8659eb66b69424ca00bcf297e3ec64a49ba0cf9541236c8de6930e25762`
- `terrain-water-15 2.png` — `95a6fba8d5a1189206f1907e12076841d8bd3ff83509c2eda465214d759494d7`
- `terrain-water-2 3.png` — `9039407837befffac21598d891be33324e816d79c698dadfb00ae8199563bfee`
- `terrain-water-4 2.png` — `91993f404ed37bb79194d465bfbf0e071704458de75de880f4414402632aae48`
- `terrain-water-6 2.png` — `565d8da25e09836377667526c332bb464a2211a32c0237599485eb89454b1d9b`
- `terrain-water-7 2.png` — `ca57c98f15ea5e650d53a47b9f7841ac1a5dd49fe2f617524d9f3018a287804c`
- `terrain-water-9 2.png` — `c44444a659aae95d41b6584f76bd538d3d9c1fe76e9f9c311e6dca0fe2a8cf14`
- `terrain-water-elevation-1 2.png` — `07b68fdce224882d30cd63d522a9b288e18872d49cce145a8e55f6771dd64c4c`
- `terrain-water-feature-3 2.png` — `2da514489075af2feb11dca12488b68bc41dca2a81b7ae2aa0f71967c542b0cf`

## Integration/runtime mirror audit

Six `AssetLab/integration/**/runtime` trees are byte-for-byte mirrors of app-consumed
`RuntimePacks/**` trees, including manifests and every hash-addressed asset:

| AssetLab producer output | App resource mirror | Files | Manifest SHA-256 |
|---|---|---:|---|
| `exploration-catalogue-objects-v1/runtime` | `ExplorationCatalogueObjects-v1` | 29 | `71dcb608dae62dc6503f9333f0114ac6b9d75871f39a1c3f222b9645d027e239` |
| `exploration-loose-essence-v1/runtime` | `ExplorationLooseEssence-v1` | 5 | `58daa8282f5f4312bbbece64325aadd343e4551f0792999680e3ebaf9550fb6e` |
| `exploration-loose-items-v1/runtime` | `ExplorationLooseItems-v1` | 64 | `a0c8251adde90797a64d43ef87668af65d235b93b16a1aecb13f8aeb235ae48d` |
| `exploration-map-identities-v1/runtime` | `ExplorationMapIdentities-v1` | 51 | `e0d926e86128def14a1bdc488311d9d0e65ab60464d16126bfb44b9514d83b80` |
| `terrain-production-pack-v1/runtime` | `TerrainProductionPack-v1` | 99 | `1c23fad456c62bd09944b175b9a7a7f55fcf976b763f44a8ff6632f5bb67a682` |
| `terrain-south-wall-v1/runtime` | `TerrainSouthWallPack-v1` | 145 | `ee635278fe03b04304b46e47673596723df58827819e79580c40cc697d5fd9bb` |

This duplication is currently intentional at the consumer boundary: AssetLab exporters and promotion
checks own the integration trees; `project.yml`, the Xcode project, native loaders, and resource
integrity tests own the `RuntimePacks` copies. It is organization debt only because the promotion
copy step is not represented by one closed repository tool. Neither side can be removed safely in a
rename-only patch.

`AssetLab/integration/writing-desk-production-pack-v1/runtime` is different: it is directly included
as the `WritingDeskProductionPack-v1` app resource and has no `RuntimePacks` duplicate. That direct
resource path is explicit current authority, not an accidental mirror.

## GameWiki disclosed-visual coverage audit

The current generated wiki is fresh and contains 27 semantic visual-family routes. Twenty-three
families expose 4,339 manifested records; all records retain semantic per-record routes and source
paths where their manifest supplies one. Six families also link to the exact `RuntimePacks` manifest
mirrors above. The wiki remains a read-only documentation projection.

Four family pages correctly expose no record previews:

- `map-slice-v1` is fail-closed because the two manifest bodies conflict.
- `catalogue-consumables-placeholder-v1` is explicitly a functional-placeholder command manifest,
  not a disclosed final raster family.
- `ui-priority-v1` is a runtime-integrated priority/ownership manifest without a raster record set.
- `world-grade-2-v1` is frozen-legacy conformance metadata without a disclosed raster record set.

`AssetSources` is safely absent because it contains zero reviewed authored packs. The one current
`AssetEvidence` receipt is also safely absent because `gameWikiDisclosure` is `withheld`. Neither
root may be crawled implicitly; a future record requires an exact disclosed pack-local receipt.

Path comparison finds 128 tracked `AssetLab/artifacts` visual files not linked by the wiki:

- 73 loose root proofs have no pack-local semantic disclosure receipt. They must remain absent until
  individually classified/relocated and explicitly disclosed through `AssetEvidence/.../evidence-receipt.json`.
- 42 `terrain-region-continuity-v1/evidence/*` files are already declared with hashes in
  `AssetLab/artifacts/terrain-region-continuity-v1/manifest.json` under `outputs[].name`; the wiki
  currently emits only `contactSheet`. The exact missing source-link contract is manifest directory
  plus each disclosed `outputs[].name`, with role `evidence` and the declared `sha256`.
- Nine Writing Parchment review files are declared as `evidence[]` and one generated reference is
  named by `productionSource.reference` with `referenceProductionSource:false`. The exact links are
  `AssetLab/artifacts/writing-parchment-v1/evidence/<evidence entry>` and
  `AssetLab/artifacts/writing-parchment-v1/<productionSource.reference>`. They must remain evidence
  and reference, never source or approval.
- Three World Material phone proofs are declared in
  `AssetLab/integration/world-material-pixel-correction-v1/manifest.json` as `evidence.*.file`, but
  physically live under `AssetLab/artifacts/world-material-pixel-correction-v1/`. Their exact links
  require the manifest to state those full repository paths or a family-specific documented base;
  the wiki must not guess across roots.

The smallest future wiki-only closure is to teach its existing visual extractor these already
disclosed field shapes and add source-link tests. It must not crawl loose files, infer production
method, change approval/classification, or create a repository/runtime catalogue.

## Smallest safe cleanup sequence

1. **Map-slice decision:** keep all bytes stationary until the old 198-output manifest is explicitly
   classified as retained evidence or removable superseded output. Then update its exact docs/wiki
   references and remove or relocate the 92 unreferenced byte copies in the same reviewed patch.
2. **Promotion bridge:** add a pack-bounded check-only promotion command for one of the six exact
   mirrors that proves source/destination tree equality and owns the copy. Do not rename hash blobs.
3. **Repeat per pack:** only after that check is independently accepted, apply the same explicit
   promotion boundary to the other five mirrors. Keep semantic navigation in each manifest.
4. **Writing Desk:** leave its direct app-resource integration path unchanged unless a separately
   approved project-resource migration names the replacement.

No global catalogue is introduced. Runtime identities remain manifest keys plus immutable hashes;
Finder navigation remains semantic at the pack and manifest level.
