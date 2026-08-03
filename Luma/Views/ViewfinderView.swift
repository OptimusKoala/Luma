import SwiftUI
import AVFoundation

/// Preview caméra UIKit (AVCaptureVideoPreviewLayer) + conversion des taps
/// en coordonnées caméra.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var onTap: (_ devicePoint: CGPoint, _ viewPoint: CGPoint) -> Void

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        var onTap: ((CGPoint, CGPoint) -> Void)?

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let viewPoint = gesture.location(in: self)
            let devicePoint = previewLayer.captureDevicePointConverted(
                fromLayerPoint: viewPoint)
            onTap?(devicePoint, viewPoint)
        }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.onTap = onTap
        view.addGestureRecognizer(UITapGestureRecognizer(
            target: view, action: #selector(PreviewView.handleTap(_:))))
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {
        view.onTap = onTap
    }
}

/// Le viseur complet : preview, badge de mode, EV courant, cercle spot.
struct ViewfinderView: View {
    @ObservedObject var camera: CameraService
    let ev100: Double?

    var body: some View {
        ZStack {
            if camera.status == .running {
                CameraPreview(session: camera.session) { devicePoint, viewPoint in
                    // Toucher le cercle = retour en moyenne ; ailleurs = spot.
                    if let spot = camera.spotPoint, spot.distance(to: viewPoint) < 44 {
                        camera.meterAverage()
                    } else {
                        camera.meterSpot(devicePoint: devicePoint, viewPoint: viewPoint)
                    }
                }
            } else {
                #if DEBUG
                // Mode captures d'écran : scène dessinée, faute de caméra sur
                // simulateur (voir ScreenshotMode).
                if let scene = ScreenshotMode.current {
                    SyntheticSceneView(decor: scene.decor)
                } else {
                    fondNeutre
                }
                #else
                fondNeutre
                #endif
            }

            if let spot = camera.spotPoint {
                cercleSpot.position(spot)
            }

            #if DEBUG
            // Le cercle spot des captures est posé en coordonnées relatives :
            // sa position ne peut être connue qu'à la mise en page.
            if let relatif = ScreenshotMode.current?.spot {
                GeometryReader { geo in
                    cercleSpot.position(x: geo.size.width * relatif.x,
                                       y: geo.size.height * relatif.y)
                }
            }
            #endif

            VStack {
                HStack {
                    Text(mesureSpotActive ? "MESURE SPOT" : "MESURE MOYENNE")
                    Spacer()
                    if let ev100 {
                        Text("EV \(ev100, specifier: "%.1f")")
                    }
                }
                .font(Theme.caption)
                .kerning(1.5)
                .foregroundStyle(Theme.cream.opacity(0.7))
                .padding(10)
                Spacer()
                Text("touche une zone pour la mesurer · touche le cercle pour revenir")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.cream.opacity(0.45))
                    .padding(.bottom, 8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18)
            .strokeBorder(Theme.leather, lineWidth: 3))
    }

    /// Preview Xcode / simulateur sans mesure : fond neutre.
    private var fondNeutre: some View {
        LinearGradient(colors: [Color(white: 0.35), Color(white: 0.15)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var cercleSpot: some View {
        Circle()
            .stroke(Theme.cream, lineWidth: 1.5)
            .frame(width: 44, height: 44)
            .shadow(radius: 4)
    }

    private var mesureSpotActive: Bool {
        #if DEBUG
        if ScreenshotMode.current?.spot != nil { return true }
        #endif
        return camera.spotPoint != nil
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}
