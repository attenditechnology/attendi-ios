import SwiftUI

@main
struct MainApp: App {

    var body: some Scene {
        WindowGroup {
            ExampleAppView()
        }
    }
}

private struct ExampleAppView: View {

    enum InternalRoute: String, Hashable {
        case twoMicrophonesStreaming = "ExampleAppTwoMicrophonesStreaming"
        case oneMicrophoneSync = "ExampleAppOneMicrophoneSync"
        case soap = "ExampleAppSOAP"
        case recorder = "ExampleAppRecorder"
    }

    @State private var path: [InternalRoute] = []
    @State private var currentScreen: InternalRoute = .twoMicrophonesStreaming

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                if currentScreen != .twoMicrophonesStreaming {
                    Button("Stream") {
                        currentScreen = .twoMicrophonesStreaming
                    }
                }

                if currentScreen != .oneMicrophoneSync {
                    Button("Sync") {
                        currentScreen = .oneMicrophoneSync
                    }
                }

                if currentScreen != .soap {
                    Button("SOAP") {
                        currentScreen = .soap
                    }
                }

                if currentScreen != .recorder {
                    Button("REC") {
                        currentScreen = .recorder
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()

            Divider()
            Spacer(minLength: 0)

            ZStack {
                switch currentScreen {
                case .twoMicrophonesStreaming:
                    TwoMicrophonesStreamingScreen()
                case .oneMicrophoneSync:
                    OneMicrophoneSyncScreen()
                case .soap:
                    SoapScreen()
                case .recorder:
                    RecorderStreamingScreen()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
