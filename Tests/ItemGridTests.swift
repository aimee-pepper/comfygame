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

    func testSixAcrossGridUsesExactlyItsAvailableWidth() {
        let contentWidth: CGFloat = 336
        let side = ItemGridMetrics.cellSide(for: contentWidth)
        let reconstructed = side * CGFloat(ItemGridMetrics.columns)
            + ItemGridMetrics.spacing * CGFloat(ItemGridMetrics.columns - 1)
        XCTAssertEqual(reconstructed, contentWidth, accuracy: 0.001)
    }
}
