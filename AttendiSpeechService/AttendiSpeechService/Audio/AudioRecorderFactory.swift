import Foundation

/// Factory object for creating instances of `AudioRecorderImpl`.
public enum AudioRecorderFactory {
    
    /// Creates the default implementation of `AudioRecorderImpl``.
    ///
    /// This recorder provides basic audio capture functionality using the
    /// underlying platform-specific implementation. It is suitable for use
    /// in most environments without requiring additional configuration.
    ///
    /// - returns: A default instance of `AudioRecorder`.
    ///
    public static func create() -> AudioRecorder {
        AudioRecorderImpl.shared
    }
}
