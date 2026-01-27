import Foundation
import VisionKit
import AVFoundation

@Observable
final class TextRecognitionService: NSObject {
    var isAvailable: Bool = false
    var permissionStatus: AVAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        checkAvailability()
        checkPermission()
    }

    func checkAvailability() {
        isAvailable = DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func checkPermission() {
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestPermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            checkPermission()
        }
        return granted
    }
}
