import Foundation

/// Represents a single frame of audio data, which contains multiple samples.
///
/// - samples: The raw 16-bit PCM audio samples in this frame. In the future we will
/// allow different types of samples supporting other PCM configurations.
public struct AudioFrame {
    public let samples: [Int16]

    public init(samples: [Int16]) {
        self.samples = samples
    }

    /// Retrieves the volume of the audio signal using the rootMeanSquare (RMS) standard.
    public func getVolume() -> Double {
        guard !samples.isEmpty else { return 0.0 }
        let sumSquares = samples.reduce(0.0) { acc, sample in
            let val = Double(sample)
            return acc + val * val
        }
        return sqrt(sumSquares / Double(samples.count))
    }
}
