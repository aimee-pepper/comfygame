import XCTest
@testable import Bookbinder

final class ItemGridTests: XCTestCase {
    func testSixAcrossGridKeepsMinimumTapTargetsAtSupportedPhoneWidths() {
        for phoneWidth in [CGFloat(320), 368, 390] {
            let contentWidth = phoneWidth - 32
            XCTAssertEqual(ItemGridMetrics.columns, 6)
            XCTAssertGreaterThanOrEqual(ItemGridMetrics.cellSide(for: contentWidth), 44,
                                        "phone width \(phoneWidth)")
        }
    }

    func testSixAcrossGridFitsInsideCompactLootCard() {
        // 320pt phone, 12pt world margin each side, 8pt card inset each side.
        let compactLootWidth: CGFloat = 320 - 24 - 16
        XCTAssertGreaterThanOrEqual(ItemGridMetrics.cellSide(for: compactLootWidth), 44)
    }

    func testSixAcrossGridUsesExactlyItsAvailableWidth() {
        let contentWidth: CGFloat = 336
        let side = ItemGridMetrics.cellSide(for: contentWidth)
        let reconstructed = side * CGFloat(ItemGridMetrics.columns)
            + ItemGridMetrics.spacing * CGFloat(ItemGridMetrics.columns - 1)
        XCTAssertEqual(reconstructed, contentWidth, accuracy: 0.001)
    }

    func testItemDetailUsesAnchoredPopoverUntilAccessibilitySizes() {
        XCTAssertFalse(ItemDetailPresentationPolicy.usesSheet(dynamicTypeSize: .large))
        XCTAssertFalse(ItemDetailPresentationPolicy.usesSheet(dynamicTypeSize: .xxxLarge))
        XCTAssertTrue(ItemDetailPresentationPolicy.usesSheet(dynamicTypeSize: .accessibility1))
        XCTAssertTrue(ItemDetailPresentationPolicy.usesSheet(dynamicTypeSize: .accessibility5))
    }

    func testItemDetailPrefersBodyAwayFromNearestVerticalEdge() {
        let height: CGFloat = 800
        XCTAssertEqual(ItemDetailPresentationPolicy.preferredArrowEdge(sourceMidY: 100,
                                                                        screenHeight: height), .top)
        XCTAssertEqual(ItemDetailPresentationPolicy.preferredArrowEdge(sourceMidY: 700,
                                                                        screenHeight: height), .bottom)
    }

    func testItemGridReflowsAtAccessibilitySizes() {
        XCTAssertEqual(ItemGridMetrics.columnCount(dynamicTypeSize: .large), 6)
        XCTAssertEqual(ItemGridMetrics.columnCount(dynamicTypeSize: .xxxLarge), 6)
        XCTAssertEqual(ItemGridMetrics.columnCount(dynamicTypeSize: .accessibility1), 3)
        XCTAssertEqual(ItemGridMetrics.columnCount(dynamicTypeSize: .accessibility5), 3)
    }
}
