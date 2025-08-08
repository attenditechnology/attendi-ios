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
final class TwoMicrophonesStreamingScreenViewModel {

    var model: TwoMicrophonesStreamingScreenModel

    private let shortTextRecorder: AttendiRecorder
    private let largeTextRecorder: AttendiRecorder
    private var cancellables: Set<AnyCancellable> = []

    init() {
        shortTextRecorder = AttendiRecorderFactory.create()
        largeTextRecorder = AttendiRecorderFactory.create()
        model = TwoMicrophonesStreamingScreenModel(
            shortTextFieldModel: TwoMicrophonesStreamingScreenModel.TextFieldModel(recorder: shortTextRecorder),
            longTextFieldModel: TwoMicrophonesStreamingScreenModel.TextFieldModel(recorder: largeTextRecorder)
        )

        Task {
            await shortTextRecorder.setPlugins(createSmallRecorderPlugins())
            await largeTextRecorder.setPlugins(createLargeRecorderPlugins())
        }
    }

    private func createSmallRecorderPlugins() -> [AttendiRecorderPlugin] {
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
                    model.shortTextFieldModel.text = stream.state.text
                    model.shortTextFieldModel.annotations = stream.state.annotations
                },
                onStreamCompleted: { [weak self] stream, error in
                    guard let self else { return }
                    if let error {
                        model.errorMessage = error.localizedDescription
                        model.isErrorAlertShown = true
                    } else {
                        model.shortTextFieldModel.text = stream.state.text
                        model.shortTextFieldModel.annotations = []
                    }
                }
            )
        ]
    }

    private func createLargeRecorderPlugins() -> [AttendiRecorderPlugin] {
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
                    model.longTextFieldModel.text = stream.state.text
                    model.longTextFieldModel.annotations = stream.state.annotations
                },
                onStreamCompleted: { [weak self] stream, error in
                    guard let self else { return }
                    if let error {
                        model.errorMessage = error.localizedDescription
                        model.isErrorAlertShown = true
                    } else {
                        model.longTextFieldModel.text = stream.state.text
                        model.longTextFieldModel.annotations = []
                    }
                }
            )
        ]
    }

    deinit {
        let smallTextRecorder = self.shortTextRecorder
        let largeTextRecorder = self.largeTextRecorder

        Task.detached(priority: .background) {
            await smallTextRecorder.release()
            await largeTextRecorder.release()
        }
    }
}
