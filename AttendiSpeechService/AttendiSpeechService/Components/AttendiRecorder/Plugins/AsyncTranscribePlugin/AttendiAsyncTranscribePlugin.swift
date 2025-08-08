import Foundation

/// A plugin for real-time, asynchronous speech transcription using `AsyncTranscribeService` and `AsyncTranscribeMessageDecoder`.
/// Designed to be extensible and customizable by allowing custom implementations of `AsyncTranscribeService` and `AsyncTranscribeMessageDecoder` to be passed in.
/// Two key components — AttendiConnection and AttendiMessageDecoder — are injected via constructor parameters,
/// allowing users to swap or extend behavior without modifying the core plugin.
///
/// By using protocols (`AsyncTranscribeService`, `AsyncTranscribeMessageDecoder`), we decouple the plugin logic from specific implementations:
/// - `AsyncTranscribeService`: Defines how and where audio is sent and responses are received.
/// - `AsyncTranscribeMessageDecoder`: Defines how incoming messages are interpreted into `[TranscribeAsyncAction]` models.
///
/// For typical use cases with the Attendi WebSocket service, the plugin provides:
/// - `AttendiAsyncTranscribeServiceImpl`: A default WebSocket-based connection that handles sending/receiving messages to Attendi's servers.
/// - `AttendiAsyncTranscribeMessageDecoder`: A decoder that interprets Attendi-formatted JSON messages into actionable `TranscribeAsyncAction` objects.
/// These cover most use cases out of the box.
///
/// If you want to integrate Attendi's plugin with your own transcription server, or use a different message format,
/// you can do so by providing custom implementations of the `AsyncTranscribeService` and `AsyncTranscribeMessageDecoder` protocols.
///
/// - Parameters:
///   - service: The transcribe async service (e.g., `AttendiAsyncTranscribeServiceImpl`) used to send audio and receive messages.
///   - serviceMessageDecoder: The decoder used to interpret JSON messages from the backend. Defaults to `AttendiAsyncTranscribeMessageDecoder`.
///   - onStreamConnecting: Callback invoked when the plugin is preparing and attempting to establish a connection.
///   - onStreamStarted: Callback invoked once the stream has been successfully established and is ready to receive audio.
///   - onStreamUpdated: Callback invoked whenever the transcribe stream is updated with new actions.
///   - onStreamCompleted: Callback invoked when the session ends normally or with an exception.
public final class AttendiAsyncTranscribePlugin: AttendiRecorderPlugin {

    private let service: AsyncTranscribeService
    private let serviceMessageDecoder: AsyncTranscribeMessageDecoder
    private let onStreamConnecting: () -> Void
    private let onStreamStarted: () -> Void
    private let onStreamUpdated: (AttendiTranscribeStream) -> Void
    private let onStreamCompleted: (AttendiTranscribeStream, Error?) -> Void

    private var transcribeStream = AttendiTranscribeStream()
    private var streamingBuffer: [Int16] = []

    /// Used for ensuring thread safety.
    private let stateMutex = AsyncMutex()
    /// This flag ensures that a complete flow does not reconnect to a completed one, preventing multiple calls to onStreamCompleted.
    private var isStreamConnecting = false
    /// We only send audio data on an open connection.
    private var isConnectionOpen = false
    /// Avoid closing twice.
    private var isClosingConnection = false
    /// We store the pluginError in an instance variable so we can pass it to the `onStreamCompleted` callback, even if the error was generated in a different method.
    private var pluginError: Error? = nil

    public init(
        service: AsyncTranscribeService,
        serviceMessageDecoder: AsyncTranscribeMessageDecoder = AttendiAsyncTranscribeMessageDecoderFactory.create(),
        onStreamConnecting: @escaping () -> Void = {},
        onStreamStarted: @escaping () -> Void = {},
        onStreamUpdated: @escaping (AttendiTranscribeStream) -> Void,
        onStreamCompleted: @escaping (AttendiTranscribeStream, Error?) -> Void = { _, _ in }
    ) {
        self.service = service
        self.serviceMessageDecoder = serviceMessageDecoder
        self.onStreamConnecting = onStreamConnecting
        self.onStreamStarted = onStreamStarted
        self.onStreamUpdated = onStreamUpdated
        self.onStreamCompleted = onStreamCompleted
    }

