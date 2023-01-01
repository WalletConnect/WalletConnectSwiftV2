import UIKit
import AVFoundation

protocol ScanQRViewDelegate: AnyObject {
    func scanDidDetect(value: String)
    func scanDidFail(with error: Error)
}

final class ScanQRView: UIView {
    enum Errors: Error {
        case deviceNotFound
    }

    weak var delegate: ScanQRViewDelegate?

    private let targetSize = CGSize(
        width: UIScreen.main.bounds.width - 32.0,
        height: UIScreen.main.bounds.width - 32.0
    )

    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var captureSession: AVCaptureSession?

    private lazy var borderView: UIView = {
        let borderView = ScanTargetView(radius: 24.0, color: UIColor(displayP3Red: 184/255, green: 245/255, blue: 61/255, alpha: 1.0), strokeWidth: 7, length: 60)
        return borderView
    }()

    private lazy var bluredView: UIView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let bluredView = UIVisualEffectView(effect: blurEffect)
        bluredView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bluredView.layer.mask = createMaskLayer()
        return bluredView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
        startCaptureSession()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateFrames()
        updateOrientation()
    }

    deinit {
        stopCaptureSession()
    }
}

// MARK: AVCaptureMetadataOutputObjectsDelegate

extension ScanQRView: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ metadataOutput: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        defer { stopCaptureSession() }
        guard
            let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let value = metadataObject.stringValue else {
                return
            }
        delegate?.scanDidDetect(value: value)
    }
}

// MARK: Privates

private extension ScanQRView {

    private func setupView() {
        backgroundColor = .black

        addSubview(bluredView)
        addSubview(borderView)
    }

    private func createMaskLayer() -> CAShapeLayer {
        let maskPath = UIBezierPath(rect: bounds)
        let rect = UIBezierPath(
            roundedRect: CGRect(
                x: center.x - targetSize.height * 0.5,
                y: center.y - targetSize.width * 0.5,
                width: targetSize.width,
                height: targetSize.height
            ),
            byRoundingCorners: .allCorners,
            cornerRadii: CGSize(width: 24.0, height: 24.0)
        )
        maskPath.append(rect)
        maskPath.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        maskLayer.fillRule = .evenOdd
        return maskLayer
    }

    private func startCaptureSession() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            do {
                let session = try self.createCaptureSession()
                session.startRunning()
                self.captureSession = session

                DispatchQueue.main.async { self.setupVideoPreviewLayer(with: session) }
            } catch {
                DispatchQueue.main.async { self.delegate?.scanDidFail(with: error) }
            }
        }
    }

    private func createCaptureSession() throws -> AVCaptureSession {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            throw Errors.deviceNotFound
        }

        let input = try AVCaptureDeviceInput(device: captureDevice)

        let session = AVCaptureSession()
        session.addInput(input)

        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: .main)
        session.addOutput(captureMetadataOutput)

        captureMetadataOutput.metadataObjectTypes = [.qr]

        return session
    }

    private func stopCaptureSession() {
        captureSession?.stopRunning()
        captureSession = nil
    }

    private func setupVideoPreviewLayer(with session: AVCaptureSession) {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.frame = layer.bounds
        videoPreviewLayer = previewLayer

        layer.insertSublayer(previewLayer, at: 0)
    }

    private func updateFrames() {
        borderView.frame.size = targetSize
        borderView.center = center
        bluredView.frame = bounds
        bluredView.layer.mask = createMaskLayer()
        videoPreviewLayer?.frame = layer.bounds
    }

    private func updateOrientation() {
        guard let connection = videoPreviewLayer?.connection else {
            return
        }
        let previewLayerConnection: AVCaptureConnection = connection

        guard previewLayerConnection.isVideoOrientationSupported else {
            return
        }
        switch UIDevice.current.orientation {
        case .portrait: return
            previewLayerConnection.videoOrientation = .portrait
        case .landscapeRight:
            previewLayerConnection.videoOrientation = .landscapeLeft
        case .landscapeLeft: return
            previewLayerConnection.videoOrientation = .landscapeRight
        case .portraitUpsideDown:
            previewLayerConnection.videoOrientation = .portraitUpsideDown
        default:
            previewLayerConnection.videoOrientation = .portrait
        }
    }
}
