import SwiftUI

/// Logo « Diaphragme » : iris à 7 lamelles (comme les 7 crans d'ouverture
/// du 28mm), cœur rouge = point de mesure. Même géométrie que l'icône
/// d'app (scripts/generate-appicon.swift) — espace de référence 100×100.
struct LumaLogo: View {
    var color: Color = Theme.ink
    var centerColor: Color = Theme.fm2Red

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height) / 100
            ZStack {
                Circle()
                    .strokeBorder(color, lineWidth: 7 * s)
                ForEach(0..<7, id: \.self) { blade in
                    IrisBlade()
                        .stroke(color, style: StrokeStyle(lineWidth: 5 * s,
                                                          lineCap: .round))
                        .rotationEffect(.degrees(Double(blade) * 360 / 7))
                }
                Circle()
                    .fill(centerColor)
                    .frame(width: 11 * s, height: 11 * s)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Une lamelle : du sommet de l'heptagone intérieur vers le fût, tangente
/// à l'ouverture (les 6 autres s'obtiennent par rotation de 360/7°).
private struct IrisBlade: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 100
        var p = Path()
        p.move(to: CGPoint(x: 50 * s, y: 36 * s))
        p.addLine(to: CGPoint(x: 78.4 * s, y: 27.8 * s))
        return p
    }
}

#Preview("Encre sur champagne") {
    LumaLogo()
        .frame(width: 80, height: 80)
        .padding(40)
        .background(Theme.background)
}

#Preview("Crème sur cuir") {
    LumaLogo(color: Theme.cream)
        .frame(width: 80, height: 80)
        .padding(40)
        .background(Theme.leather)
}
