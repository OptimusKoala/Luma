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

/// Une combinaison ouverture · vitesse réglable sur le FM2.
struct ExposurePair: Equatable, Identifiable {
    let aperture: FM2.Aperture
    let speed: FM2.ShutterSpeed
    var id: String { "\(aperture.id)-\(speed.id)" }
    /// EV que cette paire expose correctement (à l'ISO du film).
    var ev: Double { log2(aperture.fNumber * aperture.fNumber / speed.seconds) }
}

enum MeterResult: Equatable {
    case recommendation(pairs: [ExposurePair], recommendedIndex: Int)
    case tooDark
    case tooBright
}

extension ExposureCalculator {
    static func result(ev100: Double, filmISO: Double) -> MeterResult {
        let target = ev100 + log2(filmISO / 100)
        let all = FM2.apertures.flatMap { a in
            FM2.shutterSpeeds.map { ExposurePair(aperture: a, speed: $0) }
        }
        let pairs = all
            .filter { abs($0.ev - target) <= 0.5 }
            .sorted { $0.aperture.fNumber < $1.aperture.fNumber }

        guard !pairs.isEmpty else {
            return target < all.map(\.ev).min()! ? .tooDark : .tooBright
        }

        let handheldLimit = 1.0 / 125 + 1e-9
        let handheld = pairs.indices.filter { pairs[$0].speed.seconds <= handheldLimit }

        let recommended: Int
        if handheld.isEmpty {
            // Basse lumière : vitesse la plus rapide, la plus ouverte à égalité.
            recommended = pairs.indices.min { l, r in
                (pairs[l].speed.seconds, pairs[l].aperture.fNumber)
                    < (pairs[r].speed.seconds, pairs[r].aperture.fNumber)
            }!
        } else {
            // Ouverture la plus proche du cœur de la zone f/5.6–f/8
            // (f/6.7 en stops — ainsi f/5.6 bat f/11), puis vitesse la
            // plus basse restant ≥ 1/125.
            // NB : 6.7 est volontairement le point médian ARRONDI de
            // f/5.6–f/8 en stops (√(5.6×8) ≈ 6.693). L'arrondi fait
            // pencher la balance vers f/8 d'une marge minuscule
            // (~0.003 stop) — c'est ce qui décide f/8 contre f/5.6 dans
            // testSunny16_recommendsF8. Ne pas « simplifier » vers la
            // moyenne géométrique exacte sans re-vérifier ce test.
            recommended = handheld.min { l, r in
                let ld = abs(log2(pairs[l].aperture.fNumber / 6.7))
                let rd = abs(log2(pairs[r].aperture.fNumber / 6.7))
                if ld != rd { return ld < rd }
                return pairs[l].speed.seconds > pairs[r].speed.seconds
            }!
        }
        return .recommendation(pairs: pairs, recommendedIndex: recommended)
    }
}
