import Foundation

/// Base implementation of the `AsyncTranscribeService` protocol, providing core WebSocket connection
/// management, message handling, and lifecycle support for transcription services.
///
/// This class handles:
/// - Connecting to a WebSocket endpoint with automatic retries.
/// - Sending initial configuration and closing messages, if provided.
/// - Managing socket lifecycle events (open, message, close, failure).
/// - Enforcing mutual exclusion for connection attempts via a lock.
/// - Abstracting WebSocket URL creation and customization.
///
/// Subclasses must implement `createWebSocketRequest` and may override optional hooks such as:
/// - `onRetryAttempt`: to customize retry behavior (e.g., refresh token or credentials).
/// - `getOpenMessage`: to send a configuration payload upon connection.
/// - `getCloseMessage` and `getCloseCode`: to customize socket shutdown behavior.
///
/// This base class is designed to be extended by service implementations targeting specific
/// WebSocket-based transcription backends, while abstracting away connection boilerplate.
class BaseAsyncTranscribeService: AsyncTranscribeService {

    private enum Constants {
        /// Maximum duration to wait when establishing a connection.
        static let connectionTimeoutMilliseconds = 20_000

        /// Timeout to wait for the server to close the connection after sending the end-of-stream message.
        static let serverCloseSocketTimeoutMilliseconds = 5_000

        /// Polling interval for checking if the server closed the socket.
        static let serverCloseSocketIntervalCheckMilliseconds = 50

        /// WebSocket closure code indicating a normal, expected shutdown.
        static let websocketNormalClosureCode = 1000

        /// WebSocket closure code indicating a timeout, forced shutdown.
        static let websocketTimeoutClosureCode = 4000
    }

    /// A mutex to ensure that only one connect() operation can run at a time.
    /// This prevents race conditions or concurrent connection attempts,
    /// especially if connect() is called repeatedly or from multiple tasks.
    private let connectMutex = AsyncMutex()
    private var socket: URLSessionWebSocketTask?
    private var listener: AsyncTranscribeServiceListener?
    private var isConnected = false
    private var isDisconnecting = false

    /// Creates the WebSocket Request object used to initiate the connection.
    ///
    /// - Returns: A configured Request object ready for use with Network framework.
    func createWebSocketRequest() async throws -> URLRequest {
        fatalError("Subclasses must implement createWebSocketRequest()")
    }

    /// Called on retry attempts to allow the consumer to modify the request.
    /// Default implementation calls `createWebSocketRequest` again.
    ///
    /// - Parameters:
    ///   - retryAttempt: The retry number (starting from 1).
    ///   - previousRequest: The request used in the failed attempt.
    ///   - error: The error that caused the failure (optional).
    /// - Returns: A new Request object to retry with.
    func onRetryAttempt(
        retryAttempt: Int,
        previousRequest: URLRequest?,
        error: Error?
    ) async throws -> URLRequest {
        try await createWebSocketRequest()
    }

    /// (Optional) Returns the initial message to be sent immediately after the WebSocket opens.
    ///
    /// This message is typically used to initialize the transcription session, set language, model,
    /// or other backend-specific options. If `nil` is returned, no message will be sent.
    ///
    /// - Returns: A properly formatted open message as a `String` or `nil` if not needed.
    func getOpenMessage() -> String? {
        nil
    }

    /// (Optional) Returns the close message that should be sent to the server when ending the session.
    ///
    /// This message typically signals the end-of-stream or end-of-transcription event,
    /// and varies depending on the backend's protocol expectations. If `nil` is returned, no message will be sent.
    ///
    /// - Returns: A properly formatted close message as a `String` or `nil` if not needed.
    func getCloseMessage() -> String? {
        nil
    }

    /// Returns the WebSocket close code to be sent when terminating the connection.
    ///
    /// The default implementation returns `1000`, which indicates a normal closure as per
    /// RFC 6455.
    ///
    /// Subclasses may override this method to provide a custom application-defined close code
    /// (typically in the 4000–4999 range) if a different reason for closing should be conveyed.
    ///
    /// - Returns: A `Int` close code to send with the WebSocket close frame.
    func getCloseCode() -> Int {
        Constants.websocketNormalClosureCode
    }

    /// Initiates a WebSocket connection to the Attendi streaming API.
    ///
    /// This method runs asynchronously and will emit events to the provided `listener`
    /// for success, errors, and incoming messages.
    ///
    /// - Parameter listener: An implementation of `AsyncTranscribeServiceListener` to observe connection state.
    func connect(listener: AsyncTranscribeServiceListener) async throws {
        try await connectMutex.withLock {
            self.listener = listener
            try await connectSocket(listener: listener)
        }
    }

