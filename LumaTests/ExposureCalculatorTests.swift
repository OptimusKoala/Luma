import XCTest
@testable import Luma

final class ExposureCalculatorTests: XCTestCase {

    // EV100 = log2(N²/t) − log2(ISO/100) + offset
    func testEV100_knownValues() {
        let r = ExposureReading(iso: 100, shutterSeconds: 1.0 / 60,
                                aperture: 2.0, targetOffset: 0)
        // log2(4 × 60) = log2(240) ≈ 7.9069
        XCTAssertEqual(ExposureCalculator.ev100(from: r), 7.9069, accuracy: 0.001)
    }

    func testEV100_isoNormalization() {
        let base = ExposureReading(iso: 100, shutterSeconds: 1.0 / 60,
                                   aperture: 2.0, targetOffset: 0)
        let iso400 = ExposureReading(iso: 400, shutterSeconds: 1.0 / 60,
                                     aperture: 2.0, targetOffset: 0)
        // Même exposition à ISO 4× plus haut = scène 2 EV plus sombre.
        XCTAssertEqual(ExposureCalculator.ev100(from: iso400),
                       ExposureCalculator.ev100(from: base) - 2, accuracy: 0.001)
    }

    // Convention AVFoundation : offset négatif = image plus sombre que la
    // cible → la scène est plus sombre que ISO/durée seuls ne l'indiquent.
    func testEV100_offsetSignConvention() {
        let base = ExposureReading(iso: 100, shutterSeconds: 1.0 / 60,
                                   aperture: 2.0, targetOffset: 0)
        let darker = ExposureReading(iso: 100, shutterSeconds: 1.0 / 60,
                                     aperture: 2.0, targetOffset: -1)
        XCTAssertEqual(ExposureCalculator.ev100(from: darker),
                       ExposureCalculator.ev100(from: base) - 1, accuracy: 0.001)
    }

    func testSmoother_averagesLastTenSamples() {
        var s = EVSmoother()
        XCTAssertEqual(s.add(10), 10, accuracy: 0.001)
        XCTAssertEqual(s.add(12), 11, accuracy: 0.001)
        // Remplir : 10 valeurs à 20 chassent les anciennes (fenêtre = 10).
        for _ in 0..<10 { _ = s.add(20) }
        XCTAssertEqual(s.add(20), 20, accuracy: 0.001)
    }
}
