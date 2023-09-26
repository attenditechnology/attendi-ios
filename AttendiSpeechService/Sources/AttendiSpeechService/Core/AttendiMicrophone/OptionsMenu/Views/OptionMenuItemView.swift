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

struct OptionsMenuItemView: View {
    @Environment (\.optionsMenuAppearance) var optionsMenuAppearance
    var item: MenuItem
    
    var content: some View {
        HStack {
            if item.icon != nil {
                item.icon!
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .frame(width: 32, height: 32)
                    .padding(.trailing, 10)
            }
            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.body)
                    .foregroundColor(.black)
                if !(item.subtitle?.isEmpty ?? true) {
                    Text(item.subtitle!)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.top, 5)
        .padding(.bottom, 5)

    }
    
    // TODO: refactor so that `OptionsMenuItemView` has no knowledge of specific plugins such as `reportingMethod`
    var body: some View {
        switch item.action {
        case let .reportingMethod(steps, apiConfig, onComplete):
            ZStack(alignment: .leading) {
                NavigationLink(destination: ReportingMethodView(steps: steps, apiConfig: apiConfig, onComplete: onComplete)) {
                    EmptyView()
                }.opacity(0.0)
                content
            }
        case let .navigation(destination):
            ZStack(alignment: .leading) {
                NavigationLink(
                    destination: destination.navigationBarBackButtonHidden(true)
                ) {
                    EmptyView()
                }.opacity(0.0)
                content
            }
        case let .button(action):
            Button(action: {
                optionsMenuAppearance.wrappedValue = false
                action()
            }) {
                content
            }
        }
    }
}

struct OptionsMenuItemView_Previews: PreviewProvider {
    static var previews: some View {
        OptionsMenuItemView(item: MenuItem(group: "ReportingMethods", title: "Schrijf mijn rapportage", subtitle: "Vertel wat moet worden verwerkt tot rapportage", icon: Image("assistantWriteMyReport", bundle: .module), action: .button(action: { print("Active") })))
    }
}
