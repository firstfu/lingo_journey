# 相機翻譯重寫實作計劃

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 使用 AVFoundation + Vision 重寫相機翻譯功能，達到 Google 相機翻譯等級的 AR 覆蓋效果

**Architecture:** 用 AVFoundation 取得相機幀，Vision OCR 辨識文字與四角點，Apple Translation 翻譯，SwiftUI Canvas 繪製模糊遮罩與透視變形的翻譯文字

**Tech Stack:** AVFoundation, Vision, Translation, SwiftUI, CoreImage

---

## Task 1: 刪除舊的 Scanner 實作

**Files:**
- Delete: `lingo_journey/Features/Scanner/DataScannerRepresentable.swift`
- Delete: `lingo_journey/Features/Scanner/ScannerView.swift`
- Delete: `lingo_journey/Features/Scanner/ScannerViewModel.swift`
- Delete: `lingo_journey/Features/Scanner/TranslationOverlayView.swift`
- Keep: `lingo_journey/Features/Scanner/TranslationDetailCard.swift`

**Step 1: 刪除舊檔案**

```bash
rm lingo_journey/Features/Scanner/DataScannerRepresentable.swift
rm lingo_journey/Features/Scanner/ScannerView.swift
rm lingo_journey/Features/Scanner/ScannerViewModel.swift
rm lingo_journey/Features/Scanner/TranslationOverlayView.swift
```

**Step 2: 確認 TranslationDetailCard.swift 保留**

**Step 3: Commit**

```bash
git add -A && git commit -m "refactor: remove old VisionKit scanner implementation"
```

---

## Task 2: 創建資料模型 (DetectedText, TextCorners)

**Files:**
- Modify: `lingo_journey/Core/Models/ScanResult.swift`

**Step 1: 更新 ScanResult.swift，加入 TextCorners 和更新 DetectedText**

```swift
import Foundation
import CoreGraphics

/// 四角點座標 (用於透視變形)
struct TextCorners: Equatable {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint

    /// 從 normalized (0~1, 左下原點) 轉換為 screen 座標 (左上原點)
    func toScreenCoordinates(in size: CGSize) -> TextCorners {
        TextCorners(
            topLeft: CGPoint(x: topLeft.x * size.width, y: (1 - topLeft.y) * size.height),
            topRight: CGPoint(x: topRight.x * size.width, y: (1 - topRight.y) * size.height),
            bottomLeft: CGPoint(x: bottomLeft.x * size.width, y: (1 - bottomLeft.y) * size.height),
            bottomRight: CGPoint(x: bottomRight.x * size.width, y: (1 - bottomRight.y) * size.height)
        )
    }

    /// 計算邊界框
    var boundingBox: CGRect {
        let minX = min(topLeft.x, bottomLeft.x)
        let maxX = max(topRight.x, bottomRight.x)
        let minY = min(topLeft.y, topRight.y)
        let maxY = max(bottomLeft.y, bottomRight.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

/// 偵測到的文字區塊
struct DetectedText: Identifiable, Equatable {
    let id: UUID
    let text: String
    var translatedText: String?
    let corners: TextCorners
    var isTranslating: Bool

    init(
        id: UUID = UUID(),
        text: String,
        translatedText: String? = nil,
        corners: TextCorners,
        isTranslating: Bool = false
    ) {
        self.id = id
        self.text = text
        self.translatedText = translatedText
        self.corners = corners
        self.isTranslating = isTranslating
    }

    var boundingBox: CGRect {
        corners.boundingBox
    }
}
```

**Step 2: 編譯確認**

```bash
xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add TextCorners and DetectedText models for camera translation"
```

---

## Task 3: 創建 CameraManager (AVCaptureSession 管理)

**Files:**
- Create: `lingo_journey/Features/Scanner/CameraManager.swift`

**Step 1: 創建 CameraManager.swift**

