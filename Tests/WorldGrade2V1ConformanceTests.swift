import CryptoKit
import Foundation
import XCTest
@testable import Bookbinder

final class WorldGrade2V1ConformanceTests: XCTestCase {
    private let green = WorldGrade2V1.ResolvedColor(
        srgb: [62, 122, 86], resolutionVersion: "resolved-color-1.0.0",
        provenance: "bindRandom")

    private func identicalRequest() -> WorldGrade2V1.Request {
        WorldGrade2V1.Request(
            material: .init(identity: "mixedMineral", paletteFamilyID: "paleNeutral",
                            transform: .init(hue: 0, saturation: 1, value: 0)),
            atmosphere: .init(medium: "none", density: 0, paletteFamilyID: "clear"),
            flora: .init(coveragePercent: 40, paletteRichness: 50,
                         cast: [.init(speciesID: "flora-a", formID: 0, stature: 35,
                                      resolvedColor: green)]),
            resolvedColors: .init())
    }

    func testFrozenPackIdentitiesAndHashesArePinned() {
        XCTAssertEqual(WorldGrade2V1.canonicalManifestSHA256,
                       "e601d2f77a15d545fd2d893dbb2e41891518cba2900c3f6d66890d56294824c1")
        XCTAssertEqual(WorldGrade2V1.rawManifestSHA256,
                       "da7d79fb949f043453cfcffdecbf50eac44ac00a0bad307c7b879270d8f91a41")
        XCTAssertEqual(WorldGrade2V1.requestSchemaSHA256,
                       "a5693b65d9a9abc6f63d3581f27d84968e8ecad9b613094fa6a3f7b4795f65ac")
        XCTAssertEqual(WorldGrade2V1.descriptorSchemaSHA256,
                       "a34f63e50aee7346ed304c1a666209e6ef706e252b557a23cd5cd4cbaeb565b3")
        XCTAssertEqual(WorldGrade2V1.conformanceVectorsSHA256,
                       "b10c92e4232e6fb01c75d3d6ba07b4fef2d883c0b6d735afd538c1001d7218f2")
        XCTAssertEqual(WorldGrade2V1.versions.resolverVersion,
                       "world-grade-2-resolver-1.0.0")
    }

    func testIdenticalPublishedRequestAndDescriptorCanonicalHashesMatch() throws {
        let request = identicalRequest()
        XCTAssertEqual(try WorldGrade2V1.canonicalSHA256(request),
                       "51c8aff148d53a06874da1d336edd8f84c15f6e9f27f5e96225e2b7dbc265aa1")
        let descriptor = try WorldGrade2V1.resolve(request)
        XCTAssertEqual(descriptor.flora.richness, 1)
        XCTAssertEqual(descriptor.canonicalDescriptorSHA256,
                       "659e59c58822d20b5ddb7ed6303d15746d666444692bcc52ab21c37e200a5c09")
        XCTAssertEqual(try WorldGrade2V1.canonicalDescriptorSHA256(descriptor),
                       descriptor.canonicalDescriptorSHA256)
    }

    func testPublishedMaterialAndVoidColorVectorsMatchExactJSHSLPath() throws {
        let descriptor = try WorldGrade2V1.resolve(identicalRequest())
        XCTAssertEqual(try WorldGrade2V1.color("#6f7578", descriptor: descriptor,
                                               groundType: "stone"), "#84888c")
        XCTAssertEqual(try WorldGrade2V1.color("#292628", descriptor: descriptor,
                                               groundType: "chasm"), "#292628")
    }

    func testSmokeAndScopedColorMixingMatchPublishedVectors() throws {
        var request = identicalRequest()
        request.atmosphere = .init(medium: "smoke", density: 55,
                                   paletteFamilyID: "neutralSmoke")
        request.resolvedColors.atmosphere = .init(
            srgb: [120, 86, 170], resolutionVersion: "resolved-color-1.0.0",
            provenance: "bindRandom")
        let descriptor = try WorldGrade2V1.resolve(request)
        XCTAssertEqual(descriptor.canonicalDescriptorSHA256,
                       "b7a587fab873d0587e2597739d13004dc3f90255d70eee544a0d72f7773141dd")
        XCTAssertEqual(try WorldGrade2V1.color("#6f7578", descriptor: descriptor,
                                               groundType: "stone"), "#777682")
        XCTAssertEqual(try WorldGrade2V1.color("#292628", descriptor: descriptor,
                                               groundType: "chasm"), "#29242e")
    }

