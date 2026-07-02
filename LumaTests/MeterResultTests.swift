import XCTest
@testable import Luma

final class MeterResultTests: XCTestCase {

    private func recommendation(_ result: MeterResult) -> ExposurePair? {
        guard case let .recommendation(pairs, index) = result else { return nil }
        return pairs[index]
    }

    // « Sunny 16 » : EV100 = 15, film ISO 100.
    // Reco attendue : f/8 · 1/500 (zone f/5.6–f/8, la plus proche de f/8).
    func testSunny16_recommendsF8() {
        let result = ExposureCalculator.result(ev100: 15, filmISO: 100)
        let reco = recommendation(result)
        XCTAssertEqual(reco?.aperture.fNumber, 8)
        XCTAssertEqual(reco?.speed.label, "1/500")
    }

    func testPairs_allWithinHalfEVAndSortedByAperture() {
        guard case let .recommendation(pairs, _) =
                ExposureCalculator.result(ev100: 15, filmISO: 100) else {
            return XCTFail("expected recommendation")
        }
        let target = 15 + log2(100.0 / 100)
        for p in pairs { XCTAssertLessThanOrEqual(abs(p.ev - target), 0.5) }
        XCTAssertEqual(pairs.map(\.aperture.fNumber),
                       pairs.map(\.aperture.fNumber).sorted())
    }

    // Basse lumière : EV100 = 5, film 400 → cible EV 7.
    // Aucune paire ≥ 1/125 : on ouvre et on prend la vitesse la plus rapide.
    func testLowLight_opensWideAndFastestShutter() {
        let reco = recommendation(ExposureCalculator.result(ev100: 5, filmISO: 400))
        XCTAssertEqual(reco?.aperture.fNumber, 2.8)
        XCTAssertEqual(reco?.speed.label, "1/15")
    }

    // L'ISO du film décale la cible : même scène, film 4× plus sensible
    // → paires 2 EV plus fermées/rapides.
    func testFilmISO_shiftsTarget() {
        let reco100 = recommendation(ExposureCalculator.result(ev100: 12, filmISO: 100))
        let reco400 = recommendation(ExposureCalculator.result(ev100: 12, filmISO: 400))
        XCTAssertNotNil(reco100)
        XCTAssertNotNil(reco400)
        XCTAssertEqual(reco400!.ev, reco100!.ev + 2, accuracy: 0.6)
    }

    // La dichotomie tooDark/tooBright suppose une grille de paires sans
    // « trou » : si un futur objectif espaçait les EV de plus de 1,
    // une scène normale serait faussement déclarée hors plage.
    func testPairGrid_hasNoCoverageGap() {
        let evs = FM2.apertures.flatMap { a in
            FM2.shutterSpeeds.map { ExposurePair(aperture: a, speed: $0).ev }
        }.sorted()
        for (prev, next) in zip(evs, evs.dropFirst()) {
            XCTAssertLessThanOrEqual(next - prev, 1.0 + 1e-9)
        }
    }

    func testTooDark() {
        XCTAssertEqual(ExposureCalculator.result(ev100: -5, filmISO: 100), .tooDark)
    }

    func testTooBright() {
        XCTAssertEqual(ExposureCalculator.result(ev100: 25, filmISO: 100), .tooBright)
    }
}