```swift
import AVFoundation
import CoreImage

@Observable
final class CameraManager: NSObject {
    let session = AVCaptureSession()

    var onFrameCaptured: ((CVPixelBuffer) -> Void)?
    var isRunning: Bool = false
    var permissionGranted: Bool = false

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var frameCount: Int = 0
    private let processEveryNFrames = 5  // 每 5 幀處理一次

    override init() {
        super.init()
        checkPermission()
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupSession()
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }

    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                if granted {
                    self?.setupSession()
                }
            }
        }
    }

    private func setupSession() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // 添加相機輸入
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        // 添加視頻輸出
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.queue"))
        videoOutput.alwaysDiscardsLateVideoFrames = true

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)

            // 設定視頻方向
            if let connection = videoOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            }
        }

        session.commitConfiguration()
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isRunning = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameCount += 1

        // 每 N 幀處理一次，降低 CPU 負擔
        guard frameCount % processEveryNFrames == 0,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        onFrameCaptured?(pixelBuffer)
    }
}
```

**Step 2: 編譯確認**

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add CameraManager for AVFoundation camera handling"
```

---

## Task 4: 創建 CameraPreviewView (SwiftUI 相機預覽)

**Files:**
- Create: `lingo_journey/Features/Scanner/CameraPreviewView.swift`

**Step 1: 創建 CameraPreviewView.swift**

```swift
import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

class CameraPreviewUIView: UIView {
    var session: AVCaptureSession? {
        didSet {
            guard let session else { return }
            previewLayer.session = session
        }
    }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
    }
}
```

**Step 2: 編譯確認**

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add CameraPreviewView for SwiftUI camera display"
```

---

## Task 5: 創建 TextRecognitionEngine (Vision OCR)

**Files:**
- Create: `lingo_journey/Features/Scanner/TextRecognitionEngine.swift`

**Step 1: 創建 TextRecognitionEngine.swift**

```swift
import Vision
import CoreImage

struct RecognizedTextResult {
    let text: String
    let corners: TextCorners  // normalized 座標 (0~1)
}

final class TextRecognitionEngine {
    private let requestQueue = DispatchQueue(label: "text.recognition.queue", qos: .userInitiated)

    func recognizeText(in pixelBuffer: CVPixelBuffer, completion: @escaping ([RecognizedTextResult]) -> Void) {
        requestQueue.async {
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    DispatchQueue.main.async { completion([]) }
                    return
                }

                let results = observations.compactMap { observation -> RecognizedTextResult? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }

                    let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return nil }

                    // Vision 回傳 normalized 座標 (0~1, 左下原點)
                    let corners = TextCorners(
                        topLeft: observation.topLeft,
                        topRight: observation.topRight,
                        bottomLeft: observation.bottomLeft,
                        bottomRight: observation.bottomRight
                    )

                    return RecognizedTextResult(text: text, corners: corners)
                }

                DispatchQueue.main.async { completion(results) }
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
        }
    }
}
```

**Step 2: 編譯確認**

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add TextRecognitionEngine for Vision OCR"
```

---

## Task 6: 創建 TextTracker (文字追蹤與穩定)

**Files:**
- Create: `lingo_journey/Features/Scanner/TextTracker.swift`

**Step 1: 創建 TextTracker.swift**

```swift
import Foundation
import CoreGraphics

final class TextTracker {
    private var trackedTexts: [UUID: TrackedTextInfo] = [:]
    private let maxAge: TimeInterval = 0.5  // 超過 0.5 秒未見則移除
    private let smoothingFactor: CGFloat = 0.3  // 座標平滑係數
    private let similarityThreshold: Double = 0.7  // 文字相似度閾值
    private let positionThreshold: CGFloat = 0.15  // 位置接近度閾值 (normalized)

    struct TrackedTextInfo {
        let id: UUID
        var text: String
        var corners: TextCorners
        var smoothedCorners: TextCorners
        var lastSeenTime: Date
        var translatedText: String?
    }

