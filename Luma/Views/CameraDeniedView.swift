import SwiftUI

struct CameraDeniedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.subtle)
            Text("Luma a besoin de la caméra")
                .font(.headline).foregroundStyle(Theme.ink)
            Text("C'est elle qui mesure la lumière de la scène pour calculer les réglages de ton FM2. Aucune photo n'est enregistrée.")
                .font(.subheadline).foregroundStyle(Theme.subtle)
                .multilineTextAlignment(.center)
            Button("Ouvrir les Réglages") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.fm2Red)
        }
        .padding(32)
    }
}
