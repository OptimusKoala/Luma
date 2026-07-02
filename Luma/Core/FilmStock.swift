import Foundation

struct FilmStock: Identifiable, Equatable, Codable {
    let name: String
    let iso: Double
    var id: String { name }

    static func manual(iso: Double) -> FilmStock {
        FilmStock(name: "ISO \(Int(iso))", iso: iso)
    }

    /// Catalogue v1 (spec) — films négatifs couleur et N&B courants.
    static let catalog: [FilmStock] = [
        FilmStock(name: "Portra 160", iso: 160),
        FilmStock(name: "Portra 400", iso: 400),
        FilmStock(name: "Portra 800", iso: 800),
        FilmStock(name: "Ektar 100", iso: 100),
        FilmStock(name: "Gold 200", iso: 200),
        FilmStock(name: "UltraMax 400", iso: 400),
        FilmStock(name: "HP5+ 400", iso: 400),
        FilmStock(name: "Tri-X 400", iso: 400),
        FilmStock(name: "Delta 100", iso: 100),
        FilmStock(name: "Delta 400", iso: 400),
        FilmStock(name: "Fomapan 100", iso: 100),
        FilmStock(name: "Fomapan 400", iso: 400),
    ]

    static let `default` = catalog[1] // Portra 400
}
