import AVFoundation

/// A plugin for `AttendiMicrophone` that plays audible notification sounds when recording starts and stops.
///
/// This plugin uses `AVAudioPlayer` to play short audio cues:
/// - A **start** sound is played before recording begins, with a brief delay to avoid recording the sound.
/// - A **stop** sound is played immediately after recording ends.
///
/// The start sound playback is awaited before recording starts, to avoid capturing the sound itself in the recording.
/// A timeout of 2000ms ensures the app doesn't hang indefinitely if playback fails or doesn't complete.
public final class AttendiAudioNotificationPlugin: AttendiRecorderPlugin {

    private static let startNotificationTimeoutMilliseconds = 2000

    private let startNotificationSoundURL: URL
    private let stopNotificationSoundURL: URL

    private var startNotificationSound: AVAudioPlayer?
    private var stopNotificationSound: AVAudioPlayer?
    private var completionBridge: AudioPlayerCompletionBridge?

    public init(
        startNotificationSoundURL: URL? = nil,
        stopNotificationSoundURL: URL? = nil
    ) {
        self.startNotificationSoundURL = startNotificationSoundURL ?? Files.startNotificationMp3.url
        self.stopNotificationSoundURL = stopNotificationSoundURL ?? Files.stopNotificationMp3.url
    }

    public func activate(model: AttendiRecorderModel) async {
        if startNotificationSound == nil {
            startNotificationSound = loadNotificationSound(url: startNotificationSoundURL)
        }
        if stopNotificationSound == nil {
            stopNotificationSound = loadNotificationSound(url: stopNotificationSoundURL)
        }

        await model.onBeforeStartRecording { [weak self] in
            guard let self else { return }
            await playNotificationSoundWithTimeout(startNotificationSound)
        }

        await model.onStopRecording { [weak self] in
            guard let self else { return }
            await playNotificationSoundWithTimeout(stopNotificationSound)
        }
    }

    /// An AVAudioSession is needed to be active in order for the sound to play
    /// This function safely manages the audio session state without interfering with active recordings.
    @discardableResult private func setAudioSessionState(active: Bool) -> Bool {
        let session = AVAudioSession.sharedInstance()

        /// Check if the session is currently being used for recording.
        let isSessionUsedForRecording = session.category == .playAndRecord ||
        session.category == .record ||
        session.isOtherAudioPlaying

        guard !isSessionUsedForRecording else {
            return true
        }

        do {
            if active {
                try session.setCategory(.playback)
            }
            try session.setActive(active)
            return true
        } catch {
            return false
        }
    }

    private func loadNotificationSound(url: URL) -> AVAudioPlayer? {
        let audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.prepareToPlay()
        return audioPlayer
    }

    private func playNotificationSoundWithTimeout(_ sound: AVAudioPlayer?) async {
        guard let sound = sound else { return }

        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume()
                return
            }

            /// Only play if the audio session can be set to true.
            guard setAudioSessionState(active: true) else {
                continuation.resume()
                return
            }

            var resumed = false

            /// Bridge for AVAudioPlayerDelegate.
            let bridge = AudioPlayerCompletionBridge {
                if !resumed {
                    resumed = true
                    continuation.resume()
                }
            }
            completionBridge = bridge
            sound.delegate = bridge
            sound.prepareToPlay()
            sound.play()

            /// Timeout task
            Task {
                try? await Task.sleep(nanoseconds: Self.startNotificationTimeoutMilliseconds.milliToNano())
                if !resumed {
                    resumed = true
                    sound.stop()
                    continuation.resume()
                }
            }
        }
    }

    public func deactivate(model: AttendiRecorderModel) async {
        startNotificationSound?.stop()
        stopNotificationSound?.stop()
        startNotificationSound = nil
        stopNotificationSound = nil
        completionBridge = nil
    }
}
