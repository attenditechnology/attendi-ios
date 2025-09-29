import Foundation

/// A lightweight delegate bridge for observing WebSocket connection state.
///
/// `WebSocketSessionStatusBridge` conforms to `URLSessionWebSocketDelegate` and
/// exposes closure callbacks (`onOpen` and `onClose`).
final class WebSocketSessionStatusBridge: NSObject, URLSessionWebSocketDelegate {

    private let onOpen: () -> Void
    private let onClose: (URLSessionWebSocketTask.CloseCode, String?) -> Void

    /// Creates a new bridge with closures for connection lifecycle events.
    ///
    /// - Parameters:
    ///   - onOpen: Called when the WebSocket connection is successfully established.
    ///   - onClose: Called when the WebSocket connection is closed, with the close code
    ///     and an optional textual reason (decoded from `Data` if provided).
    init(
        onOpen: @escaping () -> Void,
        onClose: @escaping (URLSessionWebSocketTask.CloseCode, String?) -> Void
    ) {
        self.onOpen = onOpen
        self.onClose = onClose
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        onOpen()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith code: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        var reasonString: String? = nil
        if let reason, !reason.isEmpty {
            reasonString = String(data: reason, encoding: .utf8)
            ?? reason.map { String(format: "%02x", $0) }.joined()
        }
        onClose(code, reasonString)
    }
}