    /// 更新追蹤的文字，回傳穩定後的結果
    func update(with recognizedTexts: [RecognizedTextResult]) -> [DetectedText] {
        let now = Date()

        // 移除過期的追蹤
        trackedTexts = trackedTexts.filter { now.timeIntervalSince($0.value.lastSeenTime) < maxAge }

        var matchedIds: Set<UUID> = []

        for recognized in recognizedTexts {
            if let (id, existingInfo) = findMatch(for: recognized) {
                // 更新現有追蹤
                matchedIds.insert(id)
                var updated = existingInfo
                updated.text = recognized.text
                updated.corners = recognized.corners
                updated.smoothedCorners = smoothCorners(current: recognized.corners, previous: existingInfo.smoothedCorners)
                updated.lastSeenTime = now
                trackedTexts[id] = updated
            } else {
                // 新增追蹤
                let id = UUID()
                trackedTexts[id] = TrackedTextInfo(
                    id: id,
                    text: recognized.text,
                    corners: recognized.corners,
                    smoothedCorners: recognized.corners,
                    lastSeenTime: now,
                    translatedText: nil
                )
            }
        }

        // 轉換為 DetectedText
        return trackedTexts.values.map { info in
            DetectedText(
                id: info.id,
                text: info.text,
                translatedText: info.translatedText,
                corners: info.smoothedCorners,
                isTranslating: false
            )
        }
    }

    /// 更新翻譯結果
    func updateTranslation(for text: String, translation: String) {
        for (id, var info) in trackedTexts {
            if info.text == text {
                info.translatedText = translation
                trackedTexts[id] = info
            }
        }
    }

    /// 取得快取的翻譯
    func getCachedTranslation(for text: String) -> String? {
        trackedTexts.values.first { $0.text == text }?.translatedText
    }

    private func findMatch(for recognized: RecognizedTextResult) -> (UUID, TrackedTextInfo)? {
        for (id, info) in trackedTexts {
            let textSimilarity = stringSimilarity(info.text, recognized.text)
            let positionDistance = cornerDistance(info.corners, recognized.corners)

            if textSimilarity > similarityThreshold && positionDistance < positionThreshold {
                return (id, info)
            }
        }
        return nil
    }

    private func smoothCorners(current: TextCorners, previous: TextCorners) -> TextCorners {
        TextCorners(
            topLeft: smoothPoint(current: current.topLeft, previous: previous.topLeft),
            topRight: smoothPoint(current: current.topRight, previous: previous.topRight),
            bottomLeft: smoothPoint(current: current.bottomLeft, previous: previous.bottomLeft),
            bottomRight: smoothPoint(current: current.bottomRight, previous: previous.bottomRight)
        )
    }

    private func smoothPoint(current: CGPoint, previous: CGPoint) -> CGPoint {
        CGPoint(
            x: previous.x + (current.x - previous.x) * smoothingFactor,
            y: previous.y + (current.y - previous.y) * smoothingFactor
        )
    }

    private func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        if s1 == s2 { return 1.0 }
        if s1.isEmpty || s2.isEmpty { return 0.0 }

        let longer = s1.count > s2.count ? s1 : s2
        let shorter = s1.count > s2.count ? s2 : s1

        if longer.contains(shorter) || shorter.contains(longer) {
            return Double(shorter.count) / Double(longer.count)
        }

        // 簡單的字元重疊率
        let set1 = Set(s1)
        let set2 = Set(s2)
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)
        return Double(intersection.count) / Double(union.count)
    }

    private func cornerDistance(_ c1: TextCorners, _ c2: TextCorners) -> CGFloat {
        let d1 = hypot(c1.topLeft.x - c2.topLeft.x, c1.topLeft.y - c2.topLeft.y)
        let d2 = hypot(c1.topRight.x - c2.topRight.x, c1.topRight.y - c2.topRight.y)
        let d3 = hypot(c1.bottomLeft.x - c2.bottomLeft.x, c1.bottomLeft.y - c2.bottomLeft.y)
        let d4 = hypot(c1.bottomRight.x - c2.bottomRight.x, c1.bottomRight.y - c2.bottomRight.y)
        return (d1 + d2 + d3 + d4) / 4
    }
}
```

**Step 2: 編譯確認**

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add TextTracker for text tracking and stabilization"
```

---

## Task 7: 創建 TranslationEngine (Apple Translation + 快取)

**Files:**
- Create: `lingo_journey/Features/Scanner/TranslationEngine.swift`

**Step 1: 創建 TranslationEngine.swift**