    /// Attempts to establish a WebSocket connection using a URLRequest object. Supports automatic retries
    /// if the initial connection attempt fails.
    ///
    /// This method delegates URLRequest construction to either `createWebSocketRequest` (on the first attempt)
    /// or `onRetryAttempt` (on subsequent retries). The consumer can override `onRetryAttempt` to dynamically
    /// modify the URLRequest between retry attempts — for example, by refreshing authentication tokens or cookies.
    ///
    /// If a timeout occurs, `AsyncTranscribeServiceError.connectTimeout` is reported. For other exceptions,
    /// the method retries until `retryCount` is exhausted. When all attempts fail,
    /// `AsyncTranscribeServiceError.unknown` or `AsyncTranscribeServiceError.failedToConnect` is reported.
    ///
    /// - Parameters:
    ///   - listener: A listener for receiving error callbacks.
    ///   - retryCount: The number of retry attempts to perform after the initial failure. Defaults to 1.
    ///   - currentRetry: The current retry attempt number, starting from 0.
    ///   - previousRequest: The request used in the previous attempt. `nil` for the initial attempt.
    ///   - previousError: The Error that caused the previous failure, if any.
    private func connectSocket(
        listener: AsyncTranscribeServiceListener,
        retryCount: Int = 1,
        currentRetry: Int = 0,
        previousRequest: URLRequest? = nil,
        previousError: Error? = nil
    ) async throws {
        let request: URLRequest
        do {
            if currentRetry == 0 {
                request = try await createWebSocketRequest()
            } else {
                request = try await onRetryAttempt(
                    retryAttempt: currentRetry,
                    previousRequest: previousRequest,
                    error: previousError
                )
            }
        } catch {
            listener.onError(.failedToConnect(message: error.localizedDescription))
            return
        }

        do {
            try await connectSocket(request: request)
        } catch {
            if retryCount == 0 {
                listener.onError(.unknown(message: error.localizedDescription))
            } else {
                try await connectSocket(
                    listener: listener,
                    retryCount: retryCount - 1,
                    currentRetry: currentRetry + 1,
                    previousRequest: request,
                    previousError: error
                )
            }
        }
    }

    private func connectSocket(request: URLRequest) async throws {
        /// Use URLSession for WebSocket connection with custom headers.
        let session = URLSession(configuration: .default)
        let webSocketTask = session.webSocketTask(with: request)
        self.socket = webSocketTask

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume()
                return
            }

            webSocketTask.resume()

            /// Start receiving messages.
            receiveMessage()

            /// Send initial configuration message if provided.
            if let openMessage = getOpenMessage() {
                Task { [weak self] in
                    guard let self else { return }
                    await send(message: openMessage)
                }
            }

            isConnected = true
            listener?.onOpen()
            continuation.resume()
        }
    }

    private func receiveMessage() {
        socket?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    listener?.onMessage(text)
                default:
                    break
                }

                /// Continue receiving messages.
                receiveMessage()

            case .failure(let error):
                if !isDisconnecting {
                    listener?.onError(.unknown(message: error.localizedDescription))
                }
                handleSocketClosed()
            }
        }
    }

    private func handleSocketClosed() {
        listener?.onClose()
        socket = nil
        listener = nil
        isConnected = false
        isDisconnecting = false
    }

    /// Closes the active WebSocket connection.
    ///
    /// Sends a termination message to the server and attempts to gracefully wait
    /// for the server to close the socket. If the server doesn't respond in time,
    /// the connection is forcibly terminated.
    func disconnect() async throws {
        await connectMutex.withLock {
            if !isConnected || isDisconnecting {
                return
            }
            isDisconnecting = true

            if let closeMessage = getCloseMessage() {
                await send(message: closeMessage)
                let socketClosedByServer = await waitForServerToCloseSocket()
                if !socketClosedByServer {
                    socket?.cancel(with: .abnormalClosure, reason: nil)
                    listener?.onError(.disconnectTimeout)
                }
            } else {
                socket?.cancel(with: .normalClosure, reason: nil)
            }
            handleSocketClosed()
        }
    }

    private func waitForServerToCloseSocket() async -> Bool {
        let startTime = DispatchTime.now()

        while socket != nil {
            try? await Task.sleep(nanoseconds: Constants.serverCloseSocketIntervalCheckMilliseconds.milliToNano())

            if DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds > Constants.serverCloseSocketTimeoutMilliseconds.milliToNano() {
                return false /// Timeout reached.
            }
        }

        return true /// Socket was closed by server within timeout.
    }

    /// Sends a binary message (typically audio) to the Attendi server.
    ///
    /// - Parameter message: A Data object containing audio or binary data.
    /// - Returns: `true` if the message was sent successfully, `false` otherwise.
    func send(message: Data) async -> Bool {
        await sendIfConnected { socket in
            try? await socket.send(.data(message))
            return true
        }
    }

    /// Sends a text-based message to the Attendi server.
    ///
    /// - Parameter message: A UTF-8 string message (e.g., control or metadata).
    /// - Returns: `true` if the message was sent successfully, `false` otherwise.
    @discardableResult func send(message: String) async -> Bool {
        await sendIfConnected { socket in
            try? await socket.send(.string(message))
            return true
        }
    }

    private func sendIfConnected(action: (URLSessionWebSocketTask) async -> Bool) async -> Bool {
        guard isConnected,
              let socket
        else { return false }
        return await action(socket)
    }
}
