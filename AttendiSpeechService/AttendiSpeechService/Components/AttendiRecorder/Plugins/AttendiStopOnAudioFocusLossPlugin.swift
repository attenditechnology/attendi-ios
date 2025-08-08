import Foundation
import AVFoundation

/// A plugin for AttendiRecorder that automatically stops recording when audio focus is lost.
///
/// This plugin listens for changes in audio session interruptions using iOS’s AVAudioSession.
/// It stops the audio recording when the app loses focus—either due to incoming calls,
/// Siri, or other interruptions.
public final class AttendiStopOnAudioFocusLossPlugin: AttendiRecorderPlugin {

    private var notificationCenter: NotificationCenter = .default
    private var isRecording = false
    private var model: AttendiRecorderModel?

    public init() { }

    public func activate(model: AttendiRecorderModel) async {
        self.model = model
        notificationCenter.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

        await model.onStartRecording { [weak self] in
            guard let self else { return }
            isRecording = true
            try? AVAudioSession.sharedInstance().setActive(true, options: [])
        }

        await model.onStopRecording { [weak self] in
            guard let self else { return }
            isRecording = false
            try? AVAudioSession.sharedInstance().setActive(false, options: [])
        }
    }

    public func deactivate(model: AttendiRecorderModel) async {
        self.model = nil
        notificationCenter.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    }

    @objc private func handleAudioInterruption(notification: Notification) {
        guard
            isRecording,
            let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }

        if type == .began {
            Task {
                await model?.stop()
            }
        }
    }
}
