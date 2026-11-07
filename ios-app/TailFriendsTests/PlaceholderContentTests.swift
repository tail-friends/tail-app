import XCTest
@testable import TailFriends

final class PlaceholderContentTests: XCTestCase {
    func testPlaceholderHasTitleAndMessage() {
        XCTAssertEqual(PlaceholderContent.title, "Tail Friends")
        XCTAssertEqual(PlaceholderContent.message, "The iOS app shell is ready.")
    }
}

final class DetailWeightTrendShapeTests: XCTestCase {
    func testHealthWarningCurveDropsAtEndpointAndDefaultCurveStaysUnchanged() {
        let defaultPoints = DetailWeightTrendShape.normalizedPoints(forHealthWarning: false)
        let warningPoints = DetailWeightTrendShape.normalizedPoints(forHealthWarning: true)

        XCTAssertEqual(defaultPoints, [
            CGPoint(x: 0, y: 0.82),
            CGPoint(x: 0.18, y: 0.68),
            CGPoint(x: 0.34, y: 0.75),
            CGPoint(x: 0.51, y: 0.46),
            CGPoint(x: 0.67, y: 0.53),
            CGPoint(x: 0.83, y: 0.28),
            CGPoint(x: 1, y: 0.12)
        ])
        XCTAssertGreaterThan(warningPoints.count, 1)
        XCTAssertGreaterThan(warningPoints[warningPoints.count - 1].y, warningPoints[warningPoints.count - 2].y)
        XCTAssertEqual(warningPoints[warningPoints.count - 1].y, 0.22, accuracy: 0.001)
    }
}
