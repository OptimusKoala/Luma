#if DEBUG
import SwiftUI

/// Mode captures d'écran pour l'App Store — **compilé uniquement en DEBUG**,
/// donc absent du binaire envoyé à Apple.
///
/// Pourquoi il existe : le simulateur n'a pas de caméra, et Luma y afficherait
/// un viseur vide. Ce mode remplace le flux caméra par une scène **dessinée par
/// code** (aucune photo, donc aucune question de droits) et fixe l'EV mesuré.
///
/// Ce qu'il ne fait pas : truquer les valeurs. L'EV est injecté comme le fait
/// déjà `MeterView(demoEV100:)`, puis `ExposureCalculator` produit ouverture,
/// vitesse et ISO par le chemin de production. Les chiffres visibles sur les
/// captures sont ceux que l'app calcule réellement pour cette lumière.
///
/// Activation : variable d'environnement `LUMA_SCREENSHOT=<clé>` au lancement,
/// posée par `scripts/screenshots-simulateur.sh`.
enum ScreenshotMode {

    struct Scene {
        /// EV de la scène, normalisé ISO 100 — l'entrée du calcul réel.
        let ev100: Double
        let filmName: String?
        /// Position du cercle de mesure spot, en coordonnées relatives (0…1).
        let spot: CGPoint?
        /// Décalage par rapport à la paire recommandée, pour montrer la molette
        /// déplacée par l'utilisateur.
        let dialOffset: Int?
        let showFilmPicker: Bool
        let decor: Decor

        var film: FilmStock? {
            filmName.flatMap { nom in FilmStock.catalog.first { $0.name == nom } }
        }
    }

    /// Décor de la scène : un ciel, éventuellement un horizon et un sol, une
    /// source de lumière et des masses floues. De quoi évoquer une scène
    /// photographique sans prétendre être une photographie.
    struct Decor {
        let ciel: [Color]
        /// Position relative de la ligne d'horizon (nil = pas de sol).
        let horizon: CGFloat?
        let sol: [Color]
        let lumiere: (position: UnitPoint, teinte: Color, rayon: CGFloat)?
        let masses: [Masse]
        /// Flou d'ensemble, relatif au côté de la vue. Discret : un viseur
        /// n'est pas net, mais ce n'est pas du brouillard non plus.
        let flou: CGFloat

        /// Masse de couleur : feuillage, silhouette, halo de lampadaire.
        struct Masse {
            let position: UnitPoint
            /// Largeur relative au côté de la vue.
            let largeur: CGFloat
            /// Hauteur rapportée à la largeur — 1 = disque, 2 = silhouette.
            let elancement: CGFloat
            let teinte: Color
            let opacite: Double
            /// Flou propre, relatif au côté.
            let flou: CGFloat
        }
    }

