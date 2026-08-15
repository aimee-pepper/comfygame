import Foundation

/// Immutable native mirror of AssetLab's integration-ready functional placeholder pack.
///
/// This registry intentionally supplies only identified variants for the 17 consumables in the
/// frozen manifest. Unidentified, unsupported, and unknown catalogue identities remain absent so
/// `CatalogueItemVisualAdapter` preserves its disclosure-neutral fallback.
struct CatalogueConsumablesPlaceholderV1Registry: NativeVisualRuntime.Registry {
    static let packID = "catalogue-consumables-placeholder-v1"
    static let sourceCatalogueSHA256 = "f25e137ed92710995aea0ce5247ff94c2ce909c420a931c048449e23354361f3"
    static let manifestFileSHA256 = "162179701e16b2406ad1ffff7a4c0e8514bc19e862adf17c5ccc290aaae5c19f"

    let manifestSHA256 = "70a6d7c6c71f93c9c8488969439aed051e35a47a3579d3c219d556c160fee4a9"
    let pipelineVersion = "catalogue-consumables-functional-placeholder-1.0.0"
    let canvasWidth: UInt8 = 32
    let canvasHeight: UInt8 = 32

    var assets: [NativeVisualRuntime.Entry] { Self.generatedAssets }
    var explicitlyUnsupportedIDs: [String] { Self.unsupportedIDs }

