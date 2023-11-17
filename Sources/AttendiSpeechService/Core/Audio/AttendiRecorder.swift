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

import Foundation
import AVFoundation

let targetSampleRate = 16000

/// Wraps the lower-level `AVAudioEngine` APIs to provide a convenient interface for recording audio
/// from the device. Curently the audio samples are resampled to a sample rate of 16KHz, and represented as
/// 16-bit signed integers. The samples are accumulated in ``AttendiRecorder/buffer``.
public class AttendiRecorder {
    public enum RecordingState {
        case recording, paused, stopped
    }
    
    enum Errors: Error {
        case noInputChannels
    }
    
    private var engine = AVAudioEngine()
    
    public private(set) var state: RecordingState = .stopped
    
    /// Clients have read-only access to the buffer. If a client wants to clear it, they need to call `clearBuffer`.
    public private(set) var buffer: [Int16] = []
    
    /// This method preallocates many resources the audio engine requires to start.
    /// Use it to responsively start audio input or output.
    public func prepare() {
        engine.prepare()
    }
    
    /// Start recording audio. The audio samples are resampled to a sample rate of 16KHz, and represented as
    /// 16-bit signed integers. The samples are accumulated in `buffer`.
    public func startRecording() throws {
        // Set the audio session to active to indicate to the OS that our app is
        // recording.
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord)
        try session.setActive(true)
        
        let tapNode: AVAudioNode = engine.inputNode
        let format = tapNode.outputFormat(forBus: 0)
        // TODO: make the target format configurable
        let desiredFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Double(targetSampleRate), channels: 1, interleaved: false)!
        
        // Check if the input node has any channels. If not, we can't record.
        if (tapNode.inputFormat(forBus: 0).channelCount == 0) {
            throw Errors.noInputChannels
        }
        
        // Sometimes the app crashed on `installTap`. Not sure if this is the issue, but sometimes
        // this appears to happen when a tap is already present on a node. Just in case, we also
        // `reset` the engine (but not sure yet if this actually helps).
        engine.reset()
        tapNode.removeTap(onBus: 0)

        tapNode.installTap(onBus: 0, bufferSize: 4096, format: format, block: {
            (buffer, time) in
            if let resampledBuffer = resampleBuffer(buffer: buffer, from: tapNode.outputFormat(forBus: 0), to: desiredFormat) {
                if let channelData = resampledBuffer.int16ChannelData {
                    let channelDataArray = channelData.pointee
                    let length = Int(resampledBuffer.frameLength)
                    let bufferPointer = UnsafeBufferPointer(start: channelDataArray, count: length)
                    let audioSamples = Array(bufferPointer)
                    
                    for callback in self.audioFrameCallbacks.values {
                        callback(audioSamples)
                    }
                    
                    for callback in self.signalEnergyCallbacks.values {
                        callback(rootMeanSquare(audioSamples))
                    }
                    
                    self.buffer.append(contentsOf: audioSamples)
                }
            }
        })
        
        try engine.start()
        state = .recording
    }
    
    /// Stop recording audio and reset the audio session.
    public func stopRecording() {
        engine.inputNode.removeTap(onBus: 0)
        
        engine.stop()
        state = .stopped
        
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.soloAmbient)
        try? session.setActive(false)
    }
    
    public func pauseRecording() {
        engine.pause()
        state = .paused
    }
    
    public func resumeRecording() throws {
        try engine.start()
        state = .recording
    }
    
    /// Clear the recorder's buffer's stored samples.
    public func clearBuffer() {
        self.buffer = []
    }
    
    var audioFrameCallbacks: [String: (_ frames: [Int16]) -> Void] = [:]
    var signalEnergyCallbacks: [String: (_ energy: Double) -> Void] = [:]
    
    /// Register a callback that will be called when a new audio frame (a set of samples) is available.
    /// This is useful when you want to do something with the audio frames in real-time, such as
    /// streaming them to a server.
    ///
    /// Currently, audio samples are represented as 16-bit signed integers, so the callback input parameter
    /// is an array of such integers.
    ///
    /// - Returns: A function that can be used to remove the added callback.
    @discardableResult
    public func onAudioFrames(_ callback: @escaping (_ frames: [Int16]) -> Void) -> () -> Void {
        let id = UUID().uuidString
        audioFrameCallbacks[id] = callback
        
        return { [weak self] in
            self?.audioFrameCallbacks[id] = nil
        }
    }
    
    /// Register a callback that will be called when the signal energy (a measure of the volume)
    /// changes. We currently measure the signal energy using RMS.
    ///
    /// - Returns: A function that can be used to remove the added callback.
    @discardableResult
    public func onSignalEnergy(_ callback: @escaping (_ energy: Double) -> Void) -> () -> Void {
        let id = UUID().uuidString
        signalEnergyCallbacks[id] = callback
        
        return { [weak self] in
            self?.signalEnergyCallbacks[id] = nil
        }
    }
}

func rootMeanSquare(_ values: [Int16]) -> Double {
    let squares = values.map { Double($0) * Double($0) }
    let average = squares.reduce(0, +) / Double(values.count)
    return sqrt(average)
}
