import Foundation

/// Instantané des valeurs d'autoexposition de la caméra iPhone.
struct ExposureReading: Equatable {
    var iso: Double
    var shutterSeconds: Double
    var aperture: Double
    /// AVCaptureDevice.exposureTargetOffset (EV) : négatif = image obtenue
    /// plus sombre que la cible.
    var targetOffset: Double
}

/// Moyenne glissante sur les 10 dernières mesures — stabilise l'affichage.
struct EVSmoother {
    private var samples: [Double] = []
    private let window = 10

    mutating func add(_ value: Double) -> Double {
        samples.append(value)
        if samples.count > window { samples.removeFirst() }
        return samples.reduce(0, +) / Double(samples.count)
    }
}

enum ExposureCalculator {
    /// EV de la scène normalisé ISO 100.
    static func ev100(from r: ExposureReading) -> Double {
        log2(r.aperture * r.aperture / r.shutterSeconds)
            - log2(r.iso / 100)
            + r.targetOffset
    }
}