    static let scenes: [String: Scene] = [

        // 1. Plein soleil, paysage : le cas d'école, celui de la première
        //    capture — c'est elle qu'on voit dans les résultats de recherche.
        "plein-jour": Scene(
            ev100: 14, filmName: "Portra 400", spot: nil, dialOffset: nil,
            showFilmPicker: false,
            decor: Decor(
                ciel: [Color(red: 0.42, green: 0.66, blue: 0.88),
                       Color(red: 0.68, green: 0.82, blue: 0.92),
                       Color(red: 0.90, green: 0.90, blue: 0.84)],
                horizon: 0.63,
                sol: [Color(red: 0.55, green: 0.58, blue: 0.34),
                      Color(red: 0.36, green: 0.42, blue: 0.22),
                      Color(red: 0.24, green: 0.29, blue: 0.15)],
                lumiere: (UnitPoint(x: 0.80, y: 0.14),
                          Color(red: 1, green: 0.97, blue: 0.86), 0.34),
                masses: [
                    // Deux masses d'arbres posées sur l'horizon.
                    .init(position: UnitPoint(x: 0.20, y: 0.575), largeur: 0.30,
                          elancement: 0.72, teinte: Color(red: 0.20, green: 0.30, blue: 0.16),
                          opacite: 0.92, flou: 0.010),
                    .init(position: UnitPoint(x: 0.74, y: 0.60), largeur: 0.20,
                          elancement: 0.62, teinte: Color(red: 0.24, green: 0.33, blue: 0.18),
                          opacite: 0.85, flou: 0.010),
                    .init(position: UnitPoint(x: 0.46, y: 0.615), largeur: 0.12,
                          elancement: 0.55, teinte: Color(red: 0.27, green: 0.35, blue: 0.20),
                          opacite: 0.70, flou: 0.012),
                ],
                flou: 0.0015)),

        // 2. Molette déplacée : l'utilisateur a choisi une autre paire que la
        //    recommandation. Scène de fin de journée, faible profondeur.
        "molette": Scene(
            ev100: 12, filmName: "Tri-X 400", spot: nil, dialOffset: 2,
            showFilmPicker: false,
            decor: Decor(
                ciel: [Color(red: 0.80, green: 0.72, blue: 0.60),
                       Color(red: 0.56, green: 0.48, blue: 0.42),
                       Color(red: 0.26, green: 0.23, blue: 0.21)],
                horizon: nil, sol: [],
                lumiere: (UnitPoint(x: 0.22, y: 0.24),
                          Color(red: 1, green: 0.92, blue: 0.74), 0.30),
                masses: [
                    // Halos de lumière hors mise au point.
                    .init(position: UnitPoint(x: 0.68, y: 0.30), largeur: 0.16,
                          elancement: 1, teinte: Color(red: 1, green: 0.93, blue: 0.76),
                          opacite: 0.34, flou: 0.022),
                    .init(position: UnitPoint(x: 0.82, y: 0.46), largeur: 0.11,
                          elancement: 1, teinte: Color(red: 1, green: 0.90, blue: 0.72),
                          opacite: 0.26, flou: 0.020),
                    .init(position: UnitPoint(x: 0.56, y: 0.20), largeur: 0.08,
                          elancement: 1, teinte: Color(red: 1, green: 0.95, blue: 0.80),
                          opacite: 0.22, flou: 0.018),
                    // Masse sombre au premier plan, en bas à gauche.
                    .init(position: UnitPoint(x: 0.22, y: 0.90), largeur: 0.44,
                          elancement: 0.50, teinte: Color(red: 0.12, green: 0.11, blue: 0.10),
                          opacite: 0.72, flou: 0.024),
                ],
                flou: 0.002)),

        // 3. Sélecteur de pellicule ouvert : la feuille couvre le bas, le
        //    viseur ne se voit qu'en haut. Scène volontairement sobre.
        "pellicule": Scene(
            ev100: 13, filmName: "Portra 400", spot: nil, dialOffset: nil,
            showFilmPicker: true,
            decor: Decor(
                ciel: [Color(red: 0.50, green: 0.70, blue: 0.86),
                       Color(red: 0.78, green: 0.84, blue: 0.86)],
                horizon: 0.74,
                sol: [Color(red: 0.48, green: 0.50, blue: 0.44),
                      Color(red: 0.30, green: 0.32, blue: 0.27)],
                lumiere: (UnitPoint(x: 0.62, y: 0.18),
                          Color(red: 1, green: 0.98, blue: 0.90), 0.28),
                masses: [
                    .init(position: UnitPoint(x: 0.30, y: 0.70), largeur: 0.26,
                          elancement: 0.60, teinte: Color(red: 0.26, green: 0.31, blue: 0.22),
                          opacite: 0.80, flou: 0.012),
                ],
                flou: 0.0015)),

        // 4. Mesure spot sur un sujet en contre-jour — le cas où elle sert.
        //    La silhouette est placée sous le cercle de mesure.
        // Contre-jour de fin de journée : le cercle est posé sur la zone
        // d'ombre, celle qu'on veut exposer correctement. Le haut du ciel reste
        // en demi-teinte pour que les libellés du viseur restent lisibles.
        "spot": Scene(
            ev100: 13, filmName: "HP5+ 400", spot: CGPoint(x: 0.42, y: 0.70),
            dialOffset: nil, showFilmPicker: false,
            decor: Decor(
                ciel: [Color(red: 0.38, green: 0.46, blue: 0.56),
                       Color(red: 0.72, green: 0.66, blue: 0.54),
                       Color(red: 0.92, green: 0.80, blue: 0.58)],
                horizon: 0.54,
                sol: [Color(red: 0.20, green: 0.17, blue: 0.15),
                      Color(red: 0.09, green: 0.08, blue: 0.07)],
                lumiere: (UnitPoint(x: 0.74, y: 0.46),
                          Color(red: 1, green: 0.90, blue: 0.64), 0.30),
                masses: [
                    // Masses sombres du premier plan : la zone mesurée.
                    .init(position: UnitPoint(x: 0.40, y: 0.66), largeur: 0.46,
                          elancement: 0.42, teinte: Color(red: 0.08, green: 0.07, blue: 0.06),
                          opacite: 0.85, flou: 0.014),
                    .init(position: UnitPoint(x: 0.84, y: 0.58), largeur: 0.24,
                          elancement: 0.50, teinte: Color(red: 0.11, green: 0.10, blue: 0.09),
                          opacite: 0.70, flou: 0.016),
                ],
                flou: 0.0015)),

        // 5. Hors plage : l'app refuse de donner une valeur fausse.
        "trop-sombre": Scene(
            ev100: -3, filmName: "Portra 400", spot: nil, dialOffset: nil,
            showFilmPicker: false,
            decor: Decor(
                ciel: [Color(red: 0.07, green: 0.10, blue: 0.18),
                       Color(red: 0.05, green: 0.06, blue: 0.11)],
                horizon: 0.58,
                sol: [Color(red: 0.05, green: 0.05, blue: 0.07),
                      Color(red: 0.02, green: 0.02, blue: 0.03)],
                lumiere: (UnitPoint(x: 0.28, y: 0.50),
                          Color(red: 1, green: 0.78, blue: 0.44), 0.14),
                masses: [
                    // Quelques lumières lointaines.
                    .init(position: UnitPoint(x: 0.28, y: 0.50), largeur: 0.030,
                          elancement: 1, teinte: Color(red: 1, green: 0.86, blue: 0.58),
                          opacite: 0.85, flou: 0.006),
                    .init(position: UnitPoint(x: 0.66, y: 0.545), largeur: 0.022,
                          elancement: 1, teinte: Color(red: 1, green: 0.84, blue: 0.56),
                          opacite: 0.70, flou: 0.006),
                    .init(position: UnitPoint(x: 0.80, y: 0.535), largeur: 0.016,
                          elancement: 1, teinte: Color(red: 0.96, green: 0.88, blue: 0.70),
                          opacite: 0.55, flou: 0.005),
                ],
                flou: 0.002)),
    ]

