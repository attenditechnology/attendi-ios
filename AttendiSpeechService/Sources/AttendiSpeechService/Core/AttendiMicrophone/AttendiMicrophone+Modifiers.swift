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

// View Modifiers
extension AttendiMicrophone {
    @discardableResult
    public func variant(_ variant: AttendiMicrophone.Variant) -> AttendiMicrophone {
        let component = self
        
        component.settings.variant = variant
        return component
    }
    
    @discardableResult
    public func showOptions(_ variant: AttendiMicrophone.OptionsVariant = .normal) -> AttendiMicrophone {
        let component = self
        
        component.settings.showOptions = variant
        return component
    }
    
    @discardableResult
    public func setIcon(_ uiState: AttendiMicrophone.UIState, view: AnyView) -> AttendiMicrophone {
        let component = self
        
        component.settings.customUIIcons[uiState.rawValue] = view
        return component
    }
    
    @discardableResult
    public func setOptionsIcon(_ view: AnyView?) -> AttendiMicrophone {
        let component = self
        
        component.settings.customUIIcons["options"] = view
        return component
    }
}
