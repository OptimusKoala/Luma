import SwiftUI

/// Remplace le viseur quand la caméra est refusée ou absente : l'utilisateur
/// décrit sa lumière parmi les scènes types (table « Sunny 16 ») et Luma
/// reste un posemètre complet. La porte vers les Réglages n'est qu'un rappel
/// discret — jamais un passage obligé (rejet App Store 2.1(a) du 2026-08-07).
struct ManualSceneView: View {
    @Binding var selection: LightScene
    /// true : permission refusée (proposer les Réglages) ;
    /// false : pas de caméra sur l'appareil (rien à proposer).
    let cameraDenied: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("MESURE MANUELLE")
                Spacer()
                Text("EV \(selection.ev100, specifier: "%.0f")")
            }
            .font(Theme.caption)
            .kerning(1.5)
            .foregroundStyle(Theme.cream.opacity(0.7))
            .padding(10)

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(LightScene.catalog) { scene in
                        row(scene)
                    }
                }
                .padding(.horizontal, 10)
            }

            VStack(spacing: 6) {
                Text(cameraDenied
                     ? "avec la caméra, Luma mesurerait la lumière réelle de ta scène"
                     : "choisis la scène qui ressemble le plus à la tienne")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.cream.opacity(0.45))
                    .multilineTextAlignment(.center)
                if cameraDenied {
                    Button("Autoriser la caméra dans les Réglages") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .tint(Theme.cream.opacity(0.8))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Color(white: 0.22), Color(white: 0.12)],
                           startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18)
            .strokeBorder(Theme.leather, lineWidth: 3))
    }

    private func row(_ scene: LightScene) -> some View {
        let selected = scene == selection
        return Button {
            selection = scene
        } label: {
            HStack(spacing: 10) {
                Image(systemName: scene.symbol)
                    .font(.system(size: 15))
                    .frame(width: 24)
                    .foregroundStyle(selected ? Theme.fm2Red : Theme.cream.opacity(0.6))
                VStack(alignment: .leading, spacing: 1) {
                    Text(scene.name)
                        .font(.system(size: 13, weight: selected ? .bold : .medium))
                        .foregroundStyle(Theme.cream)
                    Text(scene.detail)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.cream.opacity(0.5))
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.fm2Red)
                }
            }
            .padding(.vertical, 7).padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(Theme.cream.opacity(selected ? 0.14 : 0.05)))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview("Caméra refusée") {
    ManualSceneView(selection: .constant(.default), cameraDenied: true)
        .padding(16)
        .background(Theme.background)
}
