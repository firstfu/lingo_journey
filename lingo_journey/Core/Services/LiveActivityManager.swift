import ActivityKit
import Foundation

@Observable
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<TranslationActivityAttributes>?

    var isActivityActive: Bool {
        currentActivity != nil
    }

    private init() {}

    /// Start a new Live Activity for translation
    func startActivity(
        sourceLanguage: String,
        targetLanguage: String,
        sourceText: String
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        // End any existing activity first
        Task {
            await endActivity()
        }

        let attributes = TranslationActivityAttributes(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )

        let initialState = TranslationActivityAttributes.ContentState(
            sourceText: sourceText,
            translatedText: "",
            isTranslating: true
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// Update the Live Activity with translation result
    func updateActivity(translatedText: String, sourceText: String) async {
        guard let activity = currentActivity else { return }

        let updatedState = TranslationActivityAttributes.ContentState(
            sourceText: sourceText,
            translatedText: translatedText,
            isTranslating: false
        )

        await activity.update(
            ActivityContent(state: updatedState, staleDate: nil)
        )
    }

    /// End the current Live Activity
    func endActivity() async {
        guard let activity = currentActivity else { return }

        let finalState = TranslationActivityAttributes.ContentState(
            sourceText: "",
            translatedText: "",
            isTranslating: false
        )

        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .immediate
        )

        currentActivity = nil
    }

    /// End activity after a delay (useful for showing result briefly)
    func endActivityAfterDelay(seconds: TimeInterval = 5.0) {
        Task {
            try? await Task.sleep(for: .seconds(seconds))
            await endActivity()
        }
    }
}
