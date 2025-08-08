import SwiftUI

/// A SwiftUI wrapper around `UITextView` that supports `NSAttributedString` and user interaction.
///
/// This component allows the display and editing of attributed text in a SwiftUI context.
/// It distinguishes between programmatic text updates and user edits to prevent unintended overwrites.
struct AttributedTextEditor: UIViewRepresentable {

    /// The attributed text bound to the SwiftUI view.
    /// This value is updated when the user edits the text, and programmatic changes to it will update the `UITextView`.
    @Binding var attributedText: NSAttributedString

    /// Tracks whether the user is currently editing the text.
    /// Used to prevent reapplying the attributed text while the user is typing.
    @Binding var isUserEditing: Bool

    /// An optional binding that keeps track of the currently focused text editor.
    /// When this text editor begins editing, it sets this binding to its `tag`.
    /// When editing ends, it resets the value to `nil`.
    @Binding var focusedField: Int?

    /// A unique identifier for this text editor instance.
    /// Used to update `focusedField` when the editor becomes active.
    let tag: Int?

    /// Reference to plain text binding, needed for syncing with the attributedText.
    private var plainTextBinding: Binding<String>? = nil

    init(
        attributedText: Binding<NSAttributedString>,
        isUserEditing: Binding<Bool>,
        focusedField: Binding<Int?> = .constant(nil),
        tag: Int? = nil
    ) {
        self._attributedText = attributedText
        self._isUserEditing = isUserEditing
        self._focusedField = focusedField
        self.tag = tag
    }

    init(
        text: Binding<String>,
        styleAttributes: [NSAttributedString.Key: Any]? = nil,
        isUserEditing: Binding<Bool> = .constant(false),
        focusedField: Binding<Int?> = .constant(nil),
        tag: Int? = nil
    ) {
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 20)
        ]
        self._attributedText = .constant(NSAttributedString(string: text.wrappedValue, attributes: styleAttributes ?? defaultAttributes))
        self._isUserEditing = isUserEditing
        self._focusedField = focusedField
        self.tag = tag
        self.plainTextBinding = text
    }

    /// Creates the underlying `UITextView` instance.
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        return textView
    }

    /// Updates the `UITextView` when the bound `NSAttributedString` changes programmatically.
    /// Skips updates if the user is currently editing the text.
    func updateUIView(_ uiView: UITextView, context: Context) {
        guard !context.coordinator.isUserEditing else { return }

        /// Only update if needed.
        if uiView.attributedText.string != attributedText.string || !uiView.attributedText.isEqualAttributes(to: attributedText) {
            let selectedRange = uiView.selectedRange
            uiView.attributedText = attributedText
            uiView.selectedRange = selectedRange
        }
    }

    /// Creates the coordinator that serves as the `UITextViewDelegate`.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// A coordinator class to bridge UIKit delegate callbacks to SwiftUI.
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: AttributedTextEditor

        /// Internal flag to track if the user is currently typing.
        var isUserEditing = false

        /// Initializes the coordinator with a reference to the parent view.
        init(_ parent: AttributedTextEditor) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.focusedField = parent.tag
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.focusedField = nil
        }

        /// Called whenever the user changes the text.
        /// Updates the bound `NSAttributedString` and sets editing flags accordingly.
        func textViewDidChange(_ textView: UITextView) {
            isUserEditing = true
            parent.isUserEditing = true

            /// Update the SwiftUI binding with new attributed text.
            let updatedText = NSAttributedString(attributedString: textView.attributedText)
            parent.attributedText = updatedText

            if let plainTextBinding = parent.plainTextBinding {
                plainTextBinding.wrappedValue = updatedText.string
            }

            /// Reset editing flags after the run loop to allow for programmatic updates.
            DispatchQueue.main.async {
                self.isUserEditing = false
                self.parent.isUserEditing = false
            }
        }
    }
}

private extension NSAttributedString {

    /// Compares the attributes (e.g., font, color, style) of two `NSAttributedString` instances for equality,
    /// **ignoring the string content** itself.
    ///
    /// - Parameter other: Another `NSAttributedString` to compare against.
    /// - Returns: `true` if both attributed strings have the same attributes (e.g., font, color) at each position,
    ///   and their lengths match. Returns `false` if any difference is found in attribute sets or string length.
    ///
    /// This method is useful when you care about whether the styling of the text has changed,
    /// rather than the actual text content. For example, when detecting whether reapplying annotations or styles is necessary.
    ///
    /// ### Note:
    /// - This comparison checks attribute dictionaries at each character index using `enumerateAttributes(...)`.
    /// - Attribute dictionaries are compared using `NSDictionary(...) != NSDictionary(...)`, which performs a shallow key-value comparison.
    func isEqualAttributes(to other: NSAttributedString) -> Bool {
        guard self.length == other.length else { return false }

        var isEqual = true
        self.enumerateAttributes(in: NSRange(location: 0, length: length), options: []) { attrs, range, stop in
            let otherAttrs = other.attributes(at: range.location, effectiveRange: nil)
            if NSDictionary(dictionary: attrs) != NSDictionary(dictionary: otherAttrs) {
                isEqual = false
                stop.pointee = true
            }
        }
        return isEqual
    }
}
