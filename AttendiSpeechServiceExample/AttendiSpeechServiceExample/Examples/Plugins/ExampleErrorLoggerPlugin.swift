import Foundation
import AttendiSpeechService

/// An example implementation of `AttendiRecorderPlugin` that collects and logs errors during recording.
struct ExampleErrorLoggerPlugin: AttendiRecorderPlugin {

    func activate(model: AttendiRecorderModel) async {
        await model.onError { error in
            debugPrint("\(Self.self) - Error: \(String(describing: error))")
        }
    }
}
