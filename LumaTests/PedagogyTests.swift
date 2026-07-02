import XCTest
@testable import Luma

final class PedagogyTests: XCTestCase {
    func testEveryApertureHasHint() {
        for a in FM2.apertures {
            XCTAssertFalse(Pedagogy.hint(aperture: a).isEmpty, a.label)
        }
    }
    func testEverySpeedHasHint() {
        for s in FM2.shutterSpeeds {
            XCTAssertFalse(Pedagogy.hint(speed: s).isEmpty, s.label)
        }
    }
}
