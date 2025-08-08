import SwiftUI

/// Configuration settings for customizing the appearance and behavior of the AttendiMicrophone.
public struct AttendiMicrophoneSettings {

    /// Sets the width and height of the microphone button.
    public let size: CGFloat

    /// Optional corner radius. If nil, a fully rounded (50%) shape is used.
    public let cornerRadius: CGFloat?

    /// Visual color states for active/inactive modes.
    public let colors: AttendiMicrophoneColors

    /// A flag indicating whether visual volume feedback is enabled during recording.
    ///
    /// When set to `true`, the UI provides additional feedback to the user by displaying
    /// the current volume level of the audio signal. This is typically visualized by
    /// filling the inside of the microphone's cone in sync with the detected volume level,
    /// giving users a real-time indication that the microphone is actively recording.
    ///
    /// This feature enhances user confidence that recording is working properly,
    /// especially in scenarios where audio input may otherwise be silent or subtle.
    public let isVolumeFeedbackEnabled: Bool

    /// A flag indicating whether the default permissions alert will be shown.
    /// By default is set to true, if a custom view needs to be displayed set this flag to false.
    public let showsDefaultPermissionsDeniedAlert: Bool

    public init(
        size: CGFloat = 48,
        cornerRadius: CGFloat? = nil,
        colors: AttendiMicrophoneColors = AttendiMicrophoneDefaults.colors(),
        isVolumeFeedbackEnabled: Bool = true,
        showsDefaultPermissionsDeniedAlert: Bool = true
    ) {
        self.size = size
        self.cornerRadius = cornerRadius
        self.colors = colors
        self.isVolumeFeedbackEnabled = isVolumeFeedbackEnabled
        self.showsDefaultPermissionsDeniedAlert = showsDefaultPermissionsDeniedAlert
    }
}

/// Defines the color scheme for different microphone states.
public struct AttendiMicrophoneColors {

    public let activeForegroundColor: Color
    public let activeBackgroundColor: Color
    public let inactiveForegroundColor: Color
    public let inactiveBackgroundColor: Color

    public init(
        activeForegroundColor: Color,
        activeBackgroundColor: Color,
        inactiveForegroundColor: Color,
        inactiveBackgroundColor: Color
    ) {
        self.activeForegroundColor = activeForegroundColor
        self.activeBackgroundColor = activeBackgroundColor
        self.inactiveForegroundColor = inactiveForegroundColor
        self.inactiveBackgroundColor = inactiveBackgroundColor
    }
}

/// Contains the default values used by AttendiMicrophone.
public enum AttendiMicrophoneDefaults {

    public static let baseAttendiColor = Color(red: 0x1C / 255.0, green: 0x69 / 255.0, blue: 0xE8 / 255.0)

    /// Creates an `AttendiMicrophoneColors` that represents the default colors used in an AttendiMicrophone.
    public static func colors(
        baseColor: Color = baseAttendiColor,
        inactiveBackgroundColor: Color = .clear,
        inactiveForegroundColor: Color? = nil,
        activeBackgroundColor: Color? = nil,
        activeForegroundColor: Color = .white
    ) -> AttendiMicrophoneColors {
        AttendiMicrophoneColors(
            activeForegroundColor: activeForegroundColor,
            activeBackgroundColor: activeBackgroundColor ?? baseColor,
            inactiveForegroundColor: inactiveForegroundColor ?? baseColor,
            inactiveBackgroundColor: inactiveBackgroundColor
        )
    }
}
