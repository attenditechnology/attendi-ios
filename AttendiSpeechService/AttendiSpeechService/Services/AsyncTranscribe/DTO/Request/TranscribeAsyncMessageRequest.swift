import Foundation

/// This message is sent to the transcription server when the microphone starts recording.
struct TranscribeAsyncMessageRequest: Encodable {
    /// Is always "ClientConfiguration" for this message type.
    /// However, the serialization somehow doesn't include the messageType in the JSON when we use a default value for the field.
    let type: String

    /// The model to use for transcription. If not specified, the backend uses a default model specified for the customer.
    let model: String?

    /// Allows for associating multiple transcriptions into `sessions` and `reports`.
    let reportId: String?

    let features: TranscribeAsyncAppSettingsRequest?
}

/// These are configuration features sent as part of the client configuration message
/// which allows us to send feature information, such as whether we can use voice editing or not.
struct TranscribeAsyncAppSettingsRequest: Encodable {
    let voiceEditing: TranscribeAsyncVoiceEditingAppSettingsRequest
}

struct TranscribeAsyncVoiceEditingAppSettingsRequest: Encodable {
    /// When enabled it allows voice editing, otherwise voice editing is disabled.
    let isEnabled: Bool
}
