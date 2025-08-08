import Foundation

/// Maps `TranscribeAsyncAction` objects to `UndoableTranscribeAction` objects with their inverse operations.
///
/// This mapper is responsible for creating undoable actions by pairing each action with its inverse.
/// The inverse action is what would need to be applied to reverse the effect of the original action.
public struct UndoableTranscribeAsyncActionMapper {

    public static func map(
        currentState: AttendiStreamState,
        actions: [TranscribeAsyncAction]
    ) throws -> [UndoableTranscribeAction] {
        var updatedText = currentState.text
        var annotations: [TranscribeAsyncAction.AddAnnotation] = currentState.annotations
        return try actions.map { action in
            let undoable: UndoableTranscribeAction
            switch action {
            case .replaceText(let replaceText):
                undoable = createUndoableReplaceTextAction(
                    currentText: updatedText,
                    action: replaceText
                )
                updatedText = try TranscribeAsyncReplaceTextMapper.map(original: updatedText, params: replaceText.parameters)

            case .addAnnotation(let addAnnotation):
                annotations.append(addAnnotation)
                undoable = createUndoableAddAnnotation(action: addAnnotation)

            case .removeAnnotation(let removeAnnotation):
                undoable = try createUndoableRemoveAnnotation(
                    action: removeAnnotation,
                    annotations: annotations
                )

            case .updateAnnotation(let updateAnnotation):
                undoable = try createUndoableUpdateAnnotation(
                    action: updateAnnotation,
                    annotations: annotations
                )
            }
            return undoable
        }
    }

    private static func createUndoableAddAnnotation(
        action: TranscribeAsyncAction.AddAnnotation
    ) -> UndoableTranscribeAction {
        UndoableTranscribeAction(
            original: TranscribeAsyncAction.addAnnotation(action),
            inverse: [
                TranscribeAsyncAction.removeAnnotation(
                    TranscribeAsyncAction.RemoveAnnotation(
                        actionData: TranscribeAsyncActionData(id: action.actionData.id, index: action.actionData.index),
                        parameters: TranscribeAsyncRemoveAnnotationParameters(id: action.parameters.id)
                    )
                )
            ]
        )
    }

    private static func createUndoableRemoveAnnotation(
        action: TranscribeAsyncAction.RemoveAnnotation,
        annotations: [TranscribeAsyncAction.AddAnnotation]
    ) throws -> UndoableTranscribeAction {
        guard let removed = annotations.first(where: {
            $0.parameters.id == action.parameters.id
        }) else {
            throw UndoableTranscribeAsyncActionMapperError.annotationNotFound("remove", action.actionData.id)
        }

        return UndoableTranscribeAction(original: TranscribeAsyncAction.removeAnnotation(action), inverse: [TranscribeAsyncAction.addAnnotation(removed)])
    }

    private static func createUndoableUpdateAnnotation(
        action: TranscribeAsyncAction.UpdateAnnotation,
        annotations: [TranscribeAsyncAction.AddAnnotation]
    ) throws -> UndoableTranscribeAction {
        guard let updated = annotations.first(where: {
            $0.parameters.id == action.parameters.id
        }) else {
            throw UndoableTranscribeAsyncActionMapperError.annotationNotFound("update", action.actionData.id)
        }

        let removedAnnotation = TranscribeAsyncAction.removeAnnotation(
            TranscribeAsyncAction.RemoveAnnotation(
                actionData: action.actionData,
                parameters: TranscribeAsyncRemoveAnnotationParameters(id: action.actionData.id)
            )
        )

        return UndoableTranscribeAction(
            original: TranscribeAsyncAction.updateAnnotation(action),
            inverse: [removedAnnotation, TranscribeAsyncAction.addAnnotation(updated)]
        )
    }

    private static func createUndoableReplaceTextAction(
        currentText: String,
        action: TranscribeAsyncAction.ReplaceText
    ) -> UndoableTranscribeAction {
        let params = action.parameters
        let replacedText = substring(currentText, start: params.startCharacterIndex, end: params.endCharacterIndex)

        let inverseAction = TranscribeAsyncAction.replaceText(
            TranscribeAsyncAction.ReplaceText(
                actionData: TranscribeAsyncActionData(
                    id: action.actionData.id,
                    index: action.actionData.index
                ),
                parameters: TranscribeAsyncReplaceTextParameters(
                    text: replacedText,
                    startCharacterIndex: params.startCharacterIndex,
                    endCharacterIndex: params.startCharacterIndex + params.text.count
                )
            )
        )

        return UndoableTranscribeAction(
            original: .replaceText(action),
            inverse: [inverseAction]
        )
    }

    private static func substring(_ text: String, start: Int, end: Int) -> String {
        guard start >= 0, start <= end, end <= text.count else { return "" }
        let from = text.index(text.startIndex, offsetBy: start)
        let to = text.index(text.startIndex, offsetBy: end)
        return String(text[from..<to])
    }
}

enum UndoableTranscribeAsyncActionMapperError: Error, LocalizedError {
    case annotationNotFound(_ operation: String, _ id: String)
    case annotationInvalid(_ operation: String)

    var errorDescription: String? {
        switch self {
        case .annotationNotFound(let operation, let id):
            return "Annotation to \(operation) not found for id '\(id)'."
        case .annotationInvalid(let operation):
            return "Annotation to \(operation) is invalid."
        }
    }
}
