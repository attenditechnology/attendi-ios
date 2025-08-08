import AVFoundation

/// Represents the current status of the audio recording permission.
public enum RecordingPermissionStatus {
    /// Permission was just granted by the user.
    case justGranted

    /// Permission was already granted previously.
    case alreadyGranted

    /// Permission was denied permanently.
    case denied
}

/// Request permission to use the microphone to the user. If the user has
/// has already granted or denied permission, the completion handler will be
/// called immediately. If the user has not yet been asked for permission, the
/// user will be prompted for permission and the completion handler will be
/// called once the user has responded.
///
/// - Parameter completion: A closure that will be called with the result status `RecordingPermissionStatus`
///   of the permission request. The closure will be called immediately if the
///   user has already granted or denied permission. Otherwise, the closure
///   will be called once the user has responded to the permission.
public enum AudioPermissionVerifier {

    static func requestMicrophonePermission(completion: @escaping (RecordingPermissionStatus) -> Void) {
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .granted:
            completion(.alreadyGranted)
        case .denied:
            completion(.denied)
        case .undetermined:
            audioSession.requestRecordPermission { allowed in
                Task { @MainActor in
                    completion(allowed ? .justGranted : .denied)
                }
            }
        @unknown default:
            fatalError("Undefined record permission status")
        }
    }

    static func hasGrantedAudioRecordingPermissions() async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            AudioPermissionVerifier.requestMicrophonePermission { status in
                if status == .denied {
                    continuation.resume(returning: false)
                    return
                }

                continuation.resume(returning: true)
            }
        }
    }
}
