import Foundation

/// Constantes matérielles : boîtier Nikon FM2 + Nikkor 28mm f/2.8.
/// Isolées ici pour rendre un futur support multi-objectifs trivial.
enum FM2 {
    struct ShutterSpeed: Equatable, Identifiable {
        let label: String
        let seconds: Double
        var id: String { label }
    }

    struct Aperture: Equatable, Identifiable {
        let fNumber: Double
        var label: String {
            fNumber == fNumber.rounded() ? "f/\(Int(fNumber))" : "f/\(fNumber)"
        }
        var id: Double { fNumber }
    }

    static let shutterSpeeds: [ShutterSpeed] = [
        .init(label: "1s", seconds: 1),
        .init(label: "1/2", seconds: 1.0 / 2),
        .init(label: "1/4", seconds: 1.0 / 4),
        .init(label: "1/8", seconds: 1.0 / 8),
        .init(label: "1/15", seconds: 1.0 / 15),
        .init(label: "1/30", seconds: 1.0 / 30),
        .init(label: "1/60", seconds: 1.0 / 60),
        .init(label: "1/125", seconds: 1.0 / 125),
        .init(label: "1/250", seconds: 1.0 / 250),
        .init(label: "1/500", seconds: 1.0 / 500),
        .init(label: "1/1000", seconds: 1.0 / 1000),
        .init(label: "1/2000", seconds: 1.0 / 2000),
        .init(label: "1/4000", seconds: 1.0 / 4000),
    ]

    static let apertures: [Aperture] =
        [2.8, 4, 5.6, 8, 11, 16, 22].map(Aperture.init)
}
