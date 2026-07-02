import SwiftUI

/// Palette « Chrome & cuir » — inspirée du boîtier FM2 chromé.
enum Theme {
    /// Argent champagne (fond clair, dégradé haut).
    static let chromeLight = Color(red: 0.96, green: 0.95, blue: 0.94)
    /// Argent champagne (dégradé bas).
    static let chromeDark = Color(red: 0.86, green: 0.85, blue: 0.82)
    /// Noir cuir grainé (panneaux sombres).
    static let leather = Color(red: 0.12, green: 0.12, blue: 0.11)
    /// Rouge FM2 (gravure des vitesses) — vitesse + accents.
    static let fm2Red = Color(red: 0.75, green: 0.22, blue: 0.17)
    /// Texte principal sur fond clair.
    static let ink = Color(red: 0.10, green: 0.10, blue: 0.10)
    /// Texte secondaire / légendes.
    static let subtle = Color(red: 0.54, green: 0.53, blue: 0.50)
    /// Texte clair sur cuir.
    static let cream = Color(red: 0.94, green: 0.93, blue: 0.90)

    static let background = LinearGradient(
        colors: [chromeLight, chromeDark],
        startPoint: .top, endPoint: .bottom)

    /// Grandes valeurs (f/5.6, 1/500…) — chiffres tabulaires arrondis.
    static func valueFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    /// Petites légendes en capitales espacées.
    static let caption = Font.system(size: 10, weight: .semibold)
}
