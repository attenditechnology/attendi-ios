import SwiftUI
import AttendiSpeechService

struct TwoMicrophonesStreamingScreenView: View {

    @Binding var model: TwoMicrophonesStreamingScreenModel
    
    /// Tracks the currently displayed attributed text in the `AttributedTextEditor`.
    ///
    /// This value is updated in two cases:
    /// - When the user is editing the text field, this state reflects the user's changes in real-time.
    /// - When the model's `text` changes programmatically (e.g., from a network update or annotation logic),
    ///   this state is updated only if the user is **not** actively editing, preventing unexpected overwrites.
    ///
    /// Used to ensure two-way binding between view and model while maintaining control over user-driven vs. programmatic updates.
    @State private var longTextFieldAttributedText: NSAttributedString = NSAttributedString(string: "")

    /// Indicates whether the user is actively editing the `AttributedTextEditor`.
    ///
    /// This flag helps differentiate between:
    /// - Programmatic changes to the model (e.g., updates from annotations or external data)
    /// - User input in the UI
    ///
    /// It's used to conditionally apply attributed text updates only when the user is **not** editing,
    /// and to push text changes back into the model only when the user **is** editing.
    @State private var isUserEditingLongTextField = false

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                HStack {
                    TextField("", text: $model.shortTextFieldModel.text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal)
                        .frame(height: 36)

                    AttendiMicrophone(
                        recorder: model.shortTextFieldModel.recorder,
                        settings: AttendiMicrophoneSettings(
                            size: 56,
                            colors: AttendiMicrophoneDefaults.colors(baseColor: Colors.pinkColor)
                        )
                    )
                }
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Colors.greyColor)
                )
                VStack {
                    AttributedTextEditor(attributedText: $longTextFieldAttributedText, isUserEditing: $isUserEditingLongTextField)
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    HStack {
                        AttendiMicrophone(
                            recorder: model.longTextFieldModel.recorder,
                            settings: AttendiMicrophoneSettings(
                                size: 56,
                                colors: AttendiMicrophoneDefaults.colors(baseColor: Colors.pinkColor)
                            )
                        )
                        .padding(8)
                        Spacer()
                    }
                }
                .onChange(of: model.longTextFieldModel.annotations) { _, newValue in
                    if !isUserEditingLongTextField {
                        longTextFieldAttributedText = mapAttributedString(
                            originalText: model.longTextFieldModel.text,
                            annotations: newValue
                        )
                    }
                }
                .onChange(of: longTextFieldAttributedText) { _, newValue in
                    if isUserEditingLongTextField {
                        model.longTextFieldModel.text = newValue.string
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Colors.greyColor)
                )
            }
            .padding(16)
        }
        .alert("Error", isPresented: $model.isErrorAlertShown) {
            Button("OK", role: .cancel) {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "Unknown error")
        }
    }

    private func mapAttributedString(
        originalText: String,
        annotations: [TranscribeAsyncAction.AddAnnotation]
    ) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: originalText)

        /// Apply base text syle.
        attributedText.addAttributes([
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 20)
        ], range: NSRange(location: 0, length: attributedText.length))

        for annotation in annotations {
            let color: UIColor = {
                switch annotation.parameters.type {
                case .transcriptionTentative: return .cyan
                case .intent: return .blue
                case .entity: return .green
                @unknown default:
                    return .black
                }
            }()
            let start = max(0, annotation.parameters.startCharacterIndex)
            let end = min(originalText.count, annotation.parameters.endCharacterIndex)
            if start < end {
                attributedText.addAttribute(.foregroundColor, value: color, range: NSRange(location: start, length: end - start))
            }
        }

        return attributedText
    }
}
