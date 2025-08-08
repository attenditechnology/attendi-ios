import Foundation
import AttendiSpeechService

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
final class TwoMicrophonesStreamingScreenModel {

    var shortTextFieldModel: TextFieldModel
    var longTextFieldModel: TextFieldModel
    var errorMessage: String?
    var isErrorAlertShown: Bool

    struct TextFieldModel {
        var text: String
        var recorder: AttendiRecorder
        var annotations: [TranscribeAsyncAction.AddAnnotation]

        init(
            text: String = "",
            recorder: AttendiRecorder,
            annotations: [TranscribeAsyncAction.AddAnnotation] = []
        ) {
            self.text = text
            self.recorder = recorder
            self.annotations = annotations
        }
    }

    init(
        shortTextFieldModel: TextFieldModel,
        longTextFieldModel: TextFieldModel,
        errorMessage: String? = nil,
        isErrorAlertShown: Bool = false
    ) {
        self.shortTextFieldModel = shortTextFieldModel
        self.longTextFieldModel = longTextFieldModel
        self.errorMessage = errorMessage
        self.isErrorAlertShown = isErrorAlertShown
    }
}
