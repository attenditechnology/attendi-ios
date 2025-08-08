import SwiftUI
import AttendiSpeechService

struct RecorderStreamingScreenView: View {

    @Binding var model: RecorderStreamingScreenModel

    var body: some View {
        VStack {
            VStack(spacing: 16) {
                Button(action: {
                    model.onStartRecordingTap()
                }) {
                    Text(model.buttonTitle)
                }
                .padding(16)

                TextEditor(text: $model.textEditorText)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
            }
            .padding()
        }
        .alert("Error", isPresented: $model.isErrorAlertShown) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "Unknown error")
        }
    }
}
