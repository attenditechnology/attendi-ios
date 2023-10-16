/// Copyright 2023 Attendi Technology B.V.
///
/// Licensed according to LICENSE.txt in this folder.

import SwiftUI

/// Add functionality relating to Attendi's `schrijfhulp`, which communicates with Attendi's spoken
/// language understanding APIs.
final public class AttendiAssistantPlugin: AttendiMicrophonePlugin {
    let defaultAssistantColor = Color(hex: "#9747FF")
    
    var previousColor = AttendiMicrophone.Colors(baseColor: Color(hex: "#1C69E8"))
    var previousOptionsIcon: AnyView? = nil
    var previousShowOptions: AttendiMicrophone.OptionsVariant = .normal
    
    let apiConfig: TranscribeAPIConfig
    
    let client: AttendiClient
    
    public init(apiConfig: TranscribeAPIConfig) {
        self.apiConfig = apiConfig
        
        let reportId = UUID().uuidString.lowercased()
        let sessionId = UUID().uuidString.lowercased()
        self.client = AttendiClient(reportId: reportId, sessionId: sessionId)
    }
    
    public override func activate(_ mic: AttendiMicrophone) {
        _ = mic.registerAudioTask(taskId: "assistant") { wav in
            let wavBase64 = wav.base64EncodedString()
            let result = await self.client.generateLanguage(wavBase64, apiConfig: self.apiConfig)
            
            switch result {
            case .success(let transcript):
                mic.onResult(transcript)
                self.goBackToNormalState(mic)
            case .failure(let error):
                await mic.triggerError(.general(message: "Kon de audio niet opsturen"))
                print("Error: \(error)")
            }
        }
        
        mic.addMenuGroup(
            MenuGroup(
                id: "assistant",
                title: NSLocalizedString("attendiSpeechService.optionsMenu.groups.assistant.title", bundle: .module, comment: ""),
                icon: Image("stars", bundle: .module),
                priority: 2
            )
        )
        
        mic.addMenuItem(
            MenuItem(
                group: "assistant",
                title: NSLocalizedString("attendiSpeechService.optionsMenu.items.assistant.writeMyReport.title", bundle: .module, comment: ""),
                subtitle: NSLocalizedString("attendiSpeechService.optionsMenu.items.assistant.writeMyReport.subtitle", bundle: .module, comment: ""),
                icon: Image("assistantWriteMyReport", bundle: .module),
                action: .button(action: {
                    Task { @MainActor in
                        self.previousColor = mic.settings.colors
                        self.previousOptionsIcon = mic.settings.customUIIcons["options"]
                        self.previousShowOptions = mic.settings.showOptions
                        
                        let color = self.defaultAssistantColor
                        
                        mic.settings.showOptions = .always
                        
                        mic.settings.colors = AttendiMicrophone.Colors(baseColor: color)
                        
                        mic.setOptionsIcon(AnyView(
                            Button(action: {self.goBackToNormalState(mic)} ) {
                                Image("wand", bundle: .module)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                                .overlay(
                                    CloseIcon(backgroundColor: color, foregroundColor: .white)
                                        .frame(width: 12, height: 12)
                                        .scaleEffect(mic.settings.size / ATTENDI_BUTTON_SIZE * 0.4)
                                        .offset(x: 9, y: -9),
                                    alignment: .topTrailing
                                )
                        ))
                        
                        mic.setActiveAudioTask("assistant")
                    }
                })
            )
        )
    }
    
    @MainActor private func goBackToNormalState(_ mic: AttendiMicrophone) {
        mic.goBackInActiveAudioTaskHistory()
        mic.settings.colors = self.previousColor
        mic.setOptionsIcon(self.previousOptionsIcon)
        mic.showOptions(self.previousShowOptions)
    }
}
