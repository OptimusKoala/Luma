import Foundation

/// Une phrase simple par cran : l'effet concret du réglage.
enum Pedagogy {
    static func hint(aperture: FM2.Aperture) -> String {
        switch aperture.fNumber {
        case 2.8: "sujet isolé, arrière-plan très flou"
        case 4:   "sujet détaché, arrière-plan doux"
        case 5.6: "sujet net, arrière-plan légèrement flou"
        case 8:   "presque tout net — le réglage passe-partout"
        case 11:  "grande zone de netteté, idéal paysage"
        case 16:  "tout net, du premier plan à l'infini"
        case 22:  "netteté maximale en profondeur"
        default:  ""
        }
    }

    static func hint(speed: FM2.ShutterSpeed) -> String {
        switch speed.label {
        case "1/4000", "1/2000": "fige n'importe quel mouvement"
        case "1/1000", "1/500":  "fige un sujet rapide"
        case "1/250", "1/125":   "fige la marche, aucun risque de bougé"
        case "1/60":             "ok à main levée, sujets calmes"
        case "1/30":             "risque de flou — cale tes coudes"
        case "1/15", "1/8":      "flou probable — appui ou trépied conseillé"
        default:                 "trépied indispensable"
        }
    }
}
