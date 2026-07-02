import SwiftUI

struct RecommendationView: View {
    let pair: ExposurePair
    let filmISO: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                value(pair.aperture.label, caption: "OUVERTURE", color: Theme.ink)
                divider
                value(pair.speed.label, caption: "VITESSE", color: Theme.fm2Red)
                divider
                value("\(Int(filmISO))", caption: "ISO FILM", color: Theme.ink)
            }
            VStack(spacing: 2) {
                Text("\(pair.aperture.label) — \(Pedagogy.hint(aperture: pair.aperture))")
                Text("\(pair.speed.label) — \(Pedagogy.hint(speed: pair.speed))")
            }
            .font(.system(size: 11))
            .foregroundStyle(Theme.subtle)
        }
    }

    private var divider: some View {
        Rectangle().fill(Theme.subtle.opacity(0.4)).frame(width: 1, height: 40)
    }

    private func value(_ text: String, caption: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(text)
                .font(Theme.valueFont(30))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(caption).font(Theme.caption).kerning(2)
                .foregroundStyle(Theme.subtle)
        }
        .frame(maxWidth: .infinity)
    }
}
