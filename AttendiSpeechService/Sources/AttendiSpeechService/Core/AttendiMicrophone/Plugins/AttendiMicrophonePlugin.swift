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

/// Plugins for the ``AttendiMicrophone`` component inherit from this class. Plugins add functionality
/// to the microphone component by using its plugin APIs. The functionality of any plugin is implemented in
/// its ``activate(_:)`` function. This function is called when the microphone is first initialized, and takes
/// as input a reference to the corresponding microphone component. Any logic that needs to run when the
/// microphone is removed from the view should be implemented in the ``deactivate(_:)`` function.
/// This might for instance be necessary when the plugin changes some global state.
///
/// An implementation of a plugin might look like the following:
///
///     public class MyPlugin: AttendiMicrophonePlugin {
///         public override func activate(_ mic: AttendiMicrophone) {
///             // Add a callback that is called when the microphone starts recording.
///             mic.callbacks.onStartRecording {
///                 print("Recording started")
///             }
///         }
///     }
///
/// Refer to the ``AttendiMicrophone`` documentation for all its plugin APIs.
open class AttendiMicrophonePlugin: Equatable {
    // Make initializer public so code outside the module can instantiate plugins.
    public init() {}

    /// This function is called when the microphone is first initialized, and takes as input a reference to the
    /// corresponding microphone component. The plugin's functionality is implemented in this function.
    ///
    /// - Parameter mic: Instance of the microphone whose functionality should be extended. The
    /// microphone exposes plugin APIs such as ``AttendiMicrophone/Callbacks-swift.class/onStartRecording(_:)``
    /// that allow its behavior to be extended at runtime.
    @MainActor open func activate(_ mic: AttendiMicrophone) { }

    /// This function is called when the microphone component disappears. Any logic that needs to run when the
    /// microphone is removed from the view should be implemented here.
    /// This might for instance be necessary when the plugin changes some global state.
    ///
    /// - Parameter mic: same as ``activate(_:)``'s `mic` parameter.
    @MainActor open func deactivate(_ mic: AttendiMicrophone) { }
    
    public static func == (lhs: AttendiMicrophonePlugin, rhs: AttendiMicrophonePlugin) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
