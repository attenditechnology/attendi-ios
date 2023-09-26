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

struct ExampleRecordingView: View {
    @Binding var microphoneLevel: CGFloat
    @State var activeListeners: Array<(() -> Void)> = []

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(UIColor.systemGray5))
                .cornerRadius(100)
                .frame(width: 32 * microphoneLevel, height: 32 * microphoneLevel)
                .animation(.linear)
            Image(systemName: "livephoto")
                .foregroundColor(.blue)
        }
        .frame(width: 32, height: 32)
    }
}

struct ExampleRecordingView_Previews: PreviewProvider {
    @State static var volume: CGFloat = 0.5
    static var previews: some View {
        ExampleRecordingView(microphoneLevel: $volume)
    }
}