    /// Scène demandée au lancement, s'il y en a une.
    static let current: Scene? = {
        guard let cle = ProcessInfo.processInfo.environment["LUMA_SCREENSHOT"] else {
            return nil
        }
        return scenes[cle]
    }()
}

/// Rend le décor d'une scène. Volontairement abstrait : des masses de couleur
/// floues, pas une fausse photographie.
struct SyntheticSceneView: View {
    let decor: ScreenshotMode.Decor

    var body: some View {
        GeometryReader { geo in
            let cote = max(geo.size.width, geo.size.height)
            ZStack {
                LinearGradient(colors: decor.ciel,
                               startPoint: .top, endPoint: .bottom)

                if let lumiere = decor.lumiere {
                    RadialGradient(
                        colors: [lumiere.teinte, lumiere.teinte.opacity(0)],
                        center: lumiere.position,
                        startRadius: 0,
                        endRadius: cote * lumiere.rayon)
                    .blendMode(.screen)
                }

                if let horizon = decor.horizon, !decor.sol.isEmpty {
                    VStack(spacing: 0) {
                        Spacer()
                        LinearGradient(colors: decor.sol,
                                       startPoint: .top, endPoint: .bottom)
                        .frame(height: geo.size.height * (1 - horizon))
                    }
                }

                // Après le sol : un arbre ou une silhouette se posent devant
                // lui. Dessinées avant, elles seraient tranchées net par la
                // ligne d'horizon.
                masses(dans: geo.size, cote: cote)
            }
            // Flou d'ensemble discret : un viseur n'est jamais parfaitement net.
            .blur(radius: cote * decor.flou)
        }
    }

    private func masses(dans taille: CGSize, cote: CGFloat) -> some View {
        ForEach(Array(decor.masses.enumerated()), id: \.offset) { _, masse in
            let largeur = cote * masse.largeur
            Ellipse()
                .fill(masse.teinte)
                .opacity(masse.opacite)
                .frame(width: largeur, height: largeur * masse.elancement)
                .blur(radius: cote * masse.flou)
                .position(x: taille.width * masse.position.x,
                          y: taille.height * masse.position.y)
        }
    }
}

#Preview("Scènes de capture") {
    let cles = ["plein-jour", "molette", "spot", "trop-sombre"]
    return VStack(spacing: 8) {
        ForEach(cles, id: \.self) { cle in
            if let scene = ScreenshotMode.scenes[cle] {
                SyntheticSceneView(decor: scene.decor)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    .padding()
}
#endif
