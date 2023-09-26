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

struct ReportingStepView: View {
    @EnvironmentObject var settings: AttendiMicrophone.Settings
    @Environment(\.colorScheme) var colorScheme

    var step: String
    var index: Int
    var hasValue: Bool
    @Binding var activeIndex: Int

    var body: some View {
        Text(step)
            .font(.title)
            .frame(width: 60, height: 60)
            .background(hasValue ? settings.color.opacity(0.1) : .clear)
            .cornerRadius(100)
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .overlay(
                Circle()
                    .stroke(activeIndex == index ? settings.color : Color(.systemGray3), lineWidth: 2)
            )
    }
}

struct ReportingStepView_Previews: PreviewProvider {
    @State static var activeIndex = 0
    static var previews: some View {
        ReportingStepView(step: "S", index: 0, hasValue: false, activeIndex: $activeIndex)
            .environmentObject(AttendiMicrophone.Settings())
    }
}
