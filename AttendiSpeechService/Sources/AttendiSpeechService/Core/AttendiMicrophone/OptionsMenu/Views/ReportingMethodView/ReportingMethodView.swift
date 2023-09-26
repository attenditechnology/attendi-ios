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

struct ReportingMethodView: View {
    @Environment (\.optionsMenuAppearance) var optionsMenuAppearance
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @EnvironmentObject var settings: AttendiMicrophone.Settings

    @State private var orientation = UIDevice.current.orientation

    @State var currentStep: Int = 0
    @State var reportedData: [String] = []
    @State var currentText = ""
    @State var submitting = false
    @State var showCancelAlert = false

    var steps: [ReportingMethodStep]
    var apiConfig: TranscribeAPIConfig
    var onComplete: (String) async -> Void

    var body: some View {
        Group {
            if verticalSizeClass == .compact {
                HStack(alignment: .top) {
                    VStack(spacing: 20) {
                        StepsView
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.trailing, 20)
                    .padding(.leading, orientation == .landscapeLeft ? 10 : 30)

                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            StepDetails
                            Spacer()
                            CloseButton
                        }
                        HStack(alignment: .bottom) {
                            StepEditor
                                .padding(.top, 10)

                            VStack(spacing: 20) {
                                AttendiMicrophone(
                                    microphoneModifier: AttendiMicrophoneModifier(size: 60),
                                    plugins: [
                                        AttendiTranscribePlugin(apiConfig: apiConfig)
                                    ]
                                )
                                .variant(.white)
                                .background(settings.color)
                                .cornerRadius(100)

                                CompleteButton
                                    .padding(20)
                                    .overlay(
                                        Circle().stroke(settings.color, lineWidth: 2)
                                    )
                            }
                            .padding(.leading, 20)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 5)
                }
                .padding(.top, 20)
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
                .ignoresSafeArea(edges: orientation == .landscapeLeft ? [.top] : [.top, .leading])
            } else {
                VStack(alignment: .leading) {
                    HStack {
                        Spacer()
                        CloseButton
                    }
                    .padding(.top, 5)
                    
                    HStack(alignment: .center, spacing: 20) {
                        StepsView
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    StepDetails
                    StepEditor

                    HStack {
                        HStack {}.frame(minWidth: 0, maxWidth: .infinity)

                        Spacer()

                        AttendiMicrophone(
                            microphoneModifier: AttendiMicrophoneModifier(size: 60),
                            plugins: [
                                AttendiTranscribePlugin(apiConfig: apiConfig)
                            ]
                        )
                        // TODO: change 'variant' type
                        .variant(.white)
                        .background(settings.color)
                        .cornerRadius(100)

                        Spacer()

                        CompleteButton
                            .padding(15)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .overlay(
                                Circle().stroke(settings.color, lineWidth: 2)
                            )
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity)
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
            }
        }
        .onRotate { newOrientation in orientation = newOrientation }
        .alert(isPresented: $showCancelAlert) {
            Alert(
                title: Text(NSLocalizedString("attendiSpeechService.reporting.destroy.title", bundle: .module, comment: "")),
                message: Text(NSLocalizedString("attendiSpeechService.reporting.destroy.message", bundle: .module, comment: "")),
                primaryButton: .destructive(Text(NSLocalizedString("attendiSpeechService.reporting.destroy.destroy", bundle: .module, comment: ""))) {
                    self.optionsMenuAppearance.wrappedValue = false
                },
                secondaryButton: .cancel(Text(NSLocalizedString("attendiSpeechService.reporting.destroy.stay", bundle: .module, comment: "")))
            )
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            reportedData = []

            for _ in steps {
                reportedData.append("")
            }
        }
    }
    
    var CloseButton: some View {
        return Button(action: {
            var hasFilledInField = false
            for field in reportedData {
                if !field.isEmpty { hasFilledInField = true; break }
            }
            if hasFilledInField || !currentText.isEmpty {
                self.showCancelAlert = true
                return
            }
            self.optionsMenuAppearance.wrappedValue = false
        }) {
            CloseIcon()
        }
    }
    
    var CompleteButton: some View {
        return Button(action: {
            // Write the current data to the report for one last time
            reportedData[currentStep] = currentText
            submitting = true
            Task { @MainActor in
                do {
                    var finalText = ""
                    // Combine the report
                    for index in steps.indices {
                        let step = steps[index]
                        if reportedData[index].isEmpty { continue }
                        finalText += "\(step.title):\n\(reportedData[index])\(index == steps.count - 1 ? "" : "\n\n")"
                    }

                    await onComplete(finalText)
                    submitting = false
                    self.optionsMenuAppearance.wrappedValue = false
                }
            }
        }) {
            ZStack {
                ProgressView()
                    .frame(width: 15, height: 15)
                    .opacity(submitting ? 1 : 0)
                Image(systemName: "checkmark")
                    .foregroundColor(settings.color)
                    .font(.system(size: 15, weight: .bold))
                    .opacity(submitting ? 0 : 1)
            }
        }
    }
    
    var StepsView: some View {
        return Group {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                Button(action: {
                    // Write the current data to the report
                    reportedData[currentStep] = currentText
                    // Update to the new page of the report
                    currentStep = index
                    currentText = reportedData[index]
                }) {
                    let hasValue = (reportedData.count > index && !reportedData[index].isEmpty) || (index == currentStep && !currentText.isEmpty)
                    
                    ReportingStepView(step: step.symbol, index: index, hasValue: hasValue, activeIndex: $currentStep)
                }
            }
        }
    }
    
    var StepDetails: some View {
        let step = steps[currentStep]
       
        return VStack(alignment: .leading) {
            Text(step.title)
                .font(.title2)
            Text(step.prompt)
                .font(.body)
                .foregroundColor(.gray)
        }
    }
    
    var StepEditor: some View {
        TextEditor(text: $currentText)
            .frame(minHeight: 200, maxHeight: .infinity)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray5), lineWidth: 2)
            )
    }
}

struct ReportingMethodView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReportingMethodView(
                steps: [
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
                ],
                apiConfig: TranscribeAPIConfig(
                    apiURL: "https://sandbox.api.attendi.nl",
                    customerKey: "ck_<key>",
                    userId: "userId",
                    unitId: "unitId",
                    modelType: .districtCare
                )
            ) { _ in
                
            }
        }
        .environmentObject(AttendiMicrophone.Settings())
    }
}