    private static let generatedAssets: [NativeVisualRuntime.Entry] = [
        entry("salve_lesser", commands: [
            .init(x: 11, y: 9, width: 10, height: 18, rgba: 0x79b56fff),
            .init(x: 13, y: 5, width: 6, height: 5, rgba: 0xeee5d5ff),
            .init(x: 9, y: 14, width: 14, height: 4, rgba: 0x8d6648ff),
            .init(x: 14, y: 17, width: 4, height: 6, rgba: 0xeee5d5ff),
        ], commandSHA256: "95da80c765e679f1d6f667a920e99a7efac74061a5c474093781c6549c3904fc", decodedRGBASHA256: "491a89e71c4d36158f81ed8f18cfc139504bce6ea1db8f1e98645564680a406e"),
        entry("salve", commands: [
            .init(x: 9, y: 8, width: 14, height: 19, rgba: 0x79b56fff),
            .init(x: 12, y: 4, width: 8, height: 5, rgba: 0xb8bdbaff),
            .init(x: 7, y: 13, width: 4, height: 9, rgba: 0x8d6648ff),
            .init(x: 21, y: 13, width: 4, height: 9, rgba: 0x8d6648ff),
            .init(x: 13, y: 15, width: 6, height: 7, rgba: 0xeee5d5ff),
        ], commandSHA256: "3207de01d1249a53fc2bb9a605d22e1f74812a1387bc67940e6e0212f8e66e1a", decodedRGBASHA256: "d418493d7820f863ff7c2c94b2807cff9514e522a635cb028ce5b4205402c3fa"),
        entry("salve_greater", commands: [
            .init(x: 7, y: 9, width: 18, height: 18, rgba: 0x79b56fff),
            .init(x: 10, y: 5, width: 12, height: 5, rgba: 0xeee5d5ff),
            .init(x: 13, y: 2, width: 6, height: 4, rgba: 0xb8bdbaff),
            .init(x: 5, y: 15, width: 4, height: 8, rgba: 0x8d6648ff),
            .init(x: 23, y: 15, width: 4, height: 8, rgba: 0x8d6648ff),
            .init(x: 13, y: 14, width: 6, height: 9, rgba: 0xd8bd82ff),
        ], commandSHA256: "3544dfb6cca06d4e63b983098b3044233b6a5eac5ca4b930c4c637e04f2db0af", decodedRGBASHA256: "d21939ee8135150e34f6464cfe5f595280333da7e0cbb0c8916172be4416b05f"),
        entry("draught_clearing", commands: [
            .init(x: 8, y: 11, width: 19, height: 16, rgba: 0x72a7c4ff),
            .init(x: 10, y: 6, width: 8, height: 6, rgba: 0xb8bdbaff),
            .init(x: 5, y: 14, width: 5, height: 9, rgba: 0xeee5d5ff),
            .init(x: 18, y: 8, width: 7, height: 4, rgba: 0xeee5d5ff),
            .init(x: 12, y: 16, width: 9, height: 3, rgba: 0x171614ff),
        ], commandSHA256: "5bf733b62e666da14b8162397c0ae5347f698329b996cbc5f295693ed3f82dba", decodedRGBASHA256: "1eec6228a7a24a5833e07c520effc78e2dd8c1117c052dfb6becb2f7df24f864"),
        entry("draught_quenching", commands: [
            .init(x: 8, y: 7, width: 16, height: 20, rgba: 0x72a7c4ff),
            .init(x: 11, y: 3, width: 10, height: 5, rgba: 0xeee5d5ff),
            .init(x: 5, y: 11, width: 5, height: 6, rgba: 0xb8bdbaff),
            .init(x: 22, y: 9, width: 5, height: 9, rgba: 0xb8bdbaff),
            .init(x: 12, y: 17, width: 8, height: 4, rgba: 0x171614ff),
        ], commandSHA256: "f530a6b3e511b1f2aa43800772ae1c4a1f8667503648348eda9dba431b10bef9", decodedRGBASHA256: "06349816da9528fad53d947bc0c0cb35999b5705876bc7e218610c7da7eeeaa6"),
        entry("antidote_broad", commands: [
            .init(x: 6, y: 12, width: 20, height: 14, rgba: 0x8d78b2ff),
            .init(x: 10, y: 6, width: 12, height: 7, rgba: 0xeee5d5ff),
            .init(x: 14, y: 2, width: 4, height: 5, rgba: 0xb8bdbaff),
            .init(x: 9, y: 16, width: 4, height: 4, rgba: 0x171614ff),
            .init(x: 19, y: 16, width: 4, height: 4, rgba: 0x171614ff),
            .init(x: 14, y: 21, width: 4, height: 4, rgba: 0x171614ff),
        ], commandSHA256: "81efe2849bedc77d15cd0da733fe43bb28592c79b2b0d916c60a9bbbf0c5f648", decodedRGBASHA256: "eaae2465b9c4048de4c45cc2fa56f62a7aae70767c25942bfcf740cfb1237f17"),
        entry("stonebark_tonic", commands: [
            .init(x: 8, y: 7, width: 16, height: 21, rgba: 0x8d6648ff),
            .init(x: 11, y: 3, width: 10, height: 5, rgba: 0xb8bdbaff),
            .init(x: 5, y: 12, width: 5, height: 12, rgba: 0x8d6648ff),
            .init(x: 22, y: 12, width: 5, height: 12, rgba: 0x8d6648ff),
            .init(x: 12, y: 12, width: 8, height: 11, rgba: 0x79b56fff),
        ], commandSHA256: "ad5dbdeac574196baffa173899659f8ab9ded106c23da9ebdc446c627eb73a7f", decodedRGBASHA256: "7384126dedc37fdfaa839bf8153db47ebbeb09ddbf4876e91fc8447e056f69ce"),
        entry("venom", commands: [
            .init(x: 13, y: 3, width: 6, height: 6, rgba: 0xeee5d5ff),
            .init(x: 10, y: 8, width: 12, height: 17, rgba: 0x8d78b2ff),
            .init(x: 7, y: 22, width: 18, height: 5, rgba: 0x8d78b2ff),
            .init(x: 14, y: 12, width: 4, height: 8, rgba: 0x171614ff),
            .init(x: 18, y: 16, width: 5, height: 3, rgba: 0xeee5d5ff),
        ], commandSHA256: "b9be0a124183ad3ceb678d985209679eb5b16706e186d8243615fd3d1fd182a4", decodedRGBASHA256: "6617c6a320b2cc6869c1ac747b621b5d8542ed834649e419f067e2673dd9fe08"),
        entry("firebrand", commands: [
            .init(x: 12, y: 9, width: 8, height: 19, rgba: 0xb96055ff),
            .init(x: 9, y: 6, width: 14, height: 5, rgba: 0xb8bdbaff),
            .init(x: 14, y: 2, width: 4, height: 6, rgba: 0xd8bd82ff),
            .init(x: 6, y: 12, width: 6, height: 8, rgba: 0xb96055ff),
            .init(x: 20, y: 12, width: 6, height: 8, rgba: 0xb96055ff),
        ], commandSHA256: "3a761f09135f21c4408f31475f872227abf764405610155f955d4b05f0168a5b", decodedRGBASHA256: "3b6fe216bae9385296f7ef06a5fe109cb86f03be1e65c106663f31c2b3e8617f"),
        entry("briar_oil", commands: [
            .init(x: 9, y: 7, width: 14, height: 20, rgba: 0xd8bd82ff),
            .init(x: 12, y: 3, width: 8, height: 5, rgba: 0xb8bdbaff),
            .init(x: 5, y: 14, width: 6, height: 5, rgba: 0x79b56fff),
            .init(x: 21, y: 11, width: 6, height: 5, rgba: 0x79b56fff),
            .init(x: 13, y: 14, width: 6, height: 8, rgba: 0x171614ff),
        ], commandSHA256: "c125d35eecb5792b1d4f7ea0ce8fc8608c739cf432613a8b7fbccabdb600fcf6", decodedRGBASHA256: "ef33432e25df6b1318f1cb92af7c8a9c1fb6161eb19227baae0d39b20bb35aef"),
        entry("flashsalt", commands: [
            .init(x: 7, y: 11, width: 18, height: 16, rgba: 0xd8bd82ff),
            .init(x: 11, y: 6, width: 10, height: 6, rgba: 0xeee5d5ff),
            .init(x: 14, y: 2, width: 4, height: 5, rgba: 0xb8bdbaff),
            .init(x: 4, y: 7, width: 5, height: 3, rgba: 0xeee5d5ff),
            .init(x: 23, y: 6, width: 5, height: 3, rgba: 0xeee5d5ff),
            .init(x: 14, y: 15, width: 4, height: 8, rgba: 0x171614ff),
        ], commandSHA256: "0ff92b2f30d5cf17297e238b3b02e9a5ba0921e06322cdaa36887412e0c90877", decodedRGBASHA256: "5b0165a2b6f7e809e7efa34b9d1bdbcd9d3a0215735de1d9fe3355382fa95bc3"),
        entry("solvent", commands: [
            .init(x: 12, y: 4, width: 8, height: 5, rgba: 0xb8bdbaff),
            .init(x: 11, y: 8, width: 10, height: 20, rgba: 0x72a7c4ff),
            .init(x: 7, y: 12, width: 5, height: 3, rgba: 0xeee5d5ff),
            .init(x: 20, y: 17, width: 6, height: 3, rgba: 0xeee5d5ff),
            .init(x: 14, y: 13, width: 4, height: 10, rgba: 0x171614ff),
        ], commandSHA256: "c4ec7960de5bbf560ba93a6bfedbbb20a161147adfb540bc8b72c77893ec132a", decodedRGBASHA256: "499212deadfcbea02f3cc8e6d769739975ea9cad45a96f4efdd78e3387224414"),
        entry("lure", commands: [
            .init(x: 8, y: 10, width: 16, height: 16, rgba: 0x8d6648ff),
            .init(x: 11, y: 5, width: 10, height: 6, rgba: 0xb8bdbaff),
            .init(x: 5, y: 15, width: 5, height: 5, rgba: 0xb96055ff),
            .init(x: 22, y: 15, width: 5, height: 5, rgba: 0xb96055ff),
            .init(x: 13, y: 14, width: 6, height: 6, rgba: 0xeee5d5ff),
            .init(x: 15, y: 25, width: 2, height: 5, rgba: 0x8d6648ff),
        ], commandSHA256: "32d7e041ca8a37265f14096dd7e284bf064ad17dfb44ec632697811655d2fc11", decodedRGBASHA256: "cf1b3083d1c0bee75a5d561418811080dea3cac87af443259a5749db4b13de21"),
        entry("stillwater", commands: [
            .init(x: 6, y: 13, width: 20, height: 13, rgba: 0x72a7c4ff),
            .init(x: 9, y: 8, width: 14, height: 6, rgba: 0xeee5d5ff),
            .init(x: 13, y: 4, width: 6, height: 5, rgba: 0xb8bdbaff),
            .init(x: 4, y: 19, width: 5, height: 4, rgba: 0x72a7c4ff),
            .init(x: 23, y: 16, width: 5, height: 4, rgba: 0x72a7c4ff),
            .init(x: 10, y: 18, width: 12, height: 2, rgba: 0x171614ff),
        ], commandSHA256: "ac3c80b9ecb88aec3e60e2ea999c7dc1f47333a26bb471515f5b302071b805a4", decodedRGBASHA256: "1b20cccb1513657acb91d7ae0be17991a656b876cb691e455ef9c94b6ca5c0a1"),
        entry("waystone", commands: [
            .init(x: 14, y: 8, width: 4, height: 21, rgba: 0xb8bdbaff),
            .init(x: 7, y: 5, width: 18, height: 4, rgba: 0xeee5d5ff),
            .init(x: 7, y: 2, width: 4, height: 8, rgba: 0xd8bd82ff),
            .init(x: 14, y: 1, width: 4, height: 8, rgba: 0xd8bd82ff),
            .init(x: 21, y: 2, width: 4, height: 8, rgba: 0xd8bd82ff),
            .init(x: 10, y: 13, width: 12, height: 4, rgba: 0x8d78b2ff),
            .init(x: 5, y: 26, width: 22, height: 3, rgba: 0x171614ff),
        ], commandSHA256: "24322b456ca4510e2471fc6f12ada346f35db9bf9981ee530e3c8fd924ba9266", decodedRGBASHA256: "7b9fc1c6b28f84f0f347276d8138fde2894e239763bb61a42a7edb551fd8329e"),
        entry("torch", commands: [
            .init(x: 14, y: 11, width: 4, height: 19, rgba: 0x8d6648ff),
            .init(x: 10, y: 6, width: 12, height: 8, rgba: 0xb96055ff),
            .init(x: 12, y: 2, width: 8, height: 7, rgba: 0xd8bd82ff),
            .init(x: 8, y: 9, width: 6, height: 6, rgba: 0xb96055ff),
            .init(x: 18, y: 8, width: 6, height: 6, rgba: 0xd8bd82ff),
        ], commandSHA256: "e9117b449711c4ad3348a165461862f27028308c60b8447dbcb60113f2791c41", decodedRGBASHA256: "ce96008ca06aafe0529e43ddce691991d40c2a4ae6cbaaf49b966517f9fb2e6e"),
        entry("farsight_draught", commands: [
            .init(x: 9, y: 8, width: 14, height: 19, rgba: 0x8d78b2ff),
            .init(x: 12, y: 3, width: 8, height: 6, rgba: 0xeee5d5ff),
            .init(x: 5, y: 11, width: 5, height: 5, rgba: 0xb8bdbaff),
            .init(x: 22, y: 11, width: 5, height: 5, rgba: 0xb8bdbaff),
            .init(x: 12, y: 14, width: 8, height: 6, rgba: 0x72a7c4ff),
            .init(x: 14, y: 16, width: 4, height: 2, rgba: 0x171614ff),
        ], commandSHA256: "06f633012a7c2d5b39b06103f5e0f2309beed15036444dc2ba6edffda0dd5d47", decodedRGBASHA256: "20968fc67e136cef72d44c38f813f68c6610a72d93d1fc4fbb0be7f9b6ddcf66"),
    ]

