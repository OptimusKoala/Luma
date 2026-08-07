import Foundation

/// Scène de lumière type pour la mesure manuelle — la table d'exposition
/// classique (règle « Sunny 16 »). C'est le repli quand la caméra est
/// refusée ou absente : l'app reste un posemètre complet, l'utilisateur
/// décrit sa lumière au lieu de la mesurer.
struct LightScene: Equatable, Identifiable {
    let name: String
    /// Le repère concret qui permet de reconnaître la scène à l'œil.
    let detail: String
    /// Symbole SF affiché dans le sélecteur.
    let symbol: String
    let ev100: Double
    var id: Double { ev100 }

    /// Du plus lumineux au plus sombre. Les EV suivent la table d'exposition
    /// standard (ANSI) ; tous restent dans la plage réglable du FM2 pour les
    /// pelliculles courantes (voir LightSceneTests).
    static let catalog: [LightScene] = [
        .init(name: "Plein soleil",
              detail: "ombres nettes et noires",
              symbol: "sun.max.fill", ev100: 15),
        .init(name: "Soleil voilé",
              detail: "ombres présentes mais douces",
              symbol: "sun.haze.fill", ev100: 14),
        .init(name: "Nuageux lumineux",
              detail: "à peine une ombre au sol",
              symbol: "cloud.sun.fill", ev100: 13),
        .init(name: "Ciel couvert",
              detail: "aucune ombre",
              symbol: "cloud.fill", ev100: 12),
        .init(name: "Ombre · coucher de soleil",
              detail: "sujet à l'ombre en journée",
              symbol: "sunset.fill", ev100: 11),
        .init(name: "Intérieur lumineux",
              detail: "en journée, près d'une fenêtre",
              symbol: "house.fill", ev100: 8),
        .init(name: "Intérieur le soir",
              detail: "éclairage artificiel domestique",
              symbol: "lightbulb.fill", ev100: 5),
    ]

    /// Présélection du mode manuel : une recommandation s'affiche d'emblée.
    static let `default` = catalog[0]
}
