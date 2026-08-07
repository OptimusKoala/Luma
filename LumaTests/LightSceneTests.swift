import XCTest
@testable import Luma

/// Le mode manuel (caméra refusée ou absente) repose sur ces scènes types :
/// l'app doit rester pleinement utilisable sans jamais rediriger vers les
/// Réglages comme seule issue (rejet App Store 2.1(a) du 2026-08-07).
final class LightSceneTests: XCTestCase {

    // La liste se lit du plus lumineux au plus sombre, sans doublon d'EV
    // (l'EV sert d'identifiant pour la sélection).
    func testCatalog_orderedFromBrightestToDarkest() {
        let evs = LightScene.catalog.map(\.ev100)
        XCTAssertGreaterThanOrEqual(LightScene.catalog.count, 5)
        for (prev, next) in zip(evs, evs.dropFirst()) {
            XCTAssertGreaterThan(prev, next)
        }
    }

    // La scène préselectionnée est le plein soleil (« Sunny 16 », EV 15) :
    // l'app affiche une recommandation dès l'ouverture du mode manuel.
    func testDefault_isSunny16() {
        XCTAssertEqual(LightScene.default.ev100, 15)
        XCTAssertEqual(LightScene.default, LightScene.catalog.first)
    }

    // Aucune scène ne doit tomber hors plage avec les pellicules courantes :
    // le mode manuel garantit toujours une paire réglable sur le FM2.
    func testEveryScene_yieldsRecommendationForCommonFilms() {
        for scene in LightScene.catalog {
            for iso in [100.0, 400.0] {
                guard case .recommendation = ExposureCalculator.result(
                        ev100: scene.ev100, filmISO: iso) else {
                    return XCTFail("\(scene.name) hors plage à ISO \(Int(iso))")
                }
            }
        }
    }
}
