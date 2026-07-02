import SwiftUI

/// Racine de l'app : MeterView démarre immédiatement (caméra comprise)
/// sous l'écran de lancement animé, qui se dissout une fois l'animation
/// jouée — le viseur est ainsi souvent déjà actif à la révélation.
struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            MeterView()
            if showSplash {
                LaunchSplashView()
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.7))
            withAnimation(.easeOut(duration: 0.45)) { showSplash = false }
        }
    }
}

/// Animation de lancement : le logo Diaphragme fait un tour sur lui-même
/// pendant que « LUMA » sort de derrière lui, révélé de gauche à droite.
struct LaunchSplashView: View {
    @State private var spin = false
    @State private var reveal = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            HStack(spacing: 14) {
                LumaLogo()
                    .frame(width: 54, height: 54)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .zIndex(1)
                Text("LUMA")
                    .font(.system(size: 32, weight: .heavy))
                    .kerning(10)
                    .foregroundStyle(Theme.ink)
                    .fixedSize()
                    // Révélation L→U→M→A : masque qui s'élargit vers la
                    // droite, plus un léger glissement de sortie du logo.
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: reveal ? 170 : 0)
                    }
                    .offset(x: reveal ? 0 : -26)
                    .frame(width: 160, alignment: .leading)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Luma")
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9)) { spin = true }
            withAnimation(.easeOut(duration: 0.7).delay(0.4)) { reveal = true }
        }
    }
}

#Preview("Splash") { LaunchSplashView() }
#Preview("Racine (démo impossible : caméra)") { RootView() }