```swift
import Foundation
import Translation

@Observable
final class TranslationEngine {
    var configuration: TranslationSession.Configuration?

    private var cache: [String: String] = [:]
    private var pendingTexts: Set<String> = []
    private var isTranslating = false

    let sourceLanguage: Locale.Language
    let targetLanguage: Locale.Language

    init(sourceLanguage: Locale.Language, targetLanguage: Locale.Language) {
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }

    /// 取得快取的翻譯，若無則加入待翻譯列表
    func getTranslation(for text: String) -> String? {
        if let cached = cache[text] {
            return cached
        }

        if !pendingTexts.contains(text) {
            pendingTexts.insert(text)
            triggerTranslationIfNeeded()
        }

        return nil
    }

    /// 觸發翻譯（設定 configuration 讓 .translationTask 執行）
    private func triggerTranslationIfNeeded() {
        guard !isTranslating, !pendingTexts.isEmpty else { return }

        isTranslating = true
        configuration = TranslationSession.Configuration(
            source: sourceLanguage,
            target: targetLanguage
        )
    }

    /// 執行翻譯（由 .translationTask 呼叫）
    func performTranslation(session: TranslationSession) async {
        let textsToTranslate = Array(pendingTexts)
        pendingTexts.removeAll()

        guard !textsToTranslate.isEmpty else {
            await MainActor.run {
                configuration = nil
                isTranslating = false
            }
            return
        }

        do {
            let requests = textsToTranslate.map { TranslationSession.Request(sourceText: $0) }
            let responses = try await session.translations(from: requests)

            await MainActor.run {
                for (index, response) in responses.enumerated() {
                    let originalText = textsToTranslate[index]
                    cache[originalText] = response.targetText
                }
            }
        } catch {
            print("Translation error: \(error)")
        }

        await MainActor.run {
            configuration = nil
            isTranslating = false

            // 如果還有待翻譯項目，繼續
            if !pendingTexts.isEmpty {
                triggerTranslationIfNeeded()
            }
        }
    }

    /// 檢查是否有快取
    func hasCachedTranslation(for text: String) -> Bool {
        cache[text] != nil
    }
}
```

**Step 2: 編譯確認**

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add TranslationEngine with caching and batch translation"
```

---

## Task 8: 創建 OverlayRenderer (模糊遮罩 + 透視變形)

**Files:**
- Create: `lingo_journey/Features/Scanner/OverlayRenderer.swift`

**Step 1: 創建 OverlayRenderer.swift**

```swift
import SwiftUI

struct TranslationOverlay: View {
    let detectedTexts: [DetectedText]
    let viewSize: CGSize
    let onTap: (DetectedText) -> Void

    var body: some View {
        Canvas { context, size in
            for text in detectedTexts {
                guard let translated = text.translatedText else { continue }

                let screenCorners = text.corners.toScreenCoordinates(in: size)
                let rect = screenCorners.boundingBox

                // 1. 繪製模糊背景遮罩
                let path = createQuadPath(from: screenCorners)
                context.fill(path, with: .color(.white.opacity(0.85)))

                // 2. 繪製翻譯文字
                let fontSize = calculateFontSize(for: rect)
                let textPosition = CGPoint(x: rect.midX, y: rect.midY)

                context.draw(
                    Text(translated)
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundColor(.black),
                    at: textPosition,
                    anchor: .center
                )
            }
        }
        .allowsHitTesting(false)

        // 疊加可點擊的透明按鈕
        ForEach(detectedTexts.filter { $0.translatedText != nil }) { text in
            let screenCorners = text.corners.toScreenCoordinates(in: viewSize)
            let rect = screenCorners.boundingBox

            Color.clear
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap(text)
                }
        }
    }

    private func createQuadPath(from corners: TextCorners) -> Path {
        var path = Path()
        path.move(to: corners.topLeft)
        path.addLine(to: corners.topRight)
        path.addLine(to: corners.bottomRight)
        path.addLine(to: corners.bottomLeft)
        path.closeSubpath()
        return path
    }

    private func calculateFontSize(for rect: CGRect) -> CGFloat {
        let height = rect.height
        return min(max(height * 0.6, 12), 24)
    }
}

// MARK: - 透視變形輔助

