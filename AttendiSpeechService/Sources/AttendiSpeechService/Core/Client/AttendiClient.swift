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

let defaultAttendiBaseURL = "https://api.attendi.nl"

/// This class knows how to communicate with Attendi's backend APIs.
public class AttendiClient {
    var reportId: String?
    var sessionId: String?
    
    public init(reportId: String? = nil, sessionId: String? = nil) {
        self.reportId = reportId
        self.sessionId = sessionId
    }
    
    /// Transcribe a base-64 encoded wav file.
    ///
    /// - Parameter wavBase64: base-64 encoded wav file recorded at a sample rate of 16 KHz, with the audio data being represented
    /// using 16-bit signed integers.
    /// - Parameter apiConfig: Parameters necessary to communicate with Attendi's transcribe API.
    public func transcribe(_ wavBase64: String, apiConfig: TranscribeAPIConfig) async -> Result<String, Error> {
        let request = BaseAudioTaskRequest(
            apiKey: apiConfig.customerKey,
            apiURL: apiConfig.apiURL ?? defaultAttendiBaseURL,
            route: "/v1/speech/transcribe"
        )
        
        request.setBody(
            wavBase64: wavBase64,
            reportId: self.reportId,
            sessionId: self.sessionId,
            unitId: apiConfig.unitId,
            userId: apiConfig.userId
        )
        
        do {
            let result = await request.send()
            
            switch result {
            case .success(let data):
                let responseJSON = try JSONSerialization.jsonObject(with: data, options: [])
                guard let responseDict = responseJSON as? [String: Any], let transcript = responseDict["transcript"] as? String else {
                    return .failure(AttendiMicrophone.Errors.invalidResponse)
                }
                
                return .success(transcript)
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }
    
    /// Used for Attendi's `schrijfhulp` functionality.
    /// See ``transcribe(_:apiConfig:)`` for further details.
    public func generateLanguage(_ wavBase64: String, apiConfig: TranscribeAPIConfig) async -> Result<String, Error> {
        let request = BaseAudioTaskRequest(
            apiKey: apiConfig.customerKey,
            apiURL: apiConfig.apiURL ?? defaultAttendiBaseURL,
            route: "/v1/spoken_language_understanding/generate_language"
        )
        
        request.setBody(
            wavBase64: wavBase64,
            reportId: self.reportId,
            sessionId: self.sessionId,
            unitId: apiConfig.unitId,
            userId: apiConfig.userId
        )
        
        do {
            let result = await request.send()
            
            switch result {
            case .success(let data):
                let responseJSON = try JSONSerialization.jsonObject(with: data, options: [])
                guard let responseDict = responseJSON as? [String: Any], let transcript = responseDict["text"] as? String else {
                    return .failure(AttendiMicrophone.Errors.invalidResponse)
                }
                
                return .success(transcript)
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }
}

/// Bundles up the information necessary to communicate with Attendi's speech understanding APIs.
public struct TranscribeAPIConfig {
    public init(apiURL: String? = nil, customerKey: String, userId: String, unitId: String, userAgent: String? = nil, modelType: ModelType) {
        self.apiURL = apiURL
        self.customerKey = customerKey
        self.userId = userId
        self.unitId = unitId
        self.userAgent = userAgent
        self.modelType = modelType
    }
    
    /**
     * URL of the Attendi Speech Service API, e.g. `https://api.attendi.nl` or
     * `https://sandbox.api.attendi.nl`.
     */
    public let apiURL: String?
    
    /**
     * Your customer API key.
     */
    public let customerKey: String
    
    /**
     * Unique id assigned (by you) to your user
     */
    public let userId: String
    
    /**
     * Unique id assigned (by you) to the team or location of your user.
     */
    public let unitId: String
    
    /**
     * User agent string identifying the user device, OS and browser.
     */
    public let userAgent: String?
    
    /**
     * Which model to use, e.g. ModelType.ResidentialCare or "ResidentialCare".
     */
    public let modelType: ModelType
}

/// Attendi serves multiple speech-to-text models. These are the types of models available.
public enum ModelType: String {
    case residentialCare, districtCare
}
