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

/// Utility class to represent requests made to Attendi's transcribe APIs.
public class BaseAudioTaskRequest {
    public var httpMethod = "POST"
    public var request: URLRequest
    
    public init(apiKey: String, apiURL: String, route: String) {
        let url = URL(string: "\(apiURL)\(route)")!
        
        self.request = URLRequest(url: url)
        self.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        self.request = setRequestApiKey(request, apiKey: apiKey)
    }
    
    public func setBody(
        wavBase64: String,
        model: String = "DistrictCare",
        reportId: String? = nil,
        sessionId: String? = nil,
        unitId: String, userId: String,
        properties: [String: Any] = [:]
    ) {
        var defaultProps = [
            "audio": wavBase64,
            "config": [
                "model": model,
            ],
            "unitId": unitId,
            "userId": userId
        ] as [String : Any]
        
        if reportId != nil { defaultProps["reportUuid"] = reportId }
        if sessionId != nil { defaultProps["sessionUuid"] = sessionId }
        
        self.request.httpBody = try? JSONSerialization.data(withJSONObject: defaultProps.merging(properties) { (_, new) in new })
    }
    
    public func send() async -> Result<Data, Error> {
        self.request.httpMethod = httpMethod
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return .failure(AttendiMicrophone.Errors.invalidResponse)
            }
            
            return .success(data)
        } catch {
            return .failure(error)
        }
    }
}
