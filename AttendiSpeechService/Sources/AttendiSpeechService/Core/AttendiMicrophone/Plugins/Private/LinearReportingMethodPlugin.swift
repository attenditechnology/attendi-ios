/// Copyright 2023 Attendi Technology B.V.
///
/// Licensed according to LICENSE.txt in this folder.

import SwiftUI

/// Healthcare professionals use certain reporting methods to give their medical reports more structure.
/// This plugin adds functionality for reporting using reporting methods that can be divided into clear steps
/// such as SOAP and SOEP.
final public class LinearReportingMethodPlugin: AttendiMicrophonePlugin {
    let apiConfig: TranscribeAPIConfig
    
    public init(apiConfig: TranscribeAPIConfig) {
        self.apiConfig = apiConfig
    }
    
    public override func activate(_ mic: AttendiMicrophone) {
        mic.addMenuGroup(
            MenuGroup(
                id: "reporting-methods",
                title: NSLocalizedString("attendiSpeechService.optionsMenu.groups.reportingMethods.title", bundle: .module, comment: ""),
                icon: Image("menu", bundle: .module),
                priority: 1
            )
        )
        
        mic.addMenuItem(
            MenuItem(
                group: "reporting-methods",
                title: "SOAP",
                action: .reportingMethod(steps: soapSteps, apiConfig: apiConfig, onComplete: { report in
                    await MainActor.run { [report] in
                        mic.onResult(report)
                    }
                })
            )
        )
        
        mic.addMenuItem(
            MenuItem(
                group: "reporting-methods",
                title: "SOEP",
                action: .reportingMethod(steps: soepSteps, apiConfig: apiConfig, onComplete: { report in
                    await MainActor.run { [report] in
                        mic.onResult(report)
                    }
                })
            )
        )
    }
}

let soepSteps = [
    ReportingMethodStep(
        title: NSLocalizedString("attendiSpeechService.SOEP.s.title", bundle: .module, comment: ""),
        symbol: NSLocalizedString("attendiSpeechService.SOEP.s.symbol", bundle: .module, comment: ""),
        prompt: NSLocalizedString("attendiSpeechService.SOEP.s.prompt", bundle: .module, comment: "")
    ),
    ReportingMethodStep(
        title: NSLocalizedString("attendiSpeechService.SOEP.o.title", bundle: .module, comment: ""),
        symbol: NSLocalizedString("attendiSpeechService.SOEP.o.symbol", bundle: .module, comment: ""),
        prompt: NSLocalizedString("attendiSpeechService.SOEP.o.prompt", bundle: .module, comment: "")
    ),
    ReportingMethodStep(
        title: NSLocalizedString("attendiSpeechService.SOEP.e.title", bundle: .module, comment: ""),
        symbol: NSLocalizedString("attendiSpeechService.SOEP.e.symbol", bundle: .module, comment: ""),
        prompt: NSLocalizedString("attendiSpeechService.SOEP.e.prompt", bundle: .module, comment: "")
    ),
    ReportingMethodStep(
        title: NSLocalizedString("attendiSpeechService.SOEP.p.title", bundle: .module, comment: ""),
        symbol: NSLocalizedString("attendiSpeechService.SOEP.p.symbol", bundle: .module, comment: ""),
        prompt: NSLocalizedString("attendiSpeechService.SOEP.p.prompt", bundle: .module, comment: "")
    )
]

let soapSteps = [
    ReportingMethodStep(
        title: NSLocalizedString("attendiSpeechService.SOAP.s.title", bundle: .module, comment: ""),
        symbol: NSLocalizedString("attendiSpeechService.SOAP.s.symbol", bundle: .module, comment: ""),
        prompt: NSLocalizedString("attendiSpeechService.SOAP.s.prompt", bundle: .module, comment: "")
    ),
    ReportingMethodStep(
        title: NSLocalizedString("attendiSpeechService.SOAP.o.title", bundle: .module, comment: ""),
        symbol: NSLocalizedString("attendiSpeechService.SOAP.o.symbol", bundle: .module, comment: ""),
        prompt: NSLocalizedString("attendiSpeechService.SOAP.o.prompt", bundle: .module, comment: "")
    ),
    ReportingMethodStep(
        title: NSLocalizedString("attendiSpeechService.SOAP.a.title", bundle: .module, comment: ""),
        symbol: NSLocalizedString("attendiSpeechService.SOAP.a.symbol", bundle: .module, comment: ""),
        prompt: NSLocalizedString("attendiSpeechService.SOAP.a.prompt", bundle: .module, comment: "")
    ),
    ReportingMethodStep(
        title: NSLocalizedString("attendiSpeechService.SOAP.p.title", bundle: .module, comment: ""),
        symbol: NSLocalizedString("attendiSpeechService.SOAP.p.symbol", bundle: .module, comment: ""),
        prompt: NSLocalizedString("attendiSpeechService.SOAP.p.prompt", bundle: .module, comment: "")
    )
]
