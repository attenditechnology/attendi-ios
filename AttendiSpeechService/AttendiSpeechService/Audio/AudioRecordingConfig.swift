import AVFoundation

/// Configuration for recording raw audio from the microphone using AVAudioEngine.
public struct AudioRecordingConfig {

    /// The sample rate in Hz. Default is 16000 Hz.
    public let sampleRate: Double

    /// The number of audio channels. Default is mono (1).
    ///
    /// Use 1 for mono, 2 for stereo. Higher values are rarely needed unless recording multi-channel sources.
    ///
    public let channel: AVAudioChannelCount

    /// The audio format used in memory (e.g., 16-bit int or 32-bit float).
    public let commonFormat: AVAudioCommonFormat

    /// Whether the audio samples are interleaved or non-interleaved in memory.
    ///
    /// - Interleaved: Samples for all channels are stored together sequentially
    ///   (e.g., `[L, R, L, R, ...]` for stereo).
    ///
    /// - Non-interleaved: Samples are stored in separate buffers for each channel
    ///   (e.g., `[L, L, L, ...]` and `[R, R, R, ...]`).
    ///
    /// Interleaved is more memory-efficient and often used with integer PCM formats.
    /// Non-interleaved is preferred for floating-point processing and by AVAudioEngine by default.
    public let interleaved: Bool

    /// The `.playAndRecord` category is chosen instead of `.record` because it offers greater flexibility
    /// for two-way audio scenarios. In particular, it:
    /// - Enables audio input from Bluetooth microphones and headsets, which `.record` does not support.
    /// - Allows audio playback during recording (e.g., for monitoring or prompt playback).
    /// - Supports routing output to the device speaker using the `.defaultToSpeaker` option.
    ///
    /// The session is further configured with:
    /// - `.allowBluetooth`: Enables audio routing to and from Bluetooth devices.
    /// - `.defaultToSpeaker`: Routes output to the speaker by default instead of the receiver.
    /// - `.mixWithOthers`: Allows this session's audio to play alongside audio from other apps.
    ///
    /// The `.defaultToSpeaker` option is included to ensure output audio (if any) is routed to the
    /// loudspeaker instead of the earpiece.
    ///
    /// iPhones default to routing output to the **earpiece** (the small speaker used during phone calls)
    /// when using `.playAndRecord` without this option. The earpiece is very quiet and only audible when
    /// holding the device to the ear, which can confuse users if any audio is played during or after recording.
    ///
    /// The **speaker**, in contrast, is the bottom or side-facing loudspeaker used for media playback,
    /// and is the expected output device for most app use cases.
    ///
    /// The `.mixWithOthers` option ensures that this session does not interrupt or silence audio from other apps,
    /// which is useful in scenarios where your app's audio should complement rather than replace other audio,
    /// such as playing a short prompt, sound effect, or background audio while the user is listening to music
    /// or using another media app.
    public let categoryOptions: AVAudioSession.CategoryOptions

    public init(
        sampleRate: Double = 16000.0,
        channel: AVAudioChannelCount = 1,
        commonFormat: AVAudioCommonFormat = .pcmFormatInt16,
        interleaved: Bool = false,
        categoryOptions: AVAudioSession.CategoryOptions = [.allowBluetooth, .defaultToSpeaker, .mixWithOthers]
    ) {
        self.sampleRate = sampleRate
        self.channel = channel
        self.commonFormat = commonFormat
        self.interleaved = interleaved
        self.categoryOptions = categoryOptions
    }
}
