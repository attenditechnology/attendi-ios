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

struct CloseIcon: View {
    var backgroundColor = Color(.secondarySystemFill)
    var foregroundColor = Color.secondary
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 30, height: 30)
                .foregroundColor(backgroundColor)
            Image(systemName: "xmark")
                .font(Font.body.weight(.bold))
                .foregroundColor(foregroundColor)
                .imageScale(.small)
                .frame(width: 44, height: 44)
        }
    }
}

struct CloseIcon_Previews: PreviewProvider {
    static var previews: some View {
        CloseIcon()
    }
}
