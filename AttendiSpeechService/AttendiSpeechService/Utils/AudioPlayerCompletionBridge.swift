import AVFoundation

/// A lightweight delegate bridge that converts `AVAudioPlayer`'s completion callback into a closure.
///
/// This is useful for cases where you want to await the end of a sound using a closure,
/// rather than conforming to `AVAudioPlayerDelegate` in your class.
///
/// - Important:
/// `AVAudioPlayer` holds a **weak reference** to its `delegate`. Therefore, you **must retain**
/// an instance of `AudioPlayerCompletionBridge` for as long as the audio is playing,
/// otherwise the callback will never be invoked.
///
/// - Example usage:
/// ```swift
/// let bridge = AudioPlayerCompletionBridge {
///     /// This will be called when playback finishes.
/// }
/// player.delegate = bridge
/// self.bridge = bridge /// Important: Retain the bridge.
/// player.play()
/// ```
final class AudioPlayerCompletionBridge: NSObject, AVAudioPlayerDelegate {
    private let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onComplete()
    }
}