    /// Activates the plugin and sets up listeners for:
    /// - WebSocket lifecycle (open, message, error, close)
    /// - Audio frame streaming from the microphone
    /// - Stop recording events
    ///
    /// Starts sending audio when enough buffered samples are collected.
    public func activate(model: AttendiRecorderModel) async {
        await model.onStartRecording { [weak self, weak model] in
            guard let self, let model else { return }
            await stateMutex.withLock { [weak self, weak model] in
                guard let self, let model else { return }
                if isStreamConnecting {
                    return
                }
                isStreamConnecting = true

                resetPluginState()
                onStreamConnecting()
                do {
                    let serviceListener = createServiceListener(model: model)
                    try await service.connect(listener: serviceListener)
                } catch {
                    await forceStopRecording(model: model, error: error)
                }
            }
        }

        await model.onAudio { [weak self] audioFrame in
            guard let self else { return }
            await processAudioFrame(audioFrame)
        }

        await model.onBeforeStopRecording { [weak self] in
            guard let self else { return }
            await closeConnection()
        }
    }

    /// Deactivates the plugin, closes the WebSocket connection, and clears any pending audio buffers or listeners.
    public func deactivate(model: AttendiRecorderModel) async {
        await closeConnection()
    }

    private func createServiceListener(model: AttendiRecorderModel) -> AsyncTranscribeServiceListener {
        ServiceListener(
            onOpenHandler: { [weak self] in
                guard let self else { return }
                isConnectionOpen = true
                onStreamStarted()
            },
            onMessageHandler: { [weak self, weak model] message in
                guard let self, let model else { return }
                do {
                    let transcribeActions = try serviceMessageDecoder.decode(message)
                    transcribeStream = try transcribeStream.receiveActions(transcribeActions)
                    onStreamUpdated(transcribeStream)
                } catch {
                    pluginError = error
                    Task { [weak self, weak model] in
                        guard let self, let model else { return }
                        await forceStopRecording(model: model, error: error)
                        await closeConnection()
                    }
                }
            },
            onErrorHandler: { [weak self, weak model] error in
                guard let self, let model else { return }
                pluginError = error
                Task { [weak self, weak model] in
                    guard let self, let model else { return }
                    await forceStopRecording(model: model, error: error)
                    await processStreamCompleted()
                }
            },
            onCloseHandler: {
                Task { [weak self] in
                    guard let self else { return }
                    await processStreamCompleted()
                }
            }
        )
    }

    private struct ServiceListener: AsyncTranscribeServiceListener {
        let onOpenHandler: () -> Void
        let onMessageHandler: (String) -> Void
        let onErrorHandler: (AsyncTranscribeServiceError) -> Void
        let onCloseHandler: () -> Void

        func onOpen() {
            onOpenHandler()
        }

        func onMessage(_ message: String) {
            onMessageHandler(message)
        }

        func onError(_ error: AsyncTranscribeServiceError) {
            onErrorHandler(error)
        }

        func onClose() {
            onCloseHandler()
        }
    }

    private func resetPluginState() {
        transcribeStream = AttendiTranscribeStream()
        isConnectionOpen = false
        isClosingConnection = false
        pluginError = nil
        streamingBuffer.removeAll()
    }

    private func forceStopRecording(model: AttendiRecorderModel, error: Error) async {
        await model.stop()
        await model.callbacks.invokeOnError(error)
    }

    private func closeConnection() async {
        await stateMutex.withLock {
            if isClosingConnection {
                return
            }
            isClosingConnection = true

            try? await service.disconnect()

            streamingBuffer.removeAll()
        }
    }

    private func processAudioFrame(_ audioFrame: AudioFrame) async {
        /// Wait for the socket connection to be open prior to adding frames to the buffer.
        if !isConnectionOpen {
            return
        }

        let byteArray = AudioEncoder.shortsToData(shorts: audioFrame.samples)
        await service.send(message: byteArray)
    }

    private func processStreamCompleted() async {
        await stateMutex.withLock {
            if !isStreamConnecting {
                return
            }
            isStreamConnecting = false
            onStreamCompleted(transcribeStream, pluginError)
        }
    }
}
