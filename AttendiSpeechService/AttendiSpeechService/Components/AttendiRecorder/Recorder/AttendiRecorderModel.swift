import Foundation
import Combine

/// Represents the various lifecycle states of an `AttendiRecorder`.
public enum AttendiRecorderState {
    /// Initial state before recording has started.
    case notStartedRecording
    /// Loading or preparing resources before recording begins.
    case loadingBeforeRecording
    /// Actively recording audio.
    case recording
    /// Performing post-processing or cleanup after recording.
    case processing
}

/// A container for asynchronous callback lists that allow clients to
/// react to recorder lifecycle events.
///
/// All callbacks are stored in actor-isolated arrays and invoked safely
/// on their associated dispatch context.
///
/// This actor enables registering and triggering suspendable (async)
/// functions during important events such as starting/stopping recording,
/// audio frame arrival, or encountering an error.
public actor AttendiRecorderCallbacks {

    /// Called whenever the recorder state changes.
    private(set) var onStateUpdate: [UUID: (AttendiRecorderState) async -> Void] = [:]

    /// Called just before recording is started.
    private(set) var onBeforeStartRecording: [UUID: () async -> Void] = [:]

    /// Called immediately after recording has started.
    private(set) var onStartRecording: [UUID: () async -> Void] = [:]

    /// Called just before recording is stopped.
    private(set) var onBeforeStopRecording: [UUID: () async -> Void] = [:]

    /// Called immediately after recording has stopped.
    private(set) var onStopRecording: [UUID: () async -> Void] = [:]

    /// Called when an error occurs during recording.
    private(set) var onError: [UUID: (Error) async -> Void] = [:]

    /// Called when a new audio frame is available during recording.
    private(set) var onAudioFrame: [UUID: (AudioFrame) async -> Void] = [:]

    /// Register a callback for recorder state updates.
    func addOnStateUpdate(_ callback: @escaping (AttendiRecorderState) async -> Void) -> UUID {
        let id = UUID()
        onStateUpdate[id] = callback
        return id
    }

    func removeOnStateUpdate(_ id: UUID) {
        onStateUpdate.removeValue(forKey: id)
    }

    /// Invoke all registered state update callbacks.
    func invokeOnStateUpdate(_ state: AttendiRecorderState) async {
        let list = onStateUpdate.values
        for callback in list {
            await callback(state)
        }
    }

    /// Register a callback that runs before recording starts.
    func addOnBeforeStartRecording(_ callback: @escaping () async -> Void) -> UUID {
        let id = UUID()
        onBeforeStartRecording[id] = callback
        return id
    }

    func removeOnBeforeStartRecording(_ id: UUID) {
        onBeforeStartRecording.removeValue(forKey: id)
    }

    func invokeOnBeforeStartRecording() async {
        let list = onBeforeStartRecording.values
        for callback in list {
            await callback()
        }
    }

    /// Register a callback that runs immediately after recording starts.
    func addOnStartRecording(_ callback: @escaping () async -> Void) -> UUID {
        let id = UUID()
        onStartRecording[id] = callback
        return id
    }

    func removeOnStartRecording(_ id: UUID) {
        onStartRecording.removeValue(forKey: id)
    }

    func invokeOnStartRecording() async {
        let list = onStartRecording.values
        for callback in list {
            await callback()
        }
    }

    /// Register a callback that runs before recording stops.
    func addOnBeforeStopRecording(_ callback: @escaping () async -> Void) -> UUID {
        let id = UUID()
        onBeforeStopRecording[id] = callback
        return id
    }

    func removeOnBeforeStopRecording(_ id: UUID) {
        onBeforeStopRecording.removeValue(forKey: id)
    }

    func invokeOnBeforeStopRecording() async {
        let list = onBeforeStopRecording.values
        for callback in list {
            await callback()
        }
    }

    /// Register a callback that runs immediately after recording stops.
    func addOnStopRecording(_ callback: @escaping () async -> Void) -> UUID {
        let id = UUID()
        onStopRecording[id] = callback
        return id
    }

    func removeOnStopRecording(_ id: UUID) {
        onStopRecording.removeValue(forKey: id)
    }

    func invokeOnStopRecording() async {
        let list = onStopRecording.values
        for callback in list {
            await callback()
        }
    }

    /// Register a callback for handling errors during recording.
    func addOnError(_ callback: @escaping (Error) async -> Void) -> UUID {
        let id = UUID()
        onError[id] = callback
        return id
    }

    func removeOnError(_ id: UUID) {
        onError.removeValue(forKey: id)
    }

    func invokeOnError(_ error: Error) async {
        let list = onError.values
        for callback in list {
            await callback(error)
        }
    }

    /// Register a callback to be called when an audio frame is available.
    func addOnAudioFrame(_ callback: @escaping (AudioFrame) async -> Void) -> UUID {
        let id = UUID()
        onAudioFrame[id] = callback
        return id
    }

    func removeOnAudioFrame(_ id: UUID) {
        onAudioFrame.removeValue(forKey: id)
    }

    func invokeOnAudioFrame(_ frame: AudioFrame) async {
        let list = onAudioFrame.values
        for callback in list {
            await callback(frame)
        }
    }
}

