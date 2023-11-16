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


let startNotificationSoundTimeoutSeconds: Double = 2

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
                
                await self.playStartNotificationAudioWithTimeout(audioPlayer, t1)
                
                // `timeIntervalSince` returns seconds
                let playAudioDurationMilliseconds = Date().timeIntervalSince(t1) * 1000
                
                // Since playing the notification audio takes some time, we shorten the
                // delay before showing the recording screen by the same amount of time. Otherwise the
                // user would wait longer than necessary before seeing the recording UI.
                mic.shortenShowRecordingDelayByMilliseconds += Int(playAudioDurationMilliseconds)
            }
            
            mic.callbacks.onStopRecording {
                mic.audioPlayer.playSound(sound: "stop_notification")
            }
        }
    }
    
    func playStartNotificationAudioWithTimeout(_ audioPlayer: AttendiAudioPlayerDelegate, _ t1: Date) async {
        // Since we have no guarantee that `onAudioPlayerDidFinishPlaying` will be called after calling
        // `playSound`, we can't simply call `continuation.resume` in the `onAudioPlayerDidFinishPlaying`
        // callback, as it might never be called. Therefore we currently poll the status of a `finishedPlaying`
        // boolean every so often, and wait for a maximum of `startNotificationSoundTimeoutSeconds` seconds
        // before resuming.
        await withCheckedContinuation { continuation in
            Task {
                var finishedPlaying: Bool = false
                
                audioPlayer.playSound(sound: "start_notification", onAudioPlayerDidFinishPlaying: {
                    finishedPlaying = true
                })
                
                while !finishedPlaying && Date().timeIntervalSince(t1) < startNotificationSoundTimeoutSeconds {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                
                continuation.resume()
            }
        }
    }
}
