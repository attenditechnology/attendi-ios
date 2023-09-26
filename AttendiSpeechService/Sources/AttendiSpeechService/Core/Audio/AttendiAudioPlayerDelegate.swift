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

import Foundation
import AVFoundation

/// Utility class to play audio and make sure the audio session is properly set and reset after playing the audio.
public class AttendiAudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    var audioPlayer: AVAudioPlayer?
    
    var oldCategory: AVAudioSession.Category = .soloAmbient
    
    var deactivateSessionAfterPlay = false
    
    func playSound(sound: String, deactivateSessionAfterPlay: Bool = false) {
        guard let soundFileURL = Bundle.module.url(forResource: sound, withExtension: "mp3") else {
            print("File not found")
            return
        }
        
        let session = AVAudioSession.sharedInstance()
        
        oldCategory = session.category
        
        // We don't need to set the category if we can already playback
        if oldCategory != .playAndRecord && oldCategory != .playback {
            do {
                try session.setCategory(.playback, options: .defaultToSpeaker)
            } catch {
                print("Setting audio session category to `playAndRecord` failed.")
            }
        }
        
        do {
            try session.setActive(true)
        } catch {
            print("Setting active to true failed.")
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundFileURL)
            audioPlayer?.volume = 1
            audioPlayer?.delegate = self
            audioPlayer?.play()
            
            // We set it like this because we don't call `audioPlayerDidFinishPlaying` directly
            self.deactivateSessionAfterPlay = deactivateSessionAfterPlay
        } catch {
            print("Audio player failed.")
        }
    }
    
    // Properly reset the audio session after we're done playing.
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        do {
            if (deactivateSessionAfterPlay) {
                try AVAudioSession.sharedInstance().setActive(false)
            }
            try AVAudioSession.sharedInstance().setCategory(oldCategory)
        } catch {
            print("Restoring previous audio session state failed.")
        }
    }
}

