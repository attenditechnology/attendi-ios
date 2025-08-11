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
final class RecorderStreamingScreenViewModel {

    var model: RecorderStreamingScreenModel
    private let recorder: AttendiRecorder
    private var cancellables: Set<AnyCancellable> = []

    init() {
        model = RecorderStreamingScreenModel()
        recorder = AttendiRecorderFactory.create()
        setupInitialConfiguration()
    }

    private func setupInitialConfiguration() {
        model.onStartRecordingTap = { [weak self] in
            guard let self else { return }
            onButtonPressed()
        }

        Task {
            await recorder.model.onError { [weak self] error in
                guard let self else { return }
                model.errorMessage = error.localizedDescription
                model.isErrorAlertShown = true
            }

            await recorder.setPlugins(createRecorderPlugins())
        }

        /// Subscribes to `recorder.recorderState` changes using Combine.
        ///
        /// - Receives updates on the main thread to ensure UI-related changes can occur safely.
        /// - Uses `[weak self]` to prevent retain cycles and memory leaks.
        /// - Calls `onRecorderStateChange(_:)` whenever a new recorder state is emitted.
        /// - Stores the subscription in the `cancellables` set to maintain its lifecycle.
        recorder.recorderStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recorderState in
                guard let self else { return }
                onRecorderStateChange(recorderState)
            }
            .store(in: &cancellables)
    }

    private func onRecorderStateChange(_ newRecorderState: AttendiRecorderState) {
        switch newRecorderState {
        case .notStartedRecording:
            model.buttonTitle = "Start Recording"
        case .loadingBeforeRecording:
            model.buttonTitle = "Loading"
        case .recording:
            model.buttonTitle = "Stop Recording"
        case .processing:
            model.buttonTitle = "Processing"
        @unknown default:
            model.buttonTitle = "Unknown"
        }
    }

    private func onButtonPressed() {
        Task {
            if recorder.model.state == AttendiRecorderState.notStartedRecording {
                await recorder.start()
            } else if recorder.model.state == AttendiRecorderState.recording {
                await recorder.stop()
            }
        }
    }

    private func createRecorderPlugins() -> [AttendiRecorderPlugin] {
        [
            ExampleWavTranscribePlugin(),
            ExampleErrorLoggerPlugin(),
            AttendiErrorPlugin(),
            AttendiAudioNotificationPlugin(),
            AttendiStopOnAudioFocusLossPlugin(),
            AttendiAsyncTranscribePlugin(
                service: AttendiAsyncTranscribeServiceFactory.create(
                    apiConfig: ExampleAttendiTranscribeAPI.transcribeAPIConfig
                ),
                onStreamUpdated: { [weak self] stream in
                    guard let self else { return }
                    model.textEditorText = stream.state.text
                },
                onStreamCompleted: { [weak self] stream, error in
                    guard let self else { return }
                    if let error {
                        model.errorMessage = error.localizedDescription
                        model.isErrorAlertShown = true
                    } else {
                        model.textEditorText = stream.state.text
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
