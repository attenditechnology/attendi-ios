import Foundation
import Combine
import AttendiSpeechService

/// A view model that manages the presentation logic and coordinates updates between the UI and underlying model.
///
/// This class is marked with `@MainActor` because it is responsible for driving view updates
/// and interacting with SwiftUI-bound state. All interactions with observable models and UI state
/// must occur on the main thread to maintain consistency and avoid runtime issues.
///
/// By applying `@MainActor`, all functions and property accesses within the view model are implicitly
/// confined to the main thread, ensuring that updates to observable state and calls into SwiftUI
/// are safe and predictable.
@MainActor
final class SoapScreenViewModel {

    var model: SoapScreenModel

    private let recorder: AttendiRecorder
    private var cancellables: Set<AnyCancellable> = []

    init() {
        recorder = AttendiRecorderFactory.create()
        model = SoapScreenModel(recorder: recorder)

        Task {
            await recorder.setPlugins(createRecorderPlugins())
        }

        recorder.recorderStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recorderState in
                guard let self else { return }
                onRecorderStateChange(recorderState)
            }
            .store(in: &cancellables)
    }

    private func onRecorderStateChange(_ newRecorderState: AttendiRecorderState) {
        model.canDisplayFocusedTextField = newRecorderState == .recording || newRecorderState == .processing
    }

    private func createRecorderPlugins() -> [AttendiRecorderPlugin] {
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
                onTranscribeCompleted: { [weak self] transcript, error in
                    guard let self else { return }
                    if let error {
                        model.errorMessage = error.localizedDescription
                        model.isErrorAlertShown = true
                    } else {
                        switch model.focusedTextFieldIndex {
                        case 0: model.text1 = transcript ?? ""
                        case 1: model.text2 = transcript ?? ""
                        case 2: model.text3 = transcript ?? ""
                        case 3: model.text4 = transcript ?? ""
                        default: break
                        }
                    }
                }
            )
        ]
    }

    deinit {
        let recorder = self.recorder

        Task.detached(priority: .background) {
            await recorder.release()
        }
    }
}