    func testFloraUsesPerSpeciesResolvedColorAndIgnoresTendencyAtRenderBoundary() throws {
        var request = identicalRequest()
        request.flora.paletteRichness = 90
        request.flora.cast[0].resolvedColor = .init(
            srgb: [55, 112, 170], resolutionVersion: "resolved-color-1.0.0",
            provenance: "bindRandom")
        request.resolvedColors.floraTendency = .init(
            srgb: [240, 20, 20], resolutionVersion: "resolved-color-1.0.0",
            provenance: "bindRandom")
        let descriptor = try WorldGrade2V1.resolve(request)
        XCTAssertEqual(try WorldGrade2V1.color("#3e7a56", descriptor: descriptor,
                                               scope: .flora, speciesID: "flora-a"), "#377c70")
        request.resolvedColors.floraTendency = nil
        XCTAssertEqual(try WorldGrade2V1.resolve(request), descriptor)
    }

    func testStrictJSONRejectsExtraFieldsWhileCodableRemainsTolerant() throws {
        let sparse = try JSONDecoder().decode(WorldGrade2V1.Request.self,
                                              from: Data("{}".utf8))
        XCTAssertThrowsError(try WorldGrade2V1.resolve(sparse))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(identicalRequest())) as? [String: Any])
        object["illumination"] = 50
        let data = try JSONSerialization.data(withJSONObject: object)
        XCTAssertThrowsError(try WorldGrade2V1.resolveJSON(data)) { error in
            XCTAssertEqual(error as? WorldGrade2V1.ContractError, .invalidFields("request"))
        }
        let tolerantDescriptor = try JSONDecoder().decode(WorldGrade2V1.Descriptor.self,
                                                           from: Data("{}".utf8))
        XCTAssertEqual(tolerantDescriptor.canonicalDescriptorSHA256, "")
    }

    func testSemanticValidationRejectsInvalidAtmosphereDuplicateFloraAndUnknownGround() throws {
        var clear = identicalRequest()
        clear.atmosphere.density = 1
        XCTAssertThrowsError(try WorldGrade2V1.resolve(clear))
        var duplicate = identicalRequest()
        duplicate.flora.cast.append(duplicate.flora.cast[0])
        XCTAssertThrowsError(try WorldGrade2V1.resolve(duplicate))
        let descriptor = try WorldGrade2V1.resolve(identicalRequest())
        XCTAssertThrowsError(try WorldGrade2V1.color("#ffffff", descriptor: descriptor,
                                                     groundType: "invented"))
    }

    func testGeometryNeverChangesAndRecolorLeavesNonHexCommandsUntouched() throws {
        let commands = [
            WorldGrade2V1.RectangleCommand(op: "rect", x: 1, y: 2, w: 3, h: 4,
                                            color: "#6f7578"),
            WorldGrade2V1.RectangleCommand(op: "mask", x: 5, y: 6, w: 7, h: 8,
                                            color: "transparent")
        ]
        let descriptor = try WorldGrade2V1.resolve(identicalRequest())
        let recolored = try WorldGrade2V1.recolor(commands, descriptor: descriptor,
                                                   groundType: "stone")
        XCTAssertEqual(recolored[0].color, "#84888c")
        XCTAssertEqual(recolored[1].color, "transparent")
        XCTAssertEqual(WorldGrade2V1.geometry(recolored), WorldGrade2V1.geometry(commands))
    }

    func testFogShortCircuitIsDescriptorIndependentTransparentRGBA() throws {
        let fog = try XCTUnwrap(WorldGrade2V1.fogRGBA(revealed: false, width: 16, height: 16))
        XCTAssertEqual(fog.count, 1024)
        XCTAssertTrue(fog.allSatisfy { $0 == 0 })
        XCTAssertEqual(SHA256.hash(data: Data(fog)).map { String(format: "%02x", $0) }.joined(),
                       "5f70bf18a086007016e948b04aed3b82103a36bea41755b6cddfaf10ace3c6ef")
        XCTAssertNil(try WorldGrade2V1.fogRGBA(revealed: true, width: 16, height: 16))
        XCTAssertThrowsError(try WorldGrade2V1.fogRGBA(revealed: false, width: 0, height: 16))
    }
}
