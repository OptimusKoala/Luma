import SwiftUI

struct MeterView: View {
    @StateObject private var camera = CameraService()
    @AppStorage("filmStock") private var filmData: Data?
    @State private var film: FilmStock = .default
    @State private var smoother = EVSmoother()
    @State private var smoothedEV: Double?
    @State private var dialSelection: ExposurePair.ID?
    @State private var showFilmPicker = false

    /// Preview Xcode / simulateur : EV fixe pour travailler l'interface.
    var demoEV100: Double? = nil

    private var ev100: Double? { demoEV100 ?? smoothedEV }

    private var result: MeterResult? {
        ev100.map { ExposureCalculator.result(ev100: $0, filmISO: film.iso) }
    }

    var body: some View {
        VStack(spacing: 16) {
            header
            ViewfinderView(camera: camera, ev100: ev100)
                .frame(maxHeight: .infinity)
            bottomPanel
        }
        .padding(16)
        .background(Theme.background.ignoresSafeArea())
        .task {
            if demoEV100 == nil { await camera.start() }
            if let filmData,
               let saved = try? JSONDecoder().decode(FilmStock.self, from: filmData) {
                film = saved
            }
        }
        .onChange(of: camera.reading) { _, reading in
            guard let reading else { return }
            smoothedEV = smoother.add(ExposureCalculator.ev100(from: reading))
        }
        .onChange(of: film) { _, newValue in
            dialSelection = nil
            filmData = try? JSONEncoder().encode(newValue)
        }
        .onChange(of: result) { _, newValue in
            guard let dialSelection else { return }
            if case let .recommendation(pairs, _) = newValue,
               pairs.contains(where: { $0.id == dialSelection }) { return }
            // La paire choisie n'existe plus (lumière changée ou hors plage) :
            // on revient au suivi de la recommandation.
            self.dialSelection = nil
        }
        .sheet(isPresented: $showFilmPicker) {
            FilmPickerSheet(film: $film)
        }
        .overlay {
            if camera.status == .denied { deniedOverlay }
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                LumaLogo()
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)
                Text("LUMA")
                    .font(.system(size: 15, weight: .heavy)).kerning(6)
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            Button { showFilmPicker = true } label: {
                HStack(spacing: 6) {
                    Circle().fill(Theme.fm2Red).frame(width: 8, height: 8)
                    Text(film.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.cream)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.subtle)
                }
                .padding(.vertical, 6).padding(.horizontal, 12)
                .background(Capsule().fill(Theme.leather))
            }
        }
    }

    @ViewBuilder
    private var bottomPanel: some View {
        switch result {
        case .recommendation(let pairs, let recommendedIndex):
            let active = pairs.first { $0.id == dialSelection }
                ?? pairs[safe: recommendedIndex]
            VStack(spacing: 14) {
                DialView(pairs: pairs, recommendedIndex: recommendedIndex,
                         selection: $dialSelection)
                if let active {
                    RecommendationView(pair: active, filmISO: film.iso)
                }
            }
        case .tooDark:
            outOfRange("Trop sombre pour le FM2 à main levée",
                       hint: "Même f/2.8 à 1s sous-exposerait. Cherche de la lumière ou passe en pose B avec un trépied.")
        case .tooBright:
            outOfRange("Trop lumineux pour cette pellicule",
                       hint: "Même f/22 à 1/4000 surexposerait. Un film moins sensible ou un filtre ND serait nécessaire.")
        case nil:
            ProgressView().frame(height: 120)
        }
    }

    private func outOfRange(_ title: String, hint: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.fm2Red)
            Text(hint)
                .font(.system(size: 12)).foregroundStyle(Theme.subtle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(RoundedRectangle(cornerRadius: 14)
            .fill(Theme.leather.opacity(0.06)))
    }

    private var deniedOverlay: some View {
        Theme.background.ignoresSafeArea()
            .overlay(CameraDeniedView())
    }
}

#Preview("Plein jour") { MeterView(demoEV100: 14) }
#Preview("Basse lumière") { MeterView(demoEV100: 5) }
#Preview("Trop sombre") { MeterView(demoEV100: -6) }
