/// Copyright 2023 Attendi Technology B.V.
/// 
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
/// 
///     http://www.apache.org/licenses/LICENSE-2.0
/// 
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.

import Darwin

/// To give extra feedback to the user that the microphone is recording, we display the volume
/// of the audio signal, which fills the inside of the microphone's cone in tandem with the volume level.
public class VolumeFeedbackPlugin: AttendiMicrophonePlugin {
    private var volume: Double = 0
    
    var clearSignalEnergyCallback: (() -> Void)? = nil
    
    public override func activate(_ mic: AttendiMicrophone) {
        Task { @MainActor in
            clearSignalEnergyCallback = mic.recorder.onSignalEnergy { energy in
                let alpha = getMovingAverageAlpha(currentVolume: energy)
                self.volume = (1 - alpha) * self.volume + alpha * energy
                
                let normalizedVolume = pow(normalizeVolume(self.volume), 0.25)
                
                // We want to always scale the volume feedback by at least this factor of the maximum size
                // This means that the volume feedback will always be visible,
                // even when the volume is very low.
                let minimumVolumeFactor = 0.2
                let newMicrophoneFillLevel =
                minimumVolumeFactor + (1 - minimumVolumeFactor) * normalizedVolume;
                
                let currentFillLevel = mic.animatedMicrophoneFillLevel
                
                if (currentFillLevel == newMicrophoneFillLevel) { return }
                
                mic.animatedMicrophoneFillLevel = newMicrophoneFillLevel;
            }
        }
    }
    
    public override func deactivate(_ mic: AttendiMicrophone) {
        if let callback = clearSignalEnergyCallback {
            callback()
        }
        clearSignalEnergyCallback = nil
    }
}

/// We bias the volume to stay high if it was high recently.
/// When the volume is high, the alpha is reduced, so that the volume stays high.
/// This makes the volume feedback a bit smoother as it doesn't  come down as quickly.
func getMovingAverageAlpha(currentVolume: Double) -> Double {
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
func normalizeVolume(_ audioLevel: Double) -> Double {
    return min(max((audioLevel - 300) / 2000, 0), 1)
}
