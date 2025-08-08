import Foundation

/// A UI-bound observable model that holds mutable state exposed to SwiftUI views.
///
/// This class is marked with `@Observable` so that SwiftUI views can automatically respond
/// to changes in its properties via the Observation framework.
///
/// It is also marked with `@MainActor` to ensure that all reads and writes to its properties
/// occur on the main thread. This is essential because:
/// - SwiftUI view updates must happen on the main thread.
/// - State changes that occur from asynchronous callbacks (e.g., from plugins, network calls,
///   or background tasks) must be dispatched to the main actor to ensure consistency.
/// - Mutating observable state off the main thread may result in missed or inconsistent UI updates.
///
/// Marking the entire model as `@MainActor` guarantees thread safety and prevents subtle bugs
/// in cases where state is updated from outside the view hierarchy.
@Observable
@MainActor
final class RecorderStreamingScreenModel {

    var textEditorText: String
    var buttonTitle: String
    var onStartRecordingTap: () -> Void
    var errorMessage: String? = nil
    var isErrorAlertShown: Bool

    init(
        textEditorText: String = "",
        buttonTitle: String = "",
        onMicrophoneTap: @escaping () -> Void = { },
        errorMessage: String? = nil,
        isErrorAlertShown: Bool = false
    ) {
        self.textEditorText = textEditorText
        self.buttonTitle = buttonTitle
        self.onStartRecordingTap = onMicrophoneTap
        self.errorMessage = errorMessage
        self.isErrorAlertShown = isErrorAlertShown
    }
}
