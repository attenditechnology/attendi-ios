import Foundation

/// Plugin protocol for components that react to the lifecycle of the recorder.
///
/// Use this when your plugin only depends on the audio recording state,
/// not the full microphone UI state.
public protocol AttendiRecorderPlugin {
    /// Called when the recorder is initialized.
    ///
    /// - Parameter model: Provides access to recorder-related state and operations.
    func activate(model: AttendiRecorderModel) async

    /// Called when the recorder is disposed.
    ///
    /// Use this to clean up any ongoing resources or subscriptions.
    ///
    /// - Parameter model: The recorder model instance used during activation.
    func deactivate(model: AttendiRecorderModel) async
}

public extension AttendiRecorderPlugin {
    func deactivate(model: AttendiRecorderModel) async {}
}
