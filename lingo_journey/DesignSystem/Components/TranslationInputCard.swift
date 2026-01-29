import SwiftUI

struct TranslationInputCard: View {
    let languageName: String
    @Binding var text: String
    var onCameraTap: (() -> Void)?
    var onMicTap: () -> Void
    var isListening: Bool = false
    var audioLevel: Float = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack {
                Text(languageName)
                    .font(.appFootnote)
                    .foregroundColor(.appTextSecondary)

                Spacer()

                HStack(spacing: AppSpacing.md) {
                    // Camera button
                    if let onCameraTap = onCameraTap {
                        Button(action: onCameraTap) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 20))
                                .foregroundColor(.appTextSecondary)
                                .frame(width: 44, height: 44)
                        }
                    }

                    // Mic button
                    Button(action: onMicTap) {
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .font(.system(size: 20))
                            .foregroundColor(isListening ? .appPrimary : .appTextSecondary)
                            .frame(width: 44, height: 44)
                            .background(isListening ? Color.appPrimary.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                    }
                }
            }

            // Audio waveform when listening
            if isListening {
                AudioWaveformView(audioLevel: audioLevel)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }

            TextField("Enter your text here...", text: $text, axis: .vertical)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)
                .lineLimit(5...10)
                .textFieldStyle(.plain)
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .animation(.easeInOut(duration: 0.2), value: isListening)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack(spacing: 20) {
            TranslationInputCard(
                languageName: "English",
                text: .constant("Hello"),
                onCameraTap: {},
                onMicTap: {},
                isListening: false
            )
            TranslationInputCard(
                languageName: "English",
                text: .constant("Hello"),
                onCameraTap: {},
                onMicTap: {},
                isListening: true,
                audioLevel: 0.6
            )
        }
        .padding()
    }
}
