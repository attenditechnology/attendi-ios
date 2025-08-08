import SwiftUI
import AttendiSpeechService

struct SoapScreenView: View {

    @Binding var model: SoapScreenModel
    @State private var isMissingPermissionsAlertPrensented: Bool = false

    private func shouldDisplayMicrophoneTarget(tag: Int) -> Bool {
        model.canDisplayFocusedTextField && model.focusedTextFieldIndex == tag
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("SOAP rapportage")

                    Text("S:")
                    StyledAttributedTextEditor(text: $model.text1, focusedField: $model.focusedTextFieldIndex, tag: 0)
                        .if(shouldDisplayMicrophoneTarget(tag: 0)) { view in
                            view.overlay(OverlayView(color: Colors.pinkColor))
                        }
                    if shouldDisplayMicrophoneTarget(tag: 0) {
                        Text("Aan het opnemen...")
                            .font(.footnote)
                    }

                    Text("O:")
                    StyledAttributedTextEditor(text: $model.text2, focusedField: $model.focusedTextFieldIndex, tag: 1)
                        .if(shouldDisplayMicrophoneTarget(tag: 1)) { view in
                            view.overlay(OverlayView(color: Colors.pinkColor))
                        }

                    Text("A:")
                    StyledAttributedTextEditor(text: $model.text3, focusedField: $model.focusedTextFieldIndex, tag: 2)
                        .if(shouldDisplayMicrophoneTarget(tag: 2)) { view in
                            view.overlay(OverlayView(color: Colors.pinkColor))
                        }

                    Text("P:")
                    StyledAttributedTextEditor(text: $model.text4, focusedField: $model.focusedTextFieldIndex, tag: 3)
                        .if(shouldDisplayMicrophoneTarget(tag: 3)) { view in
                            view.overlay(OverlayView(color: Colors.pinkColor))
                        }
                }
                .padding(16)
                .frame(maxHeight: .infinity)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    AttendiMicrophone(
                        recorder: model.recorder,
                        settings: AttendiMicrophoneSettings(
                            size: 64,
                            colors: AttendiMicrophoneColors(
                                activeForegroundColor: Colors.pinkColor,
                                activeBackgroundColor: Color.white,
                                inactiveForegroundColor: Colors.pinkColor,
                                inactiveBackgroundColor: Color.white
                            ),
                            showsDefaultPermissionsDeniedAlert: false
                        ),
                        onRecordingPermissionDeniedCallback: {
                            isMissingPermissionsAlertPrensented = true
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 64 / 2)
                            .stroke(Color.pink, lineWidth: 1)
                    )
                    .padding(16)
                }
            }
        }
        .alert("Missing Permissions", isPresented: $isMissingPermissionsAlertPrensented) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Recording Permissions have to be granted in order to use the microphone")
        }
        .alert("Error", isPresented: $model.isErrorAlertShown) {
            Button("OK", role: .cancel) {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "Unknown error")
        }
    }

    private struct StyledAttributedTextEditor: View {
        @Binding var text: String
        @Binding var focusedField: Int?
        var tag: Int

        var body: some View {
            AttributedTextEditor(
                text: $text,
                focusedField: $focusedField,
                tag: tag
            )
            .padding(8)
            .frame(maxWidth: .infinity)
            .frame(height: 100, alignment: .top)
            .overlay(
                OverlayView(color: Colors.greyColor)
            )
        }
    }

    private struct OverlayView: View {
        let color: Color

        var body: some View {
            RoundedRectangle(cornerRadius: 8)
                .stroke(color)
        }
    }
}
