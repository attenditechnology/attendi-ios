import AVFoundation
import Combine

/// Protocol defining the contract for an audio recorder.
///
/// This protocol provides methods to start and stop recording with optional delays,
/// exposes the current recorder state via a Combine `Publisher`, and includes a
/// `release()` method for proper cleanup of resources.
///
/// The `release()` method **must be called** when the recorder is no longer needed,
/// to avoid resource leaks including audio session locks, memory consumption, or thread retention.
public protocol AttendiRecorder {

    /// The core model containing callbacks and state update hooks used to drive plugin behavior.
    /// Plugins and UI components can observe or register to react to events such as start, stop,
    /// audio frame emission, or error occurrences.
    var model: AttendiRecorderModel { get }

    /// The current recording state `AttendiRecorderState`.
    var recorderState: AttendiRecorderState { get }

    /// A publisher that emits the current `AttendiRecorderState`, enabling reactive observation of the recorder’s lifecycle state.
    /// Useful for updating UI or triggering logic based on whether the recorder is idle, recording, or processing.
    var recorderStatePublisher: AnyPublisher<AttendiRecorderState, Never> { get }

    /// Indicates whether the recorder has ever started recording during its lifetime.
    ///
    /// This can be helpful for analytics or conditional logic based on recording activity.
    var isAudioSessionActive: Bool { get }

    /// Utility method to check if the user has granted permission to record audio.
    ///
    /// - Returns: `true` if permission is granted, `false` otherwise.
    func hasRecordAudioPermissionGranted() -> Bool

    /// Sets the plugins for the `AttendiRecorder`.
    ///
    /// This method should be called after the recorder is created, rather than
    /// during initialization. This is not due to retain cycles, but because some
    /// plugins may capture `self` as a reference, which prevents the recorder
    /// from being instantiated directly with those plugins.
    ///
    /// Calling this method will deactivate all previously set plugins and
    /// activate the new ones provided.
    ///
    /// - Parameter plugins: An array of `AttendiRecorderPlugin` instances to attach to the recorder.
    func setPlugins(_ plugins: [AttendiRecorderPlugin]) async

    /// Starts recording.
    func start() async

    /// Starts recording after a delay specified in milliseconds.
    ///
    /// - Parameter delayMilliseconds: Delay before starting the recording, in milliseconds.
    func start(delayMilliseconds: Int) async

    /// Stops recording.
    func stop() async

    /// Stops recording after a delay specified in milliseconds.
    ///
    /// - Parameter delayMilliseconds: Delay before stopping the recording, in milliseconds.
    func stop(delayMilliseconds: Int) async

    /// Releases any resources associated with the recorder.
    ///
    /// This should be called when the recorder is no longer needed to ensure proper deallocation
    /// of internal buffers, threads, and audio session resources.
    func release() async
}
