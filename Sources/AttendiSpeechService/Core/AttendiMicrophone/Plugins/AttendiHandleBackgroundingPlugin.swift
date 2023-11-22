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


/// An example plugin that handles a case in which the app is backgrounded while the mic is recording.
/// Currently stops the recording and performs any registered audio tasks when the view disappears.
///
/// When using the microphone in a UIHostingController, somehow it is possible
/// for the view's `onDisappear` and `onAppear` functoins to be called again (after the first time!)
/// when the application is backgrounded and foregrounded again, even when the rest
/// of the state of the view persists.
public class AttendiHandleBackgroundingPlugin: AttendiMicrophonePlugin {
    var clearCallbacks: [() -> Void] = []
    
    public override func activate(_ mic: AttendiMicrophone) {
        Task {
            clearCallbacks.append(
                mic.callbacks.onDisappear {
                    // Stop recording and call the registered audio tasks when `onDisappear`
                    // is called.
                    if (mic.recorder.state == .recording) {
                        await mic.stop(delayMilliseconds: 0)
                    }
                }
            )
        }
    }
    
    public override func deactivate(_ mic: AttendiMicrophone) {
        for callback in clearCallbacks {
            callback()
        }

        clearCallbacks = []
    }
}
