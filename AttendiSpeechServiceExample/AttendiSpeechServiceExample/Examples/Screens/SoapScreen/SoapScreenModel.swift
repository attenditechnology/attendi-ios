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
final class SoapScreenModel {

    var recorder: AttendiRecorder
    var text1: String
    var text2: String
    var text3: String
    var text4: String
    var focusedTextFieldIndex: Int?
    var canDisplayFocusedTextField: Bool
    var errorMessage: String?
    var isErrorAlertShown: Bool

    init(
        recorder: AttendiRecorder,
        text1: String = "",
        text2: String = "",
        text3: String = "",
        text4: String = "",
        focusedTextFieldIndex: Int? = 0,
        canDisplayFocusedTextField: Bool = false,
        errorMessage: String? = nil,
        isErrorAlertShown: Bool = false
    ) {
        self.recorder = recorder
        self.text1 = text1
        self.text2 = text2
        self.text3 = text3
        self.text4 = text4
        self.canDisplayFocusedTextField = canDisplayFocusedTextField
        self.errorMessage = errorMessage
        self.isErrorAlertShown = isErrorAlertShown
        self.focusedTextFieldIndex = focusedTextFieldIndex
    }
}
