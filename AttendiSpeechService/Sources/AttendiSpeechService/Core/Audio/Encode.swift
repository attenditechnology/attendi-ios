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

import AVFoundation

/// Resample a buffer containing PCM data from a source format into a target format. Can
/// change e.g. the sample rate, and the pcm data type such as int16 or float32.
func resampleBuffer(
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

/// Convert an array of audio samples into the WAV format by adding a WAV header to the samples.
/// Currently assumes the audio was recorded using signed 16-bit integers.
func pcmToWav(samples: [Int16], sampleRate: Int) -> Data {
    let bitsPerSample = 16
    let bytesPerSample = bitsPerSample / 8
    let totalDataLength = samples.count * bytesPerSample
    let byteRate = bytesPerSample * sampleRate
    let headerSize = 44
    let formatPcm: UInt16 = 1
    let numChannels: UInt16 = 1
    let blockAlign = numChannels * UInt16(bytesPerSample)
    
    var header = Data()
    header.append(contentsOf: Array("RIFF".utf8)) // ChunkID
    header.append(UInt32(totalDataLength + headerSize - 8).littleEndian.data) // ChunkSize
    header.append(contentsOf: Array("WAVE".utf8)) // Format
    header.append(contentsOf: Array("fmt ".utf8)) // Subchunk1ID
    header.append(UInt32(16).littleEndian.data) // Subchunk1Size
    header.append(formatPcm.littleEndian.data) // AudioFormat
    header.append(numChannels.littleEndian.data) // NumChannels
    header.append(UInt32(sampleRate).littleEndian.data) // SampleRate
    header.append(UInt32(byteRate).littleEndian.data) // ByteRate
    header.append(blockAlign.littleEndian.data) // BlockAlign
    header.append(UInt16(bitsPerSample).littleEndian.data) // BitsPerSample
    header.append(contentsOf: Array("data".utf8)) // Subchunk2ID
    header.append(UInt32(totalDataLength).littleEndian.data) // Subchunk2Size
    
    var wavData = Data()
    wavData.append(header)
    for sample in samples {
        wavData.append(sample.littleEndian.data)
    }
    
    return wavData
}


extension BinaryInteger {
    var data: Data {
        var source = self
        return Data(bytes: &source, count: MemoryLayout<Self>.size)
    }
}
