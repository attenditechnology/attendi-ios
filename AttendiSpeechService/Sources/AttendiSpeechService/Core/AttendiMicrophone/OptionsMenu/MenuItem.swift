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

public struct MenuGroup: Identifiable, Equatable {
    public var id: String
    public var title: String
    public var icon: Image? = nil
    public var priority: Int = 10
    
    public init(id: String, title: String, icon: Image? = nil, priority: Int = 10) {
        self.id = id
        self.title = title
        self.icon = icon
        self.priority = priority
    }
    
    public static func ==(lhs: MenuGroup, rhs: MenuGroup) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct MenuItem: Identifiable, Equatable {
    public var group: String
    public let id = UUID()
    public var title: String
    public var subtitle: String? = nil
    public var icon: Image? = nil

    public var action: MenuItemAction

    public init(group: String, title: String, subtitle: String? = nil, icon: Image? = nil, action: MenuItemAction) {
        self.group = group
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.action = action
    }

    public static func ==(lhs: MenuItem, rhs: MenuItem) -> Bool {
        return lhs.id == rhs.id
    }
}

public enum MenuItemAction {
    case reportingMethod(steps: [ReportingMethodStep], apiConfig: TranscribeAPIConfig, onComplete: (String) async -> Void)
    case navigation(destination: AnyView)
    case button(action: () -> Void)
}

public struct ReportingMethodStep {
    var title: String
    var symbol: String
    var prompt: String
}
