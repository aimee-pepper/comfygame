import XCTest
@testable import Bookbinder

final class CreaturePixelIdentityTests: XCTestCase {
    func testEverySupportedMorphologyFitsTheSixteenPixelIdentityCell() {
        for bodyPlan in CreatureBodyPlan.allCases {
            for cranialFeature in CranialFeature.allCases {
                for appendageType in AppendageType.allCases {
                    var traits = CreatureTraits()
                    traits.bodyPlan = bodyPlan
                    traits.cranialFeature = cranialFeature
                    traits.appendages = Appendages(count: appendageType == .none ? 0 : 2,
                                                    type: appendageType)

                    let cells = CreaturePixelSilhouette.cells(for: traits)
                    XCTAssertFalse(cells.isEmpty, "\(bodyPlan)/\(cranialFeature)/\(appendageType)")
                    XCTAssertTrue(cells.contains { $0.layer == .body },
                                  "feature layers cannot replace the body plan")
                    for cell in cells {
                        XCTAssertGreaterThan(cell.width, 0)
                        XCTAssertGreaterThan(cell.height, 0)
                        XCTAssertGreaterThanOrEqual(cell.x, 0)
                        XCTAssertGreaterThanOrEqual(cell.y, 0)
                        XCTAssertLessThanOrEqual(cell.x + cell.width, 16)
                        XCTAssertLessThanOrEqual(cell.y + cell.height, 16)
                    }
                }
            }
        }
    }

    func testEveryBodyPlanHasItsOwnBaseSilhouette() {
        let silhouettes = CreatureBodyPlan.allCases.map { bodyPlan -> [CreaturePixelSilhouette.Cell] in
            var traits = CreatureTraits()
            traits.bodyPlan = bodyPlan
            traits.cranialFeature = .none
            traits.appendages = Appendages(count: 0, type: .none)
            return CreaturePixelSilhouette.cells(for: traits)
        }

        for left in silhouettes.indices {
            for right in silhouettes.indices where right > left {
                XCTAssertNotEqual(silhouettes[left], silhouettes[right],
                                  "distinct axial body plans collapsed to one silhouette")
            }
        }
    }

    func testFennecAndWingedSerpentRemainDistantAtNativeCellScale() {
        var fennec = CreatureTraits()
        fennec.bodyPlan = .quadruped
        fennec.cranialFeature = .longEars
        fennec.appendages = Appendages(count: 4, type: .limbed)

        var wingedSerpent = CreatureTraits()
        wingedSerpent.bodyPlan = .serpentine
        wingedSerpent.cranialFeature = .crest
        wingedSerpent.appendages = Appendages(count: 2, type: .membrane)

        let fennecCells = Set(CreaturePixelSilhouette.cells(for: fennec).map(CellKey.init))
        let serpentCells = Set(CreaturePixelSilhouette.cells(for: wingedSerpent).map(CellKey.init))
        let overlap = fennecCells.intersection(serpentCells).count
        let union = fennecCells.union(serpentCells).count

        XCTAssertLessThan(Double(overlap) / Double(union), 0.25,
                          "the two target morphology families became visually confusable")
    }

    private struct CellKey: Hashable {
        let x: Int
        let y: Int
        let width: Int
        let height: Int
        let accent: Bool

        init(_ cell: CreaturePixelSilhouette.Cell) {
            x = cell.x
            y = cell.y
            width = cell.width
            height = cell.height
            accent = cell.layer == .accent
        }
    }
}
