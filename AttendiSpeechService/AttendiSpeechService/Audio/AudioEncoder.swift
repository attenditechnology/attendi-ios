import AVFoundation

/// Utility object for encoding audio data.
public enum AudioEncoder {
    
    /// Convert PCM audio data to WAV format by prepending a WAV header.
    ///
    /// - Parameters:
    ///   - samples: An array of 16-bit PCM samples (mono).
    ///   - sampleRate: The sample rate in Hz.
    /// - Returns: A `Data` object containing a valid WAV file.
    public static func pcmToWav(samples: [Int16], sampleRate: Int) -> Data {
        let bitsPerSample: UInt16 = 16
        let bytesPerSample = Int(bitsPerSample / 8)
        let totalDataLength = samples.count * bytesPerSample
        let byteRate = sampleRate * bytesPerSample
        let headerSize = 44
        
        let formatPcm: UInt16 = 1
        let numChannels: UInt16 = 1
        let blockAlign: UInt16 = numChannels * UInt16(bytesPerSample)
        
        var header = Data(capacity: headerSize)
        header.append(contentsOf: Array("RIFF".utf8)) /// Chunk ID.
        header.append(binaryIntegerToData(UInt32(totalDataLength + headerSize - 8))) /// Chunk size.
        header.append(contentsOf: Array("WAVE".utf8)) /// Format.
        header.append(contentsOf: Array("fmt ".utf8)) /// Subchunk1 ID.
        header.append(binaryIntegerToData(UInt32(16))) /// Subchunk1 size (PCM).
        header.append(binaryIntegerToData(formatPcm)) /// Audio format (1 = PCM).
        header.append(binaryIntegerToData(numChannels)) /// Channels.
        header.append(binaryIntegerToData(UInt32(sampleRate))) /// Sample rate.
        header.append(binaryIntegerToData(UInt32(byteRate))) /// Byte rate.
        header.append(binaryIntegerToData(blockAlign)) /// Block align.
        header.append(binaryIntegerToData(bitsPerSample)) /// Bits per sample.
        header.append(contentsOf: Array("data".utf8)) /// Subchunk2 ID.
        header.append(binaryIntegerToData(UInt32(totalDataLength))) /// Subchunk2 size.

        var wavData = Data(capacity: headerSize + totalDataLength)
        wavData.append(header)
        wavData.append(shortsToData(shorts: samples))
        return wavData
    }
    
    /// Efficiently converts an array of 16-bit samples to little-endian byte data.
    public static func shortsToData(shorts: [Int16]) -> Data {
        var data = Data(capacity: shorts.count * 2)
        shorts.withUnsafeBufferPointer {
            data.append(contentsOf: UnsafeRawBufferPointer($0))
        }
        return data
    }
    
    /// Resample a buffer containing PCM data from a source format into a target format.
    /// Can change e.g. the sample rate, and the pcm data type such as int16 or float32.
    static func resampleBuffer(
        buffer: AVAudioPCMBuffer,
        from sourceFormat: AVAudioFormat,
        to targetFormat: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else { return nil }
        
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        let sampleRateConversionRatio = sourceFormat.sampleRate / targetFormat.sampleRate
        let frameCapacity = AVAudioFrameCount(Double(buffer.frameLength) / sampleRateConversionRatio)
        
        guard let newBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCapacity) else {
            return nil
        }
        
        let conversionStatus = converter.convert(to: newBuffer, error: nil, withInputFrom: inputBlock)
        
        guard conversionStatus != .error else { return nil }
        return newBuffer
    }
    
    /// Converts any fixed-width integer into `Data` using little-endian order.
    private static func binaryIntegerToData<T: BinaryInteger>(_ value: T) -> Data where T: FixedWidthInteger {
        var littleEndianValue = value.littleEndian
        return withUnsafeBytes(of: &littleEndianValue) { Data($0) }
    }
}
