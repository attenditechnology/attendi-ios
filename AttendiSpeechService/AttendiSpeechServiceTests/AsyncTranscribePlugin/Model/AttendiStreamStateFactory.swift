import Foundation
@testable import AttendiSpeechService

enum AttendiStreamStateFactory {
    static func createSample() -> AttendiStreamState {
        return AttendiStreamState(
            text: "Attendi",
            annotations: [
                TranscribeAsyncAction.AddAnnotation(
                    actionData: TranscribeAsyncActionData(id: "1", index: 1),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: "1A",
                        startCharacterIndex: 0,
                        endCharacterIndex: 0,
                        type: .transcriptionTentative
                    )
                ),
                TranscribeAsyncAction.AddAnnotation(
                    actionData: TranscribeAsyncActionData(id: "2", index: 2),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: "2A",
                        startCharacterIndex: 0,
                        endCharacterIndex: 0,
                        type: .entity(type: .name, text: "Entity")
                    )
                ),
                TranscribeAsyncAction.AddAnnotation(
                    actionData: TranscribeAsyncActionData(id: "5", index: 5),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: "5A",
                        startCharacterIndex: 1,
                        endCharacterIndex: 5,
                        type: .intent(status: .pending)
                    )
                ),
                TranscribeAsyncAction.AddAnnotation(
                    actionData: TranscribeAsyncActionData(id: "7", index: 7),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: "7A",
                        startCharacterIndex: 1,
                        endCharacterIndex: 3,
                        type: .transcriptionTentative
                    )
                )
            ]
        )
    }
}
