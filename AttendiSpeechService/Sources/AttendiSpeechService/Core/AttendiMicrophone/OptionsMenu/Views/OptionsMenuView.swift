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

struct OptionsMenuView: View {
    @Binding var isOpen: Bool

    let menuGroups: [MenuGroup]
    let menuItems: [String: [MenuItem]]

    var body: some View {
        ZStack {}
            .sheet(isPresented: $isOpen) {
                NavigationView {
                    List {
                        ForEach(menuGroups) { group in
                            Section(header: OptionsMenuHeader(icon: group.icon, title: group.title)) {
                                ForEach (menuItems[group.id] ?? []) { item in
                                    OptionsMenuItemView(item: item)
                                }
                            }
                        }
                    }
                    .toolbar {
                        Button(action: {
                            self.isOpen.toggle()
                        }) {
                            CloseIcon()
                        }
                    }
                }
                .environment(\.optionsMenuAppearance, self.$isOpen)
            }
    }
}

struct OptionsMenuView_Previews: PreviewProvider {
    @State static var isOpen = true
    static var previews: some View {
        OptionsMenuView(isOpen: $isOpen, menuGroups: [], menuItems: [:])
    }
}

struct OptionsMenuAppearanceKey: EnvironmentKey {
    static let defaultValue = Binding<Bool>.constant(false)
}

extension EnvironmentValues {
    var optionsMenuAppearance: Binding<Bool> {
        get {
            return self[OptionsMenuAppearanceKey.self]
        }
        set {
            self[OptionsMenuAppearanceKey.self] = newValue
        }
    }
}
