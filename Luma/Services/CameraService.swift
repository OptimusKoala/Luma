import AVFoundation
import Combine
import CoreGraphics

/// Seule classe qui touche AVFoundation. Publie les lectures d'exposition
/// et gère la mesure spot. Tout le calcul vit dans ExposureCalculator.
@MainActor
final class CameraService: ObservableObject {

    enum Status: Equatable {
        case idle, running, denied, unavailable
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var reading: ExposureReading?
    /// Point de mesure spot en coordonnées de la vue (nil = mesure moyenne).
    @Published private(set) var spotPoint: CGPoint?

    let session = AVCaptureSession()
    private var device: AVCaptureDevice?
    private var offsetObservation: NSKeyValueObservation?

    func start() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            guard await AVCaptureDevice.requestAccess(for: .video) else {
                status = .denied; return
            }
        default:
            status = .denied; return
        }
        configureAndRun()
    }

    private func configureAndRun() {
        guard let device = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            status = .unavailable
            return
        }
        self.device = device

        session.beginConfiguration()
        session.sessionPreset = .high
        if session.canAddInput(input) { session.addInput(input) }
        session.commitConfiguration()

        // exposureTargetOffset change à chaque itération de l'autoexposition :
        // un seul observateur suffit à rafraîchir toute la lecture.
        offsetObservation = device.observe(\.exposureTargetOffset,
                                           options: [.initial, .new]) { [weak self] device, _ in
            let reading = ExposureReading(
                iso: Double(device.iso),
                shutterSeconds: device.exposureDuration.seconds,
                aperture: Double(device.lensAperture),
                targetOffset: Double(device.exposureTargetOffset))
            // Précondition de ExposureCalculator.ev100 (log2 et division) :
            // une lecture dégénérée produirait NaN/±Inf et polluerait le lissage.
            guard reading.iso > 0, reading.shutterSeconds.isFinite,
                  reading.shutterSeconds > 0, reading.aperture > 0 else { return }
            Task { @MainActor [weak self] in self?.reading = reading }
        }

        let session = self.session
        Task.detached(priority: .userInitiated) { session.startRunning() }
        status = .running
    }

    /// Mesure spot. `devicePoint` : coordonnées caméra (0–1, fournies par la
    /// preview layer) ; `viewPoint` : coordonnées de la vue (pour le cercle).
    func meterSpot(devicePoint: CGPoint, viewPoint: CGPoint) {
        guard let device, device.isExposurePointOfInterestSupported,
              (try? device.lockForConfiguration()) != nil else { return }
        device.exposurePointOfInterest = devicePoint
        device.exposureMode = .continuousAutoExposure
        device.unlockForConfiguration()
        spotPoint = viewPoint
    }

    /// Retour à la mesure moyenne (point d'intérêt recentré).
    func meterAverage() {
        guard let device,
              (try? device.lockForConfiguration()) != nil else { return }
        if device.isExposurePointOfInterestSupported {
            device.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
        }
        device.exposureMode = .continuousAutoExposure
        device.unlockForConfiguration()
        spotPoint = nil
    }
}
