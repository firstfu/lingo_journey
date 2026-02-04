import SwiftUI

struct TranslationInputCard: View {
    let languageName: String
    @Binding var text: String
    var onMicTap: () -> Void
    var onClearTap: (() -> Void)?
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
                    // Mic button
                    Button(action: onMicTap) {
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .font(.system(size: 20))
                            .foregroundColor(isListening ? .appPrimary : .appTextSecondary)
                            .frame(width: 44, height: 44)
                            .background(isListening ? Color.appPrimary.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                    }

                    // Clear button - only show when text is not empty
                    if !text.isEmpty, let onClearTap = onClearTap {
                        Button(action: onClearTap) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.appTextMuted)
                                .frame(width: 44, height: 44)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
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
            // With text - shows clear button
            TranslationInputCard(
                languageName: "English",
                text: .constant("Hello world"),
                onMicTap: {},
                onClearTap: {},
                isListening: false
            )
            // Empty text - no clear button
            TranslationInputCard(
                languageName: "English",
                text: .constant(""),
                onMicTap: {},
                onClearTap: {},
                isListening: false
            )
            // Listening state
            TranslationInputCard(
                languageName: "English",
                text: .constant("Hello"),
                onMicTap: {},
                onClearTap: {},
                isListening: true,
                audioLevel: 0.6
            )
        }
        .padding()
    }
}
