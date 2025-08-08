import Foundation
import AVFoundation
import AttendiSpeechService

/// An example implementation of `AttendiRecorderPlugin` that collects audio frames during recording,
/// converts them to a WAV file upon stopping, and saves the file to external storage.
///
/// This plugin listens to audio frames emitted by the recorder, accumulates them,
/// and on recording stop, encodes the collected PCM samples into a WAV format file
/// with a sample rate of 16 kHz. The output file is saved under the app's external files directory.
///
/// When testing on a physical device, you can access to the recorded WAV by going to Window/Devices and Simulators
/// On the left panel you need to select your connected device and on the right panel under Installed apps select
/// AttendiSpeechServiceExample. Tap the (...) icon and select Download Container.
/// Right click on the downloaded xcappdata file and select Show Package Contents.
/// Under AppData/Documents/output.wav will be your file.
final class ExampleWavTranscribePlugin: AttendiRecorderPlugin {
    private let outputDirectory: URL
    private var audioFrames: [Int16] = []

    init(outputDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!) {
        self.outputDirectory = outputDirectory
    }

    func activate(model: AttendiRecorderModel) async {
        await model.onAudio { [weak self] frame in
            guard let self else { return }
            audioFrames.append(contentsOf: frame.samples)
        }

        await model.onStopRecording { [weak self] in
            guard let self else { return }
            do {
                let wavData = AudioEncoder.pcmToWav(samples: self.audioFrames, sampleRate: 16000)
                let outputURL = outputDirectory.appendingPathComponent("output.wav")

                try wavData.write(to: outputURL)
                debugPrint("\(Self.self) - Saved WAV to: \(outputURL.path)")
            } catch {
                debugPrint("\(Self.self) - Error writing WAV: \(String(describing: error))")
            }

            audioFrames.removeAll()
        }
    }

    func deactivate(model: AttendiRecorderModel) {
        audioFrames.removeAll()
    }
}
