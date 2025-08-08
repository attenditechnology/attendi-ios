import AVFoundation
import Combine

/// A concrete implementation of the `AttendiRecorder` protocol.
///
/// `AttendiRecorderImpl` manages audio recording by:
/// - Delegating capture logic to a lower-level `AudioRecorder` abstraction.
/// - Handling audio configuration, such as sample rate and format.
/// - Coordinating a set of `AttendiRecorderPlugin` instances that can extend or customize behavior during the recorder's lifecycle.
///
/// ### Responsibilities:
/// - Managing the recording state and publishing updates.
/// - Invoking plugin callbacks at appropriate lifecycle stages (e.g., on start, stop, audio frame, or error).
/// - Performing proper resource cleanup via `release()` to avoid memory leaks or dangling audio sessions.
///
/// ### Parameters:
/// - `audioRecordingConfig`: Configuration for audio capture, including sample rate, encoding, and number of channels.
/// - `recorder`: A low-level `AudioRecorder` implementation that performs the actual audio capture (default is `AudioRecorderImpl`).
/// - `plugins`: A list of `AttendiRecorderPlugin` instances to hook into lifecycle events such as transcription, logging, or focus handling.
///
/// Note: Plugins are activated and deactivated in sync with the recorder lifecycle. This allows modular and reusable audio processing logic.
final class AttendiRecorderImpl: AttendiRecorder {

    private let audioRecordingConfig: AudioRecordingConfig
    private let recorder: AudioRecorder
    private var plugins: [AttendiRecorderPlugin]

    private(set) var model: AttendiRecorderModel = AttendiRecorderModel()

    /// A mutual exclusion lock to ensure that [start], [stop], and [release] operations
    /// are not executed concurrently. This protects against race conditions in the
    /// recorder’s lifecycle methods.
    private let startStopMutex = AsyncMutex()

    /// Tracks whether the recorder has been started.
    /// Used to prevent duplicate or invalid calls to `start` or `stop`.
    private var hasStarted = false

    /// Tracks whether the recorder has already been released.
    /// Prevents repeated cleanup logic from executing, making [release] idempotent.
    private var isReleased = false

    /// A reference to the task responsible for running the actual recording.
    /// This is canceled and cleared when recording is stopped or released.
    private var recorderTask: Task<Void, Error>? = nil

    /// Initializes a new recorder instance with optional audio configuration and plugins.
    ///
    /// - Parameters:
    ///   - audioRecordingConfig: Audio capture configuration (default is `AudioRecordingConfig()`).
    ///   - recorder: The internal recorder to use for capturing audio (default is `AudioRecorderImpl()`).
    ///   - plugins: A list of plugins to attach to the recording lifecycle (default is empty).
    init(
        audioRecordingConfig: AudioRecordingConfig = AudioRecordingConfig(),
        recorder: AudioRecorder = AudioRecorderImpl.shared,
        plugins: [AttendiRecorderPlugin] = []
    ) {
        self.audioRecordingConfig = audioRecordingConfig
        self.recorder = recorder
        self.plugins = plugins

        /// The reason `onStartCalled` and `onStopCalled` are assigned here is to allow the consumer
        /// to initiate recording imperatively via the model.
        ///
        /// When `start()` or `stop()` is called on the model, these callbacks are triggered internally,
        /// ensuring proper plugin behavior without exposing implementation details.
        ///
        /// These callbacks are intentionally marked as `internal` to prevent external consumers from
        /// overriding them directly when using the plugin, preserving encapsulation and consistency.
        model.onStartCalled = { [weak self] in
            guard let self else { return }
            await start()
        }

        model.onStopCalled = { [weak self] in
            guard let self else { return }
            await stop()
        }

        Task {
            for plugin in plugins {
                await plugin.activate(model: model)
            }
        }
    }

    var recorderState: AttendiRecorderState {
        model.state
    }

    var recorderStatePublisher: AnyPublisher<AttendiRecorderState, Never> {
        model.$state.eraseToAnyPublisher()
    }

    var isAudioSessionActive: Bool {
        model.state != AttendiRecorderState.notStartedRecording
    }

    func hasRecordAudioPermissionGranted() -> Bool {
        AVAudioSession.sharedInstance().recordPermission == .granted
    }

    func setPlugins(_ plugins: [AttendiRecorderPlugin]) async {
        for plugin in self.plugins {
            await plugin.deactivate(model: model)
        }

        for plugin in plugins {
            await plugin.activate(model: model)
        }

        self.plugins = plugins
    }

    func start() async {
        await start(delayMilliseconds: 0)
    }

    func start(delayMilliseconds: Int) async {
        await handleErrors {
            await startStopMutex.withLock {
                if hasStarted || isReleased {
                    return
                }
                
                hasStarted = true
                recorderTask?.cancel()

                await model.updateState(.loadingBeforeRecording)
                await model.callbacks.invokeOnBeforeStartRecording()

                recorderTask = Task {
                    try await Task.sleep(nanoseconds: delayMilliseconds.milliToNano())
                    await handleErrors {
                        try await recorder.startRecording(
                            audioRecordingConfig: audioRecordingConfig,
                            onAudio: { audioFrame in
                                await self.model.callbacks.invokeOnAudioFrame(audioFrame)
                            }
                        )
                        await model.updateState(.recording)
                        await model.callbacks.invokeOnStartRecording()
                    }
                }
            }
        }
    }

    func stop() async {
        await stop(delayMilliseconds: 0)
    }

    func stop(delayMilliseconds: Int) async {
        await handleErrors {
            await startStopMutex.withLock {
                if !hasStarted || isReleased {
                    return
                }
                hasStarted = false

                await model.updateState(.processing)
                await model.callbacks.invokeOnBeforeStopRecording()

                try? await Task.sleep(nanoseconds: delayMilliseconds.milliToNano())

                await recorder.stopRecording()

                recorderTask?.cancel()
                recorderTask = nil

                await model.callbacks.invokeOnStopRecording()
                await model.updateState(.notStartedRecording)
            }
        }
    }

    func release() async {
        await startStopMutex.withLock {
            if isReleased {
                return
            }
            isReleased = true

            for plugin in plugins {
                await plugin.deactivate(model: model)
            }

            recorderTask?.cancel()
            recorderTask = nil

            await recorder.stopRecording()
        }
    }

    private func handleErrors(_ toRun: () async throws -> Void) async {
        do {
            try await toRun()
        } catch {
            if (error as? CancellationError) == nil {
                hasStarted = false

                await model.updateState(AttendiRecorderState.notStartedRecording)
                await model.callbacks.invokeOnError(error)
            }
        }
    }
}