/// Model class managing the state and callbacks of an `AttendiRecorder`.
///
/// This class exposes the current recording state as an observable value
/// and provides a mechanism to register for various lifecycle events like
/// start, stop, error, or incoming audio frames.
///
/// It also supports injecting custom async logic to run when recording starts or stops.
public final class AttendiRecorderModel {

    /// The current state of the recorder.
    @Published public private(set) var state: AttendiRecorderState = .notStartedRecording

    /// The container for all recorder lifecycle callbacks.
    private(set) var callbacks = AttendiRecorderCallbacks()

    /// An optional async function to invoke when recording starts.
    var onStartCalled: (() async -> Void)? = nil

    /// An optional async function to invoke when recording stops.
    var onStopCalled: (() async -> Void)? = nil

    /// Creates a new instance of `AttendiRecorderModel`.
    public init() { }

    /// Starts the recorder and invokes the `onStartCalled` handler, if set.
    public func start() async {
        await onStartCalled?()
    }

    /// Stops the recorder and invokes the `onStopCalled` handler, if set.
    public func stop() async {
        await onStopCalled?()
    }

    /// Updates the internal recorder state and notifies all registered state observers.
    ///
    /// - Parameter newState: The new state to set.
    /// 
    /// This method is marked `@MainActor` to ensure that changes to the `@Published`
    /// `state` property occur on the main thread. In SwiftUI and Combine, `@Published`
    /// properties are expected to be updated from the main actor to maintain thread safety
    /// and avoid runtime warnings or UI inconsistencies.
    @MainActor public func updateState(_ newState: AttendiRecorderState) async {
        state = newState
        await callbacks.invokeOnStateUpdate(newState)
    }

    /// Register a callback to be invoked whenever the recorder state updates.
    @discardableResult public func onStateUpdate(
        _ callback: @escaping (AttendiRecorderState) async -> Void
    ) async -> () async -> Void {
        let callbacks = callbacks
        let id = await callbacks.addOnStateUpdate(callback)
        return {
            await callbacks.removeOnStateUpdate(id)
        }
    }

    /// Register a callback to be invoked before recording starts.
    @discardableResult public func onBeforeStartRecording(
        _ callback: @escaping () async -> Void
    ) async -> () async -> Void {
        let callbacks = callbacks
        let id = await callbacks.addOnBeforeStartRecording(callback)
        return {
            await callbacks.removeOnBeforeStartRecording(id)
        }
    }

    /// Register a callback to be invoked after recording starts.
    @discardableResult public func onStartRecording(
        _ callback: @escaping () async -> Void
    ) async -> () async -> Void {
        let callbacks = callbacks
        let id = await callbacks.addOnStartRecording(callback)
        return {
            await callbacks.removeOnStartRecording(id)
        }
    }

    /// Register a callback to be invoked before recording stops.
    @discardableResult public func onBeforeStopRecording(
        _ callback: @escaping () async -> Void
    ) async -> () async -> Void {
        let callbacks = callbacks
        let id = await callbacks.addOnBeforeStopRecording(callback)
        return {
            await callbacks.removeOnBeforeStopRecording(id)
        }
    }

    /// Register a callback to be invoked after recording stops.
    @discardableResult public func onStopRecording(
        _ callback: @escaping () async -> Void
    ) async -> () async -> Void {
        let callbacks = callbacks
        let id = await callbacks.addOnStopRecording(callback)
        return {
            await callbacks.removeOnStopRecording(id)
        }
    }

    /// Register a callback to be invoked when an error occurs.
    @discardableResult public func onError(
        _ callback: @escaping (Error) async -> Void
    ) async -> () async -> Void {
        let callbacks = callbacks
        let id = await callbacks.addOnError(callback)
        return {
            await callbacks.removeOnError(id)
        }
    }

    /// Register a callback to be invoked when a new audio frame is available.
    ///
    /// Use this to stream, analyze, or visualize incoming audio frames.
    @discardableResult public func onAudio(
        _ callback: @escaping (AudioFrame) async -> Void
    ) async -> () async -> Void {
        let callbacks = callbacks
        let id = await callbacks.addOnAudioFrame(callback)
        return {
            await callbacks.removeOnAudioFrame(id)
        }
    }
}
