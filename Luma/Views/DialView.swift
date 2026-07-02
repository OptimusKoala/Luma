import SwiftUI

/// Rangée horizontale des paires équivalentes. La paire recommandée est
/// encadrée de rouge. Simplification v1 assumée : le scroll sert à parcourir,
/// c'est le TAP qui sélectionne (avec retour haptique) — pas de cliquet par
/// cran pendant le glissement. selection == nil → suivre la recommandation.
struct DialView: View {
    let pairs: [ExposurePair]
    let recommendedIndex: Int
    @Binding var selection: ExposurePair.ID?

    private var activeID: ExposurePair.ID? {
        selection ?? pairs[safe: recommendedIndex]?.id
    }

    var body: some View {
        VStack(spacing: 7) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(pairs) { pair in
                            let isActive = pair.id == activeID
                            let isReco = pair.id == pairs[safe: recommendedIndex]?.id
                            Text("\(pair.aperture.label) · \(pair.speed.label)")
                                .font(.system(size: isActive ? 14 : 12,
                                              weight: isActive ? .bold : .regular))
                                .foregroundStyle(isActive ? Theme.cream : Theme.subtle)
                                .padding(.vertical, 5).padding(.horizontal, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(isActive ? Color(white: 0.22) : .clear)
                                        .strokeBorder(isReco ? Theme.fm2Red : .clear,
                                                      lineWidth: 1)
                                )
                                .onTapGesture {
                                    selection = isReco ? nil : pair.id
                                }
                                .id(pair.id)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .onChange(of: activeID) { _, id in
                    withAnimation(.snappy) { proxy.scrollTo(id, anchor: .center) }
                }
            }
            Text("◂ FLOU D'ARRIÈRE-PLAN · NETTETÉ PARTOUT ▸")
                .font(.system(size: 8, weight: .semibold))
                .kerning(1.5)
                .foregroundStyle(Theme.subtle)
        }
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.leather))
        .sensoryFeedback(.selection, trigger: activeID)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