    /// AssetLab hashes canonical JSON commands; native transport hashes normalized binary bytes.
    /// Both are pinned so converting formats cannot silently alter either authority.
    static let assetCanonicalCommandSHA256ByID: [String: String] = [
        "salve_lesser": "ee5ee25cf1ece4b432b1609c1947488e6bfa626ff0b5c236ef0f3d7c0f619116",
        "salve": "7869e1bdbfe4f41f81ca99b0d122ea38cb1fb819606ca778e9bef641d10807ed",
        "salve_greater": "af677bcc59d13da3857016a86aac58428839a4fbd012e5fd3e7aa21e70b4b78e",
        "draught_clearing": "25ea8bbdad2369e7a119e7d53841a912b102ec653402fe0df0ebfd19982b7d52",
        "draught_quenching": "89dfd4dd20741880d0780c7e1a833003052b18dfe77aca9b8fd6db3e056b3edf",
        "antidote_broad": "913456d09d6a61f95e72072a1d3259a429383ea8165c58a68eaf920f244e0d5d",
        "stonebark_tonic": "a4fe9267c125217cda4a527dac04618e280be020f17b7f4c513975e43fdf2dcd",
        "venom": "dd43406cec2eca24e0c0d7dbba24d777f0ef542b421388b920154a6b64f1d2ab",
        "firebrand": "93b3b6c2bfd38d7f8992d4979348f2783edc4c33a7436cd417f2592abd3c34a8",
        "briar_oil": "437d16349ad19d96eedb988fba39c156ed2bac8e2065689f1731229dd0cb6ce5",
        "flashsalt": "b9a6eaa86de10fe40a707d994ad6a450517e3b335c62942b78d5ed45ca93f9f6",
        "solvent": "f103c95ed4db293d0d9f3555a437fa156af66112614a6b6dd86efd857f668493",
        "lure": "d3d1efc1645dbc823a203383bb8ca377dd36278cfba097d2d55611ef84dd1bfb",
        "stillwater": "a602162e619fe7f9d6a77a7df4e83762cc1cab71ac6b409e4e3c496b0723512e",
        "waystone": "cc8e0cdbef8d10df06aaa66b7dd72c3303d72f02c97cc20deea04efd39888481",
        "torch": "fdc64df0d49e02799e70fe63f1dbfdc2c29844a4516d579effad610538010160",
        "farsight_draught": "eca2fde74b7fa108e0d507b01e4a1d85d8e14407d8cc7bacf095d4f73edf8bb0",
    ]

