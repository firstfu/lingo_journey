import ActivityKit
import SwiftUI
import WidgetKit

struct TranslationActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TranslationActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.sourceLanguage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.targetLanguage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        if context.state.isTranslating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text(context.state.translatedText)
                                .font(.headline)
                                .lineLimit(2)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.sourceText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } compactLeading: {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                if context.state.isTranslating {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Text(context.state.translatedText.prefix(10))
                        .font(.caption2)
                }
            } minimal: {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)
            }
        }
    }
}

struct LockScreenView: View {
    let context: ActivityViewContext<TranslationActivityAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(context.attributes.sourceLanguage) → \(context.attributes.targetLanguage)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if context.state.isTranslating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Translating...")
                    }
                } else {
                    Text(context.state.translatedText)
                        .font(.headline)
                }
            }

            Spacer()

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding()
    }
}
