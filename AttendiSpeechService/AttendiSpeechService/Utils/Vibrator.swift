import UIKit

/// Utility struct to handle device vibration.
public enum Vibrator {

    /// Vibrates the device with a short notification-style feedback.
    ///
    /// - Parameter notificationType: The type of vibration effect, e.g success, warning or error.
    @MainActor public static func vibrate(_ notificationType: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(notificationType)
    }
}
