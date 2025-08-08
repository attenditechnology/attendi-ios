import Foundation

/// A generic contract for establishing and interacting with a streaming or real-time connection.
///
/// Consumers can implement this protocol to use their own backend services or protocols.
/// This allows flexibility in how messages are sent or received (e.g., using a custom WebSocket, HTTP/2, etc).
public protocol AsyncTranscribeService {

    /// Initiates the connection and sets a listener for lifecycle and message events.
    ///
    /// - Parameter listener: An implementation of `AsyncTranscribeServiceListener` to handle callbacks.
    func connect(listener: AsyncTranscribeServiceListener) async throws

    /// Closes the connection if it is currently active.
    func disconnect() async throws

    /// Sends a textual message over the connection.
    ///
    /// - Parameter message: The message string to send.
    /// - Returns: `true` if the message was successfully dispatched; otherwise, `false`.
    @discardableResult func send(message: String) async -> Bool

    /// Sends binary data over the connection.
    ///
    /// - Parameter message: The binary payload to send.
    /// - Returns: `true` if the message was successfully dispatched; otherwise, `false`.
    @discardableResult func send(message: Data) async -> Bool
}

/// Listener for observing connection events and handling incoming messages.
public protocol AsyncTranscribeServiceListener {
    /// Called when the connection has been successfully opened.
    func onOpen()

    /// Called when a message is received from the connection.
    ///
    /// - Parameter message: A UTF-8 string message from the server or backend.
    func onMessage(_ message: String)

    /// Called when an error occurs during connection or message handling.
    ///
    /// - Parameter error: The specific error that occurred.
    func onError(_ error: AsyncTranscribeServiceError)

    /// Called when the connection is closed or terminated.
    func onClose()
}

/// Describes the various types of connection-related errors that may occur.
public enum AsyncTranscribeServiceError: Error, LocalizedError {

    /// Indicates a failure to establish the connection.
    case failedToConnect(message: String)

    /// Indicates the connection closed unexpectedly or with an abnormal code.
    case closedAbnormally(message: String)

    /// Connection attempt exceeded the allowed timeout.
    case connectTimeout

    /// Disconnection attempt exceeded the allowed timeout.
    case disconnectTimeout

    /// An unknown or unclassified connection error.
    case unknown(message: String)

    public var errorDescription: String? {
        switch self {
        case .failedToConnect(let message):
            return message
        case .closedAbnormally(let message):
            return message
        case .connectTimeout:
            return "Connection attempt timed out."
        case .disconnectTimeout:
            return "Disconnection attempt timed out."
        case .unknown(let message):
            return message
        }
    }
}
