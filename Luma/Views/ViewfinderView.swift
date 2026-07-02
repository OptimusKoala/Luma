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
                // Preview Xcode / simulateur : fond neutre.
                LinearGradient(colors: [Color(white: 0.35), Color(white: 0.15)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }

            if let spot = camera.spotPoint {
                Circle()
                    .stroke(Theme.cream, lineWidth: 1.5)
                    .frame(width: 44, height: 44)
                    .position(spot)
                    .shadow(radius: 4)
            }

            VStack {
                HStack {
                    Text(camera.spotPoint == nil ? "MESURE MOYENNE" : "MESURE SPOT")
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
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}
