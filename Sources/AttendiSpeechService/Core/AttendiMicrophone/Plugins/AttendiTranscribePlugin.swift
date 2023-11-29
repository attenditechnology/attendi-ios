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

/// Send recorded audio to Attendi's backend transcription API. Signal the result to the client
/// when a response is received.
///
/// Registers an audio task called `attendi-transcribe` and sets it as the active audio task.
public class AttendiTranscribePlugin: AttendiMicrophonePlugin {
    let apiConfig: TranscribeAPIConfig
    let client: AttendiClient
    
    // We need an explicit initializer here to make it public.
    public init(apiConfig: TranscribeAPIConfig) {
        self.apiConfig = apiConfig
        
        let reportId = UUID().uuidString.lowercased()
        let sessionId = UUID().uuidString.lowercased()
        self.client = AttendiClient(reportId: reportId, sessionId: sessionId)
    }
    
    public override func activate(_ mic: AttendiMicrophone) {
        let onEvent = mic.onEvent
        let onResult = mic.onResult
        let errorCallbacks = mic.callbacks.errorCallbacks.values
        
        mic.registerAudioTask(taskId: "attendi-transcribe") { [weak self] wav in
            guard let self = self else { return }
            
            let wavBase64 = wav.base64EncodedString()
            
            let result = await self.client.transcribe(wavBase64, apiConfig: self.apiConfig)
            
            switch result {
            case .success(let transcript):
                onEvent("attendi-transcribe", transcript)
                onResult(transcript)
            case .failure(let error):
                for callback in errorCallbacks {
                    await callback(.general(message: "Kon de audio niet opsturen"))
                }
                print("Error: \(error)")
            }
        }
        
        mic.setActiveAudioTask("attendi-transcribe")
    }
    
    public override func deactivate(_ mic: AttendiMicrophone) {
        mic.removeAudioTask(taskToRemoveId: "attendi-transcribe")
    }
}
