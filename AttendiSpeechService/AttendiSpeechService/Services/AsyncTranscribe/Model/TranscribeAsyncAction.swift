import Foundation

/// Represents a sealed hierarchy of asynchronous transcription actions.
public enum TranscribeAsyncAction: Equatable {
    case addAnnotation(AddAnnotation)
    case removeAnnotation(RemoveAnnotation)
    case updateAnnotation(UpdateAnnotation)
    case replaceText(ReplaceText)

    public struct AddAnnotation: Equatable {
        public let actionData: TranscribeAsyncActionData
        public let parameters: TranscribeAsyncAnnotationParameters

        public init(
            actionData: TranscribeAsyncActionData,
            parameters: TranscribeAsyncAnnotationParameters
        ) {
            self.actionData = actionData
            self.parameters = parameters
        }
    }

    public struct RemoveAnnotation: Equatable {
        public let actionData: TranscribeAsyncActionData
        public let parameters: TranscribeAsyncRemoveAnnotationParameters

        public init(
            actionData: TranscribeAsyncActionData,
            parameters: TranscribeAsyncRemoveAnnotationParameters
        ) {
            self.actionData = actionData
            self.parameters = parameters
        }
    }

    public struct UpdateAnnotation: Equatable {
        public let actionData: TranscribeAsyncActionData
        public let parameters: TranscribeAsyncAnnotationParameters

        public init(
            actionData: TranscribeAsyncActionData,
            parameters: TranscribeAsyncAnnotationParameters
        ) {
            self.actionData = actionData
            self.parameters = parameters
        }
    }

    public struct ReplaceText: Equatable {
        public let actionData: TranscribeAsyncActionData
        public let parameters: TranscribeAsyncReplaceTextParameters

        public init(
            actionData: TranscribeAsyncActionData,
            parameters: TranscribeAsyncReplaceTextParameters
        ) {
            self.actionData = actionData
            self.parameters = parameters
        }
    }
}

public struct TranscribeAsyncActionData: Equatable {
    public let id: String
    public let index: Int

    public init(id: String, index: Int) {
        self.id = id
        self.index = index
    }
}
