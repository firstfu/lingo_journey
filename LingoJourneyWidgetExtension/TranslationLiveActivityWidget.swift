import ActivityKit
import SwiftUI
import WidgetKit

struct TranslationLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TranslationActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenLiveActivityView(context: context)
                .widgetURL(URL(string: "lingojourney://translate-clipboard"))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
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
                    expandedCenterView(context: context)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if !context.state.isStandby {
                        Text(context.state.sourceText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            } compactLeading: {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                compactTrailingView(context: context)
            } minimal: {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)
            }
            .widgetURL(URL(string: "lingojourney://translate-clipboard"))
        }
    }

    @ViewBuilder
    private func expandedCenterView(context: ActivityViewContext<TranslationActivityAttributes>) -> some View {
        VStack(spacing: 4) {
            if context.state.isStandby {
                Text("點擊翻譯剪貼簿")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else if let error = context.state.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
            } else if context.state.isTranslating {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Text(context.state.translatedText)
                    .font(.headline)
                    .lineLimit(2)
            }
        }
    }

    @ViewBuilder
    private func compactTrailingView(context: ActivityViewContext<TranslationActivityAttributes>) -> some View {
        if context.state.isStandby {
            Text("點擊翻譯")
                .font(.caption2)
                .foregroundColor(.secondary)
        } else if context.state.errorMessage != nil {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
        } else if context.state.isTranslating {
            ProgressView()
                .scaleEffect(0.6)
        } else {
            Text(context.state.translatedText.prefix(10))
                .font(.caption2)
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<TranslationActivityAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(context.attributes.sourceLanguage) → \(context.attributes.targetLanguage)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if context.state.isStandby {
                    Text("點擊翻譯剪貼簿內容")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let error = context.state.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                } else if context.state.isTranslating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("翻譯中...")
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
