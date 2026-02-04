import SwiftUI
import VisionKit

struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onItemsRecognized: ([RecognizedItem]) -> Void
    let onItemTapped: (RecognizedItem) -> Void

    @Binding var isScanning: Bool

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false,
            isHighlightingEnabled: false  // 關閉高亮，使用自定義 AR 疊加
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isScanning {
            try? uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onItemsRecognized: onItemsRecognized,
            onItemTapped: onItemTapped
        )
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onItemsRecognized: ([RecognizedItem]) -> Void
        let onItemTapped: (RecognizedItem) -> Void

        init(
            onItemsRecognized: @escaping ([RecognizedItem]) -> Void,
            onItemTapped: @escaping (RecognizedItem) -> Void
        ) {
            self.onItemsRecognized = onItemsRecognized
            self.onItemTapped = onItemTapped
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            onItemsRecognized(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            onItemsRecognized(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            onItemsRecognized(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            onItemTapped(item)
        }
    }
}
