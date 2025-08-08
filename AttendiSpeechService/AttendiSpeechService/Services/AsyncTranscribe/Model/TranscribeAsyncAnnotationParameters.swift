import Foundation

public struct TranscribeAsyncAnnotationParameters: Equatable {
    public let id: String
    public let startCharacterIndex: Int
    public let endCharacterIndex: Int
    public let type: TranscribeAsyncAnnotationType

    public init(id: String, startCharacterIndex: Int, endCharacterIndex: Int, type: TranscribeAsyncAnnotationType) {
        self.id = id
        self.startCharacterIndex = startCharacterIndex
        self.endCharacterIndex = endCharacterIndex
        self.type = type
    }
}

public enum TranscribeAsyncAnnotationType: Equatable {
    case transcriptionTentative
    case intent(status: TranscribeAsyncAnnotationIntentStatus)
    case entity(type: TranscribeAsyncAnnotationEntityType, text: String)
}

public enum TranscribeAsyncAnnotationIntentStatus: Equatable {
    case pending
    case recognized
}

public enum TranscribeAsyncAnnotationEntityType: Equatable {
    case name
}
