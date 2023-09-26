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

import SwiftUI

/// Adds basic error handling functionality by using the microphone's
/// ``AttendiMicrophone/Callbacks-swift.class/onError(_:)`` API.
///
/// Currently does the following when an error occurs:
/// - vibrate the device
/// - show a tooltip with an error message next to the microphone
public class AttendiErrorPlugin: AttendiMicrophonePlugin {
    public override func activate(_ mic: AttendiMicrophone) {
        Task { @MainActor in
            mic.callbacks.onError { error in
                mic.audioPlayer.playSound(sound: "error_notification")
                
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                
                let tooltipMessage: String
                switch error {
                case .general(message: let message):
                    tooltipMessage = message
                default:
                    tooltipMessage = NSLocalizedString("attendiSpeechService.errors.\(error)", bundle: .module, comment: "")
                }
                
                mic.showTooltip(tooltipMessage)
            }
        }
    }
}
