import XCTest
@testable import Luma

final class FilmStockTests: XCTestCase {
    func testCatalogContents() {
        XCTAssertEqual(FilmStock.catalog.count, 12)
        XCTAssertTrue(FilmStock.catalog.contains { $0.name == "Portra 400" && $0.iso == 400 })
        XCTAssertTrue(FilmStock.catalog.contains { $0.name == "HP5+ 400" && $0.iso == 400 })
    }

    func testManualISO() {
        let manual = FilmStock.manual(iso: 250)
        XCTAssertEqual(manual.iso, 250)
        XCTAssertEqual(manual.name, "ISO 250")
    }
}
