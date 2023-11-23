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

enum Screen {
    case twoMicrophones
    case hoveringMicrophone
}

struct ContentView: View {
    @State private var screen: Screen = .hoveringMicrophone
    
    var body: some View {
        VStack {
           if screen == .twoMicrophones {
               TwoMicrophonesScreen()
           } else {
               HoveringMicrophoneScreen()
           }

           Button(action: {
               screen = (screen == .twoMicrophones) ? .hoveringMicrophone : .twoMicrophones
           }) {
               Text(screen == .twoMicrophones ? "Vul SOAP in" : "Ga terug")
           }
           .padding(.horizontal, 16)
           .padding(.bottom, 10)
        }
    }
}

let apiConfig = TranscribeAPIConfig(
    apiURL: "https://sandbox.api.attendi.nl",
    customerKey: "ck_<key>",
    userId: "userId",
    unitId: "unitId",
    modelType: .districtCare
)

let pinkColor = Color(.sRGB, red: 249/255, green: 43/255, blue: 131/255)
let greyColor = Color(.sRGB, red: 206/255, green: 206/255, blue: 206/255)

struct TwoMicrophonesScreen: View {
    @State private var text: String = ""
    @State private var largeText: String = ""
    
    var body: some View {
        ZStack {
            // Dismiss keyboard when tapping somewhere on the screen outside a text field
            VStack {}
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color(red: 255, green: 255, blue: 255))
                .onTapGesture {
                    dismissKeyboard()
                }
            
            VStack(spacing: 16) {
                // MARK: Small text field
                HStack {
                    TextField("", text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(Color.black)
                        .padding(.horizontal)
                        .frame(height: 36)
                    
                    AttendiMicrophone(
                        size: 56,
                        colors: AttendiMicrophone.Colors(baseColor: pinkColor),
                        plugins: [
                            AttendiErrorPlugin(),
                            AttendiTranscribePlugin(apiConfig: apiConfig),
                        ]
                    ) { newText in
                        text = newText
                    }
                }
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(greyColor)
                )
                
                // MARK: Large text field
                VStack {
                    TextEditor(text: $largeText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(Color.black)
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    HStack {
                        AttendiMicrophone(
                            size: 56,
                            colors: AttendiMicrophone.Colors(baseColor: pinkColor),
                            plugins: [
                                AttendiErrorPlugin(),
                                AttendiTranscribePlugin(apiConfig: apiConfig),
                            ]
                        ) { text in
                            largeText = text
                        }
                        .padding(8)
                        
                        Spacer()
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(greyColor)
                )
            }
            .padding(16)
        }
    }
}

// Add `if` view extension to conditionally apply a modifier to a view
extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}

struct HoveringMicrophoneScreen: View {
    @State private var text1: String = ""
    @State private var text2: String = ""
    @State private var text3: String = ""
    @State private var text4: String = ""
    @State private var focusedTextField: Int = 0
    
    @State var microphoneUIState: AttendiMicrophone.UIState? = nil
    
    func shouldDisplayMicrophoneTarget(textField: Int, targetTextField: Int) -> Bool {
        return ((microphoneUIState == .recording || microphoneUIState == .processingRecording)
                && targetTextField == textField)
    }

    var body: some View {
        let targetTextField = focusedTextField == 0 ? 1 : focusedTextField
        
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("SOAP rapportage")
                    
                    Text("S:")
                    CustomTextField(text: $text1, focusedField: $focusedTextField, tag: 1)
                        .if(shouldDisplayMicrophoneTarget(textField: 1, targetTextField: targetTextField)) { view in
                            view.border(Color.red)
                        }
                    if (shouldDisplayMicrophoneTarget(textField: 1, targetTextField: targetTextField)) {
                        Text("Aan het opnemen...")
                            .font(.footnote)
                    }
                    
                    Text("O:")
                    CustomTextField(text: $text2, focusedField: $focusedTextField, tag: 2)
                        .if(shouldDisplayMicrophoneTarget(textField: 2, targetTextField: targetTextField)) { view in
                            view.border(Color.red)
                        }
                    Text("A:")
                    CustomTextField(text: $text3, focusedField: $focusedTextField, tag: 3)
                        .if(shouldDisplayMicrophoneTarget(textField: 3, targetTextField: targetTextField)) { view in
                            view.border(Color.red)
                        }
                    Text("P:")
                    CustomTextField(text: $text4, focusedField: $focusedTextField, tag: 4)
                        .if(shouldDisplayMicrophoneTarget(textField: 4, targetTextField: targetTextField)) { view in
                            view.border(Color.red)
                        }
                }
                .padding(16)
                .frame(maxHeight: .infinity)
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    AttendiMicrophone(
                        size: 64,
                        colors: AttendiMicrophone.Colors(
                            inactiveBackgroundColor: pinkColor,
                            inactiveForegroundColor: Color.white,
                            activeBackgroundColor: pinkColor,
                            activeForegroundColor: Color.white
                        ),
                        plugins: [
                            AttendiErrorPlugin(),
                            AttendiHandleBackgroundingPlugin(),
                            AttendiTranscribePlugin(apiConfig: apiConfig),
                        ]
                    ) { text in
                        switch focusedTextField {
                            case 1:
                                text1 = text
                            case 2:
                                text2 = text
                            case 3:
                                text3 = text
                            case 4:
                                text4 = text
                            default:
                                text1 = text
                        }
                    } onAppear: { mic in
                        mic.callbacks.onUIState { uiState in
                            self.microphoneUIState = uiState
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
    
    struct CustomTextField: View {
        @Binding var text: String
        @Binding var focusedField: Int
        let tag: Int
        
        var body: some View {
            TextField("", text: $text, onEditingChanged: { isEditing in
                if isEditing {
                    self.focusedField = self.tag
                }
            })
            .textFieldStyle(PlainTextFieldStyle())
            .foregroundColor(Color.black)
            .padding(8)
            .frame(maxWidth: .infinity)
            .frame(height: 100, alignment: .top)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(greyColor)
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension View {
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
