import Foundation
@testable import AttendiSpeechService

enum TranscribeAsyncActionFactory {
    static func createSample() -> [TranscribeAsyncAction] {
        return [
            .replaceText(
                TranscribeAsyncAction.ReplaceText(
                    actionData: TranscribeAsyncActionData(id: "0", index: 0),
                    parameters: TranscribeAsyncReplaceTextParameters(
                        text: "Attendi",
                        startCharacterIndex: 0,
                        endCharacterIndex: 0
                    )
                )
            ),
            .addAnnotation(
                TranscribeAsyncAction.AddAnnotation(
                    actionData: TranscribeAsyncActionData(id: "1", index: 1),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: "1A",
                        startCharacterIndex: 0,
                        endCharacterIndex: 0,
                        type: .transcriptionTentative
                    )
                )
            ),
            .addAnnotation(
                TranscribeAsyncAction.AddAnnotation(
                    actionData: TranscribeAsyncActionData(id: "2", index: 2),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: "2A",
                        startCharacterIndex: 0,
                        endCharacterIndex: 0,
                        type: .entity(type: .name, text: "Entity")
                    )
                )
            ),
            .addAnnotation(
                TranscribeAsyncAction.AddAnnotation(
                    actionData: TranscribeAsyncActionData(id: "3", index: 3),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: "3A",
                        startCharacterIndex: 0,
                        endCharacterIndex: 0,
                        type: .transcriptionTentative
                    )
                )
            ),
            .removeAnnotation(
                TranscribeAsyncAction.RemoveAnnotation(
                    actionData: TranscribeAsyncActionData(id: "4", index: 4),
                    parameters: TranscribeAsyncRemoveAnnotationParameters(id: "3A")
                )
            ),
            .addAnnotation(
                TranscribeAsyncAction.AddAnnotation(
                    actionData: TranscribeAsyncActionData(id: "5", index: 5),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: "5A",
                        startCharacterIndex: 1,
                        endCharacterIndex: 5,
                        type: .intent(status: .pending)
                    )
                )
            ),
            .addAnnotation(
                TranscribeAsyncAction.AddAnnotation(
                    actionData: TranscribeAsyncActionData(id: "6", index: 6),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: "6A",
                        startCharacterIndex: 1,
                        endCharacterIndex: 5,
                        type: .intent(status: .pending)
                    )
                )
            ),
            .updateAnnotation(
                TranscribeAsyncAction.UpdateAnnotation(
                    actionData: TranscribeAsyncActionData(id: "7", index: 7),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: "6A",
                        startCharacterIndex: 1,
                        endCharacterIndex: 3,
                        type: .transcriptionTentative
                    )
                )
            )
        ]
    }
}