extension TextCorners {
    /// 計算透視變形矩陣
    func perspectiveTransform(to targetRect: CGRect) -> CATransform3D {
        // 簡化版：根據四角點傾斜角度計算旋轉
        let topWidth = hypot(topRight.x - topLeft.x, topRight.y - topLeft.y)
        let bottomWidth = hypot(bottomRight.x - bottomLeft.x, bottomRight.y - bottomLeft.y)

        // 計算透視傾斜
        let perspectiveRatio = topWidth / bottomWidth

        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 500.0  // 透視效果

        if abs(perspectiveRatio - 1.0) > 0.05 {
            let angle = atan((perspectiveRatio - 1.0) * 0.5)
            transform = CATransform3DRotate(transform, angle, 1, 0, 0)
        }

        // 計算旋轉角度
        let dx = topRight.x - topLeft.x
        let dy = topRight.y - topLeft.y
        let rotation = atan2(dy, dx)

        if abs(rotation) > 0.02 {
            transform = CATransform3DRotate(transform, rotation, 0, 0, 1)
        }

        return transform
    }
}
```

**Step 2: 編譯確認**

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add OverlayRenderer with blur mask and perspective transform"
```

---

## Task 9: 創建 ScannerViewModel (狀態管理)

**Files:**
- Create: `lingo_journey/Features/Scanner/ScannerViewModel.swift`

**Step 1: 創建 ScannerViewModel.swift**

```swift
import Foundation
import SwiftUI

@Observable
final class ScannerViewModel {
    // MARK: - Public State
    var detectedTexts: [DetectedText] = []
    var selectedText: DetectedText?
    var showDetailCard: Bool = false
    var viewSize: CGSize = .zero

    // MARK: - Engines
    let cameraManager = CameraManager()
    let textRecognitionEngine = TextRecognitionEngine()
    let textTracker = TextTracker()
    let translationEngine: TranslationEngine

    // MARK: - Init
    init(sourceLanguage: Locale.Language, targetLanguage: Locale.Language) {
        self.translationEngine = TranslationEngine(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )

        setupCameraCallback()
    }

    // MARK: - Setup
    private func setupCameraCallback() {
        cameraManager.onFrameCaptured = { [weak self] pixelBuffer in
            self?.processFrame(pixelBuffer)
        }
    }

    // MARK: - Frame Processing
    private func processFrame(_ pixelBuffer: CVPixelBuffer) {
        textRecognitionEngine.recognizeText(in: pixelBuffer) { [weak self] results in
            self?.handleRecognizedTexts(results)
        }
    }

    private func handleRecognizedTexts(_ results: [RecognizedTextResult]) {
        // 1. 透過 TextTracker 追蹤並穩定座標
        var trackedTexts = textTracker.update(with: results)

        // 2. 為每個文字取得翻譯
        for i in trackedTexts.indices {
            let text = trackedTexts[i].text

            if let cached = translationEngine.getTranslation(for: text) {
                trackedTexts[i].translatedText = cached
                textTracker.updateTranslation(for: text, translation: cached)
            }
        }

        // 3. 更新顯示
        detectedTexts = trackedTexts
    }

    // MARK: - Lifecycle
    func startScanning() {
        cameraManager.startSession()
    }

    func stopScanning() {
        cameraManager.stopSession()
    }

    // MARK: - Selection
    func selectText(_ text: DetectedText) {
        selectedText = text
        showDetailCard = true
    }

    func dismissDetailCard() {
        showDetailCard = false
        selectedText = nil
    }
}
```

**Step 2: 編譯確認**

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add ScannerViewModel for state management"
```

---

## Task 10: 創建 ScannerView (主視圖)

**Files:**
- Create: `lingo_journey/Features/Scanner/ScannerView.swift`

**Step 1: 創建 ScannerView.swift**

```swift
import SwiftUI
import SwiftData
import Translation

struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: ScannerViewModel

    init(sourceLanguage: Locale.Language, targetLanguage: Locale.Language) {
        _viewModel = State(initialValue: ScannerViewModel(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        ))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 相機預覽
                if viewModel.cameraManager.permissionGranted {
                    CameraPreviewView(session: viewModel.cameraManager.session)
                        .ignoresSafeArea()

                    // 2. 翻譯覆蓋層
                    TranslationOverlay(
                        detectedTexts: viewModel.detectedTexts,
                        viewSize: geometry.size,
                        onTap: { text in
                            viewModel.selectText(text)
                        }
                    )
                } else {
                    unavailableView
                }

                // 3. 頂部導航欄
                VStack {
                    topBar
                    Spacer()
                }

                // 4. 詳情卡片
                if viewModel.showDetailCard, let selectedText = viewModel.selectedText {
                    detailCardOverlay(text: selectedText)
                }
            }
            .onAppear {
                viewModel.viewSize = geometry.size
                viewModel.startScanning()
            }
            .onDisappear {
                viewModel.stopScanning()
                saveToHistory()
            }
        }
        .translationTask(viewModel.translationEngine.configuration) { session in
            await viewModel.translationEngine.performTranslation(session: session)
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }

            Spacer()

            Text(languagePairText)
                .font(.appSubheadline)
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(Color.black.opacity(0.3))
                .clipShape(Capsule())
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.md)
    }

    private var languagePairText: String {
        let source = displayName(for: viewModel.translationEngine.sourceLanguage)
        let target = displayName(for: viewModel.translationEngine.targetLanguage)
        return "\(source) → \(target)"
    }

    // MARK: - Detail Card Overlay
    private func detailCardOverlay(text: DetectedText) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissDetailCard()
                }

            VStack {
                Spacer()
                TranslationDetailCard(
                    result: ScanResult(
                        originalText: text.text,
                        translatedText: text.translatedText,
                        boundingBox: text.boundingBox,
                        isTranslating: text.isTranslating
                    ),
                    sourceLanguage: viewModel.translationEngine.sourceLanguage,
                    targetLanguage: viewModel.translationEngine.targetLanguage,
                    onDismiss: {
                        viewModel.dismissDetailCard()
                    }
                )
            }
            .transition(.move(edge: .bottom))
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showDetailCard)
    }

    // MARK: - Unavailable View
    private var unavailableView: some View {
        VStack(spacing: AppSpacing.xxl) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundColor(.appTextMuted)

            Text("相機權限未開啟")
                .font(.appTitle2)
                .foregroundColor(.appTextPrimary)

            Text("請在設定中開啟相機權限以使用掃描翻譯功能。")
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)

            Button(action: openSettings) {
                Text("開啟設定")
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)
            }
        }
        .padding(AppSpacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }

    // MARK: - Helpers
    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func saveToHistory() {
        for text in viewModel.detectedTexts {
            guard let translated = text.translatedText else { continue }

            let record = TranslationRecord(
                sourceText: text.text,
                translatedText: translated,
                sourceLanguage: viewModel.translationEngine.sourceLanguage.minimalIdentifier,
                targetLanguage: viewModel.translationEngine.targetLanguage.minimalIdentifier
            )
            modelContext.insert(record)
        }
    }
}

#Preview {
    ScannerView(
        sourceLanguage: Locale.Language(identifier: "en"),
        targetLanguage: Locale.Language(identifier: "zh-Hant")
    )
}
```

**Step 2: 編譯確認**

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add ScannerView as main camera translation UI"
```

---

## Task 11: 更新 ScanResult 兼容性

**Files:**
- Modify: `lingo_journey/Core/Models/ScanResult.swift`

**Step 1: 確保 ScanResult 與 TranslationDetailCard 兼容**

保留原有的 ScanResult，讓 TranslationDetailCard 可以繼續使用。

**Step 2: 編譯並測試整個專案**

```bash
xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: complete camera translation rewrite with AVFoundation + Vision"
```

---

## Task 12: 整合測試與修復

**目標:** 在模擬器或實機上測試完整流程，修復任何問題

**測試清單:**
- [ ] 相機預覽正常顯示
- [ ] 文字辨識正常運作
- [ ] 翻譯結果正確疊加在原文位置
- [ ] 模糊遮罩正確覆蓋原文
- [ ] 透視變形正確應用
- [ ] 文字追蹤穩定（移動相機時不跳動）
- [ ] 點擊翻譯顯示詳情卡片
- [ ] 離開時正確保存歷史記錄
