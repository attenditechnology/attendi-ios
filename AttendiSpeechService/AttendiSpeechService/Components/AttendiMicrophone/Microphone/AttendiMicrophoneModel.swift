import Foundation
import Combine

/// Manages the reactive UI state for the `AttendiMicrophone`, exposing microphone state, input volume,
/// and permission verification status as a `ObservableObject` to enable reactive UI updates.
///
/// This model maintains an internal mutable state of `AttendiMicrophoneUIState`, which encapsulates
/// the current microphone state (e.g., idle, recording), the animated fill level when the microphone
/// is recording, and a flag indicating whether audio permission should be verified.
///
/// Use this class to observe and respond to microphone-related state changes in a lifecycle-aware and
/// reactive manner.
/// 
/// The `@MainActor` attribute ensures all state mutations and Combine publications via `@Published uiState`
/// happen on the main thread. This avoids subtle timing issues where Combine subscribers would observe
/// outdated or inconsistent state due to overlapping updates from multiple threads (e.g., audio thread vs UI thread).
///
/// Using `@MainActor` guarantees serialization of state changes and eliminates the need for additional
/// struct copying or locking mechanisms that would otherwise be required to synchronize access.
@MainActor
public final class AttendiMicrophoneModel: ObservableObject {

    @Published private(set) public var uiState = AttendiMicrophoneUIState()

    public var uiStatePublisher: AnyPublisher<AttendiMicrophoneUIState, Never> {
        $uiState.eraseToAnyPublisher()
    }

    public init() { }

    public func updateState(_ state: AttendiMicrophoneState) {
        uiState.state = state
    }

    public func updateAnimatedMicrophoneFillLevel(_ fillLevel: Double) {
        uiState.animatedMicrophoneFillLevel = fillLevel
    }

    public func updateShouldVerifyAudioPermission(_ enabled: Bool) {
        uiState.shouldVerifyAudioPermission = enabled
    }
}

/// Represents the reactive UI state of the [AttendiMicrophone], including the current microphone state,
/// audio input volume, and whether audio recording permissions should be checked.
///
/// This data class is used to drive UI components that react to microphone activity, volume levels,
/// and permission requirements.
///
/// - Parameters:
///    - property state: The current [AttendiMicrophoneState] of the microphone.
///    - property animatedMicrophoneFillLevel: A normalized and smoothed volume level used to animate visual microphone feedback.
///    This value ranges between 0.0 and 1.0.
///    - property shouldVerifyAudioPermission: Whether the UI should prompt the user to verify that
/// audio recording permissions are granted.
public struct AttendiMicrophoneUIState {

    public var state: AttendiMicrophoneState
    public var animatedMicrophoneFillLevel: Double
    public var shouldVerifyAudioPermission: Bool

    public init(
        state: AttendiMicrophoneState = AttendiMicrophoneState.idle,
        animatedMicrophoneFillLevel: Double = 0.0,
        shouldVerifyAudioPermission: Bool = false
    ) {
        self.state = state
        self.animatedMicrophoneFillLevel = animatedMicrophoneFillLevel
        self.shouldVerifyAudioPermission = shouldVerifyAudioPermission
    }
}

/// Represents the various states of the [AttendiMicrophone], used to drive UI behavior
/// and reflect the current stage of the recording lifecycle.
///
/// This enum is used within [AttendiMicrophoneUIState] to indicate what the microphone is
/// currently doing, allowing the UI to respond appropriately.
public enum AttendiMicrophoneState {
    case idle
    case loading
    case recording
    case processing
}
