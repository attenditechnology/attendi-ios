import Foundation
import Combine

/// ViewModel responsible for managing the state, lifecycle, and behavior of the AttendiMicrophone component.
///
/// This ViewModel ensures microphone state, recording sessions, and plugins persist across configuration changes,
/// coordinating the recorder and plugin lifecycle while exposing reactive UI state.
///
/// The `@MainActor` attribute guarantees that all interactions with this ViewModel, including state mutations and
/// Combine publishing via `@Published`, occur on the main thread. This is essential for maintaining UI consistency
/// and avoiding race conditions or stale state emissions when multiple state updates happen in rapid succession.
///
/// By isolating all updates to the main thread, `@MainActor` resolves issues where changes to `@Published` properties
/// were occasionally missed or overwritten due to interleaved async updates from different threads (e.g., audio callbacks).
@MainActor
final class AttendiMicrophoneViewModel: ObservableObject {

    private static let loadingStateDelayMilliseconds = 150

    private let recorder: AttendiRecorder
    private let microphoneSettings: AttendiMicrophoneSettings
    private let onMicrophoneTapCallback: () -> Void
    private let onRecordingPermissionDeniedCallback: () -> Void

    private var loadingTask: Task<Void, Never>?
    private var microphoneModel = AttendiMicrophoneModel()
    private var microphoneVolumeFeedbackPlugin: AttendiMicrophoneVolumeFeedbackPlugin?

    @Published private(set) var microphoneUIState: AttendiMicrophoneUIState

    private var cancellables = Set<AnyCancellable>()

    init(
        recorder: AttendiRecorder,
        microphoneSettings: AttendiMicrophoneSettings,
        onMicrophoneTapCallback: @escaping () -> Void,
        onRecordingPermissionDeniedCallback: @escaping () -> Void
    ) {
        self.recorder = recorder
        self.microphoneSettings = microphoneSettings
        self.onMicrophoneTapCallback = onMicrophoneTapCallback
        self.onRecordingPermissionDeniedCallback = onRecordingPermissionDeniedCallback
        microphoneUIState = microphoneModel.uiState

        setupPluginLifecycle()
        bindRecorderState()
    }

    /// Handles the tap on the microphone UI component.
    func onTap() {
        showLoadingState()

        microphoneModel.updateShouldVerifyAudioPermission(true)

        onMicrophoneTapCallback()
    }

    func onAlreadyGrantedRecordingPermissions() {
        microphoneModel.updateShouldVerifyAudioPermission(false)

        Task {
            toggleRecording()
        }
    }

    func onJustGrantedRecordingPermissions() {
        microphoneModel.updateShouldVerifyAudioPermission(false)

        Task {
            await recorder.start()
        }
    }

    func onDeniedPermissions() {
        loadingTask?.cancel()
        microphoneModel.updateShouldVerifyAudioPermission(false)
        microphoneModel.updateState(.idle)

        onRecordingPermissionDeniedCallback()
    }

    /// Cancels loading state task and shows loading state if recording takes time to start.
    private func showLoadingState() {
        guard recorder.recorderState == .notStartedRecording else { return }

        loadingTask?.cancel()
        loadingTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.loadingStateDelayMilliseconds.milliToNano())

            if Task.isCancelled { return }

            if recorder.recorderState == .notStartedRecording {
                microphoneModel.updateState(.loading)
            }
        }
    }

    /// Starts or stops recording depending on current state.
    private func toggleRecording() {
        Task {
            let state = recorder.recorderState
            if state == .notStartedRecording {
                await recorder.start()
            } else if state == .recording {
                loadingTask?.cancel()
                await recorder.stop()
            }
        }
    }

    /// Binds the recorder's state changes to microphone UI updates.
    private func bindRecorderState() {
        microphoneModel.uiStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                microphoneUIState = state
            }
            .store(in: &cancellables)

        recorder.recorderStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .notStartedRecording:
                    microphoneModel.updateState(.idle)
                case .loadingBeforeRecording:
                    microphoneModel.updateState(.loading)
                case .recording:
                    microphoneModel.updateState(.recording)
                case .processing:
                    microphoneModel.updateState(.processing)
                }
            }
            .store(in: &cancellables)
    }

    /// Activates plugins and sets up cleanup on deinit.
    private func setupPluginLifecycle() {
        Task {
            await recorder.model.onError { [weak self] _ in
                guard let self else { return }
                loadingTask?.cancel()
            }

            if microphoneSettings.isVolumeFeedbackEnabled {
                microphoneVolumeFeedbackPlugin = AttendiMicrophoneVolumeFeedbackPlugin(microphoneModel: microphoneModel)
                await microphoneVolumeFeedbackPlugin?.activate(model: recorder.model)
            }
        }
    }

    /// Cleans up plugins and recorder when ViewModel is deallocated.
    deinit {
        let recorder = self.recorder
        let microphoneVolumeFeedbackPlugin = self.microphoneVolumeFeedbackPlugin

        Task.detached(priority: .background) {
            await microphoneVolumeFeedbackPlugin?.deactivate(model: recorder.model)
            await recorder.release()
        }
    }
}
