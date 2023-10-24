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
import AVFoundation

/// Play sounds at certain points of the microphone component's lifecycle to give more feedback
/// to the user. Specifically, play a start sound when the UI state is set to ``AttendiMicrophone/UIState-swift.enum/recording``
/// and play a stop sound just before recording is stopped.
public class AudioNotificationPlugin: AttendiMicrophonePlugin {
    public override func activate(_ mic: AttendiMicrophone) {
        if (mic.silent) { return }
        
        Task { @MainActor in
            mic.callbacks.onBeforeStartRecording {
                let t1 = Date()
                
                let audioPlayer = mic.audioPlayer
                
                await withUnsafeContinuation { continuation in
                    Task {
                        var finishedPlaying: Bool = false
                        
                        audioPlayer.playSound(sound: "start_notification") {
                            finishedPlaying = true
                        }
                        
                        while !finishedPlaying {
                            if Date().timeIntervalSince(t1) >= 2 {
                                break
                            }
                            try? await Task.sleep(nanoseconds: 100_000_000)
                        }
                        
                        continuation.resume()
                    }
                }
                
                // `timeIntervalSince` returns seconds
                let playAudioDurationMilliseconds = Date().timeIntervalSince(t1) * 1000
                
                // Since playing the notification audio takes some time, we shorten the
                // delay before showing the recording screen by the same amount of time. Otherwise the
                // user would wait longer than necessary before seeing the recording UI.
                mic.shortenShowRecordingDelayByMilliseconds = Int(playAudioDurationMilliseconds)
            }
            
            // We do it here and not on start recording since the recording might already be started
            // before we signal to the user that that is the case. We only want them to start speaking
            // when they think we are recording, so that they don't start speaking too early.
            mic.callbacks.onUIState { uiState in
                if uiState == .recording {
                    // Reset the delay to 0, just to clean up after ourselves.
                    mic.shortenShowRecordingDelayByMilliseconds = 0
                }
            }
            
            mic.callbacks.onStopRecording {
                mic.audioPlayer.playSound(sound: "stop_notification")
            }
        }
    }
}
