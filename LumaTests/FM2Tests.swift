import XCTest
@testable import Luma

final class FM2Tests: XCTestCase {
    func testShutterSpeeds_thirteenFullStops() {
        XCTAssertEqual(FM2.shutterSpeeds.count, 13)
        XCTAssertEqual(FM2.shutterSpeeds.first?.label, "1s")
        XCTAssertEqual(FM2.shutterSpeeds.first?.seconds, 1.0)
        XCTAssertEqual(FM2.shutterSpeeds.last?.label, "1/4000")
        XCTAssertEqual(FM2.shutterSpeeds.last!.seconds, 1.0 / 4000, accuracy: 1e-9)
    }

    func testShutterSpeeds_matchFM2Dial() {
        XCTAssertEqual(FM2.shutterSpeeds.map(\.label),
            ["1s", "1/2", "1/4", "1/8", "1/15", "1/30", "1/60",
             "1/125", "1/250", "1/500", "1/1000", "1/2000", "1/4000"])
    }

    func testApertures_sevenFullStopsFor28mm() {
        XCTAssertEqual(FM2.apertures.map(\.fNumber), [2.8, 4, 5.6, 8, 11, 16, 22])
        XCTAssertEqual(FM2.apertures.first?.label, "f/2.8")
        XCTAssertEqual(FM2.apertures[3].label, "f/8")
    }
}
