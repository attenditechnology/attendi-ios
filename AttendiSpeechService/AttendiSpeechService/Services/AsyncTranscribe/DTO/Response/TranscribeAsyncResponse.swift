import Foundation

/// A response that is sent to the end user from Attendi's transcription API
public struct TranscribeAsyncResponse: Decodable {
    public let actions: [TranscribeAsyncAnnotationResponse]

    public init(actions: [TranscribeAsyncAnnotationResponse]) {
        self.actions = actions
    }
}

public struct TranscribeAsyncAnnotationResponse: Decodable {
    public let id: String
    public let index: Int
    public let type: TranscribeAsyncActionTypeResponse
    public let parameters: TranscribeAsyncAnnotationParametersResponse?

    public init(
        id: String,
        index: Int,
        type: TranscribeAsyncActionTypeResponse,
        parameters: TranscribeAsyncAnnotationParametersResponse?
    ) {
        self.id = id
        self.index = index
        self.type = type
        self.parameters = parameters
    }
}

public struct TranscribeAsyncAnnotationParametersResponse: Decodable {
    public let type: TranscribeAsyncAnnotationParameterTypeResponse?
    public let id: String?
    public let text: String?
    public let parameters: TranscribeAsyncAnnotationExtraParametersResponse?
    public let startCharacterIndex: Int?
    public let endCharacterIndex: Int?
    
    public init(
        type: TranscribeAsyncAnnotationParameterTypeResponse? = nil,
        id: String? = nil,
        text: String? = nil,
        parameters: TranscribeAsyncAnnotationExtraParametersResponse? = nil,
        startCharacterIndex: Int? = nil,
        endCharacterIndex: Int? = nil
    ) {
        self.type = type
        self.id = id
        self.text = text
        self.parameters = parameters
        self.startCharacterIndex = startCharacterIndex
        self.endCharacterIndex = endCharacterIndex
    }
}

public struct TranscribeAsyncAnnotationExtraParametersResponse: Decodable {
    public let status: TranscribeAsyncAnnotationIntentStatusResponse?
    public let type: TranscribeAsyncAnnotationEntityTypeResponse?
    public let text: String?

    public init(
        status: TranscribeAsyncAnnotationIntentStatusResponse? = nil,
        type: TranscribeAsyncAnnotationEntityTypeResponse? = nil,
        text: String? = nil
    ) {
        self.status = status
        self.type = type
        self.text = text
    }
}

public enum TranscribeAsyncActionTypeResponse: String, Decodable {
    case addAnnotation = "add_annotation"
    case updateAnnotation = "update_annotation"
    case removeAnnotation = "remove_annotation"
    case replaceText = "replace_text"
}

public enum TranscribeAsyncAnnotationParameterTypeResponse: String, Decodable {
    case transcriptionTentative = "transcription_tentative"
    case intent = "intent"
    case entity = "entity"
}

public enum TranscribeAsyncAnnotationIntentStatusResponse: String, Decodable {
    case pending = "pending"
    case recognized = "recognized"
}

public enum TranscribeAsyncAnnotationEntityTypeResponse: String, Decodable {
    case name = "name"
}
