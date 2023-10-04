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

public typealias VoidCallback = () async -> Void

extension AttendiMicrophone {
    /// Utility class that gathers all the ``AttendiMicrophone`` callback plugin APIs. The callback plugin APIs
    /// allow clients to execute logic at various parts of the component's lifecycle.
    /// See e.g ``Callbacks-swift.class/onStartRecording(_:)``.
    public class Callbacks {
        var firstClickCallbacks: [String: VoidCallback] = [:]
        var beforeStartRecordingCallbacks: [String: VoidCallback] = [:]
        var startRecordingCallbacks: [String: VoidCallback] = [:]
        var beforeStopRecordingCallbacks: [String: VoidCallback] = [:]
        var stopRecordingCallbacks: [String: VoidCallback] = [:]
        var UIStateCallbacks: [String: (AttendiMicrophone.UIState) async -> Void] = [:]
        var errorCallbacks: [String: (AttendiMicrophone.Errors) async -> Void] = [:]
        var volumeCallbacks: [String: (Double) async -> Void] = [:]
        
        /// [PLUGIN API]
        /// Register a callback that will be called when the button is clicked for the first time.
        ///
        /// - Returns: A function that can be used to remove the added callback.
        @discardableResult
        public func onFirstClick(_ callback: @escaping VoidCallback) -> () -> Void {
            let id = UUID().uuidString
            firstClickCallbacks[id] = callback
            return { [weak self] in
                self?.firstClickCallbacks[id] = nil
            }
        }
        
        /// [PLUGIN API]
        /// Register a callback that will be called before recording of audio starts.
        ///
        /// - Returns: A function that can be used to remove the added callback.
        @discardableResult
        public func onBeforeStartRecording(_ callback: @escaping VoidCallback) -> () -> Void {
            let id = UUID().uuidString
            beforeStartRecordingCallbacks[id] = callback
            return { [weak self] in
                self?.beforeStartRecordingCallbacks[id] = nil
            }
        }
        
        /// [PLUGIN API]
        /// Register a callback that will be called just after recording of audio starts.
        ///
        /// - Returns: A function that can be used to remove the added callback.
        @discardableResult
        public func onStartRecording(_ callback: @escaping VoidCallback) -> () -> Void {
            let id = UUID().uuidString
            startRecordingCallbacks[id] = callback
            return { [weak self] in
                self?.startRecordingCallbacks[id] = nil
            }
        }
        
        /// [PLUGIN API]
        /// Register a callback that will be called just before recording of audio stops.
        ///
        /// - Returns: A function that can be used to remove the added callback.
        @discardableResult
        public func onBeforeStopRecording(_ callback: @escaping VoidCallback) -> () -> Void {
            let id = UUID().uuidString
            beforeStopRecordingCallbacks[id] = callback
            return { [weak self] in
                self?.beforeStopRecordingCallbacks[id] = nil
            }
        }
        
        /// [PLUGIN API]
        /// Register a callback that will be called after recording of audio stops.
        ///
        /// - Returns: A function that can be used to remove the added callback.
        @discardableResult
        public func onStopRecording(_ callback: @escaping VoidCallback) -> () -> Void {
            let id = UUID().uuidString
            stopRecordingCallbacks[id] = callback
            return { [weak self] in
                self?.stopRecordingCallbacks[id] = nil
            }
        }
        
        /// [PLUGIN API]
        /// Register a callback that will be called when the ``AttendiMicrophone/UIState-swift.enum`` changes. The
        /// new state is passed to the callback.
        ///
        /// - Returns: A function that can be used to remove the added callback.
        @discardableResult
        public func onUIState(_ callback: @escaping (AttendiMicrophone.UIState) async -> Void) -> () -> Void {
            let id = UUID().uuidString
            UIStateCallbacks[id] = callback
            return { [weak self] in
                self?.UIStateCallbacks[id] = nil
            }
        }
        
        /// [PLUGIN API]
        /// Register a callback that will be called when an error occurs. The error is passed to the callback.
        ///
        /// - Returns: A function that can be used to remove the added callback.
        @discardableResult
        public func onError(_ callback: @escaping ((AttendiMicrophone.Errors) async -> Void)) -> () -> Void {
            let id = UUID().uuidString
            errorCallbacks[id] = callback
            return { [weak self] in
                self?.errorCallbacks[id] = nil
            }
        }
        
        /// [PLUGIN API]
        /// Register a callback that will be called when the audio volume is updated. The new volume is passed to the callback.
        ///
        /// - Returns: A function that can be used to remove the added callback.
        @discardableResult
        public func onVolume(_ callback: @escaping (Double) async -> Void) -> () -> Void {
            let id = UUID().uuidString
            volumeCallbacks[id] = callback
            return { [weak self] in
                self?.volumeCallbacks[id] = nil
            }
        }
    }
}
