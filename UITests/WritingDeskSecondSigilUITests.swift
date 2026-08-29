import XCTest

final class WritingDeskSecondSigilUITests: XCTestCase {
    func testSecondNativePaletteTapAppendsWithoutLeavingModernDesk() throws {
        let app = XCUIApplication()
        app.launchArguments += ["--debug-audit-route", "writingDesk"]
        app.launch()

        if app.buttons["tutorial.not-now"].waitForExistence(timeout: 2) {
            app.buttons["tutorial.not-now"].tap()
        }
        let modernDesk = app.descendants(matching: .any)["writing.desk.modern"]
        XCTAssertTrue(modernDesk.waitForExistence(timeout: 8))

        let illuminationBin = app.buttons["writing.bin.illumination"]
        XCTAssertTrue(illuminationBin.waitForExistence(timeout: 5))
        illuminationBin.tap()

        try tapPalette("writing.vocabulary.target.illumination", in: app)
        try placeArmedGhost(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["writing.mark.1"].waitForExistence(timeout: 5))

        try tapPalette("writing.vocabulary.source.sun", in: app)
        try placeArmedGhost(in: app)

        XCTAssertTrue(modernDesk.exists)
        XCTAssertTrue(app.descendants(matching: .any)["writing.mark.1"].exists,
                      "The first Sigil disappeared after the second palette tap")
        XCTAssertTrue(app.descendants(matching: .any)["writing.mark.2"].waitForExistence(timeout: 5),
                      "The second Sigil was not appended through the native page gesture")
    }

    private func tapPalette(_ identifier: String, in app: XCUIApplication) throws {
        let element = app.buttons[identifier]
        for _ in 0..<8 {
            if element.exists, element.isEnabled, element.isHittable {
                element.tap()
                return
            }
            app.swipeUp()
        }
        XCTFail("The exact starter Sigil was not available through the production palette: \(identifier)")
    }

    private func placeArmedGhost(in app: XCUIApplication) throws {
        let ghost = app.descendants(matching: .any)["writing.ghost"]
        guard ghost.waitForExistence(timeout: 5) else {
            XCTFail("Palette tap did not arm the native page ghost")
            return
        }
        let start = ghost.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = start.withOffset(CGVector(dx: 10, dy: 0))
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}
