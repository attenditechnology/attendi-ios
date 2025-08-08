import Foundation
import Darwin

/// To give extra feedback to the user that the microphone is recording, we display the volume
/// of the audio signal, which fills the inside of the microphone's cone in tandem with the volume level.
class AttendiMicrophoneVolumeFeedbackPlugin: AttendiRecorderPlugin {

    private let microphoneModel: AttendiMicrophoneModel

    private var volume: Double = 0

    init(microphoneModel: AttendiMicrophoneModel) {
        self.microphoneModel = microphoneModel
    }

    func activate(model: AttendiRecorderModel) async {
        await model.onAudio { [weak self] audioFrame in
            guard let self else { return }

            let rmsLevel = audioFrame.getVolume()
            let alpha = getMovingAverageAlpha(currentVolume: rmsLevel)
            volume = (1 - alpha) * volume + alpha * rmsLevel

            let normalizedVolume = normalizeVolume(volume)

            /// We want to always scale the volume feedback by at least this factor of the maximum size
            /// This means that the volume feedback will always be visible,
            /// even when the volume is very low.
            let minimumVolumeFactor = 0.2
            let newMicrophoneFillLevel = minimumVolumeFactor + (1 - minimumVolumeFactor) * normalizedVolume

            let currentFillLevel = await microphoneModel.uiState.animatedMicrophoneFillLevel

            if currentFillLevel == newMicrophoneFillLevel { return }

            await microphoneModel.updateAnimatedMicrophoneFillLevel(newMicrophoneFillLevel)
        }

        await model.onStateUpdate { [weak self] state in
            guard let self else { return }
            
            if state == AttendiRecorderState.notStartedRecording {
                volume = 0.0
                await microphoneModel.updateAnimatedMicrophoneFillLevel(volume)
            }
        }
    }

    /// We bias the volume to stay high if it was high recently.
    /// When the volume is high, the alpha is reduced, so that the volume stays high.
    /// This makes the volume feedback a bit smoother as it doesn't  come down as quickly.
    private func getMovingAverageAlpha(currentVolume: Double) -> Double {
        let alpha = 0.7
        let volumeBiasThreshold = 0.7
        let volumeBiasAmount = 0.12

        let normalizedVolume = normalizeVolume(currentVolume)

        let highVolumeBias = normalizedVolume > volumeBiasThreshold ? volumeBiasAmount : 0.0

        return alpha - highVolumeBias
    }

    /// Hand tuned to give good values for the microphone volume, such that the value is 0 when
    /// not talking, and 1 when talking at a normal volume.
    ///
    /// During testing, observed values were around 200 when no speaking occurred, with speaking volume up
    /// to 3000-6000.
    private func normalizeVolume(_ audioLevel: Double) -> Double {
        return pow(min(max((audioLevel - 300) / 2000, 0), 1), 0.25)
    }
}
