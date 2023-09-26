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
import AttendiSpeechService

class ExamplePlugin: AttendiMicrophonePlugin {
    
    override func menuItems() -> [MenuItem]? {
        return [
            MenuItem(
                group: "test",
                title: "Example",
                action: .navigation(destination: AnyView(
                    Text("Hi, this is a new page")
                ))
            )
        ]
    }
}
