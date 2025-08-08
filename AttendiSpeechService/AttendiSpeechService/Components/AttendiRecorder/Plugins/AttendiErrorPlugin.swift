import AVFoundation

/// A plugin for `AttendiMicrophone` that provides audio and haptic feedback when a recording error occurs.
///
/// When an error is reported via the `AttendiRecorderModel.onError` callback, this plugin:
/// - Plays an error notification sound (from a bundled audio file named `error_notification`)
/// - Triggers a short device vibration
///
/// This enhances the user experience by giving immediate and clear feedback when something goes wrong
/// during audio recording (e.g., microphone access failure, unexpected termination).
///
/// The plugin ensures that the `AVAudioPlayer` used for sound playback is properly released
/// when the microphone is deactivated.
public final class AttendiErrorPlugin: AttendiRecorderPlugin {

    private let errorNotificationSoundURL: URL

    public init(errorNotificationSoundURL: URL? = nil) {
        self.errorNotificationSoundURL = errorNotificationSoundURL ?? Files.errorNotificationMp3.url
    }

    private var errorNotificationSound: AVAudioPlayer?

    public func activate(model: AttendiRecorderModel) async {
        if errorNotificationSound == nil {
            loadErrorNotificationSound()
        }

        await model.onError { [weak self] error in
            guard let self else { return }
            if let audioError = error as? AudioRecorderError,
               case .alreadyRecording = audioError {
                return
            }

            if errorNotificationSound == nil {
                loadErrorNotificationSound()
            }
            errorNotificationSound?.play()
            await Vibrator.vibrate(.error)
        }
    }

    public func deactivate(model: AttendiRecorderModel) async {
        errorNotificationSound?.stop()
        errorNotificationSound = nil
    }

    private func loadErrorNotificationSound() {
        errorNotificationSound = try? AVAudioPlayer(contentsOf: errorNotificationSoundURL)
        errorNotificationSound?.prepareToPlay()
    }
}