    private static let unsupportedIDs = """
    essence_crystal heat_core caustic_core light_core conduit_fixture
    curio_humming_shard curio_bound_knot cache_key anchor_frame
    blade_chipped blade_keen ripping_hook the_long_grievance bone_awl raking_edge
    blade_binders hairsplitter field_maul banded_mace anvilfall the_settled_argument
    long_pick warded_spear parting_needle the_kept_distance split_board banded_buckler
    tower_guard the_unarguable padded_cap ridged_helm visored_casque crown_of_quiet
    guard_padded guard_banded guard_vault the_standing_wall wrapped_hands studded_gloves
    gauntlets_of_hold the_sure_hands worn_boots shod_boots longstriders the_unhurried
    bent_pick balanced_pick corebreaker the_willing_edge pressed_leaf cold_compass
    someones_ring the_first_page two_natured_blade long_fang ranked_spear rimed_edge
    living_hook quiet_knife bloodletter warded_haft
    """.split(whereSeparator: { $0.isWhitespace }).map(String.init)

    private static func entry(
        _ catalogueID: String,
        commands: [NativeVisualRuntime.PixelCommand],
        commandSHA256: String,
        decodedRGBASHA256: String
    ) -> NativeVisualRuntime.Entry {
        .init(
            key: .init(catalogueID: catalogueID, identified: true),
            asset: .init(
                width: 32,
                height: 32,
                commands: commands,
                commandSHA256: commandSHA256,
                decodedRGBASHA256: decodedRGBASHA256
            )
        )
    }
}

extension GeneratedCatalogueItemVisualRegistry: CatalogueItemVisualRegistryProvider {
    static let registry: any NativeVisualRuntime.Registry & Sendable =
        CatalogueItemCompositeV1Registry()
}
