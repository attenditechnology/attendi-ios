import SwiftUI
import AttendiSpeechService

struct OneMicrophoneSyncScreenView: View {

    @State private var text = ""
    @State private var errorMessage: String? = nil
    @State private var isErrorAlertShown: Bool = false

    private let recorder = AttendiRecorderFactory.create()

    var body: some View {
        ZStack {
            VStack {
                TextEditor(text: $text)
                    .scrollDisabled(true)
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                HStack {
                    Spacer()
                    AttendiMicrophone(
                        recorder: recorder,
                        settings: AttendiMicrophoneSettings(
                            size: 56,
                            colors: AttendiMicrophoneDefaults.colors(baseColor: Colors.pinkColor),
                            isVolumeFeedbackEnabled: false
                        )
                    )
                    .padding(8)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Colors.greyColor)
            )
            .padding(16)
        }
        .alert("Error", isPresented: $isErrorAlertShown) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .onAppear {
            Task {
                await recorder.setPlugins(
                    createRecorderPlugins(
                        textBinding: $text,
                        errorMessageBinding: $errorMessage
                    )
                )
            }
        }
    }

    /// Avoid capturing `self` by copying the bindings, otherwise the recorder will leak.
    private func createRecorderPlugins(
        textBinding: Binding<String>,
        errorMessageBinding: Binding<String?>
    ) -> [AttendiRecorderPlugin] {
        [
            ExampleWavTranscribePlugin(),
            ExampleErrorLoggerPlugin(),
            AttendiErrorPlugin(),
            AttendiAudioNotificationPlugin(),
            AttendiStopOnAudioFocusLossPlugin(),
            AttendiSyncTranscribePlugin(
                service: AttendiTranscribeServiceFactory.create(
                    apiConfig: ExampleAttendiTranscribeAPI.transcribeAPIConfig
                ),
                onTranscribeCompleted: { transcript, error in
                    if let error {
                        errorMessageBinding.wrappedValue = error.localizedDescription
                    } else {
                        textBinding.wrappedValue = transcript ?? ""
                    }
                }
            )
        ]
    }
}
