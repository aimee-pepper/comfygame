import XCTest
@testable import Bookbinder

final class ResourceBundleIntegrityTests: XCTestCase {
    func testEveryRetainedProductionResourceIsPresentInBuiltApplicationBundle() throws {
        let rootFiles = [
            "writing.parchment.handmade-v1-172x172.png",
            "Jersey10-Regular.ttf", "Tiny5-Regular.ttf",
            "starting-town-home-v1.json", "town-starting-home-v1-phone-v2.png",
            "named-character-placeholders-v1.json",
            "town-empty-v1.png", "town-starting-v1.png",
            "building-workshop-v1.png", "building-storehouse-v1.png",
            "building-library-v1.png", "building-essence-spring-v1.png",
            "building-constellation-v1.png", "building-bestiary-v1.png",
            "building-survey-post-v1.png", "building-reliquary-v1.png",
            "building-scriptorium-v1.png", "building-apothecary-v1.png",
        ]
        for file in rootFiles {
            XCTAssertNotNil(Bundle.main.url(forResource: file, withExtension: nil), file)
        }

        let folderSentinels = [
            "runtime/manifest.json",
            "TerrainProductionPack-v1/manifest.json",
            "TerrainSouthWallPack-v1/manifest.json",
            "ExplorationMapIdentities-v1/manifest.json",
            "ExplorationLooseItems-v1/manifest.json",
            "ExplorationCatalogueObjects-v1/manifest.json",
            "ExplorationLooseEssence-v1/manifest.json",
        ]
        for relativePath in folderSentinels {
            XCTAssertTrue(FileManager.default.fileExists(
                atPath: Bundle.main.bundleURL.appending(path: relativePath).path), relativePath)
        }

        _ = try WritingDeskProductionPack.bundled()
        XCTAssertFalse(try WritingDeskProductionPack.productionParchmentData().isEmpty)
        let homeManifest = try XCTUnwrap(Bundle.main.url(
            forResource: StartingTownHomeRules.manifestName,
            withExtension: "json"))
        let homeAsset = try XCTUnwrap(Bundle.main.url(
            forResource: StartingTownHomeRules.assetName,
            withExtension: "png"))
        XCTAssertNotNil(StartingTownHomeRules.load(
            manifestURL: homeManifest,
            assetURL: homeAsset))
    }
}
